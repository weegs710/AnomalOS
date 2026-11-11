"""Add terminal-safe arrow, comparison, pipe and bind ligatures to a monospace TTF, built from its own glyphs."""

import sys

from fontTools.feaLib.builder import addOpenTypeFeaturesFromString
from fontTools.pens.areaPen import AreaPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import DecomposingRecordingPen, RecordingPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
from fontTools.ttLib.removeOverlaps import removeOverlaps

src, dst = sys.argv[1], sys.argv[2]
font = TTFont(src)
glyphs = font.getGlyphSet()
adv = font["hmtx"]["greater"][0]


def flat(name):
    rec = DecomposingRecordingPen(glyphs)
    glyphs[name].draw(rec)
    return rec


def bounds(name):
    bp = BoundsPen(glyphs)
    glyphs[name].draw(bp)
    return bp.bounds


def contour_bounds(name):
    out, cur = [], RecordingPen()
    for op, args in flat(name).value:
        cur.value.append((op, args))
        if op in ("closePath", "endPath"):
            bp = BoundsPen(None)
            cur.replay(bp)
            out.append(bp.bounds)
            cur = RecordingPen()
    return out


gx0, gy0, gx1, gy1 = bounds("greater")
mid = (gy0 + gy1) / 2
_, hy0, _, hy1 = bounds("hyphen")
hstroke = hy1 - hy0
_, _, _, ey1 = bounds("equal")
ebar = min(b[3] - b[1] for b in contour_bounds("equal"))
# x of the chevron's outer edge at the height of an equal bar, so fat shafts stop inside the arms
arm_slope = (gx1 - gx0) / (gy1 - mid)
fat_end = gx0 + (gy1 - (ey1 - ebar / 2)) * arm_slope + ebar


def place(pen, name, dx=0.0, dy=0.0, sx=1.0, sy=1.0):
    flat(name).replay(TransformPen(pen, (sx, 0, 0, sy, dx, dy)))


def shaft(pen, kind, left, right):
    x0, y0, x1, y1 = bounds(kind)
    sx = (right - left) / (x1 - x0)
    place(pen, kind, left - x0 * sx, mid - (y0 + y1) / 2, sx)


def arrow(kind, n, lhead, rhead):
    def draw(pen):
        last = (n - 1) * adv
        if kind == "hyphen":
            left = gx0 + hstroke if lhead else gx0
            right = last + gx1 - hstroke if rhead else last + gx1
        else:
            left = adv - fat_end if lhead else gx0
            right = last + fat_end if rhead else last + gx1
        shaft(pen, kind, left, right)
        if lhead:
            place(pen, "less")
        if rhead:
            place(pen, "greater", last)

    return draw


def centred(name):
    def draw(pen):
        place(pen, name, adv / 2)

    return draw


def pipe(head):
    # a stroke across the chevron's open side, ending at its own arm tips so italics keep their slant, makes a triangle
    pts = [pt for op, args in flat(head).value for pt in args if pt is not None]
    top_y, bot_y = max(p[1] for p in pts), min(p[1] for p in pts)
    band = (top_y - bot_y) * 0.15
    pick = min if head == "greater" else max
    top = pick((p for p in pts if p[1] >= top_y - band), key=lambda p: p[0])
    bot = pick((p for p in pts if p[1] <= bot_y + band), key=lambda p: p[0])
    # stroke thickness at the bar's foot, since an italic bar's bounding box is far wider than the stroke
    bar_pts = [pt for op, args in flat("bar").value for pt in args if pt is not None]
    foot = min(p[1] for p in bar_pts)
    foot_x = [p[0] for p in bar_pts if p[1] == foot]
    w = max(foot_x) - min(foot_x)
    w = w if head == "greater" else -w
    area = AreaPen(glyphs)
    glyphs[head].draw(area)
    dx = adv - (bounds(head)[0] + bounds(head)[2]) / 2

    def draw(pen):
        place(pen, head, dx)
        quad = [(top[0], top[1]), (top[0] + w, top[1]), (bot[0] + w, bot[1]), (bot[0], bot[1])]
        probe = AreaPen()
        probe.moveTo(quad[0])
        for p in quad[1:]:
            probe.lineTo(p)
        probe.closePath()
        # match the chevron's winding so the union fills the overlap instead of cutting a hole
        if (probe.value > 0) != (area.value > 0):
            quad.reverse()
        pen.moveTo((quad[0][0] + dx, quad[0][1]))
        for x, y in quad[1:]:
            pen.lineTo((x + dx, y))
        pen.closePath()

    return draw


def bind(chev, equal_first):
    # Space Mono's chevrons are wide and shallow, so any overlap nests them; they are only pulled closer
    gap = (adv - (gx1 - gx0)) / 4
    step = (gx1 - gx0) + gap

    def draw(pen):
        if equal_first:
            second = 2 * adv
            first = second - step
            shaft(pen, "equal", gx0, first + gx0 - gap)
            place(pen, chev, first)
            place(pen, chev, second)
        else:
            place(pen, chev, 0)
            place(pen, chev, step)
            shaft(pen, "equal", step + gx1 + gap, 2 * adv + gx1)

    return draw


