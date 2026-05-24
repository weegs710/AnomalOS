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
  imports = [ inputs.preservation.nixosModules.default ];

  fileSystems."/" = lib.mkForce {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=256M"
      "mode=755"
    ];
  };

  preservation.enable = true;

  preservation.preserveAt = {
    "/persist" = {
      commonMountOptions = [ "x-gvfs-hide" ];
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/db/sudo"
        "/var/lib/tailscale"
        "/etc/NetworkManager/system-connections"
        "/var/lib/bluetooth"
      ];
      files = [
        # symlink + "uninitialized" seed bypasses O_NOFOLLOW failure introduced in systemd v258
        # See: https://github.com/nix-community/preservation/issues/22
        {
          file = "/etc/machine-id";
          how = "symlink";
          inInitrd = true;
        }
        # ssh-keygen does not use O_NOFOLLOW so symlinks are safe for host keys
        { file = "/etc/ssh/ssh_host_ed25519_key"; how = "symlink"; }
        { file = "/etc/ssh/ssh_host_ed25519_key.pub"; how = "symlink"; }
        { file = "/etc/ly/save.txt"; how = "symlink"; }
      ];
      users.${username} = {
        directories = [
          # top-level home dirs
          ".ssh"
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
          "repo"
          "homebrew"
          "claude-projects"
          # XDG / desktop cross-cutting (no single owning module)
          ".config/dconf"
          ".config/gtk-3.0"
          ".config/gtk-4.0"
          ".config/glib-2.0"
          ".config/Electron"
          ".config/environment.d"
          ".config/systemd"
          ".config/pulse"
          ".config/qt5ct"
          ".config/qt6ct"
          ".config/QtProject"
          ".config/age"
          ".config/gh"
          ".config/jj"
          # apps with no dedicated module yet
          ".config/yazi"
          # emulators (saves preserved, no dedicated module)
          ".config/Ryujinx"
          ".config/ppsspp"
          ".config/desmume"
          # actively used, no dedicated module
          ".config/Cryptomator"
          # .local/share -- general (no specific module)
          ".local/share/applications"
          ".local/share/desktop-directories"
          ".local/share/icons"
          ".local/share/mime"
          ".local/share/wallpapers"
          ".local/share/cursor-sources"
          ".local/share/pki"
          ".local/share/vulkan"
          ".local/share/sddm"
          ".local/share/systemd"
          ".local/share/nix"
          ".local/share/Trash"
          ".local/share/hyprland"
          ".local/share/direnv"
          ".local/share/Cryptomator"
          ".local/share/Larian Studios"
          ".local/share/Paradox Interactive"
          ".local/share/severed-chains"
          ".local/share/gorguru"
          # .local/state -- general
          ".local/state/nix"
          ".local/state/nix-output-monitor"
          ".local/state/comma"
          ".local/state/Larian Studios"
        ];
        files = [
          ".claude.json"
          ".steam/registry.vdf"
          ".steam/exportedsettings.json"
        ];
      };
    };

    "/cache" = {
      commonMountOptions = [ "x-gvfs-hide" ];
      directories = [
        "/var/lib/private/dnscrypt-proxy"
        "/var/lib/suricata"
        "/var/lib/libvirt"
      ];
      users.${username}.directories = [
        ".cache"
        ".cargo"
      ];
    };
  };

  # Seeds persistent machine-id as "uninitialized" so systemd takes the rewrite path on firstboot
  # See: https://github.com/nix-community/preservation/issues/22
  boot.initrd.systemd.tmpfiles.settings."machine-id-init" = {
    "/sysroot/persist/etc/machine-id".f.argument = "uninitialized";
  };

  # Prevents machine-id-commit from replacing the preserved symlink with a plain file
  boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];
  systemd.services.systemd-machine-id-commit.unitConfig.ConditionFirstBoot = true;

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
