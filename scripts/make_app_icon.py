#!/usr/bin/env python3
"""
Generera Visuali2e app-ikon — pixlad "2/Z" hybrid-glyph med
pastell-gradient (lila → rosa → grön) på vit bakgrund.

Grid: 24×24. Skalas till 1024×1024 med NEAREST → behåller pixel-look.
"""
from PIL import Image
from pathlib import Path

GRID = 24
SCALE = 1024 // GRID  # 42 px per cell (24*42 = 1008, padda upp till 1024)
TARGET = 1024

BG = (252, 250, 255, 255)         # nästan-vit lavendel
LILA = (177, 156, 217, 255)       # pastell-lila
ROSA = (255, 182, 200, 255)       # pastell-rosa
GRON = (152, 216, 200, 255)       # pastell-mint

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))

def gradient_color(row_in_glyph, total_rows):
    """ Lila topp → Rosa mitten → Grön botten """
    t = row_in_glyph / max(total_rows - 1, 1)
    if t < 0.5:
        return lerp(LILA, ROSA, t * 2)
    else:
        return lerp(ROSA, GRON, (t - 0.5) * 2)

def make_glyph_grid():
    """ Returnerar 24×24 grid med True där glyph-pixlar ska vara. """
    grid = [[False] * GRID for _ in range(GRID)]

    # 2/Z hybrid: topp-bar + diagonal + botten-bar
    # Glyph rows 3..20 (18 rader), kolumner 4..19 (16 kolumner brett)
    # Topp-bar (2 px hög)
    for col in range(4, 20):
        grid[3][col] = True
        grid[4][col] = True
    # Botten-bar (2 px hög)
    for col in range(4, 20):
        grid[19][col] = True
        grid[20][col] = True
    # Diagonal från övre-höger till nedre-vänster (2 px tjock)
    # Start: rad 5 col 18-19, slut: rad 18 col 4-5
    # 13 rader (5..18), 14 kolumner (5..18) → step ~1 per rad
    diag_rows = list(range(5, 19))
    for i, r in enumerate(diag_rows):
        # col går från 18 (vid r=5) ned till 5 (vid r=18)
        col = int(18 - (i * 13 / (len(diag_rows) - 1)))
        grid[r][col] = True
        grid[r][col + 1] = True  # 2 px tjock
    return grid

def render():
    # Rita på 24×24 grid med upscaling till 1008×1008, sen padda till 1024
    inner = Image.new('RGBA', (GRID * SCALE, GRID * SCALE), BG)
    px = inner.load()
    grid = make_glyph_grid()
    glyph_top = 3
    glyph_bot = 20
    for r in range(GRID):
        for c in range(GRID):
            if grid[r][c]:
                color = gradient_color(r - glyph_top, glyph_bot - glyph_top + 1)
                for dy in range(SCALE):
                    for dx in range(SCALE):
                        px[c * SCALE + dx, r * SCALE + dy] = color

    # Lägg några små "diagram-elements" runt glyph (subtila pastell-detaljer)
    # En liten ruta upp-vänster (rosa, 1×1 cell), en cirkel-prick nere-höger
    accent_cells = [
        (1, 2, ROSA),      # rad 1, col 2 — ljus-rosa prick
        (21, 20, GRON),    # rad 21, col 20 — grön prick
        (2, 21, LILA),     # rad 2, col 21 — lila prick
    ]
    for r, c, color in accent_cells:
        # Halv opacitet
        muted = tuple(int(BG[i] + (color[i] - BG[i]) * 0.55) for i in range(4))
        for dy in range(SCALE):
            for dx in range(SCALE):
                px[c * SCALE + dx, r * SCALE + dy] = muted

    # Padda till 1024×1024 (centrera 1008 i 1024)
    canvas = Image.new('RGBA', (TARGET, TARGET), BG)
    offset = (TARGET - GRID * SCALE) // 2
    canvas.paste(inner, (offset, offset))

    out = Path(__file__).parent.parent / 'app/MermaidCanvas/Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png'
    canvas.convert('RGB').save(out, 'PNG')
    print(f'Wrote: {out}')

if __name__ == '__main__':
    render()
