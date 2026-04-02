# Wrapped superfile with config and tools
# Run with: nix run github:weegs710/AnomalOS#superfile
{
  perSystem = {pkgs, ...}: let
    # Pinned version
    superfilePkg = pkgs.superfile.overrideAttrs (old: {
      version = "1.5.0";
      src = pkgs.fetchFromGitHub {
        owner = "yorukot";
        repo = "superfile";
        rev = "v1.5.0";
        hash = "sha256-PEojifuiIjF3OUxDoMCyynOJUpFglTzh7lJUcq7g4e0=";
      };
      vendorHash = "sha256-5SSnrG3DvD1i7rNcpztHkUUap4Qp7MX04ofD7rA3xgM=";
      # write all panel-selected files to --chooser-file instead of only the triggered one
      patches = (old.patches or []) ++ [ ./superfile-chooser-multi ];
      doCheck = false;
    });

    extraTools = with pkgs; [exiftool glib zoxide ffmpeg poppler-utils];

    wrappedSuperfile = pkgs.symlinkJoin {
      name = "superfile-wrapped";
      paths = [superfilePkg];
      buildInputs = extraTools;
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/superfile \
          --prefix PATH : ${pkgs.lib.makeBinPath extraTools}
      '';
      meta.mainProgram = "superfile";
    };
  in {
    packages.superfile = wrappedSuperfile;
  };
}
