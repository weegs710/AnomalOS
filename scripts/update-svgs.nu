#!/usr/bin/env nu
# update-svgs.nu — Regenerates anomalOS-overview.svg and anomalOS-diagram.svg
# from live repository and system data.
#
# IMPORTANT: Run `jj s` in ~/dotfiles first.
# nix eval reads git-tracked state — uncommitted changes won't appear.

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

def nix-eval-raw [attr: string] {
    try { ^nix eval --raw $attr } catch { "?" }
}

# Count the length of a Nix list attribute (--apply builtins.length)
def nix-eval-count [attr: string] {
    try { ^nix eval --json $attr --apply "builtins.length" | from json } catch { 0 }
}

# Strip wrappers and suffixes to get a clean display name from a shareable filename stem
def shareable-name [stem: string] {
    $stem
    | str replace --regex '^_'   ''
    | str replace 'wrapped-'     ''
    | str replace '-editor'      ''
    | str replace '-shell'       ''
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
        $"<rect x=\"($x)\" y=\"185\" rx=\"8\" width=\"196\" height=\"62\" fill=\"#212337\" stroke=\"#3b4261\" stroke-width=\"1\"/>"
        $"<rect x=\"($x + 3)\" y=\"193\" rx=\"2\" width=\"3\" height=\"46\" fill=\"($color)\"/>"
        $"<text x=\"($x + 16)\" y=\"203\" font-size=\"10\" fill=\"#414868\" font-weight=\"600\" letter-spacing=\"1\">($label)</text>"
        $"<text x=\"($x + 16)\" y=\"221\" font-size=\"15\" fill=\"#ebfafa\" font-weight=\"600\">($name)</text>"
        $"<text x=\"($x + 16)\" y=\"237\" font-size=\"10\" fill=\"($color)\" opacity=\"0.6\">($ver)</text>"
    ]
}

def ov-section-box [x: int y: int w: int h: int color: string label: string] {
    [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"12\" width=\"($w)\" height=\"($h)\" fill=\"#212337\" stroke=\"#3b4261\" stroke-width=\"1\"/>"
        $"<rect x=\"($x)\" y=\"($y + 10)\" rx=\"12\" width=\"3\" height=\"($h - 20)\" fill=\"($color)\"/>"
        $"<text x=\"($x + 18)\" y=\"($y + 28)\" font-size=\"13\" fill=\"($color)\" font-weight=\"700\" letter-spacing=\"1\">($label)</text>"
        $"<line x1=\"($x + 14)\" y1=\"($y + 38)\" x2=\"($x + $w - 14)\" y2=\"($y + 38)\" stroke=\"#3b4261\" stroke-width=\"1\"/>"
    ]
}

def ov-kv [x: int y: int lx: int label: string value: string] {
    [
        $"<text x=\"($x)\" y=\"($y)\" font-size=\"12\" fill=\"#abb4da\">($label)</text>"
        $"<text x=\"($lx)\" y=\"($y)\" font-size=\"12\" fill=\"#ebfafa\">($value)</text>"
    ]
}

def ov-hardware [x: int y: int] {
    let lx = $x + 150
    [
        ...(ov-section-box $x $y 340 240 "#f265b5" "HARDWARE"),
        ...(ov-kv ($x + 20) ($y + 57)  $lx "CPU"     "Ryzen 9 6900HX"),
        ...(ov-kv ($x + 20) ($y + 77)  $lx "Memory"  "62 GB"),
        ...(ov-kv ($x + 20) ($y + 97)  $lx "GPU"     "RX 6600M"),
        ...(ov-kv ($x + 20) ($y + 117) $lx "Monitor" "2560×1440 @ 144Hz"),
    ]
}

