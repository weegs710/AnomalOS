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
        $"<rect width=\"($w)\" height=\"($h)\" rx=\"16\" fill=\"url(#grid)\"/>"
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

# Compute the height of a module box given its file count
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
        "<filter id=\"glow-blue\"   x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#9071f4\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-green\"  x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#37f499\" flood-opacity=\"0.15\"/></filter>"
        "<filter id=\"glow-orange\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#e9f941\" flood-opacity=\"0.15\"/></filter>"
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

# One flake input card (260×60)
def diag-input-card [x: int y: int name: string repo: string] {
    [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"12\" width=\"260\" height=\"60\" fill=\"#212337\" stroke=\"#9071f4\" stroke-width=\"1.5\" filter=\"url(#glow-blue)\"/>"
        $"<rect x=\"($x + 3)\" y=\"($y + 10)\" rx=\"3\" width=\"4\" height=\"40\" fill=\"#9071f4\"/>"
        $"<circle cx=\"($x + 22)\" cy=\"($y + 22)\" r=\"7\" fill=\"#9071f4\" opacity=\"0.2\"/>"
        $"<circle cx=\"($x + 22)\" cy=\"($y + 22)\" r=\"4\" fill=\"#9071f4\"/>"
        $"<text x=\"($x + 38)\" y=\"($y + 26)\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">($name)</text>"
        $"<text x=\"($x + 42)\" y=\"($y + 42)\" font-size=\"10\" fill=\"#9071f4\" opacity=\"0.7\">Flake Input</text>"
        $"<text x=\"($x + 42)\" y=\"($y + 53)\" font-size=\"8\" fill=\"#abb4da\" opacity=\"0.5\">($repo)</text>"
    ]
}

# Module box: absolute coordinates, width=300
def diag-module-box [x: int y: int label: string path: string files: list<string> color: string filter_id: string] {
    let n          = ($files | length)
    let h          = (box-height $n)
    let badge_x    = $x + 248
    let badge_cx   = $x + 270
    let badge_text = if $n == 1 { "1 file" } else { $"($n) files" }

    let header = [
        $"<rect x=\"($x)\" y=\"($y)\" rx=\"12\" width=\"300\" height=\"($h)\" fill=\"#212337\" stroke=\"($color)\" stroke-width=\"1.5\" filter=\"url(#($filter_id))\"/>"
        $"<rect x=\"($x + 3)\" y=\"($y + 10)\" rx=\"3\" width=\"4\" height=\"($h - 20)\" fill=\"($color)\"/>"
        $"<circle cx=\"($x + 22)\" cy=\"($y + 22)\" r=\"7\" fill=\"($color)\" opacity=\"0.2\"/>"
        $"<circle cx=\"($x + 22)\" cy=\"($y + 22)\" r=\"4\" fill=\"($color)\"/>"
        $"<text x=\"($x + 38)\" y=\"($y + 26)\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">($label)</text>"
        $"<rect x=\"($badge_x)\" y=\"($y + 6)\" rx=\"8\" width=\"44\" height=\"18\" fill=\"($color)\" opacity=\"0.18\"/>"
        $"<text x=\"($badge_cx)\" y=\"($y + 19)\" font-size=\"10\" fill=\"($color)\" font-weight=\"600\" text-anchor=\"middle\">($badge_text)</text>"
        $"<text x=\"($x + 46)\" y=\"($y + 41)\" font-size=\"10\" fill=\"($color)\" opacity=\"0.6\">($path)</text>"
        $"<line x1=\"($x + 12)\" y1=\"($y + 46)\" x2=\"($x + 288)\" y2=\"($y + 46)\" stroke=\"($color)\" stroke-width=\"0.5\" opacity=\"0.2\"/>"
    ]

    let items = ($files | enumerate | each {|it|
        let iy = $y + 60 + ($it.index * 18)
        $"<text x=\"($x + 16)\" y=\"($iy)\" font-size=\"8\" fill=\"($color)\" opacity=\"0.4\">●</text><text x=\"($x + 28)\" y=\"($iy)\" font-size=\"10\" fill=\"#abb4da\">($it.item)</text>"
    })

    [$header, $items] | flatten
}

