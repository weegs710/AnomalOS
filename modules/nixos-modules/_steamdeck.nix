{inputs, ...}: {
  flake.nixosModules.steamdeck = {
    config,
    lib,
    pkgs,
    ...
  }: let
    jupiterFanControl = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.jupiter-fan-control;
    steamdeckDsp = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.steamdeck-dsp;

    kernelPkgs = import inputs.nixpkgs-kernel {
      system = pkgs.stdenv.hostPlatform.system;
      overlays = [inputs.nix-cachyos-kernel.overlays.pinned];
    };

    deckKernel = kernelPkgs.cachyosKernels.linux-cachyos-latest-x86_64-v3.override {
      handheld = true;
      bbr3 = true;
      argsOverride = {
        extraMakeFlags = ["KCFLAGS=-march=x86-64-v3 -O2"];
      };
      structuredExtraConfig = with kernelPkgs.lib.kernel; {
        MODULE_COMPRESS_ZSTD = yes;

        # handheld patch adds these as new Kconfig symbols; explicit enable required
        MFD_STEAMDECK = module;
        EXTCON_STEAMDECK = module;
        LEDS_STEAMDECK = module;
        SENSORS_STEAMDECK = module;

        # CachyOS equiv of Jovian's DRM_AMD_COLOR_STEAMDECK (that symbol is Jovian-fork-only)
        AMD_PRIVATE_COLOR = yes;
        # amdgpu needs sole ownership of the display — simple fb must yield
        SYSFB_SIMPLEFB = lib.mkForce no;

        PINCTRL_AMD = yes;
        SPI_AMD = module;

        HID_STEAM = module;
        STEAM_FF = yes;

        SND_SOC_AMD_ACP5x = module;
        SND_SOC_AMD_VANGOGH_MACH = module;
        SND_SOC_WM_ADSP = module;
        SND_SOC_CS35L41 = module;
        SND_SOC_CS35L41_SPI = module;
        SND_SOC_NAU8821 = module;
        SND_SOC_MAX98388 = module;
        SND_AMD_ACP_CONFIG = module;
        SND_SOC_AMD_ACP_COMMON = module;
        SND_SOC_AMD_MACH_COMMON = module;
        SND_SOC_AMD_SOF_MACH = module;
        SND_SOC_SOF = module;
        SND_SOC_SOF_PROBE_WORK_QUEUE = yes;
        SND_SOC_SOF_IPC3 = yes;
        SND_SOC_SOF_IPC4 = yes;
        SND_SOC_SOF_AMD_TOPLEVEL = module;
        SND_SOC_SOF_AMD_COMMON = module;
        SND_SOC_SOF_AMD_VANGOGH = module;
        SND_SOC_CS35L36 = no;
        SND_SOC_AMD_ACP3x = no;
        SND_SOC_AMD_RENOIR = no;
        SND_SOC_AMD_ACP_PCI = no;
        SND_AMD_ASOC_RENOIR = no;
        SND_AMD_ASOC_REMBRANDT = no;
        SND_SOC_AMD_LEGACY_MACH = no;
        SND_SOC_AMD_RPL_ACP6x = no;
        SND_SOC_SOF_AMD_RENOIR = no;
        SND_SOC_SOF_AMD_REMBRANDT = no;

        ATH11K_TRACING = yes;
        CFG80211_CERTIFICATION_ONUS = yes;
        ATH_REG_DYNAMIC_USER_REG_HINTS = yes;

        HYPERVISOR_GUEST = lib.mkForce no;
        ZSWAP_DEFAULT_ON = yes;
      };
    };
  in {
    config = lib.mkIf config.mySystem.features.steamdeck {
      boot.kernelPackages = lib.mkForce (
        (kernelPkgs.linuxKernel.packagesFor deckKernel).extend (self: super: {
          zfs_cachyos = kernelPkgs.cachyosKernels.zfs-cachyos.override {
            kernel = deckKernel;
          };
        })
      );

      # panel is physically rotated in the chassis
      boot.kernelParams = lib.mkForce [
        "fbcon=rotate:1"
        "quiet"
        "amd_pstate=active"
      ];

      boot.plymouth.enable = lib.mkForce false;
      boot.kernelModules = ["hid_nintendo" "hid_playstation"];

      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", TAG+="uaccess"
        KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess"
      '';

      users.users.${config.mySystem.user.name}.extraGroups = ["input" "video"];

      hardware.enableRedistributableFirmware = true;

      environment.systemPackages = [
        jupiterFanControl
        pkgs.inputplumber
      ];

      systemd.services.jupiter-fan-control = {
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = "${pkgs.python3.withPackages (py: [py.pyyaml])}/bin/python3 ${jupiterFanControl}/share/jupiter-fan-control/fancontrol.py";
          Restart = "on-failure";
        };
      };

      systemd.services.inputplumber = {
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = "${pkgs.inputplumber}/bin/inputplumber";
          Restart = "on-failure";
        };
      };

      # steamdeck-dsp UCM2 configs for ALSA to route to the cs35l41 amps and NAU8821 codec
      environment.etc."alsa/ucm2" = {
        source = "${steamdeckDsp}/share/alsa/ucm2";
      };

      # pipewire and wireplumber hardware profile dispatch
      services.pipewire.extraConfig.pipewire."90-steamdeck-hw" = {
        "context.exec" = [
          {
            path = "${steamdeckDsp}/share/pipewire/hardware-profiles/pipewire-hwconfig";
            args = "";
          }
        ];
      };
    };
  };
}
