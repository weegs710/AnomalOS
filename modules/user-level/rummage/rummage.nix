{
  only = {
    tags = [ "desktop" ];
  };
  module =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      username = config.mySystem.user.name;
    in
    {
      imports = [ inputs.rummage.nixosModules.default ];

      programs.rummage = {
        enable = true;
        filePicker = {
          enable = true;
          desktops = [ "umbriel" ];
        };
      };

      # rummage finds extractors on PATH; plain _7zz lacks the rar codec, and file-roller refuses encrypted 7z and rar
      users.users.${username}.packages = [ pkgs._7zz-rar ];

      hjem.users.${username}.xdg.config.files = {
        # read from the package so the template moves with every bump; ~ because output_path does not expand $HOME
        "noctalia/rummage.toml".text = ''
          [theme.templates.user.rummage]
          input_path  = "${config.programs.rummage.package}/share/rummage/noctalia/rummage"
          output_path = "~/.config/rummage/colors.toml"
        '';

        "rummage/config.toml".text = ''
          # family is parsed as a fontconfig pattern, so "sans-serif" comes out as family "sans"
          [font]
          family = "SpaceGrotesk Nerd Font Propo"
          monospace = "SpaceMono Nerd Font Mono"

          [status_bar]
          text_size = 15.0

          [icon]
          theme = "builtin"
        '';
      };

      # noctalia writes colors.toml beside the linked config
      preservation.preserveAt."/persist".users.${username}.directories = [
        ".config/rummage"
        ".local/state/rummage"
      ];
    };
}
