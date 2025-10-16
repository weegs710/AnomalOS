{
  lib,
  pkgs,
  config,
  osConfig,
  inputs,
  ...
}: let
  username = osConfig.mySystem.user.name;
  homeDirectory = "/home/${username}";
in {
  imports = [
    ./modules/claude-code-enhanced
  ];

  # Enable Claude Code enhanced features
  programs.claude-code-enhanced.enable = true;

  # Override Fish shell colors for better visibility
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Fix parameter color (was 16081f - too dark)
      set -g fish_color_param b392f0  # base05 light purple
      # Optional: improve autosuggestion visibility
      set -g fish_color_autosuggestion 2f143f  # base03 medium purple
    '';
  };

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.05";

  # Basic home packages (always included)
  home.packages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.default
    inputs.nh.packages.${pkgs.system}.default
    alejandra
    alarm-clock-applet
    btop
    cliphist
    dunst
    fastfetch
    fzf
    gh
    gparted
    grim
    hyprls
    hyprshot
    jq
    kitty
    nil
    nodejs
    pamixer
    python3
    rofi
    rustc
    slurp
    swww
    tldr
    ueberzugpp
    uv
    wl-clipboard
    wl-clip-persist
    wlogout
    wlsunset
  ];

  home.sessionVariables = {
    EDITOR = "codium";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
    VISUAL = "codium";
    XDG_TERMINAL_EDITOR = "kitty";
  };

  programs.home-manager.enable = true;

  # Claude Code project directory (conditional)
  home.file."claude-projects/.keep" = lib.mkIf osConfig.mySystem.features.claudeCode {
    text = "";
  };
}
