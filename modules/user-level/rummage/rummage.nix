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
        filePicker.enable = true;
        preview = {
          thumbnails = true;
          pdf = true;
        };
      };

      nix.settings = {
        substituters = [ "https://rummage-fm.cachix.org" ];
        trusted-public-keys = [ "rummage-fm.cachix.org-1:fhPhaCttVfPBS/i//+Z+6Ch0xdxj9g94eZdQ5m6mlwA=" ];
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
          [animations]
          duration_scale = 0.5
          quality = "high"

          [animations.events]
          directory_open = "ink_bleed"
          directory_back = "fade"
          view_change = "ripple"
          focus_change = "energy_trace"
          quick_look = "scale"

          [animations.durations]
          view_change = 180

          [status_bar]
          text_size = 15.0

          [startup]
          mode = "home"

          # family is parsed as a fontconfig pattern, so "sans-serif" comes out as family "sans"
          [font]
          family = "SpaceGrotesk Nerd Font Propo"
          size = 15.0
          monospace = "SpaceMono Nerd Font Mono"

          # own app-id so umbriel floats it on the current workspace instead of the main kitty's rule
          [terminal]
          program = "kitty"
          args = ["--class", "rummage-term"]

          [icon]
          theme = "builtin"

          [keybindings]
          toggle_hidden = "period"

          [[actions]]
          id = "annotate-satty"
          label = "Annotate in satty"
          argv = ["satty", "-f", "{file}"]
          mime = ["image/*"]
          placement = "menu"
        '';
      };

      # noctalia writes colors.toml beside the linked config
      preservation.preserveAt."/persist".users.${username}.directories = [
        ".config/rummage"
        ".local/state/rummage"
      ];
    };
}
