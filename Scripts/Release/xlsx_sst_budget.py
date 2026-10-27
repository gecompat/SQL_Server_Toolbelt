"""Bind the SST correction separately from immutable earlier qualifications."""
from pathlib import Path
import ast
import hashlib
import io
import json
import zipfile

REPORT = 'Releases/1.0.0/xlsx-sst-budget-correction.json'
WORKBOOK = 'Modules/toolbelt.file.xlsx-memory/Clr/Workbook.cs'
PROVIDER_IL = 'Spikes/XlsxMemory/Test-ProviderIL.ps1'
CELL_TEST = 'Tests/Release/test_xlsx_cell_caller_qualification.py'
OFFLINE_TEST_PATH = 'Tests/Release/test_prepare_release.py'
OFFLINE_TEST_ARCHIVE = 'Releases/1.0.0/Artifacts/Xlsx-Sst-Offline-Test-Source.zip'
OFFLINE_TEST_QUALIFIED_SHA256 = 'c3ef16ee699d40a1992bbbbcb90a88b30ffc4d9af8f87cfae6db8ba2bb4276c7'
OFFLINE_TEST_CLASS = 'FunctionCallerQualificationTests'
OFFLINE_TEST_METHOD = 'test_fixed_function_compositions_and_current_native_reports'
OFFLINE_TEST_FIXTURES = ('setUp', 'setUpClass', 'tearDown', 'tearDownClass')
CANDIDATE_BUNDLE = 'Releases/1.0.0/Artifacts/Xlsx-Sst-Budget-Candidate.zip'
ARCHIVE = 'Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip'
ARCHIVE_SHA256 = '333a7d6ceb2a36523ea642ac1dd5a78b5fc86b8aaa25998db14c8ea035f068e6'
ARCHIVE_PREFIX = 'SQL-Server-Toolbelt-1.0.0-candidate-source/'
HISTORICAL = {
    WORKBOOK: 'a834d0b53a309e6836efc2ca077b48d2aebc48533a838723268416361a49812a',
    PROVIDER_IL: 'bf1ae44917a2a6d84365b82a109ac1333b3aada4347adfba534e8eb7689cef78',
}
HISTORICAL_REPORT_EOL = {
    'Releases/1.0.0/xlsx-boundary-qualification.json': {
        'original_local_sha256': '2d5d150841288e31cd113e40b225a15119fcffecc83f21b2a2f076527c9a7b07',
        'canonical_lf_sha256': 'a1ff6a3281c27ae69a8fbf2dcef0b8b60a2c3884bc473a602bc319456ca2edce',
        'lf_count': 476,
    },
    'Releases/1.0.0/xlsx-raw-caller-profile.json': {
        'original_local_sha256': 'ccf857e5d149a6b20423bc71c32a69022c9a3fd7b98cccc9d277ac549d3d7079',
        'canonical_lf_sha256': '1decbd3513a442e2f7419ea339154a8cd4ac8bf2f872cfaac7a77e7bd8e42ced',
        'lf_count': 321,
    },
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


def offline_test_projection(data):
    """Bind fixed Python source blocks without version-specific function AST fields."""
    require(b'\r' not in data.replace(b'\r\n', b''),
            'offline qualification source has noncanonical line endings')
    canonical = data.replace(b'\r\n', b'\n')
    try:
        source = canonical.decode('utf-8')
        module = ast.parse(source)
    except (UnicodeDecodeError, SyntaxError) as error:
        raise ValueError('offline qualification test is not valid UTF-8 Python') from error
    lines = source.splitlines(keepends=True)

    def node_source(node):
        start = min([node.lineno] + [item.lineno for item in node.decorator_list])
        return ''.join(lines[start - 1:node.end_lineno])

    classes = [node for node in module.body
               if isinstance(node, ast.ClassDef) and node.name == OFFLINE_TEST_CLASS]
    require(len(classes) == 1, 'offline qualification class is missing or duplicated')
    cls = classes[0]
    methods = [node for node in cls.body
               if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))]
    selected = [node for node in methods if node.name == OFFLINE_TEST_METHOD]
    require(len(selected) == 1, 'offline qualification method is missing or duplicated')
    require(not getattr(cls, 'type_params', ()),
            'offline qualification class has unsupported type parameters')
    fixture_nodes = {}
    for name in OFFLINE_TEST_FIXTURES:
        matches = [node for node in methods if node.name == name]
        require(len(matches) <= 1, 'offline qualification fixture is duplicated: ' + name)
        if matches:
            fixture_nodes[name] = node_source(matches[0])
    projection = {
        'class': {
            'name': cls.name,
            'bases': [ast.dump(node, annotate_fields=True, include_attributes=False) for node in cls.bases],
            'keywords': [ast.dump(node, annotate_fields=True, include_attributes=False) for node in cls.keywords],
            'decorators': [ast.dump(node, annotate_fields=True, include_attributes=False)
                           for node in cls.decorator_list],
        },
          'method': node_source(selected[0]),
        'fixtures': fixture_nodes,
    }
    return json.dumps(projection, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode('utf-8')


def validate_offline_test_source(root, record):
    """Bind only the fixed qualification method, not unrelated test-file helpers."""
    binding = record.get('offline_test_source')
    require(isinstance(binding, dict) and set(binding) == {
        'path', 'qualified_file_sha256', 'class_name', 'method_name', 'projection_sha256', 'archive'
    }, 'offline qualification source fields differ')
    require(binding['path'] == OFFLINE_TEST_PATH
            and binding['qualified_file_sha256'] == OFFLINE_TEST_QUALIFIED_SHA256
            and binding['class_name'] == OFFLINE_TEST_CLASS
            and binding['method_name'] == OFFLINE_TEST_METHOD
            and OFFLINE_TEST_PATH not in record['current_source_sha256'],
            'offline qualification source scope differs')
    archive_binding = binding['archive']
    require(isinstance(archive_binding, dict) and set(archive_binding) == {'path', 'sha256', 'files'}
            and archive_binding['path'] == OFFLINE_TEST_ARCHIVE,
            'offline qualification archive binding differs')
    archive_path = Path(root) / OFFLINE_TEST_ARCHIVE
    archive_bytes = archive_path.read_bytes()
    require(len(archive_binding['sha256']) == 64
            and digest(archive_bytes) == archive_binding['sha256'],
            'offline qualification archive hash differs')
    current = (Path(root) / OFFLINE_TEST_PATH).read_bytes()
    current_projection = offline_test_projection(current)
    require(digest(current_projection) == binding['projection_sha256'],
            'offline qualification projection differs')
    license_bytes = (Path(root) / 'LICENSE.md').read_bytes()
    require(b'\r' not in license_bytes.replace(b'\r\n', b'') , 'license has noncanonical line endings')
    canonical_license = license_bytes.replace(b'\r\n', b'\n')
    expected_files = {
        OFFLINE_TEST_PATH: OFFLINE_TEST_QUALIFIED_SHA256,
        'LICENSE.md': digest(canonical_license),
    }
    require(archive_binding['files'] == expected_files,
            'offline qualification archive file pins differ')
    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        entries = archive.infolist()
        names = [entry.filename for entry in entries]
        require(len(entries) == 2 and len(set(names)) == 2 and set(names) == set(expected_files),
                'offline qualification archive entries differ')
        for entry in entries:
            mode = (entry.external_attr >> 16) & 0xF000
            require(not entry.is_dir() and mode == 0x8000,
                    'offline qualification archive entry is not a regular file')
        old_source = archive.read(OFFLINE_TEST_PATH)
        old_license = archive.read('LICENSE.md')
    require(digest(old_source) == OFFLINE_TEST_QUALIFIED_SHA256
            and digest(old_license) == expected_files['LICENSE.md']
            and offline_test_projection(old_source) == current_projection,
            'offline qualification source projection differs from its qualified archive')
    return current_projection


def validate_historical_report(path, data, expected):
    projection = HISTORICAL_REPORT_EOL.get(path)
    if projection is None:
        require(digest(data) == expected, 'historical report changed: ' + path)
        return data
    canonical = data.replace(b'\r\n', b'\n')
    rebuilt = canonical.replace(b'\n', b'\r\n')
    require(expected == projection['canonical_lf_sha256']
            and b'\r' not in canonical and canonical.count(b'\n') == projection['lf_count']
            and digest(canonical) == expected
            and digest(rebuilt) == projection['original_local_sha256']
            and data in (canonical, rebuilt),
            'historical report differs beyond exact LF/CRLF projection: ' + path)
    return canonical


def validate_current(root):
    root = Path(root)
    record = read_record(root)
    require(record['candidate_bundle']['path'] == CANDIDATE_BUNDLE,
            'unexpected SST candidate archive path')
    require(record['historical_report_eol_projections'] == HISTORICAL_REPORT_EOL,
            'historical report EOL bindings differ')
    for path, expected in record['current_source_sha256'].items():
        require(not Path(path).is_absolute() and '..' not in Path(path).parts,
                'unsafe SST source path')
        require(digest((root / path).read_bytes()) == expected, 'current SST source differs: ' + path)
    validate_offline_test_source(root, record)
    for path, expected in record['historical_reports_sha256'].items():
        require(path.startswith('Releases/1.0.0/') and '..' not in Path(path).parts,
                'unsafe historical SST report path')
        validate_historical_report(path, (root / path).read_bytes(), expected)
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
        require(archive.read('LICENSE.md') == (root / 'LICENSE.md').read_bytes().replace(b'\r\n', b'\n'),
                'SST candidate license or attribution differs')
        require(digest(archive.read('Binaries/Toolbelt.File.XlsxMemory.dll')) == record['candidate_dll_sha256'],
                'qualified candidate DLL differs')
        require(archive.read('ExecutedSources/Workbook.cs') == reconstruct_executed_workbook(workbook),
                'compiled Workbook source differs')
        for path in record['compiled_sources']:
            require(archive.read('Sources/' + path) == (root / path).read_bytes(),
                    'candidate source differs: ' + path)
    return record
