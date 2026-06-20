import Foundation
import CoreGraphics
import CoreTransferable

/// v37: textjustering per form. Lagras som sträng-enum (Foundation-only, ej SwiftUI-beroende).
enum TextAlignMode: String, Codable, CaseIterable {
    case leading
    case center
    case trailing
}

enum ShapeType: String, Codable, CaseIterable {
    case circle
    case rectangle
    case diamond
    case table
    case link
    /// v31: avlång rektangel med fullständigt rundade ändar (Capsule).
    case pill
    /// v31: lös linje utan form-koppling. Endpoints i `lineEnd` (relativ position från center).
    case line
    /// v31: lös pil — som line med pilhuvud på linjeslutet.
    case arrow
    // v35.1/v36: grundformer
    /// Liksidig kvadrat med rundade hörn.
    case square
    /// Processsteg-pil (pentagon) — rektangel med spetsig högerände. Kan ha label.
    case processArrow
    /// v44: container — grupperande rektangel (Mermaid subgraph). Andra former kan vara inuti.
    case container
    /// v51.1: åttahörning (octagon) med rundade hörn.
    case octagon
    /// v67: iPhone 16 Pro-skärmram — en telefon-bezel att bygga UI ovanpå.
    case phoneFrame
    /// v68: liksidig trekant.
    case triangle
    /// v69: cylinder (databas/bevis) — native mermaid `[(...)]`.
    case cylinder
    /// v1.0: naken emoji — bara glyfen (ingen ruta). Label = emoji-tecknet; byts fritt.
    case emoji
}

extension ShapeType {
    /// Steg 9: former som ÄGER sitt innehåll — barn får `childOfContainerId`, följer
    /// med vid flytt och claim/assign-logiken gäller. container = Mermaid subgraph;
    /// phoneFrame = UI-skärm som logiskt äger sina element.
    var actsAsContainer: Bool {
        self == .container || self == .phoneFrame
    }
}

extension ShapeType: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { $0.rawValue }
    }
}

struct ShapeNode: Identifiable, Codable, Equatable {
    let id: UUID
    var type: ShapeType
    var position: CGPoint
    var label: String
    var showLabel: Bool
    /// Behålls för bakåtkompatibilitet — används om widthMultiplier/heightMultiplier saknas.
    var sizeMultiplier: CGFloat
    /// v31: separat bredd-skalning (för fri resize). Default = sizeMultiplier vid läsning.
    var widthMultiplier: CGFloat?
    /// v31: separat höjd-skalning.
    var heightMultiplier: CGFloat?
    var note: String
    /// v60: prompt-text för n8n-flöden. Följer med i Mermaid-exporten (%% <id> prompt: ...)
    /// så hela flödet kan kopieras som en körbar spec. Round-trippar via state-JSON.
    var prompt: String
    var category: ShapeCategory
    var rotation: CGFloat
    /// v19: överskrid FYLLNINGS-färg per form. Hex-sträng "#rrggbb" eller nil = paket/kategori.
    /// (v62: påverkar nu även renderingen i appen, inte bara Mermaid-exporten.)
    var colorOverride: String?
    /// v62: överskrid RAM-färg (stroke) separat. nil = paket/kategori som vanligt.
    var strokeColorOverride: String?
    /// v19: jump-link parnummer. nil för icke-link-former.
    var linkNumber: Int?
    /// v74: kedje-ordningsnummer för skill-containrar ("Skill 2"). nil för allt annat.
    var skillNumber: Int?
    /// v19: tabell-rader (för type=.table). nil = default 3.
    var tableRows: Int?
    /// v19: tabell-kolumner (för type=.table). nil = default 3.
    var tableCols: Int?
    /// v41: cellinnehåll i tabellen. Indexeras [rad][kolumn]. nil = tom.
    var tableCells: [[String]]?
    /// v23: textstil för label (Rubrik 1/2/3 eller brödtext).
    var textStyle: TextStyle
    /// v23: färg-paket-id (ColorPack.id) eller nil = ingen färg = vit + kategori-ram.
    var colorPackId: String?
    /// v31: endpoint för lösa linjer/pilar (relativ från `position`). nil för icke-line.
    var lineEnd: CGPoint?
    /// v37: textjustering (L/C/R) per form. Default = .center.
    var textAlignment: TextAlignMode
    /// v37: visa text med • per rad. Default = false.
    var hasBullets: Bool
    /// v39: visa text med 1. 2. 3. per rad. Default = false.
    var hasNumberedList: Bool
    /// v39: indragsnivå (0 = ingen, 1 = ett steg, 2 = två steg). Default = 0.
    var indentLevel: Int
    /// v47: explicit referens till container-förälder. Ersätter position-baserad
    /// detektering i `CanvasModel.shapesInside(container:)`. nil = inte i någon container.
    /// Sätts automatiskt vid drag-slut och vid drag-ut. Position-baserad detektering
    /// behålls som fallback för bakåtkompatibilitet.
    var childOfContainerId: UUID?
    /// V79-svep: låst form — kan inte flyttas/storleksändras (hänglås). Default false.
    var locked: Bool = false
    /// V79-svep: lager-ordning (-1 underst · 0 mellan · 1 överst) för UI-bygge. Default 0.
    var zLayer: Int = 0
    /// v1.0+ Visio "hoppa in": ägt underflöde (nästlad canvas). nil = vanlig form.
    var subCanvas: SubCanvas? = nil

