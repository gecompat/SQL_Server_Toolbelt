"""Exact CSV caller metadata overlay; executable qualification is unchanged."""
from pathlib import Path
import hashlib
import json
import subprocess

BASELINE = '89e17e9879b0ce22e63ecd63e3374fe1323fb9a7'
RECORD = 'Releases/1.0.0/csv-metadata-update.json'
MANIFEST = 'Modules/toolbelt.file.csv-memory/module.yaml'
REPORT = 'Releases/1.0.0/csv-caller-profile.json'
GUIDE = 'Releases/1.0.0/CLR-INSTALL.md'
GUIDE_NOTE = ('\n## CSV-Aufrufrechte\n\n'
              'CSV-Parser und -Writer benötigen unterschiedliche vorhandene Objektrechte; '
              'ResultTable ergänzt das Helper-EXECUTE. Die [gebundene Rechte- und Paketübersicht]'
              '(CSV-METADATA-UPDATE.md) nennt die exakten Profile. Die Installation erteilt keine Aufrufrechte. '
              'Die Sources behalten ihre repositoryrelativen Verweise; zusammenhängendes Offline-Lesen '
              'verwendet das vollständige Quellpaket, Online-Lesen die verlinkte Projektdokumentation.\n')
OLD = '  - "Vorhandenes EXECUTE auf den öffentlichen USPs und der verwendeten ResultTable-Runtime; keine Rechtevergabe."'
RIGHTS = (
    'Datenpfad Parser: EXECUTE auf toolbelt_file.USP_ParseCsv und SELECT auf toolbelt_file.TVF_InternalParseCsv.',
    'Datenpfad Writer: EXECUTE auf toolbelt_file.USP_WriteCsv sowie auf toolbelt_file.SVF_InternalMeasureCsvCell und toolbelt_file.SVF_InternalQuoteCsvCell.',
    'Nur bei ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable in derselben Datenbank; keine automatische Rechtevergabe.',
)
DOCS = {
    'Modules/toolbelt.file.csv-memory/README.md': (
        'Zwölf Ziel-/CL-Fälle bestanden; Manifest-/Paketwortlaut und weitere Gates bleiben separat.',
        'Zwölf Ziel-/CL-Fälle bestanden. Das [korrigierte Manifest mit Paketbindung](../../Releases/1.0.0/CSV-METADATA-UPDATE.md) nennt diese Rechte; weitere Gates bleiben separat.'),
    'Modules/toolbelt.file.csv-memory/Documentation/USP_ParseCsv.md': (
        'Manifest-/Paketwortlaut bleibt als Folgepflege offen.',
        'Das [korrigierte Manifest mit Paketbindung](../../../Releases/1.0.0/CSV-METADATA-UPDATE.md) übernimmt diese vorhandenen Rechte.'),
    'Modules/toolbelt.file.csv-memory/Documentation/USP_WriteCsv.md': (
        'Manifest-/Paketwortlaut bleibt als Folgepflege offen.',
        'Das [korrigierte Manifest mit Paketbindung](../../../Releases/1.0.0/CSV-METADATA-UPDATE.md) übernimmt diese vorhandenen Rechte.'),
    'Modules/toolbelt.file.csv-memory/Tests/README.md': (
        'Gesamtqualifikation und Manifest-/Paketpflege bleiben separat.',
        'Die [CSV-Metadaten-/Paketpflege](../../../Releases/1.0.0/CSV-METADATA-UPDATE.md) ist getrennt gebunden; Gesamtqualifikation bleibt separat.'),
}


def require(ok, message):
    if not ok:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def historical(root, path):
    require(path in {MANIFEST, REPORT, GUIDE, *DOCS}, 'Unknown CSV historical source.')
    return subprocess.run(['git', 'show', BASELINE + ':' + path], cwd=root,
                          capture_output=True, check=True, timeout=30).stdout


def corrected_manifest(original):
    before = OLD.encode()
    require(original.count(before) == 1, 'Unexpected CSV permission baseline.')
    after = '\n'.join('  - ' + json.dumps(v, ensure_ascii=False) for v in RIGHTS).encode()
    return original.replace(before, after)


def corrected_documentation(path, original):
    require(path in DOCS, 'Unknown CSV documentation correction.')
    before, after = (x.encode() for x in DOCS[path])
    require(original.count(before) == 1, 'Unexpected CSV documentation baseline.')
    return original.replace(before, after)


def validate_manifest(original, current):
    require(current == corrected_manifest(original), 'CSV changes exceed exact caller permission field.')


