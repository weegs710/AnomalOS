# Wrapped zed-editor with LSP tools and config
# Run with: nix run github:weegs710/AnomalOS#zed
{
  perSystem = { pkgs, lib, ... }:
    let
      lspTools = with pkgs; [
        nixd
        nil
        alejandra
        basedpyright
        ruff
      ];

      wrappedZed = pkgs.symlinkJoin {
        name = "zed-wrapped";
        paths = [ pkgs.zed-editor ];
        buildInputs = lspTools;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/zeditor \
            --prefix PATH : ${pkgs.lib.makeBinPath lspTools}
        '';
        meta.mainProgram = "zeditor";
      };
    in
    {
      packages.zed = wrappedZed;
    };
}
