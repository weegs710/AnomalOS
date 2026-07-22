# Plain devshell (was a flake-parts perSystem). Enter with: nix-shell devshell.nix
{
  pkgs ? import (import ./.tack).nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  },
  weegsware ? (import ./assemble.nix { }).packages."x86_64-linux",
}:
pkgs.mkShell {
  # wrapped nu so editor terminals loading this devshell keep atuin/zoxide/etc on PATH; bare pkgs.nushell shadows it and breaks the atuin hooks
  shellPackage = weegsware.nushell;

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
    nvfetcher
    weegsware.nushell
    ruff
    rust-analyzer
    rustfmt
    # tsserver resolves typescript from PATH at runtime, not bundled
    typescript
    typescript-language-server
    vscode-langservers-extracted
  ];
}
