"""thunk's edit tools: pixel work that never asks the model to imagine anything."""

from __future__ import annotations

import base64
import io
import subprocess
from typing import Any

import cv2
import numpy as np
from numpy.typing import NDArray
from PIL import Image, ImageDraw, ImageFilter, ImageFont

Img = NDArray[np.uint8]


def load(png: bytes) -> Img:
    """RGBA uint8, whatever came in."""
    return np.array(Image.open(io.BytesIO(png)).convert("RGBA"))


def save(a: Img) -> bytes:
    buf = io.BytesIO()
    mode = "RGBA" if a.shape[2] == 4 and (a[:, :, 3] < 255).any() else "RGB"
    Image.fromarray(a[:, :, :4] if mode == "RGBA" else a[:, :, :3]).save(buf, "PNG")
    return buf.getvalue()


def circles_mask(h: int, w: int, marks: list[dict[str, Any]], grow: float = 1.0) -> Img:
    m = np.zeros((h, w), np.uint8)
    for k in marks:
        cx, cy, r = int(k["x"] * w), int(k["y"] * h), max(2, int(k["r"] * w * grow))
        cv2.circle(m, (cx, cy), r, 255, -1)
    return m


def cutout(png: bytes, tolerance: float, clear_marks: list[dict[str, Any]]) -> bytes:
    """Background = what connects to the corners within `tolerance` of their colour."""
    a = load(png)
    h, w = a.shape[:2]
    rgb = np.ascontiguousarray(a[:, :, :3])
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB).astype(np.float32)
    bg = np.zeros((h, w), np.uint8)
    for cy, cx in ((0, 0), (0, w - 1), (h - 1, 0), (h - 1, w - 1)):
        close = (np.linalg.norm(lab - lab[cy, cx], axis=2) <= tolerance).astype(
            np.uint8
        )
        n, lbl = cv2.connectedComponents(close, connectivity=4)
        if n > 1 and close[cy, cx]:
            bg[lbl == lbl[cy, cx]] = 255
    if clear_marks:
        bg = np.maximum(bg, circles_mask(h, w, clear_marks))
    alpha = 255 - bg
    # one soft pixel at the edge so the cut does not stair-step
    alpha = cv2.GaussianBlur(alpha, (3, 3), 0.8)
    out = a.copy()
    out[:, :, 3] = np.minimum(a[:, :, 3], alpha)
    return save(out)


def fill_spots(png: bytes, marks: list[dict[str, Any]]) -> bytes:
    """Fill the marked circles from the pixels around them (TELEA), no model."""
    a = load(png)
    h, w = a.shape[:2]
    mask = circles_mask(h, w, marks)
    rgb = cv2.inpaint(np.ascontiguousarray(a[:, :, :3]), mask, 6, cv2.INPAINT_TELEA)
    out = a.copy()
    out[:, :, :3] = rgb
    return save(out)


def spots_mask_png(w: int, h: int, marks: list[dict[str, Any]]) -> bytes:
    """White = redraw, black = keep, one channel, for sd-server's mask_image."""
    buf = io.BytesIO()
    Image.fromarray(circles_mask(h, w, marks, grow=1.15)).save(buf, "PNG")
    return buf.getvalue()


