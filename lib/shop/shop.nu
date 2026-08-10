def cache-dir []: nothing -> string {
  [($env.XDG_CACHE_HOME? | default $"($env.HOME)/.cache") "shop"] | path join
}

def choices-path []: nothing -> string {
  [(cache-dir) "choices.json"] | path join
}

# nushell routes a script's stdout through its own pipeline, so is-terminal --stdout is false even on a real tty.
def palette []: nothing -> record {
  if (is-terminal --stderr) and ($env.NO_COLOR? | is-empty) {
    {
      b: (ansi attr_bold),
      d: (ansi attr_dimmed),
      r: (ansi red),
      g: (ansi green),
      c: (ansi cyan),
      z: (ansi reset),
    }
  } else {
    { b: "", d: "", r: "", g: "", c: "", z: "" }
  }
}

def die [msg: string, detail?: string] {
  let c = (palette)
  print -e $"($c.r)($c.b)shop:($c.z) ($msg)"
  if $detail != null {
    print -e $"($c.d)($detail)($c.z)"
  }
  exit 1
}

def hint [msg: string] {
  let c = (palette)
  print -e $"($c.d)($msg)($c.z)"
}

def interactive []: nothing -> bool {
  (is-terminal --stdin) and (is-terminal --stderr)
}

# nushell repeats the header row at the bottom of any table past 25 rows.
def render [v: any]: nothing -> string {
  $env.config.footer_mode = "never"
  $v | table --theme thin --index false
}

def locate [cmd: string]: nothing -> list<string> {
  let r = (^nix-locate --minimal --at-root --whole-name $"/bin/($cmd)" | complete)
  if $r.exit_code == 0 { $r.stdout | lines | where ($it | str trim | is-not-empty) } else { [] }
}

def raw-version-table [attr: string]: nothing -> table {
  let apply = $"f: f \"($attr)\""
  let r = (^nix eval --json -f $env.SHOP_ENGINE versionTable --apply $apply | complete)
  if $r.exit_code != 0 {
    die $"nix eval failed" ($r.stderr | str trim)
  }
  $r.stdout | from json | select version revision
}

def version-table [attr: string]: nothing -> table {
  let tbl = (raw-version-table $attr)
  if ($tbl | is-empty) {
    die $"'($attr)' has no version axis"
  }
  $tbl
}

def reject-nested [attr: string] {
  if ($attr | str contains ".") {
    die $"'($attr)' is a nested attribute -- the version index only covers top-level attributes"
  }
}

# nix reads a bare 1.5 in a selection path as a list index, so every component is quoted.
def sel-path [parts: list<string>]: nothing -> string {
  $parts | each {|p| $"\"($p)\"" } | str join "."
}

def save-choice [cmd: string, picked: record] {
  mkdir (cache-dir)
  let p = (choices-path)
  let cur = if ($p | path exists) { open $p } else { {} }
  $cur | merge { ($cmd): $picked } | save --force $p
}

def resolve-choice [cmd: string]: nothing -> record {
  let p = (choices-path)
  let cached = if ($p | path exists) { open $p | get -o $cmd } else { null }
  if $cached != null {
    if (($cached | describe) | str starts-with "record") {
      return $cached
    }
    let parts = ($cached | split row ".")
    return { attr: ($parts | drop 1 | str join "."), output: ($parts | last) }
  }

  let all = (locate $cmd)

  # The database only lists packages the binary cache has, so unfree attrs are reachable by name but never by command.
  if ($all | is-empty) {
    if ((raw-version-table $cmd) | is-empty) {
      die $"no executable '($cmd)' in the nix-index database, and no attribute called '($cmd)'"
    }
    hint $"no /bin/($cmd) in the database -- resolving the attribute '($cmd)' directly"
    let picked = { attr: $cmd, output: "" }
    save-choice $cmd $picked
    return $picked
  }

  # Only top-level attrs carry a version axis, so they are offered first.
  let ordered = ($all | sort-by {|a| $a | split row "." | length })

  let choice = if (($ordered | length) == 1) {
    $ordered | first
  } else if (interactive) {
    $ordered | input list --fuzzy $"($ordered | length) packages ship /bin/($cmd)"
  } else {
    $ordered | first
  }
  if ($choice | is-empty) {
    die "nothing picked"
  }

  let parts = ($choice | split row ".")
  let picked = { attr: ($parts | drop 1 | str join "."), output: ($parts | last) }
  save-choice $cmd $picked
  $picked
}

