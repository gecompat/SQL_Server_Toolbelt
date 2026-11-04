"""Gegenproben verhindern Aufwertung alter oder unvollständiger Abnahmen."""
import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'Scripts/Release'))
import validate_ssis_current_build as validator


class CurrentBuildTests(unittest.TestCase):
    def setUp(self):
        self.report = json.loads((validator.ROOT / validator.REPORT).read_text(encoding='utf-8'))

    def test_bound_report(self):
        validator.validate(self.report)

    def rejected(self, mutate):
        value = copy.deepcopy(self.report)
        mutate(value)
        with self.assertRaises(ValueError):
            validator.validate(value, check_files=False)

    def test_old_api_not_current(self):
        self.rejected(lambda d: d.update(api_parameters=38))

    def test_missing_type_case(self):
        self.rejected(lambda d: d['procedure_boundaries'].remove('decimal(38,18)'))

    def test_no_cleanup_no_pass(self):
        self.rejected(lambda d: d['cases'][0].update(cleanup_audit='not executed'))

    def test_failed_coordinator_no_pass(self):
        self.rejected(lambda d: d['cases'][0].update(result='FAILED_CLEANED'))

    def test_gui_reuse_is_not_new_execution(self):
        self.rejected(lambda d: d['unexecuted_claims'].update(fresh_current_build_ssms=True))

    def test_tls_reuse_is_not_new_execution(self):
        self.rejected(lambda d: d['unexecuted_claims'].update(fresh_current_build_authenticated_tls=True))

    def test_preserve_historical_scope(self):
        self.rejected(lambda d: d['reused_evidence'][0].update(original_scope_preserved=False))

    def test_required_security(self):
        self.rejected(lambda d: d['gates'].update(independent_security='not executed'))

    def test_keep_rejected_attempt(self):
        self.rejected(lambda d: d['attempt_history'].update(rejected_before_sql=0))

    def test_duplicate_context(self):
        self.rejected(lambda d: d['cases'].__setitem__(1, d['cases'][0]))

    def test_wrong_count(self):
        self.rejected(lambda d: d.update(assertions=d['assertions'] + 1))

    def test_source_drift(self):
        value = copy.deepcopy(self.report)
        value['source_sha256'][validator.MODULE + 'Clr/ProcedureDefinition.cs'] = '0' * 64
        with self.assertRaises(ValueError):
            validator.validate(value)


if __name__ == '__main__':
    unittest.main()
