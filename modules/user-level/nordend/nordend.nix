{
  only = {
    tags = [ "desktop" ];
  };
  module =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.mySystem.user.name;
      unlock = pkgs.writers.writeNuBin "nordend-unlock" (
        lib.replaceStrings
          [ "@7ZZ@" "@KITTY@" "@STTY@" ]
          [ (lib.getExe pkgs._7zz-rar) (lib.getExe pkgs.kitty) "${pkgs.coreutils}/bin/stty" ]
          (builtins.readFile ./nordend-unlock.nu)
      );
    in
    {
      imports = [ inputs.nordend.nixosModules.default ];

      programs.nordend = {
        enable = true;
        # the status bar's text size is a constant no setting reaches; replace-fail breaks the build if the line moves
        package = inputs.nordend.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace src/views/src/status_bar.cpp \
              --replace-fail "kTextSize = 12.0F" "kTextSize = 15.0F"
          '';
        });
        filePicker = {
          enable = true;
          desktops = [ "umbriel" ];
        };
      };

      hjem.users.${username}.xdg.config.files = {
        # read from the package so the template moves with every bump; ~ because output_path does not expand $HOME
        "noctalia/nordend.toml".text = ''
          [theme.templates.user.nordend]
          input_path  = "${config.programs.nordend.package}/share/nordend/noctalia/nordend"
          output_path = "~/.config/nordend/colors.toml"
        '';

        # file-roller's libarchive refuses encrypted 7z and rar, and nordend's 7zz path runs with -p-
        "nordend/config.toml".text = ''
          # family is parsed as a fontconfig pattern, so "sans-serif" comes out as family "sans"
          [font]
          family = "SpaceGrotesk Nerd Font Propo"
          monospace = "SpaceMono Nerd Font Mono"

          [icon]
          theme = "builtin"

          [[actions]]
          id = "extract-password"
          label = "Extract With Password"
          argv = ["${unlock}/bin/nordend-unlock", "{file}"]
          mime = ["application/x-7z-compressed", "application/vnd.rar"]
          selection = "one"
          placement = "menu"
          notify_on_completion = true
        '';
      };

      # noctalia writes colors.toml beside the linked config
      preservation.preserveAt."/persist".users.${username}.directories = [
        ".config/nordend"
        ".local/state/nordend"
      ];
    };
}
