# the mime db path is hardcoded to /usr/share/mime/globs2, which no NixOS box has, so every
# extension outside tfm's own 21-entry table resolves to no mime at all
import sys

OLD = b'readFile("/usr/share/mime/globs2", "utf8")'
NEW = b'readFile(process.env.TFM_GLOBS2, "utf8")'

path: str = sys.argv[1]
with open(path, "rb") as fh:
    blob = bytearray(fh.read())

found: int = blob.count(OLD)
# a bundler-renamed readFile would silently skip the rewrite
if found != 1:
    sys.exit(f"patch-globs2: expected 1 match for the globs2 read, found {found}")
if len(NEW) > len(OLD):
    sys.exit("patch-globs2: replacement longer than original")

at: int = blob.find(OLD)
blob[at : at + len(OLD)] = NEW + b" " * (len(OLD) - len(NEW))
with open(path, "wb") as fh:
    fh.write(bytes(blob))
print(f"patch-globs2: rewrote the globs2 read at offset {at}")
