#!/usr/bin/env nu

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
    let model = ($br | parse --regex '(?<m>[0-9]{3,}[A-Za-z]*M)\b' | get -o m.0
        | default ($br | parse --regex '(?<m>[0-9]{3,}[A-Za-z]*)' | get -o m.0 | default ""))
    if ($prefix | is-empty) or ($model | is-empty) { $br } else { $"($prefix) ($model)" }
}

def ov-header [nixos_ver: string linux_ver: string] {
    [
        $"<text x=\"50\" y=\"90\" font-size=\"42\" fill=\"#e8ecf1\" font-weight=\"700\">anomalOS</text>"
        "<rect x=\"290\" y=\"70\" rx=\"6\" width=\"72\" height=\"22\" fill=\"#ff2a22\" opacity=\"0.15\" stroke=\"#ff2a22\" stroke-width=\"0.5\"/>"
        "<text x=\"326\" y=\"85\" font-size=\"10\" fill=\"#ff2a22\" font-weight=\"600\" text-anchor=\"middle\">OVERVIEW</text>"
        $"<text x=\"50\" y=\"120\" font-size=\"15\" fill=\"#aeb3bd\">NixOS ($nixos_ver)  ·  Linux ($linux_ver)</text>"
    ]
}

def ov-top-card [x: int color: string label: string name: string ver: string] {
    [
        $"<rect x=\"($x)\" y=\"185\" rx=\"8\" width=\"196\" height=\"62\" fill=\"#160b0d\" stroke=\"#7a1f26\" stroke-width=\"1\"/>"
        $"<rect x=\"($x + 8)\" y=\"193\" rx=\"2\" width=\"4\" height=\"46\" fill=\"($color)\"/>"
        $"<text x=\"($x + 16)\" y=\"203\" font-size=\"10\" fill=\"#aeb3bd\" font-weight=\"600\" letter-spacing=\"1\">($label)</text>"
        $"<text x=\"($x + 16)\" y=\"221\" font-size=\"15\" fill=\"#e8ecf1\" font-weight=\"600\">($name)</text>"
        $"<text x=\"($x + 16)\" y=\"237\" font-size=\"10\" fill=\"($color)\" opacity=\"1\">($ver)</text>"
    ]
}

def ov-section-box [x: int y: int w: int h: int color: string label: string] {
    [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"12\" width=\"($w)\" height=\"($h)\" fill=\"#160b0d\" stroke=\"#7a1f26\" stroke-width=\"1\"/>"
        $"<rect x=\"($x + 8)\" y=\"($y + 14)\" rx=\"2\" width=\"4\" height=\"($h - 28)\" fill=\"($color)\"/>"
        $"<text x=\"($x + 18)\" y=\"($y + 28)\" font-size=\"13\" fill=\"($color)\" font-weight=\"700\" letter-spacing=\"1\">($label)</text>"
        $"<line x1=\"($x + 14)\" y1=\"($y + 38)\" x2=\"($x + $w - 14)\" y2=\"($y + 38)\" stroke=\"#7a1f26\" stroke-width=\"1\"/>"
    ]
}

def ov-kv [x: int y: int lx: int label: string value: string] {
    [
        $"<text x=\"($x)\" y=\"($y)\" font-size=\"12\" fill=\"#aeb3bd\">($label)</text>"
        $"<text x=\"($lx)\" y=\"($y)\" font-size=\"12\" fill=\"#e8ecf1\">($value)</text>"
    ]
}

def ov-hardware [x: int y: int hw: record] {
    let lx = $x + 150
    [
        ...(ov-section-box $x $y 340 240 "#a9b4c9" "HARDWARE"),
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
        ...(ov-section-box $x $y 340 240 "#eef1f4" "FS"),
        $"<text x=\"($pool_x)\" y=\"($y + 57)\"  font-size=\"12\" fill=\"#e8ecf1\" font-weight=\"600\">zroot</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 75)\"  font-size=\"11\" fill=\"#aeb3bd\">root</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 91)\"  font-size=\"11\" fill=\"#aeb3bd\">persist</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 107)\" font-size=\"11\" fill=\"#aeb3bd\">nix</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 123)\" font-size=\"11\" fill=\"#aeb3bd\">cache</text>"
        $"<text x=\"($pool_x)\" y=\"($y + 143)\" font-size=\"12\" fill=\"#e8ecf1\" font-weight=\"600\">zgames</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 161)\" font-size=\"11\" fill=\"#aeb3bd\">games/{heroic, roms, steam}</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 177)\" font-size=\"11\" fill=\"#aeb3bd\">media</text>"
        $"<text x=\"($pool_x)\" y=\"($y + 197)\" font-size=\"12\" fill=\"#e8ecf1\" font-weight=\"600\">tmpfs</text>"
        $"<text x=\"($dataset_x)\" y=\"($y + 213)\" font-size=\"11\" fill=\"#aeb3bd\">/  ·  256M</text>"
    ]
}

def ov-system [x: int y: int sys: record] {
    let lx = $x + 150
    [
        ...(ov-section-box $x $y 340 240 "#ff6b5c" "SYSTEM"),
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
        ...(ov-section-box $x $y 340 240 "#7b8494" "PACKAGES"),
        ...(ov-kv ($x + 20) ($y + 57)  $lx "System"         ($sys_count | into string)),
        ...(ov-kv ($x + 20) ($y + 77)  $lx "User"           ($user_count | into string)),
        ...(ov-kv ($x + 20) ($y + 97)  $lx "Total declared" ($total | into string)),
        ...(ov-kv ($x + 20) ($y + 117) $lx "Closure paths"  (if $paths > 0 { $"($paths)" } else { "?" })),
        ...(ov-kv ($x + 20) ($y + 137) $lx "Closure size"   $size),
    ]
}

