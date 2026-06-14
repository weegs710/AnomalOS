#!/usr/bin/env python3
# The AM2R YoYo runner only installs gamepad remap handlers for Xbox-named pads and hard-codes the xpad layout; this forces install and rewrites the tables to the 8BitDo Ultimate 2C BT raw layout. Idempotent and in-place safe.
import os
import sys

# .text maps VA = file_offset + 0x08048000
VA_BASE = 0x08048000

PATCHES = [
    (0x82E92D0, b"\x74\x28", b"\x90\x90", "force-install handlers"),
    (0x82E911E, b"\xb8\x02", b"\xb8\x03", "face X 2->3"),
    (0x82E9124, b"\xb8\x03", b"\xb8\x04", "face Y 3->4"),
    (0x82E912A, b"\xb8\x04", b"\xb8\x06", "LB 4->6"),
    (0x82E9130, b"\xb8\x05", b"\xb8\x07", "RB 5->7"),
    (0x82E9136, b"\xb8\x02\x50", b"\xb8\x05\x50", "LT axis 2->5"),
    (0x82E913C, b"\xb8\x05\x50", b"\xb8\x04\x50", "RT axis 5->4"),
    (0x82E9142, b"\xb8\x06", b"\xb8\x0a", "Select 6->10"),
    (0x82E9148, b"\xb8\x07", b"\xb8\x0b", "Start 7->11"),
    (0x82E914E, b"\xb8\x09", b"\xb8\x0d", "L3 9->13"),
    (0x82E9154, b"\xb8\x0a", b"\xb8\x0e", "R3 10->14"),
    (0x82E919E, b"\xb8\x03", b"\xb8\x02", "Rstick X axis 3->2"),
    (0x82E91A4, b"\xb8\x04", b"\xb8\x03", "Rstick Y axis 4->3"),
]


def main():
    if len(sys.argv) != 3:
        sys.exit(f"usage: {sys.argv[0]} <input-binary> <output-binary>")
    src, dst = sys.argv[1], sys.argv[2]

    with open(src, "rb") as f:
        data = bytearray(f.read())

    changed = False
    for va, old, new, label in PATCHES:
        off = va - VA_BASE
        actual = bytes(data[off:off + len(old)])
        if actual == new:
            continue
        if actual != old:
            sys.exit(f"FAIL {label} @0x{va:x}: expected {old.hex()} or {new.hex()} found {actual.hex()}")
        data[off:off + len(new)] = new
        changed = True

    if changed or os.path.abspath(src) != os.path.abspath(dst):
        with open(dst, "wb") as f:
            f.write(data)
        os.chmod(dst, os.stat(src).st_mode)
        print(f"am2r-patch: wrote {dst} (changed={changed})")
    else:
        print("am2r-patch: already patched, no changes")


if __name__ == "__main__":
    main()
