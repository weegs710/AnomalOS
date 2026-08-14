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
    ".config/openra"
    ".local/share/Steam"
    ".local/share/umu"
  ];

  systemd.services.dmemcg-booster-system = {
    description = "dmemcg-booster system service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = "${dmemcg-booster}/bin/dmemcg-booster --use-system-bus";
  };

  systemd.user.services.dmemcg-booster-user = {
    description = "dmemcg-booster user service";
    # graphical-session-pre.target not activated by Hyprland
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = "${dmemcg-booster}/bin/dmemcg-booster";
  };
}
