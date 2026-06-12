#!@NUSHELL@/bin/nu

def main [
    multiple: string
    directory: string
    save: string
    path: string
    out: string
    debug?: string
] {
    let cwd_file = $"($out).1"

    if $save == "1" or $directory == "1" {
        ghostty --title=termfilechooser -e yazi $"--chooser-file=($out)" $"--cwd-file=($cwd_file)" $path
        let out_empty = not ($out | path exists) or ((ls $out | first | get size) == 0B)
        let cwd_nonempty = ($cwd_file | path exists) and ((ls $cwd_file | first | get size) > 0B)
        if $out_empty and $cwd_nonempty {
            if $save == "1" {
                # reconstruct full save path: cwd + suggested filename from app
                let cwd = open $cwd_file | str trim
                $"($cwd)/($path | path basename)" | save -f $out
            } else {
                open --raw $cwd_file | save -f $out
            }
        }
        if ($cwd_file | path exists) { ^rm -f $cwd_file }
    } else {
        ghostty --title=termfilechooser -e yazi $"--chooser-file=($out)" $path
    }
}
