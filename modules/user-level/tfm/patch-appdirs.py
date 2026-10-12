# tfm never reads XDG_DATA_DIRS, so its hardcoded paths find almost no apps on NixOS
import sys

OLD = b"""applicationDirs = () => [
  path23.join(xdgDataHome(), "applications"),
  "/usr/local/share/applications",
  "/usr/share/applications",
  "/var/lib/flatpak/exports/share/applications",
  path23.join(os11.homedir(), ".local/share/flatpak/exports/share/applications")
]"""

NEW = (
    b'applicationDirs = () => [path23.join(xdgDataHome(), "applications")]'
    b'.concat((process.env.XDG_DATA_DIRS || "/usr/local/share:/usr/share")'
    b'.split(":").filter(Boolean).map((d) => path23.join(d, "applications")))'
)

path: str = sys.argv[1]
with open(path, "rb") as fh:
    blob = bytearray(fh.read())

found: int = blob.count(OLD)
# bundler-assigned aliases (path23, os11) can move between releases
if found != 1:
    sys.exit(f"patch-appdirs: expected 1 match for applicationDirs, found {found}")
if len(NEW) > len(OLD):
    sys.exit("patch-appdirs: replacement longer than original")

at: int = blob.find(OLD)
blob[at : at + len(OLD)] = NEW + b" " * (len(OLD) - len(NEW))
with open(path, "wb") as fh:
    fh.write(bytes(blob))
print(f"patch-appdirs: rewrote applicationDirs at offset {at}")
