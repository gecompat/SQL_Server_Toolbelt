"""Aktuelles XLSX-Paket aus qualifizierten DLLs und kanonischen SQL-Exporten."""
from __future__ import annotations
import argparse
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile
import zipfile

import prepare_clr_package as clr
import prepare_release as release

ROOT = Path(__file__).resolve().parents[2]
PREFIX = clr.PACKAGE + '/'
MODULES = ('toolbelt.core.result-table', 'toolbelt.archive.zip-memory', 'toolbelt.file.xlsx-memory')
EVIDENCE = 'Releases/1.0.0/XLSX-NATIVE-PACKAGE-QUALIFICATION.json'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def source_files():
    paths = set((ROOT / 'Deployment').glob('*.ps1'))
    for module in MODULES:
        root = ROOT / 'Modules' / module
        paths.add(root / 'module.yaml')
        for directory in ('Source', 'Deployment'):
            paths.update((root / directory).rglob('*.sql'))
        paths.update(p for p in (root / 'Clr').rglob('*')
                     if p.suffix in ('.cs', '.csproj') and not {'bin', 'obj'} & set(p.parts))
    return {p.relative_to(ROOT).as_posix(): p.read_bytes() for p in sorted(paths)}


def source_files_at(commit):
    """Originalquellen prüfen, ohne historische Pakete an künftigen Code zu binden."""
    require(len(commit) == 40 and all(c in '0123456789abcdef' for c in commit), 'source commit')
    raw = subprocess.check_output(['git', 'archive', '--format=tar', commit, 'Deployment',
                                   *('Modules/' + module for module in MODULES)], cwd=ROOT)
    result = {}
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        for item in archive:
            parts = Path(item.name).parts
            selected = (len(parts) == 2 and parts[0] == 'Deployment' and item.name.endswith('.ps1'))
            if len(parts) >= 3 and parts[0] == 'Modules' and parts[1] in MODULES:
                selected |= (len(parts) == 3 and parts[2] == 'module.yaml')
                selected |= (parts[2] in ('Source', 'Deployment') and item.name.endswith('.sql'))
                selected |= (parts[2] == 'Clr' and Path(item.name).suffix in ('.cs', '.csproj') and not {'bin', 'obj'} & set(parts))
            if selected and item.isfile():
                result[item.name] = archive.extractfile(item).read()
    return result


def payload():
    prior = json.loads((ROOT / 'Releases/1.0.0/xlsx-sst-budget-correction.json').read_bytes())
    bundle = (ROOT / prior['candidate_bundle']['path']).read_bytes()
    require(digest(bundle) == prior['candidate_bundle']['sha256'], 'candidate bundle drift')
    files = source_files()
    artifacts = []
    with zipfile.ZipFile(io.BytesIO(bundle)) as archive:
        require(len(archive.namelist()) == len(set(archive.namelist())), 'candidate duplicate entry')
        for name, expected in prior['candidate_bundle']['files'].items():
            data = archive.read(name)
            require(digest(data) == expected, 'candidate entry drift')
            if name.startswith('Sources/'):
                require(data.replace(b'\r\n', b'\n') == (ROOT / name[8:]).read_bytes().replace(b'\r\n', b'\n'), 'compiled XLSX source drift')
        for module, filename, sql_name in (
            ('toolbelt.archive.zip-memory', 'Toolbelt.Archive.ZipMemory.dll', 'Toolbelt_Archive_ZipMemory'),
            ('toolbelt.file.xlsx-memory', 'Toolbelt.File.XlsxMemory.dll', 'Toolbelt_File_XlsxMemory')):
            data = archive.read('Binaries/' + filename)
            artifacts.append(dict(module_id=module, file=filename, sql_name=sql_name,
                                  origin='existing_qualified_sst_candidate', sha256=digest(data),
                                  sha512=hashlib.sha512(data).hexdigest(), _bytes=data))
    zip_record = json.loads((ROOT / 'Releases/1.0.0/XLSX-ZIP-PACKAGE-FRAMEWORK-QUALIFICATION.json').read_bytes())
    pins = [p for p in zip_record['input_pins']['pins'] if p['path'].startswith('Modules/toolbelt.archive.zip-memory/Clr/')]
    require(len(pins) == 5 and all(digest((ROOT / p['path']).read_bytes()) == p['sha256'] for p in pins), 'ZIP source drift')
    result = {'Sources/' + path: data for path, data in files.items()}
    result.update({'Binaries/' + a['file']: a['_bytes'] for a in artifacts})
    # Unveränderte Export-, Uninstall- und Trustimplementierung des CLR-Pakets.
    result.update(clr.exports(files, artifacts))
    result['Install-ClrPackage.ps1'] = (ROOT / 'Scripts/Release/Install-ClrPackage.ps1').read_bytes()
    result['LICENSE.md'] = (ROOT / 'LICENSE.md').read_bytes()
    result['START-HERE.md'] = ("# XLSX installieren\n\n"
        "Dieses unveröffentlichte Paket umfasst ausschließlich ResultTable 1.0, ZIP Memory 1.4 und XLSX Memory 1.2. "
        "Andere Module des historischen CLR-Gesamtpakets sind nicht enthalten.\n\n"
        "1. ZIP-SHA256 gegen die benachbarte .sha256-Datei prüfen und in einen eigenen neuen Ordner entpacken.\n"
        "2. PowerShell 7 und vorhandenes sqlcmd verwenden. Zuerst `./Install-ClrPackage.ps1 -ValidateOnly`.\n"
        "3. Vorhandene Installationsrechte und verschlüsseltes SQL-Ziel wählen; `clr strict security` bleibt aktiv. "
        "CLR-Aktivierung und administrativer exakter Trust sind getrennte Vorbereitungen, keine automatische Rechtevergabe.\n"
        "4. `./Install-ClrPackage.ps1 -Profile Windows-local -ServerInstance localhost -Database Contoso -Action Install` "
        "mit bestehender Anmeldung ausführen. Windows-central sowie Portable-local/central wählen den gleichwertigen Modus; "
        "Portable gilt für unterstützte Linux- und Windows-Engines. SQL-Anmeldung erfolgt nur über explizites PSCredential.\n"
        "5. Repeat verwendet den exakten vorhandenen Assemblyhash. Uninstall/UninstallAbsent verlangen "
        "zusätzlich `-ConfirmNoExternalConsumers`; Trust und Dependencies anderer Verbraucher bleiben erhalten. "
        "`-RegisterExactTrust` ist ein ausdrückliches administratives Opt-in. Encrypt bleibt Mandatory; "
        "`-TrustServerCertificate` ist nur ein bewusster funktionaler Testweg und kein Serveridentitätsnachweis.\n\n"
        "Fehlende Rechte, Hashdrift oder unbekannte Verbraucher blockieren; kein Provider-/Trustfallback. "
        "Das Paket startet oder repariert keine Labressourcen. Quellen unter Sources sind die Installations-/CLR-Quellclosure, "
        "kein vollständiger Entwicklercheckout.\n\n"
        "Ergebnis und Grenzen der konkreten Paketbytes stehen im externen "
        "[Qualifikationsbericht](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/XLSX-NATIVE-PACKAGE-QUALIFICATION.md). "
        "Ein vorbereitetes Paket allein ist kein bestandener Test und keine Veröffentlichungsfreigabe.\n").encode()
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
    metadata = dict(schema_version='1.0', state='prepared_not_published', source_commit=commit,
                    qualification_state='external_scope_evidence', publication_authorized=False,
                    qualification_evidence=EVIDENCE, source_closure='deployment_and_clr_only',
                    candidate_bundle=prior['candidate_bundle'],
                    artifacts=[{k: v for k, v in a.items() if k != '_bytes'} for a in artifacts],
                    profiles={k: [a['module_id'] for a in v] for k, v in clr.profiles(artifacts).items()},
                    files={p: dict(sha256=digest(data), size=len(data)) for p, data in sorted(result.items())})
    result['CLR-PACKAGE.json'] = release.encoded(metadata)
    return result


