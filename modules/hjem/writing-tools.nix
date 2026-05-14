{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = with pkgs; [
    pandoc
    python3Packages.weasyprint
  ];

  hjem.users.${username} = {
    xdg.data.files."pandoc/defaults.yaml".text = ''
      pdf-engine: weasyprint
    '';
  };
}
