"""Exakter XLSX-Callerrechte-Overlay; native Quellen und CLR-Payload bleiben unverändert."""
from pathlib import Path
import hashlib
import io
from importlib import import_module
import json
import subprocess
import zipfile
from functools import lru_cache
import csv_metadata

ROOT = Path(__file__).resolve().parents[2]

BASELINE = '69a69beebccdafd4c5a7a509d33cf374029ef0b6'
RECORD = 'Releases/1.0.0/xlsx-metadata-update.json'
MANIFEST = 'Modules/toolbelt.file.xlsx-memory/module.yaml'
PACKAGE = 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
PACKAGE_PREFIX = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
RAW_REPORT = 'Releases/1.0.0/xlsx-raw-caller-profile.json'
CELL_REPORT = 'Releases/1.0.0/xlsx-cell-caller-qualification.json'
OFFLINE_SOURCE = 'Tests/Release/test_xlsx_cell_caller_qualification.py'
PACKAGE_SOURCES = (
    MANIFEST,
    'Modules/toolbelt.file.xlsx-memory/README.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/TVF_FormatXlsxCell.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/TVF_InterpretXlsxCell.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md',
    'Modules/toolbelt.file.xlsx-memory/Tests/README.md',
    'Modules/toolbelt.file.xlsx-memory/Tests/XLSX_CONTRACT_TEST_MATRIX.md',
)
REPORTS = (RAW_REPORT, CELL_REPORT)
DOCUMENTATION_TRANSITION_START = '62ca5f4acc24d6e594f8d60db53fe1bb0d263ec3'
DOCUMENTATION_TRANSITION_PATHS = tuple(sorted({
    p for p in PACKAGE_SOURCES if p != MANIFEST
}))
HISTORICAL_SOURCE_ARCHIVE = 'Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip'
SCOPE_TEXT = ('Selected XLSX manifest and registered reading paths; additive proof and '
              'CLR-PACKAGE file-list/evidence metadata only. SQL and DLL payloads remain byte-identical.')
RECORD_FIELDS = {
    'schema_version', 'date', 'kind', 'public_baseline_commit', 'product_chain_predecessor',
    'publication_authorized', 'automatic_grants_added', 'module_status_changed', 'module_status',
    'release_status', 'executable_source_bytes_changed', 'native_sql_attempts', 'manifest',
    'offline_source_update', 'historical_reports_sha256', 'native_manifest_pins',
    'previous_clr_zip_sha256', 'package_source_paths', 'previous_package_source_sha256',
    'current_package_source_sha256', 'documentation_transition', 'changed_product_paths',
    'previous_source_sha256', 'current_source_sha256', 'executable_package_payload_changed',
    'clr_package_update_scope', 'historical_product_source',
    'current_product_commit', 'current_product_tree',
}
OLD_RAW_PERMISSION = '  - "EXECUTE auf den beiden öffentlichen USPs; ResultTable zusätzlich Helper-EXECUTE."'
NEW_RAW_PERMISSIONS = (
    '  - "Worksheetliste: EXECUTE auf toolbelt_file.USP_ListXlsxWorksheets sowie '
    'SELECT auf toolbelt_file.TVF_InternalXlsxSheets."\n'
    '  - "Rohzellen: EXECUTE auf toolbelt_file.USP_ReadXlsxWorksheetCells sowie '
    'SELECT auf toolbelt_file.TVF_InternalXlsxCells."\n'
    '  - "Bei ResultTable zusätzlich EXECUTE auf '
    'toolbelt_core.USP_PrepareResultTable."'
)


def require(ok, message):
    if not ok:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def canonical_text(data):
    """Match Git's repository bytes when a Windows checkout expands LF files."""
    return data.replace(b'\r\n', b'\n')


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8')