def verify(path):
    binary = Path(path).read_bytes()
    require(Path(str(path) + '.sha256').read_text().split() == [digest(binary), Path(path).name], 'package sidecar drift')
    with zipfile.ZipFile(io.BytesIO(binary)) as archive:
        names = archive.namelist()
        require(len(names) == len(set(names)) and all(n.startswith(PREFIX) and '..' not in n.split('/') and '\\' not in n for n in names), 'package paths')
        data = {name[len(PREFIX):]: archive.read(name) for name in names}
    metadata = json.loads(data['CLR-PACKAGE.json'])
    require(metadata['state'] == 'prepared_not_published' and metadata['publication_authorized'] is False, 'package authority')
    require(set(data) == set(metadata['files']) | {'CLR-PACKAGE.json'}, 'package file set')
    for name, pin in metadata['files'].items():
        require(pin == dict(sha256=digest(data[name]), size=len(data[name])), 'package file drift')
    require({a['module_id'] for a in metadata['artifacts']} == set(MODULES[1:]) and len(metadata['artifacts']) == 2, 'package module scope')
    prior = json.loads((ROOT / 'Releases/1.0.0/xlsx-sst-budget-correction.json').read_bytes())
    require(metadata['candidate_bundle'] == prior['candidate_bundle'], 'package provenance drift')
    expected_dlls = {'toolbelt.archive.zip-memory': prior['zip_dependency_sha256'],
                     'toolbelt.file.xlsx-memory': prior['candidate_dll_sha256']}
    for a in metadata['artifacts']:
        require(a['sha256'] == expected_dlls[a['module_id']] and a['origin'] == 'existing_qualified_sst_candidate', 'qualified DLL provenance drift')
        require(digest(data['Binaries/' + a['file']]) == a['sha256'] and hashlib.sha512(data['Binaries/' + a['file']]).hexdigest() == a['sha512'], 'package DLL drift')
    require(metadata['profiles'] == {p: list(MODULES[1:]) for p in ('Windows-local', 'Windows-central', 'Portable-local', 'Portable-central')}, 'package profiles')
    for profile in metadata['profiles']:
        require(data['SQL/Trust-' + profile + '.sql'] == clr.trust_sql(metadata['artifacts']), 'trust script drift')
    expected_sources = {'Sources/' + name: binary for name, binary in source_files_at(metadata['source_commit']).items()}
    require({name: value for name, value in data.items() if name.startswith('Sources/')} == expected_sources, 'package original source closure drift')
    return metadata


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path)
    parser.add_argument('--verify', type=Path)
    args = parser.parse_args()
    if args.verify:
        verify(args.verify)
        print('PASS XLSX PACKAGE FILE BINDING')
    else:
        require(args.output and not args.output.exists() and not Path(str(args.output) + '.sha256').exists(), 'fresh output required')
        args.output.parent.mkdir(parents=True, exist_ok=True)
        binary = release.write_zip(payload(), clr.PACKAGE)
        args.output.write_bytes(binary)
        Path(str(args.output) + '.sha256').write_text(digest(binary) + '  ' + args.output.name + '\n', encoding='ascii')
        verify(args.output)
        print('PASS XLSX PACKAGE PREPARED; NOT PUBLISHED')
