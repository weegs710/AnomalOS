{inputs, ...}: {
  flake.nixosModules.flow-control = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedFlow = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.flow-control;
    flakePath = "${config.users.users.${username}.home}/dotfiles";
    hostName = config.networking.hostName;

    nixFileTypeConf = pkgs.writeText "nix.conf" ''
      .{
          .language_server = .{ "nixd" },
          .formatter = .{ "alejandra" },
      }
    '';

    nixdLspJson = pkgs.writeText "nixd.json" (builtins.toJSON {
      nixpkgs.expr = "import (builtins.getFlake \"${flakePath}\").inputs.nixpkgs { }";
      formatting.command = ["alejandra" "--quiet"];
      options.nixos.expr = "(builtins.getFlake \"${flakePath}\").nixosConfigurations.${hostName}.options";
    });

    pythonFileTypeConf = pkgs.writeText "python.conf" ''
      .{
          .language_server = .{ "basedpyright" },
          .formatter = .{ "ruff", "format", "-" },
      }
    '';

    basedpyrightLspJson = pkgs.writeText "basedpyright.json" (builtins.toJSON {
      basedpyright.analysis = {
        typeCheckingMode = "standard";
        diagnosticSeverityOverrides = {
          reportUnusedImport = "warning";
          reportUnusedVariable = "warning";
        };
      };
    });

    ruffLspJson = pkgs.writeText "ruff.json" (builtins.toJSON {
      settings = {
        lineLength = 88;
        lint.select = ["E" "F" "I"];
      };
    });
  in
    with lib; {
      config = mkIf config.mySystem.features.development {
        users.users.${username}.packages = [wrappedFlow];

        hjem.users.${username} = {
          xdg.config.files."flow/file_type/nix.conf" = {
            source = nixFileTypeConf;
            type = "copy";
            permissions = "0644";
          };

          xdg.config.files."flow/lsp/nixd.json" = {
            source = nixdLspJson;
            type = "copy";
            permissions = "0644";
          };

          xdg.config.files."flow/file_type/python.conf" = {
            source = pythonFileTypeConf;
            type = "copy";
            permissions = "0644";
          };

          xdg.config.files."flow/lsp/basedpyright.json" = {
            source = basedpyrightLspJson;
            type = "copy";
            permissions = "0644";
          };

          xdg.config.files."flow/lsp/ruff.json" = {
            source = ruffLspJson;
            type = "copy";
            permissions = "0644";
          };
        };
      };
    };
}
