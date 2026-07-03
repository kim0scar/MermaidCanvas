/** Små inline-ikoner (speglar SF Symbols-känslan i native-appen). */
const s = { fill: 'none', stroke: 'currentColor', strokeWidth: 1.8, strokeLinecap: 'round', strokeLinejoin: 'round' } as const;

export const IconShapes = () => (
  <svg viewBox="0 0 24 24">
    <rect x="3" y="3" width="12" height="12" rx="2" {...s} />
    <circle cx="16" cy="16" r="5.5" {...s} />
  </svg>
);
export const IconPalette = () => (
  <svg viewBox="0 0 24 24">
    <path d="M12 3a9 9 0 1 0 0 18h1.5a2 2 0 0 0 0-4H12a2 2 0 0 1 0-4h5a4 4 0 0 0 4-4c0-3.5-4-6-9-6Z" {...s} />
    <circle cx="7.5" cy="10.5" r="1.1" fill="currentColor" stroke="none" />
    <circle cx="12" cy="7.5" r="1.1" fill="currentColor" stroke="none" />
    <circle cx="16.5" cy="10.5" r="1.1" fill="currentColor" stroke="none" />
  </svg>
);
export const IconTextStyle = () => (
  <svg viewBox="0 0 24 24">
    <text x="3" y="18" fontSize="17" fontWeight="700" fill="currentColor" stroke="none">A</text>
    <text x="14" y="18" fontSize="11" fill="currentColor" stroke="none">a</text>
  </svg>
);
export const IconSparkle = () => (
  <svg viewBox="0 0 24 24">
    <path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3Z" {...s} />
    <path d="M19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9L19 15Z" {...s} strokeWidth={1.4} />
  </svg>
);
export const IconMenu = () => (
  <svg viewBox="0 0 24 24">
    <line x1="4" y1="7" x2="20" y2="7" {...s} />
    <line x1="4" y1="12" x2="20" y2="12" {...s} />
    <line x1="4" y1="17" x2="20" y2="17" {...s} />
    <circle cx="9" cy="7" r="2" fill="currentColor" stroke="none" />
    <circle cx="15" cy="12" r="2" fill="currentColor" stroke="none" />
    <circle cx="7" cy="17" r="2" fill="currentColor" stroke="none" />
  </svg>
);
export const IconNew = () => (
  <svg viewBox="0 0 24 24"><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9l-6-6Z" {...s} /><path d="M14 3v6h6" {...s} /><line x1="12" y1="12" x2="12" y2="18" {...s} /><line x1="9" y1="15" x2="15" y2="15" {...s} /></svg>
);
export const IconOpen = () => (
  <svg viewBox="0 0 24 24"><path d="M3 7V5a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v2" {...s} /><path d="M3 7h18l-2 12H5L3 7Z" {...s} /></svg>
);
export const IconSave = () => (
  <svg viewBox="0 0 24 24"><path d="M12 3v12" {...s} /><path d="M7 10l5 5 5-5" {...s} /><path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" {...s} /></svg>
);
export const IconCode = () => (
  <svg viewBox="0 0 24 24"><path d="M9 6l-6 6 6 6" {...s} /><path d="M15 6l6 6-6 6" {...s} /></svg>
);
export const IconCopy = () => (
  <svg viewBox="0 0 24 24"><rect x="8" y="8" width="12" height="12" rx="2" {...s} /><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" {...s} /></svg>
);
export const IconShare = () => (
  <svg viewBox="0 0 24 24"><path d="M12 3v12" {...s} /><path d="M7 8l5-5 5 5" {...s} /><path d="M4 13v6a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-6" {...s} /></svg>
);
export const IconEye = () => (
  <svg viewBox="0 0 24 24"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7Z" {...s} /><circle cx="12" cy="12" r="3" {...s} /></svg>
);
export const IconZoomReset = () => (
  <svg viewBox="0 0 24 24"><circle cx="10.5" cy="10.5" r="6.5" {...s} /><line x1="15.5" y1="15.5" x2="21" y2="21" {...s} /><text x="10.5" y="14" textAnchor="middle" fontSize="9" fontWeight="600" fill="currentColor" stroke="none">1</text></svg>
);
export const IconInfo = () => (
  <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" {...s} /><line x1="12" y1="11" x2="12" y2="16" {...s} /><circle cx="12" cy="8" r="0.5" fill="currentColor" stroke="none" /></svg>
);
export const IconChat = () => (
  <svg viewBox="0 0 24 24"><path d="M21 12a8 8 0 0 1-8 8H5l-2 2V12a8 8 0 0 1 8-8h2a8 8 0 0 1 8 8Z" {...s} /></svg>
);
export const IconClose = () => (
  <svg viewBox="0 0 24 24"><line x1="6" y1="6" x2="18" y2="18" {...s} /><line x1="18" y1="6" x2="6" y2="18" {...s} /></svg>
);
