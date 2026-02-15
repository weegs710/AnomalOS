{
  perSystem = {pkgs, ...}: let
    # Build dependencies package for flow-control 0.7.2
    zigPackagesRaw = import ../../deps/flow-control-build.zig.zon.nix {
      inherit (pkgs) lib linkFarm fetchurl fetchgit runCommandLocal;
      zig = pkgs.zig_0_15;
    };

    # Patch uucode to remove problematic setCwd that breaks in Nix sandbox
    zigPackages = pkgs.runCommand "zig-packages-patched" {} ''
      mkdir -p $out
      cp -rL ${zigPackagesRaw}/. $out
      chmod -R +w $out

      substituteInPlace $out/uucode-0.1.0-ZZjBPj96QADXyt5sqwBJUnhaDYs_qBeeKijZvlRa0eqM/build.zig \
        --replace-fail 'run_build_tables_exe.setCwd(b.path(""));' '// setCwd removed - UCD files symlinked to build dir instead'
    '';

    # Override flow-control to use latest upstream version
    flow-control = pkgs.flow-control.overrideAttrs (oldAttrs: rec {
      version = "0.7.2";
      src = pkgs.fetchFromGitHub {
        owner = "neurocyte";
        repo = "flow";
        rev = "v${version}";
        hash = "sha256-5+F0DKb4LXtcMXNutUSJuIe7cdBoFUoJhCs8vbm20jg=";
      };

      # Use updated build.zig.zon.nix with 0.7.2 dependencies (pre-patched)
      postConfigure = ''
        ln -s ${zigPackages} $ZIG_GLOBAL_CACHE_DIR/p
      '';

      # Symlink UCD files so uucode_build_tables can find them without setCwd
      preBuild = ''
        ln -s ${zigPackages}/uucode-0.1.0-ZZjBPj96QADXyt5sqwBJUnhaDYs_qBeeKijZvlRa0eqM/ucd ./ucd
      '';

      # Ensure VERSION env var is set for build.zig
      env = oldAttrs.env // {
        VERSION = version;
      };
    });

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

      exec ${flow-control}/bin/flow "$@"
    '';

    wrappedFlow = pkgs.symlinkJoin {
      name = "flow-control-wrapped";
      paths = [flow-control];
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
