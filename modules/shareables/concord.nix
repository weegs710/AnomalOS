{ inputs, ... }: {
  perSystem = { pkgs, lib, ... }: let
    upstream = inputs.concord.packages.${pkgs.stdenv.hostPlatform.system}.default;

    patched = upstream.overrideAttrs (old: {
      patches = (old.patches or []) ++ [ ./patches/concord-clipboard-image ];
    });

    concordWrapped = pkgs.symlinkJoin {
      name = "concord";
      paths = [ patched ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/concord \
          --prefix PATH : ${lib.makeBinPath [ pkgs.wl-clipboard ]}
      '';
      meta = patched.meta // { mainProgram = "concord"; };
    };
  in {
    packages.concord = concordWrapped;
  };
}
