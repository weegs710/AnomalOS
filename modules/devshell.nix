{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nil
        nixd
        alejandra
        git
        marksman
        vscode-langservers-extracted
      ];
    };
  };
}
