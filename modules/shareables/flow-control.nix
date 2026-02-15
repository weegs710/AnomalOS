{
  perSystem = {pkgs, ...}: let
    lspTools = with pkgs; [
      nil
      nixd
      alejandra
      basedpyright
      ruff
      vscode-langservers-extracted
      hyprls
      marksman
    ];

    customConfig = ../hjem/flow-control/custom_config;
    customHome = ../hjem/flow-control/custom_home;

    flowWrapper = pkgs.writeShellScript "flow-wrapper" ''
      FLOW_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/flow"
      FLOW_STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/flow"
      FLOW_CUSTOM_CONFIG="$FLOW_CONFIG_DIR/custom_config"
      FLOW_CUSTOM_HOME="$FLOW_CONFIG_DIR/custom_home"
      FLOW_MAIN_CONFIG="$FLOW_CONFIG_DIR/config"
      FLOW_HOME_STYLE="$FLOW_CONFIG_DIR/home.style"

      mkdir -p "$FLOW_CONFIG_DIR"
      mkdir -p "$FLOW_STATE_DIR/projects"

      if [ ! -f "$FLOW_CUSTOM_CONFIG" ]; then
        cp ${customConfig} "$FLOW_CUSTOM_CONFIG"
      fi

      if [ ! -f "$FLOW_CUSTOM_HOME" ]; then
        cp ${customHome} "$FLOW_CUSTOM_HOME"
      fi

      if [ ! -f "$FLOW_MAIN_CONFIG" ]; then
        echo 'include_files "'"$FLOW_CUSTOM_CONFIG"'"' > "$FLOW_MAIN_CONFIG"
      elif ! grep -q "include_files" "$FLOW_MAIN_CONFIG"; then
        echo 'include_files "'"$FLOW_CUSTOM_CONFIG"'"' >> "$FLOW_MAIN_CONFIG"
      fi

      if [ ! -f "$FLOW_HOME_STYLE" ]; then
        echo 'include_files "'"$FLOW_CUSTOM_HOME"'"' > "$FLOW_HOME_STYLE"
      elif ! grep -q '^include_files' "$FLOW_HOME_STYLE"; then
        echo 'include_files "'"$FLOW_CUSTOM_HOME"'"' >> "$FLOW_HOME_STYLE"
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
