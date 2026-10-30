"""Prüft die gebundene Evidenz für XLSX-Blatt- und Shared-String-Grenzen."""
from pathlib import Path
import hashlib
import json
import sys
import tempfile
import shutil
from unittest.mock import patch
import copy

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import xlsx_sst_budget
import caller_metadata
import help_contract_source
import ssis_historical_source_bridge
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

    def test_xlsx_boundary_public_source_pins_bind_exact_executed_sources(self):
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
                if relative == xlsx_sst_budget.WORKBOOK:
                    data = xlsx_sst_budget.validate_historical_source(ROOT, relative, expected)
                elif relative in help_contract_source.source_paths(ROOT):
                    data = help_contract_source.validate_historical_source(ROOT, relative, expected)
                elif relative in ssis_historical_source_bridge.source_paths():
                    data = ssis_historical_source_bridge.validate_historical_source(ROOT, relative, expected)
                else:
                    import parameter_help_transition
                    data = (parameter_help_transition.bound_source(ROOT, relative, expected)
                            if relative in parameter_help_transition.PATHS | parameter_help_transition.VERIFIER_PATHS
                            else (ROOT / relative).read_bytes())
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

    def test_xlsx_help_sources_keep_old_pins_with_exact_current_projection(self):
        for path, executed in xlsx_sst_budget.XLSX_HELP_SOURCE_SHA256.items():
            original = help_contract_source.validate_historical_source(ROOT, path, executed)
            current = help_contract_source.validate_current_source(ROOT, path)
            self.assertEqual(hashlib.sha256(original).hexdigest(), executed)
            self.assertTrue(current)
            caller_metadata.validate_source(ROOT, path, executed)
            with self.assertRaisesRegex(ValueError, 'Historical Help source pin differs'):
                caller_metadata.validate_source(ROOT, path, '0' * 64)

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

    def test_sst_correction_binds_current_candidate_and_immutable_prior_evidence(self):
        record = xlsx_sst_budget.validate_current(ROOT)
        self.assertEqual(record['candidate_dll_sha256'],
                         'f1f604492bc69d9787b0582493f4045ae7363c61723d9e166717442253bb5abd')
        self.assertEqual(record['budget'], {
            'maximum_milliseconds': 5000, 'minimum_milliseconds': 1,
            'precise_for_budgets_up_to_milliseconds': 32,
            'coarse_clock_role': 'advisory_inner_check_scheduling',
            'precise_materialization_and_final_acceptance': True,
            'hard_wallclock_guarantee': False,
        })
        self.assertEqual(record['historical_source_sha256'], xlsx_sst_budget.HISTORICAL)
        self.assertFalse(record['package_payload_changed'])
        self.assertFalse(record['publication_authorized'])

    def test_sst_correction_native_matrix_and_composed_framework_are_bounded(self):
        record = xlsx_sst_budget.read_record(ROOT)
        native = record['native']
        expected = {(p, v, cl) for p in ('windows', 'linux')
                    for v, levels in (('2019', (150,)), ('2022', (150, 160)),
                                      ('2025', (150, 160, 170))) for cl in levels}
        actual = [(c['platform'], c['sql_version'], c['compatibility_level'])
                  for c in native['cases']]
        self.assertEqual(len(actual), 12)
        self.assertEqual(set(actual), expected)
        self.assertTrue(all(c['status'] == 'PASS' and c['independent_audit']
                            and c['contexts'] == ['local', 'direct_central']
                            for c in native['cases']))
        self.assertEqual((native['positive_routes'], native['fixed_result_rows'],
                          native['overflow_rejections'], native['overflow_result_rows']),
                         (24, 72, 24, 0))
        self.assertEqual(native['overflow_error'], {'number': 51520,
                         'message': 'TBX_XLSX_SHARED_STRING_COUNT_LIMIT'})
        self.assertEqual((native['immediate_audits'], native['final_physical_target_audits'],
                          native['own_databases_removed'], native['trust_removal_events']),
                         (12, 6, 24, 24))
        self.assertEqual(record['native_attempts'], {'diagnostics_including_failure_and_audits': 8,
                         'boundary_cases': 12, 'immediate_audits': 12, 'final_audits': 6, 'total': 38})
        framework = record['framework']
        self.assertEqual(framework['original_run'], {'status': 'FAILED', 'passed_phases': 18,
                         'failed_phase': 'OwnIL', 'final_pins_unchanged': True})
        self.assertEqual(framework['successor']['status'], 'PASS')
        self.assertEqual(framework['composed_passed_phases'], 19)
        self.assertEqual(framework['successor']['allowed_member'], 'System.Environment.get_TickCount')
        self.assertEqual(framework['successor']['rejected_members'],
                         ['System.Environment.get_MachineName', 'System.Environment.GetEnvironmentVariable(string)'])
        self.assertEqual(record['clock_gate_assertions'], 35)

    def test_sst_history_adapter_rejects_current_drift_and_replaced_archive(self):
        record_bytes = (ROOT / xlsx_sst_budget.REPORT).read_bytes()
        workbook = (ROOT / xlsx_sst_budget.WORKBOOK).read_bytes()
        with tempfile.TemporaryDirectory(prefix='sst-proof-', dir=ROOT / '.runtime') as folder:
            root = Path(folder)
            current = root / xlsx_sst_budget.WORKBOOK
            current.parent.mkdir(parents=True)
            report = root / xlsx_sst_budget.REPORT
            report.parent.mkdir(parents=True)
            report.write_bytes(record_bytes)
            current.write_bytes(workbook + b'\n')
            with self.assertRaisesRegex(ValueError, 'current SST source differs'):
                xlsx_sst_budget.validate_historical_source(root, xlsx_sst_budget.WORKBOOK,
                    xlsx_sst_budget.HISTORICAL[xlsx_sst_budget.WORKBOOK])
            current.write_bytes(workbook)
            archive = root / xlsx_sst_budget.ARCHIVE
            archive.parent.mkdir(parents=True)
            archive.write_bytes(b'not the immutable source archive')
            with self.assertRaisesRegex(ValueError, 'historical source archive differs'):
                xlsx_sst_budget.validate_historical_source(root, xlsx_sst_budget.WORKBOOK,
                    xlsx_sst_budget.HISTORICAL[xlsx_sst_budget.WORKBOOK])
        with self.assertRaisesRegex(ValueError, 'unsupported historical'):
            xlsx_sst_budget.validate_historical_source(ROOT, '../unexpected', '0' * 64)

    def test_xlsx_help_source_transition_is_exact_and_archive_bound(self):
        runtime = ROOT / '.runtime'
        runtime.mkdir(exist_ok=True)
        path = 'Modules/toolbelt.file.xlsx-memory/Source/USP_ListXlsxWorksheets.sql'
        expected = xlsx_sst_budget.XLSX_HELP_SOURCE_SHA256[path]
        original = help_contract_source.validate_historical_source(ROOT, path, expected)
        current = help_contract_source.validate_current_source(ROOT, path)
        with self.assertRaisesRegex(ValueError, 'Historical Help source pin differs'):
            help_contract_source.validate_historical_source(ROOT, path, '0' * 64)
        with self.assertRaisesRegex(ValueError, 'unsupported XLSX help source path'):
            xlsx_sst_budget.project_historical_xlsx_help('../unexpected', original)

        with tempfile.TemporaryDirectory(prefix='xlsx-help-pin-', dir=runtime) as folder:
            sandbox = Path(folder)
            target = sandbox / path
            target.parent.mkdir(parents=True)
            target.write_bytes(current + b'-- unrelated SQL change\n')
            (sandbox / help_contract_source.RECORD).parent.mkdir(parents=True)
            shutil.copyfile(ROOT / help_contract_source.RECORD, sandbox / help_contract_source.RECORD)
            archive_target = sandbox / help_contract_source.ARCHIVE
            archive_target.parent.mkdir(parents=True)
            shutil.copyfile(ROOT / help_contract_source.ARCHIVE, archive_target)
            shutil.copyfile(ROOT / 'LICENSE.md', sandbox / 'LICENSE.md')
            with self.assertRaisesRegex(ValueError, 'Current Help source differs'):
                help_contract_source.validate_historical_source(sandbox, path, expected)
            target.write_bytes(current)
            archive_target.write_bytes(archive_target.read_bytes() + b'corruption')
            with self.assertRaisesRegex(ValueError, 'Help baseline archive differs'):
                help_contract_source.validate_historical_source(sandbox, path, expected)

    def test_sst_source_projections_allow_only_the_bound_changes(self):
        current = (ROOT / xlsx_sst_budget.CELL_TEST).read_bytes()
        import parameter_help_transition
        current = parameter_help_transition.restore_verifier_source(ROOT, xlsx_sst_budget.CELL_TEST, current)
        previous = xlsx_sst_budget.restore_previous_cell_test(ROOT, current)
        self.assertEqual(xlsx_sst_budget.digest(previous), xlsx_sst_budget.PREVIOUS_CELL_TEST_SHA256)
        r21 = xlsx_sst_budget.project_cell_test(previous)
        self.assertEqual(xlsx_sst_budget.restore_help_cell_test(ROOT, current), r21)
        self.assertEqual(xlsx_sst_budget.project_help_cell_test(r21), current)
        with self.assertRaisesRegex(ValueError, 'outside the exact help dispatch'):
            xlsx_sst_budget.restore_help_cell_test(
                ROOT, current.replace(xlsx_sst_budget.CELL_HELP_HOOK, b'            pass\n', 1))
        with self.assertRaisesRegex(ValueError, 'outside the exact help dispatch'):
            xlsx_sst_budget.restore_previous_cell_test(ROOT, current.replace(b'continue', b'pass', 1))
        workbook = (ROOT / xlsx_sst_budget.WORKBOOK).read_bytes()
        executed = xlsx_sst_budget.reconstruct_executed_workbook(workbook)
        self.assertEqual(executed.replace(b'\r\n', b'\n'), workbook)
        self.assertEqual(executed.count(b'\r\n'), 1)
        self.assertEqual(xlsx_sst_budget.digest(executed),
                         'c6774184c0ae8aa1d718198708fbe431fef315c8e307dd0ea012ee7c083d3504')
        with self.assertRaisesRegex(ValueError, 'timer anchor'):
            xlsx_sst_budget.reconstruct_executed_workbook(workbook.replace(b'Stopwatch.StartNew()', b'null', 1))
        path = 'Tests/Release/Invoke-XlsxSharedStringBoundaryLab.ps1'
        original = (ROOT / path).read_bytes()
        projected = xlsx_sst_budget.project_boundary_driver(original)
        cleanup = b'} finally {\n    foreach ($connection in $script:connections)'
        self.assertIn(cleanup, original)
        self.assertEqual(original[original.index(cleanup):], projected[projected.index(cleanup):])

    def test_sst_offline_source_projection_is_method_scoped(self):
        current = (ROOT / xlsx_sst_budget.OFFLINE_TEST_PATH).read_bytes()
        record = xlsx_sst_budget.read_record(ROOT)
        binding = record['offline_test_source']
        projection = xlsx_sst_budget.offline_test_projection(current)
        self.assertEqual(xlsx_sst_budget.digest(projection), binding['projection_sha256'])

        class_header = b'class FunctionCallerQualificationTests(unittest.TestCase):\n'
        method_header = (b'    def test_fixed_function_compositions_and_current_native_reports(self):\n')
        self.assertEqual(current.count(class_header), 1)
        self.assertEqual(current.count(method_header), 1)
        unrelated = current.replace(class_header,
            b'def foreign_hidden_runner_helper():\n    return None\n\n\n' + class_header, 1)
        self.assertEqual(xlsx_sst_budget.offline_test_projection(unrelated), projection)

        changed_method = current.replace(method_header,
            method_header + b"        raise AssertionError('changed selected test')\n", 1)
        self.assertNotEqual(xlsx_sst_budget.offline_test_projection(changed_method), projection)
        changed_decorator = current.replace(method_header,
            b"    @unittest.skip('changed decorator')\n" + method_header, 1)
        self.assertNotEqual(xlsx_sst_budget.offline_test_projection(changed_decorator), projection)
        changed_base = current.replace(class_header,
            b'class FunctionCallerQualificationTests(object):\n', 1)
        self.assertNotEqual(xlsx_sst_budget.offline_test_projection(changed_base), projection)
        changed_fixture = current.replace(class_header,
            class_header + b'    def setUp(self):\n        pass\n\n', 1)
        self.assertNotEqual(xlsx_sst_budget.offline_test_projection(changed_fixture), projection)

        changed_global = current + b'\nrelease = None\n'
        self.assertNotEqual(xlsx_sst_budget.offline_test_projection(changed_global), projection)
        rebound_class = current + b'\ndef FunctionCallerQualificationTests():\n    pass\n'
        with self.assertRaisesRegex(ValueError, 'class is rebound'):
            xlsx_sst_budget.offline_test_projection(rebound_class)

        loader_source = (
            b'import unittest\nrelease = load_release()\n'
            b'def load_release():\n    return 1\n'
            b'class FunctionCallerQualificationTests(unittest.TestCase):\n'
            b'    def test_fixed_function_compositions_and_current_native_reports(self):\n'
            b'        return release\n'
        )
        loader_projection = xlsx_sst_budget.offline_test_projection(loader_source)
        changed_loader = loader_source.replace(b'    return 1\n', b'    return 2\n', 1)
        self.assertNotEqual(xlsx_sst_budget.offline_test_projection(changed_loader), loader_projection)

        duplicate_method = current.replace(method_header,
            b'    def test_fixed_function_compositions_and_current_native_reports(self):\n'
            b'        pass\n\n' + method_header, 1)
        with self.assertRaisesRegex(ValueError, 'missing or duplicated'):
            xlsx_sst_budget.offline_test_projection(duplicate_method)
        missing_method = current.replace(method_header,
            method_header.replace(b'current_native_reports', b'current_native_reports_changed'), 1)
        with self.assertRaisesRegex(ValueError, 'missing or duplicated'):
            xlsx_sst_budget.offline_test_projection(missing_method)

    def test_sst_candidate_path_is_fixed_before_file_access(self):
        record = xlsx_sst_budget.read_record(ROOT)
        for path in ('../candidate.zip', '/tmp/candidate.zip', 'C:/candidate.zip',
                     'Releases/1.0.0/Artifacts/unexpected.zip'):
            altered = copy.deepcopy(record)
            altered['candidate_bundle']['path'] = path
            with patch.object(xlsx_sst_budget, 'read_record', return_value=altered):
                with self.assertRaisesRegex(ValueError, 'candidate archive path'):
                    xlsx_sst_budget.validate_current(ROOT)

    def test_sst_offline_archive_prevents_method_rebinding_and_path_escape(self):
        record = xlsx_sst_budget.read_record(ROOT)
        altered = copy.deepcopy(record)
        altered['offline_test_source']['archive']['path'] = '../unexpected.zip'
        with self.assertRaisesRegex(ValueError, 'archive binding differs'):
            xlsx_sst_budget.validate_offline_test_source(ROOT, altered)
        with tempfile.TemporaryDirectory(prefix='sst-scope-', dir=ROOT / '.runtime') as folder:
            root = Path(folder)
            self.assertTrue(root.resolve().is_relative_to((ROOT / '.runtime').resolve()))
            source = (ROOT / xlsx_sst_budget.OFFLINE_TEST_PATH).read_bytes()
            header = b'    def test_fixed_function_compositions_and_current_native_reports(self):\n'
            changed = source.replace(header, header + b"        raise AssertionError('changed oracle')\n", 1)
            current = root / xlsx_sst_budget.OFFLINE_TEST_PATH
            current.parent.mkdir(parents=True)
            current.write_bytes(changed)
            (root / 'LICENSE.md').write_bytes((ROOT / 'LICENSE.md').read_bytes())
            archive = root / xlsx_sst_budget.OFFLINE_TEST_ARCHIVE
            archive.parent.mkdir(parents=True)
            archive.write_bytes((ROOT / xlsx_sst_budget.OFFLINE_TEST_ARCHIVE).read_bytes())
            altered = copy.deepcopy(record)
            altered['offline_test_source']['projection_sha256'] = xlsx_sst_budget.digest(
                xlsx_sst_budget.offline_test_projection(changed))
            with self.assertRaisesRegex(ValueError, 'differs from its qualified archive'):
                xlsx_sst_budget.validate_offline_test_source(root, altered)

    def test_sst_old_report_projection_rejects_content_and_mixed_endings(self):
        for path, projection in xlsx_sst_budget.HISTORICAL_REPORT_EOL.items():
            canonical = (ROOT / path).read_bytes().replace(b'\r\n', b'\n')
            expected = projection['canonical_lf_sha256']
            for data in (canonical, canonical.replace(b'\n', b'\r\n')):
                self.assertEqual(xlsx_sst_budget.validate_historical_report(path, data, expected), canonical)
            for data in (canonical + b' ', canonical.replace(b'\n', b'\r\n', 1)):
                with self.assertRaisesRegex(ValueError, 'exact LF/CRLF'):
                    xlsx_sst_budget.validate_historical_report(path, data, expected)
