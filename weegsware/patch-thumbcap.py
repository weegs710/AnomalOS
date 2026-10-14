# a 25 MiB file cap skips the thumbnail job outright, so every clip over it keeps a bare glyph
import sys

OLD = b"26214400"
# 1 GiB-ish ceiling; images past RASTER_FILE_LIMIT (256 MiB) still go out-of-process to magick
NEW = b"1e9"
EXPECTED = 3

path: str = sys.argv[1]
with open(path, "rb") as fh:
    blob = bytearray(fh.read())

found: int = blob.count(OLD)
# the grid const plus the preview and hero copies the bundler inlined
if found != EXPECTED:
    sys.exit(f"patch-thumbcap: expected {EXPECTED} matches for the thumb byte cap, found {found}")
if len(NEW) > len(OLD):
    sys.exit("patch-thumbcap: replacement longer than original")

blob = bytearray(blob.replace(OLD, NEW + b" " * (len(OLD) - len(NEW))))
with open(path, "wb") as fh:
    fh.write(bytes(blob))
print(f"patch-thumbcap: rewrote {found} thumb byte caps")
