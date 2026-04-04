"""
Generates high-resolution bubble PNGs with transparent background.
Outputs to assets/bubbles/png/ folder.
"""

import os
import math
import numpy as np
from PIL import Image

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "png")
os.makedirs(OUTPUT_DIR, exist_ok=True)

SIZE = 256          # canvas size in pixels
RADIUS = 0.42       # bubble radius as fraction of SIZE

BUBBLES = [
    { "name": "red",    "hex": "#ff6b6b", "light": "#ffb3b3", "dark": "#c43030", "glow": "#ff6b6b" },
    { "name": "yellow", "hex": "#ffd166", "light": "#fff0aa", "dark": "#c08820", "glow": "#ffd166" },
    { "name": "teal",   "hex": "#4ecdc4", "light": "#aaf4f0", "dark": "#1a9b93", "glow": "#4ecdc4" },
    { "name": "blue",   "hex": "#5dade2", "light": "#aad8f8", "dark": "#1a68ac", "glow": "#5dade2" },
    { "name": "purple", "hex": "#a78bfa", "light": "#d4c0ff", "dark": "#6030d6", "glow": "#a78bfa" },
    { "name": "green",  "hex": "#95e06c", "light": "#c8f8a0", "dark": "#3ea030", "glow": "#95e06c" },
]