def swap(
    base_png: bytes, donor_png: bytes, src: dict[str, float], dst: dict[str, float]
) -> tuple[bytes, dict[str, int | float]]:
    """A feathered circle from the donor onto the base, plus proof of what changed."""
    base = load(base_png)
    donor = load(donor_png)
    bh, bw = base.shape[:2]
    if donor.shape[:2] != (bh, bw):
        donor = np.array(
            Image.fromarray(donor).resize((bw, bh), Image.Resampling.LANCZOS)
        )
    r = max(4, int(src["r"] * bw))
    sx, sy = int(src["x"] * bw), int(src["y"] * bh)
    dx, dy = int(dst["x"] * bw), int(dst["y"] * bh)
    alpha = np.zeros((bh, bw), np.float32)
    cv2.circle(alpha, (dx, dy), r, 1.0, -1)
    feather = max(3, r // 6) | 1
    alpha = cv2.GaussianBlur(alpha, (feather * 2 + 1, feather * 2 + 1), feather / 2)
    shift = np.array([[1, 0, dx - sx], [0, 1, dy - sy]], dtype=np.float32)
    moved = cv2.warpAffine(donor, shift, (bw, bh), borderMode=cv2.BORDER_REPLICATE)
    out = (
        base.astype(np.float32) * (1 - alpha[..., None])
        + moved.astype(np.float32) * alpha[..., None]
    )
    out = np.clip(out + 0.5, 0, 255).astype(np.uint8)
    diff = np.abs(out.astype(np.int16) - base.astype(np.int16)).max(axis=2) > 0
    changed = int(diff.sum())
    grown = cv2.dilate(diff.astype(np.uint8), np.ones((15, 15), np.uint8))
    regions = cv2.connectedComponents(grown)[0] - 1
    outside = diff & (
        cv2.dilate((alpha > 0).astype(np.uint8), np.ones((3, 3), np.uint8)) == 0
    )
    proof = {
        "changed_px": changed,
        "percent": round(100 * changed / (bh * bw), 3),
        "regions": int(regions),
        "outside_px": int(outside.sum()),
    }
    return save(out), proof


def fonts() -> list[dict[str, str]]:
    r = subprocess.run(
        ["fc-list", ":style=Regular", "family", "file"],
        capture_output=True,
        text=True,
        check=False,
    )
    seen: dict[str, str] = {}
    for line in r.stdout.splitlines():
        path, _, fam = line.partition(": ")
        fam = fam.split(",")[0].strip()
        if fam and fam not in seen and path.lower().endswith((".ttf", ".otf")):
            seen[fam] = path
    return [{"family": f, "file": p} for f, p in sorted(seen.items())]


def hex_rgba(h: str, alpha: int = 255) -> tuple[int, int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def text(png: bytes, p: dict[str, Any]) -> bytes:
    """Burn lettering in: font, size, fill, outline, glow, centred on (x, y)."""
    base = Image.open(io.BytesIO(png)).convert("RGBA")
    w, h = base.size
    size = max(8, int(float(p["size"]) * h))
    font = ImageFont.truetype(p["font"], size)
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    xy = (float(p["x"]) * w, float(p["y"]) * h)
    stroke = int(float(p.get("outline_w", 0)) * size)
    kw: dict[str, Any] = {"font": font, "anchor": "mm", "align": "center"}
    if float(p.get("glow", 0)) > 0:
        g = Image.new("RGBA", base.size, (0, 0, 0, 0))
        ImageDraw.Draw(g).multiline_text(
            xy,
            p["text"],
            fill=hex_rgba(p.get("glow_color", "#ffffff")),
            stroke_width=stroke + max(1, size // 12),
            stroke_fill=hex_rgba(p.get("glow_color", "#ffffff")),
            **kw,
        )
        g = g.filter(ImageFilter.GaussianBlur(float(p["glow"]) * size))
        base = Image.alpha_composite(base, g)
    d.multiline_text(
        xy,
        p["text"],
        fill=hex_rgba(p.get("color", "#ffffff")),
        stroke_width=stroke,
        stroke_fill=hex_rgba(p.get("outline", "#000000")),
        **kw,
    )
    out = Image.alpha_composite(base, layer)
    buf = io.BytesIO()
    out.convert("RGB" if png_is_opaque(out) else "RGBA").save(buf, "PNG")
    return buf.getvalue()


def png_is_opaque(im: Image.Image) -> bool:
    lo, _ = im.getchannel("A").getextrema()
    return lo == 255


def gen_size(dev_w: int, dev_h: int, long_side: int = 1664) -> tuple[int, int]:
    """A model canvas at the device aspect, multiples of 16."""
    if dev_h >= dev_w:
        h = long_side
        w = round(long_side * dev_w / dev_h / 16) * 16
    else:
        w = long_side
        h = round(long_side * dev_h / dev_w / 16) * 16
    return int(w), int(h)


def fit_guide(png: bytes, w: int, h: int) -> bytes:
    """The original whole and centred on a blurred stretch of itself."""
    im = Image.open(io.BytesIO(png)).convert("RGB")
    iw, ih = im.size
    cover = max(w / iw, h / ih)
    bg = im.resize(
        (max(1, round(iw * cover)), max(1, round(ih * cover))), Image.Resampling.LANCZOS
    )
    left, top = (bg.width - w) // 2, (bg.height - h) // 2
    bg = bg.crop((left, top, left + w, top + h)).filter(ImageFilter.GaussianBlur(50))
    fit = min(w / iw, h / ih)
    fg = im.resize(
        (max(1, round(iw * fit)), max(1, round(ih * fit))), Image.Resampling.LANCZOS
    )
    bg.paste(fg, ((w - fg.width) // 2, (h - fg.height) // 2))
    buf = io.BytesIO()
    bg.save(buf, "PNG")
    return buf.getvalue()


def finish(png: bytes, dev_w: int, dev_h: int) -> bytes:
    """Centre crop to the device aspect, then Lanczos to the exact size."""
    im = Image.open(io.BytesIO(png)).convert("RGB")
    iw, ih = im.size
    target = dev_w / dev_h
    if iw / ih > target:
        nw = round(ih * target)
        im = im.crop(((iw - nw) // 2, 0, (iw - nw) // 2 + nw, ih))
    else:
        nh = round(iw / target)
        im = im.crop((0, (ih - nh) // 2, iw, (ih - nh) // 2 + nh))
    im = im.resize((dev_w, dev_h), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    return buf.getvalue()


def similarity(a_png: bytes, b_png: bytes, box: list[int] | None = None) -> float:
    """Grey SSIM of B against A; with a box, only where A sits inside B."""
    a = cv2.cvtColor(load(a_png)[:, :, :3], cv2.COLOR_RGB2GRAY).astype(np.float64)
    b = load(b_png)[:, :, :3]
    if box:
        x, y, bw, bh = box
        b = np.ascontiguousarray(b[y : y + bh, x : x + bw])
    b = cv2.cvtColor(
        cv2.resize(b, (a.shape[1], a.shape[0]), interpolation=cv2.INTER_AREA),
        cv2.COLOR_RGB2GRAY,
    )
    b = b.astype(np.float64)
    c1, c2 = (0.01 * 255) ** 2, (0.03 * 255) ** 2
    mu_a, mu_b = cv2.GaussianBlur(a, (11, 11), 1.5), cv2.GaussianBlur(b, (11, 11), 1.5)
    s_a = cv2.GaussianBlur(a * a, (11, 11), 1.5) - mu_a**2
    s_b = cv2.GaussianBlur(b * b, (11, 11), 1.5) - mu_b**2
    s_ab = cv2.GaussianBlur(a * b, (11, 11), 1.5) - mu_a * mu_b
    m = ((2 * mu_a * mu_b + c1) * (2 * s_ab + c2)) / (
        (mu_a**2 + mu_b**2 + c1) * (s_a + s_b + c2)
    )
    return round(float(m.mean()), 3)


def fit_canvas(png: bytes, w: int, h: int) -> tuple[bytes, bytes, list[int]]:
    """Edge-pass init, its mask (white = draw new), and where the original sits."""
    im = Image.open(io.BytesIO(png)).convert("RGB")
    iw, ih = im.size
    fit = min(w / iw, h / ih)
    fw, fh = max(1, round(iw * fit)), max(1, round(ih * fit))
    canvas = Image.open(io.BytesIO(fit_guide(png, w, h)))
    x0, y0 = (w - fw) // 2, (h - fh) // 2
    m = np.full((h, w), 255, np.uint8)
    inset = 6
    m[y0 + inset : y0 + fh - inset, x0 + inset : x0 + fw - inset] = 0
    b1, b2 = io.BytesIO(), io.BytesIO()
    canvas.save(b1, "PNG")
    Image.fromarray(m).save(b2, "PNG")
    return b1.getvalue(), b2.getvalue(), [x0, y0, fw, fh]


def paste_spots(orig_png: bytes, new_png: bytes, marks: list[dict[str, Any]]) -> bytes:
    """New pixels inside the marked circles (feathered), the original elsewhere."""
    o = load(orig_png).astype(np.float32)
    n = load(new_png).astype(np.float32)
    h, w = o.shape[:2]
    if n.shape[:2] != (h, w):
        n = np.array(
            Image.fromarray(n.astype(np.uint8)).resize((w, h), Image.Resampling.LANCZOS)
        ).astype(np.float32)
    a = circles_mask(h, w, marks, grow=1.15).astype(np.float32) / 255
    k = max(3, int(min(h, w) * 0.01)) | 1
    a = cv2.GaussianBlur(a, (k * 2 + 1, k * 2 + 1), k / 2)[..., None]
    out = np.clip(o * (1 - a) + n * a + 0.5, 0, 255).astype(np.uint8)
    out[:, :, 3] = load(orig_png)[:, :, 3]
    return save(out)


def plain_border(png: bytes) -> tuple[int, int, int] | None:
    """The border colour when the picture's outer ring is one flat colour, else None."""
    a = load(png)[:, :, :3].astype(np.float32)
    h, w = a.shape[:2]
    k = max(2, min(h, w) // 50)
    ring = np.concatenate(
        [
            a[:k].reshape(-1, 3),
            a[-k:].reshape(-1, 3),
            a[:, :k].reshape(-1, 3),
            a[:, -k:].reshape(-1, 3),
        ]
    )
    if float(ring.std(axis=0).max()) > 6:
        return None
    m = np.median(ring, axis=0)
    return int(m[0]), int(m[1]), int(m[2])


def fit_plain(png: bytes, w: int, h: int, rgb: tuple[int, int, int]) -> bytes:
    im = Image.open(io.BytesIO(png)).convert("RGB")
    iw, ih = im.size
    fit = min(w / iw, h / ih)
    fg = im.resize(
        (max(1, round(iw * fit)), max(1, round(ih * fit))), Image.Resampling.LANCZOS
    )
    bg = Image.new("RGB", (w, h), rgb)
    bg.paste(fg, ((w - fg.width) // 2, (h - fg.height) // 2))
    buf = io.BytesIO()
    bg.save(buf, "PNG")
    return buf.getvalue()


def background_field(rgb: NDArray[np.float32]) -> NDArray[np.float32]:
    """A smooth dark-background estimate: local minimum, blurred, at 1/8 size."""
    h, w = rgb.shape[:2]
    small = cv2.resize(
        rgb, (max(8, w // 8), max(8, h // 8)), interpolation=cv2.INTER_AREA
    )
    k = max(3, min(small.shape[:2]) // 6) | 1
    low = cv2.erode(small, np.ones((k, k), np.uint8))
    low = cv2.GaussianBlur(low, (0, 0), k / 2)
    return np.asarray(
        cv2.resize(low, (w, h), interpolation=cv2.INTER_CUBIC), np.float32
    )


def cutout_dark(png: bytes, strength: float = 1.0, glow: float = 1.0) -> bytes:
    """Dark background to transparent; glow stays as see-through light."""
    a = load(png)
    rgb = a[:, :, :3].astype(np.float32)
    h, w = rgb.shape[:2]
    bg = background_field(rgb)
    diff = np.clip(rgb - bg, 0, None).max(axis=2)
    room = np.maximum(1.0, 255 - bg.max(axis=2))
    alpha = np.clip(diff / room * 1.8 * strength, 0, 1)
    alpha[alpha < 0.04] = 0
    solid = (alpha > 0.6).astype(np.uint8)
    holes = 1 - solid
    n, lbl = cv2.connectedComponents(holes, connectivity=4)
    border = set(
        np.unique(np.concatenate([lbl[0], lbl[-1], lbl[:, 0], lbl[:, -1]])).tolist()
    )
    small_hole = (h * w) * 0.02
    for c in range(1, n):
        if c in border:
            continue
        m = lbl == c
        if m.sum() < small_hole:
            alpha[m] = 1.0
    # 0 gives a hard edge that reads on light backgrounds too
    hard = cv2.GaussianBlur((alpha > 0.25).astype(np.float32), (3, 3), 0.8)
    alpha = glow * alpha + (1 - glow) * hard
    safe = np.maximum(alpha, 1e-3)[..., None]
    col = np.clip(bg + (rgb - bg) / safe, 0, 255)
    col = np.where(alpha[..., None] > 0.999, rgb, col)
    out = np.dstack([col, alpha * 255])
    return save(np.clip(out + 0.5, 0, 255).astype(np.uint8))


def icon_set(png: bytes, sizes: list[int], pad: float) -> dict[str, bytes]:
    """Trim, square with padding, then each size, resized premultiplied."""
    im = Image.open(io.BytesIO(png)).convert("RGBA")
    bbox = im.getchannel("A").point([0] * 9 + [255] * 247).getbbox() or (
        0,
        0,
        im.width,
        im.height,
    )
    im = im.crop(bbox)
    side = round(max(im.size) * (1 + 2 * pad))
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    out: dict[str, bytes] = {}
    pm = sq.convert("RGBa")
    for s in sorted(set(sizes)):
        buf = io.BytesIO()
        pm.resize((s, s), Image.Resampling.LANCZOS).convert("RGBA").save(buf, "PNG")
        out[f"icon-{s}.png"] = buf.getvalue()
    ico_sizes = [(s, s) for s in sorted(set(sizes)) if s <= 256]
    if ico_sizes:
        buf = io.BytesIO()
        sq.save(buf, "ICO", sizes=ico_sizes)
        out["icon.ico"] = buf.getvalue()
    return out


def small_jpeg(png: bytes, side: int = 640) -> str:
    """A data URL the vision rewriter can read: 640 px on the long side, JPEG."""
    im = Image.open(io.BytesIO(png)).convert("RGB")
    im.thumbnail((side, side), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=85)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()
