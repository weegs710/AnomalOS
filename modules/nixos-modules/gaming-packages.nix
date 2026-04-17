{inputs, ...}: {
  flake.nixosModules.gaming-packages = {
    config,
    pkgs,
    ...
  }: {
    programs.nix-ld.enable = true;

    hardware.steam-hardware.enable = true;

    programs = {
      gamescope.enable = true;
      gamemode.enable = true;
    };

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      inputs.severed-chains.packages.${pkgs.stdenv.hostPlatform.system}.default
      (openraPackages.engines.bleed.overrideAttrs (old: {
        postPatch = "";
      }))
      protonup-qt
    ];
  };
}
