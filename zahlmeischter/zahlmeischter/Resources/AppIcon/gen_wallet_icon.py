#!/usr/bin/env python3
"""
Generates the zahlmeischter app icon (Konzept A, design.md V2): a papercraft coin-purse
on a single-hue violet glow (no mesh), with a teal coin cut in half sticking up out of
the centre and a violet snap. Outputs a 1024x1024 PNG into the AppIcon asset set.

Run:  python3 gen_wallet_icon.py
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 1024


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def radial_bg(size, center, inner, outer, cx=0.5, cy=0.42):
    """A soft radial glow from `inner` (centre) to `outer` (edges)."""
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    dx = (xx / size - cx)
    dy = (yy / size - cy)
    d = np.sqrt(dx * dx + dy * dy)
    t = np.clip(d / 0.72, 0, 1)
    img = np.zeros((size, size, 3), dtype=np.uint8)
    for i in range(3):
        img[..., i] = (inner[i] + (outer[i] - inner[i]) * t).astype(np.uint8)
    return Image.fromarray(img, "RGB")


def linear_fill(draw_size, top, bottom):
    """A vertical gradient tile."""
    arr = np.zeros((draw_size, draw_size, 3), dtype=np.uint8)
    for y in range(draw_size):
        arr[y, :] = lerp(top, bottom, y / max(draw_size - 1, 1))
    return Image.fromarray(arr, "RGB")


def rounded_mask(size, box, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle(box, radius=radius, fill=255)
    return m


def circle_mask(size, center, r):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.ellipse([center[0] - r, center[1] - r, center[0] + r, center[1] + r], fill=255)
    return m


def radial_disc(size, center, r, inner, outer, hx=0.36, hy=0.30):
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    dx = (xx - (center[0] - r + 2 * r * hx))
    dy = (yy - (center[1] - r + 2 * r * hy))
    d = np.sqrt(dx * dx + dy * dy)
    t = np.clip(d / (r * 1.4), 0, 1)
    img = np.zeros((size, size, 3), dtype=np.uint8)
    for i in range(3):
        img[..., i] = (inner[i] + (outer[i] - inner[i]) * t).astype(np.uint8)
    return Image.fromarray(img, "RGB")


# Palette (design.md)
VIOLET_GLOW_IN = (0x9D, 0x8C, 0xFF)
VIOLET_GLOW_OUT = (0x5B, 0x4F, 0xCB)
PURSE_TOP = (0xFE, 0xF5, 0xFB)
PURSE_BOTTOM = (0xE9, 0xC3, 0xDC)
FLAP_TOP = (0xFF, 0xFF, 0xFF)
FLAP_BOTTOM = (0xF7, 0xE6, 0xF0)
SNAP_IN = (0x9D, 0x8C, 0xFF)
SNAP_OUT = (0x6C, 0x5C, 0xE7)
COIN_IN = (0x9B, 0xED, 0xE5)
COIN_OUT = (0x33, 0xB3, 0xAA)

icon = radial_bg(S, None, VIOLET_GLOW_IN, VIOLET_GLOW_OUT).convert("RGBA")

# Geometry
body = [int(S * 0.24), int(S * 0.35), int(S * 0.76), int(S * 0.75)]   # left,top,right,bottom
body_radius = int(S * 0.075)
coin_center = (S // 2, int(S * 0.35))
coin_r = int(S * 0.16)

# Soft drop shadow under the purse
shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
sd.rounded_rectangle([body[0] + 14, body[1] + 26, body[2] + 14, body[3] + 30],
                     radius=body_radius, fill=(43, 42, 85, 120))
shadow = shadow.filter(ImageFilter.GaussianBlur(26))
icon.alpha_composite(shadow)

# Coin (behind the purse — lower half hidden)
coin_fill = radial_disc(S, coin_center, coin_r, COIN_IN, COIN_OUT).convert("RGBA")
coin_shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(coin_shadow).ellipse(
    [coin_center[0] - coin_r, coin_center[1] - coin_r + 12,
     coin_center[0] + coin_r, coin_center[1] + coin_r + 12], fill=(20, 16, 50, 90))
icon.alpha_composite(coin_shadow.filter(ImageFilter.GaussianBlur(14)))
icon.paste(coin_fill, (0, 0), circle_mask(S, coin_center, coin_r))

# Purse body
purse = linear_fill(S, PURSE_TOP, PURSE_BOTTOM).convert("RGBA")
icon.paste(purse, (0, 0), rounded_mask(S, body, body_radius))

# Flap (top third, lighter)
flap_box = [body[0], body[1], body[2], body[1] + int(S * 0.17)]
flap = linear_fill(S, FLAP_TOP, FLAP_BOTTOM).convert("RGBA")
icon.paste(flap, (0, 0), rounded_mask(S, flap_box, body_radius))

# Snap (violet)
snap_r = int(S * 0.052)
snap_center = (int(S * 0.585), int(S * 0.47))
snap = radial_disc(S, snap_center, snap_r, SNAP_IN, SNAP_OUT).convert("RGBA")
icon.paste(snap, (0, 0), circle_mask(S, snap_center, snap_r))

out_dir = os.path.dirname(os.path.abspath(__file__))
asset = os.path.normpath(os.path.join(out_dir, "..", "..", "Assets.xcassets", "AppIcon.appiconset"))
os.makedirs(asset, exist_ok=True)
icon.convert("RGB").save(os.path.join(asset, "AppIcon-1024.png"))
print("wrote", os.path.join(asset, "AppIcon-1024.png"))
