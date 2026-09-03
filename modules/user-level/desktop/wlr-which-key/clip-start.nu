def main [mode: string, region?: string] {
  let tmp_file = "/tmp/gsr_clip.mp4"
  let capture = if $mode == "region" { $region } else if $mode == "mic" { "screen" } else { $mode }
  # gsr makes one track per -a flag, so sources must be pipe-joined to land in a single track
  let audio = if $mode == "mic" { "-a 'default_output|phone_mic_source'" } else { "-a default_output" }
  ^bash -c $"setsid gpu-screen-recorder -w '($capture)' -f 60 ($audio) -c mp4 -o '($tmp_file)' >/tmp/gsr.log 2>&1 & echo $! > /tmp/gsr.pid"
}
