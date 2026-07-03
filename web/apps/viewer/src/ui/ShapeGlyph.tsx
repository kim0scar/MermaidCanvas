import type { ShapeType } from '@v2e/domain';

/** Mini-glyfer för form-chips (speglar native chip-ikonerna). Neutral färg — CSS styr. */
export function ShapeGlyph({ type }: { type: ShapeType }) {
  const stroke = 'currentColor';
  const common = { fill: 'none', stroke, strokeWidth: 2 } as const;
  switch (type) {
    case 'circle':
      return <svg viewBox="0 0 30 24"><ellipse cx="15" cy="12" rx="10" ry="10" {...common} /></svg>;
    case 'pill':
      return <svg viewBox="0 0 30 24"><rect x="2" y="6" width="26" height="12" rx="6" {...common} /></svg>;
    case 'rectangle':
      return <svg viewBox="0 0 30 24"><rect x="3" y="5" width="24" height="14" rx="2" {...common} /></svg>;
    case 'square':
      return <svg viewBox="0 0 30 24"><rect x="7" y="4" width="16" height="16" rx="1.5" {...common} /></svg>;
    case 'diamond':
      return <svg viewBox="0 0 30 24"><path d="M15 2 L27 12 L15 22 L3 12 Z" {...common} /></svg>;
    case 'processArrow':
      return <svg viewBox="0 0 30 24"><path d="M3 5 H21 L27 12 L21 19 H3 Z" {...common} /></svg>;
    case 'octagon':
      return <svg viewBox="0 0 30 24"><path d="M10 3 H20 L26 8 V16 L20 21 H10 L4 16 V8 Z" {...common} /></svg>;
    case 'triangle':
      return <svg viewBox="0 0 30 24"><path d="M15 3 L27 21 H3 Z" {...common} /></svg>;
    case 'cylinder':
      return (
        <svg viewBox="0 0 30 24">
          <path d="M5 6 V18 A10 4 0 0 0 25 18 V6" {...common} />
          <ellipse cx="15" cy="6" rx="10" ry="4" {...common} />
        </svg>
      );
    case 'container':
      return (
        <svg viewBox="0 0 30 24">
          <rect x="2" y="3" width="26" height="18" rx="2" {...common} />
          <line x1="2" y1="9" x2="28" y2="9" stroke={stroke} strokeWidth="2" />
        </svg>
      );
    case 'table':
      return (
        <svg viewBox="0 0 30 24">
          <rect x="2" y="3" width="26" height="18" rx="1.5" {...common} />
          <line x1="2" y1="12" x2="28" y2="12" stroke={stroke} strokeWidth="1.5" />
          <line x1="15" y1="3" x2="15" y2="21" stroke={stroke} strokeWidth="1.5" />
        </svg>
      );
    case 'link':
      return (
        <svg viewBox="0 0 30 24">
          <circle cx="15" cy="12" r="9" {...common} />
          <text x="15" y="16" textAnchor="middle" fontSize="11" fill={stroke} stroke="none">1</text>
        </svg>
      );
    case 'phoneFrame':
      return <svg viewBox="0 0 30 24"><rect x="9" y="2" width="12" height="20" rx="3" {...common} /></svg>;
    case 'line':
      return <svg viewBox="0 0 30 24"><line x1="4" y1="19" x2="26" y2="5" stroke={stroke} strokeWidth="2" /></svg>;
    case 'arrow':
      return (
        <svg viewBox="0 0 30 24">
          <line x1="4" y1="12" x2="23" y2="12" stroke={stroke} strokeWidth="2" />
          <path d="M20 7 L26 12 L20 17" {...common} />
        </svg>
      );
    case 'emoji':
      return <svg viewBox="0 0 30 24"><text x="15" y="18" textAnchor="middle" fontSize="16" stroke="none" fill={stroke}>😀</text></svg>;
  }
}
