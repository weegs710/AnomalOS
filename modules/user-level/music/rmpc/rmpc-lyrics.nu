#!@NUSHELL@/bin/nu
def main [] {
    let lrc_file = $env.LRC_FILE? | default ""
    if $lrc_file == "" { return }
    if ($lrc_file | path exists) { return }

    let title = $env.TITLE? | default ""
    if $title == "" { return }

    let artist = $env.ARTIST? | default ($env.ALBUMARTIST? | default "")
    let album = $env.ALBUM? | default ""

    let dur_str = $env.DURATION? | default ""
    let dur_secs = if $dur_str == "" {
        0
    } else {
        let parts = $dur_str | split row ":"
        let n = $parts | length
        if $n == 3 {
            ($parts | get 0 | into int) * 3600 + ($parts | get 1 | into int) * 60 + ($parts | get 2 | into int)
        } else if $n == 2 {
            ($parts | get 0 | into int) * 60 + ($parts | get 1 | into int)
        } else {
            0
        }
    }

    let url = $"https://lrclib.net/api/get?track_name=($title | url encode)&artist_name=($artist | url encode)&album_name=($album | url encode)&duration=($dur_secs)"

    let lyrics = try {
        let r = http get $url
        let synced = $r.syncedLyrics? | default ""
        let plain = $r.plainLyrics? | default ""
        if $synced != "" { $synced } else if $plain != "" { $plain } else { null }
    } catch { null }

    if $lyrics == null { return }

    mkdir ($lrc_file | path dirname)
    $lyrics | save $lrc_file
}
