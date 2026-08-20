{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  dataDir = ".local/share/zelda3";

  src = pkgs.fetchFromGitHub {
    owner = "snesrev";
    repo = "zelda3";
    rev = "v0.3";
    hash = "sha256-jKCLZ8lqvkN6OmYTZtjxXgbeUUnzOtYaeWmc4rCwwF0=";
  };

  glslShadersSrc = pkgs.fetchFromGitHub {
    owner = "libretro";
    repo = "glsl-shaders";
    rev = "2b2c5ee3fd8e1a3884e20ed424fd9bfbc51cbb3d";
    hash = "sha256-cVKwHyz7G8i7Ale87I3mH7GR/EBi42AFsBU0KIdlj9g=";
  };

  # glslp paths resolve relative to the glslp, not the cwd
  glslShaders = pkgs.runCommand "zelda3-glsl-shaders" { } ''
    cp -rs ${glslShadersSrc} $out
    chmod -R u+w $out
    cp ${./scalefx-raa-level2aa.glslp} $out/presets/scalefx-raa-level2aa.glslp

    # zelda3 never binds PassPrev[pass]; Orig is the same texture
    rm $out/scalefx/shaders/scalefx-pass4.glsl
    sed 's/PassPrev5/Orig/g' \
      ${glslShadersSrc}/scalefx/shaders/scalefx-pass4.glsl \
      > $out/scalefx/shaders/scalefx-pass4.glsl
  '';

  zelda3 = pkgs.stdenv.mkDerivation {
    pname = "zelda3";
    version = "0.3";
    inherit src;
    buildInputs = [ pkgs.SDL2 ];
    # v0.3 predates C23; gnu17 keeps empty-paren protos as unspecified-args (gcc14 defaults to gnu23 where () means (void)), and -Wno-error disarms the Makefile's -Werror
    env.NIX_CFLAGS_COMPILE = "-std=gnu17 -Wno-error";
    buildPhase = "make zelda3";
    installPhase = "install -Dm755 zelda3 $out/bin/zelda3";
  };

  # zelda3 reads zelda3_assets.dat + zelda3.ini + saves from CWD (no XDG/env override), so launch it from the persisted data dir
  zelda3-wrapped = pkgs.writeShellScriptBin "zelda3" ''
    d="$HOME/${dataDir}"
    mkdir -p "$d"
    ln -sfn ${glslShaders} "$d/glsl-shaders"
    cd "$d"
    exec ${zelda3}/bin/zelda3 "$@"
  '';
in
{
  users.users.${username}.packages = [
    zelda3-wrapped
  ];

  hjem.users.${username}.xdg.data.files."zelda3/zelda3.ini".source = ./zelda3.ini;

  # zelda3.ini is hjem-owned and re-laid each boot, so it stays out of the persist list to dodge the hjem/preservation path fight
  preservation.preserveAt."/persist".users.${username} = {
    directories = [
      "${dataDir}/msu"
      "${dataDir}/saves"
    ];
    files = [
      "${dataDir}/zelda3_assets.dat"
      "${dataDir}/minishcaplink.3.zspr"
    ];
  };
}
