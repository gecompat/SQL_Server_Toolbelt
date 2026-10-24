"""Deterministische Releasegrenzen; kein SQL, Build, Tag oder Netzwerk."""
import copy
import importlib.util
import io
import json
from pathlib import Path
import stat
import shutil
import subprocess
import sys
import unittest
import warnings
import zipfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("prepare_release", ROOT / "Scripts/Release/prepare_release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class PreparationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.plan = json.loads((ROOT / release.PLAN).read_bytes())
        _, cls.files = release.snapshot("HEAD")
        cls.files[release.PLAN] = (ROOT / release.PLAN).read_bytes()
        cls.files[release.MATRIX] = (ROOT / release.MATRIX).read_bytes()

    def test_complete_current_plan_and_matrix(self):
        self.assertEqual(release.make_plan(self.files, self.plan["product_commit"]), self.plan)
        self.assertEqual(release.matrix(self.plan), (ROOT / release.MATRIX).read_bytes())
        self.assertEqual(len(self.plan["modules"]), 45)
        self.assertEqual(sum(m["proposed_channel"] == "stable" for m in self.plan["modules"]), 19)

    def test_publication_stays_unauthorized(self):
        self.assertIs(self.plan["publication_authorized"], False)
        self.assertEqual(self.plan["state"], "prepared_not_published")
        self.assertTrue(all(m["current_release_status"] == "unreleased" for m in self.plan["modules"]))

    def test_approved_target_scope_does_not_publish_or_waive_tests(self):
        scope = self.plan['approved_target_scope']
        self.assertEqual(scope['channels'], {'stable': 19, 'preview': 26})
        self.assertEqual(scope['sql_compatibility_levels'], {'2019': [150], '2022': [150, 160], '2025': [150, 160, 170]})
        self.assertIs(scope['publication_authorized'], False)
        self.assertIs(scope['preview_waives_required_tests'], False)
        self.assertIn(b'SUPPORT.md', release.matrix(self.plan))
        for flag in ('publication_authorized', 'preview_waives_required_tests'):
            changed = dict(self.files)
            forged = copy.deepcopy(scope)
            forged[flag] = True
            changed[release.DIRECTORY + '/support-scope.json'] = release.encoded(forged)
            with self.assertRaises(release.ReleaseError):
                release.make_plan(changed, self.plan['product_commit'])

    def test_complete_profiles_preserve_platform_and_dependency_boundaries(self):
        spec = importlib.util.spec_from_file_location('complete', ROOT / 'Tests/Release/prepare_complete_package.py')
        complete = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(complete)
        profiles = complete.module_profiles(self.files)
        self.assertEqual({p: len(m) for p, m in profiles.items()},
                         {'Windows-local': 45, 'Windows-central': 43, 'Portable-local': 40, 'Portable-central': 40})
        self.assertNotIn('toolbelt.filesystem.windows', profiles['Windows-central'])
        self.assertNotIn('toolbelt.archive.zip-files', profiles['Windows-central'])
        for profile in ('Portable-local', 'Portable-central'):
            self.assertNotIn('toolbelt.tsql.script-parser', profiles[profile])
            self.assertNotIn('toolbelt.metadata.table-clone', profiles[profile])
            self.assertNotIn('toolbelt.tsql.ssis-debug', profiles[profile])
            for mid in profiles[profile]:
                self.assertTrue(set(release.dependencies(self.files[f'Modules/{mid}/module.yaml'].decode('utf-8-sig'))) <= set(profiles[profile]))
        broken = dict(self.files)
        key = 'Modules/toolbelt.filesystem.windows/module.yaml'
        broken[key] = broken[key].replace(b'  local: true', b'  local: false')
        with self.assertRaises(complete.release.ReleaseError):
            complete.module_profiles(broken)

    def test_product_and_foundation_bindings(self):
        release.validate_plan(self.files, self.plan)

    def test_dependency_demotion_is_transitive(self):
        graph = {"a": {"validation_status": "validated", "dependencies": ["b"]},
                 "b": {"validation_status": "validated", "dependencies": ["c"]},
                 "c": {"validation_status": "partially validated", "dependencies": []}}
        self.assertEqual(release.channels(graph), {"a": "preview", "b": "preview", "c": "preview"})
        rows = {m["module_id"]: m for m in self.plan["modules"]}
        for mid in ("toolbelt.core.second-session", "toolbelt.core.event-log"):
            self.assertEqual(rows[mid]["validation_status"], "validated")
            self.assertEqual(rows[mid]["proposed_channel"], "preview")

    def test_missing_dependency_and_cycles_fail(self):
        for graph in ({"a": {"validation_status": "validated", "dependencies": ["missing"]}},
                      {"a": {"validation_status": "validated", "dependencies": ["a"]}}):
            with self.assertRaises(release.ReleaseError):
                release.channels(graph)

    def test_no_stable_module_depends_on_preview(self):
        rows = {m["module_id"]: m for m in self.plan["modules"]}
        for m in rows.values():
            if m["proposed_channel"] == "stable":
                self.assertEqual(m["validation_status"], "validated")
                self.assertTrue(all(rows[d]["proposed_channel"] == "stable" for d in m["dependencies"]))

    def test_forged_channel_or_approval_is_rejected(self):
        files = dict(self.files)
        files[release.MATRIX] = release.matrix(self.plan)
        for change in ("approval", "channel"):
            plan = copy.deepcopy(self.plan)
            if change == "approval":
                plan["publication_authorized"] = True
            else:
                next(m for m in plan["modules"] if m["proposed_channel"] == "preview")["proposed_channel"] = "stable"
            with self.assertRaises(release.ReleaseError):
                release.validate_plan(files, plan)

    def test_version_and_matrix_drift_fail(self):
        files = dict(self.files)
        files[release.MATRIX] = release.matrix(self.plan)
        key = "Modules/toolbelt.core.result-table/module.yaml"
        files[key] = files[key].replace(b'version: "1.0.0"', b'version: "9.0.0"', 1)
        with self.assertRaises(release.ReleaseError):
            release.validate_plan(files, self.plan)

    def test_historical_manifest_links_preserve_frozen_package_validation(self):
        files = dict(self.files)
        files[release.MATRIX] = release.matrix(self.plan, "module.yaml")
        release.validate_plan(files, self.plan)
        self.assertIn(b"/toolbelt.core.result-table/README.md)", release.matrix(self.plan))
        files = dict(self.files)
        files[release.MATRIX] = b"stale"
        with self.assertRaises(release.ReleaseError):
            release.validate_plan(files, self.plan)

    def test_private_and_windows_alias_paths_fail(self):
        for name in ("../outside", "/absolute", "C:/private", "a\\b", "a/../b", ".git/config",
                     ".runtime/private.json", "module/obj/output", "private.pfx", "private.pdb",
                     ".env", "a/secrets.json", "a/nul.txt", "a/aux", "a./file", "a/file ", "a//b"):
            with self.subTest(path=name), self.assertRaises(release.ReleaseError):
                release.safe_path(name)

    def test_archive_duplicate_and_symlink_fail(self):
        for names, symlink in ((["a", "A"], False), (["link"], True)):
            data = io.BytesIO()
            with warnings.catch_warnings(), zipfile.ZipFile(data, "w") as archive:
                warnings.simplefilter("ignore", UserWarning)
                for name in names:
                    entry = zipfile.ZipInfo(name)
                    entry.create_system = 3
                    entry.external_attr = ((stat.S_IFLNK if symlink else stat.S_IFREG) | 0o644) << 16
                    archive.writestr(entry, b"target")
            with self.assertRaises(release.ReleaseError):
                release.read_zip(data.getvalue())

    def test_zip_is_repeatable_and_preserves_bytes(self):
        payload = {"LICENSE.md": b"synthetic license", "Modules/example.sql": b"SELECT 1;\r\n"}
        first = release.write_zip(payload)
        self.assertEqual(first, release.write_zip(dict(reversed(list(payload.items())))))
        actual = release.read_zip(first)
        self.assertEqual(actual[release.NAME + "/Modules/example.sql"], payload["Modules/example.sql"])

    def test_root_entrypoint_links_are_rebased(self):
        data = {f"{release.DIRECTORY}/START-HERE.md":
                b"[guide](README.md) [matrix](FREIGABEMATRIX.md) [gates](RELEASE-GATES.md) [deployment](../../Deployment/README.md)"}
        actual = release.start_here(data).decode()
        self.assertIn(f"({release.DIRECTORY}/README.md)", actual)
        self.assertIn(f"({release.DIRECTORY}/FREIGABEMATRIX.md)", actual)
        self.assertIn("(Deployment/README.md)", actual)
        self.assertIn(f"({release.DIRECTORY}/RELEASE-GATES.md)", actual)

    def test_native_harness_guards_without_sql_access(self):
        pwsh = shutil.which("pwsh")
        if pwsh is None:
            self.skipTest("PowerShell 7 fehlt; kein SQL-Ersatzlauf")
        result = subprocess.run([pwsh, "-NoProfile", "-NonInteractive", "-File",
                                 str(ROOT / "Tests/Release/Test-StablePackageHarness.ps1")],
                                capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, "Native Harnessguards fehlgeschlagen")
        self.assertIn(b"PASS RELEASE_HARNESS", result.stdout)

    def test_build_candidate_rejects_embedded_private_paths(self):
        sys.path.insert(0, str(ROOT / "Scripts/Release"))
        import check_clr_builds
        nested = ROOT / "Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip"
        with zipfile.ZipFile(nested) as archive:
            name = next(n for n in archive.namelist() if n.endswith("/Toolbelt.Tsql.SsisDebug.dll"))
            binary = archive.read(name)
        private = ROOT / ".runtime" / "synthetic-build-input"
        check_clr_builds.check_binary(binary, [private])
        for encoding in ("utf-8", "utf-16-le"):
            with self.subTest(encoding=encoding), self.assertRaises(check_clr_builds.release.ReleaseError):
                check_clr_builds.check_binary(binary + str(private).encode(encoding), [private])

    def test_native_evidence_cannot_cover_changed_inputs(self):
        evidence = json.loads((ROOT / release.QUALIFICATION).read_bytes())
        files = dict(self.files)
        paths = (evidence["native_package"]["driver"], evidence["native_package"]["method"],
                 evidence["clr_build_inputs"]["method"])
        for path in paths:
            files[path] = (ROOT / path).read_bytes()
        files[release.QUALIFICATION] = release.encoded(evidence)
        release.validate_qualification(files, self.plan)
        for path in paths:
            changed = dict(files)
            changed[path] += b"# changed input\n"
            with self.assertRaises(release.ReleaseError):
                release.validate_qualification(changed, self.plan)
        with self.assertRaises(release.ReleaseError):
            release.validate_qualification(files, self.plan,
                                          {"Install-Stable-local.sql": b"SELECT 1;", "Install-Stable-central.sql": b"SELECT 1;"})


class ClrPackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(ROOT / 'Scripts/Release'))
        import prepare_clr_package
        cls.clr = prepare_clr_package
        cls.package = ROOT / prepare_clr_package.LOCATION

    def test_actual_prebuilt_package_and_platform_boundaries(self):
        metadata = self.clr.verify(self.package)
        self.assertEqual(len(metadata['artifacts']), 13)
        self.assertEqual(len(metadata['profiles']['Windows-local']), 12)
        self.assertEqual(len(metadata['profiles']['Windows-central']), 11)
        for mode in ('local', 'central'):
            selected = metadata['profiles']['Portable-' + mode]
            self.assertEqual(len(selected), 9)
            self.assertFalse(set(selected) & self.clr.WINDOWS_ONLY)

    def test_uninstall_repeat_preserves_absence_contract(self):
        with zipfile.ZipFile(self.package) as archive:
            prefix = self.clr.PACKAGE + '/SQL/'
            for profile in ('Windows-local','Windows-central','Portable-local','Portable-central'):
                present = archive.read(prefix + 'Uninstall-' + profile + '.sql')
                absent = archive.read(prefix + 'UninstallAbsent-' + profile + '.sql')
                self.assertNotEqual(present, absent)
                self.assertIn(b"N'0x'", absent)
                self.assertNotIn(b'$(' , absent)

    def test_corrupt_external_checksum_and_duplicate_zip_entries_fail(self):
        import tempfile
        with tempfile.TemporaryDirectory(prefix='clr-negative-',dir=self.clr.release.runtime_root()) as temp:
            path = Path(temp) / self.package.name
            path.write_bytes(self.package.read_bytes())
            checksum = Path(str(path)+'.sha256')
            checksum.write_text('0'*64+'  '+path.name+'\n',encoding='ascii')
            with self.assertRaisesRegex(self.clr.release.ReleaseError,'Prüfsumme'):
                self.clr.verify(path)
            with warnings.catch_warnings(), zipfile.ZipFile(path,'w') as archive:
                warnings.simplefilter('ignore',UserWarning)
                archive.writestr(self.clr.PACKAGE+'/duplicate.txt','a')
                archive.writestr(self.clr.PACKAGE+'/duplicate.txt','b')
            checksum.write_text(self.clr.digest(path.read_bytes())+'  '+path.name+'\n',encoding='ascii')
            with self.assertRaisesRegex(self.clr.release.ReleaseError,'Doppelte'):
                self.clr.verify(path)

    def test_clr_budget_regression_without_sql(self):
        result = subprocess.run([shutil.which('pwsh'),'-NoProfile','-NonInteractive','-File',
                                 str(ROOT / 'Tests/Release/Test-ClrPackageHarness.ps1')],capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr.decode(errors='replace'))
        self.assertIn(b'PASS CLR_HARNESS',result.stdout)

    def test_unqualified_candidate_requires_explicit_private_verification(self):
        import tempfile
        with zipfile.ZipFile(self.package) as archive:
            prefix=self.clr.PACKAGE+'/'
            payload={p[len(prefix):]:archive.read(p) for p in archive.namelist()}
        metadata=json.loads(payload.pop('CLR-PACKAGE.json'))
        payload.pop('QUALIFICATION.json')
        metadata['qualification_state']='pending'
        metadata['files']={p:{'sha256':self.clr.digest(b),'size':len(b)} for p,b in sorted(payload.items())}
        payload['CLR-PACKAGE.json']=self.clr.release.encoded(metadata)
        with tempfile.TemporaryDirectory(prefix='clr-pending-',dir=self.clr.release.runtime_root()) as temp:
            path=Path(temp)/self.package.name
            path.write_bytes(self.clr.release.write_zip(payload,self.clr.PACKAGE))
            Path(str(path)+'.sha256').write_text(self.clr.digest(path.read_bytes())+'  '+path.name+'\n',encoding='ascii')
            with self.assertRaisesRegex(self.clr.release.ReleaseError,'Kandidat'):
                self.clr.verify(path)
            self.assertEqual(self.clr.verify(path,allow_unqualified_candidate=True)['qualification_state'],'pending')

    def test_clr_qualification_rejects_sql_binary_and_method_drift(self):
        qualification = json.loads((ROOT / self.clr.QUALIFICATION).read_bytes())
        with zipfile.ZipFile(self.package) as archive:
            prefix=self.clr.PACKAGE+'/'
            payload={p[len(prefix):]:archive.read(p) for p in archive.namelist()}
        sources={p:(ROOT/p).read_bytes() for p in qualification['method_bindings']}
        self.clr.release.validate_clr_qualification(payload,qualification,sources)
        for prefix in ('SQL/','Binaries/'):
            changed=dict(payload)
            name=next(p for p in changed if p.startswith(prefix))
            changed[name]+=b'changed'
            with self.subTest(kind=prefix),self.assertRaises(self.clr.release.ReleaseError):
                self.clr.release.validate_clr_qualification(changed,qualification,sources)
        changed=dict(sources)
        changed[next(iter(changed))]+=b'# changed input\n'
        with self.assertRaises(self.clr.release.ReleaseError):
            self.clr.release.validate_clr_qualification(payload,qualification,changed)


class ApiQualificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(ROOT / 'Tests/Release'))
        import prepare_api_qualification
        cls.api = prepare_api_qualification

    def test_fixture_bytes_preserve_independent_sparse_unicode_oracles(self):
        import xml.etree.ElementTree as ET
        source = (ROOT / 'Spikes/XlsxMemory/Test-Framework.ps1').read_bytes()
        blob = self.api.xlsx_fixture(source)
        self.assertEqual(blob, self.api.xlsx_fixture(source))
        with zipfile.ZipFile(io.BytesIO(blob)) as z:
            self.assertEqual(len(z.namelist()), 6)
            ns = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
            cells = ET.fromstring(z.read('xl/worksheets/sheet1.xml')).findall('.//m:c', ns)
            self.assertEqual(len(cells), 9)
            self.assertEqual(cells[-1].get('r'), 'XFD1048576')
            self.assertIn('😀', z.read('xl/sharedStrings.xml').decode())
        with zipfile.ZipFile(io.BytesIO(self.api.xlsx_fixture(source, True))) as z:
            self.assertEqual(len(ET.fromstring(z.read('xl/worksheets/sheet1.xml')).findall('.//m:c', ns)), 100)
            self.assertEqual(len(ET.fromstring(z.read('xl/sharedStrings.xml')).find('.//m:t', ns).text), 500000)

    def test_fixture_source_change_fails_closed(self):
        with self.assertRaises((ValueError, IndexError)):
            self.api.xlsx_fixture(b'changed canonical source')

    def test_ssis_functional_projection_preserves_cross_database_oracles(self):
        import prepare_ssis_functional_fixture
        import re
        source = (ROOT / 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-V1Cases.ps1').read_bytes()
        adapted = prepare_ssis_functional_fixture.functional_v1(source).decode('utf-8')
        text = source.decode('utf-8-sig')
        start = text.index('# Rechte ausschließlich')
        end = text.index('if($CrossDatabase){', start)
        self.assertTrue(adapted.startswith(text[:start]))
        self.assertTrue(adapted.endswith(text[end:]))
        for oracle in ['CROSS_DATABASE_GENERATED_SQL', 'CROSS_DATABASE_CALLER_AND_COLLATION', 'NOLOCK_DIRTY_READ', 'NOLOCK_STILL_WAITING_FOR_SCHEMA']:
            self.assertIn(oracle, adapted)
        self.assertIsNone(re.search(r'\b(GRANT|DENY|REVOKE|CREATE\s+USER|CREATE\s+LOGIN|EXECUTE\s+AS|ALTER\s+ROLE)\b', adapted, re.I))
        with self.assertRaises(ValueError):
            prepare_ssis_functional_fixture.functional_v1(source.replace(b'if($CrossDatabase){', b'changed-source'))

    def test_no_publication_finite_scope_and_owned_cleanup_remain_explicit(self):
        plan = json.loads((ROOT / 'Tests/Release/api-qualification-spec.json').read_bytes())
        self.assertFalse(plan['publication_authorized'])
        self.assertEqual(len(plan['tests']), 165)
        self.assertEqual(len({x['id'] for x in plan['tests']}), 165)
        self.assertEqual(plan['reused_full_matrices'], ['toolbelt.conversion.safe-cast', 'toolbelt.json.pointer'])
        for t in plan['tests']:
            self.assertTrue((ROOT / t['source']).is_file())
        self.assertLess(plan['budget']['max_case_attempts'], 100)
        self.assertFalse(plan['budget']['delegation'])

    def test_evidence_assignment_preserves_every_canonical_manifest(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/evidence-map.json').read_bytes())
        api = json.loads((ROOT / 'Releases/1.0.0/api-qualification.json').read_bytes())
        spec_path = ROOT / api['fixture_spec']
        spec = json.loads(spec_path.read_bytes())
        plan = json.loads((ROOT / release.PLAN).read_bytes())
        self.assertEqual({m['module_id'] for m in report['modules']}, {m['module_id'] for m in plan['modules']})
        self.assertEqual(len(report['modules']), 45)
        self.assertFalse(report['module_statuses_changed'])
        self.assertFalse(report['publication_authorized'])
        self.assertFalse(api['publication_authorized'])
        self.assertEqual(hashlib.sha256(spec_path.read_bytes().replace(b'\r\n', b'\n')).hexdigest(), api['fixture_spec_sha256'])
        self.assertEqual(api['fixture_definitions'], len(spec['tests']))
        self.assertEqual(set(api['fixture_source_sha256']), {t['source'] for t in spec['tests']})
        self.assertEqual(api['completed_cases'], api['planned_target_cl_group_cases'])
        self.assertEqual(api['fully_passed_cases'] + api['partial_cases'], api['completed_cases'])
        cases = {c['case_id']: c for c in api['cases']}
        self.assertEqual(len(cases), api['completed_cases'])
        for case in cases.values():
            self.assertTrue(case['independent_cleanup_and_pin_audit'])
            self.assertEqual(case['result'], 'partially validated' if case['blocked_fixture_calls'] else 'validated')
        for path, digest in api['fixture_source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes().replace(b'\r\n', b'\n')).hexdigest(), digest)
        module_results = {m['module_id']: m for m in api['module_results']}
        self.assertEqual(set(module_results), {t['module_id'] for t in spec['tests']})
        self.assertEqual(api['functional_calls_passed'], sum(c['passed_fixture_calls'] + c['reused_fixture_calls'] for c in cases.values()))
        self.assertEqual(api['functional_calls_blocked'], sum(len(c['blocked_fixture_calls']) for c in cases.values()))
        for key in ('all_owned_database_names_absent', 'trust_states_restored', 'current_input_pins_unchanged', 'configuration_restored', 'separate_configuration_audit'):
            self.assertTrue(api['final_independent_audit'][key])
        for m in report['modules']:
            self.assertFalse(m['record_snapshot_is_execution_commit'])
            canonical = (ROOT / m['manifest']).read_bytes().replace(b'\r\n', b'\n')
            self.assertEqual(hashlib.sha256(canonical).hexdigest(), m['manifest_sha256'])
            self.assertEqual(set(m['additional_fixture_ids']), {t['id'] for t in spec['tests'] if t['module_id'] == m['module_id']})
            if m['additional_fixture_ids']:
                result = module_results[m['module_id']]
                self.assertEqual(m['additional_case_ids'], [c['case_id'] for c in result['cases']])
                self.assertTrue(all(c['case_id'] in cases for c in result['cases']))
                self.assertEqual(m['additional_result'], 'partially validated' if any(c['blocked'] for c in result['cases']) else 'validated selected fixture scope')

    def test_regex_followup_binds_corrected_delivery_and_preserves_history(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/regex-timeout-qualification.json').read_bytes())
        self.assertFalse(report['publication_authorized'])
        self.assertTrue(report['autonomous_development_paused'])
        self.assertFalse(report['historical_timeout_reproduced'])
        self.assertFalse(report['unique_historical_cause_proven'])
        self.assertEqual(report['old_binary_regression'], 'REPLACE_REDUNDANT_NO_MATCH_COPY')
        self.assertEqual(report['safety_limits'], {
            'standard_total_ms': 500, 'large_total_ms': 2000,
            'search_max_ms': 250, 'standard_utf16_bytes': 2097152,
            'large_utf16_bytes': 16777216})
        self.assertEqual(len(report['native_api_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level'])
                          for c in report['native_api_cases']},
                         {(p, v, cl) for p in ('linux', 'windows')
                          for v, levels in (('2019', (150,)), ('2022', (150, 160)),
                                            ('2025', (150, 160, 170))) for cl in levels})
        self.assertEqual(sum(c['fixture_calls_passed'] for c in report['native_api_cases']),
                         report['fixture_calls_passed'])
        self.assertTrue(all(c['result'] in ('PASS', 'PARTIAL') and c['independent_cleanup_and_pins']
                            for c in report['native_api_cases']))
        self.assertTrue(all('toolbelt.string.regex:Transformations.Contract.sql:' + mode in c['passed']
                            and 'toolbelt.string.regex:Materialization.Boundaries.sql:' + mode in c['passed']
                            for c in report['native_api_cases'] for mode in ('local', 'central')))
        for case in report['native_api_cases']:
            self.assertEqual(case['result'], 'PARTIAL' if case['blocked'] else 'PASS')
            self.assertTrue(all(b['id'] == 'toolbelt.string.regex:Captures.Contract.sql'
                                and b['reason'] == 'TBX_REGEX_TIMEOUT' for b in case['blocked']))
        self.assertEqual(report['package_cases_passed'], {'clr': 12, 'complete_full': 12})
        for path, digest in report['source_sha256'].items():
            current = hashlib.sha256((ROOT / path).read_bytes().replace(b'\r\n', b'\n')).hexdigest()
            if path == 'Tests/Release/Invoke-ApiQualificationLab.ps1':
                # Historische Ausführung bleibt an den tatsächlich gelieferten
                # Adapter gebunden; Diagnosepflege ist keine rückwirkende CI.
                followup = json.loads((ROOT / 'Releases/1.0.0/capture-timeout-investigation.json').read_bytes())
                self.assertEqual(followup['historical_method_bindings'], {path: digest})
                self.assertEqual(current, followup['source_sha256'][path])
                with zipfile.ZipFile(ROOT / release.ARTIFACTS / (release.NAME + '.zip')) as archive:
                    delivered = archive.read(release.NAME + '/' + path)
                self.assertEqual(hashlib.sha256(delivered.replace(b'\r\n', b'\n')).hexdigest(), digest)
            else:
                self.assertEqual(current, digest)
        data = release.read_zip((ROOT / release.CLR_PACKAGE).read_bytes())
        prefix = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
        binary = data[prefix + 'Binaries/Toolbelt.String.Regex.dll']
        self.assertEqual(hashlib.sha256(binary).hexdigest(), report['delivered_regex_binary_sha256'])
        current_plan = json.loads((ROOT / release.PLAN).read_bytes())
        self.assertEqual(report['product_commit'], current_plan['product_commit'])
        self.assertTrue(all(report['final_independent_audit'][key] for key in (
            'all_owned_database_names_absent', 'trust_states_restored',
            'current_input_pins_unchanged', 'configuration_restored', 'separate_configuration_audit')))
        historical = json.loads((ROOT / 'Releases/1.0.0/api-qualification.json').read_bytes())
        self.assertEqual(historical['partial_cases'], 1)
        self.assertEqual(historical['functional_calls_blocked'], 1)

    def test_capture_investigation_preserves_open_gate_and_exact_sources(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/capture-timeout-investigation.json').read_bytes())
        for flag in ('publication_authorized', 'production_changed', 'historical_timeout_reproduced',
                     'unique_historical_cause_proven'):
            self.assertIs(report[flag], False)
        self.assertTrue(report['autonomous_development_paused'])
        self.assertEqual(report['capture_release_gate'], 'open')
        previous = json.loads((ROOT / 'Releases/1.0.0/regex-timeout-qualification.json').read_bytes())
        self.assertEqual(report['safety_limits'], previous['safety_limits'])
        self.assertEqual(report['source_base_commit'], 'e9147db029732e6704883b8a60b5b8634bf7851b')
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes().replace(b'\r\n', b'\n')).hexdigest(), digest)
        controls = report['deliberate_timeout_controls']
        self.assertEqual([(c['synthetic_fault_phase'], c['synthetic_fault_case']) for c in controls],
                         [('rows', 1), ('negative', 27)])
        for control in controls:
            self.assertEqual(control['actual_case_state'], 'PARTIAL')
            self.assertEqual(control['contexts'], ['local', 'central'])
            self.assertTrue(control['original_sql6522_and_timeout_preserved'])
            self.assertTrue(control['private_clr_stack_and_exact_case_retained'])
            self.assertTrue(control['independent_cleanup_and_pin_audit'])
        calls = report['original_context_case']['passed_fixture_calls']
        self.assertEqual(len(calls), 7)
        self.assertTrue(all(c['result'] == 'PASS' for c in calls))
        self.assertEqual({(c['fixture'], c['context']) for c in calls
                          if 'Captures.' in c['fixture']},
                         {('toolbelt.string.regex:' + f, mode)
                          for f in ('Captures.Contract.sql', 'Captures.Metadata.ps1')
                          for mode in ('local', 'central')})
        self.assertEqual(report['per_call_diagnostic']['capture_calls_traced'], 58)
        self.assertTrue(report['final_independent_audit']['all_owned_database_names_absent'])
        self.assertTrue(report['final_independent_audit']['trust_states_restored'])
        self.assertFalse(report['final_independent_audit']['configuration_changed'])
        self.assertEqual(report['shared_wave']['attempts_consumed'], 4)
        self.assertNotIn('privateDiagnostic', json.dumps(report))
        self.assertNotIn('privateFixtureCase', json.dumps(report))

    @unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required for offline adapter guards')
    def test_capture_failure_diagnostic_without_sql(self):
        result = subprocess.run([shutil.which('pwsh'), '-NoProfile', '-NonInteractive', '-File',
                                 str(ROOT / 'Tests/Release/Test-ApiCaptureDiagnostic.ps1')],
                                cwd=ROOT, capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr.decode(errors='replace'))
        self.assertIn(b'PASS API_CAPTURE_DIAGNOSTIC', result.stdout)

    @unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required for offline adapter guards')
    def test_target_reuse_and_cleanup_reserve_without_sql(self):
        script = r'''
$ErrorActionPreference='Stop'
$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile('Tests/Release/Invoke-ApiQualificationLab.ps1',[ref]$null,[ref]$e)
if($e.Count){throw 'PARSE'}
foreach($name in @('Test-ApiSelected','Get-ReleaseTimeout','Get-ApiCasePins','Assert-ReleaseInputs','Get-ApiFixtureBinding','New-ApiBudgetProviders')){
 $node=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
 if($node.Count -ne 1){throw 'FUNCTION'}
 . ([scriptblock]::Create($node[0].Extent.Text))
}
$case=[pscustomobject]@{group='csv';Platform='linux';Version='2019';CL=150;workSeconds=300;cleanupSeconds=360}
$test=[pscustomobject]@{group='csv';only_missing_boundary_targets=$true}
if(Test-ApiSelected $test){throw 'DUPLICATE_QUALIFIED_BOUNDARY'}
$case.Version='2022'
if(-not (Test-ApiSelected $test)){throw 'MISSING_2022_BOUNDARY'}
$test=[pscustomobject]@{group='csv';only_additional_cl=$true}
if(-not (Test-ApiSelected $test)){throw 'MISSING_LOWER_CL'}
$case.CL=160
if(Test-ApiSelected $test){throw 'DUPLICATE_QUALIFIED_CL'}
$clock=[pscustomobject]@{ElapsedMilliseconds=345000};$cleanup=$false;$caught=$false
try{[void](Get-ReleaseTimeout)}catch{if($_.Exception.Message -cne 'RELEASE_API_DEADLINE'){throw};$caught=$true}
if(-not $caught){throw 'WORK_OVERRAN'}
$cleanup=$true
if((Get-ReleaseTimeout) -ne 15){throw 'CLEANUP_RESERVE_LOST'}
$clock.ElapsedMilliseconds=360001;$caught=$false
try{[void](Get-ReleaseTimeout)}catch{if($_.Exception.Message -cne 'RELEASE_API_DEADLINE'){throw};$caught=$true}
if(-not $caught){throw 'CLEANUP_UNBOUNDED'}
$root=Join-Path (Get-Location) '.runtime/offline-not-opened/Source'
$paths=@('Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Xlsx.Metadata.ps1','Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.Composition.xlsx','Modules/toolbelt.string.regex/Tests/Runtime/Relations.Metadata.ps1','Tests/CI/Set-SqlClientTlsPolicy.ps1','Tests/Release/Runtime/DefaultSnapshotCeiling.sql')
$pins=@(@{path=(Join-Path (Get-Location) 'Tests/Release/Invoke-ApiQualificationLab.ps1');sha256='synthetic'})
$pins+=@($paths|ForEach-Object {@{path=(Join-Path $root $_);sha256='synthetic'}})
$runset=[pscustomobject]@{sourceRoot=$root;spec=(Join-Path (Get-Location) 'Tests/Release/api-qualification-spec.json');pins=$pins}
$case.group='formats';$casePins=@(Get-ApiCasePins $runset $case)
if($casePins.Count -ne 4 -or @($casePins|Where-Object {$_.path -match 'regex|DefaultSnapshot'}).Count){throw 'GROUP_PIN_SCOPE'}
$checked=0
function Assert-ReleasePin($Path,$Expected){$script:checked++}
Assert-ReleaseInputs
if($checked -ne 4){throw 'GROUP_INPUT_CHECK_LOST'}
$checked=0;Assert-ReleaseInputs -All
if($checked -ne 6){throw 'WHOLE_INPUT_AUDIT_LOST'}
$ast=[Management.Automation.Language.Parser]::ParseFile('Tests/Release/Invoke-ApiQualificationMatrix.ps1',[ref]$null,[ref]$e)
$node=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Get-ApiCaseOutcome'},$true))
if($node.Count -ne 1){throw 'OUTCOME_FUNCTION'}
. ([scriptblock]::Create($node[0].Extent.Text))
if((Get-ApiCaseOutcome $true $true 'PARTIAL') -cne 'PARTIAL' -or
   (Get-ApiCaseOutcome $true $true 'COMPLETE') -cne 'PASS' -or
   (Get-ApiCaseOutcome $false $true '') -cne 'FAILED_CLEANED' -or
   (Get-ApiCaseOutcome $true $false 'COMPLETE') -cne 'CLEANUP_UNKNOWN'){throw 'FALSE_CASE_PROMOTION'}
$caught=$false
try{[void](Get-ApiCaseOutcome $true $true 'FAILED_CLEANED')}catch{if($_.Exception.Message -cne 'RELEASE_API_UNEXPECTED_STATE'){throw};$caught=$true}
if(-not $caught){throw 'UNEXPECTED_LEDGER_ACCEPTED'}
$left=[pscustomobject][ordered]@{id='synthetic';group='text';context='local'}
$right=[pscustomobject][ordered]@{context='local';group='text';id='synthetic'}
if((Get-ApiFixtureBinding $left) -cne (Get-ApiFixtureBinding $right)){throw 'JSON_KEY_ORDER_DRIFT'}
$right.context='central'
if((Get-ApiFixtureBinding $left) -ceq (Get-ApiFixtureBinding $right)){throw 'REAL_FIXTURE_DRIFT_IGNORED'}
$sourceClock=[pscustomobject]@{ElapsedMilliseconds=45000}
$providers=New-ApiBudgetProviders $sourceClock 300
$consumer=New-Module -ScriptBlock {Set-StrictMode -Version Latest}
$actual=& $consumer {param($callback) & $callback} $providers.Timeout
if($actual -ne 120){throw 'CALLBACK_SCRIPT_SCOPE_LOST'}
$sourceClock.ElapsedMilliseconds=299000
if((& $consumer {param($callback) & $callback} $providers.Timeout) -ne 1){throw 'CALLBACK_CLOCK_NOT_SHARED'}
$sourceClock.ElapsedMilliseconds=300001;$caught=$false
try{& $consumer {param($callback) & $callback} $providers.Read}catch{if($_.Exception.Message -cne 'RELEASE_API_DEADLINE'){throw};$caught=$true}
if(-not $caught){throw 'CALLBACK_DEADLINE_LOST'}
'PASS OFFLINE_API_GUARDS'
'''
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', script], cwd=ROOT, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('PASS OFFLINE_API_GUARDS', result.stdout)


if __name__ == "__main__":
    unittest.main()
