#!/usr/bin/env python3
"""Bereitet einen eingefrorenen Releasekandidaten vor; veröffentlicht nichts.

Die Moduldaten kommen aus den bestehenden Manifestlesern. Kanalvorschläge
werden transitiv über Dependencies begrenzt. Git archive liefert ausschließlich
versionierte Bytes; lokale Builds, Labdaten und Gitmetadaten bleiben draußen.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Tests/Documentation"))
import validate_documentation as documentation

VERSION = "1.0.0"
DIRECTORY = f"Releases/{VERSION}"
PLAN = f"{DIRECTORY}/release-plan.json"
MATRIX = f"{DIRECTORY}/FREIGABEMATRIX.md"
QUALIFICATION = f"{DIRECTORY}/qualification.json"
NAME = f"SQL-Server-Toolbelt-{VERSION}-candidate-source"
ARTIFACTS = f"{DIRECTORY}/Artifacts/"
CLR_PACKAGE = f"{DIRECTORY}/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip"
PRODUCT_SOURCE = f"{DIRECTORY}/product-source.json"
MAX_BYTES = 256 * 1024 * 1024
MAX_FILES = 10000

# Fachliche Restgates sind keine neue Runtimeabnahme. Die Hinweise begrenzen
# den Vorschlag und führen zur kanonischen, unveränderten Evidenz zurück.
PENDING = {
    "toolbelt.archive.zip-files": "ZIP-/NTFS-/Identitätsfälle und weitere Zielkombinationen vollständig zuordnen.",
    "toolbelt.archive.zip-memory": "SQL-LOB-Ceilings, relevante Kapazitätsgrenzen und jeweilige Reader-/Writer-Scopegrenzen prüfen.",
    "toolbelt.conversion.safe-cast": "Minimalrechte und harte Recovery separat; vollständige physische Fachmatrix seit 2026-10-19 belegt.",
    "toolbelt.core.execution-cancel": "Weitere Lifecycle-/Rechtekombinationen und harte Recovery außerhalb kooperativer Cancellation offen.",
    "toolbelt.core.work-queue": "Versionsgebundene Upgrade-/Lifecycle-/Recoveryabnahme und weitere Zielkombinationen prüfen.",
    "toolbelt.core.work-type": "Vollständigen Registry-/Rechte-/Upgrade-Scope der Version 1.2.0 abnehmen.",
    "toolbelt.core.worker-control": "Echten Committransportverlust, Recovery, Minimalrechte und weitere Workerhostkombinationen abnehmen.",
    "toolbelt.file.content": "Synthetische serverseitige Dateifixtures, Plattform-/Identitäts- und Rechtefälle gesondert bereitstellen und zuordnen.",
    "toolbelt.file.csv-memory": "Default-MaxValueBytes 16 MiB, globale Defaultzellgrenze, weitere Ziel-/Rechte-/Clientfälle separat abnehmen.",
    "toolbelt.file.xlsx-memory": "Raw-/Typ-/Anzeige-Scope, Genuine-Upgrades, weitere Ziele und Minimalrechte getrennt zuordnen.",
    "toolbelt.filesystem.windows": "Windows-/Identitäts-/NTFS-/Reparse-/Delete-/Rechtefälle; Linux bleibt außerhalb des Providers.",
    "toolbelt.json.constructors": "Core-Dependency, Constructor-/Upgrade-/CL-Scope und Minimalrechte gemeinsam abnehmen.",
    "toolbelt.json.core": "Gemeinsamen CLR-Core, Consumerclosure, Lifecycle und Rechte pro Supportkombination abnehmen.",
    "toolbelt.json.pointer": "Minimalrechte, Heap/Parallelität und harte Recovery separat; physische Full-Matrix seit 2026-10-19 belegt.",
    "toolbelt.json.schema": "Coreclosure, weitere Lifecycle-/Ziel-/Rechtekombinationen und Budgetgrenzen abnehmen.",
    "toolbelt.metadata.table-clone": "Planner, Executor und Copy gesondert prüfen; Parser-Upgrade ist keine aktuelle Gesamt-API-Abnahme.",
    "toolbelt.pseudonymization.deterministic": "Versionsgebundene Translate-/Geo-/UDT-Grenzen, weitere Ziele und Minimalrechte zuordnen.",
    "toolbelt.string.edit-distance": "Distanz-/Jaro-Scope, weitere physische Ziele, Minimalrechte und Kapazitätsgrenzen abnehmen.",
    "toolbelt.string.phonetic": "Vollständige Scannerabdeckung sowie native Ziel-/Rechte-/Lifecyclematrix abnehmen.",
    "toolbelt.string.regex": "Capture-/Replace-Grenzen, ältere Upgradepfade, große SQL-Ausgabe und Minimalrechte abnehmen.",
    "toolbelt.string.split-advanced": "Weitere Zielkombinationen und genaue Unquoting-/Split-Grenzen getrennt abnehmen.",
    "toolbelt.string.text-pairs": "Providerclosure, Paar-/Clientgrenzen, weitere Ziele und Minimalrechte abnehmen.",
    "toolbelt.tsql.script-parser": "Alle angebotenen nativen Parser-APIs, Ausgabeceilings und Minimalrechte vollständig zuordnen.",
    "toolbelt.tsql.ssis-debug": "Windows-Abnahme lokal/zentral belegt; Parserclosure, endgültige Rechte- und Releaseabnahme separat.",
}


class ReleaseError(ValueError):
    """Unvollständige oder widersprüchliche Releasevorbereitung."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReleaseError(message)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def encoded(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def git(*args: str, repository: Path | None = None, env: dict | None = None) -> bytes:
    result = subprocess.run(["git", "-C", str(repository or ROOT), *args],
                            capture_output=True, timeout=90, env=env)
    require(result.returncode == 0, "Git-Quellbindung fehlgeschlagen; kein Ersatzstand.")
    return result.stdout


