{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  sources = import ../../../../_sources/generated.nix {
    inherit (pkgs)
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };

  # .NET FailFasts at startup when no ICU is present in the FHS rootfs
  evelens = pkgs.appimageTools.wrapType2 {
    inherit (sources.evelens) pname version src;
    extraPkgs = p: [ p.icu ];
  };
in
{
  users.users.${username}.packages = [
    evelens
    pkgs.pyfa
  ];

  # config.nu resolves the bare filename relative to itself, so this has to land beside it
  hjem.users.${username}.xdg.config.files."nushell/eve.nu".source = ./eve.nu;

  mySystem.nushell.extraConfig = ''

    use eve.nu *
  '';

  # ESI tokens and the cached SDE are runtime-written, so no module can own them declaratively
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/EveLens"
    ".pyfa"
  ];
}