def diag-legend [y: int total_files: int input_count: int] {
    [
        $"<circle cx=\"412\" cy=\"($y)\" r=\"5\" fill=\"#04d1f9\"/>"
        $"<text x=\"424\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Flake Root</text>"
        $"<circle cx=\"567\" cy=\"($y)\" r=\"5\" fill=\"#9071f4\"/>"
        $"<text x=\"579\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Flake Input</text>"
        $"<circle cx=\"722\" cy=\"($y)\" r=\"5\" fill=\"#37f499\"/>"
        $"<text x=\"734\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Nix REPL</text>"
        $"<circle cx=\"877\" cy=\"($y)\" r=\"5\" fill=\"#e9f941\"/>"
        $"<text x=\"889\" y=\"($y + 4)\" font-size=\"11\" fill=\"#abb4da\">Module</text>"
        $"<text x=\"716\" y=\"($y + 35)\" font-size=\"12\" fill=\"#abb4da\" text-anchor=\"middle\">($total_files) files  ·  ($input_count) flake inputs</text>"
    ]
}

def generate-diagram [d: record] {
    let canvas_w = 1432

    # ── Module file lists ────────────────────────────────────────────────────
    let hjem_files       = $d.hjem_files
    let nixos_files      = $d.nixos_files
    let shareables_files = $d.shareables_files
    let hosts_files      = ["rig.nix"]     # show only the active host config
    let modules_root     = ["devshell.nix"]

    # ── Box positions (absolute) ─────────────────────────────────────────────
    let mod_x  = 80;    let mod_y  = 598
    let hjem_x = 404;   let hjem_y = 598
    let host_x = 728;   let host_y = 598
    let nxos_x = 1052;  let nxos_y = 598
    let shar_x = 80

    let mod_bottom  = $mod_y + (box-height ($modules_root | length))
    let shar_y      = $mod_bottom + 26   # shareables sits just below modules root box

    let hjem_bottom = $hjem_y + (box-height ($hjem_files | length))
    let nxos_bottom = $nxos_y + (box-height ($nixos_files | length))
    let shar_bottom = $shar_y + (box-height ($shareables_files | length))

    let max_bottom = ([$hjem_bottom, $nxos_bottom, $shar_bottom] | math max)
    let legend_y   = $max_bottom + 60
    let canvas_h   = $legend_y + 80

    # ── Flake input card layout ───────────────────────────────────────────────
    # Row 1: up to 4 cards at fixed x positions; row 2: remainder centered
    let row1_xs   = [160, 444, 728, 1012]
    let primaries = $d.primary_inputs
    let n_prim    = ($primaries | length)
    let row1      = ($primaries | first ([$n_prim, 4] | math min))
    let row2      = if $n_prim > 4 { $primaries | skip 4 } else { [] }

    let input_cards_row1 = ($row1 | enumerate | each {|it|
        let cx = ($row1_xs | get $it.index)
        diag-input-card $cx 160 $it.item.name $it.item.repo
    } | flatten)

    let row2_n       = ($row2 | length)
    let row2_total_w = if $row2_n > 0 { $row2_n * 260 + ($row2_n - 1) * 24 } else { 0 }
    let row2_start_x = if $row2_n > 0 { ($canvas_w - $row2_total_w) / 2 | into int } else { 0 }
    let input_cards_row2 = ($row2 | enumerate | each {|it|
        let cx = $row2_start_x + ($it.index * 284)
        diag-input-card $cx 248 $it.item.name $it.item.repo
    } | flatten)

    let follows_text = if ($d.follows_inputs | length) > 0 {
        let follows_str = ($d.follows_inputs | str join " · ")
        [$"<text x=\"716\" y=\"234\" font-size=\"9\" fill=\"#9071f4\" opacity=\"0.45\" text-anchor=\"middle\">+($d.follows_inputs | length) follow nixpkgs: ($follows_str)</text>"]
    } else {
        []
    }

    # ── Input → flake.nix connectors ─────────────────────────────────────────
    let row1_connectors = ($row1 | enumerate | each {|it|
        let cx = ($row1_xs | get $it.index) + 130   # card center x
        if $cx == 716 {
            $"<line x1=\"($cx)\" y1=\"220\" x2=\"716\" y2=\"308\" stroke=\"#9071f4\" stroke-width=\"1.8\" opacity=\"0.45\"/>"
        } else if $it.index < 2 {
            $"<polyline points=\"($cx),220 ($cx),388 716,388\" stroke=\"#9071f4\" stroke-width=\"1.8\" fill=\"none\" opacity=\"0.45\"/>"
        } else {
            $"<polyline points=\"($cx),220 ($cx),368 716,368\" stroke=\"#9071f4\" stroke-width=\"1.8\" fill=\"none\" opacity=\"0.45\"/>"
        }
    })

    let row2_connectors = ($row2 | enumerate | each {|it|
        let cx = $row2_start_x + ($it.index * 284) + 130
        $"<line x1=\"($cx)\" y1=\"308\" x2=\"($cx)\" y2=\"348\" stroke=\"#9071f4\" stroke-width=\"1.8\" opacity=\"0.45\"/>"
    })

    let flake_to_repl = [
        "<line x1=\"716\" y1=\"408\" x2=\"716\" y2=\"448\" stroke=\"#04d1f9\" stroke-width=\"1.8\" opacity=\"0.45\"/>"
        "<text x=\"730\" y=\"432\" font-size=\"8\" fill=\"#04d1f9\" opacity=\"0.35\">outputs</text>"
    ]

    # ── Central nodes: flake.nix + repl.nix ──────────────────────────────────
    let central = [
        "<rect x=\"586\" y=\"348\" rx=\"12\" width=\"260\" height=\"60\" fill=\"#212337\" stroke=\"#04d1f9\" stroke-width=\"1.5\" filter=\"url(#glow-cyan)\"/>"
        "<rect x=\"589\" y=\"358\" rx=\"3\" width=\"4\" height=\"40\" fill=\"#04d1f9\"/>"
        "<circle cx=\"608\" cy=\"370\" r=\"7\" fill=\"#04d1f9\" opacity=\"0.2\"/>"
        "<circle cx=\"608\" cy=\"370\" r=\"4\" fill=\"#04d1f9\"/>"
        "<text x=\"624\" y=\"374\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">flake.nix</text>"
        "<text x=\"628\" y=\"390\" font-size=\"10\" fill=\"#04d1f9\" opacity=\"0.7\">Flake Root</text>"
        "<rect x=\"586\" y=\"448\" rx=\"12\" width=\"260\" height=\"60\" fill=\"#212337\" stroke=\"#37f499\" stroke-width=\"1.5\" filter=\"url(#glow-green)\"/>"
        "<rect x=\"589\" y=\"458\" rx=\"3\" width=\"4\" height=\"40\" fill=\"#37f499\"/>"
        "<circle cx=\"608\" cy=\"470\" r=\"7\" fill=\"#37f499\" opacity=\"0.2\"/>"
        "<circle cx=\"608\" cy=\"470\" r=\"4\" fill=\"#37f499\"/>"
        "<text x=\"624\" y=\"474\" font-size=\"13\" fill=\"#ebfafa\" font-weight=\"700\">repl.nix</text>"
        "<text x=\"628\" y=\"490\" font-size=\"10\" fill=\"#37f499\" opacity=\"0.7\">Nix REPL</text>"
    ]

    # ── Bus: modules → hjem / hosts / nixos-modules ───────────────────────────
    let mod_cx  = $mod_x  + 150   # 230
    let hjem_cx = $hjem_x + 150   # 554
    let host_cx = $host_x + 150   # 878
    let nxos_cx = $nxos_x + 150   # 1202
    let bus_y   = $mod_y  - 24    # 574

    let bus_lines = [
        $"<line x1=\"($mod_cx)\" y1=\"($mod_y)\" x2=\"($mod_cx)\" y2=\"($bus_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($mod_cx)\" y1=\"($bus_y)\" x2=\"($nxos_cx)\" y2=\"($bus_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($hjem_cx)\" y1=\"($bus_y)\" x2=\"($hjem_cx)\" y2=\"($hjem_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($host_cx)\" y1=\"($bus_y)\" x2=\"($host_cx)\" y2=\"($host_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($nxos_cx)\" y1=\"($bus_y)\" x2=\"($nxos_cx)\" y2=\"($nxos_y)\" stroke=\"#e9f941\" stroke-width=\"1.2\" opacity=\"0.3\"/>"
        $"<line x1=\"($mod_cx)\" y1=\"($mod_bottom)\" x2=\"($mod_cx)\" y2=\"($shar_y)\" stroke=\"#e9f941\" stroke-width=\"1.8\" opacity=\"0.45\"/>"
    ]

    # ── Module boxes ─────────────────────────────────────────────────────────
    let box_modules    = (diag-module-box $mod_x  $mod_y  "modules"       "modules"               $modules_root     "#e9f941" "glow-orange")
    let box_hjem       = (diag-module-box $hjem_x $hjem_y "hjem"          "modules/hjem"          $hjem_files       "#e9f941" "glow-orange")
    let box_hosts      = (diag-module-box $host_x $host_y "hosts"         "modules/hosts"         $hosts_files      "#e9f941" "glow-orange")
    let box_nixos      = (diag-module-box $nxos_x $nxos_y "nixos-modules" "modules/nixos-modules" $nixos_files      "#e9f941" "glow-orange")
    let box_shareables = (diag-module-box $shar_x $shar_y "shareables"    "modules/shareables"    $shareables_files "#e9f941" "glow-orange")

    [
        $"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"($canvas_w)\" height=\"($canvas_h)\" viewBox=\"0 0 ($canvas_w) ($canvas_h)\">"
        ...(diag-defs),
        $"<rect width=\"($canvas_w)\" height=\"($canvas_h)\" rx=\"16\" fill=\"#171928\"/>"
        $"<rect width=\"($canvas_w)\" height=\"($canvas_h)\" rx=\"16\" fill=\"url(#grid)\"/>"
        ...(diag-header $d.total_files $d.input_count),
        ...$input_cards_row1,
        ...$input_cards_row2,
        ...$follows_text,
        ...$row1_connectors,
        ...$row2_connectors,
        ...$flake_to_repl,
        ...$central,
        ...$bus_lines,
        ...$box_modules,
        ...$box_hjem,
        ...$box_hosts,
        ...$box_nixos,
        ...$box_shareables,
        ...(diag-legend $legend_y $d.total_files $d.input_count),
        "</svg>",
    ] | str join "\n"
}

