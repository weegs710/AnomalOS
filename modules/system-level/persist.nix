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
        # uid/gid maps must exist before initrd activation creates users, or ids get reallocated alphabetically
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
        "/var/db/sudo"
      ];
      files = [
        # symlink + "uninitialized" seed bypasses O_NOFOLLOW failure introduced in systemd v258
        # See: https://github.com/nix-community/preservation/issues/22
        {
          file = "/etc/machine-id";
          how = "symlink";
          inInitrd = true;
        }
      ];
      users.${username} = {
        directories = [
          # top-level home dirs
          ".ssh"
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
          ".config/glib-2.0"
          ".config/Electron"
          ".config/environment.d"
          ".config/systemd"
          ".config/QtProject"
          ".config/age"
          # .local/share -- general (no specific module)
          ".local/share/applications"
          ".local/share/desktop-directories"
          ".local/share/icons"
          ".local/share/mime"
          ".local/share/pki"
          ".local/share/vulkan"
          ".local/share/systemd"
          ".local/share/nix"
          ".local/share/Trash"
          ".local/share/Larian Studios"
          ".local/share/Paradox Interactive"
          # .local/state -- general
          ".local/state/nix"
          ".local/state/Larian Studios"
        ];
      };
    };

    "/cache" = {
      commonMountOptions = [ "x-gvfs-hide" ];
      users.${username}.directories = [ ".cache" ];
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
}