def safe_path(name: str) -> None:
    p = PurePosixPath(name)
    require(bool(name) and not p.is_absolute() and "\\" not in name and ":" not in name,
            "Unsicherer Paketpfad.")
    require(all(part not in ("", ".", "..") and part == part.rstrip(" .") for part in name.split("/")),
            "Unsicheres Pfadsegment.")
    require(not any(part.casefold() in (".git", ".runtime", "__pycache__", "bin", "obj") for part in p.parts),
            "Lokale oder administrative Dateien im Paket.")
    require(not any(re.fullmatch(r"(?:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\..*)?", part, re.I)
                    for part in p.parts), "Reservierter Windows-Pfad.")
    require(p.suffix.lower() not in (".pfx", ".p12", ".pvk", ".snk", ".pdb", ".env")
            and p.name.lower() not in (".env", "secrets.json"), "Privater Input im Paket.")


def read_zip(data: bytes) -> dict[str, bytes]:
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        entries = archive.infolist()
        require(len(entries) <= MAX_FILES and sum(e.file_size for e in entries) <= MAX_BYTES,
                "Paketbudget überschritten.")
        names = [e.filename.rstrip("/") for e in entries]
        require(all(n == 1 for n in Counter(x.casefold() for x in names).values()), "Doppelte Paketpfade.")
        result = {}
        for entry in entries:
            safe_path(entry.filename.rstrip("/"))
            require(not stat.S_ISLNK(entry.external_attr >> 16), "Symlink im Paket.")
            require(not (entry.flag_bits & 1), "Verschlüsseltes Paketentry.")
            if not entry.is_dir():
                result[entry.filename] = archive.read(entry)
        return result


def snapshot(commit: str, repository: Path | None = None, env: dict | None = None) -> tuple[str, dict[str, bytes]]:
    resolved = git("rev-parse", "--verify", commit + "^{commit}", repository=repository, env=env).decode().strip()
    require(re.fullmatch(r"[0-9a-f]{40}", resolved) is not None, "Ungültiger Quellcommit.")
    files = read_zip(git("archive", "--format=zip", resolved, repository=repository, env=env))
    return resolved, {p: b for p, b in files.items() if not p.startswith(ARTIFACTS)}


def dependencies(text: str) -> list[str]:
    block = re.search(r"^dependencies:\s*([^\n]*)(?:\n((?:[ \t].*|\n)*))?", text, re.M)
    require(block is not None, "Dependencies fehlen.")
    return re.findall(r"module_id:\s*[\"']?(toolbelt\.[a-z0-9.-]+)", block.group(0))


def channels(modules: dict[str, dict]) -> dict[str, str]:
    def visit(mid: str, trail: set[str]) -> None:
        require(mid in modules, "Dependency fehlt.")
        require(mid not in trail, "Dependencyzyklus.")
        for dep in modules[mid]["dependencies"]:
            visit(dep, trail | {mid})
    for mid in modules:
        visit(mid, set())
    result = {mid: "stable" if m["validation_status"] == "validated" else "preview" for mid, m in modules.items()}
    while True:
        changed = False
        for mid, module in modules.items():
            if result[mid] == "stable" and any(result[d] != "stable" for d in module["dependencies"]):
                result[mid] = "preview"
                changed = True
        if not changed:
            return result


def make_plan(files: dict[str, bytes], product_commit: str) -> dict:
    modules = {}
    for path in sorted(p for p in files if re.fullmatch(r"Modules/[^/]+/module.yaml", p)):
        text = files[path].decode("utf-8-sig")
        mid = documentation.top_scalar(text, "module_id")
        prefix = f"Modules/{mid}/"
        require(path == prefix + "module.yaml" and mid not in modules, "Modulidentität widersprüchlich.")
        require(documentation.top_scalar(text, "release_status") == "unreleased", "Vorbereitung erwartet unveröffentlichte Module.")
        validation = documentation.top_scalar(text, "validation_status")
        require(validation in ("validated", "partially validated"), "Ungeprüfter Modulstatus.")
        references = [path, prefix + "README.md"]
        if prefix + "Tests/README.md" in files:
            references.append(prefix + "Tests/README.md")
        has_clr = any(p.startswith(prefix + "Clr/") and p.endswith(".csproj") for p in files)
        modules[mid] = {
            "module_id": mid, "module_version": documentation.top_scalar(text, "version"),
            "validation_status": validation, "current_release_status": "unreleased",
            "dependencies": dependencies(text),
            "declared_sql_versions": documentation.top_list(text, "sql_server_versions"),
            "manifest_sha256": sha(files[path]),
            "evidence_references": references,
            "binary_delivery": "source_and_build_scripts" if has_clr else "sql_sources",
            "pending_before_publication": PENDING.get(mid, "Vollständige bestehende Evidenz an den konkreten veröffentlichten Supportumfang binden."),
        }
    require(len(modules) == 45, "v1.0.0 erwartet genau den besprochenen Gesamtbestand von 45 Modulen.")
    proposed = channels(modules)
    for mid, module in modules.items():
        module["proposed_channel"] = proposed[mid]
        if module["validation_status"] == "validated" and proposed[mid] == "preview":
            module["pending_before_publication"] = "Transitive Preview-Dependency; Kanal bleibt bis zur gemeinsamen Freigabe Preview."
        if mid in ("toolbelt.tsql.script-parser", "toolbelt.tsql.ssis-debug"):
            module["binary_delivery"] = "qualified_ssis_install_zip_and_sources"
        if CLR_PACKAGE in files and module['binary_delivery'] != 'sql_sources':
            module['binary_delivery'] = 'prebuilt_clr_install_zip_and_sources'
    scope_path = f'{DIRECTORY}/support-scope.json'
    approved_scope = None
    if scope_path in files:
        approved_scope = json.loads(files[scope_path])
        require(approved_scope['state'] == 'approved_target_scope_not_published'
                and approved_scope['publication_authorized'] is False
                and approved_scope['preview_waives_required_tests'] is False
                and approved_scope['modules'] == 45
                and approved_scope['channels'] == dict(Counter(proposed.values()))
                and f'{DIRECTORY}/SUPPORT.md' in files, 'Supportfreigabe widersprüchlich.')
    plan = {
        "schema_version": "1.0", "project_version": VERSION,
        "state": "prepared_not_published", "publication_authorized": False,
        "product_commit": product_commit,
        "package_kind": "complete_source_candidate",
        "foundation": {"version": "1.25.0", "source_commit": "9e1b9974de58ea775d40c7c6045cd5057ba8b30c"},
        "channel_semantics": "Vorschläge für den Release-Review; keine Veröffentlichung und keine Aufwertung der Modulmanifeste.",
        "support_scope_review": "pending; deklarierte Zielversionen sind keine neue Supportzusage",
        "modules": list(modules.values()),
    }
    if approved_scope is not None:
        plan['approved_target_scope'] = approved_scope
        plan['channel_semantics'] = 'Zielkanäle ausdrücklich freigegeben; Pflichtqualifikation und öffentliche Veröffentlichung bleiben separat.'
        plan['support_scope_review'] = 'target_scope_approved; complete_per_combination_qualification_pending'
    if PRODUCT_SOURCE in files:
        product_source = json.loads(files[PRODUCT_SOURCE])
        require(product_source['product_commit'] == product_commit
                and product_source['kind'] == 'synthetic_product_snapshot'
                and all(re.fullmatch(r'[a-f0-9]{40}', product_source[k]) for k in
                        ('source_commit','product_commit','base_commit','tree_oid')), 'Produktprovenienz widersprüchlich.')
        plan['product_snapshot'] = product_source
    return plan


