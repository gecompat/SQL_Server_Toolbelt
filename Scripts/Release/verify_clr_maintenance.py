"""Verify the separately pinned XLSX maintenance delivery container."""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import io
import json
import re
import stat
import sys
import zipfile
import zlib

import clr_maintenance as maintenance
import prepare_clr_package as package
import prepare_release as release

VERIFIER_PATH = 'Scripts/Release/verify_clr_maintenance.py'
DELIVERY = 'Releases/1.0.0/clr-maintenance-delivery.json'
DELIVERY_SCHEMA = 'toolbelt-clr-maintenance-delivery/v1'
DELIVERY_KEYS = frozenset((
    'schema_version', 'package_path', 'package_sha256',
    'qualification_report_path', 'qualification_report_sha256',
    'publication_authorized', 'verification_method_sha256'))
MAX_PACKAGE_BYTES = 64 * 1024 * 1024
MAX_PACKAGE_ENTRIES = 2048
MAX_ENTRY_BYTES = 64 * 1024 * 1024
MAX_TOTAL_UNCOMPRESSED_BYTES = 128 * 1024 * 1024
MAX_DELIVERY_BYTES = 16 * 1024
MAX_SIDECAR_BYTES = 256


def sha(data):
    return hashlib.sha256(data).hexdigest()


def _read_package_payload(data, expected_payload):
    """Read only the exact safe package entries and compare their bytes."""
    release.require(isinstance(data, bytes) and len(data) <= MAX_PACKAGE_BYTES,
                    'Maintenance package exceeds its size limit.')
    prefix = package.PACKAGE + '/'
    expected_names = {prefix + name: content for name, content in expected_payload.items()}
    release.require(len(expected_names) == len(expected_payload)
                    and len(expected_names) <= MAX_PACKAGE_ENTRIES,
                    'Maintenance payload exceeds its entry limit.')
    expected_total = sum(len(content) for content in expected_payload.values())
    release.require(expected_total <= MAX_TOTAL_UNCOMPRESSED_BYTES,
                    'Maintenance payload exceeds its uncompressed size limit.')
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            entries = archive.infolist()
            names = [item.filename for item in entries]
            release.require(len(entries) == len(expected_names)
                            and len(entries) <= MAX_PACKAGE_ENTRIES
                            and len(names) == len(set(names))
                            and set(names) == set(expected_names),
                            'Maintenance package entry set differs.')
            total = 0
            result = {}
            for item in entries:
                name = item.filename
                path = PurePosixPath(name)
                release.require(not item.is_dir() and name.startswith(prefix)
                                and '\\' not in name and not path.is_absolute()
                                and all(part not in ('', '.', '..') for part in path.parts)
                                and name in expected_names,
                                'Maintenance package contains an unsafe path.')
                kind = stat.S_IFMT(item.external_attr >> 16)
                release.require(kind in (0, stat.S_IFREG)
                                and not (item.flag_bits & 0x1)
                                and item.compress_type in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED),
                                'Maintenance package contains an unsafe entry type.')
                expected = expected_names[name]
                release.require(0 <= item.file_size <= MAX_ENTRY_BYTES
                                and item.file_size == len(expected),
                                'Maintenance package entry size differs.')
                total += item.file_size
                release.require(total <= MAX_TOTAL_UNCOMPRESSED_BYTES,
                                'Maintenance package exceeds its uncompressed size limit.')
                chunks = []
                observed = 0
                with archive.open(item, 'r') as stream:
                    while True:
                        block = stream.read(min(64 * 1024, len(expected) - observed + 1))
                        if not block:
                            break
                        observed += len(block)
                        release.require(observed <= len(expected),
                                        'Maintenance package entry expands beyond its size limit.')
                        chunks.append(block)
                content = b''.join(chunks)
                release.require(content == expected,
                                'Maintenance package payload differs: ' + name[len(prefix):])
                result[name[len(prefix):]] = content
            release.require(total == expected_total,
                            'Maintenance package total size differs.')
            return result
    except (zipfile.BadZipFile, zipfile.LargeZipFile, OSError, RuntimeError, EOFError, zlib.error) as exc:
        raise release.ReleaseError('Maintenance package is not a valid safe ZIP.') from exc


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        release.require(key not in result, 'Maintenance delivery record has duplicate fields.')
        result[key] = value
    return result


