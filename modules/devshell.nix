{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      shellPackage = pkgs.nushell;

      buildInputs = with pkgs; [
        # Nix
        nil
        nixd
        alejandra

        # Nushell
        nushell
        nufmt

        # Python
        basedpyright
        ruff

        # Hyprlang
        hyprls

        # General
        git
        marksman
        vscode-langservers-extracted
      ];
    };
  };
}
