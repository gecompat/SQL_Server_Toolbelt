"""Exaktes ZIP-Callerrechte-Overlay über die historisch gebundene XLSX-Schicht."""
from pathlib import Path
import hashlib
import json
import subprocess
import zipfile
import io

XLSX_RECORD = 'Releases/1.0.0/xlsx-metadata-update.json'
XLSX_REPORTS = ('Releases/1.0.0/xlsx-raw-caller-profile.json',
                'Releases/1.0.0/xlsx-cell-caller-qualification.json')

BASELINE = 'e3b7aa4171181bc96d3df70bbde7f8200e47e303'
RECORD = 'Releases/1.0.0/zip-metadata-update.json'
REPORT = 'Releases/1.0.0/zip-caller-profile.json'
MANIFEST = 'Modules/toolbelt.archive.zip-memory/module.yaml'
PACKAGE = 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
SOURCE_ARCHIVE = 'Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip'
DOCS = tuple(sorted((
    'Modules/toolbelt.archive.zip-memory/README.md',
    'Modules/toolbelt.archive.zip-memory/Documentation/USP_ListZipEntriesFromBinary.md',
    'Modules/toolbelt.archive.zip-memory/Documentation/USP_ExtractZipEntryFromBinary.md',
    'Modules/toolbelt.archive.zip-memory/Documentation/USP_CreateZipFromEntries.md',
    'Modules/toolbelt.archive.zip-memory/Tests/README.md',
    'Modules/toolbelt.archive.zip-memory/Tests/ZIP_MEMORY_CONTRACT_TEST_MATRIX.md',
)))
PACKAGE_SOURCES = tuple(sorted((MANIFEST, *DOCS)))
OLD_PERMISSION_LINES = (
    '  - "EXECUTE auf toolbelt_archive.USP_CreateZipFromEntries"',
    '  - "EXECUTE auf toolbelt_archive.USP_ExtractZipEntryFromBinary"',
    '  - "EXECUTE auf toolbelt_archive.USP_ListZipEntriesFromBinary"',
    '  - "EXECUTE auf toolbelt_core.USP_PrepareResultTable bei Nutzung von @ResultTable"',
)
NEW_PERMISSION_LINES = (
    '  - "Liste: EXECUTE auf toolbelt_archive.USP_ListZipEntriesFromBinary und SELECT auf toolbelt_archive.TVF_InternalListZipEntriesClr; bei @ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable"',
    '  - "Extraktion: EXECUTE auf toolbelt_archive.USP_ExtractZipEntryFromBinary und SELECT auf toolbelt_archive.TVF_InternalExtractZipEntryClr; bei @ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable"',
    '  - "Writer: EXECUTE auf toolbelt_archive.USP_CreateZipFromEntries, SELECT auf toolbelt_archive.TVF_InternalZipWriterName und TVF_InternalZipWriterArchive sowie EXECUTE auf toolbelt_core.USP_PrepareResultTable für beide Ausgaberouten"',
)


def require(ok, message):
    if not ok:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def historical(root, path):
    require(path in (MANIFEST, REPORT, PACKAGE, SOURCE_ARCHIVE, XLSX_RECORD, *DOCS), 'Unbekannte ZIP-Historienquelle.')
    return subprocess.run(['git', 'show', BASELINE + ':' + path], cwd=root,
                          capture_output=True, check=True, timeout=30).stdout


def corrected_manifest(original):
    old = ('permissions_required:\n' + '\n'.join(OLD_PERMISSION_LINES)).encode('utf-8')
    new = ('permissions_required:\n' + '\n'.join(NEW_PERMISSION_LINES)).encode('utf-8')
    require(original.count(old) == 1, 'Historisches ZIP-Rechtefeld stimmt nicht exakt.')
    return original.replace(old, new)


def validate_manifest(original, current):
    require(current == corrected_manifest(original),
            'ZIP-Metadatenoverlay änderte Bytes außerhalb permissions_required.')


def validate_source(root, path, executed_digest):
    current = (Path(root) / path).read_bytes()
    if digest(current) == executed_digest:
        return
    require(path == MANIFEST, 'ZIP-Overlay ist nur für das eine Manifestfeld zulässig.')
    original = historical(root, MANIFEST)
    report_bytes = historical(root, REPORT)
    report = json.loads(report_bytes)
    require(digest(original) == executed_digest.lower()
            and (Path(root) / REPORT).read_bytes() == report_bytes
            and report['source_sha256'][MANIFEST].lower() == executed_digest.lower(),
            'ZIP-Manifestpin oder nativer Bericht weicht von der öffentlichen Basis ab.')
    validate_manifest(original, current)
    record = json.loads((Path(root) / RECORD).read_bytes())
    require(record['manifest'] == {'path': MANIFEST, 'executed_sha256': executed_digest.lower(),
                                   'current_sha256': digest(current)}
            and record['historical_report_sha256'] == digest(report_bytes),
            'ZIP-Metadatenrecord bindet Bericht oder Manifest nicht exakt.')


