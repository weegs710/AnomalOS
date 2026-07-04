def main [tmp_file: string] {
  let shots_dir = ([$env.HOME, "Pictures", "shots"] | path join)
  mkdir $shots_dir
  let name = (input "Shot name: " | str trim | str replace --all "'" "" | str replace --all "/" "" | str replace --regex '(?i)\.webp$' "")
  if $name == "" {
    ^rm -f $tmp_file
    return
  }
  let outfile = ([$shots_dir, $"($name).webp"] | path join)
  ^cwebp -lossless $tmp_file -o $outfile
  ^rm -f $tmp_file
}