def historical(root, path):
    require(path in {*PACKAGE_SOURCES, *REPORTS, PACKAGE, OFFLINE_SOURCE},
            'Unbekannte XLSX-Historienquelle.')
    return subprocess.run(['git', 'show', BASELINE + ':' + path], cwd=root,
                          capture_output=True, check=True, timeout=30).stdout


def historical_at(root, commit, path):
    require(commit == BASELINE and path in DOCUMENTATION_TRANSITION_PATHS,
            'Git-Historienzugriff ist nur für die öffentliche XLSX-Basis zulässig.')
    return subprocess.run(['git', 'show', commit + ':' + path], cwd=root,
                          capture_output=True, check=True, timeout=30).stdout


@lru_cache(maxsize=2)
def _historical_source_archive(root: str, commit: str, path: str) -> tuple[bytes, bytes]:
    """Cache only immutable Git ZIP bytes/header, keyed by root, exact OID and path."""
    result = subprocess.run(['git', 'show', commit + ':' + path], cwd=root,
                            capture_output=True, check=True, timeout=30)
    archive = result.stdout
    prefix = 'SQL-Server-Toolbelt-1.0.0-candidate-source/'
    manifest_path = prefix + 'PACKAGE-MANIFEST.json'
    with zipfile.ZipFile(io.BytesIO(archive)) as package:
        matches = [entry for entry in package.infolist() if entry.filename == manifest_path]
        require(len(matches) == 1, 'Historisches XLSX-Recoverymanifest fehlt oder ist doppelt.')
        manifest = package.read(matches[0])
    return archive, manifest


def historical_source_archive(root, commit: str, path: str) -> tuple[bytes, bytes]:
    require(path == HISTORICAL_SOURCE_ARCHIVE
            and isinstance(commit, str) and len(commit) == 40
            and all(character in '0123456789abcdef' for character in commit),
            'Historische ZIP-Cachequelle ist nicht exakt gebunden.')
    return _historical_source_archive(str(Path(root).resolve()), commit, path)


def predecessor_source_binding(root):
    """Pin the predecessor recovery archive and its tree to the CSV evidence."""
    archive, manifest_bytes = historical_source_archive(root, BASELINE, HISTORICAL_SOURCE_ARCHIVE)
    manifest = json.loads(manifest_bytes)
    csv_record = json.loads((Path(root) / csv_metadata.RECORD).read_bytes())
    require(csv_record['current_product_commit'] == DOCUMENTATION_TRANSITION_START
            and manifest['product_commit'] == DOCUMENTATION_TRANSITION_START,
            'XLSX-Vorgänger ist nicht an den historischen CSV-Produktstand gebunden.')
    tree = csv_record['current_product_tree']
    require(isinstance(tree, str) and len(tree) == 40
            and all(character in '0123456789abcdef' for character in tree),
            'CSV-Vorgängerbaum fehlt für die XLSX-Recovery.')
    return {
        'archive_commit': BASELINE,
        'archive_path': HISTORICAL_SOURCE_ARCHIVE,
        'archive_sha256': digest(archive),
        'product_commit': DOCUMENTATION_TRANSITION_START,
        'product_tree': csv_record['current_product_tree'],
    }


def predecessor_product_sources(root, record):
    """Recover the transition predecessor only from its bound public archive."""
    release = import_module('prepare_release')
    require(Path(root).resolve() == Path(release.ROOT).resolve(),
            'XLSX-Übergangsquelle muss aus dem aktuellen Repository rekonstruiert werden.')
    binding = record['historical_product_source']
    require(record['product_chain_predecessor'] == DOCUMENTATION_TRANSITION_START
            and binding == predecessor_source_binding(root),
            'XLSX-Übergangsquelle ist nicht an die öffentliche Recoverybindung gebunden.')
    _, product_files, tree = release.qualification_sources(record['product_chain_predecessor'])
    require(tree == binding['product_tree'],
            'XLSX-Übergangsvorgängerbaum weicht vom gebundenen Archiv ab.')
    return product_files