def matrix(plan: dict, module_page: str = "README.md") -> bytes:
    counts = Counter(m["proposed_channel"] for m in plan["modules"])
    lines = ["# Freigabematrix für v1.0.0", "",
             "Status: **Vorbereitung, nicht veröffentlicht**. Diese Tabelle wird aus `release-plan.json` und den Modulmanifesten erzeugt.", "",
             f"Alle 45 Module sind enthalten: **{counts['stable']} stabile Kandidaten, {counts['preview']} Preview-Kandidaten**. Alle Modulmanifeste bleiben `unreleased`.", "",
             "`stable` und `preview` sind vorgeschlagene Kanäle. Die konkrete Plattform-/Provider-/Deployment-/CL-Freigabe und deren vollständige Pflichtnachweise benötigen noch den fachlichen Release-Review. Preview ersetzt keine fehlende Pflichtprüfung im zugesagten Umfang.", "",
             "Second Session und Event Log bleiben trotz eigenem `validated` wegen der transitiven Preview-Dependency Work Type vorläufig Preview. Modulversionen bleiben unabhängig von der Projektversion 1.0.0.", "",
             "| Modul / Version | Vorschlag | Prüfstatus | Direkte Dependencies | Evidenz / offene Abnahme |",
             "|---|---|---|---|---|"]
    for m in plan["modules"]:
        mid = m["module_id"]
        ref = f"../../Modules/{mid}/{module_page}"
        evidence = next((p for p in reversed(m["evidence_references"]) if p.endswith("README.md")))
        deps = ", ".join(f"`{x}`" for x in m["dependencies"]) or "—"
        lines.append(f"| [`{mid}`]({ref}) {m['module_version']} | **{m['proposed_channel']}** | {m['validation_status']} | {deps} | [Nachweise](../../{evidence}); {m['pending_before_publication']} |")
    delivery = ("Die Spalte `binary_delivery` im [maschinenlesbaren Plan](release-plan.json) benennt die Lieferform. Das Gesamt-ZIP enthält zusätzlich den [vorgebauten CLR-Installationssatz](CLR-INSTALL.md): zwölf Toolbelt-DLLs, ScriptDom, Quellcode und fertige SQL-Dateien mit exakten Trustwerten. Die vier Profile erhalten Windows-/Portable- und lokale/zentrale Grenzen. Kein eigener Build für die Installation; fachliche Preview-/Releasegates bleiben separat."
                if any(m['binary_delivery'] == 'prebuilt_clr_install_zip_and_sources' for m in plan['modules']) else
                "Die Spalte `binary_delivery` im [maschinenlesbaren Plan](release-plan.json) benennt die Lieferform. Das Gesamt-ZIP ist ein Quellpaket. Der separat enthaltene SSIS-Installationssatz enthält bereits qualifizierte DLLs. Weitere CLR-Provider benötigen ihre dokumentierten Build-/Trustinputs; ein vollständiges vorgebautes CLR-Installationspaket wird hier nicht behauptet.")
    if 'approved_target_scope' in plan:
        lines[6] = ('Die Zielkanäle und der [Supportumfang](SUPPORT.md) sind ausdrücklich freigegeben. '
                    'Die konkrete öffentliche Supportzusage bleibt an vollständige Pflichtnachweise je Kombination gebunden. '
                    'Preview ersetzt keine fehlende Pflichtprüfung im zugesagten Umfang.')
        lines[10] = lines[10].replace('Vorschlag', 'Zielkanal')
    lines += ["", delivery, "",
              "Vor Veröffentlichung gelten die [offenen Releasegates](README.md#vor-einer-veröffentlichung) und der [kanonische Veröffentlichungsvertrag](../../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md#öffentlicher-veröffentlichungsnachweis).", ""]
    return "\n".join(lines).encode("utf-8")