# ─── Main ────────────────────────────────────────────────────────────────────

def main [] {
    if not ("CURRENT_FILE" in $env) {
        error make { msg: "CURRENT_FILE not set — run this script directly: nu scripts/update-svgs.nu" }
    }

    print "⚠  Remember: run `jj s` in ~/dotfiles first — nix eval reads git-tracked state.\n"

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
    let shareables_pkgs = ($shareables_files | each { $in | str replace '.nix' '' })

    let hjem_count         = ($hjem_files | length)
    let nixos_count        = ($nixos_files | length)
    let shareables_count   = ($shareables_files | length)
    let hosts_count        = (glob $"($dotfiles)/modules/hosts/*.nix" | length)
    let modules_root_count = (glob $"($dotfiles)/modules/*.nix" | length)
    let total_files        = $hjem_count + $nixos_count + $shareables_count + $hosts_count + $modules_root_count

    # Flake inputs via nix flake metadata (fast — reads lock file)
    let flake_meta  = (^nix flake metadata --json $dotfiles | from json)
    let all_inputs  = ($flake_meta.locks.nodes.root.inputs | columns)
    let input_count = ($all_inputs | length)

    # Detect "follows nixpkgs" inputs: their internal nixpkgs ref is a list path (["nixpkgs"])
    let follows_inputs = (
        $all_inputs | each {|name|
            let node  = ($flake_meta.locks.nodes | get $name)
            let inner = ($node.inputs? | default {})
            let nxref = $inner.nixpkgs?
            if ($nxref != null and ($nxref | describe | str starts-with 'list')) { $name } else { null }
        }
        | where { $in != null }
    )

    let primary_inputs = ($all_inputs | where { not ($in in $follows_inputs) })

    # Build input card data (name + repo slug from lock metadata)
    let primary_input_cards = ($primary_inputs | each {|name|
        let node = ($flake_meta.locks.nodes | get $name)
        let u    = $node.original.url?
        let o    = $node.original.owner?
        let url  = if $u != null { $u } else if $o != null { $"($o)/($node.original.repo)" } else { $name }
        { name: $name, repo: $url }
    })

    # ── Slow: system data via nix eval ───────────────────────────────────────
    print "→ Collecting system data (30–90s per eval call)..."

    let flake_ref = $dotfiles

    print "  · hyprland version...";    let hyprland_ver  = (nix-eval-raw  $"($flake_ref)#nixosConfigurations.HX99G.pkgs.hyprland.version")
    print "  · nushell version...";     let nushell_ver   = (nix-eval-raw  $"($flake_ref)#nixosConfigurations.HX99G.pkgs.nushell.version")
    print "  · ghostty version...";     let ghostty_ver   = (nix-eval-raw  $"($flake_ref)#nixosConfigurations.HX99G.pkgs.ghostty.version")
    print "  · fresh-editor version..."; let fresh_ver    = (nix-eval-raw  $"($flake_ref)#nixosConfigurations.HX99G.pkgs.fresh-editor.version")
    # noctalia-shell: pkgs.noctalia-shell.version is stale nixpkgs metadata.
    # Real version lives in UpdateService.qml as `baseVersion`. Fetch it at the
    # locked rev and append "-git" (all non-tagged builds use that suffix).
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
        | from json | values | get narSize | math sum
    } catch { 0 })
    let closure_size = if $closure_bytes > 0 { format-bytes $closure_bytes } else { "?" }

    # ── Assemble data record ──────────────────────────────────────────────────
    let d = {
        nixos_version:    "26.05 (Yarara)"
        linux_version:    "6.19.2-cachyos"
        hyprland_ver:     $hyprland_ver
        nushell_ver:      $nushell_ver
        ghostty_ver:      $ghostty_ver
        fresh_ver:        $fresh_ver
        noctalia_ver:     $noctalia_ver
        sys_pkg_count:    $sys_pkg_count
        user_pkg_count:   $user_pkg_count
        total_pkgs:       $total_pkgs
        closure_paths:    $closure_paths
        closure_size:     $closure_size
        shareables_pkgs:  $shareables_pkgs
        total_files:      $total_files
        input_count:      $input_count
        primary_inputs:   $primary_input_cards
        follows_inputs:   $follows_inputs
        hjem_files:       $hjem_files
        nixos_files:      $nixos_files
        shareables_files: $shareables_files
    }

    # ── Generate and write ────────────────────────────────────────────────────
    let out_dir = $"($dotfiles)/docs/assets"

    print "\n→ Writing anomalOS-overview.svg..."
    generate-overview $d | save --force $"($out_dir)/anomalOS-overview.svg"

    print "→ Writing anomalOS-diagram.svg..."
    generate-diagram $d | save --force $"($out_dir)/anomalOS-diagram.svg"

    print $"\n✓ Done. Files written to ($out_dir)/"
}
