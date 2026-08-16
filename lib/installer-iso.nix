# `nix build -f lib/installer-iso.nix config.system.build.isoImage` -- the recovery and install image for the Ventoy drive.
let
  np = (import ../.tack).nixpkgs;
  lib = np.lib or (import "${np}/lib");

  root = ../.;
  rootStr = toString root;

  # history and the VM harness are dead weight on a recovery stick, and a stripped .git would only ever report phantom deletions
  source = builtins.path {
    name = "anomalos-source";
    path = root;
    filter =
      path: _type:
      let
        rel = lib.removePrefix "${rootStr}/" (toString path);
        drop = [
          ".git"
          ".jj"
          ".direnv"
          "lib/vmtest"
          "result"
        ];
      in
      !(builtins.any (d: rel == d || lib.hasPrefix "${d}/" rel) drop);
  };

  cfg = import "${np}/nixos/lib/eval-config.nix" {
    system = "x86_64-linux";
    modules = [
      "${np}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
      (
        { pkgs, ... }:
        let
          # install.sh writes hardware.nix and the plan back into the tree, and the copy on the image is read-only
          launcher = pkgs.writeShellScriptBin "anomalos-install" ''
            set -o errexit
            set -o nounset

            target="$HOME/anomalos"
            plan="$HOME/plan.json"

            if [ ! -d "$target" ]; then
              printf '%s\n' "Copying the configuration to $target."
              cp -r /iso/anomalos "$target"
              chmod -R u+w "$target"
            fi

            cd "$target"
            # partitioning needs root, and sudo is passwordless for wheel on the installation image
            case "''${1:-install}" in
              plan)      sudo ./install.sh --save-plan "$plan" ;;
              apply)     sudo ./install.sh --plan "$plan" ;;
              partition) sudo ./install.sh --no-install ;;
              *)         sudo ./install.sh ;;
            esac

            printf '\n%s\n' "Press enter to close this window."
            read -r _
          '';

          entry =
            { name, desc, args, icon }:
            pkgs.makeDesktopItem {
              inherit name;
              desktopName = desc;
              exec = "anomalos-install ${args}";
              inherit icon;
              terminal = true;
              categories = [ "System" ];
            };

          items = map entry [
            {
              name = "anomalos-plan";
              desc = "AnomalOS: Plan Only";
              args = "plan";
              icon = "edit-find-symbolic";
            }
            {
              name = "anomalos-apply-plan";
              desc = "AnomalOS: Apply Saved Plan";
              args = "apply";
              icon = "document-open-symbolic";
            }
            {
              name = "anomalos-install";
              desc = "AnomalOS: Install";
              args = "install";
              icon = "system-software-install-symbolic";
            }
            {
              name = "anomalos-partition";
              desc = "AnomalOS: Partition Only";
              args = "partition";
              icon = "drive-harddisk-symbolic";
            }
          ];
        in
        {
          isoImage.edition = lib.mkForce "anomalos";
          isoImage.contents = [
            {
              source = source;
              target = "/anomalos";
            }
          ];

          environment.systemPackages = [
            launcher
            pkgs.gnome-terminal
          ] ++ items;

          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];

          # graphical-gnome sets this without mkDefault, so extending the dash means restating its entries
          services.desktopManager.gnome.favoriteAppsOverride = lib.mkForce ''
            [org.gnome.shell]
            favorite-apps=[ 'anomalos-plan.desktop', 'anomalos-install.desktop', 'anomalos-apply-plan.desktop', 'anomalos-partition.desktop', 'org.gnome.Terminal.desktop', 'firefox.desktop', 'org.gnome.Nautilus.desktop', 'gparted.desktop', 'nixos-manual.desktop' ]
          '';
        }
      )
    ];
  };
in
cfg