def validate_plan(files: dict[str, bytes], plan: dict, product_files: dict[str, bytes] | None = None,
                  product_tree: str | None = None) -> None:
    require(re.fullmatch(r"[0-9a-f]{40}", plan.get("product_commit", "")) is not None, "Produktcommit fehlt.")
    require(plan == make_plan(files, plan["product_commit"]), "Releaseplan ist veraltet oder aufgewertet.")
    # Frühe unveröffentlichte Kandidaten führten beim Modulnamen zum Manifest.
    # Beide exakt erzeugten Lesepfade behalten dieselben gebundenen Fakten;
    # neue Pakete verwenden immer den direkt verständlichen README-Einstieg.
    require(files.get(MATRIX) in (matrix(plan), matrix(plan, "module.yaml")), "Freigabematrix ist veraltet.")
    receipt = json.loads(files[".ai/foundation/installation-provenance.json"])
    require(plan["foundation"] == {"version": receipt["ruleset_version"], "source_commit": receipt["source_commit"]},
            "Foundationbindung stimmt nicht.")
    if product_files is None:
        available = subprocess.run(['git','cat-file','-e',plan['product_commit']+'^{commit}'],
                                   cwd=ROOT, capture_output=True).returncode == 0
        if available:
            _, product_files = snapshot(plan['product_commit'])
            product_tree = git('rev-parse',plan['product_commit']+'^{tree}').decode().strip()
        else:
            require('product_snapshot' in plan, 'Produktbasis fehlt im Checkout.')
            archive = ROOT / ARTIFACTS / (NAME + '.zip')
            data = archive.read_bytes()
            require(archive.with_suffix('.zip.sha256').read_text(encoding='ascii').split() ==
                    [sha(data),archive.name], 'Produkt-Recoveryarchiv ist beschädigt.')
            raw = read_zip(data)
            prefix = NAME + '/'
            manifest = json.loads(raw[prefix+'PACKAGE-MANIFEST.json'])
            require(manifest['product_commit'] == plan['product_commit'], 'Recoveryprodukt stimmt nicht.')
            _, product_files, product_tree = recovered_snapshot(raw[prefix+'PREPARATION.bundle'],
                manifest['source_commit'], plan['product_commit'])
    if 'product_snapshot' in plan:
        require(product_tree == plan['product_snapshot']['tree_oid'], 'Produktbaum stimmt nicht.')
    product = product_files
    for prefix in ("Modules/", "Deployment/", "Workers/"):
        require({p: b for p, b in files.items() if p.startswith(prefix)} ==
                {p: b for p, b in product.items() if p.startswith(prefix)}, "Produktinputs gegenüber der qualifizierten Basis geändert.")
    validate_qualification(files, plan)
    if CLR_PACKAGE in files:
        qualified = json.loads(files[f'{DIRECTORY}/clr-qualification.json'])
        require(qualified['product_commit'] == plan['product_commit'], 'CLR-Produktbindung veraltet.')
        inner = read_zip(files[CLR_PACKAGE])
        prefix = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
        validate_clr_qualification({p[len(prefix):]:b for p,b in inner.items()}, qualified, files)


def validate_regex_documentation_delta(previous: dict[str, bytes], current: dict[str, bytes]) -> set[str]:
    """Erlaubt ausschließlich die belegte Regex-Rechte-Dokumentationskorrektur.

    Keine allgemeine Kommentar-/Whitespacebereinigung: Die zwei SQL-Dateien
    müssen exakt den fünf bekannten Headerkorrekturen entsprechen. Alle
    übrigen Runtime-/Buildquellen bleiben bytegleich. Der Manifestnachtrag
    darf nur den dokumentierenden Evidenzblock ergänzen.
    """
    prefix = 'Modules/toolbelt.string.regex/'
    markdown = {prefix + p for p in (
        'README.md', 'Tests/README.md', 'Tests/REGEX_CONTRACT_TEST_MATRIX.md',
        'Documentation/REGEX_FUNCTIONS.md', 'Documentation/SVF_RegexReplace.md',
        'Documentation/SVF_RegexSubstring.md', 'Documentation/SVF_RegexReplaceGroups.md')}
    sql = {prefix + 'Source/RegexFunctions.sql': (2, 2),
           prefix + 'Source/RegexCaptures.sql': (0, 1)}
    manifest = prefix + 'module.yaml'
    runtime_paths = {p for p in set(previous) | set(current) if p.startswith(('Modules/', 'Deployment/', 'Workers/'))}
    changed = {p for p in runtime_paths if previous.get(p) != current.get(p)}
    require(changed and changed <= markdown | set(sql) | {manifest}, 'Unzulässiger Runtime-Delta neben der Rechte-Dokumentation.')
    replacements = (
        (b'-- Dependencies: SAFE Toolbelt_String_Regex; Rechte: SELECT/REFERENCES.',
         b'-- Dependencies: SAFE Toolbelt_String_Regex; keine direkten Fachcallergrants.'),
        (b'-- Dependencies: interner SAFE-CLR-Kern; Rechte: SELECT/REFERENCES.',
         b'-- Dependencies: interner SAFE-CLR-Kern; Rechte: EXECUTE auf dieser Fassade.'))
    for path, counts in sql.items():
        require(path in previous and path in current, 'Regex-SQL-Quelle fehlt.')
        expected = previous[path]
        for (before, after), count in zip(replacements, counts):
            require(expected.count(before) == count, 'Historischer SQL-Header stimmt nicht.')
            expected = expected.replace(before, after)
        require(current[path] == expected, 'Ausführbare Regex-SQL-Quelle geändert.')
    before = b'  - "SELECT oder REFERENCES auf den Regex-Skalarfunktionen"'
    after = '  - "EXECUTE auf den öffentlichen Regex-Skalarfunktionen; keine direkten Fachcallergrants auf interne CLR-Kerne"'.encode('utf-8')
    require(manifest in previous and manifest in current and previous[manifest].count(before) == 1, 'Historische Rechte-Metadaten fehlen.')
    expected = previous[manifest].replace(before, after).rstrip(b'\n')
    require(current[manifest].startswith(expected), 'Fachliche Manifestfelder neben den Rechten geändert.')
    suffix = current[manifest][len(expected):].strip(b'\n')
    require(re.fullmatch(rb'  - date: "[^\r\n]*"\n    workflow: "[^\r\n]*"\n    scope: "[^\r\n]*"\n    result: "success"\n?', suffix) is not None,
            'Unerwarteter Manifestnachtrag statt begrenzter Evidenz.')
    return changed


