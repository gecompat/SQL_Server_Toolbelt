"""Closed parameter-table projection on top of the existing documentation transition.

Only canonical generated parameter tables may differ. All surrounding prose,
historical reports, runtime sources and original method pins remain bound.
"""
from pathlib import Path
import hashlib
import importlib.util
import io
import json
import re
import stat
import zipfile

import current_documentation_transition as previous

ARCHIVE = 'Scripts/Release/HistoricalSources/parameter-contracts-20261030/Predecessors.zip'
ARCHIVE_SHA256 = '2b2e9a703e4af3cc6ff97b77dc2f92e2f7a06b20cb56dec459060654353f37ab'
REGISTRY = 'Documentation/Reference/api_examples.json'
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
NATIVE_PATHS = frozenset(p for p in PATHS if '/TVF_' in p)
BEGIN = '<!-- API_PARAMETERS:BEGIN -->'
END = '<!-- API_PARAMETERS:END -->'


def _snapshot(root, prefix, path):
    previous._require(path in PATHS and (prefix == 'Predecessors/' or
                      prefix == 'Native/' and path in NATIVE_PATHS),
                      'unsupported parameter documentation predecessor')
    data = previous._read_regular(Path(root), ARCHIVE, 1024 * 1024)
    previous._require(hashlib.sha256(data).hexdigest() == ARCHIVE_SHA256,
                      'parameter documentation archive differs')
    expected = {'Predecessors/' + p for p in PATHS} | {'Native/' + p for p in NATIVE_PATHS} | {'LICENSE.md'}
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        entries = archive.infolist()
        previous._require(len(entries) == len(expected) and
                          {p.filename for p in entries} == expected and
                          all(not p.is_dir() and not p.flag_bits & 1 and
                              stat.S_IFMT(p.external_attr >> 16) == stat.S_IFREG and
                              0 <= p.file_size <= previous.MAX_SOURCE_BYTES for p in entries) and
                          sum(p.file_size for p in entries) <= previous.MAX_TOTAL_SOURCE_BYTES,
                          'parameter documentation archive shape differs')
        previous._require(archive.read('LICENSE.md') == previous._read_regular(
            Path(root), 'LICENSE.md', previous.MAX_SOURCE_BYTES),
            'parameter documentation license differs')
        return archive.read(prefix + path)


def predecessor_source(root, path, current=None):
    """Verify the live canonical table and unchanged prose; return #482 bytes."""
    previous._require(path in PATHS, 'unsupported parameter documentation path')
    root = Path(root).resolve(strict=True)
    if current is None:
        current = previous._read_regular(root, path, previous.MAX_SOURCE_BYTES)
    text = current.decode('utf-8')
    previous._require(text.count(BEGIN) == 1 and text.count(END) == 1,
                      'parameter documentation requires one canonical block')
    original = _snapshot(root, 'Predecessors/', path)
    before = original.decode('utf-8')
    # Reuse the normal source-signature parser and renderer, not a second one.
    source = Path(__file__).resolve().parents[2] / 'Tests/Documentation/generate_api_catalog.py'
    spec = importlib.util.spec_from_file_location('_parameter_reference_catalog', source)
    catalog = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(catalog)
    module = Path(path).parts[1]
    name = Path(path).stem
    _, params = catalog.signature(dict(root=root / 'Modules' / module,
                                       schema='toolbelt_file', name=name, type='TVF' if name.startswith('TVF_') else 'USP'))
    registry = json.loads(previous._read_regular(root, REGISTRY, 2 * 1024 * 1024).decode('utf-8'),
                          object_pairs_hook=previous._unique_json)
    notes = registry['toolbelt_file.' + name]['parameter_notes']
    previous._require(set(notes) == {p['name'] for p in params} and
                      all(isinstance(v, str) and v.strip() for v in notes.values()),
                      'parameter documentation registry differs from signature')
    block = BEGIN + '\n' + catalog.parameter_table(params, notes) + '\n' + END + '\n'
    tables = list(re.finditer(r'(?m)^\|[^\n]*\|\r?\n\|[ :|\-]+\|\r?\n(?:\|[^\n]*\|\r?\n?)+', before))
    tables = [table for table in tables if 'Parameter' in table.group().splitlines()[0]]
    previous._require(len(tables) <= 1, 'parameter documentation predecessor table is ambiguous')
    if tables:
        table = tables[0]
        expected = before[:table.start()] + block + before[table.end():]
    else:
        heading = '\n## Vollständiger Eingabevertrag\n\n' + block + '\n'
        location = before.find('## Technischer Lösungsweg')
        previous._require(location >= 0, 'parameter documentation predecessor anchor differs')
        expected = before[:location].rstrip() + '\n' + heading + '\n' + before[location:]
    previous._require(text == expected,
                      'current documentation differs outside its exact canonical parameter projection / exact follow-up pin')
    return original


def native_documentation_source(root, path, expected_sha256):
    """Resolve only two cell-doc pins; never an executable or unknown source."""
    previous._require(path in NATIVE_PATHS, 'unsupported native parameter documentation path')
    predecessor_source(root, path)
    original = _snapshot(root, 'Native/', path)
    previous._require(isinstance(expected_sha256, str) and
                      hashlib.sha256(original).hexdigest() == expected_sha256.lower(),
                      'native parameter documentation predecessor pin differs')
    return original


def restore_raw_caller_adapter(current):
    """Undo exactly this non-qualifying doc read adapter before old method checks."""
    replacements = (
        (b'import help_contract_source\nimport parameter_documentation_transition\n', b'import help_contract_source\n'),
        (b"        source = (parameter_documentation_transition.native_documentation_source(root, relative, digest)\n"
         b"                  if relative in parameter_documentation_transition.NATIVE_PATHS else (root / path).read_bytes())\n"
         b"        current = hashlib.sha256(source).hexdigest().upper()\n",
         b"        current = hashlib.sha256((root / path).read_bytes()).hexdigest().upper()\n"),
    )
    for changed, original in replacements:
        previous._require(current.count(changed) == 1, 'parameter documentation checker projection differs')
        current = current.replace(changed, original, 1)
    return current
