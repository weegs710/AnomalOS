def main [] {
  let running = (^systemctl --user is-active phone-cam-view | complete | get stdout | str trim)
  if $running == "active" {
    # an idle camera costs ~240% phone CPU and throttles the device, so it stops with the window
    try { ^systemctl --user stop phone-cam-view } catch { }
    try { ^systemctl --user stop phone-cam } catch { }
  } else {
    # mpv cannot open /dev/video9 until scrcpy is attached to it as a producer
    try { ^systemctl --user start phone-cam } catch { }
    sleep 2000ms
    try { ^systemctl --user start phone-cam-view } catch { }
  }
  sleep 500ms
  let state = (^systemctl --user is-active phone-cam-view | complete | get stdout | str trim)
  ^notify-send "facecam" $"phone-cam-view: ($state)"
}
