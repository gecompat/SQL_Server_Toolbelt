"""SQL-freie Prüfung des getrennten zielgebundenen SSMS-Nachweises."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

MODULE = 'Modules/toolbelt.tsql.ssis-debug/'
AREA = MODULE + 'Tests/WindowsClientRecovery/'
RECORD = MODULE + 'Tests/Qualification/SsmsClient.Windows.20261101.json'
SQLCMD_RECORD = MODULE + 'Tests/Qualification/SsmsClient.Complete.Windows.20261103.json'
# Bind the complete static plan closure plus the copy verifier to the native run.
SQLCMD_SOURCE_MAP_SHA256 = '83F8B66C547560E1486FB02762CB647979EE7F4C778A5680AC0828035C7F9FF3'
METHODS = {
    AREA + 'Invoke-SsmsQualification.ps1': 'E8D7791939C1C1C814FE4F341BC7737FD61D306418C595EC5C0BEE22F6A40BFE',
    AREA + 'SsmsGuiHook.ps1': '96733D52B24895B378112AD1601FCD86D55C7AEECE7BA5D81FFA14A920AF2824',
}
COPY = AREA + 'Test-SsmsScriptCopy.ps1'
COPY_SHA256 = '82294DC172114D6BE4C58C228EF244D02C1791112A998447002E8355E221C80A'
LIMITS = [
    'Green overall SSMS coordinator and final phase-2 receipt',
    'Other Windows SQL versions or Linux SQL CLR for this GUI path',
    'OS/VM shutdown or loss of the surviving coordinator',
    'Uninterrupted public Windows TLS Lab creation',
    'Unbounded production capacity or full SSIS runtime parity',
]


def require(condition, label):
    if not condition:
        raise ValueError('SSIS_SSMS_GUI_' + label)


def digest(data):
    return hashlib.sha256(data).hexdigest().upper()


def exact(value, expected, label):
    require(value == expected and all(type(value[k]) is type(v) for k, v in expected.items()), label)


def validate_report(report, read, windows):
    require(report['contract'] == 'ssis-observed-windows-ssms/1' and report['date'] == '2026-11-01'
            and report['result'] == 'PASS_FOR_DECLARED_SCOPE' and report['publication_authorized'] is False, 'HEADER')
    require(report['scope'] == 'observed target-bound Windows SSMS login, current API and hash-identical whole-cell DebugScript execution with separate cleanup audit; final coordinator receipt excluded', 'SCOPE')
    require((report['platform'], report['sql_version'], report['patch'], report['compatibility_level'], report['native_assertions']) ==
            ('Windows', '2025', 'CU8', 150, 11) and type(report['compatibility_level']) is int
            and type(report['native_assertions']) is int, 'TARGET')
    require(report['not_qualified'] == LIMITS, 'LIMITS')
    pins = report['source_sha256']
    require(type(pins) is dict and set(pins) == set(windows['source_sha256']) | set(METHODS)
            and len(pins) == 20, 'CLOSURE')
    for path, pin in pins.items():
        require(pin == digest(read(path)), 'SOURCE_BINDING')
        require(pin == (METHODS[path] if path in METHODS else windows['source_sha256'][path]), 'NATIVE_METHOD')
    exact(report['coordinator'], {'state': 'FAILED_CLEANED',
          'failure': 'SSIS_CLIENT_GUI_NOT_COMPLETED_IN_BOUND', 'native_cases': 0,
          'phase2_receipt_executed': False, 'overall_pass_claimed': False,
          'reserved_windows_audit_on_failure': True}, 'FAILED_COORDINATOR')
    exact(report['target_preflight'], {'before_database_creation': True, 'instance_process_start_witness_matched': True,
          'windows_authentication': 'NTLM', 'encrypted': True, 'application_is_ssms': True,
          'same_owned_instance_reused': True, 'visible_query_pass': True}, 'PREFLIGHT')
    exact(report['installer'], {'qualified_inputs_reused': True, 'public_first_and_repeat_passes': 2,
          'repeat_trust_unchanged': True}, 'INSTALLER')
    exact(report['gui'], {'current_api_parameters': 38, 'complete_debugscript_cell': True,
          'whole_cell_copied': True, 'saved_utf16_lf_hash_matched': True, 'unicode_preserved': True,
          'copied_script_executed': True, 'target_rows': 2, 'messages_errors': 0,
          'operator_assistance': True, 'separate_visual_evidence': True,
          'own_instance_closed': True}, 'GUI')
    exact(report['result_options'], {'scope': 'own-producer-query', 'non_xml_character_limit': 2000000,
          'retain_crlf': True, 'configured_before_generation': True}, 'RESULT_OPTIONS')
    exact(report['copy_check'], {'method': COPY, 'method_sha256': COPY_SHA256,
          'result': 'PASS', 'scope': 'saved-copy-only', 'before_execution': True}, 'COPY_CHECK')
    require(digest(read(COPY)) == COPY_SHA256, 'COPY_SOURCE')
    exact(report['transport'], {'purpose': 'Functional', 'encrypted': True,
          'explicit_contract_trust_value': True, 'authenticated_tls_claimed': False}, 'TRANSPORT')
    exact(report['cleanup'], {'database_removed': True, 'configuration_restored': True,
          'trust_restored': True, 'other_consumers_unchanged': True, 'fresh_windows_audit': 'PASS'}, 'CLEANUP')
    exact(report['lab_support'], {'core_source_commit': '6c6c6c3c80f8eda1c8302a1775d4b3fb164c9238',
          'support_source_commit': '6c6c6c3c80f8eda1c8302a1775d4b3fb164c9238',
          'native_raw_launcher_sha256': '53C27DCF7F91922C7086D32F15463A13B9DE480E38AA6C1D60EEEDF568AF4947',
          'committed_launcher_sha256': '2172C5950EE4745813FDC2BD59DFE79D39BB671D048F0BB37CCF1D73B33BA84B',
          'source_integration': 'exact CRLF to LF checkout normalization only',
          'credential_returned': False, 'automatic_retry': False}, 'LAB_SUPPORT')
    exact(report['history'], {'earlier_failed_gui_coordinators_preserved': True,
          'prior_partial_records_unchanged': True, 'prior_truncated_copy_preserved': True,
          'prior_safety_audit_not_promoted': True}, 'HISTORY')


def validate(root):
    import validate_ssis_preparation_recovery as previous
    root = Path(root)
    previous.validate(root)
    windows = json.loads((root / previous.WINDOWS_RECORD).read_text(encoding='utf-8'))
    report = json.loads((root / RECORD).read_text(encoding='utf-8'))
    validate_report(report, lambda path: (root / path).read_bytes(), windows)
    return report


def validate_sqlcmd_report(report, read):
    require(report['contract'] == 'ssis-native-windows-ssms-sqlcmd/1'
            and report['date'] == '2026-11-03' and report['result'] == 'PASS_CLEANED'
            and report['publication_authorized'] is False, 'SQLCMD_HEADER')
    require(report['toolbelt_source_commit'] == '2a1f33f910be636d9240f90d1406dbf118f120b4'
            and report['lab_source_commit'] == '6c6c6c3c80f8eda1c8302a1775d4b3fb164c9238', 'SQLCMD_BASE')
    pins = report['source_sha256']
    require(type(pins) is dict, 'SQLCMD_SOURCE_MAP')
    canonical = json.dumps(pins, sort_keys=True, separators=(',', ':')).encode('utf-8')
    require(digest(canonical) == SQLCMD_SOURCE_MAP_SHA256, 'SQLCMD_SOURCE_MAP')
    for path, pin in pins.items():
        require(digest(read(path)) == pin, 'SQLCMD_SOURCE_BINDING')
    exact(report['target'], {'platform': 'Windows', 'sql_version': '2025', 'patch': 'CU8',
          'compatibility_level': 150}, 'SQLCMD_TARGET')
    exact(report['coordinator'], {'native_cases': 1, 'native_assertions': 17,
          'phase2_receipt_confirmed': True}, 'SQLCMD_COORDINATOR')
    exact(report['preflight'], {'target_witness_matched': True, 'observed_result_bound_to_run': True,
          'before_database_creation': True, 'authentication': 'NTLM', 'same_owned_ssms_instance': True},
          'SQLCMD_PREFLIGHT')
    exact(report['installer_and_api'], {'public_installer_passes': 2, 'repeat_trust_unchanged': True,
          'current_api_parameters': 38}, 'SQLCMD_INSTALLER_AND_API')
    exact(report['sqlcmd_stop'], {'on_error': 'EXIT', 'expected_error': 51001, 'additional_errors': 0,
          'executed_text_matched': True, 'later_sentinel_not_executed': True, 'phase_after_error': 1},
          'SQLCMD_STOP')
    exact(report['ssms_execution'], {'whole_unicode_cell_copied': True, 'saved_utf16_lf_hash_matched': True,
          'executed_envelope_verified': True, 'target_rows': 2, 'unicode_receipt_visible': True,
          'messages_errors': 0, 'operator_connected': True, 'operator_set_grid_options': True}, 'SQLCMD_GUI')
    exact(report['cleanup'], {'database_absent': True, 'owned_ssms_closed': True, 'configuration_restored': True,
          'trust_restored': True, 'other_consumers_unchanged': True, 'fresh_windows_audit': 'PASS',
          'audit_bound_to_final_journal': True}, 'SQLCMD_CLEANUP')
    exact(report['bounds'], {'native_invocations': 2, 'owned_databases': 1, 'visible_query_executions': 4,
          'maximum_minutes': 45, 'completed_within_bound': True, 'automatic_retry': False}, 'SQLCMD_BOUNDS')
    exact(report['transport'], {'purpose': 'Functional', 'encrypted': True,
          'explicit_contract_trust_value': True}, 'SQLCMD_TRANSPORT')
    require(report['excluded'] == [
        'Unattended SSMS login',
        'Other SQL versions or platforms for this GUI path',
        'Authenticated TLS and uninterrupted public Windows TLS Lab creation',
        'OS or VM loss of the coordinator',
    ], 'SQLCMD_SCOPE')


def validate_sqlcmd(root):
    root = Path(root)
    report = json.loads((root / SQLCMD_RECORD).read_text(encoding='utf-8'))
    validate_sqlcmd_report(report, lambda path: (root / path).read_bytes())
    return report


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[2]
    validate(root)
    validate_sqlcmd(root)
    print('SSIS_VISIBLE_WINDOWS_SSMS_PASS; 11 native checks plus separate GUI evidence and fresh Windows audit; overall coordinator FAILED_CLEANED; no SQL execution')
    print('SSIS_NATIVE_WINDOWS_SSMS_SQLCMD_PASS; bound record for one cleaned case, 17 native checks and fresh Windows audit; no SQL execution')