    init(id: UUID = UUID(),
         type: ShapeType,
         position: CGPoint,
         label: String = "",
         showLabel: Bool = true,
         sizeMultiplier: CGFloat = 1.0,
         widthMultiplier: CGFloat? = nil,
         heightMultiplier: CGFloat? = nil,
         note: String = "",
         prompt: String = "",
         category: ShapeCategory = .ui,
         rotation: CGFloat = 0,
         colorOverride: String? = nil,
         strokeColorOverride: String? = nil,
         linkNumber: Int? = nil,
         skillNumber: Int? = nil,
         tableRows: Int? = nil,
         tableCols: Int? = nil,
         tableCells: [[String]]? = nil,
         textStyle: TextStyle = .body,
         colorPackId: String? = nil,
         lineEnd: CGPoint? = nil,
         textAlignment: TextAlignMode = .center,
         hasBullets: Bool = false,
         hasNumberedList: Bool = false,
         indentLevel: Int = 0,
         childOfContainerId: UUID? = nil,
         locked: Bool = false,
         zLayer: Int = 0,
         subCanvas: SubCanvas? = nil) {
        self.id = id
        self.type = type
        self.position = position
        self.label = label
        self.showLabel = showLabel
        self.sizeMultiplier = sizeMultiplier
        self.widthMultiplier = widthMultiplier
        self.heightMultiplier = heightMultiplier
        self.note = note
        self.prompt = prompt
        self.category = category
        self.rotation = rotation
        self.colorOverride = colorOverride
        self.strokeColorOverride = strokeColorOverride
        self.linkNumber = linkNumber
        self.skillNumber = skillNumber
        self.tableRows = tableRows
        self.tableCols = tableCols
        self.tableCells = tableCells
        self.textStyle = textStyle
        self.colorPackId = colorPackId
        self.lineEnd = lineEnd
        self.textAlignment = textAlignment
        self.hasBullets = hasBullets
        self.hasNumberedList = hasNumberedList
        self.indentLevel = indentLevel
        self.childOfContainerId = childOfContainerId
        self.locked = locked
        self.zLayer = zLayer
        self.subCanvas = subCanvas
    }

    /// v31: effective width-multiplier (fallback till sizeMultiplier).
    var effectiveWidth: CGFloat { widthMultiplier ?? sizeMultiplier }
    /// v31: effective height-multiplier (fallback till sizeMultiplier).
    var effectiveHeight: CGFloat { heightMultiplier ?? sizeMultiplier }

