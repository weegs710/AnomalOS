{...}: {
  # Development shell for working on this configuration
  # Usage: nix develop

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
