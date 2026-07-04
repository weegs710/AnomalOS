# runs inside a floating ghostty so the polkit FIDO prompt is visible; window closes itself on exit
def main [unit: string] {
  print $"restarting ($unit) -- authenticate to proceed"
  try { ^systemctl restart $unit } catch { }
  sleep 500ms
  let state = (^systemctl is-active $unit | complete | get stdout | str trim)
  ^notify-send $"($unit): ($state)"
}
