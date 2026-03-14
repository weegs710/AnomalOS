{inputs, ...}: {
  flake.nixosModules.packages = {
    config,
    pkgs,
    ...
  }: {
    config = {
      users.users.${config.mySystem.user.name}.packages = with pkgs; [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        alejandra
        fzf
        gh
        hyprls
        hyperfine
        jq
        adbfs-rootless
        nemo-with-extensions
        nodejs
        python3
        ripgrep
        rustc
        tldr
        tutanota-desktop
        uv
        zathura
      ];
    };
  };
}
