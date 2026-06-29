#!/usr/bin/env python3
"""arch-check.py — maskinellt tvingad arkitektur för MermaidCanvas (MA spår B).

Kontrollerar de mätbara reglerna i ARKITEKTUR-REGLER.md och returnerar exit 1 vid
brott. Statiskt och snabbt (läser kod, kör inget bygge) — tänkt att sitta på varje
commit via scripts/hooks/pre-commit.

Lägen:
  (inget)            R1-R5 + version-sync (statiskt, <1 s). Default för pre-commit.
  --appstore         App Store-checklista (AS1-AS9), rapport.
  --lower-baseline   sänk filstorlekstaket i arch-baseline.json till nuvarande rader
                     (bara LÄGRE, aldrig högre). Körs vid milstolpe när filer krympt.

Round-trip-testerna (canvas → mermaid → canvas) är en SEPARAT deploy-grind som körs
med `xcodebuild test` — inte här (de kräver simulator och vore för långsamma i en
pre-commit). Se ARKITEKTUR-REGLER.md.
"""
import json
import plistlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "app" / "MermaidCanvas"
SRC = APP / "Sources"
BASELINE_PATH = ROOT / "scripts" / "arch-baseline.json"
REPORT_PATH = ROOT / "scripts" / "arch-report.md"

errors: list[str] = []
warnings: list[str] = []


def load_baseline() -> dict:
    return json.loads(BASELINE_PATH.read_text())


def strip_code(text: str) -> str:
    """Ta bort // -kommentarer, /* */ -block och stränglitteraler så regex inte
    träffar i kommentarer eller text. Grovt men tillräckligt för lager-kontroll."""
    # blockkommentarer
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.DOTALL)
    out = []
    for line in text.splitlines():
        line = re.sub(r"//.*$", "", line)            # radkommentar
        line = re.sub(r'"(?:\\.|[^"\\])*"', '""', line)  # stränginnehåll
        out.append(line)
    return "\n".join(out)


def swift_files() -> list[Path]:
    return sorted(SRC.rglob("*.swift"))


def rel(p: Path) -> str:
    return str(p.relative_to(ROOT))


# ---- (R5) Filstorlek + ratchet -------------------------------------------------

def check_file_sizes(baseline: dict):
    limits = baseline["file_line_limits"]
    new_limit = baseline["new_file_limit"]
    for f in swift_files():
        r = rel(f)
        n = len(f.read_text().splitlines())
        cap = limits.get(r, new_limit)
        if n > cap:
            if r in limits:
                errors.append(f"R5 filstorlek: {r} har {n} rader > tak {cap}. "
                              f"Bryt ut kod — jättefiler får bara krympa.")
            else:
                errors.append(f"R5 filstorlek: {r} har {n} rader > {new_limit} (gräns för nya filer). "
                              f"Dela upp i mindre filer.")
        elif r in limits and n < cap:
            warnings.append(f"ratchet: {r} krympte till {n} (tak {cap}). "
                            f"Kör scripts/arch-check.py --lower-baseline vid milstolpe.")


# ---- (R1/R2/R6b) Beroenderiktning ----------------------------------------------

def check_layering(baseline: dict):
    # R1: Mermaid-lagret rör aldrig UI.
    for f in (SRC / "Mermaid").rglob("*.swift"):
        code = strip_code(f.read_text())
        if re.search(r"^\s*import\s+(SwiftUI|UIKit)\b", code, re.MULTILINE):
            errors.append(f"R1: {rel(f)} importerar SwiftUI/UIKit. "
                          f"Mermaid-lagret (översättning till/från text) måste vara fritt från UI.")

    models_dir = SRC / "App" / "Models"
    allowed = set(baseline.get("swiftui_import_allowed_in_models", []))
    view_patterns = [
        (r"\bvar\s+body\s*:", "var body"),
        (r":\s*View\b", ": View"),
        (r"\bsome\s+View\b", "some View"),
        (r"@State\b", "@State"),
        (r"@Binding\b", "@Binding"),
        (r"@ViewBuilder\b", "@ViewBuilder"),
    ]
    for f in models_dir.rglob("*.swift"):
        code = strip_code(f.read_text())
        # R2: Model-lagret ritar aldrig.
        for pat, name in view_patterns:
            if re.search(pat, code):
                errors.append(f"R2: {rel(f)} innehåller UI-konstruktionen '{name}'. "
                              f"Modellen är hjärnan, inte ögat — flytta UI till en View.")
        # R6b: ny SwiftUI-import i Models bara i whitelistade filer.
        if re.search(r"^\s*import\s+SwiftUI\b", code, re.MULTILINE) and f.name not in allowed:
            errors.append(f"R6b: {rel(f)} importerar SwiftUI men är inte whitelistad. "
                          f"Nya Model-filer ska vara rena value-typer/logik utan SwiftUI.")


