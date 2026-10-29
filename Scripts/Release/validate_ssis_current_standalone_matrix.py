"""Validate the added Windows CL contexts for the unchanged current T-SQL installer."""
from __future__ import annotations

import json
from pathlib import Path
import re

from new_ssis_current_package import ROOT, MODULE, NAME, require, sha
from new_ssis_standalone_tsql import read_regular_bounded, MAX_PACKAGE_BYTES
import new_ssis_current_standalone_tsql as current_installer


RUNTIME = Path('Releases/1.0.0/ssis-current-standalone-runtime-qualification.json')
RUNTIME_SHA256 = '9BB8FF8B2B87C98377BDAE877869D57D56D810EF8C3F8FE0B509360977D6A28E'
MATRIX_REPORT = Path('Releases/1.0.0/ssis-current-standalone-installer-matrix.json')
NEW_CASES = {
    ('2022', 150, 'local'), ('2022', 150, 'central'),
    ('2022', 160, 'local'), ('2022', 160, 'central'),
    ('2025', 150, 'local'), ('2025', 150, 'central'),
    ('2025', 160, 'local'), ('2025', 160, 'central'),
}
BASE_TARGETS = {('2019', 150), ('2025', 170)}
NEW_TARGETS = (('2022', 150), ('2022', 160), ('2025', 150), ('2025', 160))
INPUT_PATHS = frozenset({
    'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1',
    'Modules/toolbelt.tsql.ssis-debug/Contracts/Api.json',
    'Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-Current-Install-Windows.zip',
    'Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-Current-Install-Windows.zip.sha256',
    'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/components-v2-flatfile.dtsx',
    'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/components-v2-rowcount.dtsx',
    'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/synthetic-8.dtsx',
    'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.InstallPackage.20261029.json',
    'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CurrentCases.ps1',
    'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1',
    'Releases/1.0.0/ssis-current-standalone-installer.json',
    'Releases/1.0.0/SSIS-INSTALL-TSQL-CURRENT.sql',
    'Tests/CI/LabQualifiedContract.ps1',
    'Tests/CI/run-csv-memory-lab.ps1',
    'Tests/CI/run-lab-local.ps1',
    'Tests/Release/Invoke-CurrentStandaloneTsqlInstallerMatrixLab.ps1',
    'Tests/Release/Invoke-StablePackageLab.ps1',
    'Tests/Release/Prepare-CurrentStandaloneTsqlInstallerMatrixRunset.ps1',
})
ARTIFACT_BINDING_PATHS = frozenset({
    'Tests/Release/Invoke-CurrentStandaloneTsqlInstallerMatrixLab.ps1',
    'Tests/Release/Prepare-CurrentStandaloneTsqlInstallerMatrixRunset.ps1',
    'Tests/Release/Invoke-CurrentStandaloneTsqlInstallerLab.ps1',
    'Tests/Release/Prepare-CurrentStandaloneTsqlInstallerRunset.ps1',
    'Tests/Release/Invoke-StandaloneTsqlInstallerLab.ps1',
    'Tests/Release/Prepare-StandaloneTsqlInstallerRunset.ps1',
    'Tests/Release/Invoke-StablePackageLab.ps1',
    'Tests/CI/LabQualifiedContract.ps1',
    'Tests/CI/run-lab-local.ps1',
    'Tests/CI/run-csv-memory-lab.ps1',
    'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1',
    'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CurrentCases.ps1',
    'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1',
})
INSTALLER = Path('Releases/1.0.0/SSIS-INSTALL-TSQL-CURRENT.sql')
PROVENANCE = Path('Releases/1.0.0/ssis-current-standalone-installer.json')
PACKAGE = Path(MODULE + 'InstallPackages/' + NAME + '.zip')


def _target_key(target):
    require(isinstance(target, dict) and target.get('platform') == 'windows' and
            isinstance(target.get('sql_server'), str) and
            type(target.get('compatibility_level')) is int,
            'target identity')
    return target['sql_server'], target['compatibility_level']


