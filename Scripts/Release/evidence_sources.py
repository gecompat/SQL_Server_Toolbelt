"""Exact historical source bytes and a separate, fail-closed live comparison.

Resolving an old pin establishes integrity of that input, never qualification
of a newer input. No archive/report is rewritten and no text is normalized.
"""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
import zipfile

MAX_SOURCE_BYTES = 32 * 1024 * 1024
MAX_TOTAL_BYTES = 64 * 1024 * 1024
MAX_BINDINGS = 512
_trees: dict[tuple[str, str, tuple[str, ...]], dict[str, bytes]] = {}
_reports: dict[str, dict[str, list[str]]] = {}
_packages: dict[tuple[str, str], dict[str, bytes]] = {}
_origins: dict[tuple[str, str, str], tuple[str, ...]] = {}


def _require(condition, message):
    if not condition:
        raise ValueError("Evidence sources: " + message)


def _digest(data):
    return hashlib.sha256(data).hexdigest()


def _path(value):
    _require(isinstance(value, str) and value and '\\' not in value
             and ':' not in value and '\x00' not in value
             and '\n' not in value and '\r' not in value,
             "invalid source path")
    p = PurePosixPath(value)
    _require(not p.is_absolute() and p.as_posix() == value
             and not any(x in ('', '.', '..') or x.rstrip(' .').lower() in ('.git', '.runtime')
                         for x in value.split('/')), "source outside public tree")
    return value



def _report_bytes(root, relative):
    root = Path(root).resolve()
    file = root / _path(relative)
    _require(file.resolve().is_relative_to(root) and not file.is_symlink()
             and file.is_file() and file.stat().st_size <= MAX_SOURCE_BYTES,
             "report must be a bounded regular file")
    return file.read_bytes()


def _git(root, *args, data=None, missing_ok=False):
    options = {'creationflags': subprocess.CREATE_NO_WINDOW} if sys.platform == 'win32' else {}
    result = subprocess.run(['git', '-C', str(root), *args], input=data,
                            capture_output=True, timeout=30, **options)
    if missing_ok and result.returncode != 0:
        return None
    _require(result.returncode == 0, "recorded Git source unavailable")
    return result.stdout


def _revision(value):
    _require(isinstance(value, str) and re.fullmatch('[0-9a-f]{40}', value) is not None,
             "recorded revision must be a full commit ID")
    return value


def _snapshot(root, revision, paths):
    revision = _revision(revision)
    paths = tuple(sorted({_path(p) for p in paths}))
    key = (str(root), revision, paths)
    if key in _trees:
        return _trees[key]
    kind = _git(root, 'cat-file', '-t', revision, missing_ok=True)
    if kind is None:
        # Deleted/unpublished historical branches may be absent from a full
        # remote clone. Try only the remaining declared snapshots; exact pin
        # checks still fail if none can supply the original bytes.
        return {}
    _require(kind.strip() == b'commit', "recorded revision is not a commit")
    listing = _git(root, 'ls-tree', '-r', '-z', revision, '--', *paths)
    entries = {}
    for row in listing.split(b'\x00'):
        if not row:
            continue
        info, name = row.split(b'\t', 1)
        mode, kind, oid = info.split(b' ')
        name = name.decode('utf-8')
        if name not in paths:
            continue
        _require(mode in (b'100644', b'100755') and kind == b'blob',
                 "historical source is not a regular file")
        entries[name] = oid
    if not entries:
        _trees[key] = {}
        return {}
    names = sorted(entries)
    objects = b''.join(entries[p] + b'\n' for p in names)
    sizes = _git(root, 'cat-file', '--batch-check', data=objects).splitlines()
    _require(len(sizes) == len(names), "source size inventory differs")
    total = 0
    for name, row in zip(names, sizes):
        oid, kind, size = row.split()
        _require(oid == entries[name] and kind == b'blob', "source object differs")
        size = int(size)
        _require(0 <= size <= MAX_SOURCE_BYTES, "historical source size limit")
        total += size
    _require(total <= MAX_TOTAL_BYTES, "historical source total limit")
    raw = _git(root, 'cat-file', '--batch', data=objects)
    result = {}
    offset = 0
    for name in names:
        end = raw.find(b'\n', offset)
        _require(end >= offset, "source frame missing")
        oid, kind, size = raw[offset:end].split()
        size = int(size)
        _require(oid == entries[name] and kind == b'blob'
                 and 0 <= size <= MAX_SOURCE_BYTES, "source frame differs")
        offset = end + 1
        result[name] = raw[offset:offset + size]
        _require(len(result[name]) == size and raw[offset + size:offset + size + 1] == b'\n',
                 "source frame truncated")
        offset += size + 1
    _require(offset == len(raw), "unexpected source frames")
    _trees[key] = result
    return result


