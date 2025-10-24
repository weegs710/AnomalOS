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

    home-manager.users.${config.mySystem.user.name} = {
      programs.zed-editor = {
        enable = true;

        extensions = ["nix"];

        extraPackages = with pkgs; [
          nixd
          alejandra
        ];

        userSettings = {
          telemetry = {
            diagnostics = false;
            metrics = false;
          };

          terminal = {
            font_family = lib.mkForce "Terminess Nerd Font";
            font_size = lib.mkForce 16;
          };

          buffer_font_family = lib.mkForce "Terminess Nerd Font";
          buffer_font_size = lib.mkForce 16;

          git = {
            git_gutter = "tracked_files";
            inline_blame.enabled = false;
          };

          features.edit_prediction_provider = "copilot";

          lsp.nixd.settings = {
            nixpkgs.expr = "import (builtins.getFlake \"/home/weegs/dotfiles\").inputs.nixpkgs { }";
            formatting.command = ["alejandra" "--quiet"];
            options = {
              nixos.expr = "(builtins.getFlake \"/home/weegs/dotfiles\").nixosConfigurations.Rig.options";
              home-manager.expr = "(builtins.getFlake \"/home/weegs/dotfiles\").nixosConfigurations.Rig.options.home-manager.users.type.getSubOptions []";
            };
          };
        };
      };

      stylix.targets.zed.enable = true;
    };
  };
}
