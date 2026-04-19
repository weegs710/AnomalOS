{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
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
      };
    };
}