def _additional_cases(cases):
    require(isinstance(cases, list) and len(cases) == 8, 'eight additional cases')
    keys = []
    for case in cases:
        require(isinstance(case, dict) and set(case) == {
            'platform', 'sql_server', 'compatibility_level', 'deployment_mode',
            'result', 'assertions', 'fresh_and_repeat', 'final_independent_audit'},
            'additional case fields')
        require(case.get('platform') == 'windows' and case.get('sql_server') in ('2022', '2025') and
                type(case.get('compatibility_level')) is int and
                case.get('deployment_mode') in ('local', 'central') and case.get('result') == 'PASS' and
                case.get('assertions') == 206 and case.get('fresh_and_repeat') is True and
                case.get('final_independent_audit') == 'PASS', 'additional case result')
        keys.append((case['sql_server'], case['compatibility_level'], case['deployment_mode']))
    require(len(set(keys)) == 8 and set(keys) == NEW_CASES, 'exact additional Windows CL matrix')
    return keys


def _additional_targets(targets):
    require(isinstance(targets, list) and len(targets) == 4, 'four additional targets')
    keys = []
    for target in targets:
        require(isinstance(target, dict) and set(target) == {
            'platform', 'sql_server', 'compatibility_level', 'result', 'final_independent_audit'},
            'additional target fields')
        require(target.get('platform') == 'windows' and target.get('result') == 'PASS' and
                target.get('final_independent_audit') == 'PASS', 'additional target audit')
        keys.append(_target_key(target))
    require(len(set(keys)) == 4 and set(keys) == set(NEW_TARGETS), 'exact four additional targets')
    return keys


def _validate_paths(root, pins, expected_paths):
    require(isinstance(pins, list) and len(pins) == len(expected_paths), 'execution input pin count')
    found = {}
    for pin in pins:
        require(isinstance(pin, dict) and set(pin) == {'path', 'sha256'}, 'execution input pin shape')
        path = pin['path']
        relative = Path(path)
        require(isinstance(path, str) and not relative.is_absolute() and '..' not in relative.parts and
                path in expected_paths and re.fullmatch(r'[0-9A-Fa-f]{64}', str(pin['sha256'])),
                'execution input pin boundary')
        require(path not in found, 'duplicate execution input pin')
        data = read_regular_bounded(root / relative, MAX_PACKAGE_BYTES)
        require(sha(data).lower() == pin['sha256'].lower(), 'execution input pin drift')
        found[path] = pin['sha256'].lower()
    require(set(found) == set(expected_paths), 'execution input pin closure')
    return found


