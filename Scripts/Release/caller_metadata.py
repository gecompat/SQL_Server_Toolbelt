"""Sechs belegte Caller-Rechtekorrekturen, keine allgemeine Manifestmigration.

Die ursprünglichen Ausführungsdateien und Pins bleiben unverändert. Nur das
vollständige, exakt erwartete permissions_required-Feld darf sich unterscheiden.
Alle übrigen Bytes einschließlich Status, Dependencies und Deployment bleiben
gebunden; SELECT/EXECUTE wird nicht automatisch erteilt.
"""
from pathlib import Path
import hashlib
import json
import subprocess

BASELINE = 'f6a7daa3a176510d04dc2914c958ca91954e7feb'
RECORD = 'Releases/1.0.0/caller-metadata-update.json'
REPORTS = ('conversion-caller-qualification.json', 'utility-caller-qualification.json',
           'json-schema-caller-profile.json')
SCHEMA_LIFECYCLE = ('Lifecycle: vollständige Metadatensicht und passende CREATE-/Schema-DDL-Rechte; '
                    'bekannter1.0.0→1.0.1-Upgrade zusätzlich vorhandenes ALTER-Recht auf '
                    'ASSEMBLY::Toolbelt_JsonSchema. Keine Rechtevergabe.')
RIGHTS = {
    'toolbelt.conversion.base64': [
        'SELECT auf toolbelt_conversion.TVF_Base64Encode, TVF_Base64Decode, TVF_Base64EncodeStatus und TVF_Base64DecodeStatus',
        'EXECUTE auf toolbelt_conversion.SVF_Base64Encode und SVF_Base64Decode'],
    'toolbelt.conversion.integer-base': [
        'SELECT auf toolbelt_conversion.TVF_IntegerToBase und TVF_TryBaseToInteger',
        'EXECUTE auf toolbelt_conversion.SVF_IntegerToBase und SVF_TryBaseToInteger'],
    'toolbelt.conversion.uri-component': [
        'SELECT auf toolbelt_conversion.TVF_UriComponentEncode, TVF_UriComponentDecode, TVF_UriComponentEncodeStatus und TVF_UriComponentDecodeStatus',
        'EXECUTE auf toolbelt_conversion.SVF_UriComponentEncode und SVF_UriComponentDecode'],
    'toolbelt.metadata.identifier': [
        'SELECT auf toolbelt_metadata.TVF_ParseMultipartName',
        'EXECUTE auf toolbelt_metadata.SVF_QuoteMultipartName'],
    'toolbelt.validation.semantic-version': [
        'SELECT auf toolbelt_validation.TVF_ParseSemanticVersion, TVF_CompareSemanticVersion und TVF_SemanticVersionSortKey',
        'EXECUTE auf toolbelt_validation.SVF_SemanticVersionSortKey und SVF_CompareSemanticVersion'],
    'toolbelt.json.schema': [
        'Datenpfad: EXECUTE auf toolbelt_json.USP_ValidateJsonSchema und toolbelt_core.USP_PrepareResultTable sowie SELECT auf toolbelt_json.FT_ValidateJsonSchemaInternal; gemeinsam auch bei direkter Ausgabe erforderlich',
        SCHEMA_LIFECYCLE],
}
PATHS = {f'Modules/{module}/module.yaml': module for module in RIGHTS}
READMES = {f'Modules/{module}/README.md': module for module in RIGHTS}


def corrected_readme(path, baseline):
    require(path in READMES, 'Unbekannter Caller-Lesepfad.')
    module = READMES[path]
    if module.startswith('toolbelt.conversion.'):
        old = ('Die ältere pauschale SELECT-/REFERENCES-Formulierung im Manifest ist für Scalarwrapper veraltet; '
               'ihr gebundener Metadaten-/Paketrefresh bleibt separat offen.')
        new = ('Das [korrigierte Manifest samt Paketbindung](../../Releases/1.0.0/CALLER-METADATA-UPDATE.md) '
               'nennt die Rechte je Funktion. Frühere Scalarheader sind historische Kommentare; maßgeblich sind diese Einzelrechte.')
    elif module == 'toolbelt.json.schema':
        old = ('das eingefrorene pauschale Manifestlabel wird separat gepflegt. Status und Artefakte bleiben unverändert.')
        new = ('das [aktuelle Manifest samt Paketbindung](../../Releases/1.0.0/CALLER-METADATA-UPDATE.md) '
               'führt alle drei Rechte. Modulstatus und ausführbare SQL-/DLL-Bytes bleiben unverändert.')
    else:
        old = ('Die ältere generische SELECT-/REFERENCES-Formulierung im Manifest beziehungsweise Scalarheader ist '
               'veraltet und bleibt bis zum getrennten gebundenen Metadaten-/Paketrefresh ausdrücklich als Erratum geführt.')
        new = ('Das [korrigierte Manifest samt Paketbindung](../../Releases/1.0.0/CALLER-METADATA-UPDATE.md) '
               'nennt SELECT für TVFs und EXECUTE für Scalarwrapper. Ältere Scalarheader bleiben historische '
               'Kommentare; maßgeblich sind die hier genannten, nativ geprüften Einzelrechte.')
    before = old.encode()
    require(baseline.count(before) == 1, 'Öffentlicher Caller-Lesepfad stimmt nicht.')
    return baseline.replace(before, new.encode())


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def corrected_manifest(path, original):
    require(path in PATHS, 'Kein freigegebener Caller-Metadatenpfad.')
    module = PATHS[path]
    if module == 'toolbelt.json.schema':
        old = 'permissions_required: ["Aufruf: vorhandenes EXECUTE; ' + SCHEMA_LIFECYCLE + '"]'
    elif module == 'toolbelt.conversion.uri-component':
        old = 'permissions_required: ["SELECT oder REFERENCES auf den Functions", "DDL-Rechte für Deploy und Uninstall"]'
    else:
        category = 'Scalar-valued Functions' if module.startswith('toolbelt.conversion.') else 'Functions'
        old = 'permissions_required:\n  - "SELECT oder REFERENCES auf den ' + category + '"\n  - "DDL-Rechte für Deploy und Uninstall"'
    values = RIGHTS[module] + ([] if module == 'toolbelt.json.schema' else ['DDL-Rechte für Deploy und Uninstall'])
    new = 'permissions_required:\n' + '\n'.join('  - ' + json.dumps(v, ensure_ascii=False) for v in values)
    before, after = old.encode(), new.encode()
    require(original.count(before) == 1, 'Unerwartete historische Caller-Rechteformulierung.')
    return original.replace(before, after)


