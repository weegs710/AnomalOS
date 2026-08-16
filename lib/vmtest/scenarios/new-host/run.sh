#!/usr/bin/env bash
# A machine the repository has never seen: install.sh writes its host directory, then plans and partitions for it.
set -o nounset
set -o pipefail
fail=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  OK   $1"; else echo "  FAIL $1"; fail=1; fi; }
finish() { echo; echo "== new-host $( [ $fail -eq 0 ] && echo PASSED || echo FAILED ) =="
  echo "HARNESS: EXIT $fail"; echo "HARNESS: DONE"; sync; sleep 1; poweroff -f; }

mkdir -p /mnt/repo
mount -t 9p -o trans=virtio,version=9p2000.L,ro,msize=262144 repo /mnt/repo || { echo "no repo"; fail=1; finish; }
mkdir -p /root/anomalos && cp -a /mnt/repo/. /root/anomalos/ 2>/dev/null
rm -rf /root/anomalos/.git /root/anomalos/.jj /root/anomalos/.direnv
cd /root/anomalos || { fail=1; finish; }

H=/root/anomalos/modules/hosts
echo "== STEP 0: only HX99G exists to begin with =="
ls -1 "$H" | sed 's/^/     /'
chk "HX99G is the only host"            "test \"\$(ls -1 $H | wc -l)\" -eq 1"
chk "TESTBOX does not exist yet"        "! test -d $H/TESTBOX"
echo

echo "== STEP 1: create the host and plan, no disk writes =="
# 2 = the not-listed option, then name, no tags, default system, user, disk, swap, no encryption
printf '2\nTESTBOX\n\n\nweegs\n1\n2\nn\n' | ./install.sh --save-plan /root/plan.json
echo "  step 1 exit: $?"
echo

chk "TESTBOX directory created"         "test -d $H/TESTBOX"
chk "metadata.nix written"              "test -s $H/TESTBOX/metadata.nix"
chk "host.nix written"                  "test -s $H/TESTBOX/host.nix"
chk "hardware.nix stub written"         "test -s $H/TESTBOX/hardware.nix"
chk "hostId is 8 lowercase hex"         "grep -Eq 'hostId = \"[0-9a-f]{8}\";' $H/TESTBOX/metadata.nix"
chk "hostId differs from HX99G"         "! grep -q fff29759 $H/TESTBOX/metadata.nix"
chk "system recorded"                   "grep -q 'x86_64-linux' $H/TESTBOX/metadata.nix"
chk "empty tag list accepted"           "grep -q 'tags = \[' $H/TESTBOX/metadata.nix"
chk "username landed in host.nix"       "grep -q 'name = \"weegs\";' $H/TESTBOX/host.nix"
chk "stub declares a root filesystem"   "grep -q 'zroot/root' $H/TESTBOX/hardware.nix"
chk "stub declares NIXBOOT"             "grep -q NIXBOOT $H/TESTBOX/hardware.nix"
chk "HX99G left alone"                  "! test -f $H/HX99G/hardware.nix.replaced"
chk "plan file was written"             "test -s /root/plan.json"
chk "plan names TESTBOX"                "jq -e '.host == \"TESTBOX\"' /root/plan.json"
chk "plan has exactly one pool"         "test \"\$(jq '.pools | length' /root/plan.json)\" -eq 1"
chk "plan pool is zroot"                "jq -e '.pools[0].name == \"zroot\"' /root/plan.json"
chk "plan installRoot is zroot/root"    "jq -e '.installRoot == \"zroot/root\"' /root/plan.json"
chk "plan boot label is NIXBOOT"        "jq -e '.bootLabel == \"NIXBOOT\"' /root/plan.json"
chk "plan boot partition is 1GiB"       "jq -e '.bootMiB == 1024' /root/plan.json"
chk "plan marks the host as new"        "jq -e '.newHost == true' /root/plan.json"
chk "nothing written to disk yet"       "! zpool list zroot"
echo

echo "== STEP 2: carry out the plan, stop before installing =="
./install.sh --plan /root/plan.json --yes --no-install </dev/null 2>&1 | tee /root/step2.out
echo "  step 2 exit: $?"
echo

echo "-- partitions --"; lsblk -no NAME,SIZE,FSTYPE,LABEL | sed 's/^/     /'
echo "-- datasets --";  zfs list -o name,mountpoint 2>&1 | sed 's/^/     /'
echo "-- mounts --";    findmnt -R /mnt -o TARGET,SOURCE,FSTYPE 2>&1 | sed 's/^/     /'
echo

chk "zroot pool exists"                 "zpool list zroot"
chk "no second pool was invented"       "test \"\$(zpool list -Ho name | wc -l)\" -eq 1"
chk "zroot/root created"                "zfs list zroot/root"
chk "zroot/root@blank snapshot"         "zfs list -t snapshot zroot/root@blank"
chk "zroot/nix created"                 "zfs list zroot/nix"
chk "zroot/persist created"             "zfs list zroot/persist"
chk "zroot/cache created"               "zfs list zroot/cache"
chk "no game datasets on a new host"    "! zfs list zgames"
chk "/mnt is the install root"          "mountpoint -q /mnt"
chk "/mnt/nix mounted"                  "mountpoint -q /mnt/nix"
chk "/mnt/persist mounted"              "mountpoint -q /mnt/persist"
chk "/mnt/cache mounted"                "mountpoint -q /mnt/cache"
chk "/mnt/boot mounted"                 "mountpoint -q /mnt/boot"
chk "/mnt/boot is vfat"                 "findmnt -no FSTYPE /mnt/boot | grep -q vfat"
chk "boot partition labelled NIXBOOT"   "blkid -L NIXBOOT"
chk "swap is active"                    "swapon --show=NAME --noheadings | grep -q ."
chk "stub replaced by real hardware"    "grep -q virtio $H/TESTBOX/hardware.nix"
chk "stub kept as .replaced"            "test -f $H/TESTBOX/hardware.nix.replaced"
echo "  ---- generated hardware.nix, device lines ----"
grep -nE 'fileSystems|device =|swapDevices|by-uuid|by-label' $H/TESTBOX/hardware.nix | sed 's/^/    /'
chk "/boot kept its NIXBOOT label"      "grep -q 'by-label/NIXBOOT' $H/TESTBOX/hardware.nix"
chk "/boot is not a raw uuid"           "! grep -q 'by-uuid' $H/TESTBOX/hardware.nix"
chk "said it kept the label"            "grep -q 'rather than the generated device identifier' /root/step2.out"
chk "swap left out of hardware.nix"     "grep -q 'swapDevices = \[ \];' $H/TESTBOX/hardware.nix"
chk "said it left swap out"             "grep -q 'installer.s swap partition is temporary' /root/step2.out"
chk "no prompt loop on closed stdin"    "! grep -q 'Please answer y or n' /root/step2.out"
chk "real repo untouched (read-only)"   "! touch /mnt/repo/CANARY"

finish