@dataclass(frozen=True)
class Binding:
    path: str
    recorded_sha256: str
    original: bytes
    current_sha256: str | None
    origin: str

    @property
    def current_matches(self):
        return self.current_sha256 == self.recorded_sha256


def resolve(root, bindings, *, revisions=(), originals=None):
    """Read only exact pins from declared snapshots, or verified caller originals.

    Current matching bytes can satisfy a pin directly. Newer nonmatching bytes
    cannot. Caller-provided originals are still checked against every digest.
    """
    root = Path(root).resolve()
    _require(isinstance(bindings, dict) and 0 < len(bindings) <= MAX_BINDINGS,
             "invalid source binding count")
    for p, expected in bindings.items():
        _path(p)
        _require(isinstance(expected, str) and re.fullmatch('[0-9a-fA-F]{64}', expected) is not None,
                 "invalid executed digest")
    bindings = {p: expected.lower() for p, expected in bindings.items()}
    revisions = tuple(dict.fromkeys(_revision(r) for r in revisions))
    _require(len(revisions) <= 6, "too many source snapshots")
    originals = originals or {}
    result = {}
    current_digests = {}
    missing = []
    live_total = 0
    for name, expected in bindings.items():
        file = root / name
        _require(file.resolve().is_relative_to(root) and not file.is_symlink(),
                 "live source escapes repository")
        current = None
        if file.exists():
            _require(stat.S_ISREG(file.stat().st_mode) and file.stat().st_size <= MAX_SOURCE_BYTES,
                     "live source is not a bounded regular file")
            live_total += file.stat().st_size
            _require(live_total <= MAX_TOTAL_BYTES, "live source total limit")
            current = file.read_bytes()
        current_digest = _digest(current) if current is not None else None
        current_digests[name] = current_digest
        original = originals.get(name)
        if original is not None:
            _require(isinstance(original, bytes) and len(original) <= MAX_SOURCE_BYTES
                     and _digest(original) == expected, "provided original digest differs")
            result[name] = Binding(name, expected, original, current_digest, 'verified_original')
        elif current_digest == expected:
            result[name] = Binding(name, expected, current, current_digest, 'identical_live_bytes')
        else:
            missing.append(name)
    for revision in revisions:
        if not missing:
            break
        snapshot = _snapshot(root, revision, missing)
        for name in list(missing):
            original = snapshot.get(name)
            if original is not None and _digest(original) == bindings[name]:
                result[name] = Binding(name, bindings[name], original, current_digests[name], revision)
                missing.remove(name)
    _require(not missing, "exact original source unavailable: " + ', '.join(missing))
    _require(sum(len(b.original) for b in result.values()) <= MAX_TOTAL_BYTES,
             "resolved source total limit")
    return result


def report_revisions(root, report_path, report):
    """Only recorded source anchors and the exact committed report revision.

    No search through arbitrary history. The report bytes must themselves match
    their latest recorded commit before that snapshot can supply an input.
    """
    root = Path(root).resolve()
    report_path = _path(report_path)
    report_bytes = _report_bytes(root, report_path)
    _require(json.loads(report_bytes) == report, "report changed during verification")
    # Cache only immutable provenance after exact committed-byte verification.
    # Every call still reads the live record; current source bytes are separate.
    key = (str(root), report_path, _digest(report_bytes))
    if key in _origins:
        return _origins[key]
    revisions = []
    for field in ('execution_source_baseline_commit', 'fixture_execution_source_commit',
                  'executed_code_commit', 'source_commit'):
        if report.get(field):
            revisions.append(_revision(report[field]))
    transition = report.get('source_transition', {})
    _require(isinstance(transition, dict), 'invalid source transition')
    if transition.get('original_execution_commit'):
        revisions.append(_revision(transition['original_execution_commit']))
    execution = report.get('execution', {})
    _require(isinstance(execution, dict), 'invalid execution metadata')
    if execution.get('source_commit'):
        revisions.append(_revision(execution['source_commit']))
    latest = _git(root, 'log', '-1', '--format=%H', '--', report_path).strip().decode('ascii')
    _revision(latest)
    source = _snapshot(root, latest, [report_path]).get(report_path)
    _require(source is not None and source == report_bytes,
             "report differs from its committed original")
    revisions.append(latest)
    _origins[key] = tuple(dict.fromkeys(revisions))
    return _origins[key]


