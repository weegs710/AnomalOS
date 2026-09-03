def main [encoder: string] {
  let tmp_file = "/tmp/gsr_clip.mp4"
  if not ($tmp_file | path exists) { return }
  let clips_dir = ([$env.HOME, "Videos", "clips"] | path join)
  mkdir $clips_dir
  let name = (input "Clip name: " | str trim | str replace --all "'" "" | str replace --all "/" "" | str replace --regex '(?i)\.mp4$' "")
  if $name == "" {
    ^rm -f $tmp_file
    return
  }
  let outfile = ([$clips_dir, $"($name).mp4"] | path join)
  ^mv $tmp_file $outfile
  ^bash -c $"setsid nu '($encoder)' '($outfile)' >/dev/null 2>&1 &"
}
