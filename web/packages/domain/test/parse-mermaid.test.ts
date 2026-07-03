// Enhetstester för Tier 2-parsern — varje beteende speglar Swift MermaidParser
// (parseMermaid + MermaidMetaComments + EdgeMeta + AutoLayout). Swift är facit.
import { describe, expect, it } from 'vitest';
import { parseMermaidBody } from '../src/index.js';

describe('nodrader — alla syntax-varianter', () => {
  const body = `flowchart TD
    a(("Cirkel")):::input
    b(["Kapsel #quot;X#quot;"]):::skill
    c[("Databas")]:::evidence
    d("Rundad<br/>rektangel"):::ui
    e_x["Klassisk"]
    f{"Val?"}:::gate
    g((Ocitat cirkel))
    h([Ocitat kapsel])
    i[(Ocitat cylinder)]
    j(Ocitat rund)
    k[Ocitat klassisk]
    l{Ocitat val}
`;
  const { doc } = parseMermaidBody(body);
  const byId = new Map(doc.shapes.map((s) => [s.id, s]));

  it('typer ur kroppens form-syntax', () => {
    expect(byId.get('a')!.type).toBe('circle');
    expect(byId.get('b')!.type).toBe('pill');
    expect(byId.get('c')!.type).toBe('cylinder');
    expect(byId.get('d')!.type).toBe('rectangle');
    expect(byId.get('e_x')!.type).toBe('rectangle');
    expect(byId.get('f')!.type).toBe('diamond');
    expect(byId.get('g')!.type).toBe('circle');
    expect(byId.get('h')!.type).toBe('pill');
    expect(byId.get('i')!.type).toBe('cylinder');
    expect(byId.get('j')!.type).toBe('rectangle');
    expect(byId.get('k')!.type).toBe('rectangle');
    expect(byId.get('l')!.type).toBe('diamond');
  });

  it('label-unescaping: #quot; → " och <br/> → radbrytning', () => {
    expect(byId.get('b')!.label).toBe('Kapsel "X"');
    expect(byId.get('d')!.label).toBe('Rundad\nrektangel');
  });

  it('kategori: :::klass vinner, annars id-prefix, annars ui', () => {
    expect(byId.get('a')!.category).toBe('input');
    expect(byId.get('b')!.category).toBe('skill');
    expect(byId.get('f')!.category).toBe('gate');
    expect(byId.get('e_x')!.category).toBe('ui'); // prefix "e" är ingen kategori
  });

  it('deprecated kategori (:::feat) migreras till note', () => {
    const r = parseMermaidBody('flowchart TD\n    m["X"]:::feat\n');
    expect(r.doc.shapes[0]!.category).toBe('note');
  });
});

describe('id-konventionen <kategori>_N<index> → category', () => {
  it('utan :::suffix härleds kategorin ur prefixet', () => {
    const { doc } = parseMermaidBody('flowchart TD\n    skill_N0["S"]\n    memory_N1["M"]\n    xyz_N2["?"]\n');
    const byId = new Map(doc.shapes.map((s) => [s.id, s]));
    expect(byId.get('skill_N0')!.category).toBe('skill');
    expect(byId.get('memory_N1')!.category).toBe('memory');
    expect(byId.get('xyz_N2')!.category).toBe('ui');
  });
});

describe('%%-metadata på noder — alla nycklar', () => {
  const body = `flowchart TD
    x["Allt"]:::tool
    %% x pos: 111,222
    %% x size: 1.5
    %% x width: 2.25
    %% x height: 0.50
    %% x rot: 45°
    %% x color: #123456
    %% x stroke: #654321
    %% x note: Rad1 ⏎ Rad2 med %-% procent
    %% x prompt: Gör saker
    %% x style: r2
    %% x align: leading
    %% x bullets
    %% x numbered
    %% x indent: 2
    %% x locked
    %% x z: 3
    %% x pack: rosa
    %% x link: 7
    %% x table: 3×4
    %% x table-cells: [["a","b"],["c","d"]]
`;
  const s = parseMermaidBody(body).doc.shapes[0]!;

  it('alla fält läses tillbaka som Swift', () => {
    expect(s.position).toEqual({ x: 111, y: 222 });
    expect(s.sizeMultiplier).toBe(1.5);
    expect(s.widthMultiplier).toBe(2.25);
    expect(s.heightMultiplier).toBe(0.5);
    expect(s.rotation).toBe(45);
    expect(s.colorOverride).toBe('#123456');
    expect(s.strokeColorOverride).toBe('#654321');
    expect(s.note).toBe('Rad1\nRad2 med %% procent'); // ⏎ + %-% avkodas
    expect(s.prompt).toBe('Gör saker');
    expect(s.textStyle).toBe('r2');
    expect(s.textAlignment).toBe('leading');
    expect(s.hasBullets).toBe(true);
    expect(s.hasNumberedList).toBe(true);
    expect(s.indentLevel).toBe(2);
    expect(s.locked).toBe(true);
    expect(s.zLayer).toBe(3);
    expect(s.colorPackId).toBe('rosa');
    expect(s.linkNumber).toBe(7);
    expect(s.tableRows).toBe(3);
    expect(s.tableCols).toBe(4);
    expect(s.tableCells).toEqual([['a', 'b'], ['c', 'd']]);
    expect(s.category).toBe('tool');
  });
});

