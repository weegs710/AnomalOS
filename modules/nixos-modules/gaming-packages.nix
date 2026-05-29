{
  config,
  pkgs,
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
    (openraPackages.engines.bleed.overrideAttrs (old: {
      postPatch = "";
    }))
    protonup-qt
  ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/openra"
  ];
}
