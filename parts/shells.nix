{...}: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nixfmt-rfc-style
        nixd
        git
      ];
    };
  };
}