def validate_record(record, original_runtime, original_runtime_sha256, root=ROOT):
    """Validate only composed offline evidence; it never connects to SQL Server."""
    require(isinstance(record, dict) and record.get('schema_version') == '1.0' and
            record.get('date') == '2026-10-29' and
            record.get('kind') == 'ssis_current_standalone_tsql_cl_matrix_qualification' and
            record.get('profile') == 'ssis-debug-current' and record.get('result') == 'PASS' and
            record.get('publication_authorized') is False,
            'current standalone matrix record identity')
    require(record.get('installer') == original_runtime.get('installer') and
            record.get('provenance') == original_runtime.get('provenance') and
            record.get('qualified_package') == original_runtime.get('qualified_package'),
            'unchanged installer, provenance, and package bindings')
    require(record.get('original_runtime_qualification') == {
        'path': RUNTIME.as_posix(), 'sha256': original_runtime_sha256},
        'unchanged original runtime qualification binding')

    old_targets = original_runtime.get('scope', {}).get('targets')
    require(isinstance(old_targets, list) and
            {_target_key(target) for target in old_targets} == BASE_TARGETS and len(old_targets) == 2,
            'original runtime target scope')
    new_targets = _additional_targets(record.get('additional_targets'))
    new_cases = _additional_cases(record.get('additional_cases'))
    expected_target_order = old_targets + [
        {'platform': 'windows', 'sql_server': version, 'compatibility_level': level}
        for version, level in NEW_TARGETS
    ]
    scope = record.get('scope')
    require(isinstance(scope, dict) and set(scope) == {
        'targets', 'deployment_modes', 'installed_mode_contexts'}, 'matrix scope fields')
    require(scope.get('targets') == expected_target_order and
            scope.get('deployment_modes') == ['local', 'central'] and
            scope.get('installed_mode_contexts') == 12,
            'complete twelve-context scope')

    execution = record.get('execution')
    old_execution = original_runtime.get('execution', {})
    require(isinstance(execution, dict) and set(execution) == {
        'driver', 'preparer', 'source_commit', 'mode_bindings', 'new_target_invocations',
        'new_independent_audits', 'original_successful_contexts_repeated', 'command_method'},
        'matrix execution fields')
    require(execution.get('driver') == 'Tests/Release/Invoke-CurrentStandaloneTsqlInstallerMatrixLab.ps1' and
            execution.get('preparer') == 'Tests/Release/Prepare-CurrentStandaloneTsqlInstallerMatrixRunset.ps1' and
            re.fullmatch(r'(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{40})', str(execution.get('source_commit', ''))) and
            execution.get('mode_bindings') == old_execution.get('mode_bindings') and
            execution.get('new_target_invocations') == 4 and execution.get('new_independent_audits') == 4 and
            execution.get('original_successful_contexts_repeated') == 0 and
            execution.get('command_method') == old_execution.get('command_method'),
            'matrix execution provenance')
    require(set(new_targets) == set(NEW_TARGETS) and
            { (version, level) for version, level, _mode in new_cases } == set(new_targets),
            'target and mode case composition')

    audit = record.get('final_audit')
    require(isinstance(audit, dict) and set(audit) == {
        'case_audits', 'owned_database_names_absent', 'trust_states_restored',
        'configuration_baselines_restored', 'input_pins_unchanged'}, 'matrix final audit fields')
    require(audit.get('case_audits') == 4 and audit.get('owned_database_names_absent') == 8 and
            audit.get('trust_states_restored') == 12 and
            audit.get('configuration_baselines_restored') is True and
            audit.get('input_pins_unchanged') is True, 'four independent cleanup audits')

    artifact_bindings = record.get('artifact_bindings')
    require(isinstance(artifact_bindings, dict) and set(artifact_bindings) == ARTIFACT_BINDING_PATHS,
            'direct harness artifact binding fields')
    _validate_paths(root, [{'path': path, 'sha256': digest} for path, digest in artifact_bindings.items()],
                    ARTIFACT_BINDING_PATHS)
    _validate_paths(root, record.get('execution_input_pins'), INPUT_PATHS)

    require(record.get('functional_transport') == original_runtime.get('functional_transport') and
            record.get('assembly_trust') == original_runtime.get('assembly_trust'),
            'unchanged transport and trust boundaries')
    not_qualified = record.get('not_qualified')
    require(isinstance(not_qualified, list) and
            'Full engine/CL matrix for standalone installer' not in not_qualified and
            any('Windows-authentication' in item and 'SSMS GUI' in item for item in not_qualified) and
            any('Authenticated TLS' in item for item in not_qualified) and
            any('SSISDB' in item or 'DTSX' in item for item in not_qualified) and
            any('trust-registration opt-in' in item for item in not_qualified) and
            'Publication' in not_qualified, 'remaining qualification limits')
    return True


def validate(root=ROOT):
    runtime_bytes = read_regular_bounded(root / RUNTIME, 1024 * 1024)
    require(sha(runtime_bytes).lower() == RUNTIME_SHA256.lower(), 'original runtime report bytes')
    original_runtime = current_installer.validate_runtime(root)
    record_bytes = read_regular_bounded(root / MATRIX_REPORT, 1024 * 1024)
    record = json.loads(record_bytes.decode('utf-8'))
    validate_record(record, original_runtime, sha(runtime_bytes), root)
    print('SSIS_CURRENT_STANDALONE_MATRIX_VALIDATION_PASS; exact unchanged installer; 12 Windows CL/mode contexts; no SQL')
    return record


if __name__ == '__main__':
    validate()