def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def lerp_color(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def radial_gradient_value(dx, dy, grad_cx, grad_cy, focal_r, outer_r):
    """Returns t in [0,1] for a radial gradient (focal → outer)."""
    dist = math.sqrt((dx - grad_cx) ** 2 + (dy - grad_cy) ** 2)
    if outer_r <= focal_r:
        return 1.0
    return clamp((dist - focal_r) / (outer_r - focal_r))


def draw_bubble(size: int, color: dict) -> Image.Image:
    s = size
    r = size * RADIUS          # bubble radius in pixels
    cx = cy = s / 2.0          # center

    light = hex_to_rgb(color["light"])
    mid   = hex_to_rgb(color["hex"])
    dark  = hex_to_rgb(color["dark"])
    glow  = hex_to_rgb(color["glow"])

    # Output RGBA array
    img_arr = np.zeros((s, s, 4), dtype=np.float32)

    # Pre-compute grid
    ys, xs = np.mgrid[0:s, 0:s]
    dx = xs - cx
    dy = ys - cy
    dist = np.sqrt(dx * dx + dy * dy)

    # ── Outer glow (soft halo) ──
    glow_r_inner = r * 0.55
    glow_r_outer = r * 1.38
    glow_mask = (dist <= glow_r_outer) & (dist > glow_r_inner)
    glow_t = np.clip((dist - glow_r_inner) / (glow_r_outer - glow_r_inner), 0.0, 1.0)
    glow_alpha = (1.0 - glow_t) * 0.32
    for ch in range(3):
        img_arr[:, :, ch] = np.where(glow_mask, glow[ch] / 255.0 * glow_alpha, 0.0)
    img_arr[:, :, 3] = np.where(glow_mask, glow_alpha, 0.0)

    # ── Bubble body (radial gradient) ──
    body_mask = dist <= r
    # Gradient focal: top-left of bubble
    focal_cx = -r * 0.26
    focal_cy = -r * 0.28
    focal_r  = r * 0.04
    body_t   = np.zeros((s, s), dtype=np.float32)
    dist_from_focal = np.sqrt((dx - focal_cx) ** 2 + (dy - focal_cy) ** 2)
    body_t = np.clip((dist_from_focal - focal_r) / (r * 1.05 - focal_r), 0.0, 1.0)

    # Three-stop gradient: light → mid → dark
    t2 = body_t
    stop1 = 0.42
    # t < stop1: lerp light→mid
    phase1 = np.clip(t2 / stop1, 0.0, 1.0)
    # t >= stop1: lerp mid→dark
    phase2 = np.clip((t2 - stop1) / (1.0 - stop1), 0.0, 1.0)
    use_phase2 = t2 >= stop1

    body_rgb = np.zeros((s, s, 3), dtype=np.float32)
    for ch in range(3):
        c1 = np.where(use_phase2,
                      mid[ch] / 255.0 + (dark[ch] / 255.0 - mid[ch] / 255.0) * phase2,
                      light[ch] / 255.0 + (mid[ch] / 255.0 - light[ch] / 255.0) * phase1)
        body_rgb[:, :, ch] = c1

    # Inner rim shadow (darken near edge)
    rim_start = 0.72
    rim_t = np.clip((dist / r - rim_start) / (1.0 - rim_start), 0.0, 1.0)
    rim_darken = rim_t * 0.26

    for ch in range(3):
        body_rgb[:, :, ch] = np.clip(body_rgb[:, :, ch] - rim_darken, 0.0, 1.0)

    # Composite body over glow
    body_m = body_mask.astype(np.float32)
    for ch in range(3):
        img_arr[:, :, ch] = np.where(body_mask, body_rgb[:, :, ch], img_arr[:, :, ch])
    img_arr[:, :, 3] = np.where(body_mask, 1.0, img_arr[:, :, 3])

    # ── Specular highlight (top-left ellipse, rotated) ──
    angle = -0.52
    cos_a = math.cos(-angle)
    sin_a = math.sin(-angle)
    spec_cx = cx - r * 0.26
    spec_cy = cy - r * 0.26
    rx_spec = r * 0.44
    ry_spec = r * 0.44 * 0.65
    # Rotate dx/dy into ellipse space
    lx = (xs - spec_cx) * cos_a - (ys - spec_cy) * sin_a
    ly = (xs - spec_cx) * sin_a + (ys - spec_cy) * cos_a
    ellipse_d = np.sqrt((lx / rx_spec) ** 2 + (ly / ry_spec) ** 2)
    spec_alpha = np.clip(1.0 - ellipse_d, 0.0, 1.0) ** 1.2 * 0.72
    # Apply specular only inside bubble
    spec_mask = body_mask & (ellipse_d < 1.0)
    for ch in range(3):
        cur = img_arr[:, :, ch]
        img_arr[:, :, ch] = np.where(spec_mask,
            cur + (1.0 - cur) * spec_alpha,
            cur)

    # ── Small secondary specular dot ──
    dot_cx = cx - r * 0.42
    dot_cy = cy - r * 0.40
    dot_r  = r * 0.12
    dot_dist = np.sqrt((xs - dot_cx) ** 2 + (ys - dot_cy) ** 2)
    dot_alpha = np.clip(1.0 - dot_dist / dot_r, 0.0, 1.0) ** 1.5 * 0.9
    dot_mask = body_mask & (dot_dist < dot_r)
    for ch in range(3):
        cur = img_arr[:, :, ch]
        img_arr[:, :, ch] = np.where(dot_mask,
            cur + (1.0 - cur) * dot_alpha,
            cur)

    # ── Bottom rim light ──
    rim_cx = cx + r * 0.08
    rim_cy = cy + r * 0.52
    rim_rx = r * 0.48
    rim_ry = r * 0.48 * 0.38
    rim_lx = xs - rim_cx
    rim_ly = ys - rim_cy
    rim_ed = np.sqrt((rim_lx / rim_rx) ** 2 + (rim_ly / rim_ry) ** 2)
    rim_a  = np.clip(1.0 - rim_ed, 0.0, 1.0) * 0.18
    rim_mask = body_mask & (rim_ed < 1.0)
    for ch in range(3):
        cur = img_arr[:, :, ch]
        img_arr[:, :, ch] = np.where(rim_mask,
            cur + (1.0 - cur) * rim_a,
            cur)

    # Clip and convert
    img_arr = np.clip(img_arr, 0.0, 1.0)
    img_uint8 = (img_arr * 255).astype(np.uint8)
    return Image.fromarray(img_uint8, mode="RGBA")


SIZES = [64, 128, 256, 512]

total = 0
for color in BUBBLES:
    for size in SIZES:
        img = draw_bubble(size, color)
        filename = f"bubble_{color['name']}_{size}px.png"
        filepath = os.path.join(OUTPUT_DIR, filename)
        img.save(filepath, "PNG")
        print(f"  ✓  {filename}")
        total += 1

print(f"\nDone — {total} PNGs saved to assets/bubbles/png/")