# ---- (R4) Inga otäcka kraschpunkter i Model+Mermaid ----------------------------

def check_crash_points():
    targets = list((SRC / "App" / "Models").rglob("*.swift")) + list((SRC / "Mermaid").rglob("*.swift"))
    patterns = [(r"\bfatalError\s*\(", "fatalError("), (r"\btry!", "try!"), (r"\bas!\s", "as!")]
    for f in targets:
        code = strip_code(f.read_text())
        for pat, name in patterns:
            hits = len(re.findall(pat, code))
            if hits:
                errors.append(f"R4: {rel(f)} har {hits}×'{name}'. "
                              f"En krasch i modellen/parsern kan tappa en ritning — baslinjen är 0.")


# ---- (version-sync) AppVersion ↔ project.yml ↔ Info.plist ----------------------

def check_version_sync():
    # EN enda version (Kims order): AppVersion.version driver BÅDE MARKETING_VERSION och
    # CURRENT_PROJECT_VERSION — inget separat bygg-räknar-nummer.
    av = (SRC / "App" / "AppVersion.swift").read_text()
    m = re.search(r'\bversion\s*:\s*String\s*=\s*"([^"]+)"', av)
    if not m:
        errors.append("version: hittar inte AppVersion.version = \"X.Y\" i AppVersion.swift.")
        return
    v = m.group(1)

    proj = (APP / "project.yml").read_text()
    pm = re.search(r'MARKETING_VERSION:\s*"([^"]+)"', proj)
    pb = re.search(r'CURRENT_PROJECT_VERSION:\s*"([^"]+)"', proj)
    if not pm or pm.group(1) != v:
        errors.append(f"version: project.yml MARKETING_VERSION = "
                      f"{pm.group(1) if pm else 'saknas'}, väntat {v} (= AppVersion.version).")
    if not pb or pb.group(1) != v:
        errors.append(f"version: project.yml CURRENT_PROJECT_VERSION = "
                      f"{pb.group(1) if pb else 'saknas'}, väntat {v} (= AppVersion.version, EN version).")

    plist = (SRC / "App" / "Info.plist").read_text()
    short = re.search(r"<key>CFBundleShortVersionString</key>\s*<string>([^<]*)</string>", plist)
    if short and short.group(1) not in ("$(MARKETING_VERSION)", v):
        warnings.append(f"version: Info.plist CFBundleShortVersionString = '{short.group(1)}' "
                        f"(bör vara $(MARKETING_VERSION) så det finns EN källa).")


# ---- (Mac-deploy-drift) skyddsnät, icke-blockerande ----------------------------

def check_mac_deploy_drift():
    """Hål 1-skyddsnät: om Mac-appen är installerad i /Applications men dess version
    inte matchar AppVersion → VARNA. Icke-blockerande: en dev-maskin kan legitimt vara
    odeployad, och man committar innan man deployar. Den HÅRDA grinden är
    scripts/deploy-mac.sh (vid deploy). Det här gör bara drift synlig vid nästa commit
    så Mac-appen aldrig mer tyst halkar efter iPhone (lärdomen: var 1.0 vs iPhone 1.5.1)."""
    m = re.search(r'\bversion\s*:\s*String\s*=\s*"([^"]+)"',
                  (SRC / "App" / "AppVersion.swift").read_text())
    if not m:
        return
    v = m.group(1)
    installed_plist = Path("/Applications/Visuali2e.app/Contents/Info.plist")
    if not installed_plist.exists():
        return
    try:
        installed = plistlib.loads(installed_plist.read_bytes()).get("CFBundleShortVersionString")
    except Exception:
        return
    if installed and installed != v:
        warnings.append(
            f"Mac-deploy-drift: /Applications/Visuali2e.app är {installed}, men AppVersion "
            f"är {v}. Kör scripts/deploy-mac.sh så Mac-appen inte halkar efter iPhone.")


