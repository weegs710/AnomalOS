{inputs, ...}: {
  flake.nixosModules.packages = {
    config,
    pkgs,
    ...
  }: {
    config = {
      home-manager.users.${config.mySystem.user.name} = {
        home.packages = with pkgs; [
          inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
          alejandra
          cliphist
          fastfetch
          fzf
          gh
          gparted
          grim
          hyprls
          hyprshot
          jq
          nodejs
          obsidian
          pamixer
          python3
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
      };
    };
  };
}