def corrected_install_guide(original, packaged=False):
    require(b'## CSV-Aufrufrechte' not in original, 'CSV guide already updated; no implicit replay.')
    note = GUIDE_NOTE
    if packaged:
        note = note.replace('(CSV-METADATA-UPDATE.md)',
                            '(https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/CSV-METADATA-UPDATE.md)')
    return original + note.encode()


def validate_record(record, original_manifest, current_manifest, report):
    require(record['schema_version'] == '1.0' and record['kind'] == 'exact_csv_caller_metadata_projection'
            and record['public_baseline_commit'] == BASELINE
            and record['publication_authorized'] is False
            and record['automatic_grants_added'] is False and record['module_statuses_changed'] is False,
            'CSV metadata authority or publication boundary drifted.')
    validate_manifest(original_manifest, current_manifest)
    require(record['manifest'] == {'path': MANIFEST, 'executed_sha256': digest(original_manifest),
                                   'current_sha256': digest(current_manifest)}
            and record['historical_report_sha256'] == digest(report), 'CSV executed source/report pin drifted.')
    native = json.loads(report)
    require(native['result'] == 'PASS' and native['publication_authorized'] is False
            and native['source_sha256'][MANIFEST] == digest(original_manifest), 'CSV native authority drifted.')


def validate_source(root, path, executed_digest):
    current = (Path(root) / path).read_bytes()
    if digest(current) == executed_digest:
        return
    import parameter_help_transition
    if path in parameter_help_transition.PATHS:
        parameter_help_transition.predecessor_source(root, path, executed_digest)
        return
    require(path == MANIFEST, 'Only the exact CSV manifest has a metadata exception.')
    original = historical(root, MANIFEST)
    report = historical(root, REPORT)
    require(executed_digest == digest(original) and (Path(root) / REPORT).read_bytes() == report,
            'Historical CSV execution bytes changed.')
    validate_record(json.loads((Path(root) / RECORD).read_bytes()), original, current, report)


def validate_product_delta(previous, current, record, baseline):
    """No runtime, SSIS, unknown manifest or unpublished documentation changes."""
    validate_record(record, baseline[MANIFEST], current[MANIFEST], baseline[REPORT])
    require(current[REPORT] == baseline[REPORT] and previous[MANIFEST] == baseline[MANIFEST],
            'CSV historical product or report changed.')
    paths = {p for p in set(previous) | set(current) if p.startswith(('Modules/', 'Deployment/', 'Workers/'))}
    changed = {p for p in paths if previous.get(p) != current.get(p)}
    require(MANIFEST in changed, 'CSV product correction is missing.')
    for path in changed:
        if path == MANIFEST:
            continue
        if path in DOCS:
            require(current[path] == corrected_documentation(path, baseline[path]),
                    'CSV reading path exceeds exact correction.')
        else:
            require(path.endswith('.md') and current.get(path) == baseline.get(path),
                    'Unqualified product change alongside CSV metadata.')
    require(record['changed_product_paths'] == sorted(changed), 'CSV product delta list drifted.')
    for files, key in ((previous, 'previous_source_sha256'), (current, 'current_source_sha256')):
        require(record[key] == {p: digest(files[p]) if p in files else None for p in sorted(changed)},
                'CSV product source pins drifted.')
    return changed


def refreshed_clr_payload(previous, files, source_commit, record):
    """Only selected CSV Sources and additive provenance; no SQL/binary rebuild."""
    result = dict(previous)
    result['START-HERE.md'] = corrected_install_guide(previous['START-HERE.md'], packaged=True)
    for path in (MANIFEST, *DOCS):
        result['Sources/' + path] = files[path]
    result['METADATA-UPDATE.json'] = (json.dumps(record, ensure_ascii=False, indent=2) + '\n').encode()
    metadata = json.loads(previous['CLR-PACKAGE.json'])
    require('metadata_update_evidence' not in metadata, 'CSV overlay already present; no implicit replay.')
    metadata['metadata_baseline_source_commit'] = metadata['source_commit']
    metadata['source_commit'] = source_commit
    metadata['metadata_update_evidence'] = RECORD
    metadata['files'] = {p: {'sha256': digest(b), 'size': len(b)} for p, b in sorted(result.items())
                         if p != 'CLR-PACKAGE.json'}
    result['CLR-PACKAGE.json'] = (json.dumps(metadata, ensure_ascii=False, indent=2) + '\n').encode()
    return result


def validate_clr_delta(previous, current, record, files, source_commit):
    expected = refreshed_clr_payload(previous, files, source_commit, record)
    require(current == expected, 'CLR payload exceeds exact CSV source metadata overlay.')
    for path in (MANIFEST, *DOCS):
        require(digest(files[path]) == record['current_source_sha256'][path], 'CLR CSV source pin drifted.')
    return {p for p in set(previous) | set(current) if previous.get(p) != current.get(p)}
