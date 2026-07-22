#!/usr/bin/env nu
# run `jj s` in ~/dotfiles first to snapshot the working copy before regenerating committed SVGs.

# ─── String / math helpers ──────────────────────────────────────────────────

def svg-escape [s: string] {
    $s
    | str replace --all '&' '&amp;'
    | str replace --all '<' '&lt;'
    | str replace --all '>' '&gt;'
}

def format-bytes [b: int] {
    let gb     = (($b | into float) / 1_073_741_824)
    let tenths = ($gb * 10 | math round | into int)
    let whole  = ($tenths / 10 | into int)
    let frac   = ($tenths mod 10)
    $"($whole).($frac)G"
}

def nix-eval-raw [file: string attr: string] {
    try { ^nix eval --impure --raw -f $file $attr } catch { "?" }
}

def nix-eval-count [file: string attr: string] {
    try { ^nix eval --impure --json -f $file $attr --apply "builtins.length" | from json } catch { 0 }
}

def nix-eval-bool [file: string attr: string] {
    let r = (^nix eval --impure -f $file $attr | complete)
    ($r.exit_code == 0) and (($r.stdout | str trim) == "true")
}

def gpu-clean [line: string] {
    # greedy .* grabs the LAST [..] (the device name), not the [AMD/ATI] vendor tag
    let br = ($line | parse --regex '.*\[(?<n>[^\]]+)\]' | get -o n.0 | default ($line | str replace --regex '.*: ' ''))
    let prefix = (if ($br =~ 'RX') { "RX" } else if ($br =~ 'Radeon') { "Radeon" } else { "" })
    # prefer a mobile (...M) model token from the slash-list, else first numeric model
    let model = ($br | parse --regex '(?<m>[0-9]{3,}[A-Za-z]*M)\b' | get -o m.0
        | default ($br | parse --regex '(?<m>[0-9]{3,}[A-Za-z]*)' | get -o m.0 | default ""))
    if ($prefix | is-empty) or ($model | is-empty) { $br } else { $"($prefix) ($model)" }
}

# ─── Overview SVG helpers ────────────────────────────────────────────────────

def ov-header [nixos_ver: string linux_ver: string] {
    [
        $"<text x=\"50\" y=\"90\" font-size=\"42\" fill=\"#ebfafa\" font-weight=\"700\">anomalOS</text>"
        "<rect x=\"290\" y=\"70\" rx=\"6\" width=\"72\" height=\"22\" fill=\"#04d1f9\" opacity=\"0.15\" stroke=\"#04d1f9\" stroke-width=\"0.5\"/>"
        "<text x=\"326\" y=\"85\" font-size=\"10\" fill=\"#04d1f9\" font-weight=\"600\" text-anchor=\"middle\">OVERVIEW</text>"
        $"<text x=\"50\" y=\"120\" font-size=\"15\" fill=\"#abb4da\">NixOS ($nixos_ver)  ·  Linux ($linux_ver)</text>"
    ]
}

def ov-top-card [x: int color: string label: string name: string ver: string] {
    [
        $"<rect x=\"($x)\" y=\"185\" rx=\"8\" width=\"196\" height=\"62\" fill=\"#212337\" stroke=\"#414868\" stroke-width=\"1\"/>"
        $"<rect x=\"($x + 3)\" y=\"193\" rx=\"2\" width=\"3\" height=\"46\" fill=\"($color)\"/>"
        $"<text x=\"($x + 16)\" y=\"203\" font-size=\"10\" fill=\"#414868\" font-weight=\"600\" letter-spacing=\"1\">($label)</text>"
        $"<text x=\"($x + 16)\" y=\"221\" font-size=\"15\" fill=\"#ebfafa\" font-weight=\"600\">($name)</text>"
        $"<text x=\"($x + 16)\" y=\"237\" font-size=\"10\" fill=\"($color)\" opacity=\"0.6\">($ver)</text>"
    ]
}

def ov-section-box [x: int y: int w: int h: int color: string label: string] {
    [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"12\" width=\"($w)\" height=\"($h)\" fill=\"#212337\" stroke=\"#414868\" stroke-width=\"1\"/>"
        $"<rect x=\"($x)\" y=\"($y + 10)\" rx=\"12\" width=\"3\" height=\"($h - 20)\" fill=\"($color)\"/>"
        $"<text x=\"($x + 18)\" y=\"($y + 28)\" font-size=\"13\" fill=\"($color)\" font-weight=\"700\" letter-spacing=\"1\">($label)</text>"
        $"<line x1=\"($x + 14)\" y1=\"($y + 38)\" x2=\"($x + $w - 14)\" y2=\"($y + 38)\" stroke=\"#414868\" stroke-width=\"1\"/>"
    ]
}

def ov-kv [x: int y: int lx: int label: string value: string] {
    [
        $"<text x=\"($x)\" y=\"($y)\" font-size=\"12\" fill=\"#abb4da\">($label)</text>"
        $"<text x=\"($lx)\" y=\"($y)\" font-size=\"12\" fill=\"#ebfafa\">($value)</text>"
    ]
}

def ov-hardware [x: int y: int hw: record] {
    let lx = $x + 150
    [
        ...(ov-section-box $x $y 340 240 "#f265b5" "HARDWARE"),
        ...(ov-kv ($x + 20) ($y + 57)  $lx "CPU"     (svg-escape $hw.cpu)),
        ...(ov-kv ($x + 20) ($y + 77)  $lx "Memory"  (svg-escape $hw.mem)),
        ...(ov-kv ($x + 20) ($y + 97)  $lx "GPU"     (svg-escape $hw.gpu)),
        ...(ov-kv ($x + 20) ($y + 117) $lx "iGPU"    (svg-escape $hw.igpu)),
        ...(ov-kv ($x + 20) ($y + 137) $lx "Monitor" (svg-escape $hw.monitor)),
    ]
}

