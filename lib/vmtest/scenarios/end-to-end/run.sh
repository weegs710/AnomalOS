#!/usr/bin/env bash
# Installs a host for real and leaves the disks bootable, so a second boot can prove the system comes up.
set -o nounset
set -o pipefail
fail=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  OK   $1"; else echo "  FAIL $1"; fail=1; fi; }
finish() { echo; echo "== end-to-end install $( [ $fail -eq 0 ] && echo PASSED || echo FAILED ) =="
  echo "HARNESS: EXIT $fail"; echo "HARNESS: DONE"; sync; sleep 2; poweroff -f; }

echo "== end-to-end install =="

mkdir -p /mnt/repo /nixcache
mount -t 9p -o trans=virtio,version=9p2000.L,ro,msize=262144 repo /mnt/repo || { echo "no repo share"; fail=1; finish; }
mount -t 9p -o trans=virtio,version=9p2000.L,ro,msize=262144 nixcache /nixcache || echo "  (no cache share; will fetch from the internet)"

# point the daemon at the host's prebuilt closure so the install is a copy rather than a rebuild
if mountpoint -q /nixcache; then
  echo "substituters = file:///nixcache https://cache.nixos.org" >> /etc/nix/nix.conf
  echo "require-sigs = false" >> /etc/nix/nix.conf
  systemctl restart nix-daemon 2>/dev/null; sleep 3
  echo "  cache entries: $(ls /nixcache/*.narinfo 2>/dev/null | wc -l)"
fi

mkdir -p /root/anomalos && cp -a /mnt/repo/. /root/anomalos/ 2>/dev/null
rm -rf /root/anomalos/.git /root/anomalos/.jj /root/anomalos/.direnv
cd /root/anomalos || exit 1

# VMTEST mirrors HX99G so its closure matches what the cache already holds; virtio is added because the VM has no nvme
NEW=modules/hosts/VMTEST
mkdir -p $NEW
sed 's/fff29759/00c0ffee/' modules/hosts/HX99G/metadata.nix > $NEW/metadata.nix
cp modules/hosts/HX99G/zfs.nix $NEW/zfs.nix
sed 's/"nvme"/"nvme" "virtio_blk" "virtio_pci" "virtio_scsi"/' modules/hosts/HX99G/hardware.nix > $NEW/hardware.nix
cat > $NEW/host.nix <<'NIX'
{ ... }:
{
  mySystem.user = {
    name = "weegs";
    description = "weegs";
    extraGroups = [ "networkmanager" "wheel" ];
  };
  boot.kernelParams = [ "console=tty0" "console=ttyS0,115200n8" ];
  system.stateVersion = "24.11";
}
NIX

chk "VMTEST is discovered"  "nix eval --raw --file ./assemble.nix nixosConfigurations.VMTEST.config.networking.hostName --extra-experimental-features 'nix-command flakes' | grep -q VMTEST"

echo
echo "-- plan --"
printf 'VMTEST\n1\n2\ny\n2\nn\n' | ./install.sh --save-plan /root/plan.json
echo "  plan exit: $?"
chk "plan written" "test -s /root/plan.json"

echo
echo "-- install for real (this is the long part) --"
./install.sh --plan /root/plan.json --yes --keep-hardware 2>&1 | tee /root/install.out
inst=${PIPESTATUS[0]}
echo "  install exit: $inst"
chk "install.sh reported success" "test $inst -eq 0"

echo
echo "-- install.sh must release the disks itself, or the installed machine cannot import them --"
sync
chk "install.sh exported zroot"    "! zpool list zroot"
chk "install.sh unmounted /mnt"    "! mountpoint -q /mnt"
chk "said it released the disks"   "grep -q 'Releasing the disks' /root/install.out"

echo
echo "-- re-import the way the installed system will, then inspect --"
zpool import -N zroot 2>&1 | sed 's/^/     /'
imp=${PIPESTATUS[0]}
chk "a clean import works"         "test $imp -eq 0"
mount -t zfs zroot/root /mnt 2>/dev/null
mount --mkdir -t zfs zroot/nix /mnt/nix 2>/dev/null
mount --mkdir /dev/disk/by-label/NIXBOOT /mnt/boot 2>/dev/null

chk "bootloader installed"        "test -d /mnt/boot/EFI"
chk "systemd-boot entry present"  "ls /mnt/boot/loader/entries/*.conf"
chk "system profile link exists"  "test -L /mnt/nix/var/nix/profiles/system"
chk "profile closure is on /mnt"  "test -d /mnt\$(readlink -f /mnt/nix/var/nix/profiles/system)"
chk "hardware.nix was written"    "test -f $NEW/hardware.nix"
ls -la /mnt/boot/loader/entries/ 2>&1 | sed 's/^/     /' | head -6

echo
echo "-- release again so the reboot test gets a clean pool --"
umount -R /mnt 2>/dev/null
zpool export zroot 2>/dev/null
chk "released for the reboot"     "! zpool list zroot"

finish
