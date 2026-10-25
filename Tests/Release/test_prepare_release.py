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
        # Der freigegebene Releaseplan beschreibt den eingefrorenen Kandidaten,
        # während HEAD bereits die nächste Entwicklungsänderung enthalten darf.
        with zipfile.ZipFile(ROOT / 'Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip') as archive:
            prefix = 'SQL-Server-Toolbelt-1.0.0-candidate-source/'
            manifest = json.loads(archive.read(prefix + 'PACKAGE-MANIFEST.json'))
            cls.files, _, _ = release.recovered_snapshot(archive.read(prefix + 'PREPARATION.bundle'), manifest['source_commit'], manifest['product_commit'])
        cls.files[release.PLAN] = (ROOT / release.PLAN).read_bytes()
        cls.files[release.MATRIX] = (ROOT / release.MATRIX).read_bytes()

    def test_complete_frozen_plan_and_matrix(self):
        self.assertEqual(release.make_plan(self.files, self.plan["product_commit"]), self.plan)
        self.assertEqual(release.matrix(self.plan), (ROOT / release.MATRIX).read_bytes())
        self.assertEqual(len(self.plan["modules"]), 45)
        self.assertEqual(sum(m["proposed_channel"] == "stable" for m in self.plan["modules"]), 19)

    def test_publication_stays_unauthorized(self):
        self.assertIs(self.plan["publication_authorized"], False)
        self.assertEqual(self.plan["state"], "prepared_not_published")
        self.assertTrue(all(m["current_release_status"] == "unreleased" for m in self.plan["modules"]))

    def test_external_host_does_not_become_a_thirteenth_sql_clr_provider(self):
        sys.path.insert(0, str(ROOT / 'Scripts/Release'))
        import check_clr_builds as builds
        files = dict(self.files)
        expected = builds.clr_projects(files)
        files['Modules/toolbelt.tsql.ssis-debug/Exchange/Host/Toolbelt.Ssis.Export.csproj'] = b'<Project />'
        files['Modules/toolbelt.tsql.ssis-debug/Tests/Synthetic.csproj'] = b'<Project />'
        self.assertEqual(builds.clr_projects(files), expected)
        del files[expected[0]]
        with self.assertRaises(builds.release.ReleaseError):
            builds.clr_projects(files)

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
        # Die positive Baseline stammt aus den tatsächlich qualifizierten
        # Recoveryquellen, nicht aus einem inzwischen weiterentwickelten Builder.
        for path in paths:
            self.assertIn(path, files)
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


class SsisProductDeltaTests(unittest.TestCase):
    """Synthetische Validatorinputs, kein behaupteter nativer Qualifikationslauf."""
    def inputs(self):
        prefix = 'Modules/toolbelt.tsql.ssis-debug/'
        previous = {'Modules/toolbelt.synthetic/Source/Test.sql': b'SELECT 1;',
                    prefix + 'Clr/Core.cs': b'old core', prefix + 'Source/Test.sql': b'SELECT 1;',
                    'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs': b'fixed guard'}
        for p in ('Api.json', 'DependencyPins.json', 'ReleaseObjects.1.0.0.json'):
            previous[prefix + 'Contracts/' + p] = b'{}'
        current = dict(previous)
        current[prefix + 'Clr/Core.cs'] = b'new qualified core'
        cases = [{'sql_version': v, 'compatibility_level': cl, 'deployment_mode': mode, 'result': 'PASS'}
                 for v, levels in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170)))
                 for cl in levels for mode in ('local', 'central')]
        build = {'result': 'PASS', 'cases': cases,
                 'native_source_sha256': {p: release.sha(b) for p, b in current.items()}}
        current[release.SSIS_BUILD_QUALIFICATION] = release.encoded(build)
        changed = sorted(p for p in set(previous) | set(current) if previous.get(p) != current.get(p))
        record = {'schema_version': '1.0', 'publication_authorized': False, 'changed_product_paths': changed,
                  'previous_source_sha256': {p: release.sha(previous[p]) if p in previous else None for p in changed},
                  'current_source_sha256': {p: release.sha(current[p]) for p in changed},
                  'build_qualification_sha256': release.sha(current[release.SSIS_BUILD_QUALIFICATION])}
        return previous, current, record, build

    def test_ssis_delta_keeps_other_runtime_bytes_and_exact_build_binding(self):
        old, new, record, build = self.inputs()
        self.assertEqual(release.validate_ssis_product_delta(old, new, record, build, old),
                         set(record['changed_product_paths']))
        for path in ('Modules/toolbelt.synthetic/Source/Test.sql',
                     'Modules/toolbelt.tsql.ssis-debug/Clr/Core.cs',
                     'Modules/toolbelt.tsql.ssis-debug/Contracts/DependencyPins.json'):
            old, new, record, build = self.inputs()
            new[path] += b'changed'
            changed = sorted(p for p in set(old) | set(new) if old.get(p) != new.get(p))
            record['changed_product_paths'] = changed
            record['previous_source_sha256'] = {p: release.sha(old[p]) if p in old else None for p in changed}
            record['current_source_sha256'] = {p: release.sha(new[p]) for p in changed}
            with self.subTest(path=path), self.assertRaises(release.ReleaseError):
                release.validate_ssis_product_delta(old, new, record, build, old)

    def test_ssis_delta_does_not_accept_partial_matrix_or_publication(self):
        for mutation in ('missing_case', 'failed_case', 'publication'):
            old, new, record, build = self.inputs()
            if mutation == 'missing_case':
                build['cases'].pop()
            elif mutation == 'failed_case':
                build['cases'][0]['result'] = 'not executed'
            else:
                record['publication_authorized'] = True
            new[release.SSIS_BUILD_QUALIFICATION] = release.encoded(build)
            record['current_source_sha256'][release.SSIS_BUILD_QUALIFICATION] = release.sha(new[release.SSIS_BUILD_QUALIFICATION])
            record['build_qualification_sha256'] = release.sha(new[release.SSIS_BUILD_QUALIFICATION])
            with self.subTest(mutation=mutation), self.assertRaises(release.ReleaseError):
                release.validate_ssis_product_delta(old, new, record, build, old)

    def test_qualification_selection_stays_closed(self):
        self.assertEqual(release.clr_qualification_path({}), 'Releases/1.0.0/clr-qualification.json')
        self.assertEqual(release.clr_qualification_path({'qualification_evidence': release.SSIS_CLR_QUALIFICATION}),
                         release.SSIS_CLR_QUALIFICATION)
        with self.assertRaises(release.ReleaseError):
            release.clr_qualification_path({'qualification_evidence': '../unqualified.json'})


class ClrPackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(ROOT / 'Scripts/Release'))
        import prepare_clr_package
        cls.clr = prepare_clr_package
        cls.package = ROOT / prepare_clr_package.LOCATION

    def test_regex_permission_documentation_delta_rejects_runtime_or_metadata_drift(self):
        prefix = 'Modules/toolbelt.string.regex/'
        core = b'-- Dependencies: SAFE Toolbelt_String_Regex; Rechte: SELECT/REFERENCES.\n'
        facade = b'-- Dependencies: interner SAFE-CLR-Kern; Rechte: SELECT/REFERENCES.\n'
        manifest = b'version: "1.3.0"\npermissions_required:\n  - "SELECT oder REFERENCES auf den Regex-Skalarfunktionen"\nvalidation_evidence:\n'
        old = {prefix+'Source/RegexFunctions.sql': core*2+facade*2,
               prefix+'Source/RegexCaptures.sql': facade,
               prefix+'module.yaml': manifest, 'Modules/Contoso/Source/fixture.sql': b'SELECT 1;'}
        current = dict(old)
        for p in (prefix+'Source/RegexFunctions.sql', prefix+'Source/RegexCaptures.sql'):
            current[p] = old[p].replace(core.rstrip(b'\n'), b'-- Dependencies: SAFE Toolbelt_String_Regex; keine direkten Fachcallergrants.').replace(
                facade.rstrip(b'\n'), b'-- Dependencies: interner SAFE-CLR-Kern; Rechte: EXECUTE auf dieser Fassade.')
        current[prefix+'module.yaml'] = manifest.replace(b'SELECT oder REFERENCES auf den Regex-Skalarfunktionen',
            'EXECUTE auf den öffentlichen Regex-Skalarfunktionen; keine direkten Fachcallergrants auf interne CLR-Kerne'.encode()) + (
            b'\n  - date: "2026-10-24"\n    workflow: "synthetic fixture"\n    scope: "synthetic proof"\n    result: "success"\n')
        release.validate_regex_documentation_delta(old, current)
        for path, data in (
            (prefix+'Source/RegexFunctions.sql', current[prefix+'Source/RegexFunctions.sql']+b'SELECT 2;'),
            (prefix+'module.yaml', current[prefix+'module.yaml'].replace(b'1.3.0', b'9.0.0')),
            (prefix+'module.yaml', current[prefix+'module.yaml']+b'objects: []\n'),
            ('Modules/Contoso/Source/fixture.sql', b'SELECT 2;')):
            changed = dict(current, **{path: data})
            with self.subTest(path=path, data=data[-30:]), self.assertRaises(release.ReleaseError):
                release.validate_regex_documentation_delta(old, changed)

    def test_exact_scalar_rights_report_keeps_scope_and_source_bindings(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/regex-scalar-rights-qualification.json').read_bytes())
        self.assertFalse(report['publication_authorized'])
        self.assertEqual(report['result'], 'PASS')
        self.assertEqual(len(report['public_scalar_apis']), 6)
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        cases = report['native_cases']
        self.assertEqual(len(cases), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in cases}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['independent_cleanup_and_pin_audit']
                            and c['contexts'] == ['local', 'direct_central'] for c in cases))
        self.assertEqual(report['positive_value_probes'], 144)
        self.assertEqual(report['strict_permission_denial_probes'], 720)
        self.assertEqual(report['expected_denial_sql_number'], 229)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-value', 'extra-reference'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['expected_sql_number'] == 52094
                            and c['independent_cleanup_and_pin_audit'] for c in report['oracle_rejection_controls']))
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest)
        self.assertEqual(report['final_independent_audit']['positive_case_database_names_absent'], 36)
        self.assertTrue(report['final_independent_audit']['temporary_clr_configuration_restored'])
        self.assertTrue(report['remaining_gates'])

    def test_assembly_line_continuation_preserves_exact_binary_and_other_sql(self):
        binary = bytes(range(256)) * 48
        literal = b'0x' + binary.hex().encode('ascii')
        source = b"-- unveraenderter Kontext\nDECLARE @B varbinary(max)=" + literal + b";\nSELECT 0x1234, N'Contoso';\n"
        actual = self.clr.format_assembly_literals(source, [{'_bytes': binary}])
        self.assertLess(max(map(len, actual.splitlines())), 4200)
        self.assertEqual(actual.replace(b'\\\n', b''), source)
        self.assertEqual(self.clr.format_assembly_literals(actual, [{'_bytes': binary}]), actual)
        self.assertEqual(self.clr.format_assembly_literals(source, [{'_bytes': b'other'}]), source)
        for newline in (b'\n', b'\r\n'):
            token = actual[actual.index(b'0x'):actual.index(b';')].replace(b'\\\n', b'\\' + newline)
            self.assertEqual(bytes.fromhex(token[2:].replace(b'\\' + newline, b'').decode('ascii')), binary)

    def test_native_odbc_followup_binds_client_payload_and_cleanup_scope(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/clr-client-qualification.json').read_bytes())
        qualification = json.loads((ROOT / self.clr.QUALIFICATION).read_bytes())
        self.assertFalse(report['publication_authorized'])
        self.assertEqual(report['result'], 'PASS')
        self.assertEqual(report['authentication'], 'explicit SQL credential')
        self.assertEqual(report['windows_integrated_authentication'], 'not executed')
        self.assertTrue(report['encrypt'])
        self.assertEqual(report['trust'], 'explicit schema-validated Functional Lab value')
        self.assertFalse(report['fallback'])
        self.assertEqual(report['limits'], {'work_seconds': 300, 'cleanup_deadline_seconds': 360, 'outer_watchdog_seconds': 400})
        sources = self.clr.release.clr_qualification_method_sources(qualification, report['source_sha256'])
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256(sources[path]).hexdigest(), digest)
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertEqual(len(report['native_cases']), 12)
        self.assertTrue(all(c['result'] == 'PASS' and c['independent_cleanup_and_pin_audit']
                            and c['deployment_modes'] == ['local', 'central'] for c in report['native_cases']))
        self.assertEqual(report['final_independent_audit']['current_owned_database_names_absent'], 36)
        self.assertTrue(report['final_independent_audit']['temporary_clr_configuration_restored'])
        self.assertEqual(qualification['client_followup']['evidence'], 'Releases/1.0.0/clr-client-qualification.json')
        with zipfile.ZipFile(self.package) as archive:
            prefix = self.clr.PACKAGE + '/'
            sql = {p[len(prefix):]: archive.read(p) for p in archive.namelist() if p.startswith(prefix + 'SQL/')}
            binaries = {p[len(prefix):]: hashlib.sha512(archive.read(p)).hexdigest()
                        for p in archive.namelist() if p.startswith(prefix + 'Binaries/')}
        self.assertEqual(report['sql_payload_sha256'], {p: hashlib.sha256(b).hexdigest() for p, b in sql.items()})
        normalized = report.get('normalized_current_source_sql_payload_sha256', report['normalized_prior_sql_payload_sha256'])
        self.assertEqual(normalized,
                         {p: hashlib.sha256(b.replace(b'\\\n', b'')).hexdigest() for p, b in sql.items()})
        self.assertEqual(report['binary_sha512'], binaries)
        self.assertTrue(all(max(map(len, b.splitlines())) < 8192 for b in sql.values()))

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
        sources=self.clr.release.clr_qualification_method_sources(qualification)
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
        for name in ('Sources/Modules/toolbelt.tsql.ssis-debug/Tests/Static/validate_install_package.py', 'Install-ClrPackage.ps1'):
            changed = dict(payload)
            changed[name] += b'# changed method input\n'
            with self.subTest(method=name), self.assertRaisesRegex(self.clr.release.ReleaseError, 'Paketmethodenquelle'):
                self.clr.release.validate_clr_qualification(changed,qualification,sources)

    def test_historical_clr_method_recovery_rejects_other_product(self):
        qualification = json.loads((ROOT / self.clr.QUALIFICATION).read_bytes())
        qualification['product_commit'] = '0' * 40
        with self.assertRaisesRegex(self.clr.release.ReleaseError, 'Recoveryprodukt'):
            self.clr.release.clr_qualification_method_sources(qualification)


class ApiQualificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(ROOT / 'Tests/Release'))
        import prepare_api_qualification
        cls.api = prepare_api_qualification

    def test_table_envelope_qualification_binds_matrix_oracles_and_unchanged_payload(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/table-envelope-rights-qualification.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        self.assertFalse(report['publication_authorized'])
        self.assertFalse(report['runtime_product_sql_dll_changed'])
        self.assertFalse(report['module_statuses_changed'])
        plan = json.loads((ROOT / 'Releases/1.0.0/release-plan.json').read_bytes())
        self.assertEqual(report['product_commit'], plan['product_commit'])
        expected = {(p, v, cl) for p in ('windows', 'linux') for v, cls in
                    {'2019': [150], '2022': [150, 160], '2025': [150, 160, 170]}.items() for cl in cls}
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_pin_audit'] for c in report['native_cases']))
        self.assertEqual((report['profile_scenarios_passed'], report['positive_value_profile_scenarios'],
                          report['atomic_metadata_rejections'], report['strict_permission_denial_probes']),
                         (120, 96, 24, 360))
        self.assertEqual(report['expected_permission_denial_sql_number'], 229)
        self.assertEqual(len(report['profiles']), 5)
        self.assertEqual(report['profiles'][2]['expected_sql_number'], 51023)
        control = report['shape_rejection_control']
        self.assertEqual((control['actual_state'], control['expected_sql_number']), ('FAILED_CLEANED', 52096))
        self.assertTrue(control['executed_after_corrected_baseline_pass'] and control['independent_cleanup_pin_audit'])
        historical = report['historical_extra_view_guard']
        self.assertFalse(historical['replayed'])
        self.assertEqual((historical['actual_state'], historical['expected_sql_number']), ('FAILED_CLEANED', 52096))
        investigation = json.loads((ROOT / report['initial_investigation']).read_bytes())
        self.assertEqual(historical['applicability'], investigation['extra_view_guard_applicability'])
        self.assertEqual(len(report['previous_attempts']), 4)
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['original_bytes_preserved_and_reaudited']
                            and c['cleanup_reaudit'] for c in report['previous_attempts']))
        audit = report['final_independent_audit']
        self.assertEqual((audit['corrected_case_audits'], audit['historical_original_input_and_cleanup_reaudits'],
                          audit['configuration_scopes_audited']), (13, 4, 6))
        self.assertEqual((audit['all_scope_database_names_absent'], audit['all_scope_trust_states_restored']), (51, 177))
        self.assertTrue(audit['own_configuration_restored'] and audit['current_and_historical_input_bindings_separated'])
        self.assertEqual(report['limits'], {'work_seconds': 300, 'cleanup_deadline_seconds': 360, 'outer_watchdog_seconds': 400})
        self.assertTrue(report['functional_transport']['encrypt_required'])
        self.assertTrue(report['functional_transport']['explicit_lab_trust_preserved'])
        self.assertFalse(report['functional_transport']['authenticated_tls_claim'])
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest)
        complete = json.loads((ROOT / 'Releases/1.0.0/complete-qualification.json').read_bytes())
        self.assertEqual(report['qualification_package_sql_sha256'], complete['sql_payload_sha256'])
        evidence = json.loads((ROOT / 'Releases/1.0.0/evidence-map.json').read_bytes())
        for row in evidence['modules']:
            if row['module_id'] in report['modules']:
                self.assertEqual(row['additional_rights_evidence'], 'Releases/1.0.0/table-envelope-rights-qualification.json')
                self.assertEqual(row['historical_rights_investigation'], report['initial_investigation'])
        self.assertTrue(report['remaining_gates'])

    def test_table_envelope_historical_diagnosis_preserves_original_failed_inputs(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/table-envelope-rights-investigation.json').read_bytes())
        self.assertIn('historical', report['record_role'])
        self.assertEqual(report['followup_qualification'], 'Releases/1.0.0/table-envelope-rights-qualification.json')
        self.assertEqual(report['result'], 'not qualified')
        self.assertFalse(report['publication_authorized'])
        self.assertFalse(report['runtime_product_changed'])
        self.assertFalse(report['module_statuses_changed'])
        self.assertEqual(report['corrected_native_qualification'], 'not executed')
        self.assertEqual(report['fully_passed_positive_cases'], 0)
        self.assertEqual(len(report['attempts']), 4)
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['sql_number'] == 52096
                            and c['independent_cleanup_and_original_pin_audit'] for c in report['attempts']))
        self.assertEqual(sum(c['database_names_absent'] for c in report['attempts']), 12)
        self.assertEqual(sum(c['trust_states_restored'] for c in report['attempts']), 36)
        corrected = (ROOT / report['fixture_path']).read_bytes()
        self.assertEqual(hashlib.sha256(corrected).hexdigest(), report['corrected_fixture_sha256'])
        start = corrected.index(b'DECLARE @Shape nvarchar(max)=')
        end = corrected.index(b'DECLARE @Profiles table', start)
        capture = report['capture_context_correction']
        intermediate = corrected.replace(capture['corrected_literal'].encode(), capture['original_literal'].encode())
        self.assertEqual(hashlib.sha256(intermediate).hexdigest(), report['intermediate_fixture_sha256'])
        historical = (corrected[:start] + report['historical_shape_declaration'].encode('utf-8') + corrected[end:]).replace(
            capture['corrected_literal'].encode(), capture['original_literal'].encode())
        self.assertNotEqual(corrected, historical)
        self.assertEqual(hashlib.sha256(historical).hexdigest(), report['original_fixture_sha256'])
        self.assertEqual(hashlib.sha256((corrected[:start] + corrected[end:]).replace(
            capture['corrected_literal'].encode(), capture['original_literal'].encode())).hexdigest(),
                         report['extra_view_guard_applicability']['unchanged_source_after_declared_test_deltas_sha256'])
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest)
        self.assertEqual(report['required_followup']['positive_target_cl_cases'], 12)
        self.assertEqual(report['required_followup']['fresh_standalone_oracle_controls'], 1)
        self.assertTrue(report['known_documentation_gap'])

    def test_queue_worker_rights_binds_tokens_and_populated_blocker_states(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/queue-worker-rights-qualification.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        for flag in ('publication_authorized', 'product_sources_changed', 'module_status_changed', 'package_payload_changed',
                     'managed_qualified', 'worker_host_provider_qualified', 'resulttable_worker_paths_qualified', 'barrier_snapshot_creation_qualified'):
            self.assertIs(report[flag], False)
        self.assertTrue(report['fixed_own_claim_policy_required'])
        self.assertTrue(report['claim_requires_handler_execute'])
        self.assertEqual(report['public_apis'], {name: ('SELECT' if name.startswith('VW_') else 'EXECUTE') for name in
                         ('USP_ClaimWork', 'USP_RenewWorkLease', 'USP_RecoverExpiredWork', 'USP_CompleteWork',
                          'USP_FailWork', 'USP_ScheduleWorkRetry', 'USP_RequeueDeadLetter', 'VW_WorkQueueBarrierBlockers')})
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_and_pin_audit'] for c in report['native_cases']))
        for field, total in [('positive_api_profiles', 192), ('strict_sql229_denials', 4776), ('strict_wrong_token_denials', 96),
                             ('no_claim_reservations_without_handler_execute', 24), ('populated_barrier_view_states', 48)]:
            self.assertEqual(report[field], total)
            self.assertEqual(sum(c[field] for c in report['native_cases']), total)
        self.assertEqual(report['single_grant_api_profiles'], 168)
        self.assertEqual(report['claim_with_handler_execute_profiles'], 24)
        self.assertEqual(set(report['wrong_token_error_numbers'].values()), {51952, 51923, 51928, 51987})
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-value', 'extra-object'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['independent_cleanup_and_pin_audit']
                            for c in report['oracle_rejection_controls']))
        self.assertEqual(report['final_independent_audit']['all_attempt_databases_absent'], 26)
        self.assertTrue(report['remaining_gates'])

    def test_split_cl_completion_reuses_only_identical_bound_inputs(self):
        import hashlib
        prior_path = ROOT / 'Releases/1.0.0/split-advanced-rights-qualification.json'
        prior = json.loads(prior_path.read_bytes())
        report = json.loads((ROOT / 'Releases/1.0.0/split-advanced-cl-completion.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        self.assertTrue(report['caller_profile_cl_matrix_complete'])
        self.assertEqual(report['reused_report_sha256'], hashlib.sha256(prior_path.read_bytes()).hexdigest())
        self.assertEqual(report['reused_native_cases'], prior['native_cases'])
        self.assertEqual(report['source_sha256'], prior['source_sha256'])
        self.assertEqual(report['offline_export_sha256'], prior['offline_export_sha256'])
        self.assertEqual(report['reused_oracle_controls'], prior['oracle_rejection_controls'])
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        all_cases = report['new_native_cases'] + report['reused_native_cases']
        self.assertEqual(len(report['new_native_cases']), 6)
        self.assertEqual(len(all_cases), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in all_cases}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_and_pin_audit'] for c in all_cases))
        for field, total in [('positive_api_profiles', 96), ('strict_sql229_denials', 456), ('strict_sql51680_business_denials', 48)]:
            self.assertEqual(report['combined_totals'][field], total)
            self.assertEqual(sum(c[field] for c in all_cases), total)
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual(report['final_independent_audit']['new_case_databases_absent'], 12)
        self.assertFalse(report['publication_authorized'])
        self.assertTrue(report['remaining_gates'])

    def test_split_rights_binds_selected_targets_without_full_cl_matrix_claim(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/split-advanced-rights-qualification.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        for flag in ('publication_authorized', 'module_status_changed', 'product_sources_changed', 'package_payload_changed', 'full_cl_matrix_qualified'):
            self.assertIs(report[flag], False)
        self.assertEqual(report['module_versions'], {'toolbelt.core.result-table': '1.0.0', 'toolbelt.string.split-advanced': '1.1.0'})
        self.assertEqual(report['public_apis'], {'TVF_SplitAdvanced': 'SELECT', 'TVF_UnquoteToken': 'SELECT', 'USP_SplitAdvanced': 'EXECUTE'})
        expected = {(p, v, cl) for p in ('linux', 'windows') for v, cl in (('2019', 150), ('2022', 160), ('2025', 170))}
        self.assertEqual(len(report['native_cases']), 6)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        missing = {(p, v, cl) for p in ('linux', 'windows') for v, cl in (('2022', 150), ('2025', 150), ('2025', 160))}
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['unexecuted_compatibility_combinations']}, missing)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_and_pin_audit'] for c in report['native_cases']))
        for field, total in [('positive_api_profiles', 48), ('strict_sql229_denials', 228), ('strict_sql51680_business_denials', 24)]:
            self.assertEqual(report[field], total)
            self.assertEqual(sum(c[field] for c in report['native_cases']), total)
        self.assertEqual(report['single_grant_api_profiles'], 36)
        self.assertEqual(report['usp_with_helper_profiles'], 12)
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-value', 'extra-object'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['independent_cleanup_and_pin_audit']
                            for c in report['oracle_rejection_controls']))
        self.assertEqual(report['final_independent_audit']['all_attempt_databases_absent'], 14)
        self.assertTrue(report['remaining_gates'])

    def test_queue_frontend_rights_binds_producer_policy_and_narrow_view_scope(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/queue-frontend-rights-qualification.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        for flag in ('publication_authorized', 'module_status_changed', 'product_sources_changed', 'package_payload_changed'):
            self.assertIs(report[flag], False)
        self.assertEqual(report['module_versions'], {'toolbelt.core.result-table': '1.0.0',
                          'toolbelt.core.work-type': '1.2.0', 'toolbelt.core.work-queue': '2.1.0'})
        self.assertEqual(report['public_apis'], {name: ('SELECT' if name.startswith('VW_') else 'EXECUTE') for name in
                         ('USP_EnqueueWork', 'USP_EnqueueWorkWithPolicy', 'USP_EnqueueBarrierWork',
                          'USP_GetWorkStatus', 'VW_WorkQueue', 'VW_WorkQueueBarrierBlockers')})
        self.assertTrue(report['fixed_own_enqueue_policy_required'])
        self.assertEqual(report['single_grant_api_profiles'], 120)
        self.assertEqual(report['legacy_producer_with_metadata_profiles'], 24)
        self.assertEqual(report['strict_sql51902_metadata_denials'], 24)
        self.assertEqual(report['barrier_view_scope'], 'empty public view and metadata only')
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_and_pin_audit'] for c in report['native_cases']))
        for field, total in [('positive_api_profiles', 144), ('strict_sql229_denials', 3456)]:
            self.assertEqual(report[field], total)
            self.assertEqual(sum(c[field] for c in report['native_cases']), total)
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-value', 'extra-object'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['independent_cleanup_and_pin_audit']
                            for c in report['oracle_rejection_controls']))
        self.assertEqual(report['final_independent_audit']['all_attempt_databases_absent'], 27)
        self.assertEqual(report['initial_unaccepted_fixture_attempts'], 1)
        self.assertTrue(report['remaining_gates'])

    def test_deterministic_rights_binds_single_grants_and_separate_helper_profile(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/deterministic-rights-qualification.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        for flag in ('publication_authorized', 'module_status_changed', 'product_sources_changed', 'package_payload_changed'):
            self.assertIs(report[flag], False)
        self.assertEqual(report['module_versions'], {'toolbelt.core.result-table': '1.0.0',
                                                     'toolbelt.pseudonymization.deterministic': '1.2.0'})
        self.assertEqual(report['public_apis'], {name: ('EXECUTE' if name.startswith('USP_') else 'SELECT')
                         for name in ('TVF_DeterministicRange', 'TVF_DeterministicDateShift',
                                      'TVF_DeterministicTranslate', 'TVF_DeterministicGeoJitter', 'USP_DeterministicLookup')})
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_and_pin_audit'] for c in report['native_cases']))
        for field, total in [('positive_api_profiles', 144), ('strict_sql229_denials', 1416)]:
            self.assertEqual(report[field], total)
            self.assertEqual(sum(c[field] for c in report['native_cases']), total)
        self.assertEqual(report['single_grant_api_profiles'], 120)
        self.assertEqual(report['lookup_with_helper_profiles'], 24)
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-value', 'extra-object'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['independent_cleanup_and_pin_audit']
                            for c in report['oracle_rejection_controls']))
        self.assertEqual(report['final_independent_audit']['all_attempt_databases_absent'], 26)
        self.assertTrue(report['remaining_gates'])

    def test_cancellation_rights_binds_isolated_api_and_denial_scope(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/cancellation-rights-qualification.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        for flag in ('publication_authorized', 'module_status_changed', 'product_sources_changed', 'package_payload_changed'):
            self.assertIs(report[flag], False)
        self.assertEqual(report['public_apis'], {'USP_RequestExecutionCancellation': 'EXECUTE',
                                               'TVF_ExecutionCancellationStatus': 'SELECT', 'SVF_IsCancellationRequested': 'EXECUTE'})
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_and_pin_audit'] for c in report['native_cases']))
        for field, total in [('positive_api_profiles', 72), ('strict_sql229_denials', 432)]:
            self.assertEqual(report[field], total)
            self.assertEqual(sum(c[field] for c in report['native_cases']), total)
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-value', 'extra-object'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['independent_cleanup_and_pin_audit']
                            for c in report['oracle_rejection_controls']))
        self.assertEqual(report['final_independent_audit']['all_attempt_databases_absent'], 26)
        self.assertTrue(report['remaining_gates'])

    def test_safe_cast_rights_binds_isolated_profiles_and_source_bytes(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/safe-cast-rights-qualification.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        for flag in ('publication_authorized', 'module_status_changed', 'product_sources_changed', 'package_payload_changed'):
            self.assertIs(report[flag], False)
        self.assertEqual(report['module_versions'], {'toolbelt.conversion.safe-cast': '1.0.0'})
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_and_pin_audit'] for c in report['native_cases']))
        self.assertEqual(set(report['public_apis']), {'TVF_TryCastBigInt', 'TVF_TryCastDecimal', 'TVF_TryCastDate',
                                                    'TVF_TryCastDateTime2', 'TVF_TryCastBit', 'TVF_TryCastUniqueIdentifier'})
        for field, total in [('positive_api_profiles', 144), ('value_cases', 1008), ('strict_sql229_denials', 1008)]:
            self.assertEqual(report[field], total)
            self.assertEqual(sum(c[field] for c in report['native_cases']), total)
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-value', 'extra-object'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['independent_cleanup_and_pin_audit']
                            for c in report['oracle_rejection_controls']))
        audit = report['final_independent_audit']
        self.assertEqual((audit['terminal_attempts_audited'], audit['all_attempt_databases_absent']), (14, 26))
        self.assertTrue(audit['fresh_after_all_consumers'])
        self.assertFalse(audit['server_configuration_changes'] or audit['assembly_trust_changes'])
        self.assertTrue(report['remaining_gates'])

    def test_queue_authorization_binds_consumed_fixture_and_keeps_scope_narrow(self):
        import hashlib
        import prepare_queue_authorization as queue
        report = json.loads((ROOT / 'Releases/1.0.0/queue-authorization-qualification.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        for flag in ('publication_authorized', 'module_status_changed', 'product_sources_changed', 'package_payload_changed'):
            self.assertIs(report[flag], False)
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_and_pin_audit'] for c in report['native_cases']))
        self.assertEqual(report['qualified_database_contexts'], 24)
        self.assertEqual(report['expected_strict_denials'], {'51998': 48, '51997': 24})
        self.assertEqual(report['visible_nonexecutable_handler_empty_claim_contexts'], 24)
        self.assertEqual(report['executable_handler_positive_claim_contexts'], 24)
        self.assertEqual(hashlib.sha256(queue.fixture_bytes()).hexdigest(), report['fixture_sha256'])
        self.assertTrue(report['canonical_contract_unchanged'])
        self.assertTrue(report['generation_applicability']['fixture_bytes_unchanged'])
        self.assertFalse(report['generation_applicability']['native_sql_or_harness_changed'])
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-policy-error', 'wrong-claim-count'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['independent_cleanup_and_pin_audit']
                            for c in report['oracle_rejection_controls']))
        audit = report['final_independent_audit']
        self.assertEqual((audit['terminal_attempts_audited'], audit['all_attempt_databases_absent']), (14, 26))
        self.assertTrue(audit['fresh_after_all_consumers'])
        self.assertFalse(audit['server_configuration_changes'] or audit['assembly_trust_changes'])
        self.assertTrue(report['remaining_gates'])

    def test_queue_fixture_builder_rejects_runtime_alias_before_resolved_output(self):
        import tempfile
        from types import SimpleNamespace
        from unittest import mock
        import prepare_queue_authorization as queue
        with tempfile.TemporaryDirectory() as temp:
            project = Path(temp) / 'project'
            runtime = project / '.runtime'
            runtime.mkdir(parents=True)
            outside = Path(temp) / 'outside'
            outside.mkdir()
            output = outside / 'fixture.sql'
            resolve = Path.resolve
            is_symlink = Path.is_symlink
            lstat = Path.lstat
            # Die nominelle Runtime verweist nach aussen. Nur der aufgeloeste
            # Ausgabepfad wuerde die urspruengliche Aliasidentitaet verlieren.
            def alias_resolution(path, *args, **kwargs):
                return outside if path == runtime else resolve(path, *args, **kwargs)
            for style in ('symbolic', 'windows-reparse'):
                def runtime_alias(path):
                    return style == 'symbolic' if path == runtime else is_symlink(path)
                def alias_stat(path, *args, **kwargs):
                    if path == runtime and style == 'windows-reparse':
                        return SimpleNamespace(st_file_attributes=0x400)
                    return lstat(path, *args, **kwargs)
                with mock.patch.object(queue, 'ROOT', project), \
                        mock.patch.object(Path, 'resolve', alias_resolution), \
                        mock.patch.object(Path, 'is_symlink', runtime_alias), \
                        mock.patch.object(Path, 'lstat', alias_stat), \
                        mock.patch('sys.argv', ['queue-fixture', '--output', str(output)]):
                    with self.assertRaisesRegex(SystemExit, 'QUEUE_AUTH_REPARSE_RUNTIME_REJECTED'):
                        queue.main()
            self.assertFalse(output.exists())

    def test_work_type_rights_preserves_exact_scope_sources_and_failed_controls(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/work-type-rights-qualification.json').read_bytes())
        self.assertEqual(report['result'], 'PASS')
        for flag in ('publication_authorized', 'module_status_changed', 'product_sources_changed', 'package_payload_changed'):
            self.assertIs(report[flag], False)
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['contexts'] == ['local', 'direct_central']
                            and c['independent_cleanup_and_pin_audit'] for c in report['native_cases']))
        self.assertEqual(sum(c['positive_api_profiles'] for c in report['native_cases']), report['positive_api_profiles'])
        self.assertEqual(report['positive_api_profiles'], 144)
        self.assertEqual(sum(c['strict_denials'] for c in report['native_cases']), report['strict_denial_probes'])
        self.assertEqual(report['expected_denial_sql_numbers'], {'229': 1296, '51509': 24, '51534': 24, '51591': 24})
        self.assertEqual(report['strict_denial_probes'], sum(report['expected_denial_sql_numbers'].values()))
        apis = {a['name']: a for a in report['public_apis']}
        self.assertEqual(set(apis), {'USP_RegisterWorkType', 'USP_DisableWorkType', 'USP_RemoveWorkType',
                                     'USP_ResolveWorkType', 'VW_WorkTypes', 'USP_SetWorkTypePermission'})
        self.assertEqual(apis['VW_WorkTypes']['permission'], 'SELECT')
        self.assertEqual(apis['USP_SetWorkTypePermission']['additional_required_permission'], 'CONTROL on WorkTypePermission')
        self.assertTrue(all(a['permission'] == 'EXECUTE' for n, a in apis.items() if n != 'VW_WorkTypes'))
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-value', 'extra-api'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['independent_cleanup_and_pin_audit']
                            for c in report['oracle_rejection_controls']))
        self.assertEqual(report['historical_test_failure']['result'], 'FAILED_CLEANED')
        self.assertFalse(report['historical_test_failure']['product_failure'])
        audit = report['final_independent_audit']
        self.assertEqual((audit['positive_case_databases_absent'], audit['all_attempt_databases_absent'], audit['terminal_attempts_audited']), (24, 27, 15))
        self.assertTrue(audit['fresh_audit_after_all_consumers'])
        self.assertFalse(audit['server_configuration_changes'] or audit['assembly_trust_changes'])
        self.assertTrue(report['remaining_gates'])

    def test_execution_context_rights_report_binds_isolated_scope_and_current_payload(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/execution-context-rights-qualification.json').read_bytes())
        self.assertFalse(report['publication_authorized'])
        self.assertFalse(report['module_status_changed'])
        self.assertFalse(report['product_and_package_payload_changed'])
        self.assertEqual(report['result'], 'PASS')
        self.assertEqual({a['name']: a['permission'] for a in report['public_apis']}, {
            'USP_BeginExecution': 'EXECUTE', 'USP_SetExecutionContext': 'EXECUTE',
            'USP_EndExecution': 'EXECUTE', 'TVF_CurrentExecutionContext': 'SELECT',
            'SVF_CurrentExecutionId': 'EXECUTE'})
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for cl in cls}
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in report['native_cases']}, expected)
        self.assertTrue(all(c['result'] == 'PASS' and c['independent_cleanup_and_pin_audit']
                            and c['contexts'] == ['local', 'direct_central'] for c in report['native_cases']))
        self.assertEqual(report['positive_api_scenarios'], 120)
        self.assertEqual(report['strict_permission_denial_probes'], 720)
        self.assertEqual(report['expected_denial_sql_number'], 229)
        self.assertEqual({c['synthetic_fault'] for c in report['oracle_rejection_controls']}, {'wrong-depth', 'extra-object'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED' and c['expected_sql_number'] == 52095
                            and c['independent_cleanup_and_pin_audit'] for c in report['oracle_rejection_controls']))
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest)
        package = json.loads((ROOT / 'Releases/1.0.0/complete-qualification.json').read_bytes())
        self.assertEqual(report['product_commit'], package['product_commit'])
        self.assertEqual(report['qualification_package_sql_sha256'], package['sql_payload_sha256'])
        audit = report['final_independent_audit']
        self.assertEqual(audit['positive_case_database_names_absent'], 36)
        self.assertEqual(audit['positive_case_trust_states_restored'], 132)
        self.assertEqual(audit['configuration_scopes_audited'], 6)
        self.assertTrue(audit['temporary_clr_configuration_restored'] and audit['separate_configuration_audit'])
        self.assertTrue(report['remaining_gates'])

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

    def test_evidence_assignment_preserves_recorded_manifest_snapshot(self):
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
        # Auch die damals ausgeführten Fixtures gehören zum gebundenen Snapshot.
        # Neue Testadapter werden separat qualifiziert; die alte Ausführung bleibt unverändert.
        with zipfile.ZipFile(ROOT / 'Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip') as archive:
            for path, digest in api['fixture_source_sha256'].items():
                recorded = archive.read('SQL-Server-Toolbelt-1.0.0-candidate-source/' + path).replace(b'\r\n', b'\n')
                self.assertEqual(hashlib.sha256(recorded).hexdigest(), digest)
        module_results = {m['module_id']: m for m in api['module_results']}
        self.assertEqual(set(module_results), {t['module_id'] for t in spec['tests']})
        self.assertEqual(api['functional_calls_passed'], sum(c['passed_fixture_calls'] + c['reused_fixture_calls'] for c in cases.values()))
        self.assertEqual(api['functional_calls_blocked'], sum(len(c['blocked_fixture_calls']) for c in cases.values()))
        for key in ('all_owned_database_names_absent', 'trust_states_restored', 'current_input_pins_unchanged', 'configuration_restored', 'separate_configuration_audit'):
            self.assertTrue(api['final_independent_audit'][key])
        # Die Evidenzzuordnung gehört zum unveränderlichen Kandidatenpaket.
        # Spätere Moduländerungen werden separat qualifiziert und schreiben
        # dessen historische Manifestbindung nicht auf den aktuellen Stand um.
        with zipfile.ZipFile(ROOT / 'Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip') as archive:
            recorded_manifests = {m['manifest']: archive.read('SQL-Server-Toolbelt-1.0.0-candidate-source/' + m['manifest']) for m in report['modules']}
        for m in report['modules']:
            self.assertFalse(m['record_snapshot_is_execution_commit'])
            canonical = recorded_manifests[m['manifest']].replace(b'\r\n', b'\n')
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
                    manifest = json.loads(archive.read(release.NAME + '/PACKAGE-MANIFEST.json'))
                    bundle = archive.read(release.NAME + '/PREPARATION.bundle')
                self.assertEqual(hashlib.sha256(delivered.replace(b'\r\n', b'\n')).hexdigest(), current)
                # Der neue Paketstand liefert den aktuellen Treiber. Der
                # historische Nachweis verwendet sein eigenes altes Bundle;
                # ein frischer Checkout braucht keine unreferenzierten
                # früheren Snapshotobjekte im lokalen Git-Objektstore.
                if manifest['product_commit'] != report['product_commit']:
                    applicability = json.loads((ROOT / 'Releases/1.0.0/runtime-source-equivalence.json').read_bytes())
                    historical = release.git('show', applicability['public_baseline_commit'] + ':' + release.ARTIFACTS + release.NAME + '.zip')
                    self.assertEqual(hashlib.sha256(historical).hexdigest(), applicability['previous_source_zip_sha256'])
                    raw = release.read_zip(historical)
                    manifest = json.loads(raw[release.NAME + '/PACKAGE-MANIFEST.json'])
                    bundle = raw[release.NAME + '/PREPARATION.bundle']
                    self.assertEqual(manifest['product_commit'], report['product_commit'])
                _, product, _ = release.recovered_snapshot(bundle, manifest['source_commit'], report['product_commit'])
                self.assertEqual(hashlib.sha256(product[path].replace(b'\r\n', b'\n')).hexdigest(), digest)
            else:
                self.assertEqual(current, digest)
        data = release.read_zip((ROOT / release.CLR_PACKAGE).read_bytes())
        prefix = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
        binary = data[prefix + 'Binaries/Toolbelt.String.Regex.dll']
        self.assertEqual(hashlib.sha256(binary).hexdigest(), report['delivered_regex_binary_sha256'])
        current_plan = json.loads((ROOT / release.PLAN).read_bytes())
        if report['product_commit'] != current_plan['product_commit']:
            release.validate_regex_product_applicability(report['product_commit'], current_plan['product_commit'])
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

    def test_capture_release_acceptance_keeps_exact_binary_and_historical_failures(self):
        import hashlib
        report = json.loads((ROOT / 'Releases/1.0.0/capture-release-acceptance.json').read_bytes())
        self.assertEqual(report['qualification_state'], 'complete for stated binary and scope')
        self.assertEqual(report['historical_capture_timeout_gate'], 'accepted for exact qualified binary')
        self.assertEqual(report['historical_cause'], 'unknown, not reproduced')
        for flag in ('publication_authorized', 'product_correction_claimed',
                     'historical_timeout_reproduced', 'module_validation_status_promoted'):
            self.assertIs(report[flag], False)
        previous = json.loads((ROOT / 'Releases/1.0.0/regex-timeout-qualification.json').read_bytes())
        self.assertEqual(report['safety_limits'], previous['safety_limits'])
        self.assertEqual(report['delivered_regex_binary_sha256'], previous['delivered_regex_binary_sha256'])
        with zipfile.ZipFile(ROOT / release.CLR_PACKAGE) as archive:
            binary = archive.read('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.String.Regex.dll')
        self.assertEqual(hashlib.sha256(binary).hexdigest(), report['delivered_regex_binary_sha256'])
        for group in ('source_sha256', 'prior_evidence_sha256'):
            for path, digest in report[group].items():
                self.assertEqual(hashlib.sha256((ROOT / path).read_bytes().replace(b'\r\n', b'\n')).hexdigest(), digest)
        cases = report['minimal_rights']['native_cases']
        self.assertEqual(len(cases), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in cases},
                         {(p, v, cl) for p in ('linux', 'windows')
                          for v, cls in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170)))
                          for cl in cls})
        self.assertTrue(all(c['result'] == 'PASS' and c['independent_cleanup_and_pin_audit']
                            and c['deployment_contexts'] == ['local', 'direct_central'] for c in cases))
        self.assertEqual(report['minimal_rights']['public_scalar_execute_only'], 'PASS')
        self.assertEqual(report['minimal_rights']['effective_references_permission_in_positive_phase'], 0)
        controls = report['oracle_rejection_controls']
        self.assertEqual({c['synthetic_fault'] for c in controls}, {'wrong-value', 'wrong-error', 'extra-reference'})
        self.assertTrue(all(c['actual_state'] == 'FAILED_CLEANED'
                            and c['independent_cleanup_and_pin_audit'] for c in controls))
        self.assertFalse(report['earlier_rights_revision']['proves_execute_alone'])
        self.assertTrue(report['final_independent_audit']['all_owned_database_names_absent'])
        self.assertTrue(report['final_independent_audit']['temporary_clr_configuration_restored'])
        self.assertTrue(report['remaining_gates'])
        historical = json.loads((ROOT / 'Releases/1.0.0/capture-timeout-investigation.json').read_bytes())
        self.assertEqual(historical['capture_release_gate'], 'open')

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
