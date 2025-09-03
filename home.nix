{
  lib,
  pkgs,
  ...
}:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "weegs";
  home.homeDirectory = "/home/weegs";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    alejandra
    btop-rocm
    cliphist
    dunst
    fastfetch
    fzf
    hyprshot
    jq
    rofi
    swww
    tldr
    wlogout
    wlsunset
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/weegs/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "zeditor";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
    VISUAL = "zeditor";
    XDG_TERMINAL_EDITOR = "kitty";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Hyprland config.
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$terminal" = "kitty";
      "$fileManager" = "thunar";
      "$menu" = "rofi -show drun -show-icons";
      "$webBrowser" = "librewolf";
      "$mainMod" = "SUPER";
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,Nordzy-hyprcursors"
        "HYPRCURSOR_SIZE,30"
        "TERMINAL,kitty"
        "XDG_TERMINAL_EDITOR,kitty"
      ];
      exec-once = [
        "swww-daemon &"
        "swww img ~/Pictures/monster.jpg"
        "dunst &"
        "nfa &"
      ];
      general = {
        no_border_on_floating = true;
        gaps_in = 1;
        gaps_out = 2.5;
        border_size = 2;
        "col.active_border" = lib.mkForce "rgb(b53dff)";
        "col.inactive_border" = lib.mkForce "rgba(00000000)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "master";
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      master = {
        always_keep_position = false;
        new_status = "master";
        mfact = 0.60;
      };
      misc = {
        force_default_wallpaper = lib.mkForce "-1";
        disable_hyprland_logo = lib.mkForce false;
      };
      decoration = {
        rounding = 0;
        active_opacity = 1;
        inactive_opacity = 1;
        shadow = {
          enabled = true;
          range = 8;
          render_power = 4;
          color = lib.mkForce "rgba(00000033)";
        };
        blur = {
          enabled = false;
          size = 8;
          passes = 1;
          new_optimizations = true;
          ignore_opacity = false;
          vibrancy = 0.25;
        };
      };
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
      };
      device = {
        "name" = "epic-mouse-v1";
        sensitivity = -0.5;
      };
      animations = {
        enabled = 1;
        animation = [
          "windows, 1, 3, myBezier"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 5, default"
          "workspaces, 1, 7, default"
          "windowsMove, 1, 5, myBezier"
          "windowsOut, 1, 5, myBezier"
          "fade, 1, 5, default"
          "workspaces,1,4,overshot,slidevert"
        ];
        bezier = [
          "myBezier, 0.05, 0.9, 0.1, 1.05"
          "overshot,0.05,0.9,0.1,1.1"
          "overshot,0.13,0.99,0.29,1.1"
        ];
      };
      bind = [
        "$mainMod, escape, killactive"
        "$mainMod, F, fullscreen"
        "$mainMod, G, togglefloating"
        "$mainMod, P, pseudo, "
        "$mainMod, O, togglesplit, "
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        "$mainMod, minus, togglespecialworkspace, scratchpad"
        "$mainMod SHIFT, minus, movetoworkspacesilent, special:scratchpad"
        "$mainMod, page_down, workspace, e+1"
        "$mainMod, page_up, workspace, e-1"
        ", PRINT, exec, hyprshot -m region --clipboard-only"
        "SHIFT,PRINT, exec, hyprshot -m region -o ~/Pictures"
      ];
      bindel = [
        "control ,right, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        "control ,left , exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "control ,down, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ];
      bindl = [
        "SUPER,Super_L, exec, $menu"
        "control alt,delete ,exit"
      ];
      binde = [
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"
      ];
      bindr = [
        "control&alt, B, exec, $webBrowser"
        "control&alt, D, exec, vesktop"
        "control&alt, F, exec, $fileManager"
        "control&alt, R, exec, tmux new -d -s roku_app 'appimage-run ~/AppImages/roku.AppImage'"
        "control&alt, S, exec, steam"
        "control&alt, T, exec, $terminal"
        "control&alt, Y, exec, freetube"
        "control&alt, Z, exec, zeditor"
        "control&alt $mainMod, B, exec, kitty -e bluetui"
        "control&alt $mainMod, L, exec, hyprlock"
        "control&alt $mainMod, N, exec, kitty -e nmtui"
        "control&alt $mainMod, delete, exec, wlogout"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
