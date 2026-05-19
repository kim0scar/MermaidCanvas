#!/usr/bin/env python3
"""
v35 Flöde — app-ikon-generator.

Ritar tre stiliserade former (cirkel, fyrkant, diamant) kopplade med pilar,
bakgrund i salviagrön (#B8D4C2), former i mörk grågrön (#3C5060).

Output: 1024×1024 PNG utan alpha-kanal (Apple-krav).
"""
from PIL import Image, ImageDraw
import math
import os

SIZE = 1024
BG = (184, 212, 194)        # #B8D4C2 salviagrön
SHAPE = (60, 80, 96)         # #3C5060 mörk grågrön
ARROW = (60, 80, 96)

# Lite mjukare bakgrundsövergång — extra glow runt formerna
GLOW = (210, 226, 216)

OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "app", "MermaidCanvas", "Resources", "Assets.xcassets",
    "AppIcon.appiconset", "Icon-1024.png"
)


def main():
    # RGB (ingen alpha — Apples krav för 1024)
    img = Image.new("RGB", (SIZE, SIZE), BG)
    draw = ImageDraw.Draw(img)

    # Mjuk inre vinjett-ring (ger djup utan att förstöra plattheten)
    cx, cy = SIZE // 2, SIZE // 2
    for r in range(SIZE // 2, int(SIZE * 0.42), -1):
        t = (r - SIZE * 0.42) / (SIZE * 0.5 - SIZE * 0.42)
        # gradient bg -> svagt mörkare
        col = (
            int(BG[0] - 8 * t),
            int(BG[1] - 8 * t),
            int(BG[2] - 8 * t),
        )
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col)

    # Tre former — triangelplacering: cirkel uppe, fyrkant nere-vänster, diamant nere-höger
    shape_size = 220                 # diameter / sida
    half = shape_size // 2
    # Placeringar (mitt-koordinater)
    p_circle = (SIZE // 2, int(SIZE * 0.30))
    p_square = (int(SIZE * 0.28), int(SIZE * 0.68))
    p_diamond = (int(SIZE * 0.72), int(SIZE * 0.68))

    # Pilar mellan formerna (rita FÖRE formerna så att formerna döljer linjeändar)
    line_w = 14
    arrow_pts = [
        (p_circle, p_square),
        (p_circle, p_diamond),
        (p_square, p_diamond),
    ]
    for a, b in arrow_pts:
        draw_arrow(draw, a, b, ARROW, line_w, shrink=half + 10)

    # Cirkel
    draw.ellipse(
        [p_circle[0] - half, p_circle[1] - half, p_circle[0] + half, p_circle[1] + half],
        fill=SHAPE,
    )

    # Fyrkant — rundade hörn
    radius = 36
    sx, sy = p_square
    rounded_rect(draw, sx - half, sy - half, sx + half, sy + half, radius, SHAPE)

    # Diamant — rundad
    draw_rounded_diamond(draw, p_diamond[0], p_diamond[1], half, SHAPE, corner_radius=20)

    # Säkerställ ingen alpha
    if img.mode != "RGB":
        img = img.convert("RGB")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"OK — {OUT} ({SIZE}x{SIZE} RGB, ingen alpha)")


def rounded_rect(draw, x0, y0, x1, y1, r, fill):
    draw.rectangle([x0 + r, y0, x1 - r, y1], fill=fill)
    draw.rectangle([x0, y0 + r, x1, y1 - r], fill=fill)
    draw.pieslice([x0, y0, x0 + 2 * r, y0 + 2 * r], 180, 270, fill=fill)
    draw.pieslice([x1 - 2 * r, y0, x1, y0 + 2 * r], 270, 360, fill=fill)
    draw.pieslice([x0, y1 - 2 * r, x0 + 2 * r, y1], 90, 180, fill=fill)
    draw.pieslice([x1 - 2 * r, y1 - 2 * r, x1, y1], 0, 90, fill=fill)


def draw_rounded_diamond(draw, cx, cy, half, fill, corner_radius=20):
    # Diamant = roterad fyrkant 45°. Enklast: polygon med 4 punkter, men för mjuka hörn
    # ritar vi som en bildmask och paste:ar tillbaka.
    s = int(half * 1.45)   # diagonal-justering så formen ser visuellt likvärdig stor ut
    canvas = Image.new("L", (s * 2 + 80, s * 2 + 80), 0)
    cd = ImageDraw.Draw(canvas)
    # Rita en rundad fyrkant centrerad
    pad = 40
    rounded_rect(cd, pad, pad, pad + 2 * s, pad + 2 * s, corner_radius * 2, 255)
    # Rotera 45°
    rotated = canvas.rotate(45, resample=Image.BICUBIC, expand=True)
    # Hitta rotated centrum och paste:a på huvudbilden
    rw, rh = rotated.size
    px = cx - rw // 2
    py = cy - rh // 2
    # Skapa färglager med samma storlek
    color_layer = Image.new("RGB", (rw, rh), fill)
    base = draw._image
    base.paste(color_layer, (px, py), rotated)


def draw_arrow(draw, a, b, color, width, shrink=0):
    """Rita rak linje med pilhuvud från a till b, krymp båda ändarna med 'shrink'."""
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    dist = math.hypot(dx, dy)
    if dist < 1:
        return
    ux, uy = dx / dist, dy / dist
    # Krympta start/slut
    sx, sy = ax + ux * shrink, ay + uy * shrink
    ex, ey = bx - ux * shrink, by - uy * shrink
    draw.line([(sx, sy), (ex, ey)], fill=color, width=width)
    # Pilhuvud
    head_len = 36
    head_w = 26
    # Bas-punkten där pilhuvudet börjar
    bxh, byh = ex - ux * head_len, ey - uy * head_len
    # Perpendikulär
    px, py = -uy, ux
    p1 = (bxh + px * head_w, byh + py * head_w)
    p2 = (bxh - px * head_w, byh - py * head_w)
    draw.polygon([p1, (ex, ey), p2], fill=color)


if __name__ == "__main__":
    main()
