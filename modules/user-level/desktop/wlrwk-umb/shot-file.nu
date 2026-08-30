def main [mode: string, save_script: string] {
  sleep 500ms
  let tmp_file = $"/tmp/wkshot_(random int).png"
  match $mode {
    "region" => { ^grim -g (^slurp | str trim) $tmp_file }
    "window" => {
      let win = (^umbriel windows --json | from json | where {|w| $w.focused } | first)
      ^grim -g $"($win.x),($win.y) ($win.w)x($win.h)" $tmp_file
    }
    "output" => { ^grim $tmp_file }
    _ => { return }
  }
  ^ghostty --title=name-shot -e nu $save_script $tmp_file
}
