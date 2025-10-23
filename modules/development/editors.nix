{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config = mkIf config.mySystem.features.development {
    # Development programs
    programs = {
      tmux.enable = true;
      starship.enable = true;
    };

    # Home Manager configuration for editors
    home-manager.users.${config.mySystem.user.name} = {
      # Zed Editor with full Nix development support
      programs.zed-editor = {
        enable = true;

        # Nix extension for language support
        extensions = [
          "nix"
        ];

        # LSP servers and formatters
        extraPackages = with pkgs; [
          nixd # Modern Nix LSP with flake support
          alejandra # Nix code formatter
        ];

        # User settings
        userSettings = {
          # Disable telemetry completely
          telemetry = {
            diagnostics = false;
            metrics = false;
          };

          # Terminal configuration (matching Codium settings)
          terminal = {
            font_family = lib.mkForce "Terminess Nerd Font";
            font_size = lib.mkForce 16;
          };

          # Editor font settings (matching Codium settings)
          buffer_font_family = lib.mkForce "Terminess Nerd Font";
          buffer_font_size = lib.mkForce 16;

          # Git integration
          git = {
            git_gutter = "tracked_files"; # Show git changes in gutter
            inline_blame = {
              enabled = false; # Disable inline git blame
            };
          };

          # GitHub Copilot for inline code completions
          features = {
            edit_prediction_provider = "copilot";
          };

          # LSP configuration for nixd
          lsp = {
            nixd = {
              settings = {
                # Point to your flake's nixpkgs for package completion
                nixpkgs = {
                  expr = "import (builtins.getFlake \"/home/weegs/dotfiles\").inputs.nixpkgs { }";
                };

                # Formatting with alejandra
                formatting = {
                  command = [
                    "alejandra"
                    "--quiet"
                  ];
                };

                # Options completion for NixOS configuration
                options = {
                  nixos = {
                    expr = "(builtins.getFlake \"/home/weegs/dotfiles\").nixosConfigurations.Rig.options";
                  };
                  home-manager = {
                    expr = "(builtins.getFlake \"/home/weegs/dotfiles\").nixosConfigurations.Rig.options.home-manager.users.type.getSubOptions []";
                  };
                };
              };
            };
          };
        };
      };

      # Enable Stylix theming for Zed
      stylix.targets.zed.enable = true;
    };
  };
}
