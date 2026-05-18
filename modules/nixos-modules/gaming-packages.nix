{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.nix-ld.enable = true;

  hardware.graphics.enable32Bit = true;
  hardware.steam-hardware.enable = true;

  programs = {
    gamescope.enable = true;
    gamemode.enable = true;
  };

  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    (pkgs.callPackage "${inputs.severed-chains}/nix/package.nix" { src = inputs.severed-chains; })
    (openraPackages.engines.bleed.overrideAttrs (old: {
      postPatch = "";
    }))
    protonup-qt
  ];

  environment.persistence."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/openra"
  ];
}
