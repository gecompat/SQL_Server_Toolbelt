#!/usr/bin/env python3
"""Bindet einen aktuellen Quellkandidaten; historische Qualifikation bleibt getrennt.

Git liefert ausschließlich versionierte Bytes. Der bereits separat geprüfte
Parameter-Help-Installer bleibt bytegleich; Compiler, SQL und Lab werden nicht
aufgerufen. Die Prüfung benötigt den Quellcommit im lokalen Repository.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import posixpath
import subprocess
import sys
import zipfile

import prepare_release as release
import new_parameter_help_package as help_package

ROOT = release.ROOT
NAME = "SQL-Server-Toolbelt-1.0.0-current-candidate"
GUIDE = "Releases/1.0.0/CURRENT-CANDIDATE.md"
EVIDENCE = "Releases/1.0.0/parameter-help-qualification.json"
PLAN = "CURRENT-RELEASE-PLAN.json"
MANIFEST = "CANDIDATE-MANIFEST.json"
SUMS = "SHA256SUMS.txt"


def installer_inputs(files: dict[str, bytes]) -> dict:
    """Prüft Paketbytes und Quellbindung, ohne native Aussagen zu erweitern."""
    path = help_package.OUTPUT
    checksum = files[path + ".sha256"].decode("ascii").split()
    release.require(checksum == [release.sha(files[path]), Path(path).name],
                    "Aktueller Installer: Archivprüfsumme abweichend.")
    payload = release.read_zip(files[path])
    metadata = json.loads(payload["PACKAGE.json"])
    release.require(metadata["schema_version"] == "toolbelt-parameter-help-package/v1"
                    and metadata["scope"] == "CURRENT_FRESH_INSTALL_HELP_CONTRACT"
                    and metadata["publication_authorized"] is False,
                    "Aktueller Installer: Paketvertrag abweichend.")
    release.require(metadata["files"] == {p: release.sha(b) for p, b in payload.items()
                                          if p not in ("PACKAGE.json", "SHA256SUMS")},
                    "Aktueller Installer: Nutzdatenmanifest abweichend.")
    sums = "".join(release.sha(b) + "  " + p + "\n" for p, b in sorted(payload.items())
                   if p != "SHA256SUMS").encode()
    release.require(payload["SHA256SUMS"] == sums,
                    "Aktueller Installer: Dateiprüfsummen abweichend.")
    for field in ("source_sha256", "editorial_sha256", "predecessor_packages"):
        for source, expected in metadata[field].items():
            release.safe_path(source)
            data = files[source]
            if field == "source_sha256":
                data = data.replace(b"\r\n", b"\n")
            release.require(release.sha(data) == expected,
                            "Aktueller Installer: Quellbindung abweichend: " + source)
    record = json.loads(files[EVIDENCE])
    release.require(record["schema_version"] == "toolbelt-parameter-help-qualification/v1"
                    and record["result"] == "PASS" and record["publication_authorized"] is False
                    and record["scope"] == "Installed Help and fresh-install executable contents only; no full business requalification"
                    and record["current_package"] == {"path": path, "sha256": release.sha(files[path])},
                    "Aktueller Installer: gebundener Help-Nachweis fehlt.")
    expected_contexts = {(platform, version, level, mode) for platform in ("windows", "linux")
                         for version, level in (("2019", 150), ("2022", 160), ("2025", 170))
                         for mode in ("local", "central")}
    cases = record["cases"]
    release.require(len(cases) == 12
                    and {(c["platform"], c["sql_server"], c["compatibility_level"], c["deployment_mode"])
                         for c in cases} == expected_contexts
                    and all(c["result"] == "PASS" and c["cleanup_audit"] == "PASS" for c in cases)
                    and record["authenticated_tls"] == "not executed",
                    "Aktueller Installer: Help-Kontexte oder Nachweisgrenze abweichend.")
    for source, expected in record["native_execution"]["input_sha256"].items():
        release.safe_path(source)
        release.require(release.sha(files[source]) == expected,
                        "Aktueller Installer: native Eingabebindung abweichend: " + source)
    build = json.loads(payload["SSIS-BUILD.json"])
    release.require(build["reproducedBuild"] is True
                    and build["sha512"].lower() == metadata["binary_sha512"]["Toolbelt.Tsql.SsisDebug.dll"],
                    "Aktueller Installer: reproduzierbare SSIS-Binarybindung fehlt.")
    for field in ("sourceFiles", "deploymentFiles"):
        for entry in build[field]:
            relative, expected = entry.rsplit(":", 1)
            # Die Buildliste enthält den expliziten ../ScriptParser-Link.
            # Nur innerhalb des versionierten Modulbaums normalisieren.
            source = posixpath.normpath("Modules/toolbelt.tsql.ssis-debug/" + relative.replace("\\", "/"))
            release.safe_path(source)
            release.require(source.startswith("Modules/"), "SSIS-Buildquelle außerhalb der Module.")
            release.require(release.sha(files[source]).upper() == expected,
                            "Aktueller Installer: SSIS-Buildquelle abweichend: " + source)
    modules = {p.split("/")[1] for p in files
               if p.startswith("Modules/") and p.count("/") == 2 and p.endswith("/module.yaml")}
    expected_profiles = []
    for platform in ("Windows", "Portable"):
        for mode in ("local", "central"):
            selected = sorted(m for m in modules
                              if not (platform == "Portable" and m in help_package.WINDOWS_ONLY)
                              and not (mode == "central" and m in help_package.LOCAL_ONLY))
            expected_profiles.append(dict(name=platform + "-" + mode, platform=platform,
                                          mode=mode, modules=selected))
    release.require(metadata["profiles"] == expected_profiles,
                    "Aktueller Installer: Modulprofile abweichend.")
    release.require(payload["LICENSE.md"] == files["LICENSE.md"],
                    "Aktueller Installer: Lizenz abweichend.")
    return {"path": path, "sha256": release.sha(files[path]),
            "evidence": EVIDENCE, "evidence_sha256": release.sha(files[EVIDENCE]),
            "scope": record["scope"], "profiles": expected_profiles}


def current_plan(files: dict[str, bytes], commit: str) -> dict:
    # product-source.json und release-plan.json gehören zur historischen
    # Lieferung. Ihr Produktcommit wird nicht auf heutige Quellen übertragen.
    projection = release.make_plan({p: b for p, b in files.items()
                                    if p != release.PRODUCT_SOURCE}, commit)
    return {"schema_version": "toolbelt-current-candidate/v1", "project_version": release.VERSION,
            "source_commit": commit, "state": "candidate_not_published",
            "publication_authorized": False, "full_module_qualification": "not established",
            "channels": dict(Counter(m["proposed_channel"] for m in projection["modules"])),
            "modules": projection["modules"], "installer": installer_inputs(files),
            "release_gates": "Releases/1.0.0/RELEASE-GATES.md"}


def start_here(files: dict[str, bytes]) -> bytes:
    data = files[GUIDE]
    for name in ("PARAMETER-HELP.md", "RELEASE-GATES.md", "SUPPORT.md"):
        data = data.replace(("(" + name + ")").encode(),
                            ("(Releases/1.0.0/" + name + ")").encode())
    return data


def payload(commit: str) -> dict[str, bytes]:
    resolved, files = release.snapshot(commit)
    release.require(GUIDE in files, "Kandidatenanleitung fehlt im Quellcommit.")
    release.require(not {PLAN, MANIFEST, SUMS, "START-HERE.md"} & files.keys(),
                    "Generierte Kandidatenpfade sind bereits versioniert.")
    result = dict(files)
    result[PLAN] = release.encoded(current_plan(files, resolved))
    result["START-HERE.md"] = start_here(files)
    result[MANIFEST] = release.encoded({
        "schema_version": "toolbelt-current-candidate-manifest/v1",
        "source_commit": resolved, "state": "candidate_not_published",
        "publication_authorized": False,
        "verification_scope": "source_integrity_and_bound_help_installer_only",
        "files": {p: {"bytes": len(b), "sha256": release.sha(b)}
                  for p, b in sorted(result.items())}})
    result[SUMS] = "".join(release.sha(b) + "  " + p + "\n"
                           for p, b in sorted(result.items())).encode()
    return result


def build(commit: str, output: Path) -> None:
    checksum = Path(str(output) + ".sha256")
    release.require(output.parent.is_dir() and not output.exists() and not checksum.exists(),
                    "Neues Ausgabeziel samt Prüfsumme erforderlich.")
    data = release.write_zip(payload(commit), NAME)
    # Die Größen-/Pfadgrenzen müssen schon vor der Ausgabe erfüllt sein.
    release.read_zip(data)
    with output.open("xb") as stream:
        stream.write(data)
    with checksum.open("x", encoding="ascii") as stream:
        stream.write(release.sha(data) + "  " + output.name + "\n")
    print("CURRENT_CANDIDATE_BUILD: PASS; keine Veröffentlichungs- oder Gesamtqualifikation.")


def verify(path: Path) -> None:
    data = path.read_bytes()
    release.require(Path(str(path) + ".sha256").read_text(encoding="ascii").split()
                    == [release.sha(data), path.name], "Kandidatenprüfsumme abweichend.")
    raw = release.read_zip(data)
    prefix = NAME + "/"
    release.require(all(p.startswith(prefix) for p in raw), "Kandidatenroot abweichend.")
    actual = {p[len(prefix):]: b for p, b in raw.items()}
    manifest = json.loads(actual[MANIFEST])
    # Der vertrauenswürdige lokale Quellcommit, nicht ein selbst konsistentes
    # Archivmanifest, bestimmt jeden erlaubten Inhalt einschließlich Nachweisen.
    expected = payload(manifest["source_commit"])
    release.require(actual == expected, "Kandidat weicht vom exakten Quellcommit ab.")
    print("CURRENT_CANDIDATE_VERIFY: PASS; Quellcommit, 45 Module, Installer und Prüfsummen gebunden.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--build", action="store_true")
    modes.add_argument("--verify", type=Path)
    parser.add_argument("--source-commit", default="HEAD")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.build:
        release.require(args.output is not None, "--output fehlt.")
        build(args.source_commit, args.output)
    else:
        release.require(args.output is None, "--verify erlaubt kein Ausgabeziel.")
        verify(args.verify)


if __name__ == "__main__":
    try:
        main()
    except (release.ReleaseError, OSError, KeyError, ValueError, zipfile.BadZipFile,
            subprocess.TimeoutExpired, subprocess.CalledProcessError) as error:
        print("CURRENT_CANDIDATE_FAILED: " + str(error), file=sys.stderr)
        sys.exit(1)
