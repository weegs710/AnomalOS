#!/usr/bin/env bash
# Proves the harness itself works before install.sh is asked to trust it.
set -o nounset
set -o pipefail
fail=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  OK   $1"; else echo "  FAIL $1"; fail=1; fi; }

echo "== harness smoke test =="

echo "-- repo share --"
mkdir -p /harness/../repo 2>/dev/null || true
mkdir -p /mnt/repo
mount -t 9p -o trans=virtio,version=9p2000.L,ro,msize=262144 repo /mnt/repo
chk "repo mounted"              "mountpoint -q /mnt/repo"
chk "assemble.nix readable"     "test -r /mnt/repo/assemble.nix"
chk "install.sh present"        "test -r /mnt/repo/install.sh"
chk "host dir discovered"       "test -d /mnt/repo/modules/hosts/HX99G"
chk "repo is read-only"         "! touch /mnt/repo/CANARY 2>/dev/null"

echo "-- disks --"
lsblk -no NAME,SIZE,TYPE | sed 's/^/     /'
chk "two virtio disks present"  "test \$(lsblk -dno NAME,TYPE | grep -c disk) -ge 2"

echo "-- tools install.sh needs --"
for t in sgdisk zpool zfs mkfs.fat mkswap blkdiscard jq lsblk nixos-install nix-build; do
  chk "$t" "command -v $t"
done

echo "-- can nix evaluate the config from the share? --"
if out=$(nix eval --raw --file /mnt/repo/assemble.nix \
      nixosConfigurations.HX99G.config.networking.hostName \
      --extra-experimental-features "nix-command flakes" 2>&1); then
  echo "  OK   nix eval -> $out"
else
  echo "  FAIL nix eval"
  echo "$out" | tail -5 | sed 's/^/       /'
  fail=1
fi

echo
echo "== smoke test $( [ $fail -eq 0 ] && echo PASSED || echo FAILED ) =="
# printed here because poweroff can outrun the service's own completion message
echo "HARNESS: EXIT $fail"
echo "HARNESS: DONE"
sync
sleep 1
poweroff -f