def _validate_delivery(root, actual, report_bytes):
    delivery_bytes = (Path(root) / DELIVERY).read_bytes()
    release.require(len(delivery_bytes) <= MAX_DELIVERY_BYTES,
                    'Maintenance delivery record exceeds its size limit.')
    delivery = json.loads(delivery_bytes.decode('utf-8'), object_pairs_hook=_unique_object)
    release.require(isinstance(delivery, dict) and set(delivery) == DELIVERY_KEYS
                    and delivery['schema_version'] == DELIVERY_SCHEMA
                    and delivery['package_path'] == maintenance.LOCATION
                    and delivery['qualification_report_path'] == maintenance.RECORD
                    and delivery['publication_authorized'] is False
                    and isinstance(delivery['package_sha256'], str)
                    and re.fullmatch(r'[0-9a-f]{64}', delivery['package_sha256'])
                    and isinstance(delivery['qualification_report_sha256'], str)
                    and re.fullmatch(r'[0-9a-f]{64}', delivery['qualification_report_sha256'])
                    and isinstance(delivery['verification_method_sha256'], str)
                    and re.fullmatch(r'[0-9a-f]{64}', delivery['verification_method_sha256']),
                    'Maintenance delivery record is malformed or broadened.')
    verifier_source = (Path(root) / VERIFIER_PATH).read_bytes().replace(b'\r\n', b'\n')
    release.require(sha(verifier_source) == delivery['verification_method_sha256'],
                    'Maintenance delivery verifier differs from its fixed digest.')
    release.require(sha(actual) == delivery['package_sha256'],
                    'Maintenance delivery package digest differs.')
    release.require(sha(report_bytes) == delivery['qualification_report_sha256'],
                    'Maintenance delivery qualification report digest differs.')
    return delivery


def verify(root, path=None):
    root = Path(root)
    path = root / maintenance.LOCATION if path is None else Path(path)
    release.require(path.is_file() and not path.is_symlink(),
                    'Maintenance package is missing or not a regular file.')
    release.require(path.stat().st_size <= MAX_PACKAGE_BYTES,
                    'Maintenance package exceeds its size limit.')
    report_bytes = (root / maintenance.RECORD).read_bytes()
    record = json.loads(report_bytes)
    expected_payload = maintenance.qualified_payload(root, record)
    with path.open('rb') as stream:
        actual = stream.read(MAX_PACKAGE_BYTES + 1)
        release.require(len(actual) <= MAX_PACKAGE_BYTES and stream.read(1) == b'',
                        'Maintenance package exceeds its size limit.')
    _validate_delivery(root, actual, report_bytes)
    sidecar = Path(str(path) + '.sha256').read_bytes()
    release.require(len(sidecar) <= MAX_SIDECAR_BYTES,
                    'Maintenance checksum sidecar exceeds its size limit.')
    release.require(sidecar.decode('ascii').split() == [sha(actual), path.name],
                    'Maintenance checksum differs.')
    _read_package_payload(actual, expected_payload)
    package.verify(root / package.LOCATION)
    print('PASS CLR_MAINTENANCE one XLSX replacement; 12 inherited DLLs; 12 native delta cases and audits')
    return record


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify', type=Path)
    args = parser.parse_args()
    try:
        verify(maintenance.release.ROOT, args.verify)
    except (ValueError, OSError, zipfile.BadZipFile) as exc:
        print('FAIL CLR_MAINTENANCE_VERIFY: ' + str(exc), file=sys.stderr)
        raise SystemExit(1) from exc
