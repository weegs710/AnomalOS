{
  config,
  pkgs,
  only,
  ...
}:
let
  username = config.mySystem.user.name;
in
only.gate { tags = [ "dev" ]; } {
  users.users.${username}.packages = with pkgs; [
    pandoc
    python3Packages.weasyprint
  ];

  hjem.users.${username} = {
    xdg.data.files."pandoc/defaults.yaml".source = ./pandoc-defaults.yaml;
  };
}
