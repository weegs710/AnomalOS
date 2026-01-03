{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.development {
    # Development programs
    programs = {
      tmux.enable = true;
      starship.enable = true;
    };

    home-manager.users.${config.mySystem.user.name} = {
      programs.zed-editor = {
        enable = true;

        extensions = ["nix" "basedpyright" "ruff"];

        extraPackages = with pkgs; [
          # Nix language servers
          nixd
          nil
          alejandra

          # Python language servers
          basedpyright
          ruff
        ];

        userSettings = {
          telemetry = {
            diagnostics = false;
            metrics = false;
          };

          terminal = {
            font_size = lib.mkForce 16;
          };

          buffer_font_size = lib.mkForce 16;

          git = {
            git_gutter = "tracked_files";
            inline_blame.enabled = false;
          };

          languages = {
            Python = {
              language_servers = ["basedpyright" "ruff"];
              format_on_save = "on";
              formatter = {
                external = {
                  command = "ruff";
                  arguments = ["format" "-"];
                };
              };
            };
          };

          lsp = {
            nil = {
              initialization_options = {
                formatting.command = ["alejandra" "--quiet"];
                nix.flake.autoArchive = true;
              };
            };

            nixd.settings = let
              flakePath = "${config.users.users.${config.mySystem.user.name}.home}/dotfiles";
              hostName = "${config.networking.hostName}";
            in {
              nixpkgs.expr = "import (builtins.getFlake \"${flakePath}\").inputs.nixpkgs { }";
              formatting.command = ["alejandra" "--quiet"];
              options = {
                nixos.expr = "(builtins.getFlake \"${flakePath}\").nixosConfigurations.${hostName}.options";
                home-manager.expr = "(builtins.getFlake \"${flakePath}\").nixosConfigurations.${hostName}.options.home-manager.users.type.getSubOptions []";
              };
            };

            basedpyright.settings = {
              basedpyright = {
                analysis = {
                  typeCheckingMode = "standard";
                  diagnosticSeverityOverrides = {
                    reportUnusedImport = "warning";
                    reportUnusedVariable = "warning";
                  };
                };
              };
            };

            ruff = {
              initialization_options = {
                settings = {
                  lineLength = 88;
                  lint = {
                    select = ["E" "F" "I"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
