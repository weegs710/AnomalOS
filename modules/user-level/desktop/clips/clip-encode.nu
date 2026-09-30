# short saves are sized under discord's free 20MB cap; longer ones only need to be small
def main [src: string, kind: string] {
  # gsr names saves to the second, so a second save in the same second would overwrite this one mid-encode
  let work = ($src | str replace --regex '\.mp4$' $".(random chars --length 6).raw.mp4")
  mv -f $src $work
  let dur = (^ffprobe -v error -show_entries format=duration -of csv=p=0 $work | str trim | into float)
  let dst = ($src | str replace --regex '\.mp4$' $"_($dur | math round)s.mp4")
  let tmp = ($work | str replace --regex '\.raw\.mp4$' '.av1.mp4')
  let rate = if $dur <= 62 {
    # 19MB leaves headroom under 20MB for mux overhead and the 160k aac track
    let budget = ((19_000_000 * 8 / $dur / 1000) - 160 | math floor)
    ["-b:v" $"([$budget 4500] | math min)k"]
  } else {
    ["-crf" "40"]
  }
  let r = (^ffmpeg -v error -y -i $work -c:v libsvtav1 -preset 8 ...$rate -c:a copy -movflags +faststart $tmp | complete)
  if $r.exit_code == 0 and ($tmp | path exists) {
    mv -f $tmp $dst
    rm -f $work
    ^notify-send "clip saved" ($dst | path basename)
  } else {
    rm -f $tmp
    ^notify-send "clip encode failed" $"kept raw ($work | path basename)"
  }
}
