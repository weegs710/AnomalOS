# Virtual Machine Support
#
# Note on virtiofsd:
#   When creating shared filesystems in virt-manager, add this to the
#   filesystem XML configuration:
#     <binary path="/run/current-system/sw/bin/virtiofsd"/>
#   Reference: https://discourse.nixos.org/t/virt-manager-cannot-find-virtiofsd/26752/2
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.vm {
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

    users.users.${config.mySystem.user.name}.extraGroups = ["libvirtd"];
  };
}
