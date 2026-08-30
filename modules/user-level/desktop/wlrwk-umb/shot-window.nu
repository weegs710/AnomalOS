def main [] {
  sleep 500ms
  # umbriel prints the unwrapped array, so the focused entry carries its own x/y/w/h
  let win = (^umbriel windows --json | from json | where {|w| $w.focused } | first)
  ^grim -g $"($win.x),($win.y) ($win.w)x($win.h)" - | ^wl-copy --type image/png
}
