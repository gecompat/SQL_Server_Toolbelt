"""Fresh execution evidence supplements, rather than relabels, historical SSIS proof."""
import hashlib
import json
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[2]
MODULE = 'Modules/toolbelt.tsql.ssis-debug/'
REPORT = MODULE + 'Tests/Qualification/Fresh.Build.20261104.json'
BUILD = MODULE + 'Tests/Qualification/Current.Build.20261104.json'
ARCHIVE = MODULE + 'InstallPackages/SSIS-Debug-Qualified-Install-Windows.zip'
CONTEXTS = {(version, level, mode) for version, levels in
            [('2019', [150]), ('2022', [150, 160]), ('2025', [150, 160, 170])]
            for level in levels for mode in ('local', 'central')}
PATCHES = {'2019': 'CU32', '2022': 'CU26', '2025': 'CU8'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def validate(report=None, *, check_files=True):
    if report is None:
        report = json.loads((ROOT / REPORT).read_text(encoding='utf-8'))
    require(report.get('kind') == 'ssis_fresh_current_build_qualification' and
            report.get('result') == 'PASS' and report.get('publication_authorized') is False,
            'fresh qualification identity')
    require(report.get('current_api_parameters') == 40 and
            re.fullmatch('[0-9a-f]{64}', report.get('qualified_assembly_sha256', '')) is not None,
            'current build identity')
    require(report.get('historical_failures_preserved') is True, 'failure history retained')
    matrix = report.get('zip_matrix', {})
    require(matrix.get('result') == 'PASS' and matrix.get('fresh_contexts') == 12 and
            matrix.get('reused_contexts') == 0, 'twelve fresh ZIP contexts')
    package = matrix.get('package', {})
    require(package.get('path') == ARCHIVE and all(re.fullmatch('[0-9a-f]{64}', package.get(k, ''))
            for k in ('sha256', 'manifest_sha256')), 'exact current ZIP identity')
    cases = matrix.get('cases', [])
    require(len(cases) == 12, 'matrix cardinality')
    seen = set()
    for case in cases:
        key = (case.get('sql_version'), case.get('compatibility_level'), case.get('deployment_mode'))
        require(key in CONTEXTS and key not in seen and case.get('platform') == 'windows' and
                case.get('patch') == PATCHES[key[0]], 'exact Windows/CL/mode context')
        seen.add(key)
        require(case.get('coordinator_result') == 'PASS_CLEANED' and case.get('cleanup_audit') == 'PASS' and
                case.get('fresh_execution') is True and case.get('package_assertions') == 8 and
                case.get('procedure_assertions') == 222 and case.get('functional_assertions', 0) >= 1028,
                'complete current ZIP case and independent audit')
    require(seen == CONTEXTS, 'all supported contexts')
    ssms = report.get('ssms', {})
    require(ssms.get('platform') == 'windows' and ssms.get('sql_version') == '2025' and
            ssms.get('patch') == 'CU8' and ssms.get('compatibility_level') == 150 and
            ssms.get('deployment_mode') == 'local', 'declared fresh SSMS target scope')
    require(ssms.get('test_purpose') == 'Functional' and ssms.get('authentication') == 'Windows' and
            isinstance(ssms.get('trust_server_certificate'), bool), 'explicit SSMS login and transport scope')
    require(ssms.get('coordinator_result') == 'PASS_CLEANED' and ssms.get('cleanup_audit') == 'PASS' and
            ssms.get('fresh_execution') is True and ssms.get('receipt_phase') == 2 and
            ssms.get('result_rows') == 2, 'fresh complete SSMS coordinator and receipt')
    for key in ('gui_visible', 'windows_authentication', 'exact_lab_target', 'encrypted',
                'complete_unicode_copy', 'copy_hash_verified_before_execution', 'sqlcmd_mode',
                'native_error_stopped_later_batch', 'full_script_and_receipt_executed'):
        require(ssms.get(key) is True, 'SSMS ' + key)
    require(ssms.get('authentication_automated') is False, 'authentication assistance explicit')
    tls = report.get('authenticated_tls', {})
    require(tls.get('test_purpose') == 'AuthenticatedTls' and tls.get('authentication') == 'SQL',
            'explicit TLS SQL-consumer authentication')
    require(tls.get('result') == 'PASS' and tls.get('fresh_execution') is True and
            tls.get('supervisor_result') == 'PASS' and tls.get('sql_cleanup_audit') == 'PASS' and
            tls.get('lab_cleanup_audit') == 'PASS' and tls.get('own_vm_removed') is True,
            'fresh TLS total case and independent audits')
    require(tls.get('encrypt') is True and tls.get('trust_server_certificate') is False and
            tls.get('signed_v2') is True and tls.get('same_export_bytes') is True and
            tls.get('fresh_reader_before_each_open') is True and tls.get('fallback') is False and
            tls.get('strict_client_stacks') == 2, 'authenticated TLS boundary')
    require(tls.get('sql_build') == '17.0.1000.7' and tls.get('compatibility_level') == 170 and
            tls.get('deployment_modes') == ['local', 'central'] and tls.get('sql_assertions', 0) >= 412,
            'declared fresh TLS native scope')
    method = tls.get('lab_method', {})
    require(method.get('repository') == 'gecompat/SQL_Server_Lab' and
            method.get('path') == 'Tests/Integration/Invoke-ToolbeltSsisCurrentTlsAcceptance.ps1' and
            re.fullmatch('[0-9a-f]{40}', method.get('commit', '')) and
            re.fullmatch('[0-9a-f]{64}', method.get('sha256', '')), 'Lab owns native TLS orchestration')
    for section in (matrix, ssms, tls):
        require(section.get('assembly_sha256') == report['qualified_assembly_sha256'], 'same current DLL in every scope')
    sources = report.get('source_sha256', {})
    for path in (MODULE + 'Tests/Runtime/Invoke-FreshBuildLab.ps1',
                 MODULE + 'Tests/WindowsClientRecovery/Invoke-CurrentBuildSsms.ps1',
                 MODULE + 'Tests/WindowsClientRecovery/CurrentBuildArtifacts.ps1'):
        require(path in sources, 'fresh execution method closure')
    if check_files:
        current = json.loads((ROOT / BUILD).read_text(encoding='utf-8'))
        require(current['result'] == 'PASS' and current['qualified_assembly_sha256'] == report['qualified_assembly_sha256'],
                'existing current build binding')
        archive = ROOT / ARCHIVE
        require(sha(archive.read_bytes()) == package['sha256'], 'current ZIP bytes')
        with zipfile.ZipFile(archive) as z:
            prefix = 'SSIS-Debug-Qualified-Install-Windows/'
            require(sha(z.read(prefix + 'PACKAGE-MANIFEST.json')) == package['manifest_sha256'], 'current ZIP manifest')
            require(sha(z.read(prefix + MODULE + 'Artifacts/Toolbelt.Tsql.SsisDebug.dll')) == report['qualified_assembly_sha256'],
                    'ZIP current DLL')
        for path, digest in sources.items():
            resolved = (ROOT / path).resolve()
            require(resolved.is_relative_to(ROOT) and sha(resolved.read_bytes()) == digest, 'fresh execution source drift')
    return report


if __name__ == '__main__':
    validate()
    print('SSIS_FRESH_BUILD_QUALIFICATION_PASS; fresh ZIP12, SSMS total receipt, strict TLS total case')
