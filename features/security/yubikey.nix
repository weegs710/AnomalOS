{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  username = config.mySystem.user.name;
  u2fKeys = "/home/${username}/.config/Yubico/u2f_keys";
in {
  config = mkIf config.mySystem.features.yubikey {
    security.pam.u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        interactive = true;
        authFile = u2fKeys;
      };
    };

    security.pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
      ly.u2fAuth = true;
      polkit-1.u2fAuth = true;
    };

    services = {
      udev = {
        packages = [
          pkgs.yubikey-personalization
          pkgs.libu2f-host
          pkgs.yubikey-manager
        ];
        extraRules = ''
          KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", TAG+="uaccess", MODE="0664", GROUP="plugdev"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0664"
        '';
      };
      pcscd.enable = true;
    };

    environment.systemPackages = with pkgs; [
      yubikey-manager
      pam_u2f
    ];

    users.users.${username}.extraGroups = ["plugdev"];
  };
}
