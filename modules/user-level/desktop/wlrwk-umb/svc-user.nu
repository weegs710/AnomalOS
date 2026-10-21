# user units need no auth, so no terminal -- the notification is the only feedback
def main [...units: string] {
  try { ^systemctl --user restart ...$units } catch { }
  sleep 500ms
  let body = ($units | each { |u|
    $"($u): (^systemctl --user is-active $u | complete | get stdout | str trim)"
  } | str join "\n")
  ^notify-send "user services" $body
}
