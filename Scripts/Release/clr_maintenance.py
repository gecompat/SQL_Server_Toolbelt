"""Exact XLSX-only maintenance derivation; previous deliveries remain immutable.

The full package retains the previous qualification for unchanged components.
This module does not build assemblies, execute SQL, grant trust, or publish.
"""
from pathlib import Path
import hashlib
import io
import json
import re
import zipfile

import prepare_clr_package as package
import prepare_release as release
import documentation_history

BASE_SHA256 = '896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287'
BINARY_SHA256 = 'f1f604492bc69d9787b0582493f4045ae7363c61723d9e166717442253bb5abd'
BASE_DRIVER_SHA256 = 'd59b0e8ab956d3576bc265fbf7139f123edce1dcdee995205ebee53d9c4d39cb'
BOUNDARY_FIXTURE_SHA256 = '939b47ca1d9a9ac34c50782a752fd7a39f9a446bcd345bfa33633f0d7a757f62'
BINARY = 'Binaries/Toolbelt.File.XlsxMemory.dll'
CANDIDATE = 'Releases/1.0.0/Artifacts/Xlsx-Sst-Budget-Candidate.zip'
CANDIDATE_SHA256 = '6d9607709c018bd881f0b4224ab95175159d0fe80ae6d79be33bd2f878e89d20'
LOCATION = 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Maintenance.zip'
RECORD = 'Releases/1.0.0/clr-maintenance-qualification.json'
MODULE = 'Modules/toolbelt.file.xlsx-memory/'
SQL_SOURCES = tuple(MODULE + 'Source/' + name + '.sql' for name in (
    'TVF_FormatXlsxCell', 'TVF_InterpretXlsxCell',
    'USP_ListXlsxWorksheets', 'USP_ReadXlsxWorksheetCells'))
SOURCE_OVERRIDES = SQL_SOURCES + (MODULE + 'Clr/Workbook.cs',) + tuple(
    MODULE + 'Documentation/' + name + '.md' for name in (
        'USP_ListXlsxWorksheets', 'USP_ReadXlsxWorksheetCells'))
QUALIFICATION_SCOPE = {
    'new': 'XLSX+ZIP dependency+ResultTable selected installation, help, stored TVF comments, exact 50000/50001 boundary on 12 cases local/central',
    'inherited': 'Unchanged remaining DLLs and lifecycle qualification from immutable baseline package',
    'not_executed': ['New full-profile SSIS execution', 'New full-profile lifecycle replay',
                     'Authenticated TLS qualification'],
}
REPORT_KEYS = frozenset((
    'schema_version', 'date', 'status', 'publication_authorized', 'release_status',
    'baseline_package_sha256', 'replacement_dll_sha256', 'unchanged_other_dlls',
    'maximum_milliseconds', 'qualification_scope', 'native_cases',
    'current_sources_sha256', 'method_sha256', 'executed_driver_sha256',
    'executed_fixture_sha256', 'selected_install_sha256'))
CASE_KEYS = frozenset(('platform', 'version', 'cl', 'patch', 'modes', 'result',
                       'independent_cleanup_audit'))


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read_base(root):
    data = (Path(root) / package.LOCATION).read_bytes()
    release.require(sha(data) == BASE_SHA256, 'Maintenance baseline package differs.')
    prefix = package.PACKAGE + '/'
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        names = archive.namelist()
        release.require(len(set(names)) == len(names) and all(n.startswith(prefix) for n in names),
                        'Maintenance baseline entries differ.')
        return {n[len(prefix):]: archive.read(n) for n in names}