def validate_regex_product_applicability(previous_product: str, current_product: str) -> None:
    """Historische Ausführung erhalten, neue reine Dokumentationsbasis prüfen.

    Der öffentliche Main-Vorstand enthält das unveränderte ältere Quell-ZIP.
    Beide Produktbäume werden aus ihren geprüften lokalen Bundles rekonstruiert;
    dafür sind keine Branches, Netzabrufe oder alten Arbeitscommits nötig.
    """
    record = json.loads((ROOT / DIRECTORY / 'runtime-source-equivalence.json').read_bytes())
    require(record['schema_version'] == '1.0' and record['publication_authorized'] is False
            and record['previous_product_commit'] == previous_product
            and record['current_product_commit'] == current_product, 'Runtime-Anwendbarkeitsbindung fehlt oder driftet.')
    base = record['public_baseline_commit']
    require(re.fullmatch(r'[0-9a-f]{40}', base) is not None, 'Ungültige öffentliche Anwendbarkeitsbasis.')
    historical = git('show', base + ':' + ARTIFACTS + NAME + '.zip')
    require(sha(historical) == record['previous_source_zip_sha256'], 'Historisches Quellpaket driftet.')
    source = ROOT / ARTIFACTS / (NAME + '.zip')
    data = source.read_bytes()
    require(source.with_suffix('.zip.sha256').read_text(encoding='ascii').split() == [sha(data), source.name],
            'Aktuelles Anwendbarkeitsarchiv driftet.')
    products = []
    for archive, expected in ((historical, previous_product), (data, current_product)):
        raw = read_zip(archive); prefix = NAME + '/'
        manifest = json.loads(raw[prefix+'PACKAGE-MANIFEST.json'])
        require(manifest['product_commit'] == expected, 'Anwendbarkeitsarchiv enthält anderen Produktstand.')
        _, product, tree = recovered_snapshot(raw[prefix+'PREPARATION.bundle'], manifest['source_commit'], expected)
        products.append((product, tree))
    changed = validate_regex_documentation_delta(products[0][0], products[1][0])
    require(sorted(changed) == record['changed_product_paths'] and
            products[0][1] == record['previous_product_tree'] and products[1][1] == record['current_product_tree'],
            'Anwendbarkeitsdelta oder Produktbaum driftet.')
    for index, key in ((0, 'previous_source_sha256'), (1, 'current_source_sha256')):
        require(record[key] == {p: sha(products[index][0][p]) for p in sorted(changed)}, 'Anwendbarkeitsquellhash driftet.')


def clr_qualification_method_sources(qualification: dict) -> dict[str, bytes]:
    """Historische Methoden aus ihrem geprüften Recoverypaket, niemals vom aktuellen Checkout."""
    archive = ROOT / ARTIFACTS / (NAME + '.zip')
    data = archive.read_bytes()
    require(archive.with_suffix('.zip.sha256').read_text(encoding='ascii').split() ==
            [sha(data), archive.name], 'CLR-Methoden-Recoveryarchiv beschädigt.')
    raw = read_zip(data)
    prefix = NAME + '/'
    manifest = json.loads(raw[prefix + 'PACKAGE-MANIFEST.json'])
    require(manifest['product_commit'] == qualification['product_commit'],
            'CLR-Methoden-Recoveryprodukt abweichend.')
    sources, _, _ = recovered_snapshot(raw[prefix + 'PREPARATION.bundle'],
                                       manifest['source_commit'], manifest['product_commit'])
    for path, expected in qualification['method_bindings'].items():
        require(path in sources and sha(sources[path]) == expected, 'CLR-Methoden-Recoverybindung veraltet.')
    return {path:sources[path] for path in qualification['method_bindings']}


def validate_clr_qualification(payload: dict[str,bytes], qualification: dict, sources: dict[str,bytes]) -> None:
    """Aktuelle Lieferbytes an die tatsächlich ausgeführte native Paketwelle binden."""
    require(qualification['publication_authorized'] is False and qualification['native_cases_passed'] == 12,
            'Keine CLR-Veröffentlichungsfreigabe oder vollständige Paketmatrix.')
    require(payload.get('QUALIFICATION.json') == encoded(qualification), 'CLR-Qualifikationsprojektion fehlt oder driftet.')
    require(qualification['sql_payload_sha256'] == {p:sha(b) for p,b in payload.items() if p.startswith('SQL/')},
            'CLR-SQL-Payload gegenüber nativem Nachweis geändert.')
    require(qualification['binary_sha512'] == {p:hashlib.sha512(b).hexdigest() for p,b in payload.items() if p.startswith('Binaries/')},
            'CLR-Binary gegenüber nativem Nachweis geändert.')
    for path, expected in qualification['method_bindings'].items():
        require(path in sources and sha(sources[path]) == expected, 'CLR-Methodenbindung veraltet.')


def validate_qualification(files: dict[str, bytes], plan: dict, exports: dict[str, bytes] | None = None) -> None:
    """Bindet vorhandene datierte Evidenz; führt keinen Runtime-Nachweis aus.

    Historische Pakete ohne diesen Nachtrag bleiben mit ihrem damaligen Scope
    prüfbar. Ein vorhandener Nachtrag darf dagegen keine geänderten SQL- oder
    Adapterbytes weiterhin als damals geprüft darstellen.
    """
    if QUALIFICATION not in files:
        return
    evidence = json.loads(files[QUALIFICATION])
    require(evidence["product_commit"] == plan["product_commit"] and evidence["publication_authorized"] is False,
            "Qualifikationsbasis oder Veröffentlichungsgrenze abweichend.")
    native = evidence["native_package"]
    require(sha(files[native["driver"]]) == native["driver_sha256"]
            and sha(files[native["method"]]) == native["method_sha256"],
            "Nativer Paketadapter gegenüber dem Nachweis geändert.")
    build = evidence["clr_build_inputs"]
    require(sha(files[build["method"]]) == build["method_sha256"] and build["distributed"] is False,
            "Offline-Buildprüfung gegenüber dem Nachweis geändert oder als Auslieferung dargestellt.")
    if exports is not None:
        require(native["sql_payload_sha256"] == {p: sha(b) for p, b in exports.items()},
                "Stabile Paket-SQL-Bytes gegenüber der nativen Abnahme geändert.")


