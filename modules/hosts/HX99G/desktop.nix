{
  config,
  lib,
  pkgs,
  ...
}:
let
  connectTylubio = pkgs.writeShellApplication {
    name = "connect-tylubio";
    # a unit's PATH is only coreutils, findutils, gnugrep, gnused and systemd, so the rest is pinned
    runtimeInputs = [
      config.hardware.bluetooth.package
      pkgs.ripgrep
    ];
    # the MAC is looked up by name so it stays out of the public repo
    text = ''
      for _ in $(seq 15); do
        mac=$(bluetoothctl devices | rg 'Tylubio ST200' | cut -d' ' -f2) || true
        if [ -n "$mac" ] && bluetoothctl info "$mac" | rg -q 'Connected: yes'; then
          exit 0
        fi
        if [ -n "$mac" ] && bluetoothctl connect "$mac"; then
          exit 0
        fi
        sleep 3
      done
      exit 1
    '';
  };
in
{
  # umbriel and noctalia both merge these over their shared config, so only this machine's monitors and devices live here
  hjem.users.${config.mySystem.user.name} = {
    xdg.config.files = {
      "umbriel/host.toml".source = ./umbriel-host.toml;
      "noctalia/host.toml".source = ./noctalia-host.toml;
    };

    # per-user unit: a global systemd.user.services also runs in the greeter's manager
    systemd.services.connect-tylubio = {
      description = "Reconnect the Tylubio ST200 headset at login";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe connectTylubio;
      };
    };
  };
}