def corrected_manifest(original):
    before = OLD_RAW_PERMISSION.encode('utf-8')
    require(original.count(before) == 1, 'Historischer XLSX-Rohleser-Rechteeintrag stimmt nicht.')
    return original.replace(before, NEW_RAW_PERMISSIONS.encode('utf-8'))


def validate_manifest(original, current):
    require(current == corrected_manifest(original),
            'Andere Manifestbytes neben dem exakt gebundenen Rohleser-Rechtefeld geändert.')


def corrected_offline_source(original):
    """Allow only the exact evidence hook needed to retain the original manifest pin."""
    require(b'import xlsx_metadata' not in original,
            'Historischer XLSX-Offlinequellstand enthält bereits den Overlayhook.')
    import_before = b'from test_xlsx_raw_caller_evidence import XlsxRawCallerEvidenceMixin\n'
    import_after = import_before + b'import xlsx_metadata\n'
    body_before = (b"            self.assertNotIn('..', Path(path).parts)\n"
                   b'            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)\n')
    body_after = (b"            self.assertNotIn('..', Path(path).parts)\n"
                  b'            if path == xlsx_metadata.MANIFEST:\n'
                  b'                xlsx_metadata.validate_source(ROOT, path, digest)\n'
                  b'                continue\n'
                  b'            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)\n')
    require(original.count(import_before) == 1 and original.count(body_before) == 1,
            'Historischer XLSX-Evidenztest hat eine andere Form als der gebundene Hook.')
    return original.replace(import_before, import_after).replace(body_before, body_after)


def validate_source(root, path, executed_digest):
    """Preserve the original native pin under this exact metadata-only overlay."""
    current = (Path(root) / path).read_bytes()
    if digest(current) == executed_digest:
        return
    if path == OFFLINE_SOURCE:
        original = historical(root, OFFLINE_SOURCE)
        raw = json.loads(historical(root, RAW_REPORT))
        prior_current = corrected_offline_source(original)
        require(raw['source_sha256'].get(OFFLINE_SOURCE, '').lower() == executed_digest.lower(),
                'XLSX-Evidenztest änderte mehr als den exakten Manifest-Overlayhook.')
        record = json.loads((Path(root) / RECORD).read_bytes())
        if current != prior_current:
            import zip_metadata
            zip_record = json.loads((Path(root) / zip_metadata.RECORD).read_bytes())
            zip_metadata.validate_xlsx_offline_source(root, zip_record)
            require(zip_record['offline_source_update']['execution_sha256'].lower() == executed_digest.lower(),
                    'ZIP-Folgeprojektion ist nicht an den nativen XLSX-Testpin gebunden.')
            return
        require(current == prior_current,
                'XLSX-Evidenztest änderte mehr als den exakten Manifest-Overlayhook.')
        require(record['offline_source_update'] == {
            'path': OFFLINE_SOURCE,
            'executed_sha256': raw['source_sha256'][OFFLINE_SOURCE],
            'current_sha256': digest(prior_current),
        }, 'XLSX-Evidenztest-Ausführungspin driftet.')
        return
    require(path == MANIFEST, 'XLSX-Overlay gilt ausschließlich für das Modulmanifest.')
    original = historical(root, MANIFEST)
    require(digest(original) == executed_digest.lower(),
            'XLSX-Manifest-Ausführungspin stimmt nicht mit der öffentlichen Basis überein.')
    validate_manifest(original, current)
    record = json.loads((Path(root) / RECORD).read_bytes())
    raw_bytes = (Path(root) / RAW_REPORT).read_bytes()
    cell_bytes = (Path(root) / CELL_REPORT).read_bytes()
    validate_reports(original, raw_bytes, cell_bytes)
    require(record['publication_authorized'] is False
            and record['manifest'] == {
                'path': MANIFEST,
                'executed_sha256': executed_digest.lower(),
                'current_sha256': digest(current),
            }
            and record['native_manifest_pins'] == {
                RAW_REPORT: json.loads(raw_bytes)['source_sha256'][MANIFEST],
                CELL_REPORT: json.loads(cell_bytes)['source_sha256'][MANIFEST],
            }
            and record['historical_reports_sha256'] == {
                RAW_REPORT: digest(canonical_text(raw_bytes)),
                CELL_REPORT: digest(canonical_text(cell_bytes)),
            }, 'XLSX-Metadatenoverlay erhält die historischen Ausführungspins nicht.')