# longest first: each lookup consumes its characters before a shorter one can see them
LIGS = [
    ("less_hyphen_hyphen_greater.liga", "less hyphen hyphen greater", arrow("hyphen", 4, True, True)),
    ("less_equal_equal_greater.liga", "less equal equal greater", arrow("equal", 4, True, True)),
    ("less_hyphen_greater.liga", "less hyphen greater", arrow("hyphen", 3, True, True)),
    ("less_equal_greater.liga", "less equal greater", arrow("equal", 3, True, True)),
    ("hyphen_hyphen_greater.liga", "hyphen hyphen greater", arrow("hyphen", 3, False, True)),
    ("less_hyphen_hyphen.liga", "less hyphen hyphen", arrow("hyphen", 3, True, False)),
    ("equal_equal_greater.liga", "equal equal greater", arrow("equal", 3, False, True)),
    ("less_equal_equal.liga", "less equal equal", arrow("equal", 3, True, False)),
    ("greater_greater_equal.liga", "greater greater equal", bind("greater", False)),
    ("equal_less_less.liga", "equal less less", bind("less", True)),
    ("hyphen_greater.liga", "hyphen greater", arrow("hyphen", 2, False, True)),
    ("less_hyphen.liga", "less hyphen", arrow("hyphen", 2, True, False)),
    ("equal_greater.liga", "equal greater", arrow("equal", 2, False, True)),
    ("less_equal.liga", "less equal", centred("lessequal")),
    ("greater_equal.liga", "greater equal", centred("greaterequal")),
    ("bar_greater.liga", "bar greater", pipe("greater")),
    ("less_bar.liga", "less bar", pipe("less")),
]

order = font.getGlyphOrder()
new_glyphs = {}
for name, seq, draw in LIGS:
    n = len(seq.split())
    pen = TTGlyphPen(None)
    # the glyph sits in the last cell and reaches back over spacer glyphs, so the run keeps its cell count
    draw(TransformPen(pen, (1, 0, 0, 1, -(n - 1) * adv, 0)))
    new_glyphs[name] = pen.glyph()
    for i in range(n - 1):
        new_glyphs[f"{name}.spc{i}"] = TTGlyphPen(None).glyph()

order = order + list(new_glyphs)
font.setGlyphOrder(order)
font["glyf"].glyphOrder = order
for name, g in new_glyphs.items():
    font["glyf"][name] = g
    g.recalcBounds(font["glyf"])
    font["hmtx"][name] = (adv, getattr(g, "xMin", 0))
removeOverlaps(font, [name for name, _, _ in LIGS])

fea = ["@ctx = [hyphen equal less greater bar];"]
for name, seq, _ in LIGS:
    chars = seq.split()
    n = len(chars)
    # a longer run of the same operator characters stays plain, so `--->` or `<<-` never half-ligates
    rules = [
        f"  ignore sub @ctx {chars[0]}' {' '.join(chars[1:])};",
        f"  ignore sub {chars[0]}' {' '.join(chars[1:])} @ctx;",
        f"  sub {chars[0]}' {' '.join(chars[1:])} by {name}.spc0;",
    ]
    for i in range(1, n):
        back = " ".join(f"{name}.spc{j}" for j in range(i))
        ahead = " ".join(chars[i + 1 :])
        target = f"{name}.spc{i}" if i < n - 1 else name
        rules.append(f"  sub {back} {chars[i]}' {ahead} by {target};".replace("  ;", ";"))
    tag = name.replace(".", "_")
    fea.append(f"lookup {tag} {{\n" + "\n".join(rules) + f"\n}} {tag};")
fea.append("feature calt {\n" + "\n".join(f"  lookup {n.replace('.', '_')};" for n, _, _ in LIGS) + "\n} calt;")

gsub = font["GSUB"].table
before = sorted(fr.FeatureTag for fr in gsub.FeatureList.FeatureRecord)

# feaLib replaces GSUB wholesale, so the new lookups are built on a scratch copy and spliced into the real table
scratch = TTFont()
scratch.setGlyphOrder(order)
addOpenTypeFeaturesFromString(scratch, "\n".join(fea))
new = scratch["GSUB"].table
base = len(gsub.LookupList.Lookup)
gsub.LookupList.Lookup.extend(new.LookupList.Lookup)
gsub.LookupList.LookupCount = len(gsub.LookupList.Lookup)
for lookup in new.LookupList.Lookup:
    for st in lookup.SubTable:
        for rec in getattr(st, "SubstLookupRecord", None) or []:
            rec.LookupListIndex += base
        for rs in getattr(st, "ChainSubRuleSet", None) or []:
            for rule in rs.ChainSubRule if rs else []:
                for rec in rule.SubstLookupRecord:
                    rec.LookupListIndex += base
        for rs in getattr(st, "ChainSubClassSet", None) or []:
            for rule in rs.ChainSubClassRule if rs else []:
                for rec in rule.SubstLookupRecord:
                    rec.LookupListIndex += base

calt = new.FeatureList.FeatureRecord[0]
calt.Feature.LookupListIndex = [i + base for i in calt.Feature.LookupListIndex]
records = gsub.FeatureList.FeatureRecord
existing = [fr for fr in records if fr.FeatureTag == "calt"]
if existing:
    existing[0].Feature.LookupListIndex += calt.Feature.LookupListIndex
else:
    old_index = {id(fr): i for i, fr in enumerate(records)}
    records.append(calt)
    records.sort(key=lambda fr: fr.FeatureTag)
    remap = {old_index[id(fr)]: i for i, fr in enumerate(records) if id(fr) in old_index}
    calt_index = records.index(calt)
    gsub.FeatureList.FeatureCount = len(records)
    for script in gsub.ScriptList.ScriptRecord:
        for ls in [script.Script.DefaultLangSys] + [r.LangSys for r in script.Script.LangSysRecord]:
            if ls is None:
                continue
            ls.FeatureIndex = sorted([remap[i] for i in ls.FeatureIndex] + [calt_index])
            ls.FeatureCount = len(ls.FeatureIndex)

after = sorted(fr.FeatureTag for fr in records)
assert set(before) <= set(after), (before, after)
font.save(dst)
