
# extracts a password-locked 7z or rar for nordend, whose own extraction never prompts for one

def main [archive: path] {
    let archive = ($archive | path expand)
    let parent = ($archive | path dirname)
    let stem = ($archive | path basename | str replace --regex '(?i)\.(7z|rar)$' '')
    mut out = ($parent | path join $stem)
    mut n = 2
    while ($out | path exists) {
        $out = ($parent | path join $"($stem) \(($n)\)")
        $n += 1
    }
    mkdir $out

    # kitty exits 0 whatever its command returns, so the status comes back through a file
    let status = (mktemp -t nordend-unlock.XXXXXX)
    try {
        ^@KITTY@ --class nordend-unlock --title $"unlock ($archive | path basename)" $env.CURRENT_FILE inner $archive $out $status
    } catch { }
    let rc = (open --raw $status | str trim)
    rm $status

    if $rc != "0" {
        rm -r $out
        exit (if ($rc | is-empty) { 1 } else { $rc | into int })
    }
}

def "main inner" [archive: path, out: path, status: path] {
    mut rc = 1
    for attempt in 1..3 {
        # 7zz reads the password with the terminal still echoing
        ^@STTY@ -echo
        $rc = (try { ^@7ZZ@ x -aos -y -bd $"-o($out)" -- $archive; 0 } catch { $env.LAST_EXIT_CODE })
        ^@STTY@ echo
        if $rc == 0 { break }
        # a wrong password on a plain-header rar still leaves files behind
        for f in (ls --all $out | get name) { rm -r $f }
        if $attempt < 3 { print "wrong password or damaged archive, try again" }
    }
    $rc | into string | save --force $status
}
