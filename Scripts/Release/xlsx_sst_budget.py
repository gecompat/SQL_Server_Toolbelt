"""Bind the SST correction separately from immutable earlier qualifications."""
from pathlib import Path
import hashlib
import io
import json
import zipfile

REPORT = 'Releases/1.0.0/xlsx-sst-budget-correction.json'
WORKBOOK = 'Modules/toolbelt.file.xlsx-memory/Clr/Workbook.cs'
PROVIDER_IL = 'Spikes/XlsxMemory/Test-ProviderIL.ps1'
CELL_TEST = 'Tests/Release/test_xlsx_cell_caller_qualification.py'
CANDIDATE_BUNDLE = 'Releases/1.0.0/Artifacts/Xlsx-Sst-Budget-Candidate.zip'
ARCHIVE = 'Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip'
ARCHIVE_SHA256 = '333a7d6ceb2a36523ea642ac1dd5a78b5fc86b8aaa25998db14c8ea035f068e6'
ARCHIVE_PREFIX = 'SQL-Server-Toolbelt-1.0.0-candidate-source/'
HISTORICAL = {
    WORKBOOK: 'a834d0b53a309e6836efc2ca077b48d2aebc48533a838723268416361a49812a',
    PROVIDER_IL: 'bf1ae44917a2a6d84365b82a109ac1333b3aada4347adfba534e8eb7689cef78',
}
PREVIOUS_CELL_TEST_SHA256 = 'bd17ae9b33aa84d598af119f39c81916f07fec3a7e9453ac285bf2714badbec1'
IMPORT_BEFORE = b'import zip_metadata\n'
IMPORT_AFTER = IMPORT_BEFORE + b'import xlsx_sst_budget\n'
CELL_HOOK = (b'            if path == xlsx_sst_budget.WORKBOOK:\n'
             b'                xlsx_sst_budget.validate_historical_source(ROOT, path, digest)\n'
             b'                continue\n')
CELL_ANCHOR = (b'            if path == zip_metadata.MANIFEST:\n'
               b'                zip_metadata.validate_source(ROOT, path, digest)\n'
               b'                continue\n')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_record(root):
    record = json.loads((Path(root) / REPORT).read_bytes())
    require(record['schema_version'] == 'toolbelt-xlsx-sst-budget-correction/v1'
            and record['publication_authorized'] is False
            and record['budget']['maximum_milliseconds'] == 5000
            and record['package_payload_changed'] is False,
            'SST correction scope or unchanged budget differs')
    return record


def validate_historical_source(root, path, executed_digest):
    """Verify old evidence against old bytes; separately bind the current source."""
    require(path in HISTORICAL and executed_digest.lower() == HISTORICAL[path],
            'unsupported historical SST source or execution pin')
    current = (Path(root) / path).read_bytes()
    if digest(current) == HISTORICAL[path]:
        return current
    record = read_record(root)
    require(digest(current) == record['current_source_sha256'][path]
            and record['historical_source_sha256'] == HISTORICAL,
            'current SST source differs from the separately qualified correction')
    archive_bytes = (Path(root) / ARCHIVE).read_bytes()
    require(digest(archive_bytes) == ARCHIVE_SHA256, 'historical source archive differs')
    name = ARCHIVE_PREFIX + path
    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        entries = [entry for entry in archive.infolist() if entry.filename == name]
        require(len(entries) == 1, 'historical SST source missing or duplicated')
        original = archive.read(entries[0])
    require(digest(original) == executed_digest.lower(), 'historical SST source pin differs')
    return original


def project_cell_test(previous):
    """Exact additional dispatch; earlier metadata projections remain unchanged."""
    require(digest(previous) == PREVIOUS_CELL_TEST_SHA256
            and previous.count(IMPORT_BEFORE) == previous.count(CELL_ANCHOR) == 1,
            'unexpected predecessor cell evidence test')
    return previous.replace(IMPORT_BEFORE, IMPORT_AFTER).replace(CELL_ANCHOR, CELL_ANCHOR + CELL_HOOK)


