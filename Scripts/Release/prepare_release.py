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
NAME = f"SQL-Server-Toolbelt-{VERSION}-candidate-source"
ARTIFACTS = f"{DIRECTORY}/Artifacts/"
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
    return {
        "schema_version": "1.0", "project_version": VERSION,
        "state": "prepared_not_published", "publication_authorized": False,
        "product_commit": product_commit,
        "package_kind": "complete_source_candidate",
        "foundation": {"version": "1.25.0", "source_commit": "9e1b9974de58ea775d40c7c6045cd5057ba8b30c"},
        "channel_semantics": "Vorschläge für den Release-Review; keine Veröffentlichung und keine Aufwertung der Modulmanifeste.",
        "support_scope_review": "pending; deklarierte Zielversionen sind keine neue Supportzusage",
        "modules": list(modules.values()),
    }


def matrix(plan: dict) -> bytes:
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
        ref = f"../../Modules/{mid}/module.yaml"
        evidence = next((p for p in reversed(m["evidence_references"]) if p.endswith("README.md")))
        deps = ", ".join(f"`{x}`" for x in m["dependencies"]) or "—"
        lines.append(f"| [`{mid}`]({ref}) {m['module_version']} | **{m['proposed_channel']}** | {m['validation_status']} | {deps} | [Nachweise](../../{evidence}); {m['pending_before_publication']} |")
    lines += ["", "Die Spalte `binary_delivery` im [maschinenlesbaren Plan](release-plan.json) benennt die Lieferform. Das Gesamt-ZIP ist ein Quellpaket. Der separat enthaltene SSIS-Installationssatz enthält bereits qualifizierte DLLs. Weitere CLR-Provider benötigen ihre dokumentierten Build-/Trustinputs; ein vollständiges vorgebautes CLR-Installationspaket wird hier nicht behauptet.", "",
              "Vor Veröffentlichung gelten die [offenen Releasegates](README.md#vor-einer-veröffentlichung) und der [kanonische Veröffentlichungsvertrag](../../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md#öffentlicher-veröffentlichungsnachweis).", ""]
    return "\n".join(lines).encode("utf-8")


def validate_plan(files: dict[str, bytes], plan: dict) -> None:
    require(re.fullmatch(r"[0-9a-f]{40}", plan.get("product_commit", "")) is not None, "Produktcommit fehlt.")
    require(plan == make_plan(files, plan["product_commit"]), "Releaseplan ist veraltet oder aufgewertet.")
    require(files.get(MATRIX) == matrix(plan), "Freigabematrix ist veraltet.")
    receipt = json.loads(files[".ai/foundation/installation-provenance.json"])
    require(plan["foundation"] == {"version": receipt["ruleset_version"], "source_commit": receipt["source_commit"]},
            "Foundationbindung stimmt nicht.")
    _, product = snapshot(plan["product_commit"])
    for prefix in ("Modules/", "Deployment/", "Workers/"):
        require({p: b for p, b in files.items() if p.startswith(prefix)} ==
                {p: b for p, b in product.items() if p.startswith(prefix)}, "Produktinputs gegenüber der qualifizierten Basis geändert.")


def runtime_root() -> Path:
    runtime = ROOT / ".runtime"
    runtime.mkdir(exist_ok=True)
    # st_file_attributes existiert unter Windows bereits vor Python 3.12;
    # Path.is_junction wäre erst ab 3.12 verfügbar.
    require(not runtime.is_symlink() and not (getattr(runtime.lstat(), "st_file_attributes", 0)
            & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)), "Reparse-Runtime abgewiesen.")
    return runtime


def preparation_bundle(commit: str, product_commit: str) -> tuple[str, bytes]:
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
        git("-c", "pack.threads=1", "bundle", "create", str(bundle), frozen, "^" + product_commit)
        git("bundle", "verify", str(bundle))
        return frozen, bundle.read_bytes()


def recovered_snapshot(bundle_bytes: bytes, commit: str) -> dict[str, bytes]:
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
        return files


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


def write_zip(payload: dict[str, bytes]) -> bytes:
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path, data in sorted(payload.items()):
            info = zipfile.ZipInfo(NAME + "/" + path, date_time=(1980, 1, 1, 0, 0, 0))
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
            .replace("(../../", "(")).encode("utf-8")


def build(commit: str, output: Path) -> None:
    checksum_path = output.with_suffix(output.suffix + ".sha256")
    require(not output.exists() and not checksum_path.exists() and output.parent.is_dir(),
            "ZIP und Prüfsumme müssen neue Ziele sein; kein Überschreiben.")
    resolved, files = snapshot(commit)
    require(PLAN in files, "Quellcommit enthält keinen Releaseplan; Änderungen zuerst committen.")
    plan = json.loads(files[PLAN])
    validate_plan(files, plan)
    files.update(export_stable(files, plan))
    files["START-HERE.md"] = start_here(files)
    frozen, files["PREPARATION.bundle"] = preparation_bundle(resolved, plan["product_commit"])
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
    source = recovered_snapshot(files["PREPARATION.bundle"], manifest["source_commit"])
    require(set(files) == set(source) | {"START-HERE.md", "PREPARATION.bundle", "Install-Stable-local.sql", "Install-Stable-central.sql", "PACKAGE-MANIFEST.json", "SHA256SUMS.txt"}, "Unerwartete Paketdateien.")
    for p, b in source.items():
        require(files[p] == b, "Paket weicht vom eingefrorenen Gitstand ab.")
    validate_plan(source, json.loads(source[PLAN]))
    require(manifest["product_commit"] == json.loads(source[PLAN])["product_commit"], "Produktbasis widersprüchlich.")
    require(files["START-HERE.md"] == start_here(source), "Paketeinstieg abweichend.")
    # Die zwei zusätzlichen SQL-Dateien sind keine Gitblobs. Ihre Hashes
    # allein würden nur ein selbst konsistentes Manifest belegen. Erneuter
    # Offline-Export aus dem eingefrorenen Gitstand bindet auch diese Bytes.
    expected_exports = export_stable(source, json.loads(source[PLAN]))
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
    parser.add_argument("--source-commit", default="HEAD")
    parser.add_argument("--product-commit")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.refresh:
        product, files = snapshot(args.product_commit or "HEAD")
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
