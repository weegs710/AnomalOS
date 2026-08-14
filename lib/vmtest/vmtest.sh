#!/usr/bin/env bash
# Boots a scenario in a throwaway VM so install.sh can be exercised against real disks without risking hardware.
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${REPO:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
WORK="${WORK:-$HOME/.cache/anomalos-vmtest}"
ISO="${ISO:-$WORK/iso/iso}"

# disk images must not land on tmpfs -- an install is far larger than RAM
OVMF_CODE=/run/libvirt/nix-ovmf/edk2-x86_64-code.fd
OVMF_VARS_SRC=/run/libvirt/nix-ovmf/edk2-i386-vars.fd

usage() {
	cat <<'EOF'
Usage: vmtest.sh <scenario-dir> [--timeout SECONDS] [--interactive]

The scenario directory must contain:
  disks       one "NAME SIZE" pair per line, e.g. "nvme0 40G"
  run.sh      executable; runs inside the VM as root, repo mounted at /harness/repo

Everything the VM prints goes to stdout. The run ends when the VM prints
HARNESS: DONE, or when the timeout expires.
EOF
}

[[ $# -ge 1 ]] || { usage; exit 2; }
SCENARIO="$(cd "$1" && pwd)"; shift
TIMEOUT=600
INTERACTIVE=0
REBOOT=0
CACHE=""
while [[ $# -gt 0 ]]; do
	case "$1" in
	--timeout) TIMEOUT="$2"; shift 2 ;;
	--interactive) INTERACTIVE=1; shift ;;
	--reboot) REBOOT=1; shift ;;
	--cache) CACHE="$2"; shift 2 ;;
	*) echo "unknown argument: $1" >&2; usage; exit 2 ;;
	esac
done

for f in disks run.sh; do
	[[ -e "$SCENARIO/$f" ]] || { echo "scenario is missing $f: $SCENARIO/$f" >&2; exit 2; }
done
[[ -x "$SCENARIO/run.sh" ]] || { echo "scenario run.sh is not executable: $SCENARIO/run.sh" >&2; exit 2; }

isofile="$(find "$ISO" -maxdepth 1 -name '*.iso' -print -quit 2>/dev/null || true)"
[[ -n "$isofile" ]] || { echo "no .iso found under $ISO -- build it first" >&2; exit 2; }

run="$WORK/$(basename "$SCENARIO")"
if [[ $REBOOT -eq 1 ]]; then
	[[ -d "$run" ]] || { echo "no previous run to reboot: $run" >&2; exit 2; }
else
	rm -rf "$run"; mkdir -p "$run/share"
	cp -r "$SCENARIO"/. "$run/share/"
fi

# fresh images each run, so a scenario cannot inherit the previous run's disk state
disk_args=()
i=0
while read -r name size; do
	[[ -n "${name:-}" && "${name:0:1}" != "#" ]] || continue
	img="$run/$name.qcow2"
	if [[ $REBOOT -eq 0 ]]; then
		qemu-img create -f qcow2 "$img" "$size" >/dev/null
	fi
	[[ -f "$img" ]] || { echo "missing disk image: $img" >&2; exit 2; }
	disk_args+=(-drive "file=$img,if=none,id=d$i,format=qcow2"
		-device "virtio-blk-pci,drive=d$i,serial=$name")
	i=$((i + 1))
done <"$SCENARIO/disks"
[[ $i -gt 0 ]] || { echo "scenario declares no disks" >&2; exit 2; }

if [[ $REBOOT -eq 0 ]]; then
	cp "$OVMF_VARS_SRC" "$run/OVMF_VARS.fd"
	chmod u+w "$run/OVMF_VARS.fd"
fi

boot_args=()
share_args=()
if [[ $REBOOT -eq 1 ]]; then
	echo "mode:      reboot from the installed disks (no installer media)"
else
	boot_args=(-cdrom "$isofile" -boot d)
	share_args=(
		-virtfs "local,path=$run/share,mount_tag=harness,security_model=none,id=harness"
		-virtfs "local,path=$REPO,mount_tag=repo,security_model=none,id=repo,readonly=on"
	)
	if [[ -n "$CACHE" ]]; then
		share_args+=(-virtfs "local,path=$CACHE,mount_tag=nixcache,security_model=none,id=nixcache,readonly=on")
		echo "cache:     $CACHE"
	fi
fi

echo "scenario:  $(basename "$SCENARIO")"
echo "disks:     $i"
echo "iso:       $isofile"
echo "workdir:   $run"
echo

qemu_args=(
	-machine "q35,accel=kvm"
	-cpu host
	-smp 4
	-m 4096
	-drive "if=pflash,format=raw,unit=0,readonly=on,file=$OVMF_CODE"
	-drive "if=pflash,format=raw,unit=1,file=$run/OVMF_VARS.fd"
	"${boot_args[@]}"
	"${disk_args[@]}"
	"${share_args[@]}"
	-netdev "user,id=n0"
	-device "virtio-net-pci,netdev=n0"
	-nographic
)

if [[ $INTERACTIVE -eq 1 ]]; then
	exec qemu-system-x86_64 "${qemu_args[@]}"
fi

log="$run/console.log"
set +o errexit
timeout "$TIMEOUT" qemu-system-x86_64 "${qemu_args[@]}" </dev/null | tee "$log"
qemu_rc=${PIPESTATUS[0]}
set -o errexit

echo
if grep -q "HARNESS: DONE" "$log"; then
	rc="$(grep -o 'HARNESS: EXIT [0-9]*' "$log" | tail -1 | grep -o '[0-9]*$' || echo "?")"
	echo "scenario finished, run.sh exited $rc"
	echo "console log: $log"
	[[ "$rc" == "0" ]] || exit 1
	exit 0
fi

if [[ $qemu_rc -eq 124 ]]; then
	echo "TIMED OUT after ${TIMEOUT}s without reaching HARNESS: DONE"
else
	echo "VM exited (qemu rc $qemu_rc) without reaching HARNESS: DONE"
fi
echo "console log: $log"
exit 1
