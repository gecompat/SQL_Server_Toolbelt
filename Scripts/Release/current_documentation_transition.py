"""Exact follow-up documentation transition; historical qualification bytes stay immutable."""
from __future__ import annotations

from pathlib import Path, PurePosixPath
import hashlib
import json
import os
import stat
import zipfile
import io


RECORD_PATH = 'Releases/1.0.0/documentation-followup-transition.json'
RECORD_SHA256 = 'b28ca23fb826c8f710d3e74fe7812b46cd4d6a75aa4cbd5f1b0aaac60c578155'
ARCHIVE_PATH = 'Scripts/Release/HistoricalSources/documentation-followup-20261030/Baseline.zip'
ARCHIVE_SHA256 = '33b7c78b9b81061de675a610060f2aa58e52ba72dba5a52d2e45c4cf5d801aea'
MAX_RECORD_BYTES = 16 * 1024
MAX_ARCHIVE_BYTES = 1024 * 1024
MAX_SOURCE_BYTES = 128 * 1024
MAX_TOTAL_SOURCE_BYTES = 512 * 1024
PATHS = frozenset({
    'Modules/toolbelt.core.execution-cancel/Documentation/EXECUTION_CANCELLATION_OBJECTS.md',
    'Modules/toolbelt.core.second-session/Documentation/SECOND_SESSION_OBJECTS.md',
    'Modules/toolbelt.file.content/Documentation/USP_LoadBinaryFile.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md',
    'Modules/toolbelt.file.content/Documentation/USP_LoadTextFile.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md',
    'Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md',
    'Modules/toolbelt.core.event-log/Documentation/EVENT_LOG_OBJECTS.md',
    'Modules/toolbelt.file.csv-memory/Documentation/USP_ParseCsv.md',
    'Modules/toolbelt.file.csv-memory/Documentation/USP_WriteCsv.md',
})
RECORD_KEYS = {
    'schema_version', 'date', 'kind', 'status', 'publication_authorized',
    'native_requalification_claimed', 'current_head_ci_required', 'baseline_commit',
    'integrating_commit', 'scope', 'archive_path', 'archive_sha256', 'license_sha256',
    'before_source_sha256', 'after_source_sha256',
}


class DocumentationTransitionError(ValueError):
    """Raised when the exact documented source transition or its inputs drift."""


def _require(ok: bool, message: str) -> None:
    if not ok:
        raise DocumentationTransitionError(message)


def _digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _read_regular(root: Path, relative: str, maximum: int) -> bytes:
    pure = PurePosixPath(relative)
    _require(not pure.is_absolute() and '\\' not in relative and
             all(part not in ('', '.', '..') for part in pure.parts),
             'documentation transition path is unsafe')
    candidate = root.joinpath(*pure.parts)
    current = root
    reparse = getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0x400)
    for part in pure.parts[:-1]:
        current = current / part
        metadata = current.lstat()
        _require(stat.S_ISDIR(metadata.st_mode) and
                 not getattr(metadata, 'st_file_attributes', 0) & reparse,
                 'documentation transition parent is not a regular directory')
    before = candidate.lstat()
    _require(stat.S_ISREG(before.st_mode) and
             not getattr(before, 'st_file_attributes', 0) & reparse and
             before.st_size <= maximum,
             'documentation transition input is not a bounded regular file')
    with candidate.open('rb') as stream:
        opened = os.fstat(stream.fileno())
        _require(stat.S_ISREG(opened.st_mode) and opened.st_size == before.st_size and
                 not getattr(opened, 'st_file_attributes', 0) & reparse,
                 'documentation transition input changed while opening')
        data = stream.read(maximum + 1)
    _require(len(data) == before.st_size and len(data) <= maximum,
             'documentation transition input changed while reading')
    return data


def _unique_json(pairs):
    result = {}
    for key, value in pairs:
        _require(key not in result, 'documentation transition JSON has duplicate fields')
        result[key] = value
    return result