def derive(root):
    """Only known literal replacements and four whole source inclusions change SQL."""
    root = Path(root)
    before = read_base(root)
    result = dict(before)
    candidate = (root / CANDIDATE).read_bytes()
    release.require(sha(candidate) == CANDIDATE_SHA256, 'Qualified SST candidate archive differs.')
    with zipfile.ZipFile(io.BytesIO(candidate)) as archive:
        binary = archive.read(BINARY)
    release.require(sha(binary) == BINARY_SHA256, 'Unqualified replacement DLL.')
    originals = {p: before['Sources/' + p] for p in SQL_SOURCES}
    current = {p: documentation_history.qualification_bytes(root, p).replace(b'\r\n', b'\n') for p in SOURCE_OVERRIDES}
    old_dll = before[BINARY]
    old_hash = hashlib.sha512(old_dll).digest()
    new_hash = hashlib.sha512(binary).digest()

    def replace_known_token(data, old_value, new_value):
        """Ersetzt nur den bekannten DLL- oder SHA-512-Token in erlaubten Schreibweisen."""
        found = 0
        for uppercase in (False, True):
            old_hex = old_value.hex().encode('ascii')
            new_hex = new_value.hex().encode('ascii')
            if uppercase:
                old_hex = old_hex.upper()
                new_hex = new_hex.upper()
            layouts = ((b'', b''), (b'\\\n', b'\\\n'), (b'\\\r\n', b'\\\r\n'))
            for separator, output_separator in layouts:
                if separator:
                    old_body = separator.join(old_hex[i:i + 4096] for i in range(0, len(old_hex), 4096))
                    new_body = output_separator.join(new_hex[i:i + 4096] for i in range(0, len(new_hex), 4096))
                else:
                    old_body, new_body = old_hex, new_hex
                old_token = b'0x' + old_body
                new_token = b'0x' + new_body
                offset = 0
                while True:
                    index = data.find(old_token, offset)
                    if index < 0:
                        break
                    end = index + len(old_token)
                    before_is_hex = index > 0 and data[index - 1] in b'0123456789abcdefABCDEF'
                    after_is_hex = end < len(data) and data[end] in b'0123456789abcdefABCDEF'
                    if not before_is_hex and not after_is_hex:
                        data = data[:index] + new_token + data[end:]
                        found += 1
                        offset = index + len(new_token)
                    else:
                        offset = index + 2
        return data, found

    dll_tokens = 0
    hash_tokens = 0
    for name, data in before.items():
        if not name.startswith('SQL/'):
            continue
        changed, dll_count = replace_known_token(data, old_dll, binary)
        changed, hash_count = replace_known_token(changed, old_hash, new_hash)
        dll_tokens += dll_count
        hash_tokens += hash_count
        if name.startswith(('SQL/Install-', 'SQL/Repeat-')):
            for path, original in originals.items():
                release.require(changed.count(original) == 1,
                                'Maintenance source inclusion is missing or ambiguous.')
                changed = changed.replace(original, current[path])
        result[name] = changed
    release.require(dll_tokens > 0 and dll_tokens == hash_tokens,
                    'Maintenance DLL/hash token counts differ.')
    result[BINARY] = binary
    for path, data in current.items():
        result['Sources/' + path] = data
    guide = (root / 'Releases/1.0.0/CLR-INSTALL.md').read_bytes().replace(b'\r\n', b'\n')
    guide = guide.replace(b'(../../', b'(https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/')
    guide = guide.replace(b'(InstallPackages/', b'(https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/InstallPackages/')
    result['START-HERE.md'] = guide.replace(b'(CLR-MAINTENANCE.md)', b'(https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/CLR-MAINTENANCE.md)')
    metadata = json.loads(result.pop('CLR-PACKAGE.json'))
    result.pop('QUALIFICATION.json')
    metadata['baseline_source_commit'] = metadata.pop('source_commit')
    metadata['baseline_build_source_commit'] = metadata.pop('build_source_commit')
    metadata['source_provenance'] = 'immutable_baseline_with_explicit_xlsx_override'
    metadata['artifact_build_overrides'] = {'toolbelt.file.xlsx-memory': {
        'evidence': 'Releases/1.0.0/xlsx-sst-budget-correction.json',
        'candidate_archive': CANDIDATE,
        'candidate_archive_sha256': CANDIDATE_SHA256,
        'dll_sha256': BINARY_SHA256,
        'source_projection': 'qualified_executed_workbook_to_canonical_lf',
    }}
    # Never present the previous package's native report as a new execution.
    metadata['qualification_state'] = 'pending'
    metadata['maintenance_scope'] = 'existing_xlsx_dll_and_seven_explicit_sources'
    metadata['maintenance_baseline_sha256'] = BASE_SHA256
    metadata['maintenance_qualification_evidence'] = RECORD
    for artifact in metadata['artifacts']:
        if artifact['module_id'] == 'toolbelt.file.xlsx-memory':
            artifact['sha256'] = sha(binary)
            artifact['sha512'] = new_hash.hex()
    metadata['files'] = {name: {'sha256': sha(data), 'size': len(data)}
                         for name, data in sorted(result.items())}
    result['CLR-PACKAGE.json'] = release.encoded(metadata)
    return result


