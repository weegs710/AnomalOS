{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    superfilePkg = pkgs.superfile.overrideAttrs (old: {
      version = "1.5.0";
      src = pkgs.fetchFromGitHub {
        owner = "yorukot";
        repo = "superfile";
        rev = "v1.5.0";
        hash = "sha256-PEojifuiIjF3OUxDoMCyynOJUpFglTzh7lJUcq7g4e0=";
      };
      vendorHash = "sha256-5SSnrG3DvD1i7rNcpztHkUUap4Qp7MX04ofD7rA3xgM=";
      patches = (old.patches or []) ++ [./superfile-chooser-multi];
      doCheck = false;
    });

    extraTools = with pkgs; [exiftool glib zoxide ffmpeg poppler-utils];

    wrappedSuperfile = pkgs.symlinkJoin {
      name = "superfile-wrapped";
      paths = [superfilePkg];
      buildInputs = extraTools;
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/superfile \
          --prefix PATH : ${pkgs.lib.makeBinPath extraTools}
      '';
      meta.mainProgram = "superfile";
    };
  in {
    packages.superfile = wrappedSuperfile;
  };

  flake.nixosModules.superfile = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    homeDir = config.users.users.${username}.home;
    wrappedSuperfile = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.superfile;
    wrapperScript = pkgs.writeText "superfile-wrapper.nu" ''
      #!${pkgs.nushell}/bin/nu

      def main [
          multiple: string,
          directory: string,
          save: string,
          path: string,
          out: string,
          debug?: string,
      ] {
          # superfile exposes no save/directory/multiple protocol; --chooser-file covers all modes
          ghostty --title=termfilechooser -e superfile $"--chooser-file=($out)" $path
      }
    '';
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [wrappedSuperfile];

      hjem.users.${username}.xdg.config.files = {
        "xdg-desktop-portal-termfilechooser/config".text = ''
          [filechooser]
          cmd=${homeDir}/.config/xdg-desktop-portal-termfilechooser/superfile-wrapper.nu
          default_dir=$HOME
          create_help_file=0
        '';

        # portal searches lowercase; hyprland pkg ships its own hyprland-portals.conf which wins otherwise
        "xdg-desktop-portal/hyprland-portals.conf".text = ''
          [preferred]
          default=hyprland;gtk
          org.freedesktop.impl.portal.FileChooser=termfilechooser;gtk
          org.freedesktop.impl.portal.ScreenCast=hyprland
          org.freedesktop.impl.portal.Screenshot=hyprland
        '';

        "xdg-desktop-portal-termfilechooser/superfile-wrapper.nu" = {
          source = wrapperScript;
          type = "copy";
          permissions = "0755";
        };
      };
    };
  };
}
