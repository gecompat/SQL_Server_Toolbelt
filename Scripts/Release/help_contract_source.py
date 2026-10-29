"""Exact, non-qualifying source transition for the approved Help-contract delta."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import stat
import subprocess
import zipfile
import new_ssis_standalone_tsql as standalone


RECORD = 'Releases/1.0.0/help-contract-source-delta.json'
RECORD_SHA256 = '70fed4351d4a6d7a98f386a5086738a76ceb65f43a379db394c168c0c6354c3c'
ARCHIVE = 'Releases/1.0.0/Artifacts/Help-Contract-Baseline.zip'
ARCHIVE_SHA256 = '5296d100269ab116f133f26c07164c6183d3fd8fed5f5db299a5b5323f9d0922'
BASELINE_COMMIT = 'e2c932a5906fc65a2af8cbc6ab106b7bdb51b58e'
SCHEMA = 'toolbelt-help-contract-source-delta/v1'
SCOPE = ('Existing 14 procedure help contracts, two retained XLSX TVF comments, five explicitly '
         'approved ResultTable routes, coupled dependency/fixtures/documentation; no SSIS or '
         'new SQL object')
APPROVED_RESULTTABLE_ROUTES = [
    'USP_LoadBinaryFile', 'USP_LoadTextFile', 'USP_EnqueueWorkWithPolicy',
    'USP_RequeueDeadLetter', 'USP_EnqueueBarrierWork',
]
RESULTTABLE_CONTRACT = ('Existing SELECT or local #Temp through canonical helper, replace/append, '
                        'preflight before queue DML/file IO; unchanged result columns and rights boundaries')
SOURCE_PATHS = frozenset({
    'Documentation/Architecture/FILE_CONTENT_MODULE_DESIGN.md',
    'Modules/toolbelt.core.event-log/Documentation/EVENT_LOG_OBJECTS.md',
    'Modules/toolbelt.core.event-log/Source/USP_WriteEventInternal.sql',
    'Modules/toolbelt.core.event-log/Tests/Runtime/Lifecycle.Contract.sql',
    'Modules/toolbelt.core.execution-cancel/Documentation/EXECUTION_CANCELLATION_OBJECTS.md',
    'Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql',
    'Modules/toolbelt.core.execution-cancel/Tests/Runtime/ExecutionCancellation.Contract.sql',
    'Modules/toolbelt.core.second-session/Documentation/SECOND_SESSION_OBJECTS.md',
    'Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql',
    'Modules/toolbelt.core.second-session/Source/USP_SecondSessionProbe.sql',
    'Modules/toolbelt.core.second-session/Tests/Runtime/Lifecycle.Contract.sql',
    'Modules/toolbelt.core.second-session/Tests/Static/validate_contract.py',
    'Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md',
    'Modules/toolbelt.core.work-queue/Source/USP_EnqueueBarrierWork.sql',
    'Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql',
    'Modules/toolbelt.core.work-queue/Source/USP_RequeueDeadLetter.sql',
    'Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetry.sql',
    'Modules/toolbelt.core.work-queue/Tests/Runtime/WorkQueue.Contract.sql',
    'Modules/toolbelt.file.content/Deployment/Deploy.sql',
    'Modules/toolbelt.file.content/Documentation/USP_LoadBinaryFile.md',
    'Modules/toolbelt.file.content/Documentation/USP_LoadTextFile.md',
    'Modules/toolbelt.file.content/README.md',
    'Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql',
    'Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql',
    'Modules/toolbelt.file.content/Tests/Runtime/FileContent.Contract.sql',
    'Modules/toolbelt.file.content/Tests/Static/validate_contract.py',
    'Modules/toolbelt.file.content/module.yaml',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md',
    'Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md',
    'Modules/toolbelt.file.xlsx-memory/Source/TVF_FormatXlsxCell.sql',
    'Modules/toolbelt.file.xlsx-memory/Source/TVF_InterpretXlsxCell.sql',
    'Modules/toolbelt.file.xlsx-memory/Source/USP_ListXlsxWorksheets.sql',
    'Modules/toolbelt.file.xlsx-memory/Source/USP_ReadXlsxWorksheetCells.sql',
    'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Xlsx.Contract.sql',
    'Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableCloneInternal.sql',
    'Modules/toolbelt.metadata.table-clone/Tests/Runtime/Lifecycle.Contract.sql',
    'Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookupCore.sql',
    'Modules/toolbelt.pseudonymization.deterministic/Tests/Runtime/InstalledMetadata.Contract.sql',
    'Modules/toolbelt.pseudonymization.deterministic/Tests/Static/validate_geo.py',
    'Releases/1.0.0/CLR-INSTALL.md',
})
RECORD_KEYS = {
    'schema_version', 'date', 'status', 'native_requalification_claimed',
    'current_head_ci_required', 'publication_authorized', 'baseline_commit',
    'baseline_archive', 'baseline_archive_sha256', 'scope',
    'approved_resulttable_routes', 'resulttable_contract',
    'baseline_source_sha256', 'current_source_sha256',
}
BOUNDARY_TEST = 'Tests/Release/test_xlsx_boundary_evidence.py'
BOUNDARY_BASELINE_COMMIT = BASELINE_COMMIT
BOUNDARY_BASELINE_SHA256 = 'b497d2ddd1d4fd2691b2753dff8e71e7208cd4e10ff29b7f408bf3bb154465c6'
BOUNDARY_CURRENT_SHA256 = 'bf78685fcef66a6d5b681e701fa9521dcea1c1fb3f451405d297725dc5059a88'
XLSX_METADATA_TEST = 'Tests/Release/test_xlsx_metadata.py'
XLSX_METADATA_BASELINE_SHA256 = '6e71519987a874ded010d3656ca352e9180ee63d24dce98a532d831d309b1f6e'
XLSX_METADATA_CURRENT_SHA256 = '9fc40865664197c720286b62762a81d8ee939ec69f0e8e723ce30bfff4681435'
RAW_CALLER_TEST = 'Tests/Release/test_xlsx_raw_caller_evidence.py'
RAW_CALLER_BASELINE_SHA256 = '51d9d192814f1110c40f1973885c9a305c1f0e9e8cab10d2653e0b81a372288f'
RAW_CALLER_CURRENT_SHA256 = '10e6401a85f3f462c4780acb4271f8795bd47961c8d4b5dcfe74c8fe6f1ac51b'
ZIP_FRAMEWORK_TEST = 'Tests/Release/test_xlsx_zip_package_framework.py'
ZIP_FRAMEWORK_BASELINE_SHA256 = '09016ffd43fc25c65a30c305c3024640bc7c7e5ec03a846dccc7fd73b8ab2b04'
ZIP_FRAMEWORK_CURRENT_SHA256 = '91c07940b05eb17ebfdadd75753cdf03f787fb13fd4c8a6e2a9953c52197fc8a'
NAV_RECORD = 'Releases/1.0.0/help-contract-navigation-delta.json'
NAV_ARCHIVE = 'Releases/1.0.0/Artifacts/Help-Contract-Navigation-Baseline.zip'
NAV_ARCHIVE_SHA256 = 'b1838c27f64bd762cc623a5027d61852ec207e5abd94342e4915e9fd896c65fc'
NAV_PATHS = frozenset({
    'Releases/1.0.0/README.md',
    'Releases/1.0.0/EVIDENCE-MAP.md',
    'Releases/1.0.0/RELEASE-GATES.md',
})
NAV_BASELINE_SHA256 = {
    'Releases/1.0.0/README.md': '8edf478282bfebe41e3b9af76eff5b3f878a162ff320111ceb1473e565b17db3',
    'Releases/1.0.0/EVIDENCE-MAP.md': '29cf8aa393f4dbd2d3296fab60d74bd5ffb560e4fc72aaf5af4b227a0dc0bbe8',
    'Releases/1.0.0/RELEASE-GATES.md': '5e70269381947a5eb57b86df211ebf04af9cf491fd4093cc0ff58c64d7b771e4',
}
NAV_CURRENT_SHA256 = {
    'Releases/1.0.0/README.md': 'e60daa78a47e69d8ec0a7c87ed088231bd09357a3ccb50a92a0fb86e6fc32bf4',
    'Releases/1.0.0/EVIDENCE-MAP.md': '4845ee28c48d71fd30d4e202aca40329c65475e6b3ac61efb6c61153d6cfdd64',
    'Releases/1.0.0/RELEASE-GATES.md': '39d44ea5f043642d938410bc746c32736072cf8b07e9f0bdf7220f31379c9be7',
}
SSIS_INSTALL_NAV_RECORD = 'Releases/1.0.0/ssis-standalone-installer-navigation-delta.json'
SSIS_INSTALL_NAV_SNAPSHOT_ROOT = 'Scripts/Release/HistoricalSources/ssis-standalone-installer-navigation'
SSIS_INSTALL_NAV_PATHS = frozenset({
    'Releases/1.0.0/README.md',
    'Releases/1.0.0/EVIDENCE-MAP.md',
})
SSIS_INSTALL_NAV_SNAPSHOT_FILES = {
    'Releases/1.0.0/README.md': 'Releases-1.0.0-README.txt',
    'Releases/1.0.0/EVIDENCE-MAP.md': 'Releases-1.0.0-EVIDENCE-MAP.txt',
}
SSIS_INSTALL_NAV_BASELINE_SHA256 = {
    path: NAV_CURRENT_SHA256[path] for path in SSIS_INSTALL_NAV_PATHS
}
SSIS_INSTALL_NAV_CURRENT_SHA256 = {
    'Releases/1.0.0/README.md': '95f817e0ff7a450481a43df715f9dd0593c672f3f0a383424183c2327e38d1e3',
    'Releases/1.0.0/EVIDENCE-MAP.md': '7e00b3763cfc94789eca6a86d2f7267588093d66e9c352757daf08b8ac2f157b',
}
SSIS_INSTALL_NAV_SNAPSHOT_SHA256 = dict(SSIS_INSTALL_NAV_CURRENT_SHA256)
SSIS_INSTALL_NAV_BLOCKS = {
    'Releases/1.0.0/README.md': (
        'Der [eigenständige SSIS-T-SQL-Installer](SSIS-INSTALL-TSQL.md) bündelt die\n'
        'bereits qualifizierten SQL-CLR-Objekte samt exakten DLLs in einem ausführbaren\n'
        'T-SQL-Batch. Er ändert weder die bestehende Paketqualifikation noch den\n'
        'Veröffentlichungsstatus; DTSX-Paketberichte werden getrennt behandelt.\n\n'
    ).encode('utf-8'),
    'Releases/1.0.0/EVIDENCE-MAP.md': (
        'Der [eigenständige T-SQL-Installer](SSIS-INSTALL-TSQL.md) liefert die bereits\n'
        'qualifizierten ResultTable-, Script-Parser- und SSIS-Debug-Assemblies ohne\n'
        'SQLCMD-Batchverarbeitung. Seine ausgewählten Installationsprüfungen aktualisieren\n'
        'weder die bestehenden Paketberichte noch den Veröffentlichungsstatus. Ein\n'
        'DTSX-Bericht ist ein separater Nachweisumfang.\n\n'
    ).encode('utf-8'),
}
SSIS_MATRIX_RELEASE_GATES_PATH = 'Releases/1.0.0/RELEASE-GATES.md'
SSIS_MATRIX_RELEASE_GATES_CURRENT_SHA256 = '683aea7d2cf6d2594138969c4cee206c89b4d059e2afa39132ac8e6e9279af19'
SSIS_MATRIX_RELEASE_GATES_DELTA = (
    '| SSIS: aktuelles ZIP auf allen Windows-/CL-/Moduskontexten | **PASS FÜR DEN GEBUNDENEN AKTUELLEN PAKETVERTRAG** | Zehn neue Paketfälle mit je 206 festen Assertions und zehn unabhängigen Audits ergänzen zwei unveränderte grüne Fälle: SQL 2019/CL150, SQL 2022/CL150/160 und SQL 2025/CL150/160/170 jeweils lokal und zentral. API-Metadaten, editierbare Defaults, SQL-Limits, ResultTable-Schutz und ausgeführte Row-Count-/Flatfile-Debug-Scripts sind belegt; keine vollständige SSIS-Modulabnahme. | Übrige Komponenten-/Ausdruckskombinationen, Standalone-Installer auf niedrigeren CLs, echte SSIS-Ausführung, Windowsauthentifizierung/GUI, TLS und Recovery bleiben eigene Gates. | [Aktuelle Paketmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.InstallPackage.Matrix.20261029.json), [Prüfmatrix mit Grenzen](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) |\n',
    'Die aktuelle SSIS-Paketmatrix ergänzt zehn fehlende Fälle samt zehn unabhängigen\nAudits und übernimmt zwei unveränderte grüne Fälle ohne erneuten SQL-Lauf.\nEin Luna-Implementierer und das integrierende Vertrags-/Evidenzreview genügen.\nSechs Offlineprüfungen für Zusammensetzung und Manipulationsabwehr laufen im\nbestehenden SSIS-Workflow; es entstehen weder ein weiterer Workflow noch ein\nSQL-CI-Lauf, Prozessrunner oder eine zusätzliche Reviewkette. Lokal werden nur\ngeänderte Prüfungen ausgeführt; Pflichtprüfungen am aktuellen Head und die echte\nMain-Push-CI bleiben erforderlich. Rohprotokolle bleiben privat; Kosten und\nTokens sind unbekannt. Produkt und Paketbytes bleiben unverändert.\n\n',
)


def _require(condition, message):
    if not condition:
        raise ValueError(message)


def _digest(data):
    return hashlib.sha256(data).hexdigest()


def validate_ssis_installer_navigation(root, path):
    """Replay the closed navigation delta from immutable historical snapshots."""
    root = Path(root).resolve()
    _require(path in SSIS_INSTALL_NAV_PATHS,
             'unsupported standalone installer navigation path')
    record_path = root / SSIS_INSTALL_NAV_RECORD
    record = json.loads(record_path.read_text(encoding='utf-8'))
    required = {
        'schema_version', 'date', 'status', 'native_requalification_claimed',
        'publication_authorized', 'scope', 'baseline_source_sha256',
        'current_source_sha256',
    }
    _require(isinstance(record, dict) and set(record) == required
             and record['schema_version'] == 'toolbelt-ssis-installer-navigation-delta/v1'
             and record['date'] == '2026-10-28'
             and record['status'] == 'DOCUMENTATION_DELTA_ONLY'
             and record['native_requalification_claimed'] is False
             and record['publication_authorized'] is False
             and record['scope'] == 'Two exact release-page links to the standalone T-SQL installer; no historic qualification is changed',
             'standalone installer navigation delta claims differ')
    baseline = record['baseline_source_sha256']
    current = record['current_source_sha256']
    _require(isinstance(baseline, dict) and set(baseline) == SSIS_INSTALL_NAV_PATHS
             and baseline == SSIS_INSTALL_NAV_BASELINE_SHA256
             and isinstance(current, dict) and set(current) == SSIS_INSTALL_NAV_PATHS
             and current == SSIS_INSTALL_NAV_CURRENT_SHA256
             and SSIS_INSTALL_NAV_SNAPSHOT_SHA256 == current
             and set(SSIS_INSTALL_NAV_SNAPSHOT_FILES) == SSIS_INSTALL_NAV_PATHS,
             'standalone installer navigation source pins differ')
    snapshot_relative = (PurePosixPath(SSIS_INSTALL_NAV_SNAPSHOT_ROOT) /
                         SSIS_INSTALL_NAV_SNAPSHOT_FILES[path]).as_posix()
    source = standalone.read_regular_bounded(root / snapshot_relative, 1024 * 1024)
    _require(_digest(source) == SSIS_INSTALL_NAV_SNAPSHOT_SHA256[path],
             'standalone installer navigation historical snapshot pin differs')
    block = SSIS_INSTALL_NAV_BLOCKS[path]
    _require(source.count(block) == 1,
             'standalone installer navigation block is missing or duplicated')
    block_start = source.index(block)
    restored = source[:block_start] + source[block_start + len(block):]
    _require(_digest(restored) == baseline[path]
             and restored[:block_start] + block + restored[block_start:] == source,
             'standalone installer navigation transition is not exactly reversible')
    return restored


def restore_ssis_matrix_release_gates(current):
    """Remove only the new current-package navigation from its historical view."""
    _require(isinstance(current, bytes)
             and _digest(current) == SSIS_MATRIX_RELEASE_GATES_CURRENT_SHA256,
             'current SSIS release-gates bytes differ')
    restored = current
    for added in SSIS_MATRIX_RELEASE_GATES_DELTA:
        added_bytes = added.encode('utf-8')
        _require(restored.count(added_bytes) == 1,
                 'current SSIS release-gates transition anchor differs')
        restored = restored.replace(added_bytes, b'', 1)
    _require(_digest(restored) == NAV_CURRENT_SHA256[SSIS_MATRIX_RELEASE_GATES_PATH],
             'current SSIS release-gates transition output differs')
    return restored


def _record(root):
    root = Path(root).resolve()
    record_bytes = (root / RECORD).read_bytes()
    _require(_digest(record_bytes) == RECORD_SHA256,
             'Help source-delta record differs from its fixed binding')
    record = json.loads(record_bytes.decode('utf-8'))
    _require(isinstance(record, dict) and set(record) == RECORD_KEYS,
             'Help source-delta record fields differ')
    _require(record['schema_version'] == SCHEMA
             and record['status'] == 'SOURCE_DELTA_ONLY'
             and record['native_requalification_claimed'] is False
             and record['current_head_ci_required'] is True
             and record['publication_authorized'] is False
             and record['date'] == '2026-10-28'
             and record['baseline_commit'] == BASELINE_COMMIT
             and record['baseline_archive'] == ARCHIVE
             and record['baseline_archive_sha256'] == ARCHIVE_SHA256
             and record['scope'] == SCOPE
             and record['approved_resulttable_routes'] == APPROVED_RESULTTABLE_ROUTES
             and record['resulttable_contract'] == RESULTTABLE_CONTRACT,
             'Help source-delta record claims differ')
    baseline = record['baseline_source_sha256']
    current = record['current_source_sha256']
    _require(isinstance(baseline, dict) and isinstance(current, dict)
             and len(baseline) == 40 and set(baseline) == SOURCE_PATHS
             and set(current) == SOURCE_PATHS,
             'Help source-delta path sets differ')
    for path, digest in baseline.items():
        pure = PurePosixPath(path)
        _require(not pure.is_absolute() and '..' not in pure.parts
                 and isinstance(digest, str) and len(digest) == 64
                 and all(c in '0123456789abcdef' for c in digest),
                 'Unsafe or malformed Help baseline pin')
        new_digest = current[path]
        _require(isinstance(new_digest, str) and len(new_digest) == 64
                 and all(c in '0123456789abcdef' for c in new_digest),
                 'Malformed Help current pin')
    archive_path = root / ARCHIVE
    archive_bytes = archive_path.read_bytes()
    _require(_digest(archive_bytes) == ARCHIVE_SHA256,
             'Help baseline archive differs')
    expected_files = set(baseline) | {'LICENSE.md'}
    expected_directories = {
        '/'.join(PurePosixPath(path).parts[:index]) + '/'
        for path in expected_files
        for index in range(1, len(PurePosixPath(path).parts))
    }
    with zipfile.ZipFile(archive_path) as archive:
        entries = archive.infolist()
        names = [entry.filename for entry in entries]
        files = {entry.filename for entry in entries if not entry.is_dir()}
        directories = {entry.filename for entry in entries if entry.is_dir()}
        _require(len(names) == len(set(names)) and files == expected_files
                 and directories == expected_directories,
                 'Help baseline archive file set differs')
        for entry in entries:
            mode = (entry.external_attr >> 16) & 0o170000
            allowed = (0, stat.S_IFDIR) if entry.is_dir() else (0, stat.S_IFREG)
            _require(mode in allowed and not entry.flag_bits & 0x1,
                     'Help baseline archive contains a non-regular entry')
            if not entry.is_dir() and entry.filename != 'LICENSE.md':
                _require(_digest(archive.read(entry)) == baseline[entry.filename],
                         'Help baseline archive entry differs from its fixed pin')
        license_entries = [entry for entry in entries if entry.filename == 'LICENSE.md']
        _require(len(license_entries) == 1
                 and archive.read(license_entries[0]) == (root / 'LICENSE.md').read_bytes(),
                 'Help baseline archive license differs')
    return root, record


def validate_historical_source(root, path, expected_sha256):
    """Return exact baseline bytes only when archive, record, and current bytes bind."""
    root, record = _record(root)
    _require(isinstance(path, str) and path in record['baseline_source_sha256'],
             'Unsupported Help source path')
    expected = record['baseline_source_sha256'][path]
    _require(isinstance(expected_sha256, str) and expected_sha256.lower() == expected,
             'Historical Help source pin differs')
    archive_path = root / ARCHIVE
    archive_bytes = archive_path.read_bytes()
    _require(_digest(archive_bytes) == ARCHIVE_SHA256,
             'Help baseline archive differs')
    entry_name = path
    with zipfile.ZipFile(archive_path) as archive:
        matches = [item for item in archive.infolist() if item.filename == entry_name]
        _require(len(matches) == 1 and not matches[0].is_dir()
                 and (matches[0].external_attr >> 16) & 0o170000 != 0o120000,
                 'Help baseline entry is missing, duplicate, or not regular')
        original = archive.read(matches[0])
    _require(_digest(original) == expected,
             'Help baseline entry differs from its fixed digest')
    current = (root / path).read_bytes()
    _require(_digest(current) == record['current_source_sha256'][path],
             'Current Help source differs from its fixed digest')
    return original


def source_paths(root):
    """Return only known delta paths without requiring their record for unrelated paths."""
    return SOURCE_PATHS


def validate_current_source(root, path):
    """Validate exact current bytes against the same immutable transition record."""
    root, record = _record(root)
    _require(isinstance(path, str) and path in record['current_source_sha256'],
             'Unsupported Help source path')
    expected = record['baseline_source_sha256'][path]
    validate_historical_source(root, path, expected)
    return (root / path).read_bytes()


def validate_navigation_source(root, path, expected_sha256):
    """Return an exact old navigation page while validating its separate delta."""
    root = Path(root).resolve()
    record = json.loads((root / NAV_RECORD).read_text(encoding='utf-8'))
    required = {
        'schema_version', 'date', 'status', 'native_requalification_claimed',
        'publication_authorized', 'baseline_commit', 'baseline_archive',
        'baseline_archive_sha256', 'scope', 'baseline_source_sha256',
        'current_source_sha256',
    }
    _require(isinstance(record, dict) and set(record) == required
             and record['schema_version'] == 'toolbelt-release-navigation-delta/v1'
             and record['date'] == '2026-10-28'
             and record['status'] == 'DOCUMENTATION_DELTA_ONLY'
             and record['native_requalification_claimed'] is False
             and record['publication_authorized'] is False
             and record['baseline_commit'] == BASELINE_COMMIT
             and record['baseline_archive'] == NAV_ARCHIVE
             and record['baseline_archive_sha256'] == NAV_ARCHIVE_SHA256
             and record['scope'] == 'Three release navigation pages describe the separately qualified XLSX maintenance package; historical reports remain unchanged',
             'navigation delta record claims differ')
    baseline = record['baseline_source_sha256']
    current = record['current_source_sha256']
    _require(baseline == NAV_BASELINE_SHA256
             and current == NAV_CURRENT_SHA256
             and isinstance(baseline, dict) and set(baseline) == NAV_PATHS
             and isinstance(current, dict) and set(current) == NAV_PATHS
             and path in NAV_PATHS and expected_sha256 == baseline[path],
             'unsupported navigation path or historical pin')
    archive_path = root / NAV_ARCHIVE
    archive_bytes = archive_path.read_bytes()
    _require(_digest(archive_bytes) == NAV_ARCHIVE_SHA256,
             'navigation baseline archive differs')
    with zipfile.ZipFile(archive_path) as archive:
        names = [item.filename for item in archive.infolist()]
        expected_names = set(NAV_PATHS) | {'LICENSE.md', 'Releases/', 'Releases/1.0.0/'}
        matches = [item for item in archive.infolist() if item.filename == path]
        licenses = [item for item in archive.infolist() if item.filename == 'LICENSE.md']
        _require(len(names) == len(expected_names) and set(names) == expected_names
                 and len(matches) == len(licenses) == 1
                 and not matches[0].is_dir() and not licenses[0].is_dir()
                 and all((item.is_dir() if item.filename.endswith('/') else not item.is_dir())
                         for item in archive.infolist()),
                 'navigation archive entries differ')
        original = archive.read(matches[0])
        archived_license = archive.read(licenses[0])
    if path in SSIS_INSTALL_NAV_PATHS:
        current_bytes = validate_ssis_installer_navigation(root, path)
    elif path == SSIS_MATRIX_RELEASE_GATES_PATH:
        current_document = standalone.read_regular_bounded(root / path, 1024 * 1024)
        current_bytes = restore_ssis_matrix_release_gates(current_document)
    else:
        current_bytes = (root / path).read_bytes()
    _require(_digest(original) == baseline[path]
             and archived_license == (root / 'LICENSE.md').read_bytes()
             and _digest(current_bytes) == current[path],
             'navigation baseline/current binding differs')
    return original


def _boundary_projection(original):
    result = original
    replacements = (
        (b'import tempfile\n', b'import tempfile\nimport shutil\n'),
        (b'import xlsx_sst_budget\nREPORT = ROOT /',
         b'import xlsx_sst_budget\nimport caller_metadata\nimport help_contract_source\nREPORT = ROOT /'),
        (b"                data = (xlsx_sst_budget.validate_historical_source(ROOT, relative, expected)\n"
         b"                        if relative == xlsx_sst_budget.WORKBOOK else (ROOT / relative).read_bytes())\n",
         b"                if relative == xlsx_sst_budget.WORKBOOK:\n"
         b"                    data = xlsx_sst_budget.validate_historical_source(ROOT, relative, expected)\n"
         b"                elif relative in help_contract_source.source_paths(ROOT):\n"
         b"                    data = help_contract_source.validate_historical_source(ROOT, relative, expected)\n"
         b"                else:\n"
         b"                    data = (ROOT / relative).read_bytes()\n"),
        (b"        self.assertEqual(xlsx_sst_budget.project_cell_test(previous), current)\n"
         b"        with self.assertRaisesRegex(ValueError, 'exact SST dispatch'):\n",
         b"        r21 = xlsx_sst_budget.project_cell_test(previous)\n"
         b"        self.assertEqual(xlsx_sst_budget.restore_help_cell_test(ROOT, current), r21)\n"
         b"        self.assertEqual(xlsx_sst_budget.project_help_cell_test(r21), current)\n"
         b"        with self.assertRaisesRegex(ValueError, 'outside the exact help dispatch'):\n"
         b"            xlsx_sst_budget.restore_help_cell_test(\n"
         b"                ROOT, current.replace(xlsx_sst_budget.CELL_HELP_HOOK, b'            pass\\n', 1))\n"
         b"        with self.assertRaisesRegex(ValueError, 'outside the exact help dispatch'):\n"),
    )
    for before, after in replacements:
        _require(result.count(before) == 1, 'XLSX boundary checker transition anchor differs')
        result = result.replace(before, after, 1)
    first_marker = b"    def test_xlsx_boundary_eol_projection_accepts_only_exact_line_endings(self):\n"
    first_method = (b"    def test_xlsx_help_sources_keep_old_pins_with_exact_current_projection(self):\n"
                    b"        for path, executed in xlsx_sst_budget.XLSX_HELP_SOURCE_SHA256.items():\n"
                    b"            original = help_contract_source.validate_historical_source(ROOT, path, executed)\n"
                    b"            current = help_contract_source.validate_current_source(ROOT, path)\n"
                    b"            self.assertEqual(hashlib.sha256(original).hexdigest(), executed)\n"
                    b"            self.assertTrue(current)\n"
                    b"            caller_metadata.validate_source(ROOT, path, executed)\n"
                    b"            with self.assertRaisesRegex(ValueError, 'Historical Help source pin differs'):\n"
                    b"                caller_metadata.validate_source(ROOT, path, '0' * 64)\n\n")
    _require(result.count(first_marker) == 1, 'XLSX Help-source test insertion point differs')
    result = result.replace(first_marker, first_method + first_marker, 1)
    second_marker = b"    def test_sst_source_projections_allow_only_the_bound_changes(self):\n"
    second_method = (b"    def test_xlsx_help_source_transition_is_exact_and_archive_bound(self):\n"
                     b"        runtime = ROOT / '.runtime'\n"
                     b"        runtime.mkdir(exist_ok=True)\n"
                     b"        path = 'Modules/toolbelt.file.xlsx-memory/Source/USP_ListXlsxWorksheets.sql'\n"
                     b"        expected = xlsx_sst_budget.XLSX_HELP_SOURCE_SHA256[path]\n"
                     b"        original = help_contract_source.validate_historical_source(ROOT, path, expected)\n"
                     b"        current = help_contract_source.validate_current_source(ROOT, path)\n"
                     b"        with self.assertRaisesRegex(ValueError, 'Historical Help source pin differs'):\n"
                     b"            help_contract_source.validate_historical_source(ROOT, path, '0' * 64)\n"
                     b"        with self.assertRaisesRegex(ValueError, 'unsupported XLSX help source path'):\n"
                     b"            xlsx_sst_budget.project_historical_xlsx_help('../unexpected', original)\n\n"
                     b"        with tempfile.TemporaryDirectory(prefix='xlsx-help-pin-', dir=runtime) as folder:\n"
                     b"            sandbox = Path(folder)\n"
                     b"            target = sandbox / path\n"
                     b"            target.parent.mkdir(parents=True)\n"
                     b"            target.write_bytes(current + b'-- unrelated SQL change\\n')\n"
                     b"            (sandbox / help_contract_source.RECORD).parent.mkdir(parents=True)\n"
                     b"            shutil.copyfile(ROOT / help_contract_source.RECORD, sandbox / help_contract_source.RECORD)\n"
                     b"            archive_target = sandbox / help_contract_source.ARCHIVE\n"
                     b"            archive_target.parent.mkdir(parents=True)\n"
                     b"            shutil.copyfile(ROOT / help_contract_source.ARCHIVE, archive_target)\n"
                     b"            shutil.copyfile(ROOT / 'LICENSE.md', sandbox / 'LICENSE.md')\n"
                     b"            with self.assertRaisesRegex(ValueError, 'Current Help source differs'):\n"
                     b"                help_contract_source.validate_historical_source(sandbox, path, expected)\n"
                     b"            target.write_bytes(current)\n"
                     b"            archive_target.write_bytes(archive_target.read_bytes() + b'corruption')\n"
                     b"            with self.assertRaisesRegex(ValueError, 'Help baseline archive differs'):\n"
                     b"                help_contract_source.validate_historical_source(sandbox, path, expected)\n\n")
    _require(result.count(second_marker) == 1, 'XLSX boundary checker test insertion point differs')
    return result.replace(second_marker, second_method + second_marker, 1)


def restore_boundary_checker(root, current, expected_sha256):
    _require(expected_sha256 == BOUNDARY_BASELINE_SHA256,
             'XLSX boundary checker execution pin differs')
    if _digest(current) != BOUNDARY_CURRENT_SHA256:
        import ssis_historical_source_bridge
        try:
            current = ssis_historical_source_bridge.restore_boundary_test_transition(
                root, current, expected_sha256)
        except ValueError:
            _require(False, 'Current XLSX boundary checker differs from its exact Help projection')
    _require(_digest(current) == BOUNDARY_CURRENT_SHA256,
             'Current XLSX boundary checker differs from its exact Help projection')
    result = subprocess.run(['git', 'show', BOUNDARY_BASELINE_COMMIT + ':' + BOUNDARY_TEST],
                            cwd=root, capture_output=True, timeout=30, check=True)
    original = result.stdout
    _require(_digest(original) == BOUNDARY_BASELINE_SHA256,
             'XLSX boundary checker baseline differs from its fixed execution pin')
    _require(_boundary_projection(original) == current,
             'XLSX boundary checker differs outside the exact Help projection')
    return original


def _xlsx_metadata_test_projection(original):
    result = original
    replacements = (
        (b'import xlsx_metadata as metadata\n',
         b'import xlsx_metadata as metadata\nimport xlsx_sst_budget\nimport help_contract_source\n'),
        (b"        expected_test = xlsx_sst_budget.project_cell_test(expected_test)\n",
         b"        expected_test = xlsx_sst_budget.project_cell_test(expected_test)\n"
         b"        expected_test = xlsx_sst_budget.project_help_cell_test(expected_test)\n"),
    )
    for before, after in replacements:
        _require(result.count(before) == 1, 'XLSX metadata checker transition anchor differs')
        result = result.replace(before, after, 1)
    marker = b'    def test_clr_package_overlay_preserves_sql_dll_and_csv_provenance(self):\n'
    methods = (b"    def test_help_documentation_transition_reverses_only_the_two_bound_files(self):\n"
               b"        current = {path: help_contract_source.validate_historical_source(\n"
               b"                       ROOT, path, xlsx_sst_budget.XLSX_HELP_SOURCE_SHA256[path])\n"
               b"                   for path in metadata.HELP_DOCUMENTATION_PATHS}\n"
               b"        restored = metadata.restore_help_documentation_transition(ROOT, current)\n"
               b"        for path in metadata.HELP_DOCUMENTATION_PATHS:\n"
               b"            expected = xlsx_sst_budget.XLSX_HELP_SOURCE_SHA256[path]\n"
               b"            original = help_contract_source.validate_historical_source(ROOT, path, expected)\n"
               b"            self.assertEqual(help_contract_source.validate_current_source(ROOT, path),\n"
               b"                             (ROOT / path).read_bytes())\n"
               b"            self.assertEqual(restored[path], original)\n"
               b"        changed = dict(current)\n"
               b"        path = metadata.HELP_DOCUMENTATION_PATHS[0]\n"
               b"        changed[path] += b'\\nUnapproved content.\\n'\n"
               b"        with self.assertRaisesRegex(ValueError, 'snapshot differs'):\n"
               b"            metadata.restore_help_documentation_transition(ROOT, changed)\n\n"
               b"    def test_boundary_checker_help_transition_keeps_the_old_sst_pin(self):\n"
               b"        path = help_contract_source.BOUNDARY_TEST\n"
               b"        record = xlsx_sst_budget.read_record(ROOT)\n"
               b"        current = (ROOT / path).read_bytes()\n"
               b"        restored = help_contract_source.restore_boundary_checker(\n"
               b"            ROOT, current, record['current_source_sha256'][path])\n"
               b"        self.assertEqual(hashlib.sha256(restored).hexdigest(),\n"
               b"                         help_contract_source.BOUNDARY_BASELINE_SHA256)\n"
               b"        with self.assertRaisesRegex(ValueError, 'exact Help projection'):\n"
               b"            help_contract_source.restore_boundary_checker(\n"
               b"                ROOT, current + b'\\n# unrelated checker change\\n',\n"
               b"                record['current_source_sha256'][path])\n\n")
    _require(result.count(marker) == 1, 'XLSX metadata checker test insertion point differs')
    return result.replace(marker, methods + marker, 1)


def restore_xlsx_metadata_test(root, current, expected_sha256):
    _require(expected_sha256 == XLSX_METADATA_BASELINE_SHA256
             and _digest(current) == XLSX_METADATA_CURRENT_SHA256,
             'XLSX metadata checker execution/current pin differs')
    result = subprocess.run(['git', 'show', BASELINE_COMMIT + ':' + XLSX_METADATA_TEST],
                            cwd=root, capture_output=True, timeout=30, check=True)
    original = result.stdout
    _require(_digest(original) == XLSX_METADATA_BASELINE_SHA256
             and _xlsx_metadata_test_projection(original) == current,
             'XLSX metadata checker differs outside the exact Help projection')
    return original


def _raw_caller_test_projection(original):
    result = original
    replacements = (
        (b'import xlsx_sst_budget\n', b'import xlsx_sst_budget\nimport help_contract_source\n'),
        (b"        current = hashlib.sha256((root / path).read_bytes()).hexdigest().upper()\n"
         b"        expected = by_path.get(relative, {}).get('current_sha256', digest)\n",
         b"        if relative in help_contract_source.source_paths(root):\n"
         b"            help_contract_source.validate_historical_source(root, relative, digest)\n"
         b"            continue\n"
         b"        current_bytes = (root / path).read_bytes()\n"
         b"        if relative == xlsx_sst_budget.CELL_TEST:\n"
         b"            current_bytes = xlsx_sst_budget.restore_help_cell_test(root, current_bytes)\n"
         b"        current = hashlib.sha256(current_bytes).hexdigest().upper()\n"
         b"        expected = by_path.get(relative, {}).get('current_sha256', digest)\n"),
        (b"        current = hashlib.sha256((root / path).read_bytes()).hexdigest().upper()\n"
         b"        if current != digest.upper():\n",
         b"        if relative in help_contract_source.source_paths(root):\n"
         b"            help_contract_source.validate_historical_source(root, relative, digest)\n"
         b"            continue\n"
         b"        current = hashlib.sha256((root / path).read_bytes()).hexdigest().upper()\n"
         b"        if current != digest.upper():\n"),
    )
    for before, after in replacements:
        _require(result.count(before) == 1,
                 'XLSX raw-caller checker transition anchor differs')
        result = result.replace(before, after, 1)
    return result


def restore_raw_caller_checker(root, current, expected_sha256):
    _require(expected_sha256 == RAW_CALLER_BASELINE_SHA256
             and _digest(current) == RAW_CALLER_CURRENT_SHA256,
             'XLSX raw-caller checker execution/current pin differs')
    result = subprocess.run(['git', 'show', BASELINE_COMMIT + ':' + RAW_CALLER_TEST],
                            cwd=root, capture_output=True, timeout=30, check=True)
    original = result.stdout
    _require(_digest(original) == RAW_CALLER_BASELINE_SHA256
             and _raw_caller_test_projection(original) == current,
             'XLSX raw-caller checker differs outside exact Help dispatches')
    return original


def _zip_framework_test_projection(original):
    result = original
    replacements = (
        (b'import xlsx_sst_budget\n', b'import xlsx_sst_budget\nimport help_contract_source\n'),
        (b"        source = (xlsx_sst_budget.validate_historical_source(root, path, item['sha256'])\n"
         b"                  if path in xlsx_sst_budget.HISTORICAL else (root / path).read_bytes())\n",
         b"        if path in xlsx_sst_budget.HISTORICAL:\n"
         b"            source = xlsx_sst_budget.validate_historical_source(root, path, item['sha256'])\n"
         b"        elif path in help_contract_source.source_paths(root):\n"
         b"            source = help_contract_source.validate_historical_source(root, path, item['sha256'])\n"
         b"        else:\n"
         b"            source = (root / path).read_bytes()\n"),
    )
    for before, after in replacements:
        _require(result.count(before) == 1,
                 'XLSX ZIP-framework checker transition anchor differs')
        result = result.replace(before, after, 1)
    return result


def restore_zip_framework_checker(root, current, expected_sha256):
    _require(expected_sha256 == ZIP_FRAMEWORK_BASELINE_SHA256
             and _digest(current) == ZIP_FRAMEWORK_CURRENT_SHA256,
             'XLSX ZIP-framework checker execution/current pin differs')
    result = subprocess.run(['git', 'show', BASELINE_COMMIT + ':' + ZIP_FRAMEWORK_TEST],
                            cwd=root, capture_output=True, timeout=30, check=True)
    original = result.stdout
    _require(_digest(original) == ZIP_FRAMEWORK_BASELINE_SHA256
             and _zip_framework_test_projection(original) == current,
             'XLSX ZIP-framework checker differs outside exact Help dispatch')
    return original
