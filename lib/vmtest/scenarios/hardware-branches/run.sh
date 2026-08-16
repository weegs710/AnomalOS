#!/usr/bin/env bash
# Exercises every branch of handle_hardware_config, re-wiping the disks between cases.
set -o nounset
set -o pipefail
fail=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  OK   $1"; else echo "  FAIL $1"; fail=1; fi; }

mkdir -p /mnt/repo
mount -t 9p -o trans=virtio,version=9p2000.L,ro,msize=262144 repo /mnt/repo || { echo "no repo"; poweroff -f; }
mkdir -p /root/anomalos && cp -a /mnt/repo/. /root/anomalos/ 2>/dev/null
rm -rf /root/anomalos/.git /root/anomalos/.jj /root/anomalos/.direnv
cd /root/anomalos || exit 1
HW=/root/anomalos/modules/hosts/HX99G/hardware.nix
cp "$HW" /root/hardware.original

reset_disks() {
  umount -R /mnt/boot /mnt 2>/dev/null
  swapoff -a 2>/dev/null
  zpool destroy zroot 2>/dev/null; zpool destroy zgames 2>/dev/null
  cp /root/hardware.original "$HW"
  rm -f "$HW.replaced"
}

echo "== handle_hardware_config branch tests =="
echo
printf 'HX99G\n1\n2\ny\n2\nn\n' | ./install.sh --save-plan /root/plan.json >/dev/null 2>&1
chk "plan built" "test -s /root/plan.json"

echo
echo "--- case 1: --keep-hardware leaves it alone ---"
reset_disks
./install.sh --plan /root/plan.json --yes --no-install --keep-hardware > /root/c1.log 2>&1
echo "  exit: $?"
chk "hardware.nix unchanged"        "cmp -s /root/hardware.original $HW"
chk "no .replaced backup made"      "! test -e $HW.replaced"
chk "said it kept it"               "grep -q 'Keeping the existing hardware.nix' /root/c1.log"

echo
echo "--- case 2: interactive, answer n ---"
reset_disks
printf 'n\n' | ./install.sh --plan /root/plan.json --yes --no-install > /root/c2.log 2>&1
echo "  exit: $?"
chk "hardware.nix unchanged"        "cmp -s /root/hardware.original $HW"
chk "no .replaced backup made"      "! test -e $HW.replaced"
chk "it explained before deciding"  "grep -q 'already has a hardware.nix' /root/c2.log"

echo
echo "--- case 3: interactive, answer y ---"
reset_disks
printf 'y\n' | ./install.sh --plan /root/plan.json --yes --no-install > /root/c3.log 2>&1
echo "  exit: $?"
chk "hardware.nix was replaced"     "! cmp -s /root/hardware.original $HW"
chk "generated content has virtio"  "grep -q virtio $HW"
chk "backup exists"                 "test -f $HW.replaced"
chk "backup matches the original"   "cmp -s /root/hardware.original $HW.replaced"

echo
echo "--- case 4: fresh host with no hardware.nix at all ---"
reset_disks
NEW=/root/anomalos/modules/hosts/VMFRESH
mkdir -p $NEW
sed 's/fff29759/0000beef/' /root/anomalos/modules/hosts/HX99G/metadata.nix > $NEW/metadata.nix
cp /root/anomalos/modules/hosts/HX99G/host.nix $NEW/host.nix
cp /root/anomalos/modules/hosts/HX99G/zfs.nix $NEW/zfs.nix
cp /root/hardware.original $NEW/hardware.nix
chk "VMFRESH is discovered by assemble" "nix eval --raw --file ./assemble.nix nixosConfigurations.VMFRESH.config.networking.hostName --extra-experimental-features 'nix-command flakes' | grep -q VMFRESH"
rm -f $NEW/hardware.nix
printf 'VMFRESH\n1\n2\nn\n' | ./install.sh --save-plan /root/plan2.json > /root/c4a.log 2>&1
echo "  plan-for-fresh-host exit: $?"
./install.sh --plan /root/plan2.json --yes --no-install > /root/c4.log 2>&1
echo "  exit: $?"
echo "  ---- apply output ----"; sed 's/^/    /' /root/c4.log | tail -20
chk "hardware.nix was created"      "test -f $NEW/hardware.nix"
chk "it contains virtio"            "grep -q virtio $NEW/hardware.nix"
chk "no .replaced for a new host"   "! test -e $NEW/hardware.nix.replaced"
chk "told the user it wrote it"     "grep -q 'has no hardware.nix yet' /root/c4.log"

echo
echo "== hardware branch tests $( [ $fail -eq 0 ] && echo PASSED || echo FAILED ) =="
echo "HARNESS: EXIT $fail"
echo "HARNESS: DONE"
sync; sleep 1; poweroff -f
