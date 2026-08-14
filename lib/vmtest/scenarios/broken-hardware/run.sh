#!/usr/bin/env bash
# An existing hardware.nix with no /boot, kept rather than regenerated.
set -o nounset
set -o pipefail
fail=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  OK   $1"; else echo "  FAIL $1"; fail=1; fi; }
finish() { echo; echo "== broken-hardware $( [ $fail -eq 0 ] && echo PASSED || echo FAILED ) =="
  echo "HARNESS: EXIT $fail"; echo "HARNESS: DONE"; sync; sleep 1; poweroff -f; }

mkdir -p /mnt/repo
mount -t 9p -o trans=virtio,version=9p2000.L,ro,msize=262144 repo /mnt/repo || { echo "no repo"; fail=1; finish; }
mkdir -p /root/anomalos && cp -a /mnt/repo/. /root/anomalos/ 2>/dev/null
rm -rf /root/anomalos/.git /root/anomalos/.jj /root/anomalos/.direnv
cd /root/anomalos || exit 1

echo "== hardware.nix missing /boot, kept rather than regenerated =="

NEW=modules/hosts/NOBOOT
mkdir -p $NEW
sed 's/fff29759/0badcafe/' modules/hosts/HX99G/metadata.nix > $NEW/metadata.nix
cp modules/hosts/HX99G/zfs.nix $NEW/zfs.nix
printf '{ ... }:\n{\n  mySystem.user.name = "weegs";\n  system.stateVersion = "24.11";\n}\n' > $NEW/host.nix
# HX99G's hardware, minus /boot, plus the virtio modules a VM needs
sed 's/"nvme"/"nvme" "virtio_blk" "virtio_pci" "virtio_scsi"/' modules/hosts/HX99G/hardware.nix \
  | awk '/fileSystems\."\/boot"/{skip=4} skip>0{skip--; next} {print}' > $NEW/hardware.nix

chk "hardware.nix exists"        "test -f $NEW/hardware.nix"
chk "and it has no /boot"        "! grep -q 'fileSystems\..\"/boot\"' $NEW/hardware.nix"
echo "  mounts it declares:"
nix eval --json --file ./lib/requirements.nix --apply 'f: (f "NOBOOT").mountPoints' --extra-experimental-features 'nix-command flakes' 2>&1 | tail -1 | sed 's/^/     /'

echo
echo "-- plan --"
printf 'NOBOOT\n1\n2\ny\n2\nn\n' | ./install.sh --save-plan /root/plan.json > /root/plan.log 2>&1
echo "  plan exit: $?"
chk "plan was written" "test -s /root/plan.json"

echo
echo "-- carry it out with --keep-hardware: the recheck must refuse --"
./install.sh --plan /root/plan.json --yes --no-install --keep-hardware > /root/run.log 2>&1
rc=$?
echo "  exit: $rc"
chk "refused to proceed"            "test $rc -ne 0"
chk "named the missing /boot"       "grep -q 'no filesystem at /boot' /root/run.log"
chk "said nothing was installed"    "grep -q 'nothing has been installed' /root/run.log"
chk "disks WERE set up first"       "zpool list zroot"
chk "hardware.nix left untouched"   "! grep -q 'fileSystems\..\"/boot\"' $NEW/hardware.nix"
echo "  what it said:"
grep -aE 'Problem:|bootloader has nowhere|Found [0-9]+ problem' /root/run.log | sed 's/^/     /'

echo
echo "-- same disks, --regenerate: hardware.nix gets fixed, recheck passes --"
umount -R /mnt/boot /mnt 2>/dev/null; swapoff -a 2>/dev/null
zpool destroy zroot 2>/dev/null; zpool destroy zgames 2>/dev/null
./install.sh --plan /root/plan.json --yes --no-install --regenerate > /root/regen.log 2>&1
rc=$?
echo "  exit: $rc"
chk "proceeded"                     "test $rc -eq 0"
chk "hardware.nix now has /boot"    "grep -q '/boot' $NEW/hardware.nix"
chk "recheck reported bootable"     "grep -q 'describes a machine that can boot' /root/regen.log"
chk "old hardware.nix backed up"    "test -f $NEW/hardware.nix.replaced"

finish
