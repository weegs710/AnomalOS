{...}: {
  flake.nixosModules.writing-tools = {
    config,
    pkgs,
    ...
  }: {
    config = {
      home-manager.users.${config.mySystem.user.name} = {
        programs.pandoc = {
          enable = true;
          defaults = {
            pdf-engine = "weasyprint";
          };
        };

        home.packages = with pkgs; [
          python3Packages.weasyprint
          wkhtmltopdf
        ];
      };
    };
  };
}