# 240px fits nine 18px rows; longer lists wrap to a new column
def ov-list-card [x: int y: int color: string label: string items: list<string>] {
    let n     = ($items | length)
    let cap   = (((240 - 52 - 10) / 18) | into int)
    let ncols = ([1, ((($n + $cap - 1) / $cap) | into int)] | math max)
    let rows  = ((($n + $ncols - 1) / $ncols) | into int)
    let col_w = (((340 - 40) / $ncols) | into int)
    let arrow = (char -u '25b8')
    let cells = ($items | enumerate | each {|it|
        let cx = $x + 20 + (((($it.index / $rows) | into int)) * $col_w)
        let cy = $y + 52 + (($it.index mod $rows) * 18)
        $"<text x=\"($cx)\" y=\"($cy)\" font-size=\"12\" fill=\"#e8ecf1\">($arrow) ($it.item)</text>"
    })
    [
        ...(ov-section-box $x $y 340 240 $color $label),
        ...$cells,
    ]
}

def ov-wrapped-pkgs [x: int y: int pkgs: list<string>] {
    ov-list-card $x $y "#c6ccd5" "WEEGSWARE" $pkgs
}

def ov-gaming [x: int y: int items: list<string>] {
    ov-list-card $x $y "#e5424d" "GAMING" $items
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
        $"<rect width=\"($w)\" height=\"($h)\" rx=\"16\" fill=\"#000000\"/>"
        "<defs><pattern id=\"grid\" width=\"30\" height=\"30\" patternUnits=\"userSpaceOnUse\">"
        "<circle cx=\"15\" cy=\"15\" r=\"0.5\" fill=\"#7a1f26\" opacity=\"0.2\"/>"
        "</pattern></defs>"
        $"<rect width=\"($w)\" height=\"($h)\" rx=\"16\" fill=\"url\(#grid\)\"/>"
        ...(ov-header (svg-escape $d.nixos_version) (svg-escape $d.linux_version)),
        ...(ov-top-card 70  "#ff2a22" "WM"       "Umbriel"        (svg-escape $d.umbriel_ver)),
        ...(ov-top-card 286 "#c6ccd5" "SHELL"    "nu"             (svg-escape $d.nushell_ver)),
        ...(ov-top-card 502 "#8e96a6" "TERMINAL" "kitty"          (svg-escape $d.kitty_ver)),
        ...(ov-top-card 718 "#e5424d" "EDITOR"   "zed"            (svg-escape $d.zed_ver)),
        ...(ov-top-card 934 "#ff9d98" "UI"       "Noctalia Shell"  (svg-escape $d.noctalia_ver)),
        ...(ov-hardware 70  255 $d.hardware),
        ...(ov-fs       430 255),
        ...(ov-system   790 255 $d.system),
        ...(ov-packages 70  510 $d.sys_pkg_count $d.user_pkg_count $d.total_pkgs $d.closure_paths $d.closure_size),
        ...(ov-wrapped-pkgs 430 510 $pkgs),
        ...(ov-gaming   790 510 $d.gaming),
        "</svg>",
    ] | str join "\n"
}

# 4.2px/char is JetBrains Mono's advance width
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
        "<filter id=\"glow-cyan\"   x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#ff2a22\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-purple\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#8e96a6\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-green\"  x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#c6ccd5\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-yellow\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#e5424d\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-pink\"   x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#e5424d\" flood-opacity=\"0.15\"/></filter>"
        "<pattern id=\"grid\" width=\"30\" height=\"30\" patternUnits=\"userSpaceOnUse\">"
        "<circle cx=\"15\" cy=\"15\" r=\"0.5\" fill=\"#7a1f26\" opacity=\"0.15\"/>"
        "</pattern>"
        "</defs>"
    ]
}

def diag-header [nixos_ver: string total_files: int input_count: int] {
    [
        "<text x=\"50\" y=\"85\" font-size=\"36\" fill=\"#e8ecf1\" font-weight=\"700\">anomalOS</text>"
        "<rect x=\"270\" y=\"68\" rx=\"6\" width=\"106\" height=\"22\" fill=\"#ff2a22\" opacity=\"0.15\" stroke=\"#ff2a22\" stroke-width=\"0.5\"/>"
        "<text x=\"323\" y=\"83\" font-size=\"10\" fill=\"#ff2a22\" font-weight=\"600\" text-anchor=\"middle\">ASSEMBLY</text>"
        $"<text x=\"50\" y=\"112\" font-size=\"14\" fill=\"#aeb3bd\">NixOS ($nixos_ver)  ·  /home/weegs/repo/public/anomalos  ·  ($total_files) files  ·  ($input_count) tack pins</text>"
    ]
}

def solder [cx: int cy: int color: string] {
    $"<circle cx=\"($cx)\" cy=\"($cy)\" r=\"3.5\" fill=\"($color)\" opacity=\"0.85\"/>"
}