def runtime_root() -> Path:
    runtime = ROOT / ".runtime"
    runtime.mkdir(exist_ok=True)
    # st_file_attributes existiert unter Windows bereits vor Python 3.12;
    # Path.is_junction wäre erst ab 3.12 verfügbar.
    require(not runtime.is_symlink() and not (getattr(runtime.lstat(), "st_file_attributes", 0)
            & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)), "Reparse-Runtime abgewiesen.")
    return runtime


def freeze_product(commit: str, base: str) -> dict:
    source, _ = snapshot(commit)
    base, _ = snapshot(base)
    git('merge-base','--is-ancestor',base,source)
    tree = git('rev-parse',source+'^{tree}').decode().strip()
    date = git('show','-s','--format=%cI',source).decode().strip()
    env = dict(os.environ,GIT_AUTHOR_NAME='Codex',GIT_AUTHOR_EMAIL='codex@localhost',
               GIT_COMMITTER_NAME='Codex',GIT_COMMITTER_EMAIL='codex@localhost',
               GIT_AUTHOR_DATE=date,GIT_COMMITTER_DATE=date)
    frozen = git('commit-tree',tree,'-p',base,'-m',
                 'Codex: Freeze v1.0.0 product tree with synthetic metadata',env=env).decode().strip()
    require(snapshot(frozen)[1] == snapshot(source)[1], 'Produkt-Sanitizer hat Quellbytes geändert.')
    return {'schema_version':'1.0','kind':'synthetic_product_snapshot','source_commit':source,
            'product_commit':frozen,'base_commit':base,'tree_oid':tree}


def preparation_bundle(commit: str, product_commit: str, base_commit: str | None = None) -> tuple[str, bytes]:
    """Nur Vorbereitungsdateien und synthetische Commitmetadaten ausliefern.

    Ein eigener temporärer Index entfernt die Paketablage aus dem Quellbaum.
    Der reproduzierbare Snapshotcommit erhält nur die bekannte Produktbasis
    als Parent, keine persönlichen Metadaten der Arbeitscommits. Weder echter
    Index noch Branches/Tags werden geändert; nur immutable Gitobjekte entstehen.
    """
    runtime = runtime_root()
    with tempfile.TemporaryDirectory(prefix="release-bundle-", dir=runtime) as temp:
        require(Path(temp).resolve().parent == runtime.resolve(), "Bundle außerhalb des eigenen Scopes.")
        bundle = Path(temp) / "preparation.bundle"
        date = git("show", "-s", "--format=%cI", commit).decode().strip()
        env = dict(os.environ, GIT_INDEX_FILE=str(Path(temp) / "snapshot.index"),
                   GIT_AUTHOR_NAME="Codex", GIT_AUTHOR_EMAIL="codex@localhost",
                   GIT_COMMITTER_NAME="Codex", GIT_COMMITTER_EMAIL="codex@localhost",
                   GIT_AUTHOR_DATE=date, GIT_COMMITTER_DATE=date)
        git("read-tree", commit, env=env)
        excluded = [p.decode("utf-8") for p in git("ls-tree", "-rz", "--name-only", commit, "--", ARTIFACTS).split(b"\0") if p]
        if excluded:
            git("update-index", "--force-remove", "--", *excluded, env=env)
        tree = git("write-tree", env=env).decode().strip()
        frozen = git("commit-tree", tree, "-p", product_commit, "-m",
                     "Codex: Freeze v1.0.0 preparation tree with synthetic metadata", env=env).decode().strip()
        require(snapshot(frozen)[1] == snapshot(commit)[1], "Sanitizer hat Quellbytes geändert.")
        # Git bundle benötigt einen benannten Ref. Dieser entsteht nur im
        # eigenen temporären Bare-Repository, niemals im Arbeitscheckout.
        bare = Path(temp) / "repository"
        bare.mkdir()
        bundle_env = dict(env, GIT_ALTERNATE_OBJECT_DIRECTORIES=
                          git("rev-parse", "--path-format=absolute", "--git-path", "objects").decode().strip())
        git("init", "--bare", "--quiet", repository=bare, env=bundle_env)
        git("update-ref", "refs/heads/preparation", frozen, repository=bare, env=bundle_env)
        git("-c", "pack.threads=1", "bundle", "create", str(bundle), "refs/heads/preparation",
            "^" + (base_commit or product_commit), repository=bare, env=bundle_env)
        git("bundle", "verify", str(bundle))
        return frozen, bundle.read_bytes()


