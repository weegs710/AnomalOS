{
  config,
  pkgs,
  ...
}:
let
  gpartedWithTools = pkgs.gparted.override { withAllTools = true; };
  # env set inside the sudo shell -- PAM clobbers XDG_DATA_DIRS back to root's profile otherwise, hiding the user's theme
  gpartedSafe = pkgs.writeShellScriptBin "gparted-safe" ''
    trap 'systemctl --user start udiskie' EXIT
    systemctl --user stop udiskie
    sudo sh -c "export GDK_BACKEND=wayland WAYLAND_DISPLAY='$WAYLAND_DISPLAY' XDG_RUNTIME_DIR='$XDG_RUNTIME_DIR' GTK_THEME=adw-gtk3-dark XDG_CONFIG_HOME='$HOME/.config' XDG_DATA_DIRS='$XDG_DATA_DIRS'; exec ${gpartedWithTools}/bin/gparted"
  '';
in
{
  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    adwaita-icon-theme
    bluetui
    cachix
    tutanota-desktop
    zathura
    cliphist
    dbus
    dbus-broker
    file-roller
    gpartedWithTools
    gpartedSafe
    libGL
    libnotify
    libportal
    libx11
    libxcursor
    libxi
    libxinerama
    libxrandr
    libxxf86vm
    lm_sensors
    mesa
    piper
    qview
    tremc
    ueberzugpp
    unzipNLS
    xdg-dbus-proxy
    gimp3-with-plugins
    gpu-screen-recorder
    inkscape
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.shellAliases = {
    gparted = "gparted-safe";
  };

  fonts.packages =
    with pkgs.nerd-fonts;
    [
      dejavu-sans-mono
      jetbrains-mono
      fira-code
      terminess-ttf
      space-mono
      hack
      iosevka
    ]
    ++ [ pkgs.noto-fonts-color-emoji ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/tutanota-desktop"
    ".config/qView"
    ".config/zathura"
    ".config/Yubico"
    ".config/cachix"
    ".local/share/zathura"
    ".local/share/bluetui"
  ];

  programs.gpu-screen-recorder.enable = true;
  programs.gnome-disks.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings.General.Experimental = true;

  services.blueman.enable = true;
  services.upower.enable = true;
  services.ratbagd.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.locate.enable = true;
  services.speechd.enable = false; # pulled in as a gnome dependency, not needed

  services.displayManager = {
    defaultSession = "hyprland";
    ly = {
      enable = true;
      settings = {
        clock = "%-I:%M %p  %a, %d %b %Y";
        save = true;
        show_tty = true;
        hide_borders = true;
        animation = "matrix";
        animation_frame_delay = 1;
        cmatrix_fg = "0x0004D1F9";
        cmatrix_head_col = "0x0166E4FD";
      };
    };
  };
}
