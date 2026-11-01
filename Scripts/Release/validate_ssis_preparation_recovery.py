"""Vorbereitung, harte Clientabbrüche und abgegrenzter Windows-Installernachweis.

Keine SQL-/Prozessausführung. Originale Nachweise bleiben unverändert; nur die
aggregierten Orakel und tatsächlich ausgeführten Methoden werden anerkannt.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

MODULE = 'Modules/toolbelt.tsql.ssis-debug/'
AREA = MODULE + 'Tests/WindowsClientRecovery/'
RECORD = MODULE + 'Tests/Qualification/PreparationRecovery.Windows.20261101.json'
WINDOWS_RECORD = MODULE + 'Tests/Qualification/InstallerClient.Windows.20261101.json'
COMMON = AREA + 'LabClientCommon.ps1'
NATIVE_COMMON = 'D9E69E7DA52195E9F3DB91746C473A48AA4A079A18A9A78B9A9E40B5D3152B0D'
METHODS = {
    AREA + 'Invoke-Preparation.ps1': '0CD454A9C38FBC73B8E09D494FC4CE4F29CB35469BA5F8197F79946F0088AFBC',
    AREA + 'Invoke-TransportRecovery.ps1': '88964A64E0FA6DC0C897CD6253B30018838BE1365A872A4F4F4A2365F60C0A4F',
    AREA + 'RecoveryFixture.ps1': '6F6C950127197989B31454DCE91583B3759436CCBAF7713EA40987DE96CF6C4B',
    AREA + 'qualify_host_interruption.py': '2C4F5CD59E343717DC01FD2A3F8ABA9F6DDABF3882EBD4F77E13DAB4DD83BC80',
}
MODES = ('model', 'bundle', 'iteration-bundle', 'scope-bundle', 'pipeline-bundle')
LIMITS = [
    'Full Windows-authenticated public PowerShell installer and SSMS copy/paste path require their separate client record',
    'OS/VM shutdown or loss of the surviving test coordinator',
    'Uninterrupted public Windows TLS Lab creation',
    'Unbounded production capacity or full SSIS runtime parity',
]


def require(condition, label):
    if not condition:
        raise ValueError('SSIS_PREPARATION_RECOVERY_' + label)


def digest(data):
    return hashlib.sha256(data).hexdigest().upper()


def common_native_bytes(current, integration):
    require(integration == {
        'path': COMMON, 'native_sha256': NATIVE_COMMON,
        'current_sha256': digest(current),
        'kind': 'suppress_unused_windows_remove_outputs',
        'original_native_coordinator_authentication': 'SQL',
        'covered_sql_branch_changed': False,
    }, 'COMMON_INTEGRATION')
    require(current.count(b'[void]$b.Remove') == 2, 'COMMON_EXACT_CHANGE')
    native = current.replace(b'[void]$b.Remove', b'$b.Remove')
    require(digest(native) == NATIVE_COMMON, 'COMMON_NATIVE_BINDING')
    return native


def validate_report(report, read):
    require(report['contract'] == 'ssis-preparation-hard-recovery/1' and
            report['date'] == '2026-11-01' and report['result'] == 'PASS' and
            report['publication_authorized'] is False, 'HEADER')
    require(report['scope'] == 'public preparation SQL and bounded hard export-host / SQL-client interruption; surviving independent coordinator', 'SCOPE')
    require(report['not_qualified'] == LIMITS, 'LIMITS')
    original_common = common_native_bytes(read(COMMON), report['source_integration'])
    for section, size in (('preparation', 5), ('sql_transport', 13), ('host', 11)):
        pins = report[section]['source_sha256']
        require(type(pins) is dict and len(pins) == size, 'INPUT_CLOSURE')
        for path, expected in pins.items():
            require(isinstance(path, str) and not Path(path).is_absolute() and
                    '\\' not in path and '..' not in Path(path).parts and
                    path.startswith(('Modules/', 'Tests/CI/')), 'INPUT_PATH')
            require(isinstance(expected, str) and len(expected) == 64 and
                    all(c in '0123456789abcdefABCDEF' for c in expected), 'PIN_FORMAT')
            actual = original_common if path == COMMON else read(path)
            require(digest(actual) == expected.upper(), 'SOURCE_BINDING')
            if path in METHODS:
                require(expected.upper() == METHODS[path], 'NATIVE_METHOD')
        require(set(METHODS).intersection(pins), 'METHOD_MISSING')
    prep = report['preparation']
    require(prep['source_sha256'][AREA + 'Invoke-Preparation.ps1'] == METHODS[AREA + 'Invoke-Preparation.ps1'], 'PREPARATION_METHOD')
    require(prep['lab_source_commit'] == 'e64b52c424fb61b946d8f1029fa4c4c4db2145b6' and
            prep['assertions'] == 54 and type(prep['assertions']) is int and
            prep['original_false_pending_reproduced'] is True and
            prep['original_characterization_no_mutation'] is True, 'PREPARATION_PROOF')
    require(len(prep['cases']) == 3, 'PREPARATION_MATRIX')
    for case, (version, patch) in zip(prep['cases'], (('2019', 'CU32'), ('2022', 'CU26'), ('2025', 'CU8'))):
        require(case == {'sql_version': version, 'patch': patch, 'platform': 'Windows',
                        'result': 'PASS_CLEANED', 'assertions': 18, 'public_guest_dispatches': 3,
                        'windows_guest_authentication': True, 'fresh_independent_audit': 'PASS',
                        'database_removed': True, 'configuration_restored': True, 'trust_unchanged': True}, 'PREPARATION_CASE')
        require(all(case[k] is True for k in ('windows_guest_authentication', 'database_removed',
                                              'configuration_restored', 'trust_unchanged')), 'PREPARATION_BOOLEAN')
    host = report['host']
    require(host['contract'] == 'ssis-host-hard-interruption/1' and host['result'] == 'PASS' and
            host['platform'] == 'Windows' and host['case_count'] == 10 and host['assertions'] == 95 and
            host['child_processes_started'] == 25 and
            host['host_sha256'] == 'e6510ebeb06f755799257ab3ed70af8324349bd7faad8b498e394f3178d1de5c', 'HOST_HEADER')
    expected = [(mode, kind) for mode in MODES for kind in ('process-termination', 'pipe-disconnection')]
    require(len(host['cases']) == len(expected), 'HOST_MATRIX')
    for case, (mode, kind) in zip(host['cases'], expected):
        require(case['mode'] == mode and case['interruption'] == kind and case['result'] == 'PASS' and
                type(case['interrupted_exit_code']) is int and
                case['interrupted_exit_code'] == (1 if kind == 'process-termination' else 0) and
                case['assertions'] == (10 if kind == 'process-termination' else 9) and
                case['partial_json_rejected'] is True and case['fresh_output_identical'] is True and
                case['input_unchanged'] is True, 'HOST_CASE')
    sql = report['sql_transport']
    require(sql['source_sha256'][AREA + 'Invoke-TransportRecovery.ps1'] == METHODS[AREA + 'Invoke-TransportRecovery.ps1'] and
            sql['source_sha256'][AREA + 'RecoveryFixture.ps1'] == METHODS[AREA + 'RecoveryFixture.ps1'], 'SQL_METHOD')
    require(sql['platform'] == 'Windows' and sql['sql_version'] == '2025' and sql['patch'] == 'CU8' and
            sql['authentication'] == 'Functional SQL' and sql['result'] == 'PASS_CLEANED' and
            sql['assertions'] == 18 and sql['fresh_independent_audit'] == 'PASS' and
            all(sql[k] is True for k in ('database_removed', 'configuration_restored', 'trust_restored', 'other_consumers_unchanged')) and
            sql['previous_failed_cleaned_attempts'] == 3 and sql['previous_independent_audits'] == 'PASS' and
            sql['sql_server_or_vm_killed'] is False, 'SQL_PROOF')
    require(sql['cases'] == [
        {'name': 'blocked-current-debugscript', 'processKilled': True, 'serverSessionGone': True,
         'freshResultsIdentical': True, 'result': 'PASS'},
        {'name': 'current-api-open-caller-transaction', 'processKilled': True, 'result': 'PASS',
         'callerChangesRolledBack': True, 'freshResultsIdentical': True, 'serverSessionGone': True},
    ], 'SQL_CASES')
    require(all(value is True for case in sql['cases'] for key, value in case.items()
                if key not in ('name', 'result')), 'SQL_CASE_BOOLEAN')
    require('own Sch-M lock' in sql['fault_injection'], 'OBSERVED_FAULT_INJECTION')


def validate(root):
    root = Path(root)
    report = json.loads((root / RECORD).read_text(encoding='utf-8'))
    validate_report(report, lambda path: (root / path).read_bytes())
    import validate_ssis_linux_export
    validate_ssis_linux_export.validate(root)
    validate_windows_report(json.loads((root / WINDOWS_RECORD).read_text(encoding='utf-8')),
                            lambda path: (root / path).read_bytes(), report)
    return report


def validate_windows_report(report, read, recovery):
    require(report['contract'] == 'ssis-public-windows-installer/1' and
            report['date'] == '2026-11-01' and report['result'] == 'PASS_FOR_DECLARED_SCOPE' and
            report['publication_authorized'] is False, 'WINDOWS_HEADER')
    require(report['scope'] == 'Windows-authenticated public preparation and first/repeat Install-Local plus current CLI/API DebugScript baseline; visible SSMS transport excluded', 'WINDOWS_SCOPE')
    require((report['platform'], report['sql_version'], report['patch'], report['compatibility_level'], report['assertions']) ==
            ('Windows', '2025', 'CU8', 150, 10), 'WINDOWS_TARGET')
    expected = set(recovery['sql_transport']['source_sha256']) | {
        AREA + 'Invoke-WindowsClient.ps1', AREA + 'ClientGuiHook.ps1',
        MODULE + 'Examples/Installation/Install-Local.ps1',
        MODULE + 'Deployment/Add-TrustedAssembly.sql',
        'Modules/toolbelt.tsql.script-parser/Deployment/Add-TrustedAssembly.sql'}
    require(set(report['source_sha256']) == expected, 'WINDOWS_CLOSURE')
    for path, pin in report['source_sha256'].items():
        require(digest(read(path)) == pin, 'WINDOWS_SOURCE_BINDING')
    for path, pin in {
        AREA + 'Invoke-WindowsClient.ps1': '15D323FFEAC488C835CFA46751721AF4D9A78FD61981DCB46C332FED973B9F36',
        AREA + 'ClientGuiHook.ps1': 'FB44D94E6EF2781941B5B03ABEA8980E5F4A1C9F52C690B44B5C81F6548933D7',
    }.items():
        require(report['source_sha256'][path] == pin, 'WINDOWS_NATIVE_METHOD')
    require(report['authentication'] == {'client': 'NTLM', 'existing_sysadmin': True, 'new_permissions': False} and
            report['authentication']['existing_sysadmin'] is True and report['authentication']['new_permissions'] is False, 'WINDOWS_AUTHENTICATION')
    require(report['installer'] == {'public_preparation': True, 'first_and_repeat_passes': 2,
            'public_entry_point': True, 'repeat_trust_unchanged': True, 'explicit_utf8_input': True} and
            all(value is True for key, value in report['installer'].items() if key != 'first_and_repeat_passes'), 'WINDOWS_INSTALLER')
    require(report['client_baseline'] == {'api_parameters': 38, 'complete_executable_debugscript': True,
            'executed_debugscript': True, 'target_rows': 2} and
            all(report['client_baseline'][k] is True for k in ('complete_executable_debugscript', 'executed_debugscript')), 'WINDOWS_CLIENT_BASELINE')
    require(report['coordinator'] == {'state': 'FAILED_CLEANED', 'failure': 'SSIS_CLIENT_GUI_NOT_COMPLETED_IN_BOUND',
            'ssms_qualified': False, 'gui_queries_executed': 0, 'observed_gui_failure': 'PRELOGIN_HANDSHAKE_TIMEOUT',
            'own_ssms_closed': True} and report['coordinator']['ssms_qualified'] is False and
            report['coordinator']['own_ssms_closed'] is True and type(report['coordinator']['gui_queries_executed']) is int, 'WINDOWS_FAILED_GUI_PRESERVED')
    require(report['transport'] == {'purpose': 'Functional', 'encrypted': True, 'explicit_contract_trust_value': True,
            'authenticated_tls_claimed': False} and report['transport']['encrypted'] is True and
            report['transport']['explicit_contract_trust_value'] is True and report['transport']['authenticated_tls_claimed'] is False, 'WINDOWS_TRANSPORT')
    require(report['cleanup']['fresh_windows_audit'] == 'PASS' and set(report['cleanup']) == {
        'database_removed', 'configuration_restored', 'trust_restored', 'other_consumers_unchanged', 'fresh_windows_audit'} and
        all(value is True for key, value in report['cleanup'].items() if key != 'fresh_windows_audit'), 'WINDOWS_CLEANUP')
    require(report['lab_support'] == {
        'core_source_commit': 'e64b52c424fb61b946d8f1029fa4c4c4db2145b6',
        'support_source_commit': '6c6c6c3c80f8eda1c8302a1775d4b3fb164c9238',
        'launcher_sha256': '2172C5950EE4745813FDC2BD59DFE79D39BB671D048F0BB37CCF1D73B33BA84B',
        'worker_canonical_sha256': 'C5148A8DB2C05265F52C937E27B26C492409FF3B918642BBBD33471A43FB1823',
        'worker_text_binding': 'UTF8/LF', 'native_bytes_equal_committed_blob': True,
        'credential_returned': False, 'automatic_retry': False} and
        report['lab_support']['native_bytes_equal_committed_blob'] is True and
        report['lab_support']['credential_returned'] is False and report['lab_support']['automatic_retry'] is False, 'WINDOWS_LAB_SUPPORT')
    require(report['history'] == {'earlier_coordinator_failures_preserved': True,
        'cancelled_attempt_preserved': True, 'earlier_final_audits': 'PASS'} and
        report['history']['earlier_coordinator_failures_preserved'] is True and
        report['history']['cancelled_attempt_preserved'] is True, 'WINDOWS_HISTORY')
    require(report['not_qualified'] == [
        'Complete Windows-authenticated SSMS login and full GUI Scripttransport',
        'Other Windows SQL versions or Linux SQL CLR for this installer/client path',
        'OS/VM shutdown or loss of the surviving coordinator',
        'Uninterrupted public Windows TLS Lab creation',
        'Unbounded production capacity or full SSIS runtime parity'], 'WINDOWS_LIMITS')


if __name__ == '__main__':
    result = validate(Path(__file__).resolve().parents[2])
    print('SSIS_PREPARATION_RECOVERY_PASS; 54 preparation +95 host +18 SQL +10 Windows installer/client assertions; SSMS GUI not qualified; no native execution')
