#!/usr/bin/env bash
#
# Installs a host from this repository onto local disks.
#
# The script works in two stages. First it builds a plan: which host to install,
# which disk each storage pool goes on, and how large the boot and swap
# partitions should be. It checks that plan against the host's configuration and
# refuses to continue if the two disagree. Only after that does it write
# anything to a disk.
#
# Nothing is written to any disk until the plan has passed every check and you
# have confirmed it once.

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSEMBLE="$SCRIPT_DIR/assemble.nix"
REQUIREMENTS="$SCRIPT_DIR/lib/requirements.nix"
HOSTS_DIR="$SCRIPT_DIR/modules/hosts"
NIX_FEATURES="nix-command flakes"

PLAN_IN=""
PLAN_OUT=""
ASSUME_YES=0
NO_INSTALL=0
REGENERATE="ask"
NEW_HOST=0

say() { printf '   %s\n' "$*"; }
blank() { printf '\n'; }
section() { printf '\n== %s %s\n' "$*" "$(printf '=%.0s' $(seq 1 $((62 - ${#1}))))"; }
ok() { printf '   ok   %s\n' "$*"; }
problem() {
	printf '   !!   %s\n' "$1"
	shift
	local l
	for l in "$@"; do printf '        %s\n' "$l"; done
}
die() {
	printf '\n%s\n' "Error: $*" >&2
	exit 1
}

usage() {
	cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --plan FILE        Use a previously saved plan instead of asking questions.
  --save-plan FILE   Build and check a plan, write it to FILE, then stop
                     without touching any disk. Use this to review a plan
                     before committing to it.
  --regenerate       Rewrite the host's hardware.nix from the disks this run
                     creates. Only meaningful for a host that already has one.
  --keep-hardware    Leave an existing hardware.nix untouched.
  --yes              Do not ask for the final confirmation. Intended for
                     automated runs; it still refuses a plan that fails checks.
  --no-install       Partition the disks, create the filesystems and mount
                     them, then stop without building or installing anything.
  -h, --help         Show this message.

With no options the script asks questions, shows you the resulting plan, and
waits for confirmation before writing anything.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--plan)
		PLAN_IN="${2:-}"
		[[ -n "$PLAN_IN" ]] || die "--plan needs a file path."
		shift 2
		;;
	--save-plan)
		PLAN_OUT="${2:-}"
		[[ -n "$PLAN_OUT" ]] || die "--save-plan needs a file path."
		shift 2
		;;
	--regenerate)
		REGENERATE="yes"
		shift
		;;
	--keep-hardware)
		REGENERATE="no"
		shift
		;;
	--yes)
		ASSUME_YES=1
		shift
		;;
	--no-install)
		NO_INSTALL=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*) die "Unknown option: $1. Run with --help to see the available options." ;;
	esac
done

# ---------------------------------------------------------------- prerequisites

