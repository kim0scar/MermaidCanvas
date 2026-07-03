// Native-troget-grinden: varje kategori har färger, varje form-typ har geometri +
// basstorlek, färgpaketen 0–7 ligger i exakt picker-ordning (Swift ColorPack.pickerVisible)
// och stil-precedensen följer ShapeView+Style.swift.
import { describe, expect, it } from 'vitest';
import { SHAPE_CATEGORIES, SHAPE_TYPES, TEXT_STYLES } from '@v2e/domain';
import { BASE_SIZES } from '../src/sizes.js';
import {
  CATEGORY_COLORS,
  COLOR_PACKS,
  PICKER_PACKS,
  effectiveColors,
  isDarkHex,
  packById,
} from '../src/native/colors.js';
import { SHAPE_BODY, shapeShadow } from '../src/native/geometry.js';
import { cornerRadius } from '../src/native/tokens.js';
import { cylinderPath, diamondPath, octagonPath, processArrowPath, trianglePath } from '../src/native/paths.js';
import { TEXT_STYLE_FONT, effectiveWeight, formatLabel } from '../src/native/text.js';

const HEX = /^#[0-9a-f]{6}$/;

describe('kategorifärger (port av ShapeCategory.swift)', () => {
  it('varje ShapeCategory har giltig fill/stroke/text', () => {
    for (const cat of SHAPE_CATEGORIES) {
      const c = CATEGORY_COLORS[cat];
      expect(c, cat).toBeDefined();
      expect(c.fill, `${cat} fill`).toMatch(HEX);
      expect(c.stroke, `${cat} stroke`).toMatch(HEX);
      expect(c.text, `${cat} text`).toMatch(HEX);
    }
  });

  it('stickprov mot Swift-sanningen', () => {
    expect(CATEGORY_COLORS.ui).toEqual({ fill: '#1d4ed8', stroke: '#1e293b', text: '#f9fafb' });
    expect(CATEGORY_COLORS.gate).toEqual({ fill: '#e11d48', stroke: '#9f1239', text: '#f9fafb' });
    expect(CATEGORY_COLORS.godot_script).toEqual({ fill: '#4ade80', stroke: '#16a34a', text: '#064e3b' });
  });
});

describe('färgpaket (port av ColorPack.swift)', () => {
  it('picker-paketen 0–7 i exakt Swift-ordning (pickerVisible)', () => {
    const expected = [
      { id: 'none', fill: '#ffffff', stroke: '#6b7280' },
      { id: 'blå', fill: '#deedfd', stroke: '#74b0e6' },
      { id: 'grön', fill: '#daf0e0', stroke: '#74c09a' },
      { id: 'gul', fill: '#fff0cd', stroke: '#e4b854' },
      { id: 'rosa', fill: '#ffe1ea', stroke: '#f291a8' },
      { id: 'lila', fill: '#ebdcfb', stroke: '#ad92dd' },
      { id: 'persika', fill: '#ffe6d6', stroke: '#efa379' },
      { id: 'ui-blå', fill: '#0a84ff', stroke: '#0a6cd8' },
    ];
    expect(PICKER_PACKS.map((p) => ({ id: p.id, fill: p.fill, stroke: p.stroke }))).toEqual(expected);
    expect(PICKER_PACKS[7]!.text).toBe('#ffffff'); // uiBlå = vit text
  });

  it('ALLA 12 pack-id finns kvar (gamla filer behåller sin färg)', () => {
    expect(COLOR_PACKS.map((p) => p.id)).toEqual([
      'none', 'persika', 'rosa', 'blå', 'grön', 'gul', 'lila',
      'ui-blå', 'ui-grön', 'ui-röd', 'ui-grå', 'ui-mörk',
    ]);
    expect(packById('ui-mörk').fill).toBe('#1c1c1e');
    expect(packById(undefined).id).toBe('none');
    expect(packById('finns-inte').id).toBe('none');
  });
});

describe('stil-precedens (port av ShapeView+Style.swift)', () => {
  it('default = vit fyllning + kategori-ram + mörk text', () => {
    expect(effectiveColors({ category: 'ui' })).toEqual({
      fill: '#ffffff',
      stroke: '#1e293b',
      text: '#111827',
    });
  });

  it('paket vinner över kategori, egen färg vinner över paket', () => {
    const packed = effectiveColors({ category: 'ui', colorPackId: 'blå' });
    expect(packed).toEqual({ fill: '#deedfd', stroke: '#74b0e6', text: '#18497e' });
    const own = effectiveColors({ category: 'ui', colorPackId: 'blå', color: '#0f172a', strokeColor: '#ff0000' });
    expect(own.fill).toBe('#0f172a');
    expect(own.stroke).toBe('#ff0000');
    expect(own.text).toBe('#ffffff'); // mörk egen fyllning → vit text (YIQ)
  });

  it('isDarkHex följer YIQ-tröskeln', () => {
    expect(isDarkHex('#000000')).toBe(true);
    expect(isDarkHex('#ffffff')).toBe(false);
    expect(isDarkHex('#0A84FF')).toBe(true);
  });
});

describe('geometri + storlek per form-typ', () => {
  it('varje ShapeType har SVG-kropp, BASE_SIZE, hörnradie och skugg-beslut', () => {
    for (const type of SHAPE_TYPES) {
      expect(typeof SHAPE_BODY[type], type).toBe('function');
      const size = BASE_SIZES[type];
      expect(size.w, type).toBeGreaterThan(0);
      expect(size.h, type).toBeGreaterThan(0);
      expect(Number.isFinite(cornerRadius(type, size.w, size.h)), type).toBe(true);
      expect(() => shapeShadow(type), type).not.toThrow();
    }
  });

  it('siluett-paths är giltiga (M…Z) vid basstorlek', () => {
    for (const path of [
      diamondPath(120, 80),
      processArrowPath(110, 80),
      octagonPath(80, 80),
      trianglePath(88, 80),
      cylinderPath(100, 90),
    ]) {
      expect(path.startsWith('M ')).toBe(true);
      expect(path.endsWith('Z')).toBe(true);
      expect(path).not.toContain('NaN');
    }
  });
});

describe('typografi (port av TextStyle.swift)', () => {
  it('5 nivåer med exakta storlekar/vikter', () => {
    expect(TEXT_STYLES.map((s) => TEXT_STYLE_FONT[s])).toEqual([
      { size: 40, weight: 700 },
      { size: 30, weight: 700 },
      { size: 24, weight: 600 },
      { size: 18, weight: 500 },
      { size: 14, weight: 400 },
    ]);
  });

  it('fet-toggle = en notch tyngre (Swift effectiveWeight)', () => {
    expect(effectiveWeight('body', false)).toBe(400);
    expect(effectiveWeight('body', true)).toBe(700);
    expect(effectiveWeight('jatte', true)).toBe(800);
  });

  it('formatLabel: bullets/numrering/indrag som native', () => {
    expect(formatLabel('a\nb', true, false, 0)).toBe('• a\n• b');
    expect(formatLabel('a\nb', false, true, 1)).toBe('  1. a\n  2. b');
    expect(formatLabel('a', false, false, 2)).toBe('    a');
  });
});
