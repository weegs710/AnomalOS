{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    # XDG MIME type associations
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "org.kde.okular.desktop";
      };
    };

    xdg.dataFile."applications/btop.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=btop++
      GenericName=System Monitor
      Comment=Resource monitor that shows usage and stats for processor, memory, disks, network and processes
      Icon=btop
      Exec=hyprctl dispatch exec '[workspace special:control-panel; tile] ghostty -e btop'
      Terminal=false
      Categories=System;Monitor;ConsoleOnly;
      Keywords=system;process;task
    '';

    xdg.dataFile."applications/pavucontrol.desktop".text = ''
      [Desktop Entry]
      Name=PulseAudio Volume Control
      GenericName=Volume Control
      Comment=Adjust the volume level
      Icon=multimedia-volume-control
      Exec=hyprctl dispatch exec '[workspace special:control-panel; float] pavucontrol'
      Terminal=false
      Type=Application
      Categories=AudioVideo;Audio;Mixer;GTK;
      Keywords=pavucontrol;audio;sound;volume;
    '';

    xdg.dataFile."applications/qalculate-gtk.desktop".text = ''
      [Desktop Entry]
      Name=Qalculate!
      GenericName=Calculator
      Comment=Powerful and easy to use calculator
      Icon=qalculate
      Exec=hyprctl dispatch exec '[workspace special:control-panel; float] qalculate-gtk'
      Terminal=false
      Type=Application
      Categories=Utility;Calculator;GTK;
      Keywords=calculator;math;
    '';

    xdg.dataFile."applications/piper.desktop".text = ''
      [Desktop Entry]
      Name=Piper
      GenericName=Gaming Mouse Configuration
      Comment=Configure gaming mice
      Icon=org.freedesktop.Piper
      Exec=hyprctl dispatch exec '[workspace special:control-panel; float] piper'
      Terminal=false
      Type=Application
      Categories=Settings;HardwareSettings;GTK;
      Keywords=gaming;mouse;configuration;
    '';

    xdg.dataFile."applications/org.freedesktop.Piper.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Piper
      Hidden=true
    '';

    xdg.dataFile."applications/org.kde.kwalletmanager5.desktop".text = ''
      [Desktop Entry]
      Name=KWallet Manager
      GenericName=Password Manager
      Comment=Manage KDE Wallet passwords
      Icon=kwalletmanager
      Exec=hyprctl dispatch exec '[workspace special:control-panel; float] kwalletmanager5'
      Terminal=false
      Type=Application
      Categories=Qt;KDE;Settings;Security;
      Keywords=password;wallet;credentials;
    '';
  };
}