def validate_reports(original_manifest, raw_bytes, cell_bytes):
    raw = json.loads(raw_bytes)
    cell = json.loads(cell_bytes)
    original_digest = digest(original_manifest)
    require(raw['result'] == 'PASS_WITH_EXPECTED_REJECTIONS_AND_ONE_RETAINED_FIXTURE_FAILURE'
            and raw['publication_authorized'] is False
            and raw['source_sha256'][MANIFEST].lower() == original_digest,
            'Raw-Reader-Nativebericht oder historischer Manifestpin stimmt nicht.')
    offline_pin = raw['source_sha256'].get(OFFLINE_SOURCE, '')
    require(len(offline_pin) == 64 and all(c in '0123456789abcdefABCDEF' for c in offline_pin),
            'Raw-Reader-Bericht enthält keinen gültigen ursprünglichen Offlinequellpin.')
    require(cell['result'] == 'PASS' and cell['publication_authorized'] is False
            and cell['source_sha256'][MANIFEST].lower() == original_digest,
            'Zell-Caller-Nativebericht oder historischer Manifestpin stimmt nicht.')
    raw_apis = {(x['name'], x['permission']) for x in raw['public_apis']}
    require(raw_apis == {('USP_ListXlsxWorksheets', 'EXECUTE'),
                         ('USP_ReadXlsxWorksheetCells', 'EXECUTE')},
            'Raw-Reader-API-Scope driftet.')
    cell_apis = {(x['name'], x['permission']) for x in cell['public_apis']}
    require(cell_apis == {('TVF_InterpretXlsxCell', 'SELECT'),
                          ('TVF_FormatXlsxCell', 'SELECT')},
            'Zell-Caller-API-Scope driftet.')
    require(raw['module_status'] == 'partially validated'
            and raw['release_status'] == 'unreleased'
            and cell['module_versions']['toolbelt.file.xlsx-memory'] == '1.2.0',
            'XLSX-Statusprojektion driftet.')
    return raw, cell


