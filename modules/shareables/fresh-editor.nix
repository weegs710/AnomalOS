{
  perSystem = {pkgs, ...}: let
    lspTools = with pkgs; [
      nixd
      nil
      alejandra
      basedpyright
      ruff
      vscode-langservers-extracted
      hyprls
      marksman
      nufmt
    ];

    wrappedFresh = pkgs.symlinkJoin {
      name = "fresh-editor-wrapped";
      paths = [pkgs.fresh-editor];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/fresh \
          --prefix PATH : ${pkgs.lib.makeBinPath lspTools}
      '';
      meta.mainProgram = "fresh";
    };
  in {
    packages.fresh-editor = wrappedFresh;
  };
}