# a host with many tags would otherwise run its subtitle past the card edge
def wrap-line [s: string maxchars: int] {
    let words = ($s | split row " " | where { $in != "" })
    mut lines = []
    mut cur = ""
    for word in $words {
        let cand = (if ($cur | is-empty) { $word } else { $"($cur) ($word)" })
        if (($cand | str length) > $maxchars) and (not ($cur | is-empty)) {
            $lines = ($lines | append $cur)
            $cur = $word
        } else {
            $cur = $cand
        }
    }
    if not ($cur | is-empty) { $lines = ($lines | append $cur) }
    $lines
}

def cable [pts: list<any> color: string width: number] {
    let r = 9
    let n = ($pts | length)
    mut d = $"M ($pts | get 0 | get x) ($pts | get 0 | get y)"
    if $n <= 2 {
        $d = $d + $" L ($pts | get 1 | get x) ($pts | get 1 | get y)"
    } else {
        for i in 1..($n - 2) {
            let p  = ($pts | get ($i - 1))
            let v  = ($pts | get $i)
            let nx = ($pts | get ($i + 1))
            let ux = (if $v.x == $p.x { 0 } else if $v.x > $p.x { 1 } else { -1 })
            let uy = (if $v.y == $p.y { 0 } else if $v.y > $p.y { 1 } else { -1 })
            let wx = (if $nx.x == $v.x { 0 } else if $nx.x > $v.x { 1 } else { -1 })
            let wy = (if $nx.y == $v.y { 0 } else if $nx.y > $v.y { 1 } else { -1 })
            let bx = ($v.x - ($ux * $r))
            let by = ($v.y - ($uy * $r))
            let ax = ($v.x + ($wx * $r))
            let ay = ($v.y + ($wy * $r))
            $d = $d + $" L ($bx) ($by) Q ($v.x) ($v.y) ($ax) ($ay)"
        }
        let last = ($pts | get ($n - 1))
        $d = $d + $" L ($last.x) ($last.y)"
    }
    $"<path d=\"($d)\" fill=\"none\" stroke=\"($color)\" stroke-width=\"($width)\" stroke-linecap=\"round\" stroke-linejoin=\"round\" opacity=\"0.7\"/>"
}

def diag-pin-card [x: int y: int w: int h: int pin: record] {
    let color = $pin.color
    let badge = $pin.status_label
    let bw    = (pill-w $badge)
    [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"9\" width=\"($w)\" height=\"($h)\" fill=\"#160b0d\" stroke=\"#7a1f26\" stroke-width=\"1.5\"/>"
        $"<rect x=\"($x + 4)\" y=\"($y + 9)\" rx=\"3\" width=\"4\" height=\"($h - 18)\" fill=\"($color)\"/>"
        $"<circle cx=\"($x + 22)\" cy=\"($y + 21)\" r=\"5\" fill=\"($color)\" opacity=\"0.25\"/>"
        $"<circle cx=\"($x + 22)\" cy=\"($y + 21)\" r=\"3\" fill=\"($color)\"/>"
        $"<text x=\"($x + 36)\" y=\"($y + 25)\" font-size=\"13\" fill=\"#e8ecf1\" font-weight=\"700\">($pin.name)</text>"
        $"<text x=\"($x + 36)\" y=\"($y + 43)\" font-size=\"9\" fill=\"#aeb3bd\" opacity=\"0.85\">($pin.repo)</text>"
        $"<rect x=\"($x + $w - $bw - 10)\" y=\"($y + 9)\" rx=\"5\" width=\"($bw)\" height=\"15\" fill=\"#7a1f26\" opacity=\"0.22\"/>"
        $"<text x=\"($x + $w - ($bw / 2 | into int) - 10)\" y=\"($y + 19)\" font-size=\"8\" fill=\"#c6ccd5\" font-weight=\"600\" text-anchor=\"middle\">($badge)</text>"
    ]
}

def diag-pin-block [x: int y: int w: int pins: list<record>] {
    let cols    = 3
    let card_w  = 300
    let card_h  = 56
    let n       = ($pins | length)
    let rows    = ((($n + $cols - 1) / $cols) | into int)
    let gap_x   = ((($w - 40 - ($cols * $card_w)) / ($cols - 1)) | into int)
    let gap_y   = 16
    let pad_top = 46
    let h       = $pad_top + ($rows * $card_h) + (($rows - 1) * $gap_y) + 18

    let panel = [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"14\" width=\"($w)\" height=\"($h)\" fill=\"#0b0506\" stroke=\"#7a1f26\" stroke-width=\"1.5\"/>"
        $"<text x=\"($x + 24)\" y=\"($y + 30)\" font-size=\"14\" fill=\"#e8ecf1\" font-weight=\"700\" letter-spacing=\"2\">TACK PINS</text>"
        $"<text x=\"($x + $w - 24)\" y=\"($y + 30)\" font-size=\"11\" fill=\"#aeb3bd\" opacity=\"0.85\" text-anchor=\"end\">.tack/pins.toml</text>"
        $"<line x1=\"($x + 22)\" y1=\"($y + 40)\" x2=\"($x + $w - 22)\" y2=\"($y + 40)\" stroke=\"#3d414b\" stroke-width=\"1\"/>"
    ]

    let cards = ($pins | enumerate | each {|it|
        let col = ($it.index mod $cols)
        let row = (($it.index / $cols) | into int)
        let cx  = $x + 20 + ($col * ($card_w + $gap_x))
        let cy  = $y + $pad_top + ($row * ($card_h + $gap_y))
        diag-pin-card $cx $cy $card_w $card_h $it.item
    } | flatten)

    { elems: ([$panel, $cards] | flatten), height: $h, center: ($x + (($w / 2) | into int)) }
}