def ov-fs [x: int y: int] {
    let px = $x + 20   # pool x
    let dx = $x + 36   # dataset x (indented)
    [
        ...(ov-section-box $x $y 340 240 "#e9f941" "FS"),
        $"<text x=\"($px)\" y=\"($y + 57)\"  font-size=\"12\" fill=\"#ebfafa\" font-weight=\"600\">zroot</text>"
        $"<text x=\"($dx)\" y=\"($y + 75)\"  font-size=\"11\" fill=\"#abb4da\">persist</text>"
        $"<text x=\"($dx)\" y=\"($y + 91)\"  font-size=\"11\" fill=\"#abb4da\">nix</text>"
        $"<text x=\"($dx)\" y=\"($y + 107)\" font-size=\"11\" fill=\"#abb4da\">tmp</text>"
        $"<text x=\"($px)\" y=\"($y + 127)\" font-size=\"12\" fill=\"#ebfafa\" font-weight=\"600\">zgames</text>"
        $"<text x=\"($dx)\" y=\"($y + 145)\" font-size=\"11\" fill=\"#abb4da\">games/roms</text>"
        $"<text x=\"($px)\" y=\"($y + 165)\" font-size=\"12\" fill=\"#ebfafa\" font-weight=\"600\">tmpfs</text>"
        $"<text x=\"($dx)\" y=\"($y + 181)\" font-size=\"11\" fill=\"#abb4da\">/  ·  256M</text>"
    ]
}

def ov-system [x: int y: int] {
    let lx = $x + 150
    [
        ...(ov-section-box $x $y 340 240 "#69f8b3" "SYSTEM"),
        ...(ov-kv ($x + 20) ($y + 57)  $lx "Display Mgr"  "ly"),
        ...(ov-kv ($x + 20) ($y + 77)  $lx "Bootloader"   "systemd-boot"),
        ...(ov-kv ($x + 20) ($y + 97)  $lx "Users"        "weegs"),
        ...(ov-kv ($x + 20) ($y + 117) $lx "Nix Optimise" "daily"),
        ...(ov-kv ($x + 20) ($y + 137) $lx "Nix GC"       "daily · 90d"),
    ]
}