    /// Steg 8: bär formen en prompt? Bara skill-flöde-former (.flow-kategorier) +
    /// containrar. Basformer (UI/zon/overlay) har inget prompt-fält. Styr både
    /// redigerings-sektionen och prompt-badgen.
    var carriesPrompt: Bool { type == .container || category.specType == .flow }
}

// MARK: - Bakåtkompatibel Decodable

extension ShapeNode {
    private enum CodingKeys: String, CodingKey {
        case id, type, position, label, showLabel, sizeMultiplier
        case widthMultiplier, heightMultiplier, note, prompt, category, rotation
        case colorOverride, strokeColorOverride, linkNumber, tableRows, tableCols, tableCells, textStyle
        case skillNumber  // v74
        case colorPackId, lineEnd, textAlignment, hasBullets
        case hasNumberedList, indentLevel
        case childOfContainerId  // v47
        case locked, zLayer  // V79-svep
        case subCanvas  // v1.0+ Visio
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self, forKey: .id)
        // v44: .text borttaget — migrera gamla JSON-filer som har type:"text" till .rectangle
        let rawType = try c.decode(String.self, forKey: .type)
        if let t = ShapeType(rawValue: rawType) {
            type = t
        } else if rawType == "text" {
            type = .rectangle
        } else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: c,
                                                   debugDescription: "Okänd ShapeType: \(rawType)")
        }
        position        = try c.decode(CGPoint.self, forKey: .position)
        label           = try c.decode(String.self, forKey: .label)
        showLabel       = try c.decodeIfPresent(Bool.self, forKey: .showLabel) ?? true
        sizeMultiplier  = try c.decodeIfPresent(CGFloat.self, forKey: .sizeMultiplier) ?? 1.0
        widthMultiplier = try c.decodeIfPresent(CGFloat.self, forKey: .widthMultiplier)
        heightMultiplier = try c.decodeIfPresent(CGFloat.self, forKey: .heightMultiplier)
        note            = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        prompt          = try c.decodeIfPresent(String.self, forKey: .prompt) ?? ""
        category        = try c.decodeIfPresent(ShapeCategory.self, forKey: .category) ?? .ui
        rotation        = try c.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0
        colorOverride   = try c.decodeIfPresent(String.self, forKey: .colorOverride)
        strokeColorOverride = try c.decodeIfPresent(String.self, forKey: .strokeColorOverride)  // v62
        linkNumber      = try c.decodeIfPresent(Int.self, forKey: .linkNumber)
        skillNumber     = try c.decodeIfPresent(Int.self, forKey: .skillNumber)  // v74
        tableRows       = try c.decodeIfPresent(Int.self, forKey: .tableRows)
        tableCols       = try c.decodeIfPresent(Int.self, forKey: .tableCols)
        tableCells      = try c.decodeIfPresent([[String]].self, forKey: .tableCells)
        textStyle       = try c.decodeIfPresent(TextStyle.self, forKey: .textStyle) ?? .body
        colorPackId     = try c.decodeIfPresent(String.self, forKey: .colorPackId)
        lineEnd         = try c.decodeIfPresent(CGPoint.self, forKey: .lineEnd)
        textAlignment   = try c.decodeIfPresent(TextAlignMode.self, forKey: .textAlignment) ?? .center
        hasBullets      = try c.decodeIfPresent(Bool.self, forKey: .hasBullets) ?? false
        hasNumberedList = try c.decodeIfPresent(Bool.self, forKey: .hasNumberedList) ?? false
        indentLevel     = try c.decodeIfPresent(Int.self, forKey: .indentLevel) ?? 0
        childOfContainerId = try c.decodeIfPresent(UUID.self, forKey: .childOfContainerId)
        locked          = try c.decodeIfPresent(Bool.self, forKey: .locked) ?? false
        zLayer          = try c.decodeIfPresent(Int.self, forKey: .zLayer) ?? 0
        subCanvas       = try c.decodeIfPresent(SubCanvas.self, forKey: .subCanvas)  // v1.0+ Visio
    }
}
