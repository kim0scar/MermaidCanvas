#!/usr/bin/env python3
"""
v45 Visuali2e — app-ikon-generator.

Lila gradient bakgrund, "Visuali" i vit + "2e" highlightat i ljus korall.
"2e" = "twice-exceptional" — kognitiv profil med dubbel begåvning/utmaning.
Output: 1024×1024 PNG utan alpha (Apple-krav).
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

SIZE = 1024

# Lila gradient: ljus topp → djupare lila botten
BG_TOP = (200, 175, 245)      # #C8AFF5 ljus lavendel
BG_BOTTOM = (124, 88, 220)    # #7C58DC djupare lila

# Highlight för 2e — varm korall som sticker ut mot lila
HIGHLIGHT = (255, 196, 128)   # #FFC480 mjuk korall/persika

WHITE = (255, 255, 255)
SHADOW = (60, 30, 110)

FONT_ROUNDED = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_FALLBACK = "/Library/Fonts/Avenir Next.ttc"

OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "app", "MermaidCanvas", "Resources", "Assets.xcassets",
    "AppIcon.appiconset", "Icon-1024.png"
)


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", (size, size), top)
    for y in range(size):
        t = y / (size - 1)
        col = (
            int(top[0] + (bottom[0] - top[0]) * t),
            int(top[1] + (bottom[1] - top[1]) * t),
            int(top[2] + (bottom[2] - top[2]) * t),
        )
        ImageDraw.Draw(img).line([(0, y), (size, y)], fill=col)
    return img


def load_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.truetype(FONT_FALLBACK, size)


def measure(draw, text, font):
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0], bbox[3] - bbox[1], bbox[0], bbox[1]


def main():
    img = vertical_gradient(SIZE, BG_TOP, BG_BOTTOM)

    # Mjuk inre glow uppe-vänster för djup
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-200, -200, 700, 700], fill=(255, 255, 255, 40))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=120))
    img.paste(glow, (0, 0), glow)

    draw = ImageDraw.Draw(img)

    # === TEXT-LAYOUT ===
    # "Visuali" + "2e" på samma rad
    # Stora typsnitt — ska fylla ikonen brett, "2e" lite större (highlight)

    # Text-storlek skalas automatiskt så hela "Visuali 2e" får ordentlig
    # padding mot kanterna (iOS rundar hörnen ~18% av sidan, så marginal är kritisk)
    text_main = "Visuali"
    text_2e = "2e"

    target_width = int(SIZE * 0.78)   # max-bredd för texten

    # Börja stort + skala ner tills det får plats
    font_size = 240
    while font_size > 60:
        font_main = load_font(FONT_ROUNDED, font_size)
        font_2e = load_font(FONT_ROUNDED, int(font_size * 1.18))
        w_main, h_main, ox_main, oy_main = measure(draw, text_main, font_main)
        w_2e, h_2e, ox_2e, oy_2e = measure(draw, text_2e, font_2e)
        # Pill-padding ingår i totalen
        pill_pad_x = max(int(font_size * 0.06), 12)
        gap = int(font_size * 0.05)
        total_w = w_main + gap + w_2e + 2 * pill_pad_x
        if total_w <= target_width:
            break
        font_size -= 10

    base_x = (SIZE - total_w) // 2 + pill_pad_x

    # Vertikalt centrum — flytta upp lite för balans
    cy = int(SIZE * 0.46)

    # === SKUGGA bakom text ===
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.text((base_x - ox_main + 6, cy - h_main // 2 - oy_main + 8),
            text_main, font=font_main, fill=(40, 20, 80, 130))
    sd.text((base_x + w_main + gap - ox_2e + 6, cy - h_2e // 2 - oy_2e + 8),
            text_2e, font=font_2e, fill=(40, 20, 80, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=12))
    img.paste(shadow, (0, 0), shadow)

    # === HUVUDTEXT "Visuali" — vit ===
    draw.text(
        (base_x - ox_main, cy - h_main // 2 - oy_main),
        text_main,
        font=font_main,
        fill=WHITE,
    )

    # === HIGHLIGHT-PILL bakom "2e" ===
    # Avrundad pill i korall som bakgrund — gör 2e visuellt distinkt
    pill_pad_y = max(int(font_size * 0.06), 10)
    pill_x0 = base_x + w_main + gap - pill_pad_x
    pill_y0 = cy - h_2e // 2 - pill_pad_y
    pill_x1 = base_x + w_main + gap + w_2e + pill_pad_x
    pill_y1 = cy + h_2e // 2 + pill_pad_y
    radius = (pill_y1 - pill_y0) // 2
    draw.rounded_rectangle([pill_x0, pill_y0, pill_x1, pill_y1],
                           radius=radius, fill=HIGHLIGHT)

    # "2e" i djupare lila ovanpå pill — kontrast mot korallen
    draw.text(
        (base_x + w_main + gap - ox_2e, cy - h_2e // 2 - oy_2e),
        text_2e,
        font=font_2e,
        fill=(80, 40, 160),
    )

    # === LITEN UNDERTITEL ===
    sub_font = load_font(FONT_ROUNDED, 64)
    sub = "visuell tankekarta"
    sw, sh, sox, soy = measure(draw, sub, sub_font)
    sub_x = (SIZE - sw) // 2 - sox
    sub_y = int(SIZE * 0.78) - sh // 2 - soy
    # Skugga
    sshadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(sshadow).text((sub_x + 3, sub_y + 4), sub,
                                  font=sub_font, fill=(40, 20, 80, 120))
    sshadow = sshadow.filter(ImageFilter.GaussianBlur(radius=6))
    img.paste(sshadow, (0, 0), sshadow)
    draw.text((sub_x, sub_y), sub, font=sub_font, fill=(255, 245, 230))

    # Säkerställ ingen alpha
    if img.mode != "RGB":
        img = img.convert("RGB")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"OK — {OUT} ({SIZE}x{SIZE} RGB, ingen alpha)")


if __name__ == "__main__":
    main()
