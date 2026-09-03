# runs detached from clip-save because svt-av1 takes roughly half the clip's runtime
def main [src: string] {
  let dst = ($src | str replace --regex '\.mp4$' '.mkv')
  let r = (^ffmpeg -v error -y -i $src -c:v libsvtav1 -crf 40 -preset 8 -c:a copy $dst | complete)
  if $r.exit_code == 0 and ($dst | path exists) {
    ^rm -f $src
    ^notify-send "clip encoded" ($dst | path basename)
  } else {
    ^notify-send "clip encode failed" $"kept ($src | path basename)"
  }
}