def _load(root: Path):
    root = Path(root).resolve(strict=True)
    record_bytes = _read_regular(root, RECORD_PATH, MAX_RECORD_BYTES)
    _require(_digest(record_bytes) == RECORD_SHA256,
             'documentation transition record differs from its fixed digest')
    try:
        record = json.loads(record_bytes.decode('utf-8'), object_pairs_hook=_unique_json)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise DocumentationTransitionError('documentation transition record is malformed') from exc
    _require(isinstance(record, dict) and set(record) == RECORD_KEYS and
             record['schema_version'] == '1.0' and
             record['date'] == '2026-10-30' and
             record['kind'] == 'exact_documentation_followup_transition' and
             record['status'] == 'DOCUMENTATION_TRANSITION_ONLY' and
             record['publication_authorized'] is False and
             record['native_requalification_claimed'] is False and
             record['current_head_ci_required'] is True and
             record['baseline_commit'] == '9363cb42eff328590276ad4d4f2289d4f3575262' and
             record['integrating_commit'] == '7ef70dd77d2bcd0709908159807f9b97076c4f40' and
             record['scope'] == ('Exactly ten documentation files transitioned from the pre-integration source bytes to the SQL object documentation integration; historical execution reports and pins are unchanged. Current documentation bytes are bound separately and require current-head CI.') and
             record['archive_path'] == ARCHIVE_PATH and
             record['archive_sha256'] == ARCHIVE_SHA256 and
             isinstance(record['license_sha256'], str) and
             set(record['before_source_sha256']) == PATHS and
             set(record['after_source_sha256']) == PATHS,
             'documentation transition record claims or paths differ')
    for mapping in (record['before_source_sha256'], record['after_source_sha256']):
        _require(all(isinstance(value, str) and len(value) == 64 and
                     all(char in '0123456789abcdef' for char in value)
                     for value in mapping.values()),
                 'documentation transition source pin is malformed')

    archive_bytes = _read_regular(root, ARCHIVE_PATH, MAX_ARCHIVE_BYTES)
    _require(_digest(archive_bytes) == ARCHIVE_SHA256,
             'documentation transition archive differs from its fixed digest')
    try:
        with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
            entries = archive.infolist()
            names = [entry.filename for entry in entries]
            expected_names = set(PATHS) | {'LICENSE.md'}
            _require(len(names) == len(set(names)) and set(names) == expected_names and
                     all(not entry.is_dir() and entry.compress_type in
                         (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED) and
                         not entry.flag_bits & 0x1 and
                         stat.S_IFMT(entry.external_attr >> 16) in (0, stat.S_IFREG)
                         for entry in entries),
                     'documentation transition archive entry set or type differs')
            content = {}
            total = 0
            for entry in entries:
                _require(0 <= entry.file_size <= MAX_SOURCE_BYTES,
                         'documentation transition archive entry exceeds its bound')
                data = archive.read(entry)
                _require(len(data) == entry.file_size,
                         'documentation transition archive entry size differs')
                total += len(data)
                _require(total <= MAX_TOTAL_SOURCE_BYTES,
                         'documentation transition archive exceeds its total bound')
                content[entry.filename] = data
    except (zipfile.BadZipFile, zipfile.LargeZipFile, OSError, RuntimeError) as exc:
        raise DocumentationTransitionError('documentation transition archive is invalid') from exc
    _require(_digest(content['LICENSE.md']) == record['license_sha256'] and
             content['LICENSE.md'] == _read_regular(root, 'LICENSE.md', MAX_SOURCE_BYTES),
             'documentation transition license differs')
    for path in PATHS:
        _require(_digest(content[path]) == record['before_source_sha256'][path],
                 'documentation transition historical source differs')
    for path in PATHS:
        current = _read_regular(root, path, MAX_SOURCE_BYTES)
        if _digest(current) != record['after_source_sha256'][path]:
            import parameter_documentation_transition as parameters
            if path in parameters.PATHS:
                current = parameters.predecessor_source(root, path, current)
        _require(_digest(current) == record['after_source_sha256'][path],
                 'current documentation differs from its exact follow-up pin')
    return root, record, content


def validate_current(root, path: str, expected_before_sha256: str | None = None) -> bytes:
    """Validate exact current bytes and return them for current-document consumers."""
    _require(path in PATHS, 'unsupported documentation transition path')
    _, record, _ = _load(root)
    before = record['before_source_sha256'][path]
    if expected_before_sha256 is not None:
        _require(isinstance(expected_before_sha256, str) and
                 expected_before_sha256 == before,
                 'documentation transition predecessor pin differs')
    return _read_regular(Path(root).resolve(strict=True), path, MAX_SOURCE_BYTES)


def historical_source(root, path: str, expected_before_sha256: str | None = None) -> bytes:
    """Return only the exact archived pre-integration bytes after validating current state."""
    _require(path in PATHS, 'unsupported documentation transition path')
    _, record, content = _load(root)
    before = record['before_source_sha256'][path]
    if expected_before_sha256 is not None:
        _require(isinstance(expected_before_sha256, str) and
                 expected_before_sha256 == before,
                 'documentation transition predecessor pin differs')
    return content[path]