describe('shape-type, hidden-label/name och line-end', () => {
  it('%% shape-type vinner över kroppen (phoneFrame saknar egen syntax)', () => {
    const { doc } = parseMermaidBody('flowchart TD\n    p["Telefon"]\n    %% p shape-type: phoneFrame\n');
    expect(doc.shapes[0]!.type).toBe('phoneFrame');
  });

  it('dold etikett (" " i kroppen) återställs från %% name', () => {
    const { doc } = parseMermaidBody(
      'flowchart TD\n    h1[" "]:::ui\n    %% h1 hidden-label\n    %% h1 name: Dolt namn\n');
    expect(doc.shapes[0]!.label).toBe('Dolt namn');
    expect(doc.shapes[0]!.showLabel).toBe(false);
  });

  it('line-end skrivs absolut → läses som relativ offset', () => {
    const { doc } = parseMermaidBody(
      'flowchart TD\n    l["Pil"]\n    %% l shape-type: arrow\n    %% l pos: 100,100\n    %% l line-end: 180,140\n');
    expect(doc.shapes[0]!.lineEnd).toEqual({ x: 80, y: 40 });
  });

  it('v66-migrering: gamla width/height på linje bakas in i lineEnd', () => {
    const { doc } = parseMermaidBody(
      'flowchart TD\n    l2["Linje"]\n    %% l2 shape-type: line\n    %% l2 pos: 100,100\n'
      + '    %% l2 line-end: 180,140\n    %% l2 width: 2.00\n    %% l2 height: 3.00\n');
    const s = doc.shapes[0]!;
    expect(s.lineEnd).toEqual({ x: 160, y: 120 });
    expect(s.sizeMultiplier).toBe(1);
    expect(s.widthMultiplier).toBeUndefined();
    expect(s.heightMultiplier).toBeUndefined();
  });
});

describe('kanter — alla 8 pil-kombinationer + etiketter', () => {
  const body = `flowchart TD
    n0["A"] --> n1["B"]
    n0 -.-> n2["C"]
    n2 <--> n1
    n0 --- n2
    n1 -.- n2
    n2 <-- n0
    n1 <-.-> n0
    n2 <-.- n1
    n0 -->|"Ja"| n1
    n0 -- gammal stil --> n1
    n0 ==> n1
`;
  const { doc } = parseMermaidBody(body);

  it('riktning + stil ur pil-glyfen', () => {
    expect(doc.edges[0]).toMatchObject({ from: 'n0', to: 'n1', direction: 'forward', style: 'solid' });
    expect(doc.edges[1]).toMatchObject({ from: 'n0', to: 'n2', direction: 'forward', style: 'dashed' });
    expect(doc.edges[2]).toMatchObject({ from: 'n2', to: 'n1', direction: 'bidirectional', style: 'solid' });
    expect(doc.edges[3]).toMatchObject({ from: 'n0', to: 'n2', direction: 'none', style: 'solid' });
    expect(doc.edges[4]).toMatchObject({ from: 'n1', to: 'n2', direction: 'none', style: 'dashed' });
    expect(doc.edges[5]).toMatchObject({ from: 'n2', to: 'n0', direction: 'backward', style: 'solid' });
    expect(doc.edges[6]).toMatchObject({ from: 'n1', to: 'n0', direction: 'bidirectional', style: 'dashed' });
    expect(doc.edges[7]).toMatchObject({ from: 'n2', to: 'n1', direction: 'backward', style: 'dashed' });
  });

  it('etiketter: citerad, gammal --text-->-stil och tjock pil (==>)', () => {
    expect(doc.edges[8]).toMatchObject({ label: 'Ja' });
    expect(doc.edges[9]).toMatchObject({ label: 'gammal stil' });
    expect(doc.edges[10]).toMatchObject({ label: '', direction: 'forward', style: 'solid' });
  });
});

