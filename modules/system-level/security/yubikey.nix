{
  pkgs,
  ...
}:
{
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      cue = true;
    };
  };

  services = {
    udev = {
      packages = [
        pkgs.yubikey-personalization
        pkgs.libu2f-host
        pkgs.yubikey-manager
      ];
      # uaccess grants the seat user a device ACL, so no group membership is involved
      extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", TAG+="uaccess"
      '';
    };
    pcscd.enable = true;
  };

  environment.systemPackages = with pkgs; [
    yubikey-manager
    pam_u2f
  ];

}
