{...}: {
  perSystem = {pkgs, ...}: let
    lspTools = with pkgs; [
      nil
      nixd
      alejandra
      basedpyright
      ruff
    ];

    customConfig = ../hjem/flow-control/custom_config;

    flowWrapper = pkgs.writeShellScript "flow-wrapper" ''
      FLOW_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/flow"
      FLOW_CUSTOM_CONFIG="$FLOW_CONFIG_DIR/custom_config"
      FLOW_MAIN_CONFIG="$FLOW_CONFIG_DIR/config"

      mkdir -p "$FLOW_CONFIG_DIR"

      if [ ! -f "$FLOW_CUSTOM_CONFIG" ]; then
        cp ${customConfig} "$FLOW_CUSTOM_CONFIG"
      fi

      if [ ! -f "$FLOW_MAIN_CONFIG" ]; then
        echo 'include_files "'"$FLOW_CUSTOM_CONFIG"'"' > "$FLOW_MAIN_CONFIG"
      elif ! grep -q "include_files" "$FLOW_MAIN_CONFIG"; then
        echo 'include_files "'"$FLOW_CUSTOM_CONFIG"'"' >> "$FLOW_MAIN_CONFIG"
      fi

      exec ${pkgs.flow-control}/bin/flow "$@"
    '';

    wrappedFlow = pkgs.symlinkJoin {
      name = "flow-control-wrapped";
      paths = [pkgs.flow-control];
      buildInputs = lspTools;
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        rm $out/bin/flow
        makeWrapper ${flowWrapper} $out/bin/flow \
          --prefix PATH : ${pkgs.lib.makeBinPath lspTools}
      '';
      meta.mainProgram = "flow";
    };
  in {
    packages.flow-control = wrappedFlow;
  };
}
