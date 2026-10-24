"""Canonical SSIS functional oracles, without provisioning identity fixtures."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import shutil


def functional_v1(source: bytes) -> bytes:
    text = source.decode('utf-8-sig')
    start_marker = '# Rechte ausschließlich'
    end_marker = 'if($CrossDatabase){'
    if text.count(start_marker) != 1 or text.count(end_marker) != 1:
        raise ValueError('SSIS_SECURITY_SCOPE_ANCHORS_CHANGED')
    start = text.index(start_marker)
    end = text.index(end_marker, start)
    removed = text[start:end]
    if 'CREATE USER SyntheticSsisReader WITHOUT LOGIN' not in removed or 'DROP USER SyntheticSsisReader' not in removed:
        raise ValueError('SSIS_SECURITY_SCOPE_CHANGED')
    return (text[:start] + '# Principal/right fixtures remain separately not executed.\n' + text[end:]).encode('utf-8')


def prepare(source_root: Path, destination: Path) -> dict:
    if destination.exists():
        raise ValueError('SSIS_NEW_FIXTURE_DIRECTORY_REQUIRED')
    module = source_root / 'Modules/toolbelt.tsql.ssis-debug'
    for relative in ['Tests/Runtime', 'Tests/Fixtures', 'Contracts']:
        shutil.copytree(module / relative, destination / relative)
    relative = Path('Tests/Runtime/Invoke-V1Cases.ps1')
    original = (module / relative).read_bytes()
    adapted = functional_v1(original)
    (destination / relative).write_bytes(adapted)
    result = {'source': 'Modules/toolbelt.tsql.ssis-debug/' + relative.as_posix(),
              'source_sha256': hashlib.sha256(original).hexdigest(),
              'adapted_sha256': hashlib.sha256(adapted).hexdigest(),
              'omitted_scope': 'Synthetic principal provisioning, grant/revoke and impersonation only; not a minimum-rights qualification.',
              'preserved_scope': 'Canonical functional assertions, NOLOCK behavior, actual cross-database caller and generated SQL, API and component cases.'}
    (destination / 'derivation.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    return result
