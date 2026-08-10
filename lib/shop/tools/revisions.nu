const BUCKET = "https://nix-releases.s3.amazonaws.com/"

# A directory appears in this bucket only once Hydra published the channel, which is what makes its store paths substitutable.
def bucket-names []: nothing -> list<string> {
  mut names = []
  mut marker = ""
  loop {
    let raw = (http get --raw $"($BUCKET)?delimiter=/&prefix=nixos/unstable/&max-keys=1000&marker=($marker)")
    let page = ($raw | parse --regex '<Prefix>nixos/unstable/(?<name>[^<]+)/</Prefix>' | get name)
    if ($page | is-empty) { break }
    $names = ($names | append $page)
    if not ($raw | str contains "<IsTruncated>true</IsTruncated>") { break }
    $marker = $"nixos/unstable/($page | last)/"
  }
  $names
}

# The commit is embedded in the directory name, so the whole list costs a few listings rather than a fetch per channel.
def short-shas [names: list<string>]: nothing -> list<string> {
  $names
  | each {|n| $n | parse --regex '\.(?<sha>[0-9a-f]{11,12})$' | get sha.0? }
  | compact
  | uniq
}

# A release point is the git tag; the bucket's first entry for that release is already a backport bump past it.
def release-points [clone: string]: nothing -> table {
  ^git -C $clone for-each-ref --format='%(refname:short) %(objectname)' 'refs/tags/*'
  | lines
  | parse --regex '^(?<release>\d\d\.\d\d) (?<sha>[0-9a-f]{40})$'
}

def resolve-one [clone: string, sha: string]: nothing -> any {
  let r = (^git -C $clone log -1 --format='%H %cs' $"($sha)^{commit}" | complete)
  if $r.exit_code != 0 {
    return null
  }
  let parts = ($r.stdout | str trim | split row " ")
  { rev: $parts.0, date: $parts.1, channel: "nixos-unstable" }
}

def main [
  --clone: string                     # bare nixpkgs clone to resolve commits against
  --pin: string                       # newest revision to include; the index stops here
  --out: string = "index/revisions.json"
  --min-year: int = 2017
  --threads: int = 16
  --merge                             # keep existing entries at their offsets and only append newer ones
] {
  if ($clone | is-empty) or ($pin | is-empty) {
    error make { msg: "--clone and --pin are both required" }
  }

  let pinned = (resolve-one $clone $pin)
  if $pinned == null {
    error make { msg: $"pin ($pin) is not a commit in ($clone) -- git fetch?" }
  }
  print $"pin ($pinned.rev | str substring 0..11) dated ($pinned.date)"

  let names = (bucket-names)
  let shorts = (short-shas $names)
  print $"($names | length) archived channels, ($shorts | length) carry a commit"

  let bumps = (
    $shorts
    | par-each --threads $threads {|s| resolve-one $clone $s }
    | compact
    | where ($it.date | str substring 0..3 | into int) >= $min_year
  )

  # Releases carry a name worth selecting by, so they are kept regardless of --min-year.
  let releases = (
    release-points $clone
    | par-each --threads $threads {|r|
        let got = (resolve-one $clone $r.sha)
        if $got == null { null } else { $got | merge { channel: "release", release: $r.release } }
      }
    | compact
  )
  print $"($bumps | length) channel bumps, ($releases | length) releases"

  let rows = (
    $bumps
    | append $releases
    | where $it.date <= $pinned.date
    | uniq-by rev
    | sort-by date rev
  )

  mkdir ($out | path dirname)
  let existing = if ($merge and ($out | path exists)) { open $out } else { [] }

  let final = if ($existing | is-empty) {
    $rows
  } else {
    # versions.json stores bare offsets into this array, so existing entries can never move.
    let known = ($existing | get rev)
    let tail = ($existing | last | get date)
    let new = ($rows | where not ($it.rev in $known))
    let stale = ($new | where $it.date < $tail)
    if ($stale | is-not-empty) {
      print $"warning: ($stale | length) new revisions predate the current tail and were skipped -- re-run without --merge to rebuild offsets"
    }
    $existing | append ($new | where $it.date >= $tail | sort-by date rev)
  }

  $final | to json --indent 1 | save --force $out
  let added = (($final | length) - ($existing | length))
  print $"($final | length) revisions \(+($added)\), ($final | first | get date) .. ($final | last | get date) -> ($out)"
}