def report_sources(root, report_path, *, field='source_sha256', bindings=None, originals=None):
    report = json.loads(_report_bytes(root, report_path))
    revisions = report_revisions(root, report_path, report)
    pins = bindings if bindings is not None else report[field]
    recorded = {}
    def collect(node):
        if isinstance(node, dict):
            for name, value in node.items():
                if isinstance(value, str) and re.fullmatch('[0-9a-fA-F]{64}', value):
                    recorded.setdefault(name, set()).add(value.lower())
                else:
                    collect(value)
        elif isinstance(node, list):
            for value in node:
                collect(value)
    collect(report)
    for update in report.get('post_native_source_updates', []):
        if isinstance(update, dict) and isinstance(update.get('path'), str):
            value = update.get('current_sha256', '')
            if isinstance(value, str) and re.fullmatch('[0-9a-fA-F]{64}', value):
                recorded.setdefault(update['path'], set()).add(value.lower())
    _require(all(isinstance(value, str) and value.lower() in recorded.get(name, ())
                 for name, value in pins.items()), "source pin is not recorded by this report")
    original_inputs = dict(originals or {})
    package = report.get('package', {})
    if isinstance(package, dict) and package.get('path') and package.get('sha256'):
        archive_path = _path(package['path'])
        expected_archive = package['sha256'].lower()
        _require(re.fullmatch('[0-9a-f]{64}', expected_archive) is not None, "invalid package digest")
        file = Path(root) / archive_path
        _require(file.resolve().is_relative_to(Path(root).resolve()) and not file.is_symlink()
                 and file.is_file() and file.stat().st_size <= MAX_TOTAL_BYTES,
                 "package must be a bounded regular file")
        data = file.read_bytes()
        _require(_digest(data) == expected_archive, "recorded package digest differs")
        key = (str(Path(root).resolve()), expected_archive)
        if key not in _packages:
            import io
            recovered = {}
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                infos = archive.infolist()
                _require(len(infos) <= 8192 and len({i.filename for i in infos}) == len(infos),
                         "duplicate or excessive package entries")
                total = 0
                for info in infos:
                    marker = '/Sources/'
                    if marker not in info.filename:
                        continue
                    name = _path(info.filename.split(marker, 1)[1])
                    _require(not info.is_dir() and not info.flag_bits & 1
                             and stat.S_IFMT(info.external_attr >> 16) in (0, stat.S_IFREG)
                             and info.file_size <= MAX_SOURCE_BYTES,
                             "package source is not bounded and regular")
                    total += info.file_size
                    _require(total <= MAX_TOTAL_BYTES and name not in recovered,
                             "package source total or duplicate limit")
                    recovered[name] = archive.read(info)
            _packages[key] = recovered
        for name, expected in pins.items():
            candidate = _packages[key].get(name)
            if candidate is not None and _digest(candidate) == expected.lower():
                original_inputs.setdefault(name, candidate)
    return resolve(root, pins, revisions=revisions, originals=original_inputs)


def report_path(root, report):
    """Find the unique unchanged public record represented by a loaded object."""
    root = Path(root).resolve()
    key = str(root)
    identity = _digest(json.dumps(report, sort_keys=True, separators=(',', ':')).encode('utf-8'))
    if key not in _reports:
        index = {}
        files = sorted((root / 'Releases/1.0.0').glob('*.json'))
        _require(len(files) <= 256, "report inventory limit")
        for file in files:
            _require(not file.is_symlink() and file.stat().st_size <= MAX_SOURCE_BYTES,
                     "report must be a bounded regular file")
            loaded = json.loads(file.read_bytes())
            digest = _digest(json.dumps(loaded, sort_keys=True, separators=(',', ':')).encode('utf-8'))
            index.setdefault(digest, []).append(file.relative_to(root).as_posix())
        _reports[key] = index
    matches = _reports[key].get(identity, [])
    _require(len(matches) == 1, "unknown or ambiguous original report")
    name = matches[0]
    _require(json.loads((root / name).read_bytes()) == report, "report changed during verification")
    return name


def require_current(bindings):
    """Source equality is necessary, not sufficient, for current qualification."""
    drift = sorted(name for name, binding in bindings.items() if not binding.current_matches)
    _require(not drift, "current source qualification missing: " + ', '.join(drift))


def original_for(root, report, path, recorded_sha256):
    """Convenience for a pin belonging to a unique immutable public report."""
    name = report_path(root, report)
    return report_sources(root, name, bindings={path: recorded_sha256})[path].original


def applicability(bindings):
    """Describe source applicability without inventing a native qualification."""
    return {'historical_integrity': True,
            'current_sources_match': all(b.current_matches for b in bindings.values()),
            'changed_or_missing_sources': sorted(p for p, b in bindings.items() if not b.current_matches),
            'current_native_qualification': 'not established by source integrity'}
