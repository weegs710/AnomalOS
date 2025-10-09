{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.development {
    # Add development editors to user packages
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      # zed-editor

      # VSCodium with GitHub Copilot support
      (vscodium.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          # Add trustedExtensionAuthAccess for GitHub Copilot authentication
          substituteInPlace $out/lib/vscode/resources/app/product.json \
            --replace-fail \
            '"extensionKind": {' \
            '"trustedExtensionAuthAccess": ["GitHub.copilot","GitHub.copilot-chat"],"extensionKind": {'
        '';
      }))
    ];

    # Development programs
    programs = {
      tmux.enable = true;
      starship.enable = true;
    };
  };
}