def make_record(root, product_source, old_files, new_files, old_package):
    report = historical(root, REPORT)
    xlsx_bytes = historical(root, XLSX_RECORD)
    xlsx = json.loads(xlsx_bytes)
    old_source_archive = historical(root, SOURCE_ARCHIVE)
    old_manifest = old_files[MANIFEST]
    current_manifest = new_files[MANIFEST]
    validate_manifest(old_manifest, current_manifest)
    require(json.loads(report)['source_sha256'][MANIFEST].lower() == digest(old_manifest),
            'ZIP-Nativepin stimmt nicht mit der vorigen Produktquelle überein.')
    record = {
        'schema_version': '1.0', 'kind': 'exact_zip_caller_metadata_projection',
        'date': '2026-10-26', 'public_baseline_commit': BASELINE,
        'publication_authorized': False, 'automatic_grants_added': False,
        'module_status_changed': False, 'module_status': 'partially validated',
        'release_status': 'unreleased', 'executable_source_bytes_changed': False,
        'executable_package_payload_changed': False, 'native_sql_attempts': 0,
        'manifest': {'path': MANIFEST, 'executed_sha256': digest(old_manifest),
                     'current_sha256': digest(current_manifest)},
        'historical_report_sha256': digest(report),
        'executed_package_sha256': json.loads(report)['artifact_binding']['executed_package_sha256'].lower(),
        'previous_clr_zip_sha256': digest(old_package),
        'previous_source_zip_path': SOURCE_ARCHIVE,
        'previous_source_zip_sha256': digest(old_source_archive),
        'product_chain_predecessor': xlsx['current_product_commit'],
        'previous_product_tree': xlsx['current_product_tree'],
        'current_product_commit': product_source['product_commit'],
        'current_product_tree': product_source['tree_oid'],
        'package_source_paths': list(PACKAGE_SOURCES),
        'previous_source_sha256': {p: digest(old_files[p]) for p in PACKAGE_SOURCES},
        'current_source_sha256': {p: digest(new_files[p]) for p in PACKAGE_SOURCES},
        'previous_documentation_sha256': {p: digest(old_files[p]) for p in DOCS},
        'current_documentation_sha256': {p: digest(new_files[p]) for p in DOCS},
        'xlsx_record_sha256': digest(xlsx_bytes),
    }
    return record