def validate_record(record, original_manifest, current_manifest, previous_package,
                    previous_payload, current_payload, raw_bytes, cell_bytes):
    require(set(record) == RECORD_FIELDS
            and record['schema_version'] == '1.0'
            and record['date'] == '2026-10-26'
            and record['kind'] == 'exact_xlsx_caller_metadata_projection'
            and record['public_baseline_commit'] == BASELINE
            and record['product_chain_predecessor'] == DOCUMENTATION_TRANSITION_START
            and record['publication_authorized'] is False
            and record['automatic_grants_added'] is False
            and record['module_status_changed'] is False
            and record['module_status'] == 'partially validated'
            and record['release_status'] == 'unreleased'
            and record['executable_source_bytes_changed'] is False
            and record['executable_package_payload_changed'] is False
            and record['native_sql_attempts'] == 0,
            'XLSX-Metadatenautorität oder Statusgrenze driftet.')
    require(record['historical_product_source'] == predecessor_source_binding(ROOT),
            'XLSX-Historienquelle ist nicht exakt an Archiv, Produktcommit und Produktbaum gebunden.')
    product_source = json.loads((ROOT / 'Releases/1.0.0/product-source.json').read_bytes())
    zip_path = ROOT / 'Releases/1.0.0/zip-metadata-update.json'
    if zip_path.is_file():
        import zip_metadata
        zip_record = json.loads(zip_path.read_bytes())
    else:
        zip_metadata = None
        zip_record = None
    if zip_record is not None and zip_record.get('product_chain_predecessor') == record['current_product_commit']:
        # ZIP ist eine spätere Metadatenstufe. XLSX bleibt an seinem aus dem
        # öffentlichen ZIP-Vorgängerarchiv rekonstruierten e89-Tree gebunden.
        require((ROOT / RECORD).read_bytes() == zip_metadata.historical(ROOT, RECORD)
                and zip_record.get('xlsx_record_sha256') == digest(zip_metadata.historical(ROOT, RECORD)),
                'Historischer XLSX-Produktrecord driftet innerhalb der ZIP-Stufe.')
        archive = zip_metadata.historical(ROOT, zip_metadata.SOURCE_ARCHIVE)
        require(digest(archive) == zip_record.get('previous_source_zip_sha256'),
                'Öffentliche ZIP-Vorgängerquelle für XLSX stimmt nicht mit ihrem Hash überein.')
        source_prefix = 'SQL-Server-Toolbelt-1.0.0-candidate-source/'
        with zipfile.ZipFile(io.BytesIO(archive)) as source_archive:
            source_manifest = json.loads(source_archive.read(source_prefix + 'PACKAGE-MANIFEST.json'))
        release = import_module('prepare_release')
        _, _, recovered_tree = release.recovered_snapshot(
            release.read_zip(archive)[source_prefix + 'PREPARATION.bundle'],
            source_manifest['source_commit'], source_manifest['product_commit'])
        require(source_manifest['product_commit'] == record['current_product_commit']
                and recovered_tree == record['current_product_tree']
                and recovered_tree == zip_record['previous_product_tree'],
                'Historischer XLSX-Produktcommit oder Produktbaum driftet.')
    else:
        require(record['current_product_commit'] == product_source['product_commit']
                and record['current_product_tree'] == product_source['tree_oid']
                and product_source['base_commit'] == BASELINE,
                'XLSX-Aktuellproduktcommit oder Produktbaum driftet.')
    validate_manifest(original_manifest, current_manifest)
    validate_reports(original_manifest, raw_bytes, cell_bytes)
    require(record['manifest'] == {
        'path': MANIFEST,
        'executed_sha256': digest(original_manifest),
        'current_sha256': digest(current_manifest),
    }, 'Historischer und aktueller XLSX-Manifestpin driftet.')
    offline_original = historical(ROOT, OFFLINE_SOURCE)
    offline_current = corrected_offline_source(offline_original)
    raw_report = json.loads(raw_bytes)
    require(record['offline_source_update'] == {
        'path': OFFLINE_SOURCE,
        'executed_sha256': raw_report['source_sha256'][OFFLINE_SOURCE],
        'current_sha256': digest(offline_current),
    }, 'XLSX-Offlineevidenztest ist nicht exakt an seinen alten Quellpin gebunden.')
    require(record['historical_reports_sha256'] == {
        RAW_REPORT: digest(canonical_text(raw_bytes)), CELL_REPORT: digest(canonical_text(cell_bytes)),
    }, 'XLSX-Callerberichte sind unvollständig oder verändert.')
    raw_report, cell_report = json.loads(raw_bytes), json.loads(cell_bytes)
    require(record['native_manifest_pins'] == {
        RAW_REPORT: raw_report['source_sha256'][MANIFEST],
        CELL_REPORT: cell_report['source_sha256'][MANIFEST],
    }, 'Native XLSX-Manifestpins wurden verändert.')
    require(record['package_source_paths'] == list(PACKAGE_SOURCES),
            'XLSX-Paketquellliste wurde erweitert oder umgeordnet.')
    require(record['previous_clr_zip_sha256'] == digest(previous_package),
            'Historisches CLR-Paket weicht vom gebundenen Ausgangspaket ab.')
    require(record['previous_package_source_sha256'] == {
        p: digest(previous_payload['Sources/' + p]) for p in PACKAGE_SOURCES
    }, 'Paketquellen des XLSX-Ausgangspakets weichen ab.')
    require(record['current_package_source_sha256'] == {
        p: digest(current_payload[p]) for p in PACKAGE_SOURCES
    }, 'Aktuelle XLSX-Paketquellen weichen ab.')
    require(record['changed_product_paths'] == [MANIFEST],
            'XLSX-Produktdelta enthält mehr als das Rechtefeld.')
    require(record['previous_source_sha256'] == {MANIFEST: digest(original_manifest)}
            and record['current_source_sha256'] == {MANIFEST: digest(current_manifest)},
            'XLSX-Produktquellpins drifteten.')
    transition_previous_files = predecessor_product_sources(ROOT, record)
    require(record['documentation_transition']['from_commit'] == DOCUMENTATION_TRANSITION_START
            and record['documentation_transition']['to_commit'] == BASELINE
            and record['documentation_transition']['paths'] == list(DOCUMENTATION_TRANSITION_PATHS)
            and record['documentation_transition']['previous_source_sha256'] == {
                p: digest(transition_previous_files[p])
                for p in DOCUMENTATION_TRANSITION_PATHS
            }
            and record['documentation_transition']['current_source_sha256'] == {
                p: digest(historical_at(ROOT, BASELINE, p)) for p in DOCUMENTATION_TRANSITION_PATHS
            },
            'XLSX-Dokumentationsbasis oder Übergangspfad driftet.')
    require(record['clr_package_update_scope'] == SCOPE_TEXT,
            'XLSX-CLR-Paketumfang beansprucht unbekannte Änderungen.')


