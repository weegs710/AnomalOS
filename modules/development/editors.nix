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

    # VSCodium with GitHub Copilot support in home-manager
    home-manager.users.${config.mySystem.user.name} = {
      programs.vscode = {
        enable = true;
        package = pkgs.vscodium.overrideAttrs (oldAttrs: {
          postInstall = (oldAttrs.postInstall or "") + ''
            # Add trustedExtensionAuthAccess for GitHub Copilot authentication
            substituteInPlace $out/lib/vscode/resources/app/product.json \
              --replace-fail \
              '"extensionKind": {' \
              '"trustedExtensionAuthAccess": ["GitHub.copilot","GitHub.copilot-chat"],"extensionKind": {'
          '';
        });
        profiles.default.userSettings = {
          "workbench.colorTheme" = "Stylix";
          "security.workspace.trust.untrustedFiles" = "open";
          "workbench.startupEditor" = "none";
          "git.openRepositoryInParentFolders" = "always";
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "workbench.activityBar.location" = "bottom";
          "terminal.integrated.fontFamily" = lib.mkForce "Terminess Nerd Font";
          "terminal.integrated.fontSize" = lib.mkForce 12;
          "editor.fontFamily" = lib.mkForce "'Terminess Nerd Font', monospace";
          "editor.fontSize" = lib.mkForce 12;

          # Disable auto-updates for manually installed extensions
          "extensions.autoUpdate" = false;
        };
      };
    };
  };
}
