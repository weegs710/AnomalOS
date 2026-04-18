{
  perSystem = {pkgs, ...}: let
    lspTools = with pkgs; [
      basedpyright
      biome
      clippy
      hyprls
      marksman
      nil
      nixd
      nixfmt
      nufmt
      ruff
      rust-analyzer
      rustfmt
      # tsserver resolves typescript from PATH at runtime, not bundled
      typescript
      typescript-language-server
      vscode-langservers-extracted
    ];

    wrappedFresh = pkgs.symlinkJoin {
      name = "fresh-editor-wrapped";
      paths = [pkgs.fresh-editor];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/fresh \
          --prefix PATH : ${pkgs.lib.makeBinPath lspTools} \
          --run 'cd "$HOME/dotfiles"'
      '';
      meta.mainProgram = "fresh";
    };
  in {
    packages.fresh-editor = wrappedFresh;
  };
}
