"""Exact historical SSIS source bytes retained in the frozen CLR installer."""
from pathlib import Path, PurePosixPath
import hashlib
import stat
import zipfile


ARCHIVE = 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
ARCHIVE_SHA256 = '896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287'
PREFIX = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/Sources/'
SOURCES = {
    'Modules/toolbelt.tsql.ssis-debug/module.yaml': {
        'historical': 'ab519faa5743e872f44e70499ebafcdeeed065e079eec2e95e8d5c518286bf8f',
        'current': '55e7ea67b219c665f62297821e1eedd931ca3591427899fd51fcbf03903794a7',
    },
    'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs': {
        'historical': '33331e397100720c2413ac75d22ac25cd23cda4b7816bfa30338c2f14808829b',
        'current': '0635250f5a30064985d50a1e982f6d66fe022769ae20d72885e9b24505e36b52',
    },
}


def _sha(data):
    return hashlib.sha256(data).hexdigest()


def source_paths():
    return frozenset(SOURCES)


def validate_historical_source(root, path, expected_sha256):
    """Return exact V1 archive bytes after binding both frozen and current inputs."""
    root = Path(root).resolve()
    if not isinstance(path, str) or path not in SOURCES:
        raise ValueError('SSIS_HISTORICAL_SOURCE_PATH')
    binding = SOURCES[path]
    if not isinstance(expected_sha256, str) or expected_sha256.lower() != binding['historical']:
        raise ValueError('SSIS_HISTORICAL_SOURCE_PIN')
    archive_path = root / ARCHIVE
    archive_bytes = archive_path.read_bytes()
    if _sha(archive_bytes) != ARCHIVE_SHA256:
        raise ValueError('SSIS_HISTORICAL_ARCHIVE_PIN')
    entry_name = PREFIX + path
    with zipfile.ZipFile(archive_path) as archive:
        matches = [entry for entry in archive.infolist() if entry.filename == entry_name]
        if (len(matches) != 1 or matches[0].is_dir() or
                (matches[0].external_attr >> 16) & 0o170000 == stat.S_IFLNK):
            raise ValueError('SSIS_HISTORICAL_SOURCE_ENTRY')
        original = archive.read(matches[0])
    if _sha(original) != binding['historical']:
        raise ValueError('SSIS_HISTORICAL_SOURCE_ARCHIVE_BYTES')
    current = (root / PurePosixPath(path)).read_bytes()
    if _sha(current) != binding['current']:
        raise ValueError('SSIS_HISTORICAL_SOURCE_CURRENT_BYTES')
    return original
