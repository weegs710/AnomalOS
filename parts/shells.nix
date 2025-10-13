{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nixfmt-rfc-style
        nil
        git
      ];
    };
  };
}