def resolve-version [attr: string, tbl: table, want: string]: nothing -> string {
  if ($want | is-empty) {
    if not (interactive) {
      die $"no version given for '($attr)' and nothing to prompt on"
    }
    let picked = ($tbl | reverse | input list --fuzzy $"every ($attr) that ever existed")
    if ($picked | is-empty) {
      die "nothing picked"
    }
    return $picked.version
  }

  let known = ($tbl | get version)
  if ($want in $known) {
    return $want
  }
  let listed = ($known | str join " ")
  die $"no revision ever shipped ($attr) ($want)" $"known versions: ($listed)"
}

def show-rev []: nothing -> string {
  let c = (palette)
  let label = (^nix eval --raw -f $env.SHOP_ENGINE pinnedLabel | str trim)
  let note = if (^nix eval --json -f $env.SHOP_ENGINE pinnedExact | from json) {
    "exact pairing with the nix-index database"
  } else {
    "nearest indexed revision -- the database is newer than the index"
  }
  $"($c.c)($label)($c.z) ($c.d)\(($note)\)($c.z)"
}

def usage []: nothing -> string {
  let c = (palette)
  [
    $"($c.b)shop($c.z) -- run any version of any package, without installing it"
    ""
    $"($c.b)USAGE($c.z)"
    $"  ($c.c)shop <command>[@<version>] [args...]($c.z)"
    ""
    $"  ($c.c)shop rg($c.z)             newest ripgrep, run right now, installed nowhere"
    $"  ($c.c)shop jq@1.5($c.z)         the exact jq that shipped as 1.5, years ago"
    $"  ($c.c)shop jq@($c.z)            pick a jq version from a menu"
    $"  ($c.c)shop -l rg($c.z)          every ripgrep that ever existed"
    ""
    $"($c.b)OPTIONS($c.z)"
    $"  ($c.c)-l, --list <cmd>($c.z)    every version of that command, with its revision"
    $"  ($c.c)-p, --print <cmd>($c.z)   which packages provide that command"
    $"  ($c.c)-s, --shell <cmd>($c.z)   open a shell with it instead of running it"
    $"  ($c.c)--rev($c.z)               which revision a bare command resolves against"
    $"  ($c.c)-h, --help($c.z)          show this"
    ""
    $"($c.b)HOW IT WORKS($c.z)"
    $"  1  you type a command name, like ($c.c)rg($c.z)"
    $"  2  shop asks the nix-index database which package ships /bin/rg,"
    $"     and gets back ($c.c)ripgrep($c.z)"
    "  3  if you gave a version, shop looks up the last nixpkgs revision"
    "     that shipped ripgrep at that version"
    "  4  it pulls that one package out of the binary cache and runs it"
    "  5  nothing is installed. it lands in /nix/store and is collected by"
    "     the garbage collector like anything else"
    ""
    $"  no version means the revision shop is paired with. ($c.c)shop --rev($c.z)"
    "  tells you which one that is."
    ""
    $"($c.b)EXAMPLES($c.z)"
    "  every version of jq nixpkgs ever shipped, newest last, each with the"
    "  revision it came from:"
    ""
    $"      ($c.c)shop -l jq($c.z)"
    ""
    "  run one of them:"
    ""
    $"      ($c.c)shop jq@1.5 --version($c.z)"
    "      jq-1.5"
    ""
    "  leave the version off after the @ and shop gives you a searchable"
    "  menu of every version, newest first:"
    ""
    $"      ($c.c)shop jq@($c.z)"
    ""
    $"  the command is ($c.c)rg($c.z), the package is ($c.c)ripgrep($c.z). shop knows that:"
    ""
    $"      ($c.c)shop rg --version($c.z)"
    "      ripgrep 15.2.0"
    ""
    "  a shell with a 2017-era ripgrep on PATH. exit and it is gone:"
    ""
    $"      ($c.c)shop -s rg@0.4.0($c.z)"
    ""
    "  when several packages ship one command, shop asks you to pick and"
    "  then remembers the answer:"
    ""
    $"      ($c.c)shop -p convert($c.z)"
    ""
    $"($c.b)GOTCHAS($c.z)"
    "  the command you type is not always the package you think."
    "  /bin/python3 comes from python3Minimal, python311, python312 and"
    $"  python313 -- not from the attribute literally named ($c.c)python3($c.z). so"
    $"  ($c.c)shop python3@3.6.2($c.z) fails, because whatever shop picked never"
    $"  shipped a 3.6.2. use ($c.c)shop -p python3($c.z) to see the candidates, and"
    $"  ($c.c)shop -l python3($c.z) to see what your pick actually has."
    ""
    "  versions only work on top-level packages:"
    ""
    $"      shop yt-dlp@2026.07.04                    ($c.g)<- works($c.z)"
    $"      shop python314Packages.yt-dlp@2026.07.04  ($c.r)<- does not($c.z)"
    ""
    "  packages deleted from nixpkgs years ago cannot be found by command"
    "  name at all. the database only knows what exists today."
    ""
    "  the first package out of any given revision is slow -- shop has to"
    "  fetch that nixpkgs tree, roughly 300MB. every package from that same"
    "  revision afterwards is basically free."
    ""
    $"($c.b)CACHE($c.z)"
    "  ~/.cache/shop/choices.json   which package you picked for each command."
    "  delete a key, or the whole file, to be asked again."
  ] | str join "\n"
}

