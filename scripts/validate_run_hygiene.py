#!/usr/bin/env python3
"""Run-hygiene-validator för demo-skill-3 (steg 13).

Kontrollerar att varje körning under runs/<run_id>/ följer revisionshygienen:
manifest med alla fält, PASS/FAIL-regler, fillista, latest-pekare, ren rot,
och att gateutfallet stämmer med gap_analys.md.

Körning:  python3 scripts/validate_run_hygiene.py [sökväg till demo-skill-3]
Exit 0 = allt grönt. Exit 1 = minst ett fel. Skriver validation_report.md i mappen.
"""

import re
import sys
from pathlib import Path

DEFAULT_BASE = Path(
    "/Users/kim/Library/Mobile Documents/com~apple~CloudDocs/"
    "00000. Claude Code/1. Mermaid/demo-skill-3"
)

OBLIGATORISKA_FALT = ["run_id", "input", "status", "aktiv outputfil"]
OUTPUT_FILNAMN = {"resultat.md", "manual_review.md", "gap_analys.md",
                  "s1_research.md", "s2_research.md"}


def las_manifest(path: Path) -> dict:
    """Plocka ut fält, fillista och gate-rader ur ett run_manifest.md."""
    text = path.read_text(encoding="utf-8")
    m = {"_text": text, "filer": []}
    for falt in OBLIGATORISKA_FALT + ["gatevillkor", "gateutfall"]:
        tr = re.search(rf"^- {re.escape(falt)}:\s*(.+)$", text, re.MULTILINE)
        if tr:
            m[falt] = tr.group(1).strip()
    sektion = re.search(r"## Skapade filer\n(.*?)(\n##|\Z)", text, re.DOTALL)
    if sektion:
        for rad in sektion.group(1).splitlines():
            rad = rad.strip()
            if rad.startswith("- "):
                # ta bort kommentar inom parentes i slutet av raden
                m["filer"].append(re.sub(r"\s*\(.*\)\s*$", "", rad[2:]).strip())
    return m


def gate_fran_gap(gap_path: Path) -> tuple[str, int, int]:
    """Räkna BEKRÄFTAT/KONFLIKT i gap-tabellen → förväntat gateutfall."""
    bekraftat = konflikt = 0
    for rad in gap_path.read_text(encoding="utf-8").splitlines():
        if not rad.strip().startswith("|"):
            continue
        celler = [c.strip() for c in rad.strip().strip("|").split("|")]
        if not celler:
            continue
        status = celler[-1]
        if status == "BEKRÄFTAT":
            bekraftat += 1
        elif status == "KONFLIKT":
            konflikt += 1
    utfall = "PASS" if bekraftat >= 2 and konflikt == 0 else "FAIL"
    return utfall, bekraftat, konflikt


def validera_run(run_dir: Path, base: Path) -> list[str]:
    """Returnerar lista med fel (tom lista = grönt)."""
    fel = []
    manifest_path = run_dir / "run_manifest.md"
    if not manifest_path.exists():
        return [f"run_manifest.md saknas i {run_dir.name}"]
    m = las_manifest(manifest_path)

    status = m.get("status", "")
    # Arkiv-runs (före revisionssäkringen): kräver bara inaktiv-märkning.
    if status.startswith("ARKIV"):
        if "INGEN" not in m.get("aktiv outputfil", ""):
            fel.append(f"{run_dir.name}: arkiv-run måste ha aktiv outputfil: INGEN")
        return fel

    for falt in OBLIGATORISKA_FALT + ["gatevillkor", "gateutfall"]:
        if not m.get(falt):
            fel.append(f"{run_dir.name}: fältet '{falt}' saknas i manifestet")
    if not m["filer"]:
        fel.append(f"{run_dir.name}: 'Skapade filer'-listan saknas/tom")

    aktiv = m.get("aktiv outputfil", "")
    resultat = run_dir / "resultat.md"
    manual = run_dir / "manual_review.md"

    if status == "PASS":
        if aktiv != "resultat.md":
            fel.append(f"{run_dir.name}: PASS kräver aktiv outputfil resultat.md (är: {aktiv})")
        if not resultat.exists():
            fel.append(f"{run_dir.name}: PASS men resultat.md saknas")
        if aktiv == "manual_review.md":
            fel.append(f"{run_dir.name}: PASS får inte ha manual_review.md som aktiv output")
        if manual.exists() and "Scope-beslut" not in manual.read_text(encoding="utf-8"):
            fel.append(f"{run_dir.name}: PASS-run har manual_review.md utan 'Scope-beslut'-märkning")
    elif status == "FAIL":
        if aktiv != "manual_review.md":
            fel.append(f"{run_dir.name}: FAIL kräver aktiv outputfil manual_review.md (är: {aktiv})")
        if not manual.exists():
            fel.append(f"{run_dir.name}: FAIL men manual_review.md saknas")
        if aktiv == "resultat.md" or resultat.exists():
            fel.append(f"{run_dir.name}: FAIL-run får inte ha resultat.md")
    else:
        fel.append(f"{run_dir.name}: okänd status '{status}' (väntat PASS/FAIL/ARKIV)")

    for f in m["filer"]:
        if not (base / f).exists():
            fel.append(f"{run_dir.name}: listad fil saknas: {f}")

    gap = run_dir / "gap_analys.md"
    if gap.exists():
        forvantat, b, k = gate_fran_gap(gap)
        utfall = m.get("gateutfall", "")
        if not utfall.startswith(forvantat):
            fel.append(f"{run_dir.name}: gateutfall '{utfall}' stämmer inte med "
                       f"gap_analys.md ({b} BEKRÄFTAT, {k} KONFLIKT → {forvantat})")
        if status != forvantat:
            fel.append(f"{run_dir.name}: status {status} stämmer inte med gap_analys.md (→ {forvantat})")
    else:
        fel.append(f"{run_dir.name}: gap_analys.md saknas — gateutfallet kan inte verifieras")
    return fel


