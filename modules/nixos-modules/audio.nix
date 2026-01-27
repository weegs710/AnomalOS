{...}: {
  flake.nixosModules.audio = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        security.rtkit.enable = true;

        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          wireplumber.enable = true;

          extraConfig.pipewire."91-audiophile" = {
            "context.properties" = {
              "default.clock.allowed-rates" = [44100 48000];
              "resample.quality" = 10;
            };
          };

          wireplumber.extraConfig."91-bluetooth-hq" = {
            "monitor.bluez.properties" = {
              "bluez5.enable-sbc-xq" = true;
              "bluez5.enable-msbc" = true;
              "bluez5.enable-hw-volume" = true;
              "bluez5.codecs" = ["ldac" "aac" "aptx_hd" "aptx" "sbc_xq" "sbc"];
            };
          };
        };

        users.users.${config.mySystem.user.name}.packages = with pkgs; [
          pamixer
          pavucontrol
          wireplumber
        ];
      };
    };
}