check_tools() {
	local purpose="$1"
	shift
	local missing=() t
	for t in "$@"; do
		command -v "$t" >/dev/null 2>&1 || missing+=("$t")
	done
	((${#missing[@]} > 0)) || return 0
	say "This machine is missing tools needed to $purpose:"
	for t in "${missing[@]}"; do say "  - $t"; done
	blank
	say "Boot the NixOS installer image, which provides all of them, and run"
	say "this script again from there."
	exit 1
}

require_planning_tools() {
	check_tools "read the configuration and inspect disks" nix lsblk jq
	[[ -r "$ASSEMBLE" ]] || die "Cannot read $ASSEMBLE. Run this script from inside a clone of the repository."
	[[ -r "$REQUIREMENTS" ]] || die "Cannot read $REQUIREMENTS. The clone looks incomplete."
}

require_install_tools() {
	# discovering this mid-write leaves partly-erased disks, so it has to fail before anything is touched
	((EUID == 0)) || die "Partitioning disks needs root. Run this script again with sudo."
	check_tools "partition disks and install" \
		sgdisk zpool zfs mkfs.fat mkswap blkdiscard nixos-install nixos-generate-config
}

# ------------------------------------------------------------------------ hosts

list_hosts() {
	local d
	for d in "$HOSTS_DIR"/*/; do
		[[ -d "$d" ]] || continue
		local name
		name="$(basename "$d")"
		[[ "${name:0:1}" != "_" ]] || continue
		say "$name"
	done
}

host_exists() {
	local want="$1" h
	while read -r h; do
		[[ "$h" != "$want" ]] || return 0
	done < <(list_hosts)
	return 1
}

valid_tags() {
	nix eval --json --file "$ASSEMBLE" --apply "f: (f { }).validTags" \
		--extra-experimental-features "$NIX_FEATURES" 2>/dev/null | jq -r '.[]' 2>/dev/null || true
}

# a machine this repository has never seen has no directory to select, so one is written before anything else runs
create_host() {
	local name tags system user hostid answer tag valid
	mapfile -t valid < <(valid_tags)

	while true; do
		read -rp "Name for this machine: " name || die "No answer received. This script has to be run from a terminal."
		if [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
			say "Use letters, digits, dashes and underscores, and do not start with a dash or underscore."
			continue
		fi
		if host_exists "$name"; then
			say "\"$name\" already exists in $HOSTS_DIR. Choose a different name."
			continue
		fi
		break
	done

	blank
	if ((${#valid[@]} > 0)); then
		say "Tags decide which parts of the configuration this machine gets."
		say "Available: ${valid[*]}"
	else
		say "Tags decide which parts of the configuration this machine gets."
	fi
	while true; do
		read -rp "Tags for $name, separated by spaces (enter for none): " answer || die "No answer received. This script has to be run from a terminal."
		tags=""
		local ok=1
		for tag in $answer; do
			if ((${#valid[@]} > 0)) && ! printf '%s\n' "${valid[@]}" | grep -qx "$tag"; then
				say "\"$tag\" is not one of: ${valid[*]}"
				ok=0
				break
			fi
			tags+="    \"$tag\""$'\n'
		done
		((ok == 1)) && break
	done

	read -rp "System type [x86_64-linux]: " system || die "No answer received. This script has to be run from a terminal."
	system="${system:-x86_64-linux}"

	while true; do
		read -rp "Username for the primary account on $name: " user || die "No answer received. This script has to be run from a terminal."
		[[ "$user" =~ ^[a-z_][a-z0-9_-]*$ ]] && break
		say "Use a lowercase name starting with a letter or underscore."
	done

	hostid="$(head -c4 /dev/urandom | od -A none -t x4 | tr -d ' \n')"

	mkdir -p "$HOSTS_DIR/$name"
	cat >"$HOSTS_DIR/$name/metadata.nix" <<EOF
{
  system = "$system";
  # ZFS reads this from /etc/hostid to refuse importing a pool owned by another machine, so it must differ per host
  hostId = "$hostid";
  tags = [
$tags  ];
}
EOF
	cat >"$HOSTS_DIR/$name/host.nix" <<EOF
{ ... }:
{
  mySystem.user = {
    name = "$user";
    description = "$user";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  # nh reads NH_FILE instead of NH_FLAKE; NH_ATTRP is derived from the host directory name
  environment.variables = {
    NH_FILE = "/home/$user/anomalos/assemble.nix";
  };

  system.stateVersion = "24.11";
}
EOF

	# the plan is checked against the filesystems the configuration declares, so a machine with none cannot be planned for
	cat >"$HOSTS_DIR/$name/hardware.nix" <<'EOF'
{
  config,
  lib,
  ...
}:
{
  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    zfs.devNodes = "/dev/disk/by-partuuid";
    supportedFilesystems.zfs = true;
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "@SYSTEM@";
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  fileSystems."/" = {
    device = "zroot/root";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };
  fileSystems."/nix" = {
    device = "zroot/nix";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/persist" = {
    device = "zroot/persist";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/cache" = {
    device = "zroot/cache";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=5G"
      "mode=1777"
    ];
  };

  swapDevices = [ ];

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
    priority = 100;
  };
}
EOF
	sed -i "s|@SYSTEM@|$system|" "$HOSTS_DIR/$name/hardware.nix"

	blank
	say "Created $HOSTS_DIR/$name with identifier $hostid."
	NEW_HOST=1
	say "It starts with this repository's standard storage layout: a temporary root,"
	say "and zroot holding /nix, /persist and /cache. The disks are set up to match,"
	say "and then the real hardware configuration for this machine replaces it."
	HOST="$name"
	REGENERATE="yes"
}

choose_host() {
	local hosts
	mapfile -t hosts < <(list_hosts)

	if ((${#hosts[@]} > 0)); then
		section "Choosing a host"
	say "Hosts defined in this repository:"
		local i
		for i in "${!hosts[@]}"; do
			local meta="$HOSTS_DIR/${hosts[i]}/metadata.nix"
			local detail=""
			if [[ -r "$meta" ]]; then
				detail="$(nix eval --json --file "$meta" --extra-experimental-features "$NIX_FEATURES" 2>/dev/null |
					jq -r '"\(.system)  \(.tags | join(", "))"' 2>/dev/null || true)"
			fi
			printf '  %d) %-16s %s\n' "$((i + 1))" "${hosts[i]}" "$detail"
		done
		printf '  %d) %s\n' "$((${#hosts[@]} + 1))" "a machine not listed above"
		blank
	else
		say "This repository defines no hosts yet."
		blank
		create_host
		return
	fi

	local answer
	while true; do
		read -rp "Which host is being installed on this machine? " answer || die "No answer received. This script has to be run from a terminal."
		if [[ "$answer" =~ ^[0-9]+$ ]] && ((answer == ${#hosts[@]} + 1)); then
			blank
			create_host
			return
		fi
		if [[ "$answer" =~ ^[0-9]+$ ]] && ((answer >= 1 && answer <= ${#hosts[@]})); then
			HOST="${hosts[answer - 1]}"
			return
		fi
		if host_exists "$answer"; then
			HOST="$answer"
			return
		fi
		say "That is not one of the choices above. Enter a number or a host name."
	done
}

# ----------------------------------------------------------------- requirements

load_requirements() {
	section "Reading what \"$HOST\" expects from its disks"
	REQS="$WORK/requirements.json"
	if ! nix eval --json --file "$REQUIREMENTS" --apply "f: f \"$HOST\"" \
		--extra-experimental-features "$NIX_FEATURES" >"$REQS" 2>"$WORK/requirements.err"; then
		say "The configuration for \"$HOST\" could not be evaluated. Nothing has been"
		say "written to any disk. The error was:"
		blank
		sed 's/^/  /' "$WORK/requirements.err" | tail -20
		exit 1
	fi
}

# ------------------------------------------------------------------------ disks

# type=disk excludes partitions, and zram is memory rather than storage
usable_disks_json() {
	lsblk -J -b -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,MODEL |
		jq '[ .blockdevices[]
              | select(.type == "disk")
              | select(.name | startswith("zram") | not)
              | { path, size, model: (.model // "unknown"),
                  holds: [ (.children // [])[] | select(.fstype == "zfs_member") | .label ] } ]'
}

human_size() { numfmt --to=iec --suffix=B "$1" 2>/dev/null || printf '%s bytes' "$1"; }

show_disks() {
	local n
	n="$(jq 'length' <<<"$DISKS")"
	section "Disks attached to this machine"
	local i
	for ((i = 0; i < n; i++)); do
		local path size model holds
		path="$(jq -r ".[$i].path" <<<"$DISKS")"
		size="$(jq -r ".[$i].size" <<<"$DISKS")"
		model="$(jq -r ".[$i].model" <<<"$DISKS")"
		holds="$(jq -r ".[$i].holds | join(\", \")" <<<"$DISKS")"
		printf '  %d) %-16s %-10s %s\n' "$((i + 1))" "$path" "$(human_size "$size")" "$model"
		if [[ -n "$holds" ]]; then
			printf '     %s\n' "Already contains a storage pool named: $holds"
			printf '     %s\n' "Choosing this disk destroys that pool and everything in it."
		fi
	done
	blank
}

pick_disk() {
	local prompt="$1" answer n
	n="$(jq 'length' <<<"$DISKS")"
	while true; do
		read -rp "$prompt " answer || die "No answer received. This script has to be run from a terminal."
		if [[ "$answer" =~ ^[0-9]+$ ]] && ((answer >= 1 && answer <= n)); then
			jq -r ".[$((answer - 1))].path" <<<"$DISKS"
			return
		fi
		if jq -e --arg p "$answer" 'any(.[]; .path == $p)' <<<"$DISKS" >/dev/null; then
			printf '%s\n' "$answer"
			return
		fi
		say "That is not one of the disks listed above. Enter a number or a device path." >&2
	done
}

ask_number() {
	local prompt="$1" default="$2" answer
	while true; do
		read -rp "$prompt [$default] " answer || die "No answer received. This script has to be run from a terminal."
		answer="${answer:-$default}"
		if [[ "$answer" =~ ^[0-9]+$ ]]; then
			printf '%s\n' "$answer"
			return
		fi
		say "Enter a whole number, or press enter to accept $default." >&2
	done
}

ask_yes_no() {
	local prompt="$1" answer
	while true; do
		read -rp "$prompt [y/n] " answer || die "No answer received. This script has to be run from a terminal."
		case "$answer" in
		[Yy]*)
			return 0
			;;
		[Nn]*)
			return 1
			;;
		*) say "Please answer y or n." ;;
		esac
	done
}

# ------------------------------------------------------------------------- plan

build_plan() {
	DISKS="$(usable_disks_json)"
	local ndisks
	ndisks="$(jq 'length' <<<"$DISKS")"
	((ndisks > 0)) || die "No usable disks were found on this machine."

	blank
	show_disks

	local pools
	mapfile -t pools < <(jq -r '.pools[]' "$REQS")
	say "The configuration for \"$HOST\" stores data in ${#pools[@]} pool(s): ${pools[*]}"
	say "Each one needs a disk. A disk can hold only one pool."
	blank

	local assignments="[]" pool disk
	for pool in "${pools[@]}"; do
		while true; do
			disk="$(pick_disk "Which disk should hold the pool \"$pool\"? (number or path)")"
			if jq -e --arg d "$disk" 'any(.[]; .disk == $d)' <<<"$assignments" >/dev/null; then
				say "$disk is already assigned to another pool. Choose a different disk."
				continue
			fi
			break
		done
		assignments="$(jq --arg n "$pool" --arg d "$disk" '. + [{name: $n, disk: $d}]' <<<"$assignments")"
	done

	blank
	say "The machine needs one disk to boot from. It gets a 1GiB boot partition"
	say "and a temporary swap partition used only during installation."
	local boot_pool boot_disk
	boot_pool="$(jq -r '.[0].name' <<<"$assignments")"
	boot_disk="$(jq -r '.[0].disk' <<<"$assignments")"
	if ((${#pools[@]} > 1)); then
		say "By default this is $boot_disk, the disk holding \"$boot_pool\"."
		if ! ask_yes_no "Use $boot_disk as the boot disk?"; then
			boot_disk="$(pick_disk "Which disk should the machine boot from? (number or path)")"
			jq -e --arg d "$boot_disk" 'any(.[]; .disk == $d)' <<<"$assignments" >/dev/null ||
				die "The boot disk must be one of the disks assigned to a pool."
		fi
	fi

	blank
	local boot_mib swap_gib
	boot_mib=1024
	swap_gib="$(ask_number "How much swap should the installer use, in GiB?" 16)"
	say "Swap is only used while installing. What the machine uses afterwards is"
	say "whatever its configuration declares."

	blank
	local encrypt=false
	if ask_yes_no "Encrypt the storage pools with a passphrase?"; then
		encrypt=true
		say "You will be asked to set the passphrase when each pool is created."
	fi

	local boot_label
	boot_label="$(jq -r '(.labels[] | select(.mountPoint == "/boot") | .label) // "NIXBOOT"' "$REQS")"

	PLAN="$WORK/plan.json"
	jq -n \
		--arg host "$HOST" \
		--arg bootDisk "$boot_disk" \
		--arg bootLabel "$boot_label" \
		--argjson bootMiB "$boot_mib" \
		--argjson swapGiB "$swap_gib" \
		--argjson encrypt "$encrypt" \
		--argjson newHost "$([[ $NEW_HOST -eq 1 ]] && echo true || echo false)" \
		--argjson pools "$assignments" \
		--slurpfile reqs "$REQS" \
		'{
           host: $host, newHost: $newHost,
           bootDisk: $bootDisk, bootLabel: $bootLabel,
           bootMiB: $bootMiB, swapGiB: $swapGiB, encrypt: $encrypt,
           pools: $pools,
           installRoot: ($reqs[0].pools[0] + "/root"),
           datasets: $reqs[0].datasets,
           mounts: $reqs[0].zfsMounts
         }' >"$PLAN"
}

# --------------------------------------------------------------------- checking

check_plan() {
	local problems=0

	section "Checking the plan against the configuration"

	local missing_pools
	missing_pools="$(jq -r --slurpfile p "$PLAN" \
		'[ .pools[] | select( . as $n | ($p[0].pools | map(.name)) | index($n) | not ) ] | .[]' "$REQS")"
	if [[ -n "$missing_pools" ]]; then
		problem "the configuration expects storage pools this plan does not create" \
			"Assign a disk to each pool listed below, or change the configuration."
		while read -r pool; do
			printf '        - %s\n' "\"$pool\" is required, but no disk is assigned to it"
		done <<<"$missing_pools"
		blank
		problems=$((problems + 1))
	else
		ok "every storage pool the configuration needs has a disk assigned"
	fi

	local missing_ds
	missing_ds="$(jq -r --slurpfile p "$PLAN" \
		'[ .datasets[] | select( . as $d | $p[0].datasets | index($d) | not ) ] | .[]' "$REQS")"
	if [[ -n "$missing_ds" ]]; then
		problem "the configuration mounts filesystems this plan does not create" \
			"The machine would fail to mount these after it reboots."
		while read -r ds; do
			printf '        - %s\n' "\"$ds\" is mounted by the configuration but is not in the plan"
		done <<<"$missing_ds"
		blank
		problems=$((problems + 1))
	else
		ok "every filesystem the configuration mounts will be created"
	fi

	local want_label have_label
	want_label="$(jq -r '(.labels[] | select(.mountPoint == "/boot") | .label) // ""' "$REQS")"
	have_label="$(jq -r '.bootLabel // ""' "$PLAN")"
	if [[ -n "$want_label" && "$want_label" != "$have_label" ]]; then
		problem "the boot partition label does not match" "The machine would not boot."
		printf '        - %s\n' "the configuration looks for a partition labelled \"$want_label\""
		printf '        - %s\n' "this plan would label it \"${have_label:-none}\""
		blank
		problems=$((problems + 1))
	else
		ok "boot partition will be labelled \"$want_label\", which is what the configuration expects"
	fi

	local hostid
	hostid="$(jq -r '.hostId // ""' "$REQS")"
	if [[ -z "$hostid" || "$hostid" == "null" ]]; then
		problem "this host has no hostId" "ZFS needs one to tell machines apart." "Set hostId in $HOSTS_DIR/$HOST/metadata.nix."
		blank
		problems=$((problems + 1))
	else
		ok "host identifier is $hostid"
	fi

	local plan_disks
	plan_disks="$(jq -r '.pools[].disk' "$PLAN")"
	while read -r d; do
		[[ -n "$d" ]] || continue
		if [[ ! -b "$d" ]]; then
			problem "$d is not a block device on this machine"
			blank
			problems=$((problems + 1))
		fi
	done <<<"$plan_disks"

	blank
	if ((problems > 0)); then
		say "Found $problems problem(s). Nothing has been written to any disk."
		return 1
	fi
	say "The plan satisfies the configuration."
	return 0
}

check_bootable() {
	local problems=0

	section "Checking that the machine can boot"

	local mounts
	mounts="$(jq -r '.mountPoints[]' "$REQS")"

	if grep -qx "/" <<<"$mounts"; then
		ok "the configuration declares a root filesystem"
	else
		problem "the configuration declares no root filesystem" "Without a filesystem mounted at / the machine cannot start."
		blank
		problems=$((problems + 1))
	fi

	if grep -qx "/boot" <<<"$mounts"; then
		ok "the configuration declares a boot filesystem"
	else
		problem "the configuration declares no filesystem at /boot" "The bootloader has nowhere to put the kernel."
		blank
		problems=$((problems + 1))
	fi

	blank
	if ((problems > 0)); then
		say "Found $problems problem(s). The disks are set up, but nothing has been installed."
		return 1
	fi
	say "The configuration describes a machine that can boot."
	return 0
}

show_plan() {
	local host bootDisk bootLabel bootMiB swapGiB encrypt
	host="$(jq -r .host "$PLAN")"
	bootDisk="$(jq -r .bootDisk "$PLAN")"
	bootLabel="$(jq -r .bootLabel "$PLAN")"
	bootMiB="$(jq -r .bootMiB "$PLAN")"
	swapGiB="$(jq -r .swapGiB "$PLAN")"
	encrypt="$(jq -r .encrypt "$PLAN")"

	section "This is what will happen"
	say "  Host:        $host"
	say "  Boot disk:   $bootDisk  (${bootMiB}MiB partition labelled $bootLabel)"
	say "  Swap:        ${swapGiB}GiB on $bootDisk, used during installation only"
	say "  Encryption:  $([[ "$encrypt" == "true" ]] && echo "yes, passphrase" || echo "no")"
	blank
	say "  Storage pools:"
	jq -r '.pools[] | "    \(.name) on \(.disk)"' "$PLAN"
	blank
	say "  Filesystems created and mounted:"
	jq -r '.mounts[] | "    \(.device) at \(.mountPoint)"' "$PLAN"
	blank
	say "  Every disk listed above will be completely erased."
	blank
}

# -------------------------------------------------------------------- execution

partition_boot_disk() {
	local disk="$1" boot_mib="$2" swap_gib="$3" label="$4"

	say "Erasing $disk and creating partitions."
	blkdiscard -f "$disk" 2>/dev/null || true
	sgdisk --zap-all "$disk" >/dev/null

	sgdisk -n3:1M:+"${boot_mib}"M -t3:EF00 -c3:boot "$disk" >/dev/null
	sgdisk -n2:0:+"${swap_gib}"G -t2:8200 -c2:swap "$disk" >/dev/null
	sgdisk -n1:0:0 -t1:BF01 -c1:pool "$disk" >/dev/null
	sgdisk -p "$disk" >/dev/null
	udevadm settle 2>/dev/null || sleep 3

	BOOT_PART="$(part_path "$disk" 3)"
	SWAP_PART="$(part_path "$disk" 2)"
	POOL_PART="$(part_path "$disk" 1)"

	say "Formatting the boot partition."
	mkfs.fat -F 32 "$BOOT_PART" -n "$label" >/dev/null

	say "Enabling swap for the installation."
	mkswap "$SWAP_PART" --label SWAP >/dev/null
	swapon "$SWAP_PART"
}

# some device families separate the partition number with a p, so ask the kernel rather than guess
part_path() {
	local disk="$1" num="$2" candidate
	for candidate in "${disk}${num}" "${disk}p${num}"; do
		[[ -b "$candidate" ]] && {
			printf '%s\n' "$candidate"
			return
		}
	done
	die "Could not find partition $num on $disk after creating it."
}

wipe_whole_disk() {
	local disk="$1"
	say "Erasing $disk."
	blkdiscard -f "$disk" 2>/dev/null || true
	sgdisk --zap-all "$disk" >/dev/null
	sgdisk -n1:0:0 -t1:BF01 -c1:pool "$disk" >/dev/null
	sgdisk -p "$disk" >/dev/null
	udevadm settle 2>/dev/null || sleep 3
	POOL_PART="$(part_path "$disk" 1)"
}

create_pool() {
	local name="$1" part="$2" encrypt="$3"
	local opts=(-f -o ashift=12 -o autotrim=on
		-O compression=zstd -O acltype=posixacl -O atime=off
		-O xattr=sa -O normalization=formD -O mountpoint=none)
	if [[ "$encrypt" == "true" ]]; then
		opts+=(-O encryption=aes-256-gcm -O keyformat=passphrase -O keylocation=prompt)
		say "Creating pool \"$name\". You will be asked to set its passphrase now."
	else
		say "Creating pool \"$name\"."
	fi
	zpool create "${opts[@]}" "$name" "$part"
}

apply_plan() {
	local encrypt boot_disk boot_mib swap_gib boot_label install_root
	encrypt="$(jq -r .encrypt "$PLAN")"
	boot_disk="$(jq -r .bootDisk "$PLAN")"
	boot_mib="$(jq -r .bootMiB "$PLAN")"
	swap_gib="$(jq -r .swapGiB "$PLAN")"
	boot_label="$(jq -r .bootLabel "$PLAN")"
	install_root="$(jq -r .installRoot "$PLAN")"

	blank
	section "Writing to disks"

	local n i name disk
	n="$(jq '.pools | length' "$PLAN")"
	for ((i = 0; i < n; i++)); do
		name="$(jq -r ".pools[$i].name" "$PLAN")"
		disk="$(jq -r ".pools[$i].disk" "$PLAN")"
		if [[ "$disk" == "$boot_disk" ]]; then
			partition_boot_disk "$disk" "$boot_mib" "$swap_gib" "$boot_label"
		else
			wipe_whole_disk "$disk"
		fi
		create_pool "$name" "$POOL_PART" "$encrypt"
	done

	say "Creating the filesystem the installation is written into."
	zfs create -p -o mountpoint=legacy "$install_root"
	zfs snapshot "${install_root}@blank"
	mount -t zfs "$install_root" /mnt

	say "Mounting the boot partition."
	mount --mkdir "$BOOT_PART" /mnt/boot

	local persist_ds
	persist_ds="$(jq -r '(.mounts[] | select(.mountPoint == "/persist") | .device) // empty' "$PLAN")"
	RESTORE_FROM=""
	[[ -z "$persist_ds" ]] || ask_restore "$persist_ds"

	local ds mp
	while read -r ds mp; do
		[[ -n "$ds" ]] || continue
		if [[ "$mp" == "/persist" && -n "$RESTORE_FROM" ]]; then
			say "Restoring $ds from $RESTORE_FROM."
			zfs receive -o mountpoint=legacy "$ds" <"$RESTORE_FROM" ||
				die "Restoring $ds failed. The disks are set up, but nothing was installed."
			mount --mkdir -t zfs "$ds" "/mnt$mp"
			continue
		fi
		say "Creating $ds for $mp."
		# -p because a nested dataset cannot be created before its parents exist
		zfs create -p -o mountpoint=legacy "$ds"
		mount --mkdir -t zfs "$ds" "/mnt$mp"
	done < <(jq -r '.mounts[] | "\(.device) \(.mountPoint)"' "$PLAN")
}

# asked before the dataset loop, whose stdin is the plan rather than the terminal
ask_restore() {
	local ds="$1" path
	((ASSUME_YES == 0)) || return 0

	blank
	say "The /persist dataset holds everything this machine keeps between reboots,"
	say "including the SSH host key its encrypted secrets are tied to. Restoring it"
	say "from a snapshot keeps those secrets working. Creating it empty means the"
	say "machine generates a new host key, and secrets encrypted to the old one"
	say "will need to be re-encrypted before they work again."
	blank
	ask_yes_no "Restore $ds from a snapshot file?" || return 0

	while true; do
		read -rp "Full path to the snapshot file: " path || die "No answer received. This script has to be run from a terminal."
		if [[ -r "$path" ]]; then
			RESTORE_FROM="$path"
			return 0
		fi
		say "Cannot read that file. Enter a path that exists."
	done
}

# ----------------------------------------------------------- hardware config

handle_hardware_config() {
	local hw="$HOSTS_DIR/$HOST/hardware.nix"
	local generated="$WORK/generated"

	mkdir -p "$generated"
	section "Recording the hardware configuration"
	say "Recording the disk layout that was just created."
	nixos-generate-config --root /mnt --dir "$generated" >/dev/null 2>&1 ||
		die "nixos-generate-config failed. The disks are set up; nothing has been installed."

	# nixos-generate-config resolves by-uuid before by-label, and a uuid does not survive moving the disk
	local gen="$generated/hardware-configuration.nix" mp lbl
	while read -r mp lbl; do
		[[ -n "$mp" ]] || continue
		awk -v mp="$mp" -v lbl="$lbl" '
			index($0, "fileSystems.\"" mp "\"") { inblock = 1 }
			inblock && /device = "/ {
				sub(/device = "[^"]*"/, "device = \"/dev/disk/by-label/" lbl "\"")
				inblock = 0
			}
			{ print }
		' "$gen" >"$gen.relabelled" && mv "$gen.relabelled" "$gen"
		say "Kept $mp on its label \"$lbl\" rather than the generated device identifier."
	done < <(jq -r '.labels[] | "\(.mountPoint) \(.label)"' "$REQS")

	# the swap partition exists only for the installation, so recording it would make a temporary disk permanent
	awk '
		/^[[:space:]]*swapDevices[[:space:]]*=/ { print "  swapDevices = [ ];"; skip = 1; next }
		skip && /\];/ { skip = 0; next }
		skip { next }
		{ print }
	' "$gen" >"$gen.noswap" && mv "$gen.noswap" "$gen"
	say "Left swap out of the hardware configuration; the installer's swap partition is temporary."

	# nixos-generate-config never emits neededForBoot, and without it /persist is missing from the initrd and /etc/machine-id never resolves
	while read -r mp; do
		[[ -n "$mp" ]] || continue
		awk -v mp="$mp" '
			index($0, "fileSystems.\"" mp "\"") { inblock = 1 }
			inblock && /};/ {
				print "      neededForBoot = true;"
				inblock = 0
			}
			{ print }
		' "$gen" >"$gen.needed" && mv "$gen.needed" "$gen"
		say "Marked $mp as needed for boot so the initrd still mounts it."
	done < <(jq -r '.neededForBoot[]' "$REQS")

	if [[ ! -e "$hw" ]]; then
		say "This host has no hardware.nix yet. Writing the generated one."
		cp "$generated/hardware-configuration.nix" "$hw"
		say "Wrote $hw. Review it before the machine goes into service."
		return
	fi

	case "$REGENERATE" in
	no)
		say "Keeping the existing hardware.nix as instructed."
		;;
	yes)
		cp "$hw" "$hw.replaced"
		cp "$generated/hardware-configuration.nix" "$hw"
		say "Replaced $hw. The previous version is at $hw.replaced."
		;;
	*)
		blank
		say "This host already has a hardware.nix. The freshly generated one is at:"
		say "  $generated/hardware-configuration.nix"
		say "Replacing it would discard any changes made by hand, such as kernel"
		say "settings or graphics options."
		if ask_yes_no "Replace $hw with the generated version?"; then
			cp "$hw" "$hw.replaced"
			cp "$generated/hardware-configuration.nix" "$hw"
			say "Replaced it. The previous version is at $hw.replaced."
		else
			say "Keeping the existing hardware.nix."
		fi
		;;
	esac
}

# ------------------------------------------------------------------------- main

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

require_planning_tools

if [[ -n "$PLAN_IN" ]]; then
	[[ -r "$PLAN_IN" ]] || die "Cannot read the plan file: $PLAN_IN"
	jq -e . "$PLAN_IN" >/dev/null 2>&1 || die "$PLAN_IN is not valid JSON."
	PLAN="$WORK/plan.json"
	cp "$PLAN_IN" "$PLAN"
	HOST="$(jq -r '.host // ""' "$PLAN")"
	[[ -n "$HOST" ]] || die "The plan file does not name a host."
	host_exists "$HOST" || die "The plan names host \"$HOST\", which has no directory in $HOSTS_DIR."
	if [[ "$(jq -r '.newHost // false' "$PLAN")" == "true" && "$REGENERATE" == "ask" ]]; then
		REGENERATE="yes"
	fi
	say "Using the plan in $PLAN_IN for host \"$HOST\"."
	load_requirements
else
	choose_host
	blank
	load_requirements
	build_plan
fi

blank
check_plan || exit 1

if [[ -n "$PLAN_OUT" ]]; then
	cp "$PLAN" "$PLAN_OUT"
	blank
	say "Plan written to $PLAN_OUT. No disks were touched."
	say "Run this script again with --plan $PLAN_OUT to carry it out."
	exit 0
fi

blank
show_plan

if ((ASSUME_YES == 0)); then
	ask_yes_no "Erase those disks and install?" || {
		say "Stopped. Nothing was written."
		exit 0
	}
fi

require_install_tools
apply_plan
handle_hardware_config

blank
say "The disks now exist, so the configuration can be checked against them"
say "rather than against what it looked like beforehand."
blank
load_requirements
check_plan || die "The plan and the configuration disagree. The disks are set up, but nothing was installed."
blank
check_bootable || exit 1

if ((NO_INSTALL == 1)); then
	blank
	say "Disks are set up and mounted under /mnt. Stopping before the install as asked."
	say "Nothing has been built and nothing has been installed."
	exit 0
fi

blank
section "Building and installing"
say "Building and installing the system for \"$HOST\". This can take a while."
say "The build happens on the disks that were just prepared, so the machine"
say "doing the installation does not need memory to hold the whole system."

SUBSTITUTERS="$(jq -r '.substituters | join(" ")' "$REQS")"
TRUSTED_KEYS="$(jq -r '.trustedPublicKeys | join(" ")' "$REQS")"
if [[ -n "$SUBSTITUTERS" ]]; then
	blank
	say "Package caches this host trusts, taken from its own configuration:"
	jq -r '.substituters[] | "  " + .' "$REQS"
fi
blank

# --file/--attr makes nixos-install build with --store /mnt; building here instead would need RAM the size of the closure
nixos-install \
	--root /mnt \
	--file "$ASSEMBLE" \
	--attr "nixosConfigurations.$HOST" \
	--no-root-password \
	--no-channel-copy \
	--option extra-experimental-features "$NIX_FEATURES" \
	--option substituters "$SUBSTITUTERS" \
	--option trusted-public-keys "$TRUSTED_KEYS" ||
	die "The installation failed. The disks are set up, but the system was not installed."

blank
# zfs records the importing host in the pool, so a pool left imported here is refused by the machine that just got installed
section "Releasing the disks"
say "Releasing the disks so the installed system can claim them."
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true
export_failed=0
while read -r pool; do
	[[ -n "$pool" ]] || continue
	zpool export "$pool" || export_failed=1
done < <(jq -r '.pools[].name' "$PLAN")

if ((export_failed == 1)); then
	blank
	say "The system was installed, but a storage pool could not be released."
	say "This machine will refuse to import it at boot. Before rebooting, run:"
	say ""
	jq -r '.pools[].name' "$PLAN" | while read -r p; do say "  zpool export $p"; done
	exit 1
fi

blank
say "Installation finished. It is safe to reboot."