def ov-fs [x: int y: int] {
    let pool_x    = $x + 20
    let dataset_x = $x + 36
    [
        ...(ov-section-box $x $y 340 240 "#f1fc79" "FS"),
        $"<text x=\"($pool_x)\" y=\"($y + 57)\"  font-size=\"12\" fill=\"#ebfafa\" font-weight=\"600\">zroot</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 75)\"  font-size=\"11\" fill=\"#abb4da\">persist</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 91)\"  font-size=\"11\" fill=\"#abb4da\">nix</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 107)\" font-size=\"11\" fill=\"#abb4da\">tmp</text>"
        $"<text x=\"($pool_x)\" y=\"($y + 127)\" font-size=\"12\" fill=\"#ebfafa\" font-weight=\"600\">zgames</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 145)\" font-size=\"11\" fill=\"#abb4da\">games/roms</text>"
        $"<text x=\"($pool_x)\" y=\"($y + 165)\" font-size=\"12\" fill=\"#ebfafa\" font-weight=\"600\">tmpfs</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 181)\" font-size=\"11\" fill=\"#abb4da\">/  ·  256M</text>"
    ]
}

def ov-system [x: int y: int sys: record] {
    let lx = $x + 150
    [
        ...(ov-section-box $x $y 340 240 "#33c57f" "SYSTEM"),
        ...(ov-kv ($x + 20) ($y + 57)  $lx "Display Mgr"  (svg-escape $sys.dm)),
        ...(ov-kv ($x + 20) ($y + 77)  $lx "Bootloader"   (svg-escape $sys.bootloader)),
        ...(ov-kv ($x + 20) ($y + 97)  $lx "User"         (svg-escape $sys.user)),
        ...(ov-kv ($x + 20) ($y + 117) $lx "Nix Optimise" (svg-escape $sys.optimise)),
        ...(ov-kv ($x + 20) ($y + 137) $lx "Nix GC"       (svg-escape $sys.gc)),
    ]
}

def ov-packages [x: int y: int sys_count: int user_count: int total: int paths: int size: string] {
    let lx = $x + 150
    [
        ...(ov-section-box $x $y 340 240 "#a48cf2" "PACKAGES"),
        ...(ov-kv ($x + 20) ($y + 57)  $lx "System"         ($sys_count | into string)),
        ...(ov-kv ($x + 20) ($y + 77)  $lx "User"           ($user_count | into string)),
        ...(ov-kv ($x + 20) ($y + 97)  $lx "Total declared" ($total | into string)),
        ...(ov-kv ($x + 20) ($y + 117) $lx "Closure paths"  (if $paths > 0 { $"($paths)" } else { "?" })),
        ...(ov-kv ($x + 20) ($y + 137) $lx "Closure size"   $size),
    ]
}

def ov-wrapped-pkgs [x: int y: int pkgs: list<string>] {
    let lx    = $x + 20
    let iy    = $y + 52
    let items = ($pkgs | enumerate | each {|it|
        $"<text x=\"($lx)\" y=\"($iy + ($it.index * 18))\" font-size=\"12\" fill=\"#ebfafa\">▸ ($it.item)</text>"
    })
    [
        ...(ov-section-box $x $y 340 240 "#37f499" "WRAPPED PKGS"),
        ...$items,
    ]
}

def ov-gaming [x: int y: int items: list<string>] {
    let lx    = $x + 20
    let iy    = $y + 52
    let arrow = (char -u '25b8')
    let rows = ($items | enumerate | each {|it|
        $"<text x=\"($lx)\" y=\"($iy + ($it.index * 18))\" font-size=\"12\" fill=\"#ebfafa\">($arrow) ($it.item)</text>"
    })
    [
        ...(ov-section-box $x $y 340 240 "#04d1f9" "GAMING"),
        ...$rows,
    ]
}

def generate-overview [d: record] {
    let w    = 1200
    let h    = 800
    let pkgs = ($d.weegsware_pkgs | sort)

    [
        $"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"($w)\" height=\"($h)\" viewBox=\"0 0 ($w) ($h)\">"
        "<defs><style>"
        "@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&amp;display=swap');"
        "text { font-family: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', Consolas, monospace; }"
        "</style></defs>"
        $"<rect width=\"($w)\" height=\"($h)\" rx=\"16\" fill=\"#171928\"/>"
        "<defs><pattern id=\"grid\" width=\"30\" height=\"30\" patternUnits=\"userSpaceOnUse\">"
        "<circle cx=\"15\" cy=\"15\" r=\"0.5\" fill=\"#414868\" opacity=\"0.2\"/>"
        "</pattern></defs>"
        $"<rect width=\"($w)\" height=\"($h)\" rx=\"16\" fill=\"url\(#grid\)\"/>"
        ...(ov-header (svg-escape $d.nixos_version) (svg-escape $d.linux_version)),
        ...(ov-top-card 70  "#a48cf2" "WM"       "Hyprland"       (svg-escape $d.hyprland_ver)),
        ...(ov-top-card 286 "#37f499" "SHELL"    "nu"             (svg-escape $d.nushell_ver)),
        ...(ov-top-card 502 "#04d1f9" "TERMINAL" "ghostty"        (svg-escape $d.ghostty_ver)),
        ...(ov-top-card 718 "#f1fc79" "EDITOR"   "zed"            (svg-escape $d.zed_ver)),
        ...(ov-top-card 934 "#a48cf2" "UI"       "Noctalia Shell"  (svg-escape $d.noctalia_ver)),
        ...(ov-hardware 70  255 $d.hardware),
        ...(ov-fs       430 255),
        ...(ov-system   790 255 $d.system),
        ...(ov-packages 70  510 $d.sys_pkg_count $d.user_pkg_count $d.total_pkgs $d.closure_paths $d.closure_size),
        ...(ov-wrapped-pkgs 430 510 $pkgs),
        ...(ov-gaming   790 510 $d.gaming),
        "</svg>",
    ] | str join "\n"
}

