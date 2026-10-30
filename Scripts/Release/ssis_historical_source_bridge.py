"""Historische Quellen gegen ihre eingefrorenen Artefakte prüfen, nicht gegen HEAD."""
from pathlib import Path
import hashlib
import io
import stat
import zipfile

import new_ssis_standalone_tsql as standalone


ARCHIVE = 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
ARCHIVE_SHA256 = '896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287'
PREFIX = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/Sources/'
MAX_ARCHIVE_BYTES = 32 * 1024 * 1024
MAX_SOURCE_BYTES = 1024 * 1024
BOUNDARY_TEST = 'Tests/Release/test_xlsx_boundary_evidence.py'
BOUNDARY_TEST_CURRENT_SHA256 = 'c41138df973120e30c6948e779f5cfe92d138214c09da2b9e05d6cab1aac606e'
SOURCES = {
    'Modules/toolbelt.tsql.ssis-debug/module.yaml': {
        'historical': 'ab519faa5743e872f44e70499ebafcdeeed065e079eec2e95e8d5c518286bf8f',
    },
    'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs': {
        'historical': '33331e397100720c2413ac75d22ac25cd23cda4b7816bfa30338c2f14808829b',
    },
}


def _sha(data):
    return hashlib.sha256(data).hexdigest()


def source_paths():
    return frozenset(SOURCES)


def validate_historical_source(root, path, expected_sha256):
    """Exakte damalige Bytes liefern; dies qualifiziert keine aktuelle Implementierung."""
    root = Path(root).resolve()
    if not isinstance(path, str) or path not in SOURCES:
        raise ValueError('SSIS_HISTORICAL_SOURCE_PATH')
    binding = SOURCES[path]
    if not isinstance(expected_sha256, str) or expected_sha256.lower() != binding['historical']:
        raise ValueError('SSIS_HISTORICAL_SOURCE_PIN')
    archive_path = root / ARCHIVE
    archive_bytes = standalone.read_regular_bounded(archive_path, MAX_ARCHIVE_BYTES)
    if _sha(archive_bytes) != ARCHIVE_SHA256:
        raise ValueError('SSIS_HISTORICAL_ARCHIVE_PIN')
    entry_name = PREFIX + path
    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        matches = [entry for entry in archive.infolist() if entry.filename == entry_name]
        if (len(matches) != 1 or matches[0].is_dir() or
                (matches[0].external_attr >> 16) & 0o170000 == stat.S_IFLNK):
            raise ValueError('SSIS_HISTORICAL_SOURCE_ENTRY')
        if matches[0].file_size > MAX_SOURCE_BYTES:
            raise ValueError('SSIS_HISTORICAL_SOURCE_SIZE')
        original = archive.read(matches[0])
    if _sha(original) != binding['historical']:
        raise ValueError('SSIS_HISTORICAL_SOURCE_ARCHIVE_BYTES')
    return original


def read_r28_api_source(root, path, expected_sha256):
    """Die damalige API bleibt im qualifizierten R28-Paket unverändert überprüfbar."""
    expected = '9f99b9a24d3a0535e156a313def1ed723ff62f17aa2e4859ac58c41e51bc1001'
    if (path != 'Modules/toolbelt.tsql.ssis-debug/Contracts/Api.json' or
            not isinstance(expected_sha256, str) or expected_sha256.lower() != expected):
        raise ValueError('SSIS_R28_API_SOURCE_PIN')
    archive_path = Path(root) / 'Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-ComponentsV2-1.0.0-Install-Windows.zip'
    data = standalone.read_regular_bounded(archive_path, MAX_ARCHIVE_BYTES)
    if _sha(data) != '73e601da0d57f694b68d2339589c037c72f3905d9855cefff37863cc32183e9a':
        raise ValueError('SSIS_R28_ARCHIVE_PIN')
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        entry = archive.getinfo('SSIS-Debug-ComponentsV2-1.0.0-Install-Windows/' + path)
        if entry.is_dir() or entry.file_size > MAX_SOURCE_BYTES:
            raise ValueError('SSIS_R28_API_SOURCE_SIZE')
        original = archive.read(entry)
    if _sha(original) != expected:
        raise ValueError('SSIS_R28_API_SOURCE_BYTES')
    return original


def restore_boundary_test_transition(root, current, expected_sha256):
    """Remove only the three SSIS bridge lines before the older Help projection runs."""
    import help_contract_source

    if expected_sha256 != help_contract_source.BOUNDARY_BASELINE_SHA256:
        raise ValueError('SSIS_BOUNDARY_TEST_BASELINE_PIN')
    root = Path(root).resolve()
    actual = standalone.read_regular_bounded(root / BOUNDARY_TEST, MAX_SOURCE_BYTES)
    import parameter_help_transition
    try:
        actual = parameter_help_transition.restore_verifier_source(root, BOUNDARY_TEST, actual)
        current = parameter_help_transition.restore_verifier_source(root, BOUNDARY_TEST, current)
    except ValueError as error:
        raise ValueError('SSIS_BOUNDARY_TEST_CURRENT_BYTES') from error
    if not isinstance(current, bytes) or current != actual or _sha(current) != BOUNDARY_TEST_CURRENT_SHA256:
        raise ValueError('SSIS_BOUNDARY_TEST_CURRENT_BYTES')
    replacements = (
        (b'import ssis_historical_source_bridge\n', b''),
        (b'                elif relative in ssis_historical_source_bridge.source_paths():\n'
         b'                    data = ssis_historical_source_bridge.validate_historical_source(ROOT, relative, expected)\n', b''),
    )
    restored = current
    for before, after in replacements:
        if restored.count(before) != 1:
            raise ValueError('SSIS_BOUNDARY_TEST_TRANSITION_ANCHOR')
        restored = restored.replace(before, after, 1)
    if _sha(restored) != help_contract_source.BOUNDARY_CURRENT_SHA256:
        raise ValueError('SSIS_BOUNDARY_TEST_TRANSITION_OUTPUT')
    return restored
