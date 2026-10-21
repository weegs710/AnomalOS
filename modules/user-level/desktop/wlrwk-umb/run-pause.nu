# holds the spawned terminal open until dismissed -- one-shot output would otherwise flash and vanish
# --wrapped so flag-looking args (systemctl --no-pager) land in the rest param instead of erroring
def --wrapped main [...cmd: string] {
  try { ^$cmd.0 ...($cmd | skip 1) } catch { }
  print ""
  input "-- enter to close --" | ignore
}
