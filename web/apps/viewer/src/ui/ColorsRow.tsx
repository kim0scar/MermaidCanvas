/** Speglar native färgpaket-raden: 8 numrerade paket (ColorPack.pickerVisible). */
export interface PackChip {
  id: number;
  name: string;
  fill: string;
  stroke: string;
  text?: string;
}

export function ColorsRow({ packs, onPick }: { packs: PackChip[]; onPick: (id: number) => void }) {
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
    </div>
  );
}
