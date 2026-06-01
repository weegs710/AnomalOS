{
  config,
  pkgs,
  ...
}:
{
  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    adwaita-icon-theme
    kdePackages.kdeconnect-kde
    bluetui
    cachix
    nemo-with-extensions
    tutanota-desktop
    zathura
    cliphist
    dbus
    dbus-broker
    file-roller
    gparted
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
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.shellAliases = {
    gparted = "sudo WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR gparted";
  };

  fonts.packages = with pkgs.nerd-fonts; [
    dejavu-sans-mono
    jetbrains-mono
    fira-code
    terminess-ttf
    space-mono
    hack
    iosevka
  ] ++ [ pkgs.noto-fonts-color-emoji ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/nemo"
    ".config/tutanota-desktop"
    ".config/qView"
    ".config/zathura"
    ".config/Yubico"
    ".config/cachix"
    ".local/share/nemo"
    ".local/share/zathura"
    ".local/share/bluetui"
  ];
}
