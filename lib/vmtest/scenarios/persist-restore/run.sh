#!/usr/bin/env bash
# /persist carries the SSH host key that agenix secrets are encrypted to, so restoring it is what keeps them working across a reinstall.
set -o nounset
set -o pipefail
fail=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  OK   $1"; else echo "  FAIL $1"; fail=1; fi; }
finish() { echo; echo "== persist-restore $( [ $fail -eq 0 ] && echo PASSED || echo FAILED ) =="
  echo "HARNESS: EXIT $fail"; echo "HARNESS: DONE"; sync; sleep 1; poweroff -f; }

mkdir -p /mnt/repo
mount -t 9p -o trans=virtio,version=9p2000.L,ro,msize=262144 repo /mnt/repo || { echo "no repo"; fail=1; finish; }
mkdir -p /root/anomalos && cp -a /mnt/repo/. /root/anomalos/ 2>/dev/null
rm -rf /root/anomalos/.git /root/anomalos/.jj /root/anomalos/.direnv
cd /root/anomalos || exit 1

NEW=modules/hosts/RESTORE
mkdir -p $NEW
sed 's/fff29759/0badf00d/' modules/hosts/HX99G/metadata.nix > $NEW/metadata.nix
cp modules/hosts/HX99G/zfs.nix $NEW/zfs.nix
sed 's/"nvme"/"nvme" "virtio_blk" "virtio_pci" "virtio_scsi"/' modules/hosts/HX99G/hardware.nix > $NEW/hardware.nix
printf '{ ... }:\n{\n  mySystem.user.name = "weegs";\n  system.stateVersion = "24.11";\n}\n' > $NEW/host.nix

echo "== persist restore =="
echo
echo "-- first install, to create a /persist worth keeping --"
printf 'RESTORE\n1\n2\ny\n2\nn\n' | ./install.sh --save-plan /root/plan.json > /root/plan.log 2>&1
echo "  plan exit: $?"
./install.sh --plan /root/plan.json --yes --no-install --keep-hardware > /root/first.log 2>&1
echo "  first run exit: $?"
chk "/mnt/persist is mounted" "mountpoint -q /mnt/persist"

mkdir -p /mnt/persist/etc/ssh
echo "PRETEND-HOST-KEY-abc123" > /mnt/persist/etc/ssh/ssh_host_ed25519_key
echo "canary" > /mnt/persist/CANARY
sync
chk "marker written" "test -f /mnt/persist/CANARY"

echo
echo "-- snapshot it and send it to a file --"
umount -R /mnt/boot 2>/dev/null
umount -R /mnt 2>/dev/null
zfs snapshot zroot/persist@backup
zfs send zroot/persist@backup > /root/persist.snap
echo "  snapshot size: $(du -h /root/persist.snap | cut -f1)"
chk "snapshot file exists" "test -s /root/persist.snap"

echo
echo "-- wipe everything --"
swapoff -a 2>/dev/null
zpool destroy zroot 2>/dev/null; zpool destroy zgames 2>/dev/null
chk "pools destroyed" "! zpool list zroot"

echo
echo "-- reinstall, answering yes to the restore prompt --"
printf 'y\ny\n/root/persist.snap\n' | ./install.sh --plan /root/plan.json --no-install --keep-hardware > /root/restore.log 2>&1
echo "  exit: $?"
chk "it offered the restore"        "grep -q 'holds everything this machine keeps' /root/restore.log"
chk "it explained the host key"     "grep -q 'SSH host key' /root/restore.log"
chk "it said it was restoring"      "grep -q 'Restoring zroot/persist' /root/restore.log"
chk "/mnt/persist mounted again"    "mountpoint -q /mnt/persist"
chk "CANARY survived the reinstall" "test -f /mnt/persist/CANARY"
chk "host key survived"             "grep -q PRETEND-HOST-KEY /mnt/persist/etc/ssh/ssh_host_ed25519_key"
chk "other datasets are fresh"      "test ! -f /mnt/nix/CANARY"
echo "  restored /persist contents:"; ls -a /mnt/persist 2>/dev/null | head -6 | sed 's/^/     /'

finish
