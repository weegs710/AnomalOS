{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation = {
    libvirtd.enable = true;

    vmVariant = {
      virtualisation = {
        memorySize = 1024 * 16;
        cores = 8;
      };
    };
  };

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    virtiofsd
  ];

  users.users.${config.mySystem.user.name}.extraGroups = [ "libvirtd" ];

  systemd.services."virt-secret-init-encryption" = {
    serviceConfig.ExecStart = lib.mkForce "${pkgs.bash}/bin/bash -c 'umask 0077 && dd if=/dev/random status=none bs=32 count=1 | systemd-creds encrypt --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key'";
  };
}
