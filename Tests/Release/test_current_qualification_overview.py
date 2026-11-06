"""Gegenproben gegen veraltete und überhöhte zentrale Qualifikationsaussagen."""
from pathlib import Path
import copy
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import current_qualification_overview as overview


class CurrentQualificationOverviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ssis, cls.parser = overview.records()
        cls.text = (ROOT / overview.PAGE).read_text(encoding='utf-8')

    def test_current_page_matches_source_checked_records(self):
        overview.validate(self.text, self.ssis, self.parser)

    def test_missing_and_duplicate_current_section_are_rejected(self):
        for text in (self.text.replace(overview.HEADING, '## Historischer Snapshot', 1),
                     self.text + '\n' + overview.HEADING):
            with self.subTest(text=text[-50:]), self.assertRaises(ValueError):
                overview.validate(text, self.ssis, self.parser)

    def test_historical_incoming_section_links_keep_their_targets(self):
        for target in ('was-vor-veröffentlichung-offen-bleibt',
                       'aktueller-restgate-status-und-voraussetzungen'):
            self.assertEqual(self.text.count('<a id="' + target + '"></a>'), 1)

    def test_wrong_assertion_total_is_rejected(self):
        with self.assertRaises(ValueError):
            overview.validate(self.text.replace('15204 Assertions', '15205 Assertions', 1),
                              self.ssis, self.parser)

    def test_combining_windows_login_and_strict_tls_is_rejected(self):
        with self.assertRaises(ValueError):
            overview.validate(self.text.replace('SQL-Anmeldung; AuthenticatedTls',
                                                'Windows-Anmeldung; AuthenticatedTls', 1),
                              self.ssis, self.parser)

    def test_failed_ssms_coordinator_is_not_promoted(self):
        bad = copy.deepcopy(self.ssis)
        bad['ssms']['coordinator_result'] = 'FAILED_CLEANED'
        with self.assertRaises(ValueError):
            overview.render(bad, self.parser)

    def test_missing_fresh_audit_is_not_promoted(self):
        bad = copy.deepcopy(self.ssis)
        bad['zip_matrix']['cases'][0]['cleanup_audit'] = 'NOT_EXECUTED'
        with self.assertRaises(ValueError):
            overview.render(bad, self.parser)

    def test_authentication_automation_claim_is_rejected(self):
        bad = copy.deepcopy(self.ssis)
        bad['ssms']['authentication_automated'] = True
        with self.assertRaises(ValueError):
            overview.render(bad, self.parser)

    def test_tls_fallback_cannot_become_strict_qualification(self):
        bad = copy.deepcopy(self.ssis)
        bad['authenticated_tls']['fallback'] = True
        with self.assertRaises(ValueError):
            overview.render(bad, self.parser)

    def test_parser_full_native_coverage_claim_is_rejected(self):
        bad = copy.deepcopy(self.parser)
        bad['fullNativeBoundaryCoverage'] = True
        with self.assertRaises(ValueError):
            overview.render(self.ssis, bad)

    def test_parser_unexecuted_branches_cannot_disappear(self):
        bad = copy.deepcopy(self.parser)
        bad['publicBoundaryCallsNotExecuted'] = []
        with self.assertRaises(ValueError):
            overview.render(self.ssis, bad)

    def test_parser_combined_evidence_is_not_a_general_pass(self):
        bad = copy.deepcopy(self.parser)
        bad['result'] = 'PASS'
        with self.assertRaises(ValueError):
            overview.render(self.ssis, bad)

    def test_parser_source_drift_is_rejected(self):
        bad = copy.deepcopy(self.parser)
        path = next(iter(bad['productSources']))
        bad['productSources'][path] = '0' * 64
        with self.assertRaises(ValueError):
            overview.render(self.ssis, bad)


if __name__ == '__main__':
    unittest.main()