def group-dirs [files: list<string>] {
    let roots  = ($files | where { not ($in | str contains "/") } | sort | each {|f| { label: $f, key: $f } })
    let nested = ($files | where { $in | str contains "/" } | sort)
    let dirs   = ($nested | each { $in | split row "/" | first } | uniq)
    let groups = ($dirs | each {|d|
        let fs = ($nested | where { ($in | split row "/" | first) == $d } | each {|f|
            { label: ($f | str substring (($d | str length) + 1)..), key: $f }
        })
        { dir: $"($d)/", files: $fs }
    })
    { roots: $roots, groups: $groups }
}

def diag-dir-card [x: int y: int w: int title: string path: string files: list<record> file_inputs: record pin_hues: record accent: string subtitle: string = ""] {
    let n      = ($files | length)
    # 6.2px/char is JetBrains Mono's advance at 10px
    let sub_lines = (if ($subtitle | is-empty) { [] } else { wrap-line $subtitle ((($w - 34) / 6.2) | into int) })
    let head_h = (if ($sub_lines | is-empty) { 32 } else { 32 + (($sub_lines | length) * 15) })
    let h      = $head_h + ($n * 22) + 14

    let card = ([
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"10\" width=\"($w)\" height=\"($h)\" fill=\"#160b0d\" stroke=\"#7a1f26\" stroke-width=\"1.5\"/>"
        $"<rect x=\"($x + 4)\" y=\"($y + 8)\" rx=\"3\" width=\"4\" height=\"($h - 16)\" fill=\"($accent)\"/>"
        $"<text x=\"($x + 18)\" y=\"($y + 21)\" font-size=\"14\" fill=\"#e8ecf1\" font-weight=\"700\">($title)</text>"
        ($sub_lines | enumerate | each {|it|
            $"<text x=\"($x + 18)\" y=\"($y + 37 + ($it.index * 14))\" font-size=\"10\" fill=\"($accent)\" opacity=\"1\">($it.item)</text>"
        })
    ] | flatten)

    let items = ($files | enumerate | each {|it|
        let f        = $it.item
        let iy       = $y + $head_h + 16 + ($it.index * 22)
        let file_key = $"($path)/($f.key)"
        let consumed = ($file_inputs | get -o $file_key | default [])
        let dot        = $"<text x=\"($x + 18)\" y=\"($iy)\" font-size=\"9\" fill=\"($accent)\" opacity=\"0.9\">●</text><text x=\"($x + 32)\" y=\"($iy)\" font-size=\"13\" fill=\"#c6ccd5\">($f.label)</text>"
        if ($consumed | is-empty) {
            [$dot]
        } else {
            mut tags = []
            mut tx = $x + $w - 12
            for inp in ($consumed | reverse) {
                let tw    = ((($inp | str length) * 5.6 + 16) | math round)
                $tx       = $tx - $tw - 4
                let hue   = ($pin_hues | get -o $inp | default "#aeb3bd")
                let tcx   = $tx + (($tw / 2) | into int)
                $tags = ($tags | append [
                    $"<rect x=\"($tx)\" y=\"($iy - 12)\" rx=\"4\" width=\"($tw)\" height=\"17\" fill=\"($hue)\" opacity=\"0.92\"/>"
                    $"<text x=\"($tcx)\" y=\"($iy)\" font-size=\"9\" fill=\"#000000\" font-weight=\"700\" text-anchor=\"middle\">($inp)</text>"
                ])
            }
            [[$dot], ($tags | flatten)] | flatten
        }
    } | flatten)

    { elems: ([$card, $items] | flatten), height: $h }
}

def diag-bundle-column [colx: int top_y: int w: int ncols: int label: string path: string files: list<string> file_inputs: record pin_hues: record unit: string annotations: record = {}] {
    let pad       = 16
    let inner_gap = 14
    let title_h   = 56
    let card_w    = ((($w - (2 * $pad) - (($ncols - 1) * $inner_gap)) / $ncols) | into int)
    let n         = ($files | length)
    let plural    = if $n == 1 { "" } else { "s" }
    let grouped   = (group-dirs $files)
    let hdr_cx    = $colx + (($w / 2) | into int)
    # distinct accent per subdir so sibling cards are distinguishable
    let dir_accents = ["#ff2a22" "#c6ccd5" "#8e96a6" "#e5424d" "#eef1f4" "#ff9d98" "#ff6b5c" "#a9b4c9" "#7b8494"]

    # subdir names alone are ambiguous across bundles
    let cards = ([
        (if (($grouped.roots | length) > 0) { [{ title: $"($label)/", files: $grouped.roots, subtitle: "" }] } else { [] })
        ($grouped.groups | each {|g|
            let key = ($g.dir | str trim --right --char "/")
            { title: $"($label)/($g.dir)", files: $g.files, subtitle: ($annotations | get -o $key | default "") }
        })
    ] | flatten)

    mut dir_elems = []
    mut col_ys = (0..($ncols - 1) | each { $top_y + $title_h })
    for it in ($cards | enumerate) {
        let a  = ($dir_accents | get ($it.index mod ($dir_accents | length)))
        let ci = ($col_ys | enumerate | sort-by item | first | get index)
        let cx = $colx + $pad + ($ci * ($card_w + $inner_gap))
        let cy = ($col_ys | get $ci)
        let dc = (diag-dir-card $cx $cy $card_w $it.item.title $path $it.item.files $file_inputs $pin_hues $a $it.item.subtitle)
        $dir_elems = ($dir_elems | append $dc.elems)
        $col_ys = ($col_ys | update $ci ($cy + $dc.height + 14))
    }
    let container_h = (($col_ys | math max) - $top_y)

    let container = [
        $"<rect x=\"($colx)\" y=\"($top_y)\" rx=\"14\" width=\"($w)\" height=\"($container_h)\" fill=\"#0b0506\" stroke=\"#7a1f26\" stroke-width=\"2\"/>"
        $"<text x=\"($colx + 20)\" y=\"($top_y + 30)\" font-size=\"16\" fill=\"#e8ecf1\" font-weight=\"700\">($label)</text>"
        $"<text x=\"($colx + 20)\" y=\"($top_y + 47)\" font-size=\"10\" fill=\"#aeb3bd\">($path)  ·  ($n) ($unit)($plural)</text>"
    ]

    { elems: ([$container, $dir_elems] | flatten), bottom: ($top_y + $container_h), center: $hdr_cx }
}

