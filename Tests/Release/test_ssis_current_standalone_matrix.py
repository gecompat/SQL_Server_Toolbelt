"""Offline composition and boundary checks for the current standalone CL matrix."""
from copy import deepcopy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import new_ssis_current_standalone_tsql as current_installer
import new_ssis_standalone_tsql as renderer
import validate_ssis_current_standalone_matrix as matrix


class CurrentStandaloneMatrixTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime_bytes = renderer.read_regular_bounded(ROOT / matrix.RUNTIME, 1024 * 1024)
        cls.runtime = json.loads(cls.runtime_bytes.decode('utf-8'))
        cls.runtime_sha256 = current_installer.sha(cls.runtime_bytes)
        cls.record = cls.synthetic_record()

    @classmethod
    def synthetic_record(cls):
        original = cls.runtime
        bindings = {path: current_installer.sha(renderer.read_regular_bounded(ROOT / path, renderer.MAX_PACKAGE_BYTES))
                    for path in matrix.ARTIFACT_BINDING_PATHS}
        pins = {path: current_installer.sha(renderer.read_regular_bounded(ROOT / path, renderer.MAX_PACKAGE_BYTES))
                for path in matrix.INPUT_PATHS}
        base = [
            {'platform': 'windows', 'sql_server': '2019', 'compatibility_level': 150},
            {'platform': 'windows', 'sql_server': '2025', 'compatibility_level': 170},
        ]
        added_targets = [
            {'platform': 'windows', 'sql_server': version, 'compatibility_level': level,
             'result': 'PASS', 'final_independent_audit': 'PASS'}
            for version, level in matrix.NEW_TARGETS
        ]
        added_cases = [
            {'platform': 'windows', 'sql_server': version, 'compatibility_level': level,
             'deployment_mode': mode, 'result': 'PASS', 'assertions': 206,
             'fresh_and_repeat': True, 'final_independent_audit': 'PASS'}
            for version, level in matrix.NEW_TARGETS for mode in ('local', 'central')
        ]
        old_not_qualified = [item for item in original['not_qualified']
                             if item != 'Full engine/CL matrix for standalone installer']
        return {
            'schema_version': '1.0', 'date': '2026-10-29',
            'kind': 'ssis_current_standalone_tsql_cl_matrix_qualification',
            'profile': 'ssis-debug-current', 'result': 'PASS', 'publication_authorized': False,
            'installer': deepcopy(original['installer']),
            'provenance': deepcopy(original['provenance']),
            'qualified_package': deepcopy(original['qualified_package']),
            'original_runtime_qualification': {
                'path': matrix.RUNTIME.as_posix(), 'sha256': cls.runtime_sha256},
            'additional_targets': added_targets,
            'additional_cases': added_cases,
            'scope': {'targets': base + [
                {'platform': 'windows', 'sql_server': version, 'compatibility_level': level}
                for version, level in matrix.NEW_TARGETS],
                'deployment_modes': ['local', 'central'], 'installed_mode_contexts': 12},
            'execution': {
                'driver': 'Tests/Release/Invoke-CurrentStandaloneTsqlInstallerMatrixLab.ps1',
                'preparer': 'Tests/Release/Prepare-CurrentStandaloneTsqlInstallerMatrixRunset.ps1',
                'source_commit': 'abcdef12',
                'mode_bindings': deepcopy(original['execution']['mode_bindings']),
                'new_target_invocations': 4, 'new_independent_audits': 4,
                'original_successful_contexts_repeated': 0,
                'command_method': original['execution']['command_method']},
            'final_audit': {'case_audits': 4, 'owned_database_names_absent': 8,
                            'trust_states_restored': 12, 'configuration_baselines_restored': True,
                            'input_pins_unchanged': True},
            'artifact_bindings': bindings,
            'execution_input_pins': [{'path': path, 'sha256': digest} for path, digest in pins.items()],
            'functional_transport': deepcopy(original['functional_transport']),
            'assembly_trust': deepcopy(original['assembly_trust']),
            'not_qualified': old_not_qualified,
        }

    def test_composes_exact_additional_contexts_without_repeating_originals(self):
        self.assertTrue(matrix.validate_record(self.record, self.runtime, self.runtime_sha256))

    def test_rejects_duplicate_or_wrong_cl_case(self):
        for mutate in (
            lambda r: r['additional_cases'].__setitem__(1, deepcopy(r['additional_cases'][0])),
            lambda r: r['additional_cases'][0].update(compatibility_level=170),
        ):
            changed = deepcopy(self.record)
            mutate(changed)
            with self.assertRaisesRegex(ValueError, 'exact additional Windows CL matrix'):
                matrix.validate_record(changed, self.runtime, self.runtime_sha256)

    def test_rejects_wrong_original_binding_and_target_order(self):
        changed = deepcopy(self.record)
        changed['original_runtime_qualification']['sha256'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'unchanged original runtime'):
            matrix.validate_record(changed, self.runtime, self.runtime_sha256)
        changed = deepcopy(self.record)
        changed['scope']['targets'][2], changed['scope']['targets'][3] = (
            changed['scope']['targets'][3], changed['scope']['targets'][2])
        with self.assertRaisesRegex(ValueError, 'complete twelve-context scope'):
            matrix.validate_record(changed, self.runtime, self.runtime_sha256)

    def test_rejects_missing_audit_or_current_artifact_drift(self):
        changed = deepcopy(self.record)
        changed['final_audit']['input_pins_unchanged'] = False
        with self.assertRaisesRegex(ValueError, 'four independent cleanup audits'):
            matrix.validate_record(changed, self.runtime, self.runtime_sha256)
        changed = deepcopy(self.record)
        changed['artifact_bindings']['Tests/Release/Invoke-CurrentStandaloneTsqlInstallerMatrixLab.ps1'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'execution input pin drift'):
            matrix.validate_record(changed, self.runtime, self.runtime_sha256)


if __name__ == '__main__':
    unittest.main()
