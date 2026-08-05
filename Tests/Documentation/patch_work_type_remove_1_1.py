#!/usr/bin/env python3
from __future__ import annotations

import os
import re
from pathlib import Path

ROOT = Path.cwd()
EVIDENCE_URL = os.environ.get("EVIDENCE_URL", "")
DATE = "2026-08-05"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    (ROOT / path).write_text(content.rstrip() + "\n", encoding="utf-8", newline="\n")


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: erwartet genau einen Treffer, gefunden {count}: {old!r}")
    write(path, text.replace(old, new, 1))


write(
    "Documentation/Architecture/WORK_TYPE_MODULE_DESIGN.md",
    """# Work-Type-Katalog – Moduldesign

## Sicherheitsgrenze

`toolbelt.core.work-type` ist ein persistenter Katalog, aber kein allgemeiner SQL-Executor. Ein Work Type verweist ausschließlich auf eine vorhandene Stored Procedure derselben Datenbank. SQL-Text, Batch-Text, frei zusammengesetzte Commands und versteckte Raw-SQL-Optionen sind ausgeschlossen.

## Parametervertrag

Version 1 kennt nur `NONE` und `JSON_PAYLOAD`. Der JSON-Vertrag ist deklarative Metadaten. Eine spätere Ausführung darf daraus keine ungeprüfte dynamische Parameterliste erzeugen. Ein Session-Provider muss je Mode eine feste parametrisierte Aufrufoberfläche besitzen.

## Mutation und Concurrency

Registrierungen werden unter `UPDLOCK, HOLDLOCK` serialisiert. Exakte Wiederholungen verändern die Zeile nicht. Konfigurationsänderungen benötigen `@AllowUpdate`; Reaktivierung benötigt ein eigenes Flag. Optionales `@ExpectedRowVersion` schützt administrative Änderungen vor Lost Updates.

Version `1.1.0` ergänzt eine bewusst getrennte Removal-Operation. Ein Work Type muss zuerst deaktiviert werden. Die eigentliche Entfernung benötigt `@AllowDelete = 1` und kann zusätzlich mit der erwarteten `rowversion` abgesichert werden. Dadurch bleibt die normale Deaktivierung reversibel, während die irreversible Löschung weder versehentlich noch auf einer veralteten Katalogsicht erfolgt.

## Transaktionsvertrag

Register, Disable und Remove verwenden eine eigene Transaktion oder bei vorhandener Caller-Transaktion einen Modul-Savepoint. Erwartete Fehler rollen nur die jeweilige Modulmutation zurück. Eine Katalogmutation bei `XACT_STATE() = -1` ist nicht möglich; `USP_RemoveWorkType` lehnt diesen Zustand vor der ersten Mutation ab.

## Persistenz und Lifecycle

Die interne Tabelle `toolbelt_core.WorkType` bleibt bei Redeploy erhalten. Uninstall mit vorhandenen Zeilen benötigt `AllowDataLoss = 1`. Zentrale Installation registriert ausschließlich Handler in der zentralen Toolbelt-Datenbank.

Modulabhängige Capabilities dürfen ihren eigenen Work Type beim Uninstall nur über den öffentlichen Ablauf Disable → Remove abbauen. Direkte DML auf `toolbelt_core.WorkType` bleibt außerhalb des öffentlichen Vertrags.

## Berechtigungen

Das Modul erweitert keine Rechte. Registrierung verlangt, dass der aufrufende Principal die Zielprocedure ausführen darf. Rechte für einen Second-Session- oder Worker-Provider werden separat entschieden und nicht aus der Registrierung abgeleitet.
""",
)

changelog = read("CHANGELOG.md")
entry = f"""## {DATE} – Work-Type-Katalog 1.1.0

- `toolbelt.core.work-type` um `toolbelt_core.USP_RemoveWorkType` erweitert.
- Entfernung ist nur nach Disable, mit `@AllowDelete = 1` und optionaler `rowversion`-Prüfung zulässig.
- Savepoint-, uncommittable-Caller-, ResultTable- und Lifecycle-Verträge werden capabilitybezogen getestet.

"""
if entry.strip() not in changelog:
    marker = "# CHANGELOG\n\n"
    if changelog.count(marker) != 1:
        raise RuntimeError("CHANGELOG-Einfügemarke ist nicht eindeutig.")
    write("CHANGELOG.md", changelog.replace(marker, marker + entry, 1))

