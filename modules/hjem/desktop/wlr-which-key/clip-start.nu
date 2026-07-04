def main [mode: string, region?: string] {
  let tmp_file = "/tmp/gsr_clip.mp4"
  let capture = if $mode == "region" { $region } else { $mode }
  ^bash -c $"setsid gpu-screen-recorder -w '($capture)' -f 60 -a default_output -c mp4 -o '($tmp_file)' >/tmp/gsr.log 2>&1 & echo $! > /tmp/gsr.pid"
}
