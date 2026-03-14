{
  flake.nixosModules.writing-tools = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = lib.mkIf config.mySystem.features.development {
      users.users.${username}.packages = with pkgs; [
        pandoc
        python3Packages.weasyprint
        wkhtmltopdf
      ];

      hjem.users.${username} = {
        xdg.data.files."pandoc/defaults.yaml".text = ''
          pdf-engine: weasyprint
        '';
      };
    };
  };
}
