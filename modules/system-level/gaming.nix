{
  config,
  pkgs,
  weegsware,
  only,
  ...
}:
let
  wrappedSteam = weegsware.steam;

  dmemcg-booster = pkgs.rustPlatform.buildRustPackage {
    pname = "dmemcg-booster";
    version = "0.1.2";
    src = pkgs.fetchFromGitLab {
      domain = "gitlab.steamos.cloud";
      owner = "holo";
      repo = "dmemcg-booster";
      rev = "79de901c077fedf2b3be53b460e4be8c16eaf020";
      hash = "sha256-qETBTccMJmB5IJPBK1sLTUdtpPfLFMKFwewLqpB/PgM=";
    };
    cargoLock.lockFile = ./dmemcg-booster-Cargo.lock;
    buildInputs = with pkgs; [
      dbus
      # runtime dep per upstream PKGBUILD, not linked by cargo
      libdrm
    ];
    nativeBuildInputs = [ pkgs.pkg-config ];
  };

  materialTheme = pkgs.fetchFromGitHub {
    owner = "kuska1";
    repo = "Material-Theme";
    rev = "32b6c127aab294c6f7c79ba7d3a12c717cc67227";
    hash = "sha256-3IQAZNsKXMpBu1ecMdJzoU1EvIW19fS1yOR2MbNUlZw=";
  };
in
only.gate { tags = [ "gaming" ]; }
{
  programs.nix-ld.enable = true;

  hardware.graphics.enable32Bit = true;
  hardware.steam-hardware.enable = true;

  programs = {
    gamescope.enable = true;
    gamemode.enable = true;
  };

  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    (openraPackages.engines.bleed.overrideAttrs (_old: {
      postPatch = "";
    }))
    protonup-qt
    protontricks
    wrappedSteam
  ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/millennium"
    ".config/openra"
    ".local/share/Steam"
    ".local/share/umu"
  ];

  # C copies only when the target is missing, so a theme already on disk is never overwritten
  systemd.user.tmpfiles.users.${config.mySystem.user.name}.rules = [
    "d %h/.local/share/Steam/millennium 0755 - - -"
    "d %h/.local/share/Steam/millennium/themes 0755 - - -"
    "C %h/.local/share/Steam/millennium/themes/Material-Theme - - - - ${materialTheme}"
  ];

  systemd.services.dmemcg-booster-system = {
    description = "dmemcg-booster system service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = "${dmemcg-booster}/bin/dmemcg-booster --use-system-bus";
  };

  hjem.users.${config.mySystem.user.name}.systemd.services.dmemcg-booster-user = {
    description = "dmemcg-booster user service";
    # umbriel does activate graphical-session-pre.target; default.target here predates the migration
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = "${dmemcg-booster}/bin/dmemcg-booster";
  };
}
