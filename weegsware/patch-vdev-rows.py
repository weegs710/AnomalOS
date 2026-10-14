# an unmounted zfs_member is a vdev label, not a filesystem, so offering it as a sidebar mount row
# fires a polkit prompt onto the controlling tty for a mount that can never succeed
import sys

OLD = b"""PSEUDO_FSTYPES = new Set([
    "squashfs",
    "tmpfs",
    "devtmpfs",
    "proc",
    "sysfs",
    "efivarfs",
    "overlay",
    "ramfs",
    "devfs",
    "cgroup"
  ])"""

# only `.has` is ever called on it, so an object with that one method is a drop-in
NEW = (
    b"PSEUDO_FSTYPES = { has: (t) => "
    b"/^(squashfs|tmpfs|devtmpfs|proc|sysfs|efivarfs|overlay|ramfs|devfs|cgroup)$|_member$/"
    b".test(t) }"
)

path: str = sys.argv[1]
with open(path, "rb") as fh:
    blob = bytearray(fh.read())

found: int = blob.count(OLD)
# the set is emitted once in an esm init block; a reformat upstream would move it
if found != 1:
    sys.exit(f"patch-vdev-rows: expected 1 match for the pseudo-fstype set, found {found}")
if len(NEW) > len(OLD):
    sys.exit("patch-vdev-rows: replacement longer than original")

at: int = blob.find(OLD)
blob[at : at + len(OLD)] = NEW + b" " * (len(OLD) - len(NEW))
with open(path, "wb") as fh:
    fh.write(bytes(blob))
print(f"patch-vdev-rows: rewrote the pseudo-fstype set at offset {at}")
