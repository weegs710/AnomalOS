#!/usr/bin/env nu

let theme_dir = $"($env.out)/share/plymouth/themes/relaxed"

mkdir $theme_dir

# %d is ffmpeg's own frame-number format specifier, not nushell interpolation
^ffmpeg -i docs/assets/relaxed.gif -start_number 0 $"($theme_dir)/frame_%d.png"

# 1x1 because the Plymouth script scales it to screen dimensions at runtime
^convert -size 1x1 xc:black $"($theme_dir)/black.png"

glob scripts/plymouth/*.{script,plymouth} | each { cp $in $theme_dir } | ignore

# Plymouth reads /usr/ paths from the descriptor; nix installs to store, not /usr/
open --raw $"($theme_dir)/relaxed.plymouth"
    | str replace --all "/usr/" $"($env.out)/"
    | save --force $"($theme_dir)/relaxed.plymouth"