def restore_previous_cell_test(root, current):
    if digest(current) == PREVIOUS_CELL_TEST_SHA256:
        return current
    record = read_record(root)
    require(digest(current) == record['current_source_sha256'][CELL_TEST]
            and current.count(IMPORT_AFTER) == current.count(CELL_HOOK) == 1,
            'cell evidence test differs from exact SST dispatch')
    previous = current.replace(IMPORT_AFTER, IMPORT_BEFORE).replace(CELL_HOOK, b'')
    require(digest(previous) == PREVIOUS_CELL_TEST_SHA256
            and project_cell_test(previous) == current,
            'cell evidence predecessor cannot be recovered exactly')
    return previous


def project_boundary_driver(original):
    """Reproduce only private location binding; no SQL oracle or cleanup edits."""
    param = b'    [Parameter(Mandatory)][string]$RunsetPath,'
    anchor = b"$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))"
    require(original.count(param) == original.count(anchor) == 1,
            'unexpected original boundary driver')
    result = original.replace(param, param + b'\r\n    [Parameter(Mandatory)][string]$RepositoryRoot,')
    result = result.replace(anchor, b"$repo = [IO.Path]::GetFullPath($RepositoryRoot)\r\n$releaseScriptsRoot = Join-Path $repo 'Tests/Release'")
    require(result.count(b'$PSScriptRoot') == 8, 'boundary helper bindings differ')
    return result.replace(b'$PSScriptRoot', b'$releaseScriptsRoot')


def reconstruct_executed_workbook(canonical):
    """Only executed line 22 used CRLF; Git and the maintained source use LF."""
    require(b'\r' not in canonical and canonical.count(b'\n') == 436,
            'unexpected canonical Workbook line endings')
    lines = canonical.splitlines(keepends=True)
    require(lines[21] == b'        private readonly Stopwatch clock = Stopwatch.StartNew();\n',
            'precise timer anchor differs')
    lines[21] = lines[21][:-1] + b'\r\n'
    return b''.join(lines)


def validate_current(root):
    root = Path(root)
    record = read_record(root)
    require(record['candidate_bundle']['path'] == CANDIDATE_BUNDLE,
            'unexpected SST candidate archive path')
    for path, expected in record['current_source_sha256'].items():
        require(not Path(path).is_absolute() and '..' not in Path(path).parts,
                'unsafe SST source path')
        require(digest((root / path).read_bytes()) == expected, 'current SST source differs: ' + path)
    for path, expected in record['historical_reports_sha256'].items():
        require(path.startswith('Releases/1.0.0/') and '..' not in Path(path).parts,
                'unsafe historical SST report path')
        require(digest((root / path).read_bytes()) == expected, 'historical report changed: ' + path)
    for path, expected in HISTORICAL.items():
        validate_historical_source(root, path, expected)
    workbook = (root / WORKBOOK).read_bytes()
    require(digest(reconstruct_executed_workbook(workbook)) == record['source_projection']['executed_sha256']
            and digest(workbook) == record['source_projection']['canonical_lf_sha256'],
            'executed Workbook projection differs')
    driver = (root / record['driver_projection']['path']).read_bytes()
    require(digest(driver) == record['driver_projection']['original_sha256']
            and digest(project_boundary_driver(driver)) == record['driver_projection']['executed_sha256'],
            'executed boundary driver projection differs')
    candidate = record['candidate_bundle']
    bundle = (root / candidate['path']).read_bytes()
    require(digest(bundle) == candidate['sha256'], 'SST candidate archive differs')
    with zipfile.ZipFile(io.BytesIO(bundle)) as archive:
        names = archive.namelist()
        require(len(names) == len(set(names)) and set(names) == set(candidate['files']),
                'SST candidate entries differ')
        for name, expected in candidate['files'].items():
            require(digest(archive.read(name)) == expected, 'SST candidate entry differs: ' + name)
        require(digest(archive.read('Binaries/Toolbelt.File.XlsxMemory.dll')) == record['candidate_dll_sha256'],
                'qualified candidate DLL differs')
        require(archive.read('ExecutedSources/Workbook.cs') == reconstruct_executed_workbook(workbook),
                'compiled Workbook source differs')
        for path in record['compiled_sources']:
            require(archive.read('Sources/' + path) == (root / path).read_bytes(),
                    'candidate source differs: ' + path)
    return record
