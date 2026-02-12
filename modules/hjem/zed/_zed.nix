{inputs, ...}: {
  flake.nixosModules.zed = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedZed = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.zed;
    flakePath = "${config.users.users.${username}.home}/dotfiles";
    hostName = config.networking.hostName;
    settingsJson = pkgs.writeText "zed-settings.json" (builtins.toJSON {
      theme = "Noctalia Dark";
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      terminal.font_size = 16;
      buffer_font_size = 16;
      git = {
        git_gutter = "tracked_files";
        inline_blame.enabled = false;
      };
      extensions = ["nix" "basedpyright" "ruff"];
      languages.Python = {
        language_servers = ["basedpyright" "ruff"];
        format_on_save = "on";
        formatter.external = {
          command = "ruff";
          arguments = ["format" "-"];
        };
      };
      lsp = {
        nil.initialization_options = {
          formatting.command = ["alejandra" "--quiet"];
          nix.flake.autoArchive = true;
        };
        nixd.settings = {
          nixpkgs.expr = "import (builtins.getFlake \"${flakePath}\").inputs.nixpkgs { }";
          formatting.command = ["alejandra" "--quiet"];
          options.nixos.expr = "(builtins.getFlake \"${flakePath}\").nixosConfigurations.${hostName}.options";
        };
        basedpyright.settings.basedpyright.analysis = {
          typeCheckingMode = "standard";
          diagnosticSeverityOverrides = {
            reportUnusedImport = "warning";
            reportUnusedVariable = "warning";
          };
        };
        ruff.initialization_options.settings = {
          lineLength = 88;
          lint.select = ["E" "F" "I"];
        };
      };
    });
  in
    with lib; {
      config = mkIf config.mySystem.features.development {
        users.users.${username}.packages = [ wrappedZed ];

        hjem.users.${username} = {
          xdg.config.files."zed/settings.json" = {
            source = settingsJson;
            type = "copy";
            permissions = "0644";
          };
        };
      };
    };
}
