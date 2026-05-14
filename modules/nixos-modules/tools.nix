{
  config,
  pkgs,
  ...
}:
{
  programs = {
    wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
    git.enable = true;
    direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      direnvrcExtra = ''
        warn_timeout=0
        hide_env_diff=true
      '';
    };
  };

  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    cargo
    clippy
    gh
    hyperfine
    hyprls
    jq
    nodejs
    python3
    ripgrep
    rust-analyzer
    rustc
    rustfmt
    uv
  ];

  environment.systemPackages = with pkgs; [
    jujutsu
  ];
}
