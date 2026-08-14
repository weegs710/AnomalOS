{ only, ... }:
# k8s.nix declares mySystem.k8sLab, so disabling it while this file is live breaks eval
only.gate { tags = [ "lab" ]; }
{
  mySystem.k8sLab.nodes = {
    cp2 = {
      role = "control-plane";
      vcpu = 3;
      memoryMiB = 8192;
      ip = "192.168.126.11";
      mac = "52:54:00:1a:35:11";
    };
    cp3 = {
      role = "control-plane";
      vcpu = 3;
      memoryMiB = 8192;
      ip = "192.168.126.12";
      mac = "52:54:00:1a:35:12";
    };
    lb = {
      role = "lb";
      vcpu = 1;
      memoryMiB = 1024;
      ip = "192.168.126.30";
      mac = "52:54:00:1a:35:30";
    };
  };
}