def write_private(root, output):
    root, output = Path(root), Path(output)
    release.require(output.resolve().is_relative_to((root / '.runtime').resolve())
                    and not output.exists(), 'Maintenance draft must be new and private.')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(release.write_zip(derive(root), package.PACKAGE))
    Path(str(output) + '.sha256').write_text(sha(output.read_bytes()) + '  ' + output.name + '\n', encoding='ascii')
    return output


def selected_xlsx_export(payload, mode):
    """Extract whole canonical module sections, never execute unrelated modules."""
    release.require(mode in ('local', 'central'), 'Invalid maintenance deployment mode.')
    sql = payload['SQL/Install-Portable-' + mode + '.sql']
    header = sql.split(b'-- BEGIN MODULE ', 1)[0]
    sections = []
    for module in ('toolbelt.core.result-table', 'toolbelt.archive.zip-memory',
                   'toolbelt.file.xlsx-memory'):
        pattern = (rb'(?m)^-- BEGIN MODULE ' + re.escape(module.encode())
                   + rb'\n.*?^-- END MODULE ' + re.escape(module.encode()) + rb'\n')
        matches = list(re.finditer(pattern, sql, re.S))
        release.require(len(matches) == 1, 'Missing or ambiguous maintenance module section.')
        sections.append(matches[0][0] + b'GO\n')
    return header + b''.join(sections)


