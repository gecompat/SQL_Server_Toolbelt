"""Prüft aktuelle SSIS-Abnahme und getrennte historische Anwendbarkeit."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODULE = 'Modules/toolbelt.tsql.ssis-debug/'
REPORT = MODULE + 'Tests/Qualification/Current.Build.20261104.json'
SECURITY = MODULE + 'Tests/Qualification/Security.CurrentBuild.20261104.json'
CONTEXTS = {('2019', 150, 'local'), ('2022', 160, 'central'), ('2025', 170, 'local')}
GATES = {'current_functional', 'procedure_boundaries', 'current_api', 'caller_rights',
         'lifecycle', 'offline_framework', 'independent_security', 'evidence_applicability'}
BOUNDARIES = {'int', 'bigint', 'decimal(38,18)', 'help_first', 'debug_messages',
              'keep_null_zero_one', 'result_table_no_resultset', 'caller_transaction',
              'implicit_transactions', 'xact_abort', 'conversion_failure',
              'materialization_failure_atomic', 'write_failure_atomic', 'temp_cleanup'}


def require(value, message):
    if not value:
        raise ValueError(message)


def sha(path):
    resolved = (ROOT / path).resolve()
    require(resolved.is_relative_to(ROOT.resolve()) and resolved.is_file(), 'evidence path')
    require(resolved.stat().st_size <= 16 * 1024 * 1024, 'evidence size')
    return hashlib.sha256(resolved.read_bytes()).hexdigest()


def validate(report=None, *, check_files=True):
    if report is None:
        report = json.loads((ROOT / REPORT).read_text(encoding='utf-8'))
    require(report.get('kind') == 'ssis_current_build_qualification' and report.get('result') == 'PASS' and
            report.get('publication_authorized') is False and report.get('functional_scope_complete') is True,
            'current build identity')
    require(report.get('api_parameters') == 40 and type(report['api_parameters']) is int, 'current API')
    require(set(report.get('gates', {})) == GATES and set(report['gates'].values()) == {'PASS'}, 'required gates')
    cases = report.get('cases', [])
    require(len(cases) == 3 and {(c.get('sql_version'), c.get('compatibility_level'), c.get('deployment_mode')) for c in cases} == CONTEXTS,
            'representative current contexts')
    for case in cases:
        require(case.get('result') == 'PASS_FOR_COMPOSED_SCOPE' and case.get('cleanup_audit') == 'PASS' and
                case.get('functional_result') == 'PASS_FOR_DECLARED_SCOPE' and case.get('procedure_coordinator_result') == 'PASS_CLEANED' and
                case.get('functional_coordinator_result') == ('FAILED_CLEANED' if case['sql_version'] == '2019' else 'PASS_CLEANED') and
                type(case.get('assertions')) is int and case['assertions'] > 1000 and
                case.get('authenticated_tls') == 'not executed' and case.get('real_lowpriv') is True,
                'native current result and audit')
    require(set(report.get('procedure_boundaries', [])) == BOUNDARIES, 'procedure boundary coverage')
    require(report.get('assertions') == sum(c['assertions'] for c in cases), 'native assertion total')
    require(report.get('offline_framework') == {'profile': 'Full', 'bounded_children': 27, 'result': 'PASS'}, 'framework qualification')
    require(report.get('risk_mapping') == 'unchanged_default_branches_plus_current_12_context_package_matrix', 'matrix applicability')
    require(report.get('unexecuted_claims') == {
        'fresh_current_build_ssms': False, 'fresh_current_build_authenticated_tls': False,
        'unattended_authentication': False, 'lab_uninterrupted_windows_tls_creation': False,
        'os_vm_coordinator_loss': False, 'full_ssis_runtime_parity': False,
    }, 'no invented execution claims')
    reuse = report.get('reused_evidence', [])
    require(len(reuse) >= 8 and len({e.get('path') for e in reuse}) == len(reuse), 'unique reused evidence')
    require(all(e.get('applicability') in ('unchanged_mechanism_with_current_bridge', 'unchanged_exact_artifact',
                                          'unchanged_core_with_current_regression') and e.get('original_scope_preserved') is True for e in reuse),
            'explicit historical applicability')
    history = report.get('attempt_history', {})
    require(type(history.get('failed_cleaned')) is int and type(history.get('rejected_before_sql')) is int and
            history['failed_cleaned'] >= 0 and history['rejected_before_sql'] >= 1 and
            type(history.get('pass_cleaned')) is int and history['pass_cleaned'] >= 6 and
            history.get('independent_audits') == history['failed_cleaned'] + history['pass_cleaned'],
            'retained failure history and audit count')
    sources = report.get('source_sha256', {})
    require(MODULE + 'Clr/ProcedureDefinition.cs' in sources and MODULE + 'Contracts/Api.json' in sources and
            MODULE + 'Tests/Runtime/Invoke-ProcedureBoundaryCases.ps1' in sources and len(sources) >= 40,
            'current source closure')
    if check_files:
        for path, digest in sources.items():
            require(sha(path) == digest, 'changed current source: ' + path)
        for evidence in reuse:
            require(sha(evidence['path']) == evidence.get('sha256'), 'changed historical evidence')
            for path, digest in evidence.get('unchanged_mechanism_sources', {}).items():
                require(sha(path) == digest, 'changed historical mechanism: ' + path)
        require(sha(SECURITY) == report.get('security_report_sha256'), 'security evidence binding')
        security = json.loads((ROOT / SECURITY).read_text(encoding='utf-8'))
        require(security.get('result') == 'PASS' and security.get('independent_reviewer') is True and
                security.get('review_kind') == 'static_security_contract' and security.get('runtime_executed_by_reviewer') is False and
                security.get('open_findings') == [] and security.get('original_pass_withdrawn') is True and
                any(f.get('id') == 'F-01' and f.get('status') == 'fixed' for f in security.get('resolved_findings', [])),
                'independent static security scope and preserved finding')
        for path, digest in security.get('reviewed_product_sha256', {}).items():
            require(sha(path) == digest, 'changed security-reviewed source')
        require(len(security.get('reviewed_product_sha256', {})) >= 10, 'security source closure')
    return report


if __name__ == '__main__':
    validate()
    print('SSIS_CURRENT_BUILD_QUALIFICATION_PASS; original execution and applicability separated')
