#!/usr/bin/env python3
"""Bold single-emblem app icon for Cờ Cá Ngựa: a lacquered gold medallion
(coin-like, not a boxy plaque) bearing a two-tone, rim-lit red horse-head
silhouette ("ngựa"), tilted, on a rich royal-blue gradient background.
One dominant accent color (blue) rather than cramming all 4 player colors
into the icon — matches the house single-emblem style (SamLoc's tilted
"2♥" card, Fanorona's tilted board tile) — but this pass adds real
gradients/shadows/highlights so it reads as a dimensional lacquered game
token rather than a flat two-tone badge."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

APP_DIR = Path(__file__).resolve().parent
SIZE = 1024
SS = 3  # supersample factor for smooth edges/gradients
S = SIZE * SS


def lerp(a, b, t):
    return a + (b - a) * t


def diag_gradient(size, c0, c1, angle_deg=45):
    """Directional gradient (c0 at the 'start' corner, c1 at the opposite
    corner) rendered via PIL's built-in linear_gradient + rotate, which is
    fast (C-level) and avoids a slow per-pixel Python loop."""
    base = Image.new("L", (256, 256))
    for x in range(256):
        base.paste(x, (x, 0, x + 1, 256))
    base = base.resize((size * 2, size * 2))
    base = base.rotate(angle_deg, resample=Image.BICUBIC, expand=False)
    w, h = base.size
    base = base.crop(((w - size) // 2, (h - size) // 2, (w + size) // 2, (h + size) // 2))
    grad = Image.new("RGB", (size, size))
    px = base.load()
    lut_r = [int(lerp(c0[0], c1[0], i / 255)) for i in range(256)]
    lut_g = [int(lerp(c0[1], c1[1], i / 255)) for i in range(256)]
    lut_b = [int(lerp(c0[2], c1[2], i / 255)) for i in range(256)]
    out = Image.merge("RGB", [
        base.point(lambda v: lut_r[v]),
        base.point(lambda v: lut_g[v]),
        base.point(lambda v: lut_b[v]),
    ])
    return out


def diag_gradient_L(size, v0, v1, angle_deg=45):
    """Single-channel directional gradient, v0 at the 'start' corner fading
    to v1 at the opposite corner. Used as a directional multiply-mask."""
    base = Image.new("L", (256, 256))
    for x in range(256):
        base.paste(x, (x, 0, x + 1, 256))
    base = base.resize((size * 2, size * 2))
    base = base.rotate(angle_deg, resample=Image.BICUBIC, expand=False)
    w, h = base.size
    base = base.crop(((w - size) // 2, (h - size) // 2, (w + size) // 2, (h + size) // 2))
    lut = [int(lerp(v0, v1, i / 255)) for i in range(256)]
    return base.point(lambda v: lut[v])


def radial_gradient(size, c0, c1, center=(0.5, 0.5), radius_frac=0.75):
    """Radial gradient c0 (center) -> c1 (edge)."""
    cx, cy = center[0] * size, center[1] * size
    maxr = radius_frac * size
    grad = Image.new("L", (size, size))
    # Build once at low res for speed, then upscale.
    lowres = 256
    small = Image.new("L", (lowres, lowres))
    spx = small.load()
    scx, scy = center[0] * lowres, center[1] * lowres
    smaxr = radius_frac * lowres
    for y in range(lowres):
        for x in range(lowres):
            d = math.hypot(x - scx, y - scy) / smaxr
            spx[x, y] = max(0, min(255, int(d * 255)))
    grad = small.resize((size, size), resample=Image.BICUBIC)
    lut_r = [int(lerp(c0[0], c1[0], i / 255)) for i in range(256)]
    lut_g = [int(lerp(c0[1], c1[1], i / 255)) for i in range(256)]
    lut_b = [int(lerp(c0[2], c1[2], i / 255)) for i in range(256)]
    out = Image.merge("RGB", [
        grad.point(lambda v: lut_r[v]),
        grad.point(lambda v: lut_g[v]),
        grad.point(lambda v: lut_b[v]),
    ])
    return out


# ---------------------------------------------------------------------------
# Background: rich royal-blue radial + vertical gradient, near-black at the
# corners so the gold medallion pops.
# ---------------------------------------------------------------------------
bg_radial = radial_gradient(S, (44, 92, 196), (8, 16, 46), center=(0.42, 0.36), radius_frac=0.95)
bg_linear = diag_gradient(S, (30, 64, 148), (5, 10, 30), angle_deg=90)
img = Image.blend(bg_linear, bg_radial, 0.55).convert("RGB")

# ---------------------------------------------------------------------------
# Medallion (coin/token), NOT a rounded rectangle: a circular disc with a
# raised bezel ring, so it reads as a deliberately-designed game piece
# rather than a generic app-icon "badge button."
# ---------------------------------------------------------------------------
cx, cy = S / 2, S / 2
outer_r = S * 0.40   # outer bezel edge
inner_r = S * 0.355  # inner face edge (where the gold face gradient sits)

# --- drop shadow (soft, offset down-right, lifts the medallion off the bg) ---
shadow_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
sdraw = ImageDraw.Draw(shadow_layer)
shadow_offset = S * 0.028
sdraw.ellipse(
    [cx - outer_r + shadow_offset, cy - outer_r + shadow_offset * 1.4,
     cx + outer_r + shadow_offset, cy + outer_r + shadow_offset * 1.4],
    fill=(0, 0, 0, 170),
)
shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(S * 0.02))
img.paste(Image.alpha_composite(img.convert("RGBA"), shadow_layer).convert("RGB"), (0, 0))

# --- outer bezel ring: darker bronze-gold, gives the coin a raised edge ---
medallion = Image.new("RGBA", (S, S), (0, 0, 0, 0))
mdraw = ImageDraw.Draw(medallion)
bezel_grad = diag_gradient(S, (255, 220, 140), (120, 78, 18), angle_deg=48)
bezel_mask = Image.new("L", (S, S), 0)
bmdraw = ImageDraw.Draw(bezel_mask)
bmdraw.ellipse([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r], fill=255)
medallion.paste(bezel_grad, (0, 0), bezel_mask)

# --- inner face: lacquered gold radial gradient, light upper-left -> deep
# amber/bronze lower-right, like an enameled game token catching light ---
face_grad = radial_gradient(S, (255, 236, 176), (168, 108, 26), center=(0.36, 0.30), radius_frac=0.62)
face_mask = Image.new("L", (S, S), 0)
fmdraw = ImageDraw.Draw(face_mask)
fmdraw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r], fill=255)
face_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
face_layer.paste(face_grad, (0, 0), face_mask)
medallion = Image.alpha_composite(medallion, face_layer)

# --- thin bright specular highlight arc along the upper-left bezel rim
# (sells the "polished metal" read). Sized to sit *inside* the bezel ring
# and additionally clamped to the outer disc so it can never spill onto
# the background outside the coin. ---
highlight_layer = Image.new("L", (S, S), 0)
hdraw = ImageDraw.Draw(highlight_layer)
ring_w = outer_r - inner_r
hr = outer_r - ring_w * 0.5
hw = ring_w * 0.32
hdraw.arc([cx - hr - hw, cy - hr - hw, cx + hr + hw, cy + hr + hw], start=200, end=290,
          fill=255, width=int(ring_w * 0.7))
highlight_layer = highlight_layer.filter(ImageFilter.GaussianBlur(S * 0.006))
highlight_layer = ImageChops.multiply(highlight_layer, bezel_mask)
white_layer = Image.new("RGBA", (S, S), (255, 250, 230, 0))
white_layer.putalpha(highlight_layer.point(lambda v: int(v * 0.85)))
medallion = Image.alpha_composite(medallion, white_layer)

# --- subtle inner shadow along the lower-right rim (opposite the
# highlight) to reinforce the light-from-upper-left read; same clamp. ---
inner_shadow_layer = Image.new("L", (S, S), 0)
isdraw = ImageDraw.Draw(inner_shadow_layer)
isdraw.arc([cx - hr - hw, cy - hr - hw, cx + hr + hw, cy + hr + hw], start=20, end=110,
           fill=255, width=int(ring_w * 0.8))
inner_shadow_layer = inner_shadow_layer.filter(ImageFilter.GaussianBlur(S * 0.008))
inner_shadow_layer = ImageChops.multiply(inner_shadow_layer, bezel_mask)
dark_layer = Image.new("RGBA", (S, S), (40, 20, 4, 0))
dark_layer.putalpha(inner_shadow_layer.point(lambda v: int(v * 0.55)))
medallion = Image.alpha_composite(medallion, dark_layer)

# ---------------------------------------------------------------------------
# Horse-head silhouette (Apple Symbols "♞" BLACK CHESS KNIGHT — a clean
# filled shape at icon scale), rendered with a two-tone deep-red gradient
# fill plus a thin rim-light on the upper-left edge, so it reads as a lit
# 3D form rather than a flat silhouette.
# ---------------------------------------------------------------------------
font = ImageFont.truetype("/System/Library/Fonts/Apple Symbols.ttf", int(S * 0.60))
ch = "♞"  # BLACK CHESS KNIGHT
tmp = Image.new("L", (S, S), 0)
tdraw = ImageDraw.Draw(tmp)
bbox = tdraw.textbbox((0, 0), ch, font=font)
w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
gx = cx - w / 2 - bbox[0]
gy = cy - h / 2 - bbox[1] - S * 0.015
tdraw.text((gx, gy), ch, font=font, fill=255)
glyph_mask = tmp

# Two-tone red gradient fill: lighter warm red upper-left -> deep garnet
# lower-right, giving the silhouette real volume instead of one flat hue.
red_grad = diag_gradient(S, (224, 78, 64), (110, 16, 22), angle_deg=48)
horse_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
horse_layer.paste(red_grad, (0, 0), glyph_mask)

# Rim-light: take the glyph mask, shift it down-right slightly, subtract
# from the original to isolate a thin sliver all around the silhouette's
# edge, then multiply that sliver by a directional (upper-left -> zero at
# lower-right) mask so only the light-facing edges actually glow — a full
# outline reads as a flat sticker/decal, a one-sided glow reads as a lit
# 3D form.
shift = int(S * 0.006)
shifted = ImageChops.offset(glyph_mask, shift, shift)
rim_mask = ImageChops.subtract(glyph_mask, shifted)
rim_mask = rim_mask.filter(ImageFilter.GaussianBlur(S * 0.0015))
rim_dir_mask = diag_gradient_L(S, 255, 0, angle_deg=48)
rim_mask = ImageChops.multiply(rim_mask, rim_dir_mask)
rim_layer = Image.new("RGBA", (S, S), (255, 214, 150, 0))
rim_layer.putalpha(rim_mask.point(lambda v: int(min(255, v * 2.2))))
horse_layer = Image.alpha_composite(horse_layer, rim_layer)

# Soft contact shadow under the horse head so it visibly sits above the
# gold face rather than being painted flush onto it.
horse_shadow = Image.new("L", (S, S), 0)
hsdraw = ImageDraw.Draw(horse_shadow)
hsoff = S * 0.010
hs_glyph = ImageChops.offset(glyph_mask, int(hsoff), int(hsoff * 1.6))
horse_shadow = hs_glyph.filter(ImageFilter.GaussianBlur(S * 0.010))
horse_shadow_layer = Image.new("RGBA", (S, S), (30, 12, 4, 0))
horse_shadow_layer.putalpha(horse_shadow.point(lambda v: int(v * 0.55)))

medallion = Image.alpha_composite(medallion, horse_shadow_layer)
medallion = Image.alpha_composite(medallion, horse_layer)

# ---------------------------------------------------------------------------
# Tilt the whole medallion, composite onto the background, downsample.
# ---------------------------------------------------------------------------
rotated = medallion.rotate(-7, resample=Image.BICUBIC, expand=False, center=(cx, cy))
img = Image.alpha_composite(img.convert("RGBA"), rotated).convert("RGB")
img = img.resize((SIZE, SIZE), resample=Image.LANCZOS)

out = APP_DIR / "CoCaNgua/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
img.save(out)
print("wrote", out, img.size)