# ─── Diagram SVG helpers ─────────────────────────────────────────────────────

def box-height [n: int] {
    60 + ($n * 18)
}

# pill width sized to content: JetBrains Mono advance is ~0.6em, pills render at font-size 7
def pill-w [label: string] {
    ((($label | str length) * 4.2 + 10) | math round)
}

def diag-defs [] {
    [
        "<defs>"
        "<style>"
        "@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&amp;display=swap');"
        "text { font-family: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', Consolas, monospace; }"
        "</style>"
        "<filter id=\"glow-cyan\"   x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#04d1f9\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-purple\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#a48cf2\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-green\"  x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#37f499\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-yellow\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#f1fc79\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-pink\"   x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#f265b5\" flood-opacity=\"0.15\"/></filter>"
        "<pattern id=\"grid\" width=\"30\" height=\"30\" patternUnits=\"userSpaceOnUse\">"
        "<circle cx=\"15\" cy=\"15\" r=\"0.5\" fill=\"#414868\" opacity=\"0.15\"/>"
        "</pattern>"
        "</defs>"
    ]
}

def diag-header [nixos_ver: string total_files: int input_count: int] {
    [
        "<text x=\"50\" y=\"85\" font-size=\"36\" fill=\"#ebfafa\" font-weight=\"700\">anomalOS</text>"
        "<rect x=\"270\" y=\"68\" rx=\"6\" width=\"106\" height=\"22\" fill=\"#04d1f9\" opacity=\"0.15\" stroke=\"#04d1f9\" stroke-width=\"0.5\"/>"
        "<text x=\"323\" y=\"83\" font-size=\"10\" fill=\"#04d1f9\" font-weight=\"600\" text-anchor=\"middle\">ASSEMBLY</text>"
        $"<text x=\"50\" y=\"112\" font-size=\"14\" fill=\"#abb4da\">NixOS ($nixos_ver)  ·  /home/weegs/repo/public/anomalos  ·  ($total_files) files  ·  ($input_count) tack pins</text>"
    ]
}

def diag-badge [x: int y: int label: string color: string] {
    let tw = (pill-w $label)
    [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"6\" width=\"($tw)\" height=\"14\" fill=\"($color)\" opacity=\"0.18\"/>"
        $"<text x=\"($x + ($tw / 2))\" y=\"($y + 10)\" font-size=\"7\" fill=\"($color)\" font-weight=\"600\" text-anchor=\"middle\">($label)</text>"
    ]
}

def diag-input-card [x: int y: int name: string repo: string badges: list<record>] {
    let card = [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"10\" width=\"300\" height=\"48\" fill=\"#212337\" stroke=\"#a48cf2\" stroke-width=\"1\" filter=\"url\(#glow-purple\)\"/>"
        $"<rect x=\"($x + 3)\" y=\"($y + 8)\" rx=\"3\" width=\"3\" height=\"32\" fill=\"#a48cf2\"/>"
        $"<circle cx=\"($x + 18)\" cy=\"($y + 18)\" r=\"5\" fill=\"#a48cf2\" opacity=\"0.2\"/>"
        $"<circle cx=\"($x + 18)\" cy=\"($y + 18)\" r=\"3\" fill=\"#a48cf2\"/>"
        $"<text x=\"($x + 30)\" y=\"($y + 21)\" font-size=\"12\" fill=\"#ebfafa\" font-weight=\"700\">($name)</text>"
        $"<text x=\"($x + 30)\" y=\"($y + 36)\" font-size=\"8\" fill=\"#abb4da\" opacity=\"0.5\">($repo)</text>"
    ]
    mut badge_elems = []
    mut bx = $x + 294
    for b in ($badges | reverse) {
        let tw = (pill-w $b.label)
        $bx = $bx - $tw - 4
        $badge_elems = ($badge_elems | append (diag-badge $bx ($y + 4) $b.label $b.color))
    }
    [$card, ($badge_elems | flatten)] | flatten
}

def diag-input-group [x: int y: int label: string color: string inputs: list<record>] {
    let card_h  = 48
    let gap     = 8
    let pad_top = 32
    let n       = ($inputs | length)
    let h       = $pad_top + ($n * $card_h) + (($n - 1) * $gap) + 16
    let w       = 332

    let box = [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"12\" width=\"($w)\" height=\"($h)\" fill=\"none\" stroke=\"($color)\" stroke-width=\"1\" stroke-dasharray=\"4,3\" opacity=\"0.4\"/>"
        $"<text x=\"($x + 16)\" y=\"($y + 20)\" font-size=\"10\" fill=\"($color)\" font-weight=\"700\" letter-spacing=\"1\">($label)</text>"
    ]

    let cards = ($inputs | enumerate | each {|it|
        let cy = $y + $pad_top + ($it.index * ($card_h + $gap))
        diag-input-card ($x + 16) $cy $it.item.name $it.item.repo $it.item.badges
    } | flatten)

    { elems: ([$box, $cards] | flatten), height: $h }
}

