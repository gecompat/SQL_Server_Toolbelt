"""Prüft die gebundene Evidenz für XLSX-Blatt- und Shared-String-Grenzen."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'Releases/1.0.0/xlsx-boundary-qualification.json'


class XlsxBoundaryEvidenceMixin:
    def _xlsx_boundary_report(self):
        return json.loads(REPORT.read_bytes())

    def test_xlsx_boundary_evidence_status_and_scope_are_exact(self):
        report = self._xlsx_boundary_report()
        self.assertEqual(report['schema_version'], 'toolbelt-xlsx-boundary-qualification/v1')
        self.assertIs(report['publication_authorized'], False)
        self.assertIs(report['product_sql_changed'], False)
        self.assertIs(report['product_clr_changed'], False)
        self.assertIs(report['manifest_or_package_changed'], False)
        self.assertIs(report['authenticated_tls_qualified'], False)
        self.assertEqual(report['module_status'], 'partially validated')
        self.assertEqual(report['release_status'], 'unreleased')
        self.assertEqual(report['sheet_count']['result'], 'PASS_FOR_FIXED_WORKSHEET_COUNT_BOUNDARY')
        self.assertEqual(report['shared_strings']['result'], 'BLOCKED_BUDGET')
        encoded = REPORT.read_text(encoding='utf-8').lower()
        for forbidden in ('sha512', '.runtime', 'testumgebung', 'connectionstring', 'trust_server_certificate'):
            self.assertNotIn(forbidden, encoded)
        self.assertIs(report['totals']['trust_hashes_unique_counted'], False)

    def test_xlsx_boundary_sheet_counts_and_fixed_oracles_are_consistent(self):
        report = self._xlsx_boundary_report()
        sheet = report['sheet_count']
        self.assertEqual(sheet['matrix']['case_count'], 12)
        self.assertEqual(sheet['matrix']['routes'], 24)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level'])
                          for c in sheet['matrix']['cases']}, {
            (platform, version, cl)
            for platform in ('linux', 'windows')
            for version, levels in (('2019', (150,)), ('2022', (150, 160)),
                                    ('2025', (150, 160, 170)))
            for cl in levels
        })
        self.assertEqual(sheet['workbook']['positive_sheets'], 32)
        self.assertEqual(sheet['workbook']['overflow_sheets'], 33)
        self.assertEqual(sheet['oracle']['positive_rows_per_route'], 32)
        self.assertEqual(sheet['oracle']['expected_positive_rows'], 24 * 32)
        self.assertEqual(sheet['oracle']['overflow_error_number'], 51520)
        self.assertEqual(sheet['oracle']['overflow_error_message'], 'TBX_XLSX_SHEET_LIMIT')
        self.assertEqual(sheet['oracle']['overflow_rows_before_error'], 0)
        self.assertEqual(sheet['audits']['immediate'], 12)
        self.assertEqual(sheet['audits']['selected_final'], 6)
        self.assertEqual(sheet['databases']['own_created_and_dropped'], 24)

    def test_xlsx_boundary_sst_blocker_does_not_claim_unrun_overflow(self):
        report = self._xlsx_boundary_report()
        sst = report['shared_strings']
        self.assertEqual(sst['default_limit'], 50000)
        self.assertEqual(sst['positive_fixture_references'], [0, 24999, 49999])
        self.assertEqual(sst['failed_positive_attempts'], 2)
        self.assertEqual(sst['failed_diagnostic'], 'TBX_XLSX_BUDGET_EXCEEDED')
        self.assertEqual(sst['sql_error_number'], 51520)
        self.assertEqual(sst['rows_observed_before_failure'], 0)
        self.assertEqual(sst['overflow_fixture_count'], 50001)
        self.assertEqual(sst['overflow_attempts'], 0)
        self.assertEqual(sst['central_route_attempts'], 0)
        self.assertEqual(sst['successful_routes'], 0)
        totals = report['totals']
        self.assertEqual(totals['native_sql_process_invocations'], 34)
        self.assertEqual(totals['sheet_matrix_cases'], 12)
        self.assertEqual(totals['sheet_positive_routes'], 24)
        self.assertEqual(totals['sheet_expected_positive_rows'], 768)
        self.assertEqual(totals['sheet_zero_row_rejections'], 24)
        self.assertEqual(totals['sst_failed_local_attempts'], 2)
        self.assertEqual(totals['sst_overflow_calls'], 0)
        self.assertEqual(totals['own_database_entries'], 26)
        self.assertEqual(totals['trust_removal_events'], 28)
        self.assertIs(totals['trust_hashes_unique_counted'], False)

    def test_xlsx_boundary_public_source_pins_match_current_files(self):
        report = self._xlsx_boundary_report()
        expected_counts = report['source_pin_counts']
        self.assertEqual(expected_counts, {'sheet_count': 129, 'shared_strings': 132})
        for scope, pins in report['source_sha256'].items():
            self.assertEqual(len(pins), expected_counts[scope])
            for relative, expected in pins.items():
                self.assertFalse(relative.startswith(('/', '\\')))
                self.assertNotIn('..', Path(relative).parts)
                self.assertNotIn('.runtime', relative.lower())
                self.assertEqual(len(expected), 64)
                data = (ROOT / relative).read_bytes()
                if relative == report['source_eol_projection']['path']:
                    projection = report['source_eol_projection']
                    normalized = data.replace(b'\r\n', b'\n')
                    self.assertNotIn(b'\r', normalized)
                    self.assertEqual(normalized.count(b'\n'), projection['lf_line_count'])
                    self.assertEqual(hashlib.sha256(normalized).hexdigest(),
                                     projection['canonical_lf_sha256'])
                    rebuilt = normalized.replace(b'\n', b'\r\n')
                    self.assertEqual(hashlib.sha256(rebuilt).hexdigest(), expected)
                    self.assertIn(data, (normalized, rebuilt), relative)
                    actual = expected
                else:
                    actual = hashlib.sha256(data).hexdigest()
                self.assertEqual(actual, expected, relative)

    def test_xlsx_boundary_eol_projection_accepts_only_exact_line_endings(self):
        report = self._xlsx_boundary_report()
        projection = report['source_eol_projection']
        self.assertEqual(projection['path'],
                         'Modules/toolbelt.file.xlsx-memory/Tests/XLSX_CONTRACT_TEST_MATRIX.md')
        raw = (ROOT / projection['path']).read_bytes()
        normalized = raw.replace(b'\r\n', b'\n')
        rebuilt = normalized.replace(b'\n', b'\r\n')
        self.assertIn(raw, (normalized, rebuilt))
        self.assertEqual(hashlib.sha256(rebuilt).hexdigest(),
                         projection['executed_raw_sha256'])
        modified = normalized.replace(b'32', b'33', 1)
        self.assertNotEqual(hashlib.sha256(modified).hexdigest(),
                            projection['canonical_lf_sha256'])
