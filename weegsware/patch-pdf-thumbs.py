# nothing but image/* and video/* is ever offered a thumbnail, so a pdf keeps its glyph forever
import sys

OLD_IMAGE = b'''fileIsImage = (name) => {
  const ext = extOf(name);
  if (FILE_ICON_BY_EXT[ext] === "file-image")
    return true;
  const mime = globs2ByExt?.get(ext);
  return !!mime && mime.startsWith("image/");
}'''

# the three thumb gates are its only callers, so widening it here covers grid, props and preview
NEW_IMAGE = b'''fileIsImage = (name) => {
  const ext = extOf(name);
  return FILE_ICON_BY_EXT[ext] === "file-image" || ext === "pdf" || !!globs2ByExt?.get(ext)?.startsWith("image/");
}'''

OLD_ARGV = b'''    "-define",
    `jpeg:size=${pxW * 2}x${pxH * 2}`,
    p,'''

# a multi-page or animated input makes magick write one png per frame into a stream that holds one
NEW_ARGV = b'''    "-define", `jpeg:size=${pxW * 2}x${pxH * 2}`, p + "[0]",'''

path: str = sys.argv[1]
with open(path, "rb") as fh:
    blob = bytearray(fh.read())

for label, old, new in (("fileIsImage", OLD_IMAGE, NEW_IMAGE), ("magick argv", OLD_ARGV, NEW_ARGV)):
    found: int = blob.count(old)
    if found != 1:
        sys.exit(f"patch-pdf-thumbs: expected 1 match for {label}, found {found}")
    if len(new) > len(old):
        sys.exit(f"patch-pdf-thumbs: {label} replacement longer than original")
    at: int = blob.find(old)
    blob[at : at + len(old)] = new + b" " * (len(old) - len(new))
    print(f"patch-pdf-thumbs: rewrote {label} at offset {at}")

with open(path, "wb") as fh:
    fh.write(bytes(blob))