def diag-module-box [x: int y: int label: string path: string files: list<string> file_inputs: record color: string --unit: string = "file"] {
    let n          = ($files | length)
    let h          = (box-height $n)
    let w          = 330
    let badge_x    = $x + $w - 52
    let badge_cx   = $x + $w - 30
    let badge_text = if $n == 1 { $"1 ($unit)" } else { $"($n) ($unit)s" }

    let header = [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"12\" width=\"($w)\" height=\"($h)\" fill=\"#212337\" stroke=\"($color)\" stroke-width=\"1.5\" filter=\"url\(#glow-yellow\)\"/>"
        $"<rect x=\"($x + 3)\" y=\"($y + 10)\" rx=\"3\" width=\"4\" height=\"($h - 20)\" fill=\"($color)\"/>"
        $"<circle cx=\"($x + 22)\" cy=\"($y + 22)\" r=\"7\" fill=\"($color)\" opacity=\"0.2\"/>"
        $"<circle cx=\"($x + 22)\" cy=\"($y + 22)\" r=\"4\" fill=\"($color)\"/>"
        $"<text x=\"($x + 38)\" y=\"($y + 26)\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">($label)</text>"
        $"<rect x=\"($badge_x)\" y=\"($y + 6)\" rx=\"8\" width=\"44\" height=\"18\" fill=\"($color)\" opacity=\"0.18\"/>"
        $"<text x=\"($badge_cx)\" y=\"($y + 19)\" font-size=\"10\" fill=\"($color)\" font-weight=\"600\" text-anchor=\"middle\">($badge_text)</text>"
        $"<text x=\"($x + 46)\" y=\"($y + 41)\" font-size=\"10\" fill=\"($color)\" opacity=\"0.6\">($path)</text>"
        $"<line x1=\"($x + 12)\" y1=\"($y + 46)\" x2=\"($x + $w - 12)\" y2=\"($y + 46)\" stroke=\"($color)\" stroke-width=\"0.5\" opacity=\"0.2\"/>"
    ]

    let items = ($files | enumerate | each {|it|
        let iy       = $y + 60 + ($it.index * 18)
        let file_key = $"($path)/($it.item)"
        let consumed = ($file_inputs | get -o $file_key | default [])
        let dot      = $"<text x=\"($x + 16)\" y=\"($iy)\" font-size=\"8\" fill=\"($color)\" opacity=\"0.4\">●</text><text x=\"($x + 28)\" y=\"($iy)\" font-size=\"10\" fill=\"#abb4da\">($it.item)</text>"
        if ($consumed | is-empty) {
            [$dot]
        } else {
            mut tags = []
            mut tx = $x + $w - 10
            for inp in ($consumed | reverse) {
                let tw      = (pill-w $inp)
                $tx         = $tx - $tw - 3
                let tag_color = "#a48cf2"
                let tcx     = $tx + ($tw / 2 | into int)
                $tags = ($tags | append [
                    $"<rect x=\"($tx)\" y=\"($iy - 11)\" rx=\"4\" width=\"($tw)\" height=\"14\" fill=\"($tag_color)\" opacity=\"0.15\"/>"
                    $"<text x=\"($tcx)\" y=\"($iy - 2)\" font-size=\"7\" fill=\"($tag_color)\" opacity=\"0.7\" text-anchor=\"middle\">($inp)</text>"
                ])
            }
            [[$dot], ($tags | flatten)] | flatten
        }
    } | flatten)

    [$header, $items] | flatten
}

def diag-legend [y: int cx: int total_files: int input_count: int] {
    [
        $"<circle cx=\"($cx - 300)\" cy=\"($y)\" r=\"5\" fill=\"#04d1f9\"/>"
        $"<text x=\"($cx - 288)\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Entry</text>"
        $"<circle cx=\"($cx - 180)\" cy=\"($y)\" r=\"5\" fill=\"#a48cf2\"/>"
        $"<text x=\"($cx - 168)\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Pin</text>"
        $"<circle cx=\"($cx - 70)\" cy=\"($y)\" r=\"5\" fill=\"#37f499\"/>"
        $"<text x=\"($cx - 58)\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">REPL</text>"
        $"<circle cx=\"($cx + 45)\" cy=\"($y)\" r=\"5\" fill=\"#f1fc79\"/>"
        $"<text x=\"($cx + 57)\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Module</text>"
        $"<rect x=\"($cx - 170)\" y=\"($y + 25)\" rx=\"6\" width=\"44\" height=\"14\" fill=\"#37f499\" opacity=\"0.18\"/>"
        $"<text x=\"($cx - 148)\" y=\"($y + 35)\" font-size=\"7\" fill=\"#37f499\" font-weight=\"600\" text-anchor=\"middle\">follows</text>"
        $"<rect x=\"($cx - 116)\" y=\"($y + 25)\" rx=\"6\" width=\"34\" height=\"14\" fill=\"#f265b5\" opacity=\"0.18\"/>"
        $"<text x=\"($cx - 99)\" y=\"($y + 35)\" font-size=\"7\" fill=\"#f265b5\" font-weight=\"600\" text-anchor=\"middle\">fetch</text>"
        $"<rect x=\"($cx - 72)\" y=\"($y + 25)\" rx=\"6\" width=\"38\" height=\"14\" fill=\"#f1fc79\" opacity=\"0.18\"/>"
        $"<text x=\"($cx - 53)\" y=\"($y + 35)\" font-size=\"7\" fill=\"#f1fc79\" font-weight=\"600\" text-anchor=\"middle\">pinned</text>"
        $"<rect x=\"($cx - 24)\" y=\"($y + 25)\" rx=\"6\" width=\"56\" height=\"14\" fill=\"#a48cf2\" opacity=\"0.18\"/>"
        $"<text x=\"($cx + 4)\" y=\"($y + 35)\" font-size=\"7\" fill=\"#a48cf2\" font-weight=\"600\" text-anchor=\"middle\">standalone</text>"
        $"<text x=\"($cx)\" y=\"($y + 65)\" font-size=\"12\" fill=\"#abb4da\" text-anchor=\"middle\">($total_files) files  ·  ($input_count) tack pins</text>"
    ]
}