plan = read("Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md")
plan = plan.replace(
    "`toolbelt_core.USP_RegisterWorkType`, `USP_DisableWorkType`, `USP_ResolveWorkType`, `VW_WorkTypes`",
    "`toolbelt_core.USP_RegisterWorkType`, `USP_DisableWorkType`, `USP_RemoveWorkType`, `USP_ResolveWorkType`, `VW_WorkTypes`",
)
write("Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md", plan)

candidate_path = "Backlog/TOOLBELT_CANDIDATES.md"
candidates = read(candidate_path)
pattern = r"(^## TC-2026-022:.*?)(?=^## TC-|\Z)"
match = re.search(pattern, candidates, flags=re.MULTILINE | re.DOTALL)
if match is None:
    raise RuntimeError("TC-2026-022 fehlt.")
section = match.group(1)
section = re.sub(
    r"^\| \*\*Mögliche Technologie\*\* \|.*$",
    "| **Mögliche Technologie** | Implementiert als persistenter T-SQL-Katalog `toolbelt.core.work-type`. Version `1.1.0` ergänzt die kontrollierte Entfernung deaktivierter Work Types über `USP_RemoveWorkType`; Raw SQL bleibt ausgeschlossen. |",
    section,
    count=1,
    flags=re.MULTILINE,
)
section = re.sub(
    r"^\| \*\*Nächster Schritt\*\* \|.*$",
    "| **Nächster Schritt** | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; abhängige Module verwenden für ihren Lifecycle Disable → Remove statt direkter Katalog-DML. |",
    section,
    count=1,
    flags=re.MULTILINE,
)
write(candidate_path, candidates[: match.start()] + section + candidates[match.end() :])

if EVIDENCE_URL:
    manifest_path = "Modules/toolbelt.core.work-type/module.yaml"
    manifest = read(manifest_path)
    if EVIDENCE_URL not in manifest:
        manifest += f"""  - date: \"{DATE}\"
    workflow: \"{EVIDENCE_URL}\"
    scope: \"SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170; Removal-Freigabe, Disable-Pflicht, RowVersion, Caller-Savepoint, uncommittable Caller, ResultTable und Lifecycle\"
    result: \"success\"
"""
        write(manifest_path, manifest)

    module_readme_path = "Modules/toolbelt.core.work-type/README.md"
    module_readme = read(module_readme_path)
    if EVIDENCE_URL not in module_readme:
        module_readme += f"\nRemoval-Evidenz Version `1.1.0`: {EVIDENCE_URL}\n"
        write(module_readme_path, module_readme)

    evidence_path = "Modules/toolbelt.core.work-type/Tests/README.md"
    evidence = read(evidence_path)
    evidence = evidence.replace(
        "Die konkrete Run-ID wird erst nach erfolgreicher Ausführung ergänzt.",
        f"Die capabilitybezogene Runtime-Matrix ist erfolgreich. Evidenz: {EVIDENCE_URL}",
    )
    write(evidence_path, evidence)

    matrix_path = "Modules/toolbelt.core.work-type/Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md"
    matrix = read(matrix_path)
    matrix = matrix.replace(
        "Removal-Version `1.1.0`: Evidenz wird mit dem capabilitybezogenen W4b-Runtime-Lauf ergänzt.",
        f"Removal-Version `1.1.0`: SQL Server 2025 Linux CL150/160/170 erfolgreich; Evidenz {EVIDENCE_URL}",
    )
    write(matrix_path, matrix)

    tests_path = "Tests/README.md"
    tests = read(tests_path)
    tests = re.sub(
        r"^\| `toolbelt\.core\.work-type` \|.*$",
        f"| `toolbelt.core.work-type` | [WORK_TYPE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.work-type/Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md) | `partially validated`; Version 1.1.0 einschließlich kontrollierter Removal-Capability auf SQL Server 2025 Linux CL150/160/170, Evidenz {EVIDENCE_URL} |",
        tests,
        count=1,
        flags=re.MULTILINE,
    )
    write(tests_path, tests)

print("Work-Type-1.1-Dokumentationskopplung: erfolgreich")