def refreshed_clr_payload(previous, sources, record):
    """Kopiert genau die ausgewählten XLSX-Lesepfade und lässt CSV-Provenienz bestehen."""
    result = dict(previous)
    metadata = json.loads(previous['CLR-PACKAGE.json'])
    require(metadata.get('metadata_update_evidence') == 'Releases/1.0.0/csv-metadata-update.json'
            and 'METADATA-UPDATE.json' in previous,
            'Vorhandene CSV-Metadatenprojektion fehlt oder ist verändert.')
    require('xlsx_metadata_update_evidence' not in metadata
            and 'XLSX-METADATA-UPDATE.json' not in previous,
            'XLSX-Metadatenoverlay existiert bereits; kein impliziter Replay.')
    for path in PACKAGE_SOURCES:
        require(path in sources, f'XLSX-Paketquelle fehlt: {path}')
        result['Sources/' + path] = sources[path]
    result['XLSX-METADATA-UPDATE.json'] = encoded(record)
    metadata['xlsx_metadata_update_evidence'] = RECORD
    metadata['files'] = {p: {'sha256': digest(data), 'size': len(data)}
                         for p, data in sorted(result.items()) if p != 'CLR-PACKAGE.json'}
    result['CLR-PACKAGE.json'] = encoded(metadata)
    return result