def qualified_payload(root, record):
    release.require(isinstance(record, dict) and set(record) == REPORT_KEYS,
                    'Maintenance qualification fields are missing or unknown.')
    release.require(record['schema_version'] == 'toolbelt-clr-maintenance/v1'
                    and record['date'] == '2026-10-28'
                    and record['status'] == 'PASS_XLSX_INSTALL_HELP_SST_DELTA'
                    and record['release_status'] == 'unreleased'
                    and record['qualification_scope'] == QUALIFICATION_SCOPE
                    and record['publication_authorized'] is False
                    and record['baseline_package_sha256'] == BASE_SHA256
                    and record['replacement_dll_sha256'] == BINARY_SHA256
                    and record['unchanged_other_dlls'] == 12
                    and record['maximum_milliseconds'] == 5000,
                    'Maintenance qualification scope differs.')
    expected = {(platform, version, level)
                for platform in ('linux', 'windows')
                for version, levels in (('2019', (150,)), ('2022', (150, 160)),
                                        ('2025', (150, 160, 170))) for level in levels}
    cases = record['native_cases']
    release.require(isinstance(cases, list) and all(isinstance(c, dict) and set(c) == CASE_KEYS for c in cases),
                    'Maintenance native case fields are missing or unknown.')
    release.require(len(cases) == 12 and
                    {(c['platform'], c['version'], c['cl']) for c in cases} == expected
                    and all(c['modes'] == ['local', 'central'] and c['result'] == 'PASS'
                            and c['independent_cleanup_audit'] == 'PASS'
                            and c['patch'] == ('latest' if c['platform'] == 'linux' else
                                {'2019': 'cu32', '2022': 'cu26', '2025': 'cu8'}[c['version']])
                            for c in cases),
                    'Maintenance native matrix or audits are incomplete.')
    release.require(set(record['current_sources_sha256']) == set(SOURCE_OVERRIDES),
                    'Maintenance source scope differs.')
    for path, pin in record['current_sources_sha256'].items():
        release.require(sha(documentation_history.qualification_bytes(root, path).replace(b'\r\n', b'\n')) == pin,
                        'Maintenance qualified source differs.')
    for path, pin in record['method_sha256'].items():
        release.require(sha(documentation_history.qualification_method_bytes(root, path).replace(b'\r\n', b'\n')) == pin,
                        'Maintenance qualification method differs.')
    release.require(set(record['method_sha256']) == {
        'Scripts/Release/clr_maintenance.py',
        'Tests/Release/Runtime/Xlsx.MaintenanceHelp.sql',
        'Tests/Release/Invoke-XlsxSharedStringBoundaryLab.ps1',
        'Tests/Release/Runtime/Xlsx.SharedStringCount.sql'},
        'Maintenance methods are missing or broadened.')
    import xlsx_sst_budget
    driver = (Path(root) / 'Tests/Release/Invoke-XlsxSharedStringBoundaryLab.ps1').read_bytes().replace(b'\r\n', b'\n')
    release.require(sha(driver) == BASE_DRIVER_SHA256,
                    'Maintenance cannot silently change the prior bounded driver or its cleanup.')
    release.require(record['executed_driver_sha256'] == sha(xlsx_sst_budget.project_boundary_driver(driver)),
                    'Maintenance driver is not the unchanged bounded driver projection.')
    boundary = (Path(root) / 'Tests/Release/Runtime/Xlsx.SharedStringCount.sql').read_bytes().replace(b'\r\n', b'\n')
    release.require(sha(boundary) == BOUNDARY_FIXTURE_SHA256, 'Maintenance fixed SST oracle differs.')
    fixture = ((Path(root) / 'Tests/Release/Runtime/Xlsx.MaintenanceHelp.sql').read_bytes().replace(b'\r\n', b'\n')
               + b'\n' + boundary)
    release.require(record['executed_fixture_sha256'] == sha(fixture),
                    'Maintenance fixture is not the exact help and unchanged boundary composition.')
    payload = derive(root)
    release.require(record['selected_install_sha256'] == {
        mode: sha(selected_xlsx_export(payload, mode)) for mode in ('local', 'central')},
        'Maintenance executed module selection differs.')
    metadata = json.loads(payload.pop('CLR-PACKAGE.json'))
    payload['QUALIFICATION.json'] = release.encoded(record)
    metadata['qualification_state'] = 'composed_qualified'
    metadata['qualification_evidence'] = RECORD
    metadata['files'] = {name: {'sha256': sha(data), 'size': len(data)}
                         for name, data in sorted(payload.items())}
    payload['CLR-PACKAGE.json'] = release.encoded(metadata)
    return payload


def verify(root, path=None):
    root = Path(root)
    path = root / LOCATION if path is None else Path(path)
    record = json.loads((root / RECORD).read_bytes())
    expected = release.write_zip(qualified_payload(root, record), package.PACKAGE)
    actual = path.read_bytes()
    release.require(actual == expected, 'Maintenance package is not the exact qualified derivation.')
    release.require(Path(str(path) + '.sha256').read_text(encoding='ascii').split()
                    == [sha(actual), path.name], 'Maintenance checksum differs.')
    # The inherited component report is validated against its original bytes.
    package.verify(root / package.LOCATION)
    print('PASS CLR_MAINTENANCE one XLSX replacement; 12 inherited DLLs; 12 native delta cases and audits')
    return record


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify', type=Path)
    parser.add_argument('--prepare-private', type=Path)
    args = parser.parse_args()
    if args.prepare_private:
        write_private(release.ROOT, args.prepare_private)
    else:
        verify(release.ROOT, args.verify)