describe('%% e<i>-kant-metadata', () => {
  const body = `flowchart TD
    a["A"] --> b["B"]
    %% e0 waypoint: 100,50
    %% e0 waypoint: 200,80
    %% e0 labelPlacement: above
    %% e0 color: #ff0000
    %% e0 fromSide: right
    %% e0 toSide: left
    %% e0 lineShape: orthogonal
    %% e0 collapsed: true
    a -.-> c["C"]
    %% e1 lineShape: straight
`;
  const { doc, extras } = parseMermaidBody(body);

  it('alla kant-nycklar läses per index (waypoints ackumuleras i ordning)', () => {
    expect(doc.edges[0]).toMatchObject({
      waypoints: [{ x: 100, y: 50 }, { x: 200, y: 80 }],
      labelPlacement: 'above',
      colorHex: '#ff0000',
      fromSide: 'right',
      toSide: 'left',
      lineShape: 'orthogonal',
    });
    expect(doc.edges[1]!.lineShape).toBe('straight');
    expect(doc.edges[1]!.labelPlacement).toBe('below');
  });

  it('kollaps per gren via %% e<i> collapsed', () => {
    expect(extras.collapsedEdgeIds.has(doc.edges[0]!.id)).toBe(true);
    expect(extras.collapsedEdgeIds.has(doc.edges[1]!.id)).toBe(false);
  });

  it('legacy nod-kollaps (%% <id> collapsed) migreras till alla utgående grenar', () => {
    const r = parseMermaidBody(
      'flowchart TD\n    c1["Rot"] --> c2["Barn"]\n    c1 --> c3["Barn2"]\n    c4["Annan"] --> c1\n    %% c1 collapsed\n');
    expect(r.extras.collapsedEdgeIds.has(r.doc.edges[0]!.id)).toBe(true);
    expect(r.extras.collapsedEdgeIds.has(r.doc.edges[1]!.id)).toBe(true);
    expect(r.extras.collapsedEdgeIds.has(r.doc.edges[2]!.id)).toBe(false);
  });
});

describe('subgraph → container + medlemskap', () => {
  const body = `flowchart TD
    ui_N0["Barn 1"]:::ui
    ui_N1["Barn 2"]:::ui
    subgraph skill_N9 ["Skill 1"]
        ui_N0
        ui_N1
    end
    %% skill_N9 container-pos: 400,300
    %% skill_N9 skill-nr: 2
    %% skill_N9 note: Grupp-notis
    subgraph zone_N2 [Ocitat etikett]
    end
    subgraph plain_N3
    end
`;
  const { doc } = parseMermaidBody(body);
  const byId = new Map(doc.shapes.map((s) => [s.id, s]));

  it('tre subgraph-varianter blir containrar (label ur ["…"], [..] eller = id)', () => {
    expect(byId.get('skill_N9')).toMatchObject({ type: 'container', label: 'Skill 1', category: 'skill' });
    expect(byId.get('zone_N2')).toMatchObject({ type: 'container', label: 'Ocitat etikett', category: 'zone' });
    expect(byId.get('plain_N3')).toMatchObject({ type: 'container', label: 'plain_N3', category: 'ui' });
  });

  it('container-pos + skill-nr + note läses på containern', () => {
    expect(byId.get('skill_N9')!.position).toEqual({ x: 400, y: 300 });
    expect(byId.get('skill_N9')!.skillNumber).toBe(2);
    expect(byId.get('skill_N9')!.note).toBe('Grupp-notis');
  });

  it('noder mellan subgraph…end blir containerns barn', () => {
    expect(byId.get('ui_N0')!.childOfContainerId).toBe('skill_N9');
    expect(byId.get('ui_N1')!.childOfContainerId).toBe('skill_N9');
    expect(byId.get('skill_N9')!.childOfContainerId).toBeUndefined();
  });
});