def validate_manifest(path, original, current):
    require(current == corrected_manifest(path, original),
            'Andere Manifestbytes neben den exakt belegten Caller-Rechten geändert.')


def historical_manifest(root, path):
    require(path in PATHS, 'Historischer Zugriff nur auf sechs Caller-Manifeste.')
    result = subprocess.run(['git', 'show', BASELINE + ':' + path], cwd=root,
                            capture_output=True, timeout=30, check=True)
    return result.stdout


def validate_source(root, path, executed_digest):
    """Unveränderte Quellen exakt prüfen; sechs Metadatenänderungen getrennt belegen."""
    current = (Path(root) / path).read_bytes()
    if digest(current) == executed_digest:
        return
    original = historical_manifest(root, path)
    require(digest(original) == executed_digest, 'Originaler Ausführungspin stimmt nicht.')
    validate_manifest(path, original, current)
    record = json.loads((Path(root) / RECORD).read_bytes())
    require(record['public_baseline_commit'] == BASELINE and record['publication_authorized'] is False,
            'Caller-Metadatenbasis oder Veröffentlichungsgrenze driftet.')
    require(record['manifests'][path] == {'executed_sha256': executed_digest,
                                        'current_sha256': digest(current)},
            'Historische und aktuelle Manifestbindung driftet.')


def validate_product_delta(previous, current, record, baseline):
    """Nur sechs Rechtefelder und bereits öffentliche Markdownpflege zulassen."""
    paths = {p for p in set(previous) | set(current)
             if p.startswith(('Modules/', 'Deployment/', 'Workers/'))}
    changed = {p for p in paths if previous.get(p) != current.get(p)}
    require(set(PATHS) <= changed and set(record['manifests']) == set(PATHS),
            'Die sechs Caller-Metadatenkorrekturen sind unvollständig.')
    require(record['public_baseline_commit'] == BASELINE and record['publication_authorized'] is False,
            'Unbekannte Caller-Metadatenbasis.')
    reports = {f'Releases/1.0.0/{p}' for p in REPORTS}
    require(set(record['historical_reports_sha256']) == reports,
            'Caller-Ausführungsberichte unvollständig gebunden.')
    for path in reports:
        require(current[path] == baseline[path]
                and digest(current[path]) == record['historical_reports_sha256'][path],
                'Originaler Caller-Ausführungsbericht geändert.')
    for path in changed:
        if path in PATHS:
            require(previous[path] == baseline[path], 'Historische Caller-Manifeste widersprechen der öffentlichen Basis.')
            validate_manifest(path, previous[path], current[path])
            require(record['manifests'][path] == {'executed_sha256': digest(previous[path]),
                                                'current_sha256': digest(current[path])}, 'Manifestpin driftet.')
        elif path in READMES:
            require(current[path] == corrected_readme(path, baseline[path]),
                    'Caller-Lesepfad besitzt andere als die ausgewählten Korrekturen.')
        else:
            require(path.endswith('.md') and current.get(path) == baseline.get(path),
                    'Runtime-/Deployment-/Vertragsänderung neben Caller-Metadaten.')
    require(sorted(changed) == record['changed_product_paths'], 'Caller-Produktdelta driftet.')
    for files, field in ((previous, 'previous_source_sha256'), (current, 'current_source_sha256')):
        require(record[field] == {p: digest(files[p]) if p in files else None for p in sorted(changed)},
                'Caller-Produktquellbindung driftet.')
    return changed
