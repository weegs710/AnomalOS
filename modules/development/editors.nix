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
        };
      };
    };
  };
}
