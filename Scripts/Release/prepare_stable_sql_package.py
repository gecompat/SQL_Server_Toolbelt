#!/usr/bin/env python3
"""Packt ausschließlich bereits qualifizierte Stable-SQL-Bytes; kein SQL/Build/Netzwerk."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import stat
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
RELEASE = Path('Releases/1.0.0')
SOURCE_NAME = 'SQL-Server-Toolbelt-1.0.0-candidate-source'
NAME = 'SQL-Server-Toolbelt-1.0.0-Stable-SQL'
SOURCE = RELEASE / 'Artifacts' / (SOURCE_NAME + '.zip')
PACKAGE = RELEASE / 'InstallPackages' / (NAME + '.zip')
SQL_NAMES = ('Install-Stable-local.sql', 'Install-Stable-central.sql')
ENTRIES = {*SQL_NAMES, 'LICENSE.md', 'START-HERE.md', 'PACKAGE-MANIFEST.json', 'SHA256SUMS'}
MAX_ARCHIVE = 64 * 1024 * 1024
MAX_ENTRY = 2 * 1024 * 1024


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + '\n').encode('utf-8')


def bounded_file(path: Path, maximum: int = MAX_ENTRY) -> bytes:
    require(path.is_file() and path.stat().st_size <= maximum, 'Datei fehlt oder Größenlimit überschritten.')
    with path.open('rb') as stream:
        data = stream.read(maximum + 1)
    require(len(data) <= maximum, 'Datei überschreitet Größenlimit.')
    return data


def checked_member(archive: zipfile.ZipFile, name: str) -> bytes:
    matches = [entry for entry in archive.infolist() if entry.filename == name]
    require(len(matches) == 1, 'ZIP-Eintrag fehlt oder ist doppelt.')
    entry = matches[0]
    kind = stat.S_IFMT(entry.external_attr >> 16)
    require(not entry.is_dir() and kind in (0, stat.S_IFREG) and not entry.flag_bits & 1,
            'Nur unverschlüsselte reguläre ZIP-Dateien erlaubt.')
    require(0 <= entry.file_size <= MAX_ENTRY, 'ZIP-Eintrag überschreitet Größenlimit.')
    with archive.open(entry) as stream:
        data = stream.read(MAX_ENTRY + 1)
    require(len(data) == entry.file_size and len(data) <= MAX_ENTRY, 'ZIP-Eintragsgröße abweichend.')
    return data


def expected_payload(root: Path = ROOT) -> dict[str, bytes]:
    source = bounded_file(root / SOURCE, MAX_ARCHIVE)
    checksum = bounded_file(root / (str(SOURCE) + '.sha256')).decode('ascii').split()
    require(len(checksum) == 2 and re.fullmatch('[0-9a-fA-F]{64}', checksum[0]) is not None
            and checksum[1] == SOURCE.name and checksum[0].lower() == sha(source),
            'Quellarchiv-Prüfsumme abweichend.')
    plan_bytes = bounded_file(root / RELEASE / 'release-plan.json')
    qualification_bytes = bounded_file(root / RELEASE / 'qualification.json')
    plan = json.loads(plan_bytes)
    native = json.loads(qualification_bytes)['native_package']
    stable = sorted(({'module_id': m['module_id'], 'module_version': m['module_version']}
                     for m in plan['modules'] if m['proposed_channel'] == 'stable'), key=lambda m: m['module_id'])
    require(plan['state'] == 'prepared_not_published' and plan['publication_authorized'] is False
            and len(stable) == len({m['module_id'] for m in stable}) == 19, 'Stable-Kandidatenumfang abweichend.')
    require(native['result'] == 'success' and native['stable_modules'] == 19
            and len(native['cases']) == 12 and set(native['sql_payload_sha256']) == set(SQL_NAMES),
            'Gebundene native SQL-Qualifikation fehlt.')
    payload = {}
    with zipfile.ZipFile(io.BytesIO(source)) as archive:
        # Ausschließlich feste Namen lesen; kein Extrahieren und keine fremden Module übernehmen.
        for name in (*SQL_NAMES, 'LICENSE.md'):
            payload[name] = checked_member(archive, SOURCE_NAME + '/' + name)
    for name in SQL_NAMES:
        require(sha(payload[name]) == native['sql_payload_sha256'][name], 'Nativ qualifizierter SQL-Payload abweichend.')
    require(payload['LICENSE.md'] == bounded_file(root / 'LICENSE.md'), 'Geschützter Lizenztext abweichend.')
    payload['START-HERE.md'] = bounded_file(root / RELEASE / 'STABLE-SQL-INSTALL.md')
    payload['PACKAGE-MANIFEST.json'] = canonical_json({
        'schema_version': 'toolbelt-stable-sql-package/v1', 'project_version': '1.0.0',
        'state': 'prepared_not_published', 'publication_authorized': False,
        'stable_candidates': stable, 'product_commit': plan['product_commit'],
        'source_archive_sha256': sha(source), 'release_plan_sha256': sha(plan_bytes),
        'qualification_sha256': sha(qualification_bytes),
        'historical_native_archive_sha256': native['archive_sha256'],
        'sql_payload_sha256': native['sql_payload_sha256'],
        'payload_native_qualification_reused': True, 'standalone_archive_native_execution': False,
        'qualification_scope': 'Existing twelve target/CL cases, local/central/consumer SQL payload scope only; no new full module, GUI, identity, TLS or production acceptance',
        'files_sha256': {name: sha(data) for name, data in sorted(payload.items())},
    })
    payload['SHA256SUMS'] = ''.join(sha(data) + '  ' + name + '\n'
                                  for name, data in sorted(payload.items())).encode('ascii')
    require(set(payload) == ENTRIES, 'Paketumfang abweichend.')
    return payload


def zip_payload(payload: dict[str, bytes]) -> bytes:
    output = io.BytesIO()
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(payload.items()):
            info = zipfile.ZipInfo(NAME + '/' + name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            archive.writestr(info, data, compresslevel=9)
    return output.getvalue()


def verify(data: bytes, root: Path = ROOT) -> None:
    require(len(data) <= MAX_ARCHIVE, 'Paket überschreitet Größenlimit.')
    expected = expected_payload(root)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        names = [entry.filename for entry in archive.infolist()]
        require(len(names) == len(ENTRIES) and set(names) == {NAME + '/' + n for n in ENTRIES},
                'Paket enthält fehlende, doppelte oder unerlaubte Pfade.')
        for name, value in expected.items():
            require(checked_member(archive, NAME + '/' + name) == value, 'Paketinhalt oder Herkunftsbindung abweichend.')
    require(data == zip_payload(expected), 'Paketcontainer ist nicht deterministisch reproduzierbar.')


def write_artifacts(output: Path, data: bytes) -> None:
    checksum = Path(str(output) + '.sha256')
    require(output.parent.is_dir() and not output.exists() and not checksum.exists(),
            'Ausgabeordner fehlt oder Ausgabe existiert bereits; kein Überschreiben.')
    identity = None
    try:
        with output.open('xb') as stream:
            own_stat = os.fstat(stream.fileno())
            identity = (own_stat.st_dev, own_stat.st_ino)
            stream.write(data)
        with checksum.open('xb') as stream:
            stream.write((sha(data) + '  ' + output.name + '\n').encode('ascii'))
    except BaseException:
        try:
            current = output.lstat()
            if (identity == (current.st_dev, current.st_ino) and stat.S_ISREG(current.st_mode)
                    and bounded_file(output, MAX_ARCHIVE) == data):
                output.unlink()
        except (OSError, ValueError):
            pass  # Unklare oder veränderte Ausgaben bleiben zur Prüfung erhalten.
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=('build', 'verify'))
    parser.add_argument('--output', type=Path, default=ROOT / PACKAGE)
    args = parser.parse_args()
    try:
        if args.operation == 'build':
            data = zip_payload(expected_payload())
            verify(data)
            write_artifacts(args.output, data)
        else:
            data = bounded_file(args.output, MAX_ARCHIVE)
            checksum = bounded_file(Path(str(args.output) + '.sha256')).decode('ascii').split()
            require(checksum == [sha(data), args.output.name], 'Paket-Prüfsumme abweichend.')
            verify(data)
        print('PASS Stable SQL package:19 candidates,2 unchanged qualified SQL payloads; prepared_not_published; no SQL executed')
        return 0
    except (ValueError, OSError, KeyError, TypeError, zipfile.BadZipFile) as error:
        # Keine fremden Dateiinhalte oder private Pfade in Ausgaben übernehmen.
        print('FAIL Stable SQL package (' + type(error).__name__ + ')', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
