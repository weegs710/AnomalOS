{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;

  showTmpfs = pkgs.writeShellScriptBin "show-tmpfs" ''
    echo "=== tmpfs usage ==="
    df -h /
    echo ""
    echo "=== Largest files on tmpfs ==="
    find / -maxdepth 4 \
      ! -path "/nix" ! -path "/nix/*" \
      ! -path "/persist" ! -path "/persist/*" \
      ! -path "/cache" ! -path "/cache/*" \
      ! -path "/tmp" ! -path "/tmp/*" \
      ! -path "/boot" ! -path "/boot/*" \
      ! -path "/mnt" ! -path "/mnt/*" \
      ! -path "/run" ! -path "/run/*" \
      ! -path "/sys" ! -path "/sys/*" \
      ! -path "/proc" ! -path "/proc/*" \
      ! -path "/dev" ! -path "/dev/*" \
      -type f -printf '%s %p\n' 2>/dev/null \
      | sort -rn | head -40 \
      | awk '{
          size = $1;
          if (size >= 1048576) printf "%7.1fM  %s\n", size/1048576, $2;
          else if (size >= 1024) printf "%7.1fK  %s\n", size/1024, $2;
          else printf "%8dB  %s\n", size, $2;
        }'
  '';
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  fileSystems."/" = lib.mkForce {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=256M"
      "mode=755"
    ];
  };

  environment.persistence = {
    "/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/db/sudo"
        "/var/lib/tailscale"
        "/etc/NetworkManager/system-connections"
        "/var/lib/bluetooth"
      ];
      files = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ly/save.txt"
      ];
      users.${username} = {
        directories = [
          ".ssh"
          ".config"
          ".local"
          ".concord"
          ".crawl"
          ".var"
          ".claude"
          "cloud"
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Videos"
          "Desktop"
          "dotfiles"
          "homebrew"
          "claude-projects"
          "weegs.dev"
          "ossu"
        ];
        files = [
          ".claude.json"
          ".steam/registry.vdf"
          ".steam/exportedsettings.json"
        ];
      };
    };

    "/cache" = {
      hideMounts = true;
      directories = [
        "/var/lib/private/dnscrypt-proxy"
        "/var/lib/suricata"
        "/var/lib/libvirt"
      ];
      users.${username} = {
        directories = [
          ".cache"
          ".cargo"
        ];
      };
    };
  };

  users.users.${username}.packages = [ showTmpfs ];

  # Create persistent installation date marker if it doesn't exist
  system.activationScripts.persistInstallDate = lib.stringAfter [ "var" ] ''
    if [ ! -f /persist/.system-install-date ]; then
      if [ -e /nix/var/nix/profiles/system-1-link ]; then
        install_date=$(stat -c '%Y' /nix/var/nix/profiles/system-1-link)
      else
        install_date=$(date +%s)
      fi
      echo "$install_date" > /persist/.system-install-date
      chmod 644 /persist/.system-install-date
    fi
  '';

  # Steam symlinks must exist before Decky Loader starts, otherwise Decky creates .steam/steam as a directory which ln can't replace.
  systemd.user.tmpfiles.rules = [
    "d %h/.steam 0755 - - -"
    "L %h/.steam/steam - - - - %h/.local/share/Steam"
    "L %h/.steam/root - - - - %h/.local/share/Steam"
  ];
}