describe('nakna id:n och auto-layout', () => {
  it('id utan deklaration blir rektangel med id:t som text', () => {
    const { doc } = parseMermaidBody('flowchart TD\n    start --> slut\n');
    const byId = new Map(doc.shapes.map((s) => [s.id, s]));
    expect(byId.get('start')).toMatchObject({ type: 'rectangle', label: 'start', category: 'ui' });
    expect(byId.get('slut')).toMatchObject({ type: 'rectangle', label: 'slut' });
  });

  it('utan %% pos följer layouten flowchart-riktningen (LR = x växer)', () => {
    const { doc } = parseMermaidBody('flowchart LR\n    q0["A"] --> q1["B"]\n    q1 --> q2["C"]\n');
    const byId = new Map(doc.shapes.map((s) => [s.id, s]));
    expect(byId.get('q0')!.position).toEqual({ x: 200, y: 160 });
    expect(byId.get('q1')!.position).toEqual({ x: 370, y: 160 });
    expect(byId.get('q2')!.position).toEqual({ x: 540, y: 160 });
  });

  it('TD utan pos: y växer per nivå', () => {
    const { doc } = parseMermaidBody('flowchart TD\n    q0["A"] --> q1["B"]\n');
    const byId = new Map(doc.shapes.map((s) => [s.id, s]));
    expect(byId.get('q0')!.position).toEqual({ x: 200, y: 160 });
    expect(byId.get('q1')!.position).toEqual({ x: 200, y: 330 });
  });

  it('flow-fil utan explicit riktning auto-layoutas LR (v66)', () => {
    const body = 'flowchart\n    f0["A"] --> f1["B"]\n';
    const lr = parseMermaidBody(body, { specType: 'flow' });
    const byIdLr = new Map(lr.doc.shapes.map((s) => [s.id, s]));
    expect(byIdLr.get('f1')!.position).toEqual({ x: 370, y: 160 });
    const td = parseMermaidBody(body); // utan flow-spec → TD
    const byIdTd = new Map(td.doc.shapes.map((s) => [s.id, s]));
    expect(byIdTd.get('f1')!.position).toEqual({ x: 200, y: 330 });
  });
});

describe('canvas-nivå: canvas-size + legend', () => {
  const { extras } = parseMermaidBody(
    'flowchart TD\n    %% canvas-size: 800,600\n    a["A"]\n    %% legend ui: Betyder grej\n    %% legend skill: En skill\n');

  it('%% canvas-size → extras.canvasSize', () => {
    expect(extras.canvasSize).toEqual({ width: 800, height: 600 });
  });

  it('%% legend-rader → extras.legend', () => {
    expect(extras.legend).toEqual({ ui: 'Betyder grej', skill: 'En skill' });
  });

  it('utan raderna: canvasSize undefined + tom legend', () => {
    const r = parseMermaidBody('flowchart TD\n    a["A"]\n');
    expect(r.extras.canvasSize).toBeUndefined();
    expect(r.extras.legend).toEqual({});
  });
});

describe('robusthet', () => {
  it('init-direktivet (%%{…}) och style/classDef/linkStyle-rader stör inte', () => {
    const body = '%%{init: {"flowchart": {"curve": "basis"}}}%%\nflowchart TD\n'
      + '    a["A"]:::ui --> b["B"]:::ui\n'
      + '    style a font-size:28px,padding:16px\n'
      + '    linkStyle 0 interpolate linear\n'
      + '    classDef ui fill:#ffffff,stroke:#1e293b,color:#111827;\n';
    const { doc } = parseMermaidBody(body);
    expect(doc.shapes.map((s) => s.id).sort()).toEqual(['a', 'b']);
    expect(doc.edges).toHaveLength(1);
  });

  it('tom kropp ger tomt dokument', () => {
    const { doc } = parseMermaidBody('');
    expect(doc.shapes).toHaveLength(0);
    expect(doc.edges).toHaveLength(0);
  });

  it('pil-tecken inne i nod-text blir inte kanter (stripNodeBodies)', () => {
    const { doc } = parseMermaidBody('flowchart TD\n    a["x --> y"] --> b["B"]\n');
    expect(doc.edges).toHaveLength(1);
    expect(doc.edges[0]).toMatchObject({ from: 'a', to: 'b' });
    expect(doc.shapes.find((s) => s.id === 'a')!.label).toBe('x --> y');
  });
});