# ---- App Store-checklista ------------------------------------------------------

def run_appstore():
    rows = []

    def add(code, ok, label, detail=""):
        rows.append((code, ok, label, detail))

    privacy = list(APP.rglob("PrivacyInfo.xcprivacy"))
    add("AS1", bool(privacy), "Privacy manifest (PrivacyInfo.xcprivacy)",
        "" if privacy else "SAKNAS — krävs för App Store.")

    before = len(errors)
    check_version_sync()
    add("AS2", len(errors) == before, "Version-sync AppVersion↔project.yml↔Info.plist")

    icon = APP / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json"
    add("AS4", icon.exists(), "App-ikon (AppIcon.appiconset)")

    plist = (SRC / "App" / "Info.plist").read_text()
    add("AS5", "UILaunchScreen" in plist, "Launch screen")
    add("AS8", "ITSAppUsesNonExemptEncryption" in plist, "Encryption-deklaration",
        "" if "ITSAppUsesNonExemptEncryption" in plist else "saknas — App Store Connect frågar varje gång.")

    proj = (APP / "project.yml").read_text()
    add("AS6", "com.kimlundqvist.mermaidcanvas" in proj and "SFXR8MV6MP" in proj,
        "Bundle-ID + Team")

    lines = ["# App Store-gate", ""]
    hard_fail = False
    for code, ok, label, detail in rows:
        mark = "✅" if ok else "❌"
        if not ok and code in ("AS1", "AS2", "AS4", "AS5"):
            hard_fail = True
        lines.append(f"- {mark} **{code}** {label}{(' — ' + detail) if detail else ''}")
    lines.append("")
    lines.append("Hård (avvisas utan): AS1, AS2, AS4, AS5. Övriga = bör fixas.")
    REPORT_PATH.write_text("\n".join(lines))
    print("\n".join(lines))
    return 1 if hard_fail else 0


# ---- lower-baseline ------------------------------------------------------------

def lower_baseline():
    baseline = load_baseline()
    limits = baseline["file_line_limits"]
    changed = []
    for r in list(limits.keys()):
        p = ROOT / r
        if not p.exists():
            continue
        n = len(p.read_text().splitlines())
        if n < limits[r]:
            changed.append(f"{r}: {limits[r]} → {n}")
            limits[r] = n
    BASELINE_PATH.write_text(json.dumps(baseline, indent=2, ensure_ascii=False) + "\n")
    if changed:
        print("Sänkte tak:\n  " + "\n  ".join(changed))
    else:
        print("Inga tak att sänka — allt redan på sin lägsta nivå.")
    return 0


# ---- main ----------------------------------------------------------------------

def write_report():
    lines = ["# arch-check rapport", ""]
    if errors:
        lines.append(f"## ❌ {len(errors)} regelbrott")
        lines += [f"- {e}" for e in errors]
    else:
        lines.append("## ✅ Inga regelbrott")
    if warnings:
        lines.append("")
        lines.append(f"## ⚠️ {len(warnings)} påminnelser")
        lines += [f"- {w}" for w in warnings]
    REPORT_PATH.write_text("\n".join(lines) + "\n")


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg == "--appstore":
        sys.exit(run_appstore())
    if arg == "--lower-baseline":
        sys.exit(lower_baseline())

    baseline = load_baseline()
    check_file_sizes(baseline)
    check_layering(baseline)
    check_crash_points()
    check_version_sync()
    check_mac_deploy_drift()
    write_report()

    for w in warnings:
        print(f"⚠️  {w}")
    if errors:
        for e in errors:
            print(f"❌ {e}")
        print(f"\narch-check: {len(errors)} regelbrott. Se scripts/arch-report.md.")
        sys.exit(1)
    print("✅ arch-check: alla arkitekturregler gröna.")
    sys.exit(0)


if __name__ == "__main__":
    main()