def recovered_snapshot(bundle_bytes: bytes, commit: str, product_commit: str) -> tuple[dict, dict, str]:
    """Bundle lokal importieren, ohne Objektstore oder Refs des Checkouts zu ändern.

    Das eigene temporäre Bare-Repository liest die bekannte Produktbasis über
    einen privaten Alternate. Fetch benutzt ausschließlich die gehaltene lokale
    Bundledatei, keinen Remote und keine Credentials. Auch nach Squash/Branch-
    Cleanup bleibt der Vorbereitungscommit dadurch rekonstruierbar.
    """
    require(len(bundle_bytes) <= 16 * 1024 * 1024, "Vorbereitungsbundle zu groß.")
    runtime = runtime_root()
    objects = git("rev-parse", "--path-format=absolute", "--git-path", "objects").decode().strip()
    with tempfile.TemporaryDirectory(prefix="release-verify-", dir=runtime) as temp:
        target = Path(temp).resolve()
        require(target.parent == runtime.resolve(), "Bundleprüfung außerhalb des eigenen Scopes.")
        bundle = target / "preparation.bundle"
        bundle.write_bytes(bundle_bytes)
        env = dict(os.environ, GIT_ALTERNATE_OBJECT_DIRECTORIES=objects,
                   GIT_TERMINAL_PROMPT="0", GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        git("init", "--bare", "--quiet", repository=target, env=env)
        git("bundle", "verify", str(bundle), repository=target, env=env)
        git("-c", "gc.auto=0", "-c", "maintenance.auto=false", "fetch", "--quiet", "--no-tags",
            "--no-write-fetch-head", str(bundle), commit, repository=target, env=env)
        resolved, files = snapshot(commit, repository=target, env=env)
        require(resolved == commit, "Rekonstruierter Quellcommit abweichend.")
        _, product = snapshot(product_commit, repository=target, env=env)
        tree = git('rev-parse',product_commit+'^{tree}',repository=target,env=env).decode().strip()
        return files, product, tree


def export_stable(files: dict[str, bytes], plan: dict) -> dict[str, bytes]:
    pwsh = shutil.which("pwsh")
    require(pwsh is not None, "PowerShell 7 fehlt für den vorhandenen Offline-SQL-Exporter.")
    stable = [m["module_id"] for m in plan["modules"] if m["proposed_channel"] == "stable"]
    runtime = runtime_root()
    with tempfile.TemporaryDirectory(prefix="release-", dir=runtime) as temp:
        target = Path(temp).resolve()
        require(target.parent == runtime.resolve(), "Temporärer Export außerhalb des eigenen Scopes.")
        for path, content in files.items():
            destination = target / path
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(content)
        wrapper = target / "export-stable.ps1"
        wrapper.write_text("param([string]$Mode,[string]$Modules,[string]$OutputFile)\n"
                           "$ErrorActionPreference='Stop'\n"
                           "& (Join-Path $PSScriptRoot 'Deployment/Deploy-All.ps1') "
                           "-DeploymentMode $Mode -ModuleId ($Modules -split ',') -OutputSqlFile $OutputFile\n", encoding="utf-8")
        result = {}
        for mode in ("local", "central"):
            output = target / f"Install-Stable-{mode}.sql"
            # -OutputSqlFile ist ausdrücklich verbindungsfrei. Kein Server,
            # kein sqlcmd, keine Trustmutation und keine Zielkonfiguration.
            command = [pwsh, "-NoProfile", "-NonInteractive", "-File", str(wrapper),
                       "-Mode", mode, "-Modules", ",".join(stable), "-OutputFile", str(output)]
            completed = subprocess.run(command, cwd=target, capture_output=True, timeout=120)
            require(completed.returncode == 0 and output.is_file(), "Offline-SQL-Export fehlgeschlagen.")
            result[output.name] = output.read_bytes()
        return result


def write_zip(payload: dict[str, bytes], root_name: str = NAME) -> bytes:
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path, data in sorted(payload.items()):
            info = zipfile.ZipInfo(root_name + "/" + path, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            archive.writestr(info, data, compresslevel=9)
    return output.getvalue()


def start_here(files: dict[str, bytes]) -> bytes:
    """Der versionierte Einstieg liegt zwei Ebenen unter dem Paketroot."""
    text = files[f"{DIRECTORY}/START-HERE.md"].decode("utf-8")
    return (text.replace("(README.md)", f"({DIRECTORY}/README.md)")
            .replace("(FREIGABEMATRIX.md)", f"({DIRECTORY}/FREIGABEMATRIX.md)")
            .replace("(RELEASE-GATES.md)", f"({DIRECTORY}/RELEASE-GATES.md)")
            .replace("(CLR-INSTALL.md)", f"({DIRECTORY}/CLR-INSTALL.md)")
            .replace("(SUPPORT.md)", f"({DIRECTORY}/SUPPORT.md)")
            .replace("(../../", "(")).encode("utf-8")


def build(commit: str, output: Path) -> None:
    checksum_path = output.with_suffix(output.suffix + ".sha256")
    require(not output.exists() and not checksum_path.exists() and output.parent.is_dir(),
            "ZIP und Prüfsumme müssen neue Ziele sein; kein Überschreiben.")
    resolved, files = snapshot(commit)
    require(PLAN in files, "Quellcommit enthält keinen Releaseplan; Änderungen zuerst committen.")
    plan = json.loads(files[PLAN])
    validate_plan(files, plan)
    exports = export_stable(files, plan)
    validate_qualification(files, plan, exports)
    files.update(exports)
    files["START-HERE.md"] = start_here(files)
    frozen, files["PREPARATION.bundle"] = preparation_bundle(resolved, plan["product_commit"],
        plan.get('product_snapshot',{}).get('base_commit'))
    manifest = {"schema_version": "1.0", "project_version": VERSION,
                "state": "prepared_not_published", "source_commit": frozen,
                "preparation_origin_commit": resolved,
                "product_commit": plan["product_commit"], "package_kind": plan["package_kind"],
                "files": [{"path": p, "bytes": len(b), "sha256": sha(b)} for p, b in sorted(files.items())]}
    files["PACKAGE-MANIFEST.json"] = encoded(manifest)
    files["SHA256SUMS.txt"] = "".join(f"{sha(b)}  {p}\n" for p, b in sorted(files.items())).encode("utf-8")
    data = write_zip(files)
    with output.open("xb") as stream:
        stream.write(data)
    with checksum_path.open("x", encoding="ascii") as stream:
        stream.write(f"{sha(data)}  {output.name}\n")
    print(f"Releasekandidat erzeugt: 45 Module; {len(files)} Dateien; keine Veröffentlichung.")


def verify(path: Path) -> None:
    data = path.read_bytes()
    checksum = path.with_suffix(path.suffix + ".sha256").read_text(encoding="ascii").split()
    require(checksum == [sha(data), path.name], "ZIP-Prüfsumme stimmt nicht.")
    raw = read_zip(data)
    prefix = NAME + "/"
    require(all(p.startswith(prefix) for p in raw), "Falscher Paketroot.")
    files = {p[len(prefix):]: b for p, b in raw.items()}
    manifest = json.loads(files["PACKAGE-MANIFEST.json"])
    require(manifest["state"] == "prepared_not_published" and manifest["package_kind"] == "complete_source_candidate", "Falscher Paketstatus.")
    listed = {entry["path"]: entry for entry in manifest["files"]}
    require(len(listed) == len(manifest["files"]) and set(listed) | {"PACKAGE-MANIFEST.json", "SHA256SUMS.txt"} == set(files), "Unvollständiges Paketmanifest.")
    for p, entry in listed.items():
        require(len(files[p]) == entry["bytes"] and sha(files[p]) == entry["sha256"], "Dateihash stimmt nicht.")
    expected_sums = "".join(f"{sha(b)}  {p}\n" for p, b in sorted(files.items()) if p != "SHA256SUMS.txt").encode("utf-8")
    require(files["SHA256SUMS.txt"] == expected_sums, "Dateiprüfsummen unvollständig.")
    source, product, tree = recovered_snapshot(files["PREPARATION.bundle"], manifest["source_commit"], manifest['product_commit'])
    require(set(files) == set(source) | {"START-HERE.md", "PREPARATION.bundle", "Install-Stable-local.sql", "Install-Stable-central.sql", "PACKAGE-MANIFEST.json", "SHA256SUMS.txt"}, "Unerwartete Paketdateien.")
    for p, b in source.items():
        require(files[p] == b, "Paket weicht vom eingefrorenen Gitstand ab.")
    validate_plan(source, json.loads(source[PLAN]), product_files=product, product_tree=tree)
    require(manifest["product_commit"] == json.loads(source[PLAN])["product_commit"], "Produktbasis widersprüchlich.")
    require(files["START-HERE.md"] == start_here(source), "Paketeinstieg abweichend.")
    # Die zwei zusätzlichen SQL-Dateien sind keine Gitblobs. Ihre Hashes
    # allein würden nur ein selbst konsistentes Manifest belegen. Erneuter
    # Offline-Export aus dem eingefrorenen Gitstand bindet auch diese Bytes.
    expected_exports = export_stable(source, json.loads(source[PLAN]))
    validate_qualification(source, json.loads(source[PLAN]), expected_exports)
    for mode in ("local", "central"):
        name = f"Install-Stable-{mode}.sql"
        require(files[name] == expected_exports[name], "SQL-Export weicht von der eingefrorenen Quelle ab.")
        text = files[name].decode("utf-8")
        require(":ON ERROR EXIT" in text and "$(" not in text, "Unvollständiger SQL-Export.")
    print("Paketintegrität, Quellcommit, 45-Modul-Plan und transitive Kanalgrenzen: PASS; keine native Installationsabnahme.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--refresh", action="store_true")
    modes.add_argument("--check", action="store_true")
    modes.add_argument("--build", action="store_true")
    modes.add_argument("--verify", type=Path)
    modes.add_argument('--freeze-product', action='store_true')
    parser.add_argument("--source-commit", default="HEAD")
    parser.add_argument("--product-commit")
    parser.add_argument("--output", type=Path)
    parser.add_argument('--base-commit')
    args = parser.parse_args()
    if args.freeze_product:
        require(args.product_commit is not None and args.base_commit is not None, 'Explizite Produktquelle und öffentliche Basis erforderlich.')
        record = freeze_product(args.product_commit,args.base_commit)
        (ROOT / PRODUCT_SOURCE).write_bytes(encoded(record))
        print('Synthetischer Produktbaum eingefroren; keine Quelldatei, Branch oder Veröffentlichung verändert.')
    elif args.refresh:
        product, files = snapshot(args.product_commit or "HEAD")
        # Produktquellen bleiben eingefroren. Die Lieferform entsteht dagegen
        # aus dem aktuellen Vorbereitungsstand, nicht aus der früheren Basis.
        _, preparation = snapshot(args.source_commit)
        if CLR_PACKAGE in preparation:
            files[CLR_PACKAGE] = preparation[CLR_PACKAGE]
        for path in (f'{DIRECTORY}/support-scope.json', f'{DIRECTORY}/SUPPORT.md', PRODUCT_SOURCE):
            if path in preparation:
                files[path] = preparation[path]
        plan = make_plan(files, product)
        (ROOT / PLAN).parent.mkdir(parents=True, exist_ok=True)
        (ROOT / PLAN).write_bytes(encoded(plan))
        (ROOT / MATRIX).write_bytes(matrix(plan))
        print("Freigabevorschläge erzeugt; Modulmanifeste unverändert.")
    elif args.check:
        require(not git("diff", "--name-only", "HEAD", "--", "Modules/", "Deployment/", "Workers/").strip()
                and not git("ls-files", "--others", "--exclude-standard", "--", "Modules/", "Deployment/", "Workers/").strip(),
                "Nicht eingefrorene Produktänderungen im Checkout.")
        product_plan = json.loads((ROOT / PLAN).read_bytes())
        _, files = snapshot(args.source_commit)
        # Vor dem ersten Commit sind ausschließlich die beiden Ableitungen
        # zusätzliche lokale Inputs; Produktbytes stammen weiterhin aus Git.
        files[PLAN] = (ROOT / PLAN).read_bytes()
        files[MATRIX] = (ROOT / MATRIX).read_bytes()
        validate_plan(files, product_plan)
        print("Releaseplan und Freigabematrix: PASS; Veröffentlichung nicht autorisiert.")
    elif args.build:
        require(args.output is not None, "--output fehlt.")
        build(args.source_commit, args.output)
    else:
        verify(args.verify)


if __name__ == "__main__":
    try:
        main()
    except (ReleaseError, OSError, KeyError, json.JSONDecodeError, zipfile.BadZipFile, subprocess.TimeoutExpired) as error:
        print(f"RELEASE_PREPARATION_FAILED: {error}", file=sys.stderr)
        sys.exit(1)
