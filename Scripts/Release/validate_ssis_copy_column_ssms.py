"""Current-archive visible SSMS scope; never promotes historical or partial runs."""
import hashlib
import json
from pathlib import Path
import re
import validate_ssis_copy_column_delivery as delivery

ROOT = Path(__file__).resolve().parents[2]
REPORT = delivery.MODULE + 'Tests/Qualification/Ssms.CopyColumn.20261115.json'
METHODS = tuple([
    "Modules/toolbelt.core.result-table/Deployment/Deploy.sql",
    "Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql",
    "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql",
    "Modules/toolbelt.tsql.script-parser/Deployment/Add-TrustedAssembly.sql",
    "Modules/toolbelt.tsql.ssis-debug/Contracts/DependencyPins.json",
    "Modules/toolbelt.tsql.ssis-debug/Deployment/Add-TrustedAssembly.sql",
    "Modules/toolbelt.tsql.ssis-debug/Examples/Installation/Install-Local.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Examples/Installation/PrepareServer.sql",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/synthetic-8.dtsx",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.Delivery.20261115.json",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.V1.20261114.json",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.Build.20261104.json",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.Build.Native.20261104.json",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.Functional.20261031.json",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/AutonomousSsmsHook.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/ClientGuiHook.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/CopyColumnArtifacts.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-CopyColumnSsms.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-CurrentBuildSsms.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-SsmsSqlcmd.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-TransportRecovery.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-WindowsClient.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/LabClientCommon.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/New-SsmsExecutionEnvelope.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/New-SsmsSqlcmdEnvelope.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/RecoveryFixture.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/SsmsGuiHook.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/SsmsSqlcmdHook.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/VisibleSsmsHook.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Write-SsmsPreflightObservation.ps1",
    "Tests/CI/LabQualifiedContract.ps1",
    "Tests/CI/run-lab-local.ps1"
])


def require(value, label):
    if not value:
        raise ValueError('SSIS_COPY_SSMS_' + label)


def exact(value, expected, label):
    # JSON distinguishes booleans from integer counters and preserves list order.
    require(json.dumps(value, sort_keys=True) == json.dumps(expected, sort_keys=True), label)


def source_paths():
    return set(METHODS) | delivery.source_paths() | {delivery.REPORT}


def validate(record=None, *, check_files=True):
    r = record if record is not None else json.loads((ROOT / REPORT).read_bytes())
    require(set(r) == {'kind', 'date', 'result', 'scope', 'target', 'artifacts', 'case', 'audit',
                       'assistance', 'reuse', 'budget', 'source_sha256'}, 'ROOT_KEYS')
    exact([r['kind'], r['date'], r['result']],
          ['ssis_copy_column_ssms_native_qualification', '2026-11-15', 'PASS_FOR_DECLARED_SCOPE'], 'IDENTITY')
    exact(r['scope'], {'current_archive_windows_ssms': True, 'full_module_qualification': False,
          'fresh_full_functional_zip_matrix': False, 'fresh_authenticated_tls': False,
          'copy_column_gui_fixture': False, 'publication_authorized': False}, 'SCOPE')
    exact(r['target'], {'platform': 'Windows', 'sql_version': '2025', 'patch': 'CU8',
          'compatibility_level': 150, 'deployment_mode': 'local', 'test_purpose': 'Functional',
          'authentication': 'Windows', 'auth_scheme': 'NTLM', 'encrypt': True,
          'trust_server_certificate': True}, 'TARGET')
    exact(r['case'], {'coordinator_result': 'PASS_CLEANED', 'checks': 17, 'completed_cases': 1,
          'public_installer_passes': 2, 'visible_gui_executions': 4, 'same_owned_ssms_instance': True,
          'exact_lab_target': True, 'windows_preflight': True, 'complete_unicode_grid_copy': True,
          'copied_utf16_lf_units': 184441, 'copy_hash_verified_before_execution': True,
          'sqlcmd_mode': True, 'native_expected_error': 51001, 'later_batch_stopped': True,
          'negative_receipt_phase_unchanged': 1, 'executed_editor_text_verified': True,
          'full_script_and_receipt_executed': True, 'receipt_phase': 2, 'result_rows': 2,
          'unexpected_execution_errors': 0, 'own_ssms_closed': True}, 'TOTAL_CASE')
    exact(r['audit'], {'result': 'PASS', 'fresh_independent_windows_process': True,
          'binds_exact_final_journal': True, 'owned_databases_removed': 1,
          'configuration_restored': True, 'trust_restored': True,
          'other_consumers_unchanged': True}, 'CLEANUP')
    exact(r['assistance'], {'authentication_automated': False,
          'manual_steps': ['Windows authentication', 'per-query grid copy options'],
          'gui_executions_by_agent': 4}, 'ASSISTANCE')
    exact(r['reuse'], {'existing_copy_delta': True, 'existing_portable_host': True,
          'existing_archive_delivery': True, 'green_matrices_reexecuted': False,
          'historical_records_unchanged': True}, 'REUSE')
    exact(r['budget'], {'native_target_audit_calls': 2, 'owned_databases': 1,
          'visible_gui_executions': 4, 'maximum_minutes': 45, 'native_failures': 0,
          'retries': 0, 'closed': True, 'previous_waves_preserved': True}, 'BUDGET')
    q = json.loads((ROOT / delivery.REPORT).read_bytes())
    artifacts = r['artifacts']
    exact(artifacts, {'qualified_source_record': delivery.QUALIFICATION,
          'qualified_source_record_sha256': hashlib.sha256((ROOT / delivery.QUALIFICATION).read_bytes()).hexdigest(),
          'delivery_record': delivery.REPORT,
          'delivery_record_sha256': hashlib.sha256((ROOT / delivery.REPORT).read_bytes()).hexdigest(),
          'assembly_sha256': q['package']['provider_sha256'],
          'archive_sha256': q['package']['sha256']}, 'CURRENT_ARTIFACTS')
    sources = r['source_sha256']
    require(set(sources) == source_paths(), 'SOURCE_CLOSURE')
    require(all(isinstance(v, str) and re.fullmatch('[0-9a-f]{64}', v) for v in sources.values()), 'HASH_FORMAT')
    if check_files:
        delivery.validate()
        for path, digest in sources.items():
            require(hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, 'SOURCE_DRIFT')
    return r


if __name__ == '__main__':
    validate()
    print('SSIS_COPY_COLUMN_SSMS_SCOPE_PASS; visible Windows total case17/fresh audit; no full-module claim')