def diag-legend [y: int cx: int pins: list<record> total_files: int input_count: int] {
    let per_row = 5
    let item_w  = 230
    let row_h   = 34
    let grid_w  = $per_row * $item_w
    let startx  = $cx - (($grid_w / 2) | into int) + 24

    let swatches = ($pins | enumerate | each {|it|
        let r  = (($it.index / $per_row) | into int)
        let c  = ($it.index mod $per_row)
        let ix = $startx + ($c * $item_w)
        let ry = $y + 54 + ($r * $row_h)
        let p  = $it.item
        [
            $"<rect x=\"($ix)\" y=\"($ry - 13)\" rx=\"3\" width=\"17\" height=\"17\" fill=\"($p.hue)\"/>"
            $"<text x=\"($ix + 26)\" y=\"($ry)\" font-size=\"15\" fill=\"#e8ecf1\">($p.name)</text>"
        ]
    } | flatten)

    let rows = (((($pins | length) + $per_row - 1) / $per_row) | into int)
    [
        $"<text x=\"($cx)\" y=\"($y)\" font-size=\"17\" fill=\"#e8ecf1\" font-weight=\"700\" letter-spacing=\"2\" text-anchor=\"middle\">COLOR KEY</text>"
        $"<text x=\"($cx)\" y=\"($y + 24)\" font-size=\"13\" fill=\"#aeb3bd\" text-anchor=\"middle\">a tag on a file wears the color of the pin it pulls in  ·  untagged files ride on plain nixpkgs</text>"
        ...$swatches,
        $"<text x=\"($cx)\" y=\"($y + 54 + ($rows * $row_h) + 10)\" font-size=\"13\" fill=\"#aeb3bd\" opacity=\"0.7\" text-anchor=\"middle\">($total_files) files  ·  ($input_count) tack pins</text>"
    ]
}

def diag-node [x: int y: int w: int color: string title: string sub: string] {
    [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"12\" width=\"($w)\" height=\"54\" fill=\"#160b0d\" stroke=\"#7a1f26\" stroke-width=\"1.5\"/>"
        $"<rect x=\"($x + 4)\" y=\"($y + 9)\" rx=\"3\" width=\"4\" height=\"36\" fill=\"($color)\"/>"
        $"<circle cx=\"($x + 24)\" cy=\"($y + 22)\" r=\"5\" fill=\"($color)\" opacity=\"0.25\"/>"
        $"<circle cx=\"($x + 24)\" cy=\"($y + 22)\" r=\"3\" fill=\"($color)\"/>"
        $"<text x=\"($x + 38)\" y=\"($y + 26)\" font-size=\"14\" fill=\"#e8ecf1\" font-weight=\"700\">($title)</text>"
        $"<text x=\"($x + 38)\" y=\"($y + 43)\" font-size=\"10\" fill=\"($color)\" opacity=\"1\">($sub)</text>"
    ]
}