def ov-packages [x: int y: int sys_count: int user_count: int total: int paths: int size: string] {
    let lx = $x + 150
    [
        ...(ov-section-box $x $y 340 240 "#9071f4" "PACKAGES"),
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

def ov-gaming [x: int y: int] {
    [
        ...(ov-section-box $x $y 340 240 "#04d1f9" "GAMING"),
        $"<text x=\"($x + 20)\" y=\"($y + 57)\"  font-size=\"12\" fill=\"#ebfafa\">▸ Steam + Decky Loader</text>"
        $"<text x=\"($x + 20)\" y=\"($y + 77)\"  font-size=\"12\" fill=\"#ebfafa\">▸ RetroArch</text>"
        $"<text x=\"($x + 20)\" y=\"($y + 97)\"  font-size=\"12\" fill=\"#ebfafa\">▸ ProtonUp-Qt</text>"
        $"<text x=\"($x + 20)\" y=\"($y + 117)\" font-size=\"12\" fill=\"#ebfafa\">▸ OpenRA</text>"
        $"<text x=\"($x + 20)\" y=\"($y + 137)\" font-size=\"12\" fill=\"#ebfafa\">▸ Renegade X</text>"
    ]
}

def generate-overview [d: record] {
    let w    = 1200
    let h    = 800
    let pkgs = ($d.shareables_pkgs | each { shareable-name $in } | sort)

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
        ...(ov-top-card 718 "#e9f941" "EDITOR"   "fresh"          (svg-escape $d.fresh_ver)),
        ...(ov-top-card 934 "#9071f4" "UI"       "Noctalia Shell"  (svg-escape $d.noctalia_ver)),
        ...(ov-hardware 70  255),
        ...(ov-fs       430 255),
        ...(ov-system   790 255),
        ...(ov-packages 70  510 $d.sys_pkg_count $d.user_pkg_count $d.total_pkgs $d.closure_paths $d.closure_size),
        ...(ov-wrapped-pkgs 430 510 $pkgs),
        ...(ov-gaming   790 510),
        "</svg>",
    ] | str join "\n"
}

# ─── Diagram SVG helpers ─────────────────────────────────────────────────────

def box-height [n: int] {
    60 + ($n * 18)
}

def diag-defs [] {
    [
        "<defs>"
        "<style>"
        "@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&amp;display=swap');"
        "text { font-family: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', Consolas, monospace; }"
        "</style>"
        "<filter id=\"glow-cyan\"   x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#04d1f9\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-purple\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#9071f4\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-green\"  x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#37f499\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-yellow\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#e9f941\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-pink\"   x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#f265b5\" flood-opacity=\"0.15\"/></filter>"
        "<pattern id=\"grid\" width=\"30\" height=\"30\" patternUnits=\"userSpaceOnUse\">"
        "<circle cx=\"15\" cy=\"15\" r=\"0.5\" fill=\"#414868\" opacity=\"0.15\"/>"
        "</pattern>"
        "</defs>"
    ]
}

def diag-header [total_files: int input_count: int] {
    [
        "<text x=\"50\" y=\"85\" font-size=\"36\" fill=\"#ebfafa\" font-weight=\"700\">anomalOS</text>"
        "<rect x=\"270\" y=\"68\" rx=\"6\" width=\"106\" height=\"22\" fill=\"#04d1f9\" opacity=\"0.15\" stroke=\"#04d1f9\" stroke-width=\"0.5\"/>"
        "<text x=\"323\" y=\"83\" font-size=\"10\" fill=\"#04d1f9\" font-weight=\"600\" text-anchor=\"middle\">FLAKE DIAGRAM</text>"
        $"<text x=\"50\" y=\"112\" font-size=\"14\" fill=\"#abb4da\">NixOS 26.05  ·  /home/weegs/dotfiles  ·  ($total_files) files  ·  ($input_count) flake inputs</text>"
    ]
}

# Badge pill: small colored rounded rect with text
def diag-badge [x: int y: int label: string color: string] {
    let tw = ($label | str length) * 6 + 8
    [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"6\" width=\"($tw)\" height=\"14\" fill=\"($color)\" opacity=\"0.18\"/>"
        $"<text x=\"($x + ($tw / 2))\" y=\"($y + 10)\" font-size=\"7\" fill=\"($color)\" font-weight=\"600\" text-anchor=\"middle\">($label)</text>"
    ]
}

# Input card with badges (300x48)
def diag-input-card [x: int y: int name: string repo: string badges: list<record>] {
    let card = [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"10\" width=\"300\" height=\"48\" fill=\"#212337\" stroke=\"#9071f4\" stroke-width=\"1\" filter=\"url\(#glow-purple\)\"/>"
        $"<rect x=\"($x + 3)\" y=\"($y + 8)\" rx=\"3\" width=\"3\" height=\"32\" fill=\"#9071f4\"/>"
        $"<circle cx=\"($x + 18)\" cy=\"($y + 18)\" r=\"5\" fill=\"#9071f4\" opacity=\"0.2\"/>"
        $"<circle cx=\"($x + 18)\" cy=\"($y + 18)\" r=\"3\" fill=\"#9071f4\"/>"
        $"<text x=\"($x + 30)\" y=\"($y + 21)\" font-size=\"12\" fill=\"#ebfafa\" font-weight=\"700\">($name)</text>"
        $"<text x=\"($x + 30)\" y=\"($y + 36)\" font-size=\"8\" fill=\"#abb4da\" opacity=\"0.5\">($repo)</text>"
    ]
    # render badges from right edge
    mut badge_elems = []
    mut bx = $x + 294
    for b in ($badges | reverse) {
        let tw = ($b.label | str length) * 6 + 8
        $bx = $bx - $tw - 4
        $badge_elems = ($badge_elems | append (diag-badge $bx ($y + 4) $b.label $b.color))
    }
    [$card, ($badge_elems | flatten)] | flatten
}

# Group box: dashed border with section label, contains input cards stacked vertically
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

# Module box with input tags on consuming files (330px wide)
def diag-module-box [x: int y: int label: string path: string files: list<string> file_inputs: record color: string] {
    let n          = ($files | length)
    let h          = (box-height $n)
    let w          = 330
    let badge_x    = $x + $w - 52
    let badge_cx   = $x + $w - 30
    let badge_text = if $n == 1 { "1 file" } else { $"($n) files" }

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
        let iy = $y + 60 + ($it.index * 18)
        let file_key = $"($path)/($it.item)"
        let consumed = ($file_inputs | get -o $file_key | default [])
        let dot = $"<text x=\"($x + 16)\" y=\"($iy)\" font-size=\"8\" fill=\"($color)\" opacity=\"0.4\">●</text><text x=\"($x + 28)\" y=\"($iy)\" font-size=\"10\" fill=\"#abb4da\">($it.item)</text>"
        if ($consumed | is-empty) {
            [$dot]
        } else {
            # render input tags from right side of box
            mut tags = []
            mut tx = $x + $w - 10
            for inp in ($consumed | reverse) {
                let tw = ($inp | str length) * 5 + 10
                $tx = $tx - $tw - 3
                let tag_color = "#9071f4"
                let tcx = $tx + ($tw / 2 | into int)
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
        $"<text x=\"($cx - 288)\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Flake Root</text>"
        $"<circle cx=\"($cx - 155)\" cy=\"($y)\" r=\"5\" fill=\"#9071f4\"/>"
        $"<text x=\"($cx - 143)\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Input</text>"
        $"<circle cx=\"($cx - 50)\" cy=\"($y)\" r=\"5\" fill=\"#37f499\"/>"
        $"<text x=\"($cx - 38)\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">REPL</text>"
        $"<circle cx=\"($cx + 45)\" cy=\"($y)\" r=\"5\" fill=\"#e9f941\"/>"
        $"<text x=\"($cx + 57)\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Module</text>"
        $"<circle cx=\"($cx + 155)\" cy=\"($y)\" r=\"5\" fill=\"#f265b5\"/>"
        $"<text x=\"($cx + 167)\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Non-flake</text>"
        # badge key row
        $"<rect x=\"($cx - 200)\" y=\"($y + 25)\" rx=\"6\" width=\"44\" height=\"14\" fill=\"#37f499\" opacity=\"0.18\"/>"
        $"<text x=\"($cx - 178)\" y=\"($y + 35)\" font-size=\"7\" fill=\"#37f499\" font-weight=\"600\" text-anchor=\"middle\">follows</text>"
        $"<rect x=\"($cx - 140)\" y=\"($y + 25)\" rx=\"6\" width=\"38\" height=\"14\" fill=\"#e9f941\" opacity=\"0.18\"/>"
        $"<text x=\"($cx - 121)\" y=\"($y + 35)\" font-size=\"7\" fill=\"#e9f941\" font-weight=\"600\" text-anchor=\"middle\">pinned</text>"
        $"<rect x=\"($cx - 86)\" y=\"($y + 25)\" rx=\"6\" width=\"50\" height=\"14\" fill=\"#f265b5\" opacity=\"0.18\"/>"
        $"<text x=\"($cx - 61)\" y=\"($y + 35)\" font-size=\"7\" fill=\"#f265b5\" font-weight=\"600\" text-anchor=\"middle\">non-flake</text>"
        $"<rect x=\"($cx - 20)\" y=\"($y + 25)\" rx=\"6\" width=\"32\" height=\"14\" fill=\"#04d1f9\" opacity=\"0.18\"/>"
        $"<text x=\"($cx - 4)\" y=\"($y + 35)\" font-size=\"7\" fill=\"#04d1f9\" font-weight=\"600\" text-anchor=\"middle\">local</text>"
        $"<rect x=\"($cx + 28)\" y=\"($y + 25)\" rx=\"6\" width=\"56\" height=\"14\" fill=\"#9071f4\" opacity=\"0.18\"/>"
        $"<text x=\"($cx + 56)\" y=\"($y + 35)\" font-size=\"7\" fill=\"#9071f4\" font-weight=\"600\" text-anchor=\"middle\">standalone</text>"
        # summary
        $"<text x=\"($cx)\" y=\"($y + 65)\" font-size=\"12\" fill=\"#abb4da\" text-anchor=\"middle\">($total_files) files  ·  ($input_count) flake inputs</text>"
    ]
}

def generate-diagram [d: record] {
    let canvas_w  = 1500
    let col_gap   = 16

    # ── Input groups ─────────────────────────────────────────────────────────
    let group_x = [60, 408, 756, 1104]
    let group_y = 140

    let g_follows  = (diag-input-group ($group_x | get 0) $group_y "FOLLOWS NIXPKGS" "#37f499" ($d.input_groups.follows))
    let g_nonflake = (diag-input-group ($group_x | get 1) $group_y "NON-FLAKE"        "#f265b5" ($d.input_groups.nonflake))
    let g_pinned   = (diag-input-group ($group_x | get 2) $group_y "PINNED"           "#e9f941" ($d.input_groups.pinned))
    let g_standalone = (diag-input-group ($group_x | get 3) $group_y "STANDALONE"      "#9071f4" ($d.input_groups.standalone))

    let max_group_h = ([$g_follows.height, $g_nonflake.height, $g_pinned.height, $g_standalone.height] | math max)
    let groups_bottom = $group_y + $max_group_h

    # ── Central nodes ────────────────────────────────────────────────────────
    let central_y = $groups_bottom + 40
    let flake_x   = 540;  let flake_y = $central_y
    let repl_x    = 860;  let repl_y  = $central_y

    # group → flake.nix connector lines (one per group, from each group's actual bottom)
    let group_colors   = ["#37f499", "#f265b5", "#e9f941", "#9071f4"]
    let group_heights  = [$g_follows.height, $g_nonflake.height, $g_pinned.height, $g_standalone.height]
    let group_centers  = ($group_x | each { $in + 166 })
    let flake_center_x = $flake_x + 130
    let connectors = ($group_centers | enumerate | each {|it|
        let gx = $it.item
        let gy = $group_y + ($group_heights | get $it.index)
        let color = ($group_colors | get $it.index)
        $"<polyline points=\"($gx),($gy) ($gx),($gy + 16) ($flake_center_x),($flake_y - 4)\" stroke=\"($color)\" stroke-width=\"1.2\" fill=\"none\" opacity=\"0.3\"/>"
    })

    let central = [
        # flake.nix
        $"<rect x=\"($flake_x)\" y=\"($flake_y)\" rx=\"12\" width=\"260\" height=\"54\" fill=\"#212337\" stroke=\"#04d1f9\" stroke-width=\"1.5\" filter=\"url\(#glow-cyan\)\"/>"
        $"<rect x=\"($flake_x + 3)\" y=\"($flake_y + 8)\" rx=\"3\" width=\"4\" height=\"38\" fill=\"#04d1f9\"/>"
        $"<circle cx=\"($flake_x + 22)\" cy=\"($flake_y + 20)\" r=\"5\" fill=\"#04d1f9\" opacity=\"0.2\"/>"
        $"<circle cx=\"($flake_x + 22)\" cy=\"($flake_y + 20)\" r=\"3\" fill=\"#04d1f9\"/>"
        $"<text x=\"($flake_x + 36)\" y=\"($flake_y + 24)\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">flake.nix</text>"
        $"<text x=\"($flake_x + 36)\" y=\"($flake_y + 40)\" font-size=\"10\" fill=\"#04d1f9\" opacity=\"0.7\">Flake Root</text>"
        # repl.nix
        $"<rect x=\"($repl_x)\" y=\"($repl_y)\" rx=\"12\" width=\"260\" height=\"54\" fill=\"#212337\" stroke=\"#37f499\" stroke-width=\"1.5\" filter=\"url\(#glow-green\)\"/>"
        $"<rect x=\"($repl_x + 3)\" y=\"($repl_y + 8)\" rx=\"3\" width=\"4\" height=\"38\" fill=\"#37f499\"/>"
        $"<circle cx=\"($repl_x + 22)\" cy=\"($repl_y + 20)\" r=\"5\" fill=\"#37f499\" opacity=\"0.2\"/>"
        $"<circle cx=\"($repl_x + 22)\" cy=\"($repl_y + 20)\" r=\"3\" fill=\"#37f499\"/>"
        $"<text x=\"($repl_x + 36)\" y=\"($repl_y + 24)\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">repl.nix</text>"
        $"<text x=\"($repl_x + 36)\" y=\"($repl_y + 40)\" font-size=\"10\" fill=\"#37f499\" opacity=\"0.7\">Nix REPL</text>"
        # connector between them
        $"<line x1=\"($flake_x + 260)\" y1=\"($flake_y + 27)\" x2=\"($repl_x)\" y2=\"($repl_y + 27)\" stroke=\"#04d1f9\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<text x=\"($flake_x + 275)\" y=\"($flake_y + 23)\" font-size=\"8\" fill=\"#04d1f9\" opacity=\"0.35\">outputs</text>"
    ]

    # ── Modules root card ────────────────────────────────────────────────────
    let mod_root_y  = $central_y + 80
    let mod_root_x  = $flake_center_x - 130
    let mod_root_files = $d.modules_root_files

    let flake_to_mod = [
        $"<line x1=\"($flake_center_x)\" y1=\"($flake_y + 54)\" x2=\"($flake_center_x)\" y2=\"($mod_root_y)\" stroke=\"#e9f941\" stroke-width=\"1.5\" opacity=\"0.4\"/>"
        $"<text x=\"($flake_center_x + 8)\" y=\"($flake_y + 70)\" font-size=\"8\" fill=\"#e9f941\" opacity=\"0.35\">imports</text>"
    ]

    let box_root = (diag-module-box $mod_root_x $mod_root_y "modules" "modules" $mod_root_files $d.file_inputs "#e9f941")
    let mod_root_bottom = $mod_root_y + (box-height ($mod_root_files | length))

    # ── Module boxes (4 columns) ─────────────────────────────────────────────
    let box_w  = 330
    let mod_xs = [40, 396, 752, 1108]
    let mod_y  = $mod_root_bottom + 40

    let box_hosts  = (diag-module-box ($mod_xs | get 0) $mod_y "hosts"         "modules/hosts"         $d.hosts_files      $d.file_inputs "#e9f941")
    let box_hjem   = (diag-module-box ($mod_xs | get 1) $mod_y "hjem"          "modules/hjem"          $d.hjem_files       $d.file_inputs "#e9f941")
    let box_nixos  = (diag-module-box ($mod_xs | get 2) $mod_y "nixos-modules" "modules/nixos-modules" $d.nixos_files      $d.file_inputs "#e9f941")
    let box_shar   = (diag-module-box ($mod_xs | get 3) $mod_y "shareables"    "modules/shareables"    $d.shareables_files $d.file_inputs "#e9f941")

    # ── Tree lines: modules root → child dirs ────────────────────────────────
    let tree_y   = $mod_root_bottom + 4
    let bus_y    = $mod_y - 16
    let mod_cxs  = ($mod_xs | each { $in + ($box_w / 2 | into int) })

    let tree_lines = [
        # vertical from root down to bus
        $"<line x1=\"($flake_center_x)\" y1=\"($tree_y)\" x2=\"($flake_center_x)\" y2=\"($bus_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        # horizontal bus
        $"<line x1=\"($mod_cxs | get 0)\" y1=\"($bus_y)\" x2=\"($mod_cxs | get 3)\" y2=\"($bus_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        # drops to each column
        $"<line x1=\"($mod_cxs | get 0)\" y1=\"($bus_y)\" x2=\"($mod_cxs | get 0)\" y2=\"($mod_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($mod_cxs | get 1)\" y1=\"($bus_y)\" x2=\"($mod_cxs | get 1)\" y2=\"($mod_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($mod_cxs | get 2)\" y1=\"($bus_y)\" x2=\"($mod_cxs | get 2)\" y2=\"($mod_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($mod_cxs | get 3)\" y1=\"($bus_y)\" x2=\"($mod_cxs | get 3)\" y2=\"($mod_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
    ]

    # ── Canvas sizing and legend ─────────────────────────────────────────────
    let hosts_bottom = $mod_y + (box-height ($d.hosts_files | length))
    let hjem_bottom  = $mod_y + (box-height ($d.hjem_files | length))
    let nixos_bottom = $mod_y + (box-height ($d.nixos_files | length))
    let shar_bottom  = $mod_y + (box-height ($d.shareables_files | length))
    let max_bottom   = ([$hosts_bottom, $hjem_bottom, $nixos_bottom, $shar_bottom] | math max)

    let legend_y  = $max_bottom + 50
    let canvas_h  = $legend_y + 90
    let center_x  = ($canvas_w / 2 | into int)

    [
        $"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"($canvas_w)\" height=\"($canvas_h)\" viewBox=\"0 0 ($canvas_w) ($canvas_h)\">"
        ...(diag-defs),
        $"<rect width=\"($canvas_w)\" height=\"($canvas_h)\" rx=\"16\" fill=\"#171928\"/>"
        $"<rect width=\"($canvas_w)\" height=\"($canvas_h)\" rx=\"16\" fill=\"url\(#grid\)\"/>"
        ...(diag-header $d.total_files $d.input_count),
        ...$g_follows.elems,
        ...$g_nonflake.elems,
        ...$g_pinned.elems,
        ...$g_standalone.elems,
        ...$connectors,
        ...$central,
        ...$flake_to_mod,
        ...$box_root,
        ...$tree_lines,
        ...$box_hosts,
        ...$box_hjem,
        ...$box_nixos,
        ...$box_shar,
        ...(diag-legend $legend_y $center_x $d.total_files $d.input_count),
        "</svg>",
    ] | str join "\n"
}

# ─── Data collection ────────────────────────────────────────────────────────

# Classify flake inputs into groups with badges
def classify-inputs [flake_meta: record] {
    let root_inputs = ($flake_meta.locks.nodes.root.inputs | columns)

    let classified = ($root_inputs | each {|name|
        let node_key = ($flake_meta.locks.nodes.root.inputs | get $name)
        let is_list = ($node_key | describe | str starts-with "list")
        if $is_list {
            # follows-style redirect, shouldn't happen for root inputs but handle it
            { name: $name, repo: $name, badges: [{ label: "follows", color: "#37f499" }], group: "follows" }
        } else {
            let node = ($flake_meta.locks.nodes | get $node_key)
            let orig = ($node.original? | default {})
            let locked = ($node.locked? | default {})
            let inner_inputs = ($node.inputs? | default {})

            # determine repo display string
            let url = ($orig.url? | default "")
            let owner = ($orig.owner? | default "")
            let repo = if ($url | str length) > 0 {
                $url | str replace 'github:' '' | str replace 'git+https://' '' | str replace --regex '/flake.nix$' ''
            } else if ($owner | str length) > 0 {
                $"($owner)/($orig.repo? | default $name)"
            } else { $name }

            # classify traits
            let nxref = ($inner_inputs.nixpkgs? | default null)
            let is_follows = ($nxref != null and ($nxref | describe | str starts-with "list"))
            let is_nonflake = (($node.flake? | default true) == false)
            let is_path = (($orig.type? | default "") == "path")
            let ref_pin = ($orig.ref? | default "")
            # pinned = has a ref (branch/tag) or the URL contains a commit hash
            let is_pinned = (($ref_pin | str length) > 0 or ($url =~ '/[0-9a-f]{40}$'))

            mut badges = []
            if $is_follows   { $badges = ($badges | append { label: "follows", color: "#37f499" }) }
            if $is_pinned    { $badges = ($badges | append { label: "pinned",  color: "#e9f941" }) }
            if $is_nonflake  { $badges = ($badges | append { label: "non-flake", color: "#f265b5" }) }
            if $is_path      { $badges = ($badges | append { label: "local",   color: "#04d1f9" }) }

            # primary group for layout (priority: nonflake > follows > pinned > standalone)
            let group = if $is_nonflake { "nonflake" } else if $is_follows { "follows" } else if $is_pinned { "pinned" } else { "standalone" }

            if ($badges | is-empty) { $badges = [{ label: "standalone", color: "#9071f4" }] }

            { name: $name, repo: $repo, badges: $badges, group: $group }
        }
    })

    # group into buckets
    {
        follows:    ($classified | where { $in.group == "follows" }),
        nonflake:   ($classified | where { $in.group == "nonflake" }),
        pinned:     ($classified | where { $in.group == "pinned" }),
        standalone: ($classified | where { $in.group == "standalone" }),
    }
}

# Map files to the input names they consume, by grepping for inputs.X references
def find-input-consumers [dotfiles: string input_names: list<string>] {
    mut result = {}
    for name in $input_names {
        if $name == "flake-parts" { continue }  # framework input, not consumed by modules
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

    print "⚠  Remember: run `jj s` in ~/dotfiles first -- nix eval reads git-tracked state.\n"

    let dotfiles = ($env.CURRENT_FILE | path dirname | path join ".." | path expand)

    # ── Fast: repo data via globs ─────────────────────────────────────────────
    print "→ Collecting repo data..."

    let hjem_files = (
        glob $"($dotfiles)/modules/hjem/**/*.nix"
        | each { $in | path relative-to $"($dotfiles)/modules/hjem" }
        | sort
    )
    let nixos_files = (
        glob $"($dotfiles)/modules/nixos-modules/*.nix"
        | each { $in | path basename }
        | sort
    )
    let shareables_files = (
        glob $"($dotfiles)/modules/shareables/*.nix"
        | each { $in | path basename }
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
    let shareables_pkgs = ($shareables_files | each { $in | str replace '.nix' '' })

    let hjem_count         = ($hjem_files | length)
    let nixos_count        = ($nixos_files | length)
    let shareables_count   = ($shareables_files | length)
    let hosts_count        = ($hosts_files | length)
    let modules_root_count = ($modules_root_files | length)
    let total_files        = $hjem_count + $nixos_count + $shareables_count + $hosts_count + $modules_root_count

    # Flake inputs via nix flake metadata (fast -- reads lock file)
    print "→ Classifying flake inputs..."
    let flake_meta  = (^nix flake metadata --json $dotfiles | from json)
    let all_inputs  = ($flake_meta.locks.nodes.root.inputs | columns)
    let input_count = ($all_inputs | length)

    let input_groups = (classify-inputs $flake_meta)

    # Map files to their consumed inputs
    print "→ Mapping input consumers..."
    let file_inputs = (find-input-consumers $dotfiles $all_inputs)

    # ── Slow: system data via nix eval ───────────────────────────────────────
    print "→ Collecting system data (30-90s per eval call)..."

    let flake_ref = $dotfiles

    print "  · hyprland version...";    let hyprland_ver  = (nix-eval-raw  $"($flake_ref)#nixosConfigurations.HX99G.pkgs.hyprland.version")
    print "  · nushell version...";     let nushell_ver   = (nix-eval-raw  $"($flake_ref)#nixosConfigurations.HX99G.pkgs.nushell.version")
    print "  · ghostty version...";     let ghostty_ver   = (nix-eval-raw  $"($flake_ref)#nixosConfigurations.HX99G.pkgs.ghostty.version")
    print "  · fresh-editor version..."; let fresh_ver    = (nix-eval-raw  $"($flake_ref)#nixosConfigurations.HX99G.pkgs.fresh-editor.version")
    # noctalia-shell version from source (pkgs.version is stale nixpkgs metadata)
    print "  · noctalia-shell version..."
    let noctalia_node = ($flake_meta.locks.nodes | get "noctalia-shell")
    let noctalia_rev  = $noctalia_node.locked.rev
    let noctalia_qml  = (
        try {
            ^gh api $"repos/noctalia-dev/noctalia-shell/contents/Services/Noctalia/UpdateService.qml?ref=($noctalia_rev)" --jq '.content'
            | ^base64 -d
        } catch { "" }
    )
    let noctalia_ver  = (
        if ($noctalia_qml | str length) > 0 {
            let base = (
                $noctalia_qml
                | lines
                | where { $in =~ 'readonly property string baseVersion:' }
                | first
                | parse --regex 'baseVersion: "(?P<ver>[^"]+)"'
                | get ver
                | first
            )
            $"v($base)-git"
        } else { "?" }
    )
    print "  · system package count..."; let sys_pkg_count  = (nix-eval-count $"($flake_ref)#nixosConfigurations.HX99G.config.environment.systemPackages")
    print "  · user package count...";   let user_pkg_count = (nix-eval-count $"($flake_ref)#nixosConfigurations.HX99G.config.users.users.weegs.packages")
    let total_pkgs = $sys_pkg_count + $user_pkg_count

    print "  · closure size (slow)..."
    let closure_paths = (try { ^nix path-info --recursive /nix/var/nix/profiles/system | lines | length } catch { 0 })
    let closure_bytes = (try {
        ^nix path-info --recursive --json /nix/var/nix/profiles/system
        | from json | get narSize | math sum
    } catch { 0 })
    let closure_size = if $closure_bytes > 0 { format-bytes $closure_bytes } else { "?" }

    # ── Assemble data record ──────────────────────────────────────────────────
    let d = {
        nixos_version:      "26.05 (Yarara)"
        linux_version:      "6.19.2-cachyos"
        hyprland_ver:       $hyprland_ver
        nushell_ver:        $nushell_ver
        ghostty_ver:        $ghostty_ver
        fresh_ver:          $fresh_ver
        noctalia_ver:       $noctalia_ver
        sys_pkg_count:      $sys_pkg_count
        user_pkg_count:     $user_pkg_count
        total_pkgs:         $total_pkgs
        closure_paths:      $closure_paths
        closure_size:       $closure_size
        shareables_pkgs:    $shareables_pkgs
        total_files:        $total_files
        input_count:        $input_count
        input_groups:       $input_groups
        file_inputs:        $file_inputs
        hjem_files:         $hjem_files
        nixos_files:        $nixos_files
        shareables_files:   $shareables_files
        hosts_files:        $hosts_files
        modules_root_files: $modules_root_files
    }

    # ── Generate and write ────────────────────────────────────────────────────
    let out_dir = $"($dotfiles)/docs/assets"

    print "\n→ Writing anomalOS-overview.svg..."
    generate-overview $d | save --force $"($out_dir)/anomalOS-overview.svg"

    print "→ Writing anomalOS-diagram.svg..."
    generate-diagram $d | save --force $"($out_dir)/anomalOS-diagram.svg"

    print $"\n✓ Done. Files written to ($out_dir)/"
}