def make_record(root, previous_package, previous_payload, current_sources,
                previous_files, current_files, transition_previous_files,
                transition_current_files):
    original_manifest = historical(root, MANIFEST)
    current_manifest = current_sources[MANIFEST]
    validate_manifest(original_manifest, current_manifest)
    require(previous_files[MANIFEST] == original_manifest,
            'XLSX-Metadatenoverlay muss direkt auf der gebundenen Produktbasis aufsetzen.')
    changed = {p for p in set(previous_files) | set(current_files)
               if p.startswith(('Modules/', 'Deployment/', 'Workers/'))
               and previous_files.get(p) != current_files.get(p)}
    require(changed == {MANIFEST}, 'XLSX-Produktdelta enthält weitere Laufzeit-/Metadatendateien.')
    transition_changed = {p for p in set(transition_previous_files) | set(transition_current_files)
                          if p.startswith(('Modules/', 'Deployment/', 'Workers/'))
                          and transition_previous_files.get(p) != transition_current_files.get(p)}
    require(transition_changed == set(DOCUMENTATION_TRANSITION_PATHS)
            and all(p.endswith('.md') for p in transition_changed),
            'Vorheriger XLSX-Dokumentationsübergang ist nicht exakt der veröffentlichte Lesepfad.')
    require(all(current_sources[p] == transition_current_files[p] for p in DOCUMENTATION_TRANSITION_PATHS),
            'Aktuelle XLSX-Lesepfade weichen vom gebundenen Integrationsstand ab.')
    raw_bytes = historical(root, RAW_REPORT)
    cell_bytes = historical(root, CELL_REPORT)
    raw, cell = validate_reports(original_manifest, raw_bytes, cell_bytes)
    product_commit, product_tree = _current_product_binding(root)
    offline_source = corrected_offline_source(historical(root, OFFLINE_SOURCE))
    record = {
        'schema_version': '1.0',
        'date': '2026-10-26',
        'kind': 'exact_xlsx_caller_metadata_projection',
        'public_baseline_commit': BASELINE,
        'product_chain_predecessor': DOCUMENTATION_TRANSITION_START,
        'historical_product_source': predecessor_source_binding(root),
        # Eine spätere ZIP-Metadatenstufe besitzt den aktuellen Produktdeskriptor.
        # Die XLSX-Projektion bleibt an ihren eigenen Produktstand gebunden.
        'current_product_commit': product_commit,
        'current_product_tree': product_tree,
        'publication_authorized': False,
        'automatic_grants_added': False,
        'module_status_changed': False,
        'module_status': 'partially validated',
        'release_status': 'unreleased',
        'executable_source_bytes_changed': False,
        'native_sql_attempts': 0,
        'manifest': {
            'path': MANIFEST,
            'executed_sha256': digest(original_manifest),
            'current_sha256': digest(current_manifest),
        },
        'offline_source_update': {
            'path': OFFLINE_SOURCE,
            'executed_sha256': raw['source_sha256'][OFFLINE_SOURCE],
            'current_sha256': digest(offline_source),
        },
        'historical_reports_sha256': {
            RAW_REPORT: digest(canonical_text(raw_bytes)),
            CELL_REPORT: digest(canonical_text(cell_bytes)),
        },
        'native_manifest_pins': {
            RAW_REPORT: raw['source_sha256'][MANIFEST],
            CELL_REPORT: cell['source_sha256'][MANIFEST],
        },
        'previous_clr_zip_sha256': digest(previous_package),
        'package_source_paths': list(PACKAGE_SOURCES),
        'previous_package_source_sha256': {
            p: digest(previous_payload['Sources/' + p]) for p in PACKAGE_SOURCES
        },
        'current_package_source_sha256': {
            p: digest(current_sources[p]) for p in PACKAGE_SOURCES
        },
        'documentation_transition': {
            'from_commit': DOCUMENTATION_TRANSITION_START,
            'to_commit': BASELINE,
            'paths': list(DOCUMENTATION_TRANSITION_PATHS),
            'previous_source_sha256': {
                p: digest(transition_previous_files[p]) for p in DOCUMENTATION_TRANSITION_PATHS
            },
            'current_source_sha256': {
                p: digest(transition_current_files[p]) for p in DOCUMENTATION_TRANSITION_PATHS
            },
        },
        'changed_product_paths': sorted(changed),
        'previous_source_sha256': {p: digest(previous_files[p]) for p in sorted(changed)},
        'current_source_sha256': {p: digest(current_files[p]) for p in sorted(changed)},
        'executable_package_payload_changed': False,
        'clr_package_update_scope': SCOPE_TEXT,
    }
    validate_record(record, original_manifest, current_manifest, previous_package,
                    previous_payload, current_sources, raw_bytes, cell_bytes)
    return record