def validate_record(root, record, old_files, current_files, old_package, report_bytes=None):
    fields = {'schema_version', 'kind', 'date', 'public_baseline_commit',
              'publication_authorized', 'automatic_grants_added', 'module_status_changed',
              'module_status', 'release_status', 'executable_source_bytes_changed',
              'executable_package_payload_changed', 'native_sql_attempts', 'manifest',
              'historical_report_sha256', 'executed_package_sha256', 'previous_clr_zip_sha256',
              'previous_source_zip_path', 'previous_source_zip_sha256',
              'product_chain_predecessor', 'previous_product_tree', 'current_product_commit',
              'current_product_tree', 'package_source_paths', 'previous_source_sha256',
              'current_source_sha256', 'previous_documentation_sha256',
              'current_documentation_sha256', 'xlsx_record_sha256'}
    require(set(record) == fields and record['schema_version'] == '1.0'
            and record['kind'] == 'exact_zip_caller_metadata_projection'
            and record['date'] == '2026-10-26'
            and record['public_baseline_commit'] == BASELINE
            and record['publication_authorized'] is False
            and record['automatic_grants_added'] is False
            and record['module_status_changed'] is False
            and record['module_status'] == 'partially validated'
            and record['release_status'] == 'unreleased'
            and record['executable_source_bytes_changed'] is False
            and record['executable_package_payload_changed'] is False
            and record['native_sql_attempts'] == 0,
            'ZIP-Metadatenstatus oder Freigabegrenze driftet.')
    report_bytes = report_bytes or (Path(root) / REPORT).read_bytes()
    report = json.loads(report_bytes)
    xlsx_bytes = historical(root, XLSX_RECORD)
    require(report_bytes == historical(root, REPORT)
            and (Path(root) / XLSX_RECORD).read_bytes() == xlsx_bytes
            and record['historical_report_sha256'] == digest(report_bytes)
            and record['executed_package_sha256'] == report['artifact_binding']['executed_package_sha256'].lower()
            and record['executed_package_sha256'] == digest(old_package)
            and report['source_sha256'][MANIFEST].lower() == digest(old_files[MANIFEST]),
            'ZIP-Nativebericht, Ausführungspaket oder Manifestpin driftet.')
    validate_manifest(old_files[MANIFEST], current_files[MANIFEST])
    require(record['manifest'] == {'path': MANIFEST,
                                   'executed_sha256': digest(old_files[MANIFEST]),
                                   'current_sha256': digest(current_files[MANIFEST])},
            'ZIP-Manifestdelta ist nicht exakt gebunden.')
    require(record['product_chain_predecessor'] == json.loads((Path(root) / XLSX_RECORD).read_bytes())['current_product_commit']
            and record['xlsx_record_sha256'] == digest(xlsx_bytes)
            and record['previous_product_tree'] == json.loads(xlsx_bytes)['current_product_tree']
            and all(isinstance(record[k], str) and len(record[k]) == 40
                    and all(c in '0123456789abcdef' for c in record[k])
                    for k in ('product_chain_predecessor', 'previous_product_tree',
                              'current_product_commit', 'current_product_tree')),
            'Vorherige XLSX-Metadatenebene driftet.')
    require(record['previous_source_zip_path'] == SOURCE_ARCHIVE
            and record['previous_source_zip_sha256'] == digest(historical(root, SOURCE_ARCHIVE)),
            'Historische ZIP-Produktquelle ist nicht an das öffentliche Quellarchiv gebunden.')
    require(record['package_source_paths'] == list(PACKAGE_SOURCES)
            and record['previous_source_sha256'] == {p: digest(old_files[p]) for p in PACKAGE_SOURCES}
            and record['current_source_sha256'] == {p: digest(current_files[p]) for p in PACKAGE_SOURCES}
            and record['previous_documentation_sha256'] == {p: digest(old_files[p]) for p in DOCS}
            and record['current_documentation_sha256'] == {p: digest(current_files[p]) for p in DOCS},
            'ZIP-Quell- oder Dokumentationspins drifteten.')


def validate_product_delta(root, previous, current, record, baseline, old_package):
    validate_record(root, record, previous, current, old_package)
    require(digest(previous[MANIFEST]) == record['previous_source_sha256'][MANIFEST]
            and current[MANIFEST] == corrected_manifest(previous[MANIFEST]),
            'ZIP-Produktkorrektur fehlt oder überschreitet das Rechtefeld.')
    changed = {p for p in set(previous) | set(current)
               if p.startswith(('Modules/', 'Deployment/', 'Workers/'))
               and previous.get(p) != current.get(p)}
    require(changed == {MANIFEST, *DOCS}
            and {p: digest(current[p]) for p in DOCS} == record['current_documentation_sha256'],
            'ZIP-Produktdelta überschreitet Manifest und sechs gebundene Dokumentationspfade.')
    require(all(current[p] == baseline[p] for p in DOCS),
            'ZIP-Lesepfade stimmen nicht mit der öffentlichen Integrationsbasis überein.')
    return changed


def refreshed_clr_payload(previous, sources, record):
    result = dict(previous)
    metadata = json.loads(previous['CLR-PACKAGE.json'])
    require(metadata.get('xlsx_metadata_update_evidence') == 'Releases/1.0.0/xlsx-metadata-update.json'
            and 'XLSX-METADATA-UPDATE.json' in previous
            and 'zip_metadata_update_evidence' not in metadata
            and 'ZIP-METADATA-UPDATE.json' not in previous,
            'ZIP-Overlay benötigt exakt das bestehende XLSX-Paket als Vorgänger.')
    for path in PACKAGE_SOURCES:
        require(path in sources, f'ZIP-Paketquelle fehlt: {path}')
        result['Sources/' + path] = sources[path]
    result['ZIP-METADATA-UPDATE.json'] = (json.dumps(record, ensure_ascii=False, indent=2) + '\n').encode()
    metadata['zip_metadata_update_evidence'] = RECORD
    metadata['files'] = {p: {'sha256': digest(data), 'size': len(data)}
                         for p, data in sorted(result.items()) if p != 'CLR-PACKAGE.json'}
    result['CLR-PACKAGE.json'] = (json.dumps(metadata, ensure_ascii=False, indent=2) + '\n').encode()
    return result
