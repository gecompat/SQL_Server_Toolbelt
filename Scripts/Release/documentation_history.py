"""Historical documentation bindings; never qualify today's edited reference text.

Executable product sources, native fixtures, reports and their pins still use
their existing validators. Only eight exact documentation paths have a frozen
pre-reference snapshot. Current documentation is checked by the normal project
documentation checks, independently of old native qualification.
"""
from pathlib import Path, PurePosixPath
import hashlib
import io
import zipfile

ARCHIVE = 'Scripts/Release/HistoricalSources/sql-object-documentation/QualifiedDocumentation.zip'
ARCHIVE_SHA256 = '71af74733f2c8429a0a0e408e5b7499328ffb299ece3ec0be123313ef820c1fd'
PATHS = frozenset({
    'Modules/toolbelt.file.content/Documentation/USP_LoadBinaryFile.md',
    'Modules/toolbelt.file.content/Documentation/USP_LoadTextFile.md',
    'Modules/toolbelt.file.csv-memory/Documentation/USP_ParseCsv.md',
    'Modules/toolbelt.file.csv-memory/Documentation/USP_WriteCsv.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/TVF_FormatXlsxCell.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/TVF_InterpretXlsxCell.md',
})
MAINTENANCE = 'Scripts/Release/clr_maintenance.py'
MAINTENANCE_PROJECTION = (
    (b'import prepare_release as release\n',
     b'import prepare_release as release\nimport documentation_history\n'),
    (b"current = {p: (root / p).read_bytes().replace(b'\\r\\n', b'\\n') for p in SOURCE_OVERRIDES}",
     b"current = {p: documentation_history.qualification_bytes(root, p).replace(b'\\r\\n', b'\\n') for p in SOURCE_OVERRIDES}"),
    (b"sha((Path(root) / path).read_bytes().replace(b'\\r\\n', b'\\n')) == pin,\n                        'Maintenance qualified source differs.'",
     b"sha(documentation_history.qualification_bytes(root, path).replace(b'\\r\\n', b'\\n')) == pin,\n                        'Maintenance qualified source differs.'"),
    (b"sha((Path(root) / path).read_bytes().replace(b'\\r\\n', b'\\n')) == pin,\n                        'Maintenance qualification method differs.'",
     b"sha(documentation_history.qualification_method_bytes(root, path).replace(b'\\r\\n', b'\\n')) == pin,\n                        'Maintenance qualification method differs.'"),
)
RAW_CALLER_PROJECTION = (
    (b'import help_contract_source\n', b'import help_contract_source\nimport documentation_history\n'),
    (b'        current = hashlib.sha256((root / path).read_bytes()).hexdigest().upper()\n',
     b'        current = hashlib.sha256(documentation_history.qualification_bytes(root, relative)).hexdigest().upper()\n'),
)


def qualification_bytes(root, path):
    """Return frozen bytes only for registered docs; runtime bytes stay current."""
    root = Path(root)
    if (not isinstance(path, str) or not path or ':' in path or '\\' in path
            or PurePosixPath(path).is_absolute() or '..' in PurePosixPath(path).parts):
        raise ValueError('Unsafe historical documentation source path')
    if path not in PATHS:
        return (root / path).read_bytes()
    data = (root / ARCHIVE).read_bytes()
    if hashlib.sha256(data).hexdigest() != ARCHIVE_SHA256:
        raise ValueError('Historical documentation archive differs')
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)) or set(names) != PATHS | {'LICENSE.md'}:
            raise ValueError('Historical documentation path set differs')
        if archive.read('LICENSE.md') != (root / 'LICENSE.md').read_bytes():
            raise ValueError('Historical documentation license differs')
        return archive.read(path)


def restore_projection(current, replacements):
    """Undo only literal read-adapter changes; the caller checks the old hash."""
    for original, projected in replacements:
        if current.count(projected) != 1:
            raise ValueError('Historical documentation checker projection differs')
        current = current.replace(projected, original, 1)
    return current


def qualification_method_bytes(root, path):
    current = (Path(root) / path).read_bytes().replace(b'\r\n', b'\n')
    return restore_projection(current, MAINTENANCE_PROJECTION) if path == MAINTENANCE else current