def generate-diagram [d: record] {
    let canvas_w = 1500
    let spine_x  = ($canvas_w / 2 | into int)   # everything hangs off the vertical centerline

    let pin_x = 250
    let pin_y = 140
    let pin_w = 1000
    let pb    = (diag-pin-block $pin_x $pin_y $pin_w $d.pins)
    let pin_bottom = $pin_y + $pb.height

    let node_w   = 260
    let node_cx  = $spine_x
    let node_x   = $node_cx - ($node_w / 2 | into int)

    let tack_y     = $pin_bottom + 48
    let assemble_y = $tack_y + 100

    let spine = [
        ...(diag-node $node_x $tack_y $node_w "#ff2a22" ".tack" "pins → resolver"),
        ...(diag-node $node_x $assemble_y $node_w "#ff2a22" "assemble.nix" "nixosSystem + packages"),
    ]

    let spine_cables = [
        (cable [{x: $node_cx, y: $pin_bottom} {x: $node_cx, y: $tack_y}] "#ff2a22" 3)
        (cable [{x: $node_cx, y: ($tack_y + 54)} {x: $node_cx, y: $assemble_y}] "#ff2a22" 3)
    ]

    let ep_w   = 236
    let ep_h   = 54
    let ep_gap = 12
    let ep_x   = $node_x + $node_w + 150
    let ep_cx  = $ep_x + (($ep_w / 2) | into int)
    let ep_defs = [
        { t: "flake.nix",    s: "nix build .#" }
        { t: "repl.nix",     s: "nix repl" }
        { t: "devshell.nix", s: "nix-shell" }
        { t: "ci.nix",       s: "nix-build → toplevel" }
    ]
    let ep_n     = ($ep_defs | length)
    let ep_total = ($ep_n * $ep_h) + (($ep_n - 1) * $ep_gap)
    let ep_top   = ($assemble_y + 27) - (($ep_total / 2) | into int)
    let ep_ys    = ($ep_defs | enumerate | each {|it| $ep_top + ($it.index * ($ep_h + $ep_gap)) })

    let ep_nodes = ($ep_defs | enumerate | each {|it|
        diag-node $ep_x ($ep_ys | get $it.index) $ep_w "#c6ccd5" $it.item.t $it.item.s
    } | flatten)

    let asm_rx     = $node_x + $node_w
    let asm_cy     = $assemble_y + 27
    let ep_exit_ys = [($asm_cy - 24) ($asm_cy - 8) ($asm_cy + 8) ($asm_cy + 24)]
    # outer cables take the near lane to avoid crossings
    let ep_lane_xs = [($asm_rx + 34) ($asm_rx + 70) ($asm_rx + 70) ($asm_rx + 34)]
    let ep_cables = [
        $"<text x=\"($ep_x)\" y=\"($ep_top - 14)\" font-size=\"11\" fill=\"#c6ccd5\" font-weight=\"700\" letter-spacing=\"1\">ENTRYPOINTS</text>"
        $"<text x=\"($ep_x + 108)\" y=\"($ep_top - 14)\" font-size=\"10\" fill=\"#aeb3bd\">consume assemble.nix</text>"
        ...(0..3 | each {|i|
            let sy = ($ep_exit_ys | get $i)
            let lx = ($ep_lane_xs | get $i)
            let ey = (($ep_ys | get $i) + 27)
            (cable [{x: $asm_rx, y: $sy} {x: $lx, y: $sy} {x: $lx, y: $ey} {x: $ep_x, y: $ey}] "#c6ccd5" 3)
        })
    ]

    # offset clears the entrypoint cluster above
    let mod_top  = ([($assemble_y + 54 + 80), ($ep_top + $ep_total + 70)] | math max)
    let pin_hues = ($d.pins | reduce --fold {} {|p, acc| $acc | upsert $p.name $p.hue })

    # centered gap keeps the fan exits symmetric
    let gw   = 672
    let lgx  = 40
    let rgx  = 788
    let lcx  = $lgx + (($gw / 2) | into int)
    let rcx  = $rgx + (($gw / 2) | into int)

    let hosts_col  = (diag-bundle-column $lgx $mod_top $gw 2 "hosts" "modules/hosts" $d.hosts_files $d.file_inputs $pin_hues "file" $d.host_meta)
    let user_top   = ($hosts_col.bottom + 40)
    let user_col   = (diag-bundle-column $lgx $user_top $gw 2 "user-level" "modules/user-level" $d.user_files $d.file_inputs $pin_hues "file")

    let weegs_col  = (diag-bundle-column $rgx $mod_top $gw 1 "weegsware" "./weegsware" $d.weegsware_pkgs {} $pin_hues "pkg")
    let system_top = ($weegs_col.bottom + 40)
    let system_col = (diag-bundle-column $rgx $system_top $gw 2 "system-level" "modules/system-level" $d.system_files $d.file_inputs $pin_hues "file")

    let col_elems  = ([$hosts_col.elems $user_col.elems $weegs_col.elems $system_col.elems] | flatten)
    let max_bottom = ([$user_col.bottom $system_col.bottom] | math max)

    let asm_by   = $assemble_y + 54
    let lane_h   = $mod_top - 32
    let lane_ul  = $user_top - 26
    let lane_sl  = $system_top - 26
    # shared so the exit solders cannot drift from the cables they cap
    let fan_xs = [726 742 758 774]
    let fan_cables = [
        (cable [{x: ($fan_xs | get 0), y: $asm_by} {x: ($fan_xs | get 0), y: $lane_h}  {x: $lcx, y: $lane_h}  {x: $lcx, y: $mod_top}]   "#e5424d" 3)
        (cable [{x: ($fan_xs | get 1), y: $asm_by} {x: ($fan_xs | get 1), y: $lane_ul} {x: $lcx, y: $lane_ul} {x: $lcx, y: $user_top}]  "#e5424d" 3)
        (cable [{x: ($fan_xs | get 2), y: $asm_by} {x: ($fan_xs | get 2), y: $lane_sl} {x: $rcx, y: $lane_sl} {x: $rcx, y: $system_top}] "#e5424d" 3)
        (cable [{x: ($fan_xs | get 3), y: $asm_by} {x: ($fan_xs | get 3), y: $lane_h}  {x: $rcx, y: $lane_h}  {x: $rcx, y: $mod_top}]   "#e5424d" 3)
    ]

    # solder must draw after its node to land on top
    let all_solders = [
        (solder $node_cx $pin_bottom "#ff2a22")
        (solder $node_cx $tack_y "#ff2a22")
        (solder $node_cx ($tack_y + 54) "#ff2a22")
        (solder $node_cx $assemble_y "#ff2a22")
        ...(0..3 | each {|i| (solder $asm_rx ($ep_exit_ys | get $i) "#c6ccd5") })
        ...(0..3 | each {|i| (solder $ep_x (($ep_ys | get $i) + 27) "#c6ccd5") })
        ...($fan_xs | each {|fx| (solder $fx $asm_by "#e5424d") })
        (solder $lcx $mod_top "#e5424d")
        (solder $lcx $user_top "#e5424d")
        (solder $rcx $mod_top "#e5424d")
        (solder $rcx $system_top "#e5424d")
    ]

    let legend_y = $max_bottom + 60
    let canvas_h = $legend_y + 170
    let center_x = $spine_x

    [
        $"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"($canvas_w)\" height=\"($canvas_h)\" viewBox=\"0 0 ($canvas_w) ($canvas_h)\">"
        ...(diag-defs),
        $"<rect width=\"($canvas_w)\" height=\"($canvas_h)\" rx=\"16\" fill=\"#000000\"/>"
        $"<rect width=\"($canvas_w)\" height=\"($canvas_h)\" rx=\"16\" fill=\"url\(#grid\)\"/>"
        ...(diag-header (svg-escape $d.nixos_version) $d.total_files $d.input_count),
        ...$pb.elems,
        ...$spine_cables,
        ...$ep_cables,
        ...$fan_cables,
        ...$spine,
        ...$ep_nodes,
        ...$col_elems,
        ...$all_solders,
        ...(diag-legend $legend_y $center_x $d.pins $d.total_files $d.input_count),
        "</svg>",
    ] | str join "\n"
}