def --wrapped main [...rest] {
  if ($rest | is-empty) {
    print -e (usage)
    exit 1
  }

  let head = ($rest | first)
  let mode = (match $head {
    "-h" | "--help" => "help",
    "--rev" => "rev",
    "-l" | "--list" => "list",
    "-p" | "--print" => "print",
    "-s" | "--shell" => "shell",
    _ if ($head | str starts-with "-") => "bad",
    _ => "run",
  })

  if $mode == "help" { return (usage) }
  if $mode == "rev" { return (show-rev) }
  if $mode == "bad" { die $"unknown option '($head)'" }

  let argv = if $mode == "run" { $rest } else { $rest | skip 1 }
  if ($argv | is-empty) {
    die $"($head) needs a command"
  }

  let bits = ($argv | first | split row "@")
  let cmd = ($bits | first)
  let version = ($bits | get -o 1)
  let passthru = ($argv | skip 1)

  if ($cmd | is-empty) {
    die "no command given"
  }

  if $mode == "print" {
    let found = (locate $cmd)
    if ($found | is-empty) {
      if ((raw-version-table $cmd) | is-empty) {
        die $"no executable '($cmd)' in the nix-index database, and no attribute called '($cmd)'"
      }
      hint $"no /bin/($cmd) in the database -- shop resolves the attribute '($cmd)' directly"
      return
    }
    return (render ($found | wrap attr))
  }

  let picked = (resolve-choice $cmd)
  let attr = $picked.attr
  let output = $picked.output

  if $mode == "list" {
    reject-nested $attr
    return (render (version-table $attr))
  }

  let selection = if $version == null {
    let base = (["pkgs"] | append ($attr | split row "."))
    sel-path (if ($output | is-empty) { $base } else { $base | append $output })
  } else {
    reject-nested $attr
    let tbl = (version-table $attr)
    let ver = (resolve-version $attr $tbl $version)
    hint $"($attr) ($ver) -- from ($tbl | where version == $ver | first | get revision)"
    let base = ["versions" $attr $ver]
    sel-path (if ($output | is-empty) { $base } else { $base | append $output })
  }

  if $mode == "shell" {
    exec nix shell -f $env.SHOP_ENGINE $selection
  }

  exec nix shell -f $env.SHOP_ENGINE $selection --command $cmd ...$passthru
}
