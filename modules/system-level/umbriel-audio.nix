{ pkgs, ... }:
let
  producer = pkgs.writers.writePython3Bin "umbriel-audio-producer" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./umbriel-audio-producer.py);
in
{
  # Umbriel only draws the level it is sent, so this feeds it from the default sink's monitor.
  systemd.user.services.umbriel-audio-producer = {
    description = "Audio level feed for Umbriel effects";
    wantedBy = [ "umbriel-session.target" ];
    partOf = [ "umbriel-session.target" ];
    after = [
      "umbriel.service"
      "pipewire.service"
    ];
    path = [ pkgs.pipewire ];
    # umbriel publishes UMBRIEL_SOCKET to the session only after units like this one can start, so it is set here.
    environment.UMBRIEL_SOCKET = "%t/umbriel-wayland-0.sock";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${producer}/bin/umbriel-audio-producer --gain 6";
      Restart = "always";
      RestartSec = 2;
    };
  };
}