def main() -> int:
    base = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_BASE
    runs_dir = base / "runs"
    alla_fel = []
    rader = []

    run_dirs = sorted(d for d in runs_dir.iterdir() if d.is_dir()) if runs_dir.is_dir() else []
    if not run_dirs:
        alla_fel.append("inga runs hittades under runs/")

    riktiga = []  # runs med PASS/FAIL (inte arkiv)
    for d in run_dirs:
        fel = validera_run(d, base)
        alla_fel += fel
        mp = d / "run_manifest.md"
        status = las_manifest(mp).get("status", "?") if mp.exists() else "?"
        rader.append((d.name, status, fel))
        if mp.exists() and status in ("PASS", "FAIL"):
            riktiga.append(d.name)

    # latest/ måste finnas och peka på senaste riktiga run
    latest = base / "latest" / "run_manifest.md"
    if not latest.exists():
        alla_fel.append("latest/run_manifest.md saknas")
        rader.append(("latest", "?", ["saknas"]))
    else:
        lm = las_manifest(latest)
        senaste = max(riktiga) if riktiga else None
        fel_latest = []
        if senaste and lm.get("run_id") != senaste:
            fel_latest.append(f"latest pekar på '{lm.get('run_id')}', senaste run är '{senaste}'")
        if senaste and latest.read_text(encoding="utf-8") != (runs_dir / senaste / "run_manifest.md").read_text(encoding="utf-8"):
            fel_latest.append("latest/run_manifest.md är inte en kopia av senaste runs manifest")
        alla_fel += fel_latest
        rader.append(("latest", lm.get("status", "?"), fel_latest))

    # roten får inte innehålla aktiva outputfiler
    rotfel = [f"aktiv outputfil i roten: {f.name}"
              for f in base.iterdir() if f.is_file() and f.name in OUTPUT_FILNAMN]
    alla_fel += rotfel
    rader.append(("<roten>", "-", rotfel))

    # rapport
    ok = not alla_fel
    rapport = ["# Validation report — run-hygiene (demo-skill-3)", "",
               f"Validator: scripts/validate_run_hygiene.py · Totalstatus: {'PASS' if ok else 'FAIL'}", "",
               "| Kontrollerad | Status | Utfall |", "|---|---|---|"]
    for namn, status, fel in rader:
        rapport.append(f"| {namn} | {status} | {'PASS' if not fel else 'FAIL: ' + '; '.join(fel)} |")
    rapport += ["", "Kontroller per run: manifest finns · obligatoriska fält · PASS/FAIL-regler "
                "(aktiv outputfil + fil-existens) · fillistan stämmer · gateutfall mot gap_analys.md "
                "(PASS = ≥2 BEKRÄFTAT, 0 KONFLIKT). Globalt: latest-pekare · ren rot · arkiv inaktivt.", ""]
    (base / "validation_report.md").write_text("\n".join(rapport), encoding="utf-8")

    print("\n".join(f"FEL: {f}" for f in alla_fel) if alla_fel else "PASS — alla kontroller gröna")
    print(f"Rapport: {base / 'validation_report.md'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
