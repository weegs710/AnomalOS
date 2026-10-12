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
    let mode = if $save == "1" { "save" } else if $directory == "1" { "dir" } else if $multiple == "1" { "files" } else { "file" }
    # tfm exits 1 on a path that does not exist, and with create_help_file=0 a save target never does
    let start = if $mode == "save" { $path | path dirname } else { $path }

    with-env {
        TFM_CHOOSER_FILE: $out
        TFM_CWD_FILE: $cwd_file
        TFM_CHOOSER_MODE: $mode
        TFM_CONFIG: "@CHOOSERCONF@"
    } {
        # the portal deletes the out file whenever the wrapper exits nonzero, and a failing external aborts the rest of this script
        try { ^@TERM@ --title=termfilechooser @TFM@ $start } catch { }
    }

    # save and directory modes resolve against the folder tfm ended in, because neither picks a file that already exists
    let picked = ($out | path exists) and ((ls $out | first | get size) > 0B)
    if not $picked and ($cwd_file | path exists) {
        let cwd = (open $cwd_file | str trim)
        if $cwd != "" and $mode == "save" {
            $"($cwd)/($path | path basename)" | save --force $out
        } else if $cwd != "" and $mode == "dir" {
            $cwd | save --force $out
        }
    }
    rm --force $cwd_file
}
