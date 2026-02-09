{...}: {
  perSystem = {pkgs, ...}: let
    lspTools = with pkgs; [
      nil
      nixd
      alejandra
      basedpyright
      ruff
    ];

    wrappedFlow = pkgs.symlinkJoin {
      name = "flow-control-wrapped";
      paths = [pkgs.flow-control];
      buildInputs = lspTools;
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/flow \
          --prefix PATH : ${pkgs.lib.makeBinPath lspTools}
      '';
      meta.mainProgram = "flow";
    };
  in {
    packages.flow-control = wrappedFlow;
  };
}
