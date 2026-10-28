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
XLSX_HELP_SOURCE_SHA256 = {
    'Modules/toolbelt.file.xlsx-memory/Source/TVF_FormatXlsxCell.sql': '0486ecef2cefd4eb37a057592459c57601ac479705a7a58bd3183acfe2a95975',
    'Modules/toolbelt.file.xlsx-memory/Source/TVF_InterpretXlsxCell.sql': '5da7aca180f52b8128f819c72e5003fb9c632516a5ac5f3f4a4d4999c2e3616d',
    'Modules/toolbelt.file.xlsx-memory/Source/USP_ListXlsxWorksheets.sql': '2a8b4e8368e529c9a0d882ad784d0a4fa38bdf83a15a87b2e772705bb61e31c1',
    'Modules/toolbelt.file.xlsx-memory/Source/USP_ReadXlsxWorksheetCells.sql': 'ced8e5ccc754303317ed06a1d72adfe79d60cc31d3d4970902e65d032316b825',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md': '045167e135141f62282570a094a4a9cab9ec5f5ca0dd21c361a27f67d7a0f848',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md': '640d6d221bf171ab0fb28c1df2cdf66e2e32b95826ff5382f97c7eebae530ed3',
    'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Xlsx.Contract.sql': 'efa6cd746c51e3047a13008e385e61d2ce5b543e6a84103a10599ac7c1a63683',
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
PREVIOUS_HELP_MODULE_SHA256 = 'd2b42dd8c8f725b331ab8ebaef9772bf4ddfb7c3a26e2ae06e816358de75222b'
IMPORT_BEFORE = b'import zip_metadata\n'
IMPORT_AFTER = IMPORT_BEFORE + b'import xlsx_sst_budget\n'
CELL_HOOK = (b'            if path == xlsx_sst_budget.WORKBOOK:\n'
             b'                xlsx_sst_budget.validate_historical_source(ROOT, path, digest)\n'
             b'                continue\n')
CELL_ANCHOR = (b'            if path == zip_metadata.MANIFEST:\n'
               b'                zip_metadata.validate_source(ROOT, path, digest)\n'
               b'                continue\n')
CELL_HELP_ANCHOR = (b'            if path == xlsx_sst_budget.WORKBOOK:\n'
                    b'                xlsx_sst_budget.validate_historical_source(ROOT, path, digest)\n'
                    b'                continue\n')
CELL_HELP_HOOK = (b'            if path in xlsx_sst_budget.XLSX_HELP_SOURCE_SHA256:\n'
                  b'                xlsx_sst_budget.validate_historical_help_source(ROOT, path, digest)\n'
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


def project_historical_xlsx_help(path, original):
    """Apply only the exact functional-help edits to archived XLSX bytes."""
    replacements = {
        'Modules/toolbelt.file.xlsx-memory/Source/USP_ListXlsxWorksheets.sql': (
            b"('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Hilfe ohne fachliche Eingaben.',N'EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe=1;');",
            b"('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Listet die Sheets eines vom Caller bereitgestellten synthetischen XLSX-Binarys.',N'EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@SyntheticWorkbook;');"),
        'Modules/toolbelt.file.xlsx-memory/Source/USP_ReadXlsxWorksheetCells.sql': (
            b"('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Hilfe ohne fachliche Eingaben.',N'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;');",
            b"('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Liest sparse Zellen aus Sheet 1 eines vom Caller bereitgestellten synthetischen XLSX-Binarys.',N'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@SyntheticWorkbook,@SheetOrdinal=1;');"),
        'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md': (
            b'EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe = 1;\n', b''),
        'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md': (
            b'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe = 1;\n', b''),
    }
    if path in replacements:
        old, new = replacements[path]
        require(original.count(old) == 1, 'historical XLSX help anchor is missing or duplicated')
        result = original.replace(old, new, 1)
        if path.endswith('.md'):
            result += (b'\n`@Hilfe = 1` liefert separat das standardisierte Help-Resultset ohne\n'
                       b'Workbook-Eingabe oder Runtime-Dependency.\n')
        return result

    if path in ('Modules/toolbelt.file.xlsx-memory/Source/TVF_FormatXlsxCell.sql',
                'Modules/toolbelt.file.xlsx-memory/Source/TVF_InterpretXlsxCell.sql'):
        comment_end = original.find(b'*/')
        require(original.startswith(b'/*\n') and comment_end > 0,
                'historical XLSX TVF documentation block differs')
        comment = original[:comment_end + 2]
        remainder = original[comment_end + 2:]
        require(remainder.startswith(b'\n'), 'historical XLSX TVF comment terminator differs')
        remainder = remainder[1:]
        marker = b'\nRETURNS TABLE'
        require(remainder.count(marker) == 1, 'historical XLSX TVF declaration anchor differs')
        signature, tail = remainder.split(marker, 1)
        if path.endswith('TVF_InterpretXlsxCell.sql'):
            old = (b'-- Deployment erstellt keine Berechtigungen. SQL2019/2022/2025 Windows/Linux Zielmatrix,\n'
                   b'-- neue API dort erst nach tats\xc3\xa4chlicher integrierter Qualifikation als PASS behandeln.')
            new = b'-- Deployment erstellt keine Berechtigungen. SQL2019/2022/2025 Windows/Linux Zielmatrix.'
            require(comment.count(old) == 1, 'historical XLSX TVF help note differs')
            comment = comment.replace(old, new, 1)
        return signature + b'\n' + comment + b'\nRETURNS TABLE' + tail

    contract_path = 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Xlsx.Contract.sql'
    if path == contract_path:
        anchor = (b"EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=NULL,@MaxParts=0,"
                  b"@ResultTable=N'not a temp table';\n")
        block = '''\nDECLARE @Help TABLE
(
 HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,
 Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,
 IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL
);
INSERT @Help EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe=1;
IF NOT EXISTS(SELECT 1 FROM @Help WHERE ObjectName=N'USP_ListXlsxWorksheets' AND Section='EXAMPLE' AND ExampleSql LIKE N'%@XlsxBinary=@SyntheticWorkbook%' AND ExampleSql NOT LIKE N'%@Hilfe=1%')
 THROW 51590,N'ListXlsxWorksheets Hilfe benötigt ein funktionales Beispiel.',1;
DELETE FROM @Help;
INSERT @Help EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;
IF NOT EXISTS(SELECT 1 FROM @Help WHERE ObjectName=N'USP_ReadXlsxWorksheetCells' AND Section='EXAMPLE' AND ExampleSql LIKE N'%@XlsxBinary=@SyntheticWorkbook%' AND ExampleSql LIKE N'%@SheetOrdinal=1%')
 THROW 51590,N'ReadXlsxWorksheetCells Hilfe benötigt ein funktionales Beispiel.',1;
'''.encode('utf-8')
        require(original.count(anchor) == 1, 'historical XLSX contract anchor is missing or duplicated')
        return original.replace(anchor, anchor + block, 1)

    raise ValueError('unsupported XLSX help source path')


def validate_historical_help_source(root, path, executed_digest):
    """Keep old XLSX execution pins through the separately bound Help delta."""
    expected = XLSX_HELP_SOURCE_SHA256.get(path)
    require(expected is not None and isinstance(executed_digest, str)
            and executed_digest.lower() == expected,
            'unsupported historical XLSX help source or execution pin')
    import help_contract_source
    return help_contract_source.validate_historical_source(root, path, expected)


def project_help_cell_test(r21_source):
    """Add one exact dispatch to the already-bound R21 cell checker."""
    require(r21_source.count(CELL_HELP_ANCHOR) == 1
            and CELL_HELP_HOOK not in r21_source,
            'historical XLSX cell-checker help anchor differs')
    return r21_source.replace(CELL_HELP_ANCHOR, CELL_HELP_ANCHOR + CELL_HELP_HOOK, 1)


def restore_help_cell_test(root, current):
    """Reverse only the help dispatch and return the exact R21 checker bytes."""
    archive_bytes = (Path(root) / ARCHIVE).read_bytes()
    require(digest(archive_bytes) == ARCHIVE_SHA256,
            'historical checker archive differs')
    name = ARCHIVE_PREFIX + CELL_TEST
    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        entries = [entry for entry in archive.infolist() if entry.filename == name]
        require(len(entries) == 1 and not entries[0].is_dir(),
                'historical checker is missing or duplicated')
        original = archive.read(entries[0])
    require(digest(original) == PREVIOUS_CELL_TEST_SHA256,
            'historical checker archive pin differs')
    r21 = project_cell_test(original)
    projected = project_help_cell_test(r21)
    require(current in (r21, projected),
            'current cell checker differs outside the exact help dispatch')
    return r21


def restore_help_checker_module(current):
    """Reverse only the later Help dispatch additions to the pinned SST helper."""
    source_map = b'''XLSX_HELP_SOURCE_SHA256 = {
    'Modules/toolbelt.file.xlsx-memory/Source/TVF_FormatXlsxCell.sql': '0486ecef2cefd4eb37a057592459c57601ac479705a7a58bd3183acfe2a95975',
    'Modules/toolbelt.file.xlsx-memory/Source/TVF_InterpretXlsxCell.sql': '5da7aca180f52b8128f819c72e5003fb9c632516a5ac5f3f4a4d4999c2e3616d',
    'Modules/toolbelt.file.xlsx-memory/Source/USP_ListXlsxWorksheets.sql': '2a8b4e8368e529c9a0d882ad784d0a4fa38bdf83a15a87b2e772705bb61e31c1',
    'Modules/toolbelt.file.xlsx-memory/Source/USP_ReadXlsxWorksheetCells.sql': 'ced8e5ccc754303317ed06a1d72e5003fb9c632516a5ac5f3f4a4d4999c2e3616d',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md': '045167e135141f62282570a094a4a9cab9ec5f5ca0dd21c361a27f67d7a0f848',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md': '640d6d221bf171ab0fb28c1df2cdf66e2e32b95826ff5382f97c7eebae530ed3',
    'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Xlsx.Contract.sql': 'efa6cd746c51e3047a13008e385e61d2ce5b543e6a84103a10599ac7c1a63683',
}
'''
    cell_help_constants = (b"CELL_HELP_ANCHOR = (b'            if path == xlsx_sst_budget.WORKBOOK:\\n'\n"
                           b"                    b'                xlsx_sst_budget.validate_historical_source(ROOT, path, digest)\\n'\n"
                           b"                    b'                continue\\n')\n"
                           b"CELL_HELP_HOOK = (b'            if path in xlsx_sst_budget.XLSX_HELP_SOURCE_SHA256:\\n'\n"
                           b"                  b'                xlsx_sst_budget.validate_historical_help_source(ROOT, path, digest)\\n'\n"
                           b"                  b'                continue\\n')\n")
    helper_pin_constant = (b"PREVIOUS_HELP_MODULE_SHA256 = "
                           + b"'" + PREVIOUS_HELP_MODULE_SHA256.encode('ascii') + b"'\n")
    function_start = b'\ndef project_historical_xlsx_help(path, original):\n'
    function_end = b'\ndef project_cell_test(previous):\n'
    previous_cell_test = (b"    require(digest(current) == record['current_source_sha256'][CELL_TEST]\n"
                          b"            and current.count(IMPORT_AFTER) == current.count(CELL_HOOK) == 1,\n"
                          b"            'cell evidence test differs from exact SST dispatch')\n"
                          b"    previous = current.replace(IMPORT_AFTER, IMPORT_BEFORE).replace(CELL_HOOK, b'')\n"
                          b"    require(digest(previous) == PREVIOUS_CELL_TEST_SHA256\n"
                          b"            and project_cell_test(previous) == current,\n")
    current_cell_test = (b"    r21 = restore_help_cell_test(root, current)\n"
                         b"    require(digest(r21) == record['current_source_sha256'][CELL_TEST]\n"
                         b"            and r21.count(IMPORT_AFTER) == r21.count(CELL_HOOK) == 1,\n"
                         b"            'cell evidence test differs from exact SST dispatch')\n"
                         b"    previous = r21.replace(IMPORT_AFTER, IMPORT_BEFORE).replace(CELL_HOOK, b'')\n"
                         b"    require(digest(previous) == PREVIOUS_CELL_TEST_SHA256\n"
                         b"            and project_cell_test(previous) == r21,\n")
    previous_validate = (b"        require(digest((root / path).read_bytes()) == expected, 'current SST source differs: ' + path)\n")
    current_validate = (b"        current = (root / path).read_bytes()\n"
                       b"        if path == CELL_TEST:\n"
                       b"            current = restore_help_cell_test(root, current)\n"
                       b"        elif path == 'Scripts/Release/xlsx_sst_budget.py':\n"
                       b"            current = restore_help_checker_module(current)\n"
                       b"        elif path == 'Tests/Release/test_xlsx_boundary_evidence.py':\n"
                       b"            import help_contract_source\n"
                       b"            current = help_contract_source.restore_boundary_checker(root, current, expected)\n"
                       b"        elif path == 'Tests/Release/test_xlsx_metadata.py':\n"
                       b"            import help_contract_source\n"
                       b"            current = help_contract_source.restore_xlsx_metadata_test(root, current, expected)\n"
                       b"        elif path == 'Tests/Release/test_xlsx_raw_caller_evidence.py':\n"
                       b"            import help_contract_source\n"
                       b"            current = help_contract_source.restore_raw_caller_checker(root, current, expected)\n"
                       b"        elif path == 'Tests/Release/test_xlsx_zip_package_framework.py':\n"
                       b"            import help_contract_source\n"
                       b"            current = help_contract_source.restore_zip_framework_checker(root, current, expected)\n"
                       b"        elif path in help_contract_source.NAV_PATHS:\n"
                       b"            import help_contract_source\n"
                       b"            current = help_contract_source.validate_navigation_source(root, path, expected)\n"
                       b"        require(digest(current) == expected, 'current SST source differs: ' + path)\n")

    result = current
    source_map_anchor = b'}\nXLSX_HELP_SOURCE_SHA256 = {\n'
    source_map_end = b'}\nHISTORICAL_REPORT_EOL = {\n'
    require(result.count(source_map_anchor) == 1 and result.count(source_map_end) == 1,
            'XLSX Help source map transition is ambiguous')
    map_start = result.index(source_map_anchor) + len(b'}\n')
    map_end = result.index(source_map_end, map_start) + len(b'}\n')
    result = result[:map_start] + result[map_end:]
    require(result.count(cell_help_constants) == 1, 'XLSX Help checker constants transition is ambiguous')
    result = result.replace(cell_help_constants, b'', 1)
    require(result.count(helper_pin_constant) == 1,
            'SST helper historical pin transition is ambiguous')
    result = result.replace(helper_pin_constant, b'', 1)
    require(result.count(function_start) == 1 and result.count(function_end) == 1,
            'XLSX Help checker function block is ambiguous')
    start = result.index(function_start)
    end = result.index(function_end, start)
    result = result[:start] + result[end:]
    require(result.count(current_cell_test) == 1, 'SST checker transition is ambiguous')
    result = result.replace(current_cell_test, previous_cell_test, 1)
    require(result.count(current_validate) == 1, 'SST current-source validation transition is ambiguous')
    result = result.replace(current_validate, previous_validate, 1)
    import_anchor = b"    record = read_record(root)\n    import help_contract_source\n"
    require(result.count(import_anchor) == 1, 'SST helper import transition is ambiguous')
    result = result.replace(import_anchor, b"    record = read_record(root)\n", 1)
    require(digest(result) == PREVIOUS_HELP_MODULE_SHA256,
            'SST helper differs beyond the exact later Help dispatch')
    return result


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
    r21 = restore_help_cell_test(root, current)
    require(digest(r21) == record['current_source_sha256'][CELL_TEST]
            and r21.count(IMPORT_AFTER) == r21.count(CELL_HOOK) == 1,
            'cell evidence test differs from exact SST dispatch')
    previous = r21.replace(IMPORT_AFTER, IMPORT_BEFORE).replace(CELL_HOOK, b'')
    require(digest(previous) == PREVIOUS_CELL_TEST_SHA256
            and project_cell_test(previous) == r21,
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
        start = min([node.lineno] + [item.lineno for item in getattr(node, 'decorator_list', ())])
        return ''.join(lines[start - 1:node.end_lineno])

    definitions = {}
    for node in module.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            definitions.setdefault(node.name, []).append(node)
    selected_name_definitions = definitions.get(OFFLINE_TEST_CLASS, [])
    require(len(selected_name_definitions) == 1 and selected_name_definitions[0].__class__ is ast.ClassDef,
            'offline qualification class is rebound at module scope')
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
    module_context = [node for node in module.body
                      if not isinstance(node, (ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef))]
    scoped_nodes = [*cls.bases, *cls.keywords, *cls.decorator_list, selected[0]]
    scoped_nodes.extend(node for name in OFFLINE_TEST_FIXTURES
                        for node in methods if node.name == name)

    def referenced_names(nodes):
        return {node.id for item in nodes for node in ast.walk(item)
                if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Load)}

    pending = referenced_names([*module_context, *scoped_nodes])
    included_helpers = {}
    while pending:
        name = pending.pop()
        matches = definitions.get(name, [])
        if not matches:
            continue
        require(len(matches) == 1,
                'offline qualification referenced helper is duplicated: ' + name)
        helper = matches[0]
        if helper is cls or name in included_helpers:
            continue
        require(not (isinstance(helper, ast.ClassDef)
                     and getattr(helper, 'type_params', ())),
                'offline qualification helper has unsupported type parameters: ' + name)
        included_helpers[name] = node_source(helper)
        if isinstance(helper, ast.ClassDef):
            pending.update(referenced_names([*helper.bases, *helper.keywords,
                                             *helper.decorator_list, *helper.body]))
        else:
            pending.update(referenced_names([helper]))
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
        'module_context': [node_source(node) for node in module_context],
        'referenced_helpers': included_helpers,
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
    import help_contract_source
    require(record['candidate_bundle']['path'] == CANDIDATE_BUNDLE,
            'unexpected SST candidate archive path')
    require(record['historical_report_eol_projections'] == HISTORICAL_REPORT_EOL,
            'historical report EOL bindings differ')
    for path, expected in record['current_source_sha256'].items():
        require(not Path(path).is_absolute() and '..' not in Path(path).parts,
                'unsafe SST source path')
        current = (root / path).read_bytes()
        if path == CELL_TEST:
            current = restore_help_cell_test(root, current)
        elif path == 'Scripts/Release/xlsx_sst_budget.py':
            current = restore_help_checker_module(current)
        elif path == 'Tests/Release/test_xlsx_boundary_evidence.py':
            import help_contract_source
            current = help_contract_source.restore_boundary_checker(root, current, expected)
        elif path == 'Tests/Release/test_xlsx_metadata.py':
            import help_contract_source
            current = help_contract_source.restore_xlsx_metadata_test(root, current, expected)
        elif path == 'Tests/Release/test_xlsx_raw_caller_evidence.py':
            import help_contract_source
            current = help_contract_source.restore_raw_caller_checker(root, current, expected)
        elif path == 'Tests/Release/test_xlsx_zip_package_framework.py':
            import help_contract_source
            current = help_contract_source.restore_zip_framework_checker(root, current, expected)
        elif path in help_contract_source.NAV_PATHS:
            import help_contract_source
            current = help_contract_source.validate_navigation_source(root, path, expected)
        require(digest(current) == expected, 'current SST source differs: ' + path)
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