def generate-diagram [d: record] {
    let canvas_w = 1500

    # ── Input groups ─────────────────────────────────────────────────────────
    let group_x = [60, 408, 756, 1104]
    let group_y = 140

    let active_groups = ([
        { label: "FOLLOWS",    color: "#37f499", inputs: $d.input_groups.follows }
        { label: "FETCH",      color: "#f265b5", inputs: $d.input_groups.fetch }
        { label: "PINNED",     color: "#f1fc79", inputs: $d.input_groups.pinned }
        { label: "STANDALONE", color: "#a48cf2", inputs: $d.input_groups.standalone }
    ] | where { ($in.inputs | length) > 0 })

    let groups = ($active_groups | enumerate | each {|it|
        let gx = ($group_x | get $it.index)
        let g  = (diag-input-group $gx $group_y $it.item.label $it.item.color $it.item.inputs)
        { center: ($gx + 166), height: $g.height, color: $it.item.color, elems: $g.elems }
    })
    let group_elems   = ($groups | each { $in.elems } | flatten)
    let max_group_h   = ($groups | each { $in.height } | math max)
    let groups_bottom = $group_y + $max_group_h

    # ── Central pipeline: pins → .tack → assemble.nix ────────────────────────
    let central_y = $groups_bottom + 40
    let tack_x    = 540;  let tack_y = $central_y
    let repl_x    = 860;  let repl_y = $central_y

    let tack_center_x = $tack_x + 130
    # orthogonal bus: each non-empty group drops -> horizontal bus -> single drop into .tack
    let groups_bus_y  = $tack_y - 24
    let connectors = [
        ...($groups | each {|r|
            $"<line x1=\"($r.center)\" y1=\"($group_y + $r.height)\" x2=\"($r.center)\" y2=\"($groups_bus_y)\" stroke=\"($r.color)\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        })
        $"<line x1=\"(($groups | first).center)\" y1=\"($groups_bus_y)\" x2=\"(($groups | last).center)\" y2=\"($groups_bus_y)\" stroke=\"#04d1f9\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($tack_center_x)\" y1=\"($groups_bus_y)\" x2=\"($tack_center_x)\" y2=\"($tack_y)\" stroke=\"#04d1f9\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
    ]

    let assemble_y        = $tack_y + 80
    let assemble_x        = $tack_x
    let assemble_center_x = $tack_center_x

    let central = [
        $"<rect x=\"($tack_x)\" y=\"($tack_y)\" rx=\"12\" width=\"260\" height=\"54\" fill=\"#212337\" stroke=\"#04d1f9\" stroke-width=\"1.5\" filter=\"url\(#glow-cyan\)\"/>"
        $"<rect x=\"($tack_x + 3)\" y=\"($tack_y + 8)\" rx=\"3\" width=\"4\" height=\"38\" fill=\"#04d1f9\"/>"
        $"<circle cx=\"($tack_x + 22)\" cy=\"($tack_y + 20)\" r=\"5\" fill=\"#04d1f9\" opacity=\"0.2\"/>"
        $"<circle cx=\"($tack_x + 22)\" cy=\"($tack_y + 20)\" r=\"3\" fill=\"#04d1f9\"/>"
        $"<text x=\"($tack_x + 36)\" y=\"($tack_y + 24)\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">.tack</text>"
        $"<text x=\"($tack_x + 36)\" y=\"($tack_y + 40)\" font-size=\"10\" fill=\"#04d1f9\" opacity=\"0.7\">pins → resolver</text>"
        $"<rect x=\"($repl_x)\" y=\"($repl_y)\" rx=\"12\" width=\"260\" height=\"54\" fill=\"#212337\" stroke=\"#37f499\" stroke-width=\"1.5\" filter=\"url\(#glow-green\)\"/>"
        $"<rect x=\"($repl_x + 3)\" y=\"($repl_y + 8)\" rx=\"3\" width=\"4\" height=\"38\" fill=\"#37f499\"/>"
        $"<circle cx=\"($repl_x + 22)\" cy=\"($repl_y + 20)\" r=\"5\" fill=\"#37f499\" opacity=\"0.2\"/>"
        $"<circle cx=\"($repl_x + 22)\" cy=\"($repl_y + 20)\" r=\"3\" fill=\"#37f499\"/>"
        $"<text x=\"($repl_x + 36)\" y=\"($repl_y + 24)\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">repl.nix</text>"
        $"<text x=\"($repl_x + 36)\" y=\"($repl_y + 40)\" font-size=\"10\" fill=\"#37f499\" opacity=\"0.7\">import ./.tack</text>"
        $"<line x1=\"($tack_x + 260)\" y1=\"($tack_y + 27)\" x2=\"($repl_x)\" y2=\"($repl_y + 27)\" stroke=\"#04d1f9\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<text x=\"($tack_x + 275)\" y=\"($tack_y + 23)\" font-size=\"8\" fill=\"#04d1f9\" opacity=\"0.35\">import</text>"
        $"<rect x=\"($assemble_x)\" y=\"($assemble_y)\" rx=\"12\" width=\"260\" height=\"54\" fill=\"#212337\" stroke=\"#04d1f9\" stroke-width=\"1.5\" filter=\"url\(#glow-cyan\)\"/>"
        $"<rect x=\"($assemble_x + 3)\" y=\"($assemble_y + 8)\" rx=\"3\" width=\"4\" height=\"38\" fill=\"#04d1f9\"/>"
        $"<circle cx=\"($assemble_x + 22)\" cy=\"($assemble_y + 20)\" r=\"5\" fill=\"#04d1f9\" opacity=\"0.2\"/>"
        $"<circle cx=\"($assemble_x + 22)\" cy=\"($assemble_y + 20)\" r=\"3\" fill=\"#04d1f9\"/>"
        $"<text x=\"($assemble_x + 36)\" y=\"($assemble_y + 24)\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">assemble.nix</text>"
        $"<text x=\"($assemble_x + 36)\" y=\"($assemble_y + 40)\" font-size=\"10\" fill=\"#04d1f9\" opacity=\"0.7\">nixosSystem</text>"
        $"<line x1=\"($tack_center_x)\" y1=\"($tack_y + 54)\" x2=\"($assemble_center_x)\" y2=\"($assemble_y)\" stroke=\"#04d1f9\" stroke-width=\"1.5\" opacity=\"0.4\"/>"
        $"<text x=\"($tack_center_x + 8)\" y=\"($tack_y + 70)\" font-size=\"8\" fill=\"#04d1f9\" opacity=\"0.35\">resolve</text>"
    ]

    # ── Modules root card ────────────────────────────────────────────────────
    let mod_root_y     = $assemble_y + 80
    let mod_root_x     = $assemble_center_x - 130
    let mod_root_files = $d.modules_root_files

    let assemble_to_mod = [
        $"<line x1=\"($assemble_center_x)\" y1=\"($assemble_y + 54)\" x2=\"($assemble_center_x)\" y2=\"($mod_root_y)\" stroke=\"#f1fc79\" stroke-width=\"1.5\" opacity=\"0.4\"/>"
        $"<text x=\"($assemble_center_x + 8)\" y=\"($assemble_y + 70)\" font-size=\"8\" fill=\"#f1fc79\" opacity=\"0.35\">imports</text>"
    ]

    let box_root        = (diag-module-box $mod_root_x $mod_root_y "modules" "modules" $mod_root_files $d.file_inputs "#f1fc79")
    let mod_root_bottom = $mod_root_y + (box-height ($mod_root_files | length))

    # ── Module boxes (4 columns) ─────────────────────────────────────────────
    let box_w  = 330
    let mod_xs = [40, 396, 752, 1108]
    let mod_y  = $mod_root_bottom + 40

    let box_hosts = (diag-module-box ($mod_xs | get 0) $mod_y "hosts"         "modules/hosts"         $d.hosts_files      $d.file_inputs "#f1fc79")
    let box_hjem  = (diag-module-box ($mod_xs | get 1) $mod_y "hjem"          "modules/hjem"          $d.hjem_files       $d.file_inputs "#f1fc79")
    let box_nixos = (diag-module-box ($mod_xs | get 2) $mod_y "nixos-modules" "modules/nixos-modules" $d.nixos_files      $d.file_inputs "#f1fc79")
    let box_weegsware = (diag-module-box ($mod_xs | get 3) $mod_y "weegsware" "./weegsware" $d.weegsware_pkgs {} "#a48cf2" --unit "pkg")

    # ── Tree lines: modules root → child dirs ────────────────────────────────
    let tree_y  = $mod_root_bottom + 4
    let bus_y   = $mod_y - 16
    let mod_cxs = ($mod_xs | each { $in + ($box_w / 2 | into int) })

    let tree_lines = [
        $"<line x1=\"($assemble_center_x)\" y1=\"($tree_y)\" x2=\"($assemble_center_x)\" y2=\"($bus_y)\" stroke=\"#f1fc79\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($mod_cxs | get 0)\" y1=\"($bus_y)\" x2=\"($mod_cxs | get 3)\" y2=\"($bus_y)\" stroke=\"#f1fc79\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        ...($mod_cxs | each {|cx|
            $"<line x1=\"($cx)\" y1=\"($bus_y)\" x2=\"($cx)\" y2=\"($mod_y)\" stroke=\"#f1fc79\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        })
    ]

    # ── Canvas sizing and legend ─────────────────────────────────────────────
    let hosts_bottom = $mod_y + (box-height ($d.hosts_files | length))
    let hjem_bottom  = $mod_y + (box-height ($d.hjem_files | length))
    let nixos_bottom = $mod_y + (box-height ($d.nixos_files | length))
    let weegsware_bottom = $mod_y + (box-height ($d.weegsware_pkgs | length))
    let max_bottom   = ([$hosts_bottom, $hjem_bottom, $nixos_bottom, $weegsware_bottom] | math max)

    let legend_y = $max_bottom + 50
    let canvas_h = $legend_y + 90
    let center_x = ($canvas_w / 2 | into int)

    [
        $"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"($canvas_w)\" height=\"($canvas_h)\" viewBox=\"0 0 ($canvas_w) ($canvas_h)\">"
        ...(diag-defs),
        $"<rect width=\"($canvas_w)\" height=\"($canvas_h)\" rx=\"16\" fill=\"#171928\"/>"
        $"<rect width=\"($canvas_w)\" height=\"($canvas_h)\" rx=\"16\" fill=\"url\(#grid\)\"/>"
        ...(diag-header (svg-escape $d.nixos_version) $d.total_files $d.input_count),
        ...$group_elems,
        ...$connectors,
        ...$central,
        ...$assemble_to_mod,
        ...$box_root,
        ...$tree_lines,
        ...$box_hosts,
        ...$box_hjem,
        ...$box_nixos,
        ...$box_weegsware,
        ...(diag-legend $legend_y $center_x $d.total_files $d.input_count),
        "</svg>",
    ] | str join "\n"
}

# ─── Data collection ────────────────────────────────────────────────────────

def classify-inputs [pins: record] {
    let inputs = ($pins.inputs)
    let names  = ($inputs | columns)

    let classified = ($names | each {|name|
        let pin         = ($inputs | get $name)
        let url         = ($pin.url? | default "")
        let type        = ($pin.type? | default "flake")
        let has_follows = ("follows" in ($pin | columns))

        let repo = (
            $url
            | str replace 'github:' ''
            | str replace 'git+https://' ''
            | str replace 'git+ssh://' ''
        )

        let is_fetch  = ($type == "fetch")
        let is_fixed  = ($type == "fixed")
        # pinned = url ends in a 40-char commit hash
        let is_pinned = ($url =~ '/[0-9a-f]{40}$')

        mut badges = []
        if $has_follows { $badges = ($badges | append { label: "follows", color: "#37f499" }) }
        if $is_fetch    { $badges = ($badges | append { label: "fetch",   color: "#f265b5" }) }
        if $is_fixed    { $badges = ($badges | append { label: "fixed",   color: "#f7c67f" }) }
        if $is_pinned   { $badges = ($badges | append { label: "pinned",  color: "#f1fc79" }) }

        # primary group for layout (priority: fetch/fixed > follows > pinned > standalone)
        let group = if ($is_fetch or $is_fixed) { "fetch" } else if $has_follows { "follows" } else if $is_pinned { "pinned" } else { "standalone" }

        if ($badges | is-empty) { $badges = [{ label: "standalone", color: "#a48cf2" }] }

        { name: $name, repo: $repo, badges: $badges, group: $group }
    })

    {
        follows:    ($classified | where { $in.group == "follows" }),
        fetch:      ($classified | where { $in.group == "fetch" }),
        pinned:     ($classified | where { $in.group == "pinned" }),
        standalone: ($classified | where { $in.group == "standalone" }),
    }
}

def find-input-consumers [dotfiles: string input_names: list<string>] {
    mut result = {}
    for name in $input_names {
        let files = (
            try {
                ^rg -l $"inputs\\.($name)[^\\w-]" $"($dotfiles)/modules/" --type nix
                | lines
                | each {|f|
                    $f | path relative-to $"($dotfiles)"
                }
            } catch { [] }
        )
        for f in $files {
            let existing = ($result | get -o $f | default [])
            $result = ($result | upsert $f ($existing | append $name))
        }
    }
    $result
}

# ─── Main ────────────────────────────────────────────────────────────────────

def main [] {
    if not ("CURRENT_FILE" in $env) {
        error make { msg: "CURRENT_FILE not set -- run this script directly: nu scripts/update-svgs.nu" }
    }

    print "⚠  Remember: run `jj s` in ~/dotfiles first -- snapshot the working copy before regenerating committed SVGs.\n"

    let dotfiles = ($env.CURRENT_FILE | path dirname | path join ".." | path expand)

    # ── Fast: repo data via globs ─────────────────────────────────────────────
    print "→ Collecting repo data..."

    let hjem_files = (
        glob $"($dotfiles)/modules/hjem/**/*.nix"
        | each { $in | path relative-to $"($dotfiles)/modules/hjem" }
        | sort
    )
    let nixos_files = (
        glob $"($dotfiles)/modules/nixos-modules/**/*.nix"
        | each { $in | path relative-to $"($dotfiles)/modules/nixos-modules" }
        | sort
    )
    let hosts_files = (
        glob $"($dotfiles)/modules/hosts/*.nix"
        | each { $in | path basename }
        | sort
    )
    let modules_root_files = (
        glob $"($dotfiles)/modules/*.nix"
        | each { $in | path basename }
        | sort
    )
    let hjem_count         = ($hjem_files | length)
    let nixos_count        = ($nixos_files | length)
    let hosts_count        = ($hosts_files | length)
    let modules_root_count = ($modules_root_files | length)
    let total_files        = $hjem_count + $nixos_count + $hosts_count + $modules_root_count

    print "→ Classifying tack pins..."
    let pins        = (open $"($dotfiles)/.tack/pins.toml")
    let lock        = (open $"($dotfiles)/.tack/pins.lock.json")
    let all_inputs  = ($pins.inputs | columns)
    let input_count = ($all_inputs | length)

    let input_groups = (classify-inputs $pins)

    print "→ Mapping input consumers..."
    let file_inputs = (find-input-consumers $dotfiles $all_inputs)

    # ── Slow: system data via nix eval ───────────────────────────────────────
    print "→ Collecting system data (30-90s per eval call)..."

    let assemble = $"($dotfiles)/assemble.nix"

    print "  · hyprland version...";     let hyprland_ver  = (nix-eval-raw  $assemble "nixosConfigurations.HX99G.pkgs.hyprland.version")
    print "  · nushell version...";      let nushell_ver   = (nix-eval-raw  $assemble "nixosConfigurations.HX99G.pkgs.nushell.version")
    print "  · ghostty version...";      let ghostty_ver   = (nix-eval-raw  $assemble "nixosConfigurations.HX99G.pkgs.ghostty.version")
    print "  · zed version..."; let zed_ver = (nix-eval-raw $assemble "nixosConfigurations.HX99G.pkgs.zed-editor.version")
    # noctalia version from meson.build at the locked rev (pkgs.version is stale nixpkgs metadata)
    print "  · noctalia version..."
    let noctalia_rev  = ($lock | get "noctalia" | get rev)
    let noctalia_meson = (
        try {
            ^gh api $"repos/noctalia-dev/noctalia/contents/meson.build?ref=($noctalia_rev)" --jq '.content'
            | ^base64 -d
        } catch { "" }
    )
    let noctalia_ver  = (
        if ($noctalia_meson | str length) > 0 {
            let base = (
                $noctalia_meson
                | lines
                | where { ($in | str contains "version") and ($in | str contains "'") and (not ($in | str contains "meson_version")) }
                | first
                | parse --regex "'(?P<ver>[0-9][^']*)'"
                | get ver
                | first
            )
            $"v($base)"
        } else { "?" }
    )
    print "  · system package count..."; let sys_pkg_count  = (nix-eval-count $assemble "nixosConfigurations.HX99G.config.environment.systemPackages")
    print "  · user package count...";   let user_pkg_count = (nix-eval-count $assemble "nixosConfigurations.HX99G.config.users.users.weegs.packages")
    let total_pkgs = $sys_pkg_count + $user_pkg_count

    print "  · closure size (slow)..."
    let closure_paths = (try { ^nix path-info --recursive /nix/var/nix/profiles/system | lines | length } catch { 0 })
    let closure_bytes = (try {
        ^nix path-info --recursive --json /nix/var/nix/profiles/system
        | from json | get narSize | math sum
    } catch { 0 })
    let closure_size = if $closure_bytes > 0 { format-bytes $closure_bytes } else { "?" }

    print "  · nixos version...";   let nixos_release   = (nix-eval-raw $assemble "nixosConfigurations.HX99G.config.system.nixos.release")
    print "  · nixos codename...";  let nixos_codename  = (nix-eval-raw $assemble "nixosConfigurations.HX99G.config.system.nixos.codeName")
    print "  · kernel version...";  let linux_version   = (nix-eval-raw $assemble "nixosConfigurations.HX99G.config.boot.kernelPackages.kernel.modDirVersion")
    let nixos_version = $"($nixos_release) \(($nixos_codename)\)"

    # ── Live hardware probe (runs on the rig itself) ──────────────────────────
    print "→ Probing hardware..."
    let cpu = (^cat /proc/cpuinfo | lines | where { $in =~ 'model name' } | first
        | str replace --regex '.*:\s*' '' | str replace 'AMD ' '' | str replace ' with Radeon Graphics' '' | str trim)
    let mem_kb = (^cat /proc/meminfo | lines | where { $in =~ '^MemTotal' } | first
        | parse --regex 'MemTotal:\s+(?<kb>\d+)' | get kb.0 | into int)
    let vga = (^lspci | lines | where { $in =~ '(VGA|3D|Display)' })
    let igpu_line = ($vga | where { $in =~ '(Rembrandt|Raphael|Phoenix|680M|780M)' } | get -o 0 | default "")
    let disc_line = ($vga | where { $in !~ '(Rembrandt|Raphael|Phoenix|680M|780M)' } | get -o 0 | default ($vga | get -o 0 | default ""))
    let hardware = {
        cpu:     $cpu
        mem:     $"(($mem_kb / 1048576) | math round) GB"
        gpu:     (if ($disc_line | is-empty) { "?" } else { gpu-clean $disc_line })
        igpu:    (if ($igpu_line | is-empty) { "-" } else { gpu-clean $igpu_line })
        monitor: (try { ^hyprctl monitors -j | from json | each {|m| $"($m.width)(char -u 'd7')($m.height) @ (($m.refreshRate) | math round)Hz" } | str join ", " } catch { "?" })
    }

    # ── System / gaming / weegsware (config eval) ─────────────────────────────
    print "→ Evaluating system / gaming / weegsware..."
    let dm = (["ly" "gdm" "sddm" "greetd"] | where {|d|
        let r = (^nix eval --impure -f $assemble $"nixosConfigurations.HX99G.config.services.displayManager.($d).enable" | complete)
        ($r.exit_code == 0) and (($r.stdout | str trim) == "true")
    } | get -o 0 | default "?")
    let gc_days = (nix-eval-raw $assemble "nixosConfigurations.HX99G.config.nix.gc.options" | parse --regex '(?<d>[0-9]+d)' | get -o d.0 | default "")
    let system = {
        dm:         $dm
        bootloader: (if (nix-eval-bool $assemble "nixosConfigurations.HX99G.config.boot.loader.systemd-boot.enable") { "systemd-boot" } else if (nix-eval-bool $assemble "nixosConfigurations.HX99G.config.boot.loader.grub.enable") { "grub" } else { "?" })
        user:       (nix-eval-raw $assemble "nixosConfigurations.HX99G.config.mySystem.user.name")
        optimise:   (if (nix-eval-bool $assemble "nixosConfigurations.HX99G.config.nix.optimise.automatic") { "daily" } else { "off" })
        gc:         (if (nix-eval-bool $assemble "nixosConfigurations.HX99G.config.nix.gc.automatic") { (if ($gc_days | is-empty) { "daily" } else { $"daily (char -u '00b7') ($gc_days)" }) } else { "off" })
    }

    let weegsware_pkgs = (try { ^nix eval --impure --json -f $assemble packages.x86_64-linux --apply 'builtins.attrNames' | from json | sort } catch { [] })

    let gmods = (glob $"($dotfiles)/modules/hjem/gaming/*.nix" | each { $in | path parse | get stem } | sort)
    mut gaming = $gmods
    if ("steam" in $weegsware_pkgs) { $gaming = ($gaming | append "steam") }
    if ($"($dotfiles)/modules/hjem/decky.nix" | path exists) { $gaming = ($gaming | append "decky") }
    if (nix-eval-bool $assemble "nixosConfigurations.HX99G.config.programs.gamescope.enable") { $gaming = ($gaming | append "gamescope") }
    if (nix-eval-bool $assemble "nixosConfigurations.HX99G.config.programs.gamemode.enable") { $gaming = ($gaming | append "gamemode") }

    # ── Assemble data record ──────────────────────────────────────────────────
    let d = {
        nixos_version:      $nixos_version
        linux_version:      $linux_version
        hyprland_ver:       $hyprland_ver
        nushell_ver:        $nushell_ver
        ghostty_ver:        $ghostty_ver
        zed_ver:            $zed_ver
        noctalia_ver:       $noctalia_ver
        sys_pkg_count:      $sys_pkg_count
        user_pkg_count:     $user_pkg_count
        total_pkgs:         $total_pkgs
        closure_paths:      $closure_paths
        closure_size:       $closure_size
        weegsware_pkgs:     $weegsware_pkgs
        gaming:             $gaming
        hardware:           $hardware
        system:             $system
        total_files:        $total_files
        input_count:        $input_count
        input_groups:       $input_groups
        file_inputs:        $file_inputs
        hjem_files:         $hjem_files
        nixos_files:        $nixos_files
        hosts_files:        $hosts_files
        modules_root_files: $modules_root_files
    }

    # ── Generate and write ────────────────────────────────────────────────────
    let out_dir = $"($dotfiles)/assets"

    print "\n→ Writing anomalOS-overview.svg..."
    generate-overview $d | save --force $"($out_dir)/anomalOS-overview.svg"

    print "→ Writing anomalOS-diagram.svg..."
    generate-diagram $d | save --force $"($out_dir)/anomalOS-diagram.svg"

    print $"\n✓ Done. Files written to ($out_dir)/"
}
