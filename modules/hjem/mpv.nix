{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [ pkgs.mpv ];

  hjem.users.${username}.xdg.config.files."mpv/mpv.conf".text = ''
    vo=gpu-next
    gpu-api=vulkan
    hwdec=vaapi

    scale=lanczos
    dscale=lanczos
    cscale=lanczos

    video-sync=display-resample
    display-fps-override=144
    interpolation=yes

    ao=pipewire

    # ASS tracks ignore these and use embedded styles
    sid=no
    sub-font=JetBrainsMono Nerd Font
    sub-color="#FFFFFF"
    sub-border-color="#000000"
    sub-border-size=2.4
    sub-back-color="#00000000"

    screenshot-directory=~/Pictures/mpv-screenshots
    screenshot-format=webp

    deband=yes
  '';
}
