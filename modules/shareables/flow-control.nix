{
  perSystem = {pkgs, ...}: let
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

    flow-control = pkgs.flow-control.overrideAttrs (oldAttrs: rec {
      version = "0.7.2";
      src = pkgs.fetchFromGitHub {
        owner = "neurocyte";
        repo = "flow";
        rev = "v${version}";
        hash = "sha256-5+F0DKb4LXtcMXNutUSJuIe7cdBoFUoJhCs8vbm20jg=";
      };

      postConfigure = ''
        ln -s ${zigPackages} $ZIG_GLOBAL_CACHE_DIR/p
      '';

      # Symlink UCD files so uucode_build_tables can find them without setCwd
      preBuild = ''
        ln -s ${zigPackages}/uucode-0.1.0-ZZjBPj96QADXyt5sqwBJUnhaDYs_qBeeKijZvlRa0eqM/ucd ./ucd
      '';

      env =
        oldAttrs.env
        // {
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

    flowWrapper = pkgs.writeScript "flow-wrapper" ''
      #!/usr/bin/env nu

      def main [...args] {
        let flow_config_dir = ($env.XDG_CONFIG_HOME? | default $"($env.HOME)/.config") + "/flow"
        let flow_state_dir = ($env.XDG_STATE_HOME? | default $"($env.HOME)/.local/state") + "/flow"
        let flow_custom_config = $"($flow_config_dir)/custom_config"
        let flow_custom_home = $"($flow_config_dir)/custom_home"
        let flow_main_config = $"($flow_config_dir)/config"
        let flow_home_style = $"($flow_config_dir)/home.style"

        mkdir $flow_config_dir
        mkdir $"($flow_state_dir)/projects"

        if not ($flow_custom_config | path exists) {
          cp ${customConfig} $flow_custom_config
        }

        if not ($flow_custom_home | path exists) {
          cp ${customHome} $flow_custom_home
        }

        if not ($flow_main_config | path exists) {
          $'include_files "($flow_custom_config)"' | save $flow_main_config
        } else if (open $flow_main_config | str contains $'include_files "($flow_custom_config)"' | not $in) {
          $"\ninclude_files \"($flow_custom_config)\"" | save --append $flow_main_config
        }

        if not ($flow_home_style | path exists) {
          $'include_files "($flow_custom_home)"' | save $flow_home_style
        } else if (open $flow_home_style | str contains $'include_files "($flow_custom_home)"' | not $in) {
          $"\ninclude_files \"($flow_custom_home)\"" | save --append $flow_home_style
        }

        ^${flow-control}/bin/flow ...$args
      }
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
