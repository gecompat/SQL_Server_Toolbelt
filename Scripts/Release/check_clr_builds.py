#!/usr/bin/env python3
"""Prüft CLR-Buildinputs isoliert und reproduzierbar; liefert keine DLLs aus.

Zwei eigene Quellkopien erhalten ausschließlich versionierte Inputs. Neue
Binaryhashes ersetzen weder bekannte Closurepins noch native Qualifikation.
Compilerlogs, Buildpfade und der Kandidatensatz bleiben privat in .runtime.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

import prepare_release as release

ROOT = release.ROOT


def check_binary(data: bytes, private_roots: list[Path]) -> None:
    spec = importlib.util.spec_from_file_location(
        "ssis_pe_guard", ROOT / "Modules/toolbelt.tsql.ssis-debug/Tests/Static/validate_install_package.py")
    guard = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(guard)
    guard.no_codeview(data)
    for root in private_roots:
        for text in (str(root), str(root).replace("\\", "/")):
            release.require(text.encode() not in data and text.encode("utf-16-le") not in data,
                            "Lokaler Buildpfad im Kandidatenbinary.")


def run(msbuild: Path, output: Path) -> None:
    private = release.runtime_root().resolve()
    destination = output.absolute()
    release.require(destination.parent.resolve() == private and not destination.exists(),
                    "Neues direktes .runtime-Unterverzeichnis erforderlich.")
    release.require(msbuild.is_file(), "Explizites MSBuild fehlt.")
    release.require(not release.git("status", "--porcelain", "--", "Modules", "Deployment", "Workers").strip(),
                    "Produktinputs im Checkout geändert.")
    commit, files = release.snapshot("HEAD")
    projects = sorted(p for p in files if p.startswith("Modules/") and p.endswith(".csproj"))
    release.require(len(projects) == 12, "Erwartet werden die zwölf besprochenen CLR-Projekte.")
    first = ("toolbelt.json.core", "toolbelt.archive.zip-memory")
    projects.sort(key=lambda p: (first.index(p.split('/')[1]) if p.split('/')[1] in first else 2, p))
    nested = files["Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip"]
    with zipfile.ZipFile(io.BytesIO(nested)) as archive:
        names = [n for n in archive.namelist() if n.endswith('/Microsoft.SqlServer.TransactSql.ScriptDom.dll')]
        release.require(len(names) == 1, "Eindeutiger vorhandener ScriptDom-Input fehlt.")
        scriptdom = archive.read(names[0])
    release.require(hashlib.sha512(scriptdom).hexdigest() ==
                    '459e137268a4ca378023cd7e68a04655cec2c19a8d01546e81b1a7abf1fe2f9226a03cc3fa2323081c3c1b05626af988c98527711d577919cf409367f853dac7',
                    "ScriptDom-Pin abweichend.")
    destination.mkdir()
    dependency = destination / 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'
    dependency.write_bytes(scriptdom)
    roots = [destination / 'first', destination / 'second']
    candidates: dict[str, list[bytes]] = {}
    for shadow in roots:
        shadow.mkdir()
        for path, data in files.items():
            if path.startswith('Modules/'):
                target = shadow / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
        for project in projects:
            module = project.split('/')[1]
            xml = ET.fromstring(files[project])
            assembly = next(n.text for n in xml.iter() if n.tag.endswith('}AssemblyName'))
            # Keine neuen Builddependencies: .NET Framework, expliziter Compiler
            # und die bereits gepinnte ScriptDom-DLL aus dem vorhandenen Paket.
            command = [str(msbuild), str(shadow / project), '/t:Rebuild', '/m:1', '/nodeReuse:false',
                       '/nologo', '/verbosity:minimal', '/p:Configuration=Release', '/p:Platform=AnyCPU',
                       '/p:DebugType=none', '/p:DebugSymbols=false', '/p:UseSharedCompilation=false',
                       f'/p:PathMap={shadow}=/_/SQL_Server_Toolbelt', f'/p:ScriptDomDllPath={dependency}']
            completed = subprocess.run(command, capture_output=True, timeout=180, cwd=shadow)
            (destination / f'{shadow.name}-{module}.log').write_bytes(completed.stdout + completed.stderr)
            release.require(completed.returncode == 0, f"Build fehlgeschlagen: {module}; Diagnose ausschließlich privat.")
            binary = shadow / Path(project).parent / 'bin/Release' / (assembly + '.dll')
            data = binary.read_bytes()
            check_binary(data, roots)
            candidates.setdefault(module, []).append(data)
    report = {'schema_version': '1.0', 'source_commit': commit, 'scope': 'OFFLINE_BUILD_ONLY',
              'native_qualification': 'NOT_EXECUTED', 'trust_authorization': 'NOT_GRANTED',
              'distributed': False, 'builds': []}
    registry = json.loads(files['Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'])
    known = {a['Fields']['moduleId']: a['Fields']['binarySha256'] for a in registry['artifacts']}
    for module, binaries in candidates.items():
        release.require(len(binaries) == 2 and binaries[0] == binaries[1], f"Build nicht reproduzierbar: {module}")
        digest = release.sha(binaries[0])
        report['builds'].append({'module_id': module, 'sha256': digest,
                                'sha512': hashlib.sha512(binaries[0]).hexdigest(),
                                'reproducible': True, 'no_codeview': True,
                                'known_json_closure_match': digest == known[module] if module in known else None})
    (destination / 'build-check.json').write_bytes(release.encoded(report))
    print('PASS CLR_BUILD_INPUTS 12 projects, two isolated builds each, byte equality and PE/privacy guards; native NOT_EXECUTED; no distribution')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--msbuild', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    try:
        run(args.msbuild, args.output)
    except (release.ReleaseError, OSError, subprocess.TimeoutExpired, ValueError) as error:
        print(f'CLR_BUILD_CHECK_FAILED: {error}', file=sys.stderr)
        sys.exit(1)
