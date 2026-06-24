#!/usr/bin/env python3
"""
Visuali2e 1.0 — klassisk Apple-app-ikon.

Motiv "Flödet": tre kopplade vita noder (cirkel → romb → rundad ruta) med pilar,
diagonalt över en djup indigo→violett vertikal gradient. Berättar direkt vad appen gör.
Mjuk gloss uppe-vänster + subtil skugga under formerna = klassiskt Apple-djup.

Full-bleed kvadrat (iOS maskar hörnen själv). Renderas i 4× och nedskalas med
LANCZOS för mjuka, rena kanter. Skriver om samma enda Icon-1024.png.
"""
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path
import math

SS = 4                 # supersampling för mjuka kanter
S = 1024 * SS          # arbetsupplösning

# Vertikal gradient: djup indigo överst → violett nederst (premium, tidlöst)
TOP = (54, 44, 140)    # #362C8C indigo
BOT = (128, 92, 232)   # #805CE8 violett
WHITE = (255, 255, 255, 255)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(w, h, top, bot):
    col = Image.new('RGB', (1, h))
    px = col.load()
    for y in range(h):
        px[0, y] = lerp(top, bot, y / (h - 1))
    return col.resize((w, h))


def P(x, y):
    return (x * SS, y * SS)


def R(v):
    return int(v * SS)


def toward(a, b, dist):
    """Punkt `dist` px från a längs linjen a→b (1024-skala)."""
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    return (a[0] + dist * math.cos(ang), a[1] + dist * math.sin(ang))


def main():
    base = vertical_gradient(S, S, TOP, BOT).convert('RGBA')

    # Mjuk gloss uppe-vänster (subtilt ljus → djup)
    gloss = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(gloss).ellipse(
        [-S * 0.25, -S * 0.45, S * 0.85, S * 0.55], fill=(255, 255, 255, 55))
    gloss = gloss.filter(ImageFilter.GaussianBlur(S * 0.10))
    base = Image.alpha_composite(base, gloss)

    # Nod-geometri (1024-skala), diagonalt centrerad. Glesare noder → pilarna syns tydligt.
    c1, r1 = (300, 300), 84               # cirkel
    c2, d2 = (512, 512), 96               # romb (halv-diagonal)
    c3, w3, h3, cr3 = (724, 724), 220, 140, 38   # rundad ruta

    # Skugg-lager: formerna mörka → blur → låg opacitet, lätt nedåt-offset
    shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    dark = (18, 10, 56, 120)
    sd.ellipse([P(c1[0] - r1, c1[1] - r1), P(c1[0] + r1, c1[1] + r1)], fill=dark)
    sd.polygon([P(c2[0], c2[1] - d2), P(c2[0] + d2, c2[1]),
                P(c2[0], c2[1] + d2), P(c2[0] - d2, c2[1])], fill=dark)
    sd.rounded_rectangle([P(c3[0] - w3 // 2, c3[1] - h3 // 2),
                          P(c3[0] + w3 // 2, c3[1] + h3 // 2)], radius=R(cr3), fill=dark)
    shadow = shadow.filter(ImageFilter.GaussianBlur(S * 0.013))
    off = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    off.paste(shadow, (0, int(S * 0.013)))
    base = Image.alpha_composite(base, off)

    draw = ImageDraw.Draw(base)

    # Vita noder
    draw.ellipse([P(c1[0] - r1, c1[1] - r1), P(c1[0] + r1, c1[1] + r1)], fill=WHITE)
    draw.polygon([P(c2[0], c2[1] - d2), P(c2[0] + d2, c2[1]),
                  P(c2[0], c2[1] + d2), P(c2[0] - d2, c2[1])], fill=WHITE)
    draw.rounded_rectangle([P(c3[0] - w3 // 2, c3[1] - h3 // 2),
                            P(c3[0] + w3 // 2, c3[1] + h3 // 2)], radius=R(cr3), fill=WHITE)

    # Pilar mellan noderna (kant→kant, pilspets synlig på gradienten)
    lw = 20

    def arrow(a, b, start_pad, end_pad):
        ps = toward(a, b, start_pad)
        pe = toward(b, a, end_pad)
        draw.line([P(*ps), P(*pe)], fill=WHITE, width=R(lw))
        ang = math.atan2(pe[1] - ps[1], pe[0] - ps[0])
        ah, aw = 44, 30
        left = (pe[0] - ah * math.cos(ang) + aw * math.sin(ang),
                pe[1] - ah * math.sin(ang) - aw * math.cos(ang))
        right = (pe[0] - ah * math.cos(ang) - aw * math.sin(ang),
                 pe[1] - ah * math.sin(ang) + aw * math.cos(ang))
        draw.polygon([P(*pe), P(*left), P(*right)], fill=WHITE)

    arrow(c1, c2, r1 + 8, d2 + 14)            # cirkel → romb
    arrow(c2, c3, d2 + 8, h3 // 2 + 14)       # romb → rundad ruta

    out = (Path(__file__).parent.parent /
           'app/MermaidCanvas/Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png')
    base.resize((1024, 1024), Image.LANCZOS).convert('RGB').save(out, 'PNG')
    print(f'Wrote: {out}')


if __name__ == '__main__':
    main()
