# the menu execs under sh -c with stdout nulled, so a failed start is invisible without a notification
def main [action: string] {
  try { ^systemctl --user $action phone-cam } catch { }
  sleep 500ms
  let state = (^systemctl --user is-active phone-cam | complete | get stdout | str trim)
  ^notify-send "phone cam" $"phone-cam: ($state)"
}