def validate_product_delta(previous, current, record, baseline):
    """Erlaubt nur das exakt gebundene permissions_required-Feld."""
    require(record['public_baseline_commit'] == BASELINE
            and record['publication_authorized'] is False,
            'XLSX-Produktbasis oder Veröffentlichungsgrenze driftet.')
    changed = {p for p in set(previous) | set(current)
               if p.startswith(('Modules/', 'Deployment/', 'Workers/'))
               and previous.get(p) != current.get(p)}
    require(changed == {MANIFEST} and record['changed_product_paths'] == [MANIFEST],
            'XLSX-Produktdelta überschreitet das einzelne Callerrechtefeld.')
    require(previous[MANIFEST] == baseline[MANIFEST],
            'Historisches XLSX-Manifest widerspricht der gebundenen Produktbasis.')
    validate_manifest(baseline[MANIFEST], current[MANIFEST])
    require(record['manifest'] == {
        'path': MANIFEST,
        'executed_sha256': digest(previous[MANIFEST]),
        'current_sha256': digest(current[MANIFEST]),
    }, 'XLSX-Produktdelta-Manifestpins drifteten.')
    require(record['previous_source_sha256'] == {p: digest(previous[p]) for p in sorted(changed)}
            and record['current_source_sha256'] == {p: digest(current[p]) for p in sorted(changed)},
            'XLSX-Produktquellpins drifteten.')
    return changed


def validate_documentation_transition(previous, current, record):
    """Bind the already-integrated XLSX documentation sources before metadata cleanup."""
    transition = record['documentation_transition']
    changed = {p for p in set(previous) | set(current)
               if p.startswith(('Modules/', 'Deployment/', 'Workers/'))
               and previous.get(p) != current.get(p)}
    paths = set(DOCUMENTATION_TRANSITION_PATHS)
    require(changed == paths and transition['paths'] == sorted(paths)
            and all(p.endswith('.md') for p in changed),
            'Historischer XLSX-Dokumentationsübergang überschreitet den gebundenen Lesepfad.')
    require(transition['previous_source_sha256'] == {p: digest(previous[p]) for p in sorted(paths)}
            and transition['current_source_sha256'] == {p: digest(current[p]) for p in sorted(paths)},
            'Historischer XLSX-Dokumentationsübergang driftet.')
    return changed


def validate_clr_delta(root, previous_package, previous, current, record, sources):
    original_manifest = historical(root, MANIFEST)
    current_manifest = sources[MANIFEST]
    raw_bytes = sources[RAW_REPORT]
    cell_bytes = sources[CELL_REPORT]
    validate_record(record, original_manifest, current_manifest, previous_package,
                    previous, sources, raw_bytes, cell_bytes)
    expected = refreshed_clr_payload(previous, sources, record)
    require(current == expected, 'CLR-Paketdelta überschreitet das begrenzte XLSX-Metadatenoverlay.')
    for path in PACKAGE_SOURCES:
        require(digest(sources[path]) == record['current_package_source_sha256'][path],
                'XLSX-Paketquelle stimmt nicht mit ihrem aktuellen Pin überein.')
    for path in set(previous) | set(current):
        if path.startswith(('SQL/', 'Binaries/')):
            require(previous.get(path) == current.get(path), 'XLSX-Overlay änderte SQL- oder DLL-Payloadbytes.')
    return {p for p in set(previous) | set(current) if previous.get(p) != current.get(p)}


def _current_product_binding(root):
    """Liefert den Produktstand dieser Metadatenebene, nicht spätere Overlays."""
    zip_path = Path(root) / 'Releases/1.0.0/zip-metadata-update.json'
    if zip_path.is_file():
        zip_record = json.loads(zip_path.read_bytes())
        return zip_record['product_chain_predecessor'], zip_record['previous_product_tree']
    product = json.loads((Path(root) / 'Releases/1.0.0/product-source.json').read_bytes())
    return product['product_commit'], product['tree_oid']
