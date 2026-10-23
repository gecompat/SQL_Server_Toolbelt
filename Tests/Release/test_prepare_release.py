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
        plan = json.loads((ROOT / release.PLAN).read_bytes())
        self.assertEqual({m['module_id'] for m in report['modules']}, {m['module_id'] for m in plan['modules']})
        self.assertEqual(len(report['modules']), 45)
        self.assertFalse(report['module_statuses_changed'])
        self.assertFalse(report['publication_authorized'])
        for m in report['modules']:
            self.assertFalse(m['record_snapshot_is_execution_commit'])
            canonical = (ROOT / m['manifest']).read_bytes().replace(b'\r\n', b'\n')
            self.assertEqual(hashlib.sha256(canonical).hexdigest(), m['manifest_sha256'])

    @unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required for offline adapter guards')
    def test_target_reuse_and_cleanup_reserve_without_sql(self):
        script = r'''
$ErrorActionPreference='Stop'
$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile('Tests/Release/Invoke-ApiQualificationLab.ps1',[ref]$null,[ref]$e)
if($e.Count){throw 'PARSE'}
foreach($name in @('Test-ApiSelected','Get-ReleaseTimeout','Get-ApiCasePins','Assert-ReleaseInputs')){
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
'PASS OFFLINE_API_GUARDS'
'''
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', script], cwd=ROOT, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('PASS OFFLINE_API_GUARDS', result.stdout)


if __name__ == "__main__":
    unittest.main()
