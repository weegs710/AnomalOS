# Plain devshell (was a flake-parts perSystem). Enter with: nix-shell devshell.nix
{
  pkgs ? import (import ./.tack).nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  },
}:
pkgs.mkShell {
  shellPackage = pkgs.nushell;

  buildInputs = with pkgs; [
    basedpyright
    biome
    clippy
    dprint
    git
    hyprls
    marksman
    nil
    nixd
    nixfmt
    nufmt
    nushell
    ruff
    rust-analyzer
    rustfmt
    # tsserver resolves typescript from PATH at runtime, not bundled
    typescript
    typescript-language-server
    vscode-langservers-extracted
  ];
}
