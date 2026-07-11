/** Speglar native färgpaket-raden: 8 numrerade paket (ColorPack.pickerVisible). */
export interface PackChip {
  id: number;
  name: string;
  fill: string;
  stroke: string;
  text?: string;
}

export function ColorsRow({
  packs,
  onPick,
  fill,
  stroke,
  onCustomColor,
}: {
  packs: PackChip[];
  onPick: (id: number) => void;
  fill: string;
  stroke: string;
  onCustomColor: (patch: { color?: string; strokeColor?: string }) => void;
}) {
  return (
    <div className="ios-subrow">
      {packs.map((p) => (
        <button
          key={p.id}
          className="ios-packchip"
          style={{
            ['--pack-fill' as string]: p.fill,
            ['--pack-stroke' as string]: p.stroke,
            ['--pack-text' as string]: p.text ?? '#374151',
          }}
          onClick={() => onPick(p.id)}
          aria-label={p.name}
          title={p.name}
        >
          {p.id}
        </button>
      ))}
      <div className="ios-divider" />
      <label className="ios-colorfield" title="Egen fyllningsfärg">
        <span className="lbl">Fyll</span>
        <input
          type="color"
          value={/^#[0-9a-fA-F]{6}$/.test(fill) ? fill : '#ffffff'}
          onChange={(e) => onCustomColor({ color: e.target.value })}
          aria-label="Egen fyllningsfärg"
        />
      </label>
      <label className="ios-colorfield" title="Egen ramfärg">
        <span className="lbl">Ram</span>
        <input
          type="color"
          value={/^#[0-9a-fA-F]{6}$/.test(stroke) ? stroke : '#1e293b'}
          onChange={(e) => onCustomColor({ strokeColor: e.target.value })}
          aria-label="Egen ramfärg"
        />
      </label>
      <button
        className="ios-stylebtn"
        onClick={() => onCustomColor({ color: '', strokeColor: '' })}
        aria-label="Rensa egen färg"
        title="Rensa egen färg (tillbaka till paket)"
      >
        ✕
      </button>
    </div>
  );
}
