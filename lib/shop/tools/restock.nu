
def pin-from-flake [lock: string, input: string]: nothing -> any {
  # open guesses a parser from the extension, and .lock is not json to nushell.
  let l = (open --raw $lock | from json)
  let root = ($l.root? | default "root")
  let ref = ($l.nodes | get -o $root | get -o inputs | get -o $input)
  if $ref == null {
    return null
  }
  # A follows entry is a path through other inputs rather than a direct node key.
  mut key = $ref
  if (($ref | describe) | str starts-with "list") {
    mut cur = $root
    for step in $ref {
      $cur = ($l.nodes | get $cur | get inputs | get $step)
    }
    $key = $cur
  }
  $l.nodes | get -o $key | get -o locked | get -o rev
}

def pin-from-tack [lock: string, input: string]: nothing -> any {
  open --raw $lock | from json | get -o $input | get -o rev
}

def pin-from-channel []: nothing -> any {
  let r = (^nix-instantiate --eval --expr 'toString <nixpkgs>' | complete)
  if $r.exit_code != 0 {
    return null
  }
  let f = ([($r.stdout | str trim | str replace --all '"' ""), ".git-revision"] | path join)
  if ($f | path exists) { open --raw $f | str trim } else { null }
}

def resolve-pin [repo: string, input: string, given: string] {
  if ($given | is-not-empty) {
    if ($given =~ '^[0-9a-f]{40}$') {
      return $given
    }
    let r = (http get $"https://channels.nixos.org/($given)/git-revision" | str trim)
    print $"pin from channel ($given)"
    return $r
  }

  let flake = ([$repo "flake.lock"] | path join)
  if ($flake | path exists) {
    let got = (pin-from-flake $flake $input)
    if $got != null {
      print $"pin from flake.lock input '($input)'"
      return $got
    }
  }

  let tack = ([$repo ".tack" "pins.lock.json"] | path join)
  if ($tack | path exists) {
    let got = (pin-from-tack $tack $input)
    if $got != null {
      print $"pin from tack pins.lock.json input '($input)'"
      return $got
    }
  }

  let got = (pin-from-channel)
  if $got != null {
    print "pin from <nixpkgs>/.git-revision"
    return $got
  }

  error make {
    msg: $"could not work out a nixpkgs revision for ($repo).
looked for: flake.lock, .tack/pins.lock.json, <nixpkgs>/.git-revision
pass one instead:  restock --pin <40-char-rev>   or   restock --pin nixos-unstable"
  }
}

# Refresh the shop index against the current nixpkgs pin, after updating your inputs.
def main [
  --repo: string = "."                # checkout holding lib/shop/index
  --clone: string                     # bare nixpkgs clone; defaults to $SHOP_CLONE
  --pin: string = ""                  # a 40-char rev, or a channel name like nixos-unstable
  --input: string = "nixpkgs"         # which lock input to read the revision from
  --threads: int = 12
  --rebuild                           # discard offsets and rebuild the whole index
] {
  let clone = ($clone | default $env.SHOP_CLONE?)
  if ($clone | is-empty) {
    error make { msg: "no nixpkgs clone: pass --clone or set SHOP_CLONE" }
  }

  let rev = (resolve-pin $repo $input $pin)
  print $"pin ($rev | str substring 0..11)"

  let tools = ([$repo "lib" "shop" "tools"] | path join)
  let index = ([$repo "lib" "shop" "index"] | path join)

  print "fetching the clone"
  ^git -C $clone fetch --prune --quiet origin

  (^nu ([$tools "revisions.nu"] | path join)
    --clone $clone
    --pin $rev
    --out ([$index "revisions.json"] | path join)
    --threads $threads
    ...(if $rebuild { [] } else { ["--merge"] }))

  (^python3 ([$tools "index.py"] | path join)
    --clone $clone
    --revisions ([$index "revisions.json"] | path join)
    --out ([$index "versions.json"] | path join)
    --cache ([$index ".per-rev"] | path join)
    --threads $threads
    ...(if $rebuild { [] } else { ["--incremental"] }))

  print "restocked -- rebuild to pick it up"
}
