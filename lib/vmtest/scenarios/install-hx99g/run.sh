#!/usr/bin/env bash
# Exercises the destructive half of install.sh against throwaway virtio disks.
set -o nounset
set -o pipefail
fail=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  OK   $1"; else echo "  FAIL $1"; fail=1; fi; }

echo "== install.sh destructive test =="
echo

mkdir -p /mnt/repo
mount -t 9p -o trans=virtio,version=9p2000.L,ro,msize=262144 repo /mnt/repo || { echo "cannot mount repo"; poweroff -f; }

# a writable copy so the run can rewrite hardware.nix without touching the real repository
mkdir -p /root/anomalos
cp -a /mnt/repo/. /root/anomalos/ 2>/dev/null
rm -rf /root/anomalos/.git /root/anomalos/.jj /root/anomalos/.direnv
cd /root/anomalos || exit 1

echo "-- disks the VM presents --"
lsblk -dno NAME,SIZE,TYPE | sed 's/^/     /'
echo

echo "== STEP 1: interactive plan, no disk writes =="
printf 'HX99G\n1\n2\ny\n2\nn\n' | ./install.sh --save-plan /root/plan.json
echo "  step 1 exit: $?"
chk "plan file was written" "test -s /root/plan.json"
if [ -s /root/plan.json ]; then
  echo "  plan pools:"; jq -r '.pools[] | "     \(.name) -> \(.disk)"' /root/plan.json
fi
echo

echo "== STEP 2: carry out the plan, stop before installing =="
./install.sh --plan /root/plan.json --yes --no-install --regenerate
step2=$?
echo "  step 2 exit: $step2"
echo

echo "== STEP 3: verify what actually landed on the disks =="
echo "-- partitions --"
lsblk -no NAME,SIZE,FSTYPE,LABEL | sed 's/^/     /'
echo "-- pools --"
zpool list -o name,size,health 2>&1 | sed 's/^/     /'
echo "-- datasets --"
zfs list -o name,mountpoint 2>&1 | sed 's/^/     /'
echo "-- mounts under /mnt --"
findmnt -R /mnt -o TARGET,SOURCE,FSTYPE 2>&1 | sed 's/^/     /'
echo

chk "zroot pool exists"                 "zpool list zroot"
chk "zgames pool exists"                "zpool list zgames"
chk "zroot/root created"                "zfs list zroot/root"
chk "zroot/root@blank snapshot"         "zfs list -t snapshot zroot/root@blank"
chk "zroot/nix created"                 "zfs list zroot/nix"
chk "zroot/persist created"             "zfs list zroot/persist"
chk "zroot/cache created"               "zfs list zroot/cache"
chk "zgames/games/roms created"         "zfs list zgames/games/roms"
chk "zgames/games/steam created"        "zfs list zgames/games/steam"
chk "zgames/games/heroic created"       "zfs list zgames/games/heroic"
chk "zgames/media created"              "zfs list zgames/media"
chk "zroot/tmp NOT created"             "! zfs list zroot/tmp"
chk "/mnt is the install root"          "mountpoint -q /mnt"
chk "/mnt/nix mounted"                  "mountpoint -q /mnt/nix"
chk "/mnt/persist mounted"              "mountpoint -q /mnt/persist"
chk "/mnt/cache mounted"                "mountpoint -q /mnt/cache"
chk "/mnt/mnt/games/1g1r mounted"       "mountpoint -q /mnt/mnt/games/1g1r"
chk "/mnt/boot mounted"                 "mountpoint -q /mnt/boot"
chk "/mnt/boot is vfat"                 "findmnt -no FSTYPE /mnt/boot | grep -q vfat"
chk "boot partition labelled NIXBOOT"   "blkid -L NIXBOOT"
chk "swap is active"                    "swapon --show=NAME --noheadings | grep -q ."
chk "hardware.nix was regenerated"      "grep -q virtio /root/anomalos/modules/hosts/HX99G/hardware.nix"
chk "previous hardware.nix backed up"   "test -f /root/anomalos/modules/hosts/HX99G/hardware.nix.replaced"
chk "real repo untouched (read-only)"   "! touch /mnt/repo/CANARY"

echo
echo "== destructive test $( [ $fail -eq 0 ] && echo PASSED || echo FAILED ) =="
# printed here because poweroff can outrun the service's own completion message
echo "HARNESS: EXIT $fail"
echo "HARNESS: DONE"
sync
sleep 1
poweroff -f