def classify-inputs [pins: record] {
    let inputs         = ($pins.inputs)
    let names          = ($inputs | columns)
    let follow_targets = ($pins.all_follow? | default {} | columns)
    # ordered so adjacent pins stay distinct
    let hue_pool = ["#ff2a22" "#e5424d" "#c6ccd5" "#8e96a6" "#eef1f4" "#ff9d98" "#a9b4c9" "#ff6b5c" "#7b8494"]

    $names | each {|name|
        let pin  = ($inputs | get $name)
        let url  = ($pin.url? | default "")
        let excl = ($pin.exclude_follow? | default [])
        let repo = (
            $url
            | str replace 'gh:' '' | str replace 'cb:' ''
            | str replace 'github:' '' | str replace 'git+https://' ''
        )

        let is_root     = ($name in $follow_targets)
        let is_excluded = (($follow_targets | length) > 0) and ($follow_targets | all {|t| $t in $excl })

        let status = if $is_root { "root" } else if $is_excluded { "standalone" } else { "follows" }
        let rank   = if $is_root { 0 } else if $is_excluded { 2 } else { 1 }

        { name: $name, repo: $repo, status: $status, status_label: $status, rank: $rank }
    }
    | sort-by rank name
    # consumer pills reuse the pin hue so a pin is traceable by color
    | enumerate | each {|it|
        let hue = ($hue_pool | get ($it.index mod ($hue_pool | length)))
        $it.item | merge { color: $hue, hue: $hue }
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

def main [] {
    if not ("CURRENT_FILE" in $env) {
        error make { msg: "CURRENT_FILE not set -- run this script directly: nu lib/scripts/draw.nu" }
    }

    print "⚠  Remember: run `jj s` in anomalos first -- snapshot the working copy before regenerating committed SVGs.\n"

    let dotfiles = ($env.CURRENT_FILE | path dirname | path join ".." ".." | path expand)

    print "→ Collecting repo data..."

    let user_files = (
        glob $"($dotfiles)/modules/user-level/**/*.nix"
        | each { $in | path relative-to $"($dotfiles)/modules/user-level" }
        | sort
    )
    let system_files = (
        glob $"($dotfiles)/modules/system-level/**/*.nix"
        | each { $in | path relative-to $"($dotfiles)/modules/system-level" }
        | sort
    )
    let hosts_files = (
        glob $"($dotfiles)/modules/hosts/**/*.nix"
        | each { $in | path relative-to $"($dotfiles)/modules/hosts" }
        | sort
    )
    # metadata.nix is a bare attrset, so it evals without a full system eval
    let host_meta = (
        glob $"($dotfiles)/modules/hosts/*/metadata.nix"
        | reduce --fold {} {|f, acc|
            let name = ($f | path dirname | path basename)
            let m = (try { ^nix eval --json --file $f | from json } catch { {} })
            let sys = ($m | get -o system | default "?")
            let tags = ($m | get -o tags | default [] | str join ", ")
            $acc | insert $name (if ($tags | is-empty) { $sys } else { $"($sys)  ·  ($tags)" })
        }
    )
    let user_count         = ($user_files | length)
    let system_count       = ($system_files | length)
    let hosts_count        = ($hosts_files | length)
    let total_files        = $user_count + $system_count + $hosts_count

    print "→ Classifying tack pins..."
    let pins        = (open $"($dotfiles)/.tack/pins.toml")
    let lock        = (open $"($dotfiles)/.tack/pins.lock.json")
    let all_inputs  = ($pins.inputs | columns)
    let input_count = ($all_inputs | length)

    let pin_list = (classify-inputs $pins)

    print "→ Mapping input consumers..."
    let file_inputs = (find-input-consumers $dotfiles $all_inputs)

    print "→ Collecting system data (30-90s per eval call)..."

    let assemble = $"($dotfiles)/assemble.nix"

    # the compositor is a flake input, not a nixpkgs attr, and meson.build now defers to a VERSION file
    print "  · umbriel version..."
    let umbriel_rev = ($lock | get "umbriel" | get rev)
    let umbriel_raw = (
        try {
            ^gh api $"repos/noctalia-dev/umbriel/contents/VERSION?ref=($umbriel_rev)" --jq '.content'
            | ^base64 -d
        } catch { "" }
    )
    let umbriel_ver = (
        if (($umbriel_raw | str trim | str length) > 0) {
            $"v(($umbriel_raw | str trim))"
        } else { "?" }
    )
    print "  · nushell version...";      let nushell_ver   = (nix-eval-raw  $assemble "nixosConfigurations.HX99G.pkgs.nushell.version")
    print "  · kitty version...";        let kitty_ver     = (nix-eval-raw  $assemble "nixosConfigurations.HX99G.pkgs.kitty.version")
    print "  · zed version..."; let zed_ver = (nix-eval-raw $assemble "nixosConfigurations.HX99G.pkgs.zed-editor.version")
    # read at the locked rev because pkgs.version is stale nixpkgs metadata; meson.build now defers to a VERSION file
    print "  · noctalia version..."
    let noctalia_rev  = ($lock | get "noctalia" | get rev)
    let noctalia_raw = (
        try {
            ^gh api $"repos/noctalia-dev/noctalia/contents/VERSION?ref=($noctalia_rev)" --jq '.content'
            | ^base64 -d
        } catch { "" }
    )
    let noctalia_ver  = (
        if (($noctalia_raw | str trim | str length) > 0) {
            $"v(($noctalia_raw | str trim))"
        } else { "?" }
    )
    print "  · system package count..."; let sys_pkg_count  = (nix-eval-count $assemble "nixosConfigurations.HX99G.config.environment.systemPackages")
    print "  · user package count...";   let user_pkg_count = (nix-eval-count $assemble "nixosConfigurations.HX99G.config.users.users.weegs.packages")
    let total_pkgs = $sys_pkg_count + $user_pkg_count

    print "  · closure size (slow)..."
    let closure_paths = (try { ^nix path-info --recursive /nix/var/nix/profiles/system | lines | length } catch { 0 })
    # nix --json is now a record keyed by store path (format 1); pull the values before summing
    let closure_bytes = (try {
        ^nix path-info --recursive --json --json-format 1 /nix/var/nix/profiles/system
        | from json | values | get narSize | math sum
    } catch { 0 })
    let closure_size = if $closure_bytes > 0 { format-bytes $closure_bytes } else { "?" }

    print "  · nixos version...";   let nixos_release   = (nix-eval-raw $assemble "nixosConfigurations.HX99G.config.system.nixos.release")
    print "  · nixos codename...";  let nixos_codename  = (nix-eval-raw $assemble "nixosConfigurations.HX99G.config.system.nixos.codeName")
    print "  · kernel version...";  let linux_version   = (nix-eval-raw $assemble "nixosConfigurations.HX99G.config.boot.kernelPackages.kernel.modDirVersion")
    let nixos_version = $"($nixos_release) \(($nixos_codename)\)"

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
        # umbriel outputs has no json mode, so the active mode is read off the (current) tag
        monitor: (try {
            ^umbriel outputs
            | lines
            | where { $in =~ '\(current\)' }
            | each {|l|
                let m = ($l | parse --regex '(?<w>[0-9]+)x(?<h>[0-9]+) @ (?<r>[0-9.]+)' | first)
                $"($m.w)(char -u 'd7')($m.h) @ (($m.r | into float) | math round)Hz"
            }
            | str join ", "
        } catch { "?" })
    }

    print "→ Evaluating system / gaming / weegsware..."
    let dm = (["noctalia-greeter" "ly" "gdm" "sddm"] | where {|d|
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

    let weegsware_pkgs = (try { ^nix eval --impure --json -f $assemble packages.x86_64-linux --apply 'builtins.attrNames' | from json } catch { [] } | sort)

    # gaming modules are a mix of gaming/<name>/<name>.nix dirs + gaming/*.nix files -- catch both
    let gmods = (
        glob $"($dotfiles)/modules/user-level/gaming/*"
        | each {|p| if ($p | path type) == "dir" { $p | path basename } else { $p | path parse | get stem } }
        | uniq | sort
    )
    mut gaming = $gmods
    if (nix-eval-bool $assemble "nixosConfigurations.HX99G.config.programs.gamescope.enable") { $gaming = ($gaming | append "gamescope") }
    if (nix-eval-bool $assemble "nixosConfigurations.HX99G.config.programs.gamemode.enable") { $gaming = ($gaming | append "gamemode") }

    let d = {
        nixos_version:      $nixos_version
        linux_version:      $linux_version
        umbriel_ver:        $umbriel_ver
        nushell_ver:        $nushell_ver
        kitty_ver:          $kitty_ver
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
        pins:               $pin_list
        file_inputs:        $file_inputs
        user_files:         $user_files
        system_files:       $system_files
        hosts_files:        $hosts_files
        host_meta:          $host_meta
    }

    let out_dir = $"($dotfiles)/assets"

    print "\n→ Writing anomalOS-overview.svg..."
    generate-overview $d | save --force $"($out_dir)/anomalOS-overview.svg"

    print "→ Writing anomalOS-diagram.svg..."
    generate-diagram $d | save --force $"($out_dir)/anomalOS-diagram.svg"

    print $"\n✓ Done. Files written to ($out_dir)/"
}
