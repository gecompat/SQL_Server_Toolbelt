"""BefÃƒÂ¼llter File-Content-Repeat: echte Admission ohne Lab/SQL."""
from pathlib import Path
from datetime import datetime, timedelta, timezone
import copy
import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / 'Tests/Release/Invoke-FileContentRepeatLab.ps1'


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class FileRepeatAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='clone-planner-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n-- BEGIN MODULE toolbelt.file.content\nSELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        fixtures = [ROOT / ('Modules/toolbelt.file.content/Tests/Runtime/' + name) for name in ('RepeatCurrent.Contract.sql', 'Lifecycle.Contract.sql')]
        files = [DRIVER, *fixtures, *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1'))]
        files += [ROOT / ('Modules/toolbelt.file.content/Tests/Runtime/' + n) for n in ('RepeatCurrent.Capture.sql','RepeatCurrent.Assert.sql')]
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        cases = []
        for platform in ('windows', 'linux'):
            for version, patch, levels in (('2019', 'CU32', (150,)), ('2022', 'CU26', (150, 160)),
                                            ('2025', 'CU8', (150, 160, 170))):
                for level in levels:
                    if platform == 'linux' and level == max(levels):
                        continue
                    cases.append(dict(Platform=platform, Version=version, Patch=patch if platform == 'windows' else 'latest',
                                      CL=level, modes=['local', 'central']))
        self.record = dict(schema_version='file-content-repeat-current/v1', explicit_qualification_approved=True,
                           started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=45)).isoformat(),
                           fixtures=list(map(str, fixtures)), exports=exports, cases=cases,
                           pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record=None):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record or self.record), encoding='utf-8')
        result = subprocess.run(['pwsh', '-NoProfile', '-File', str(DRIVER), '-RunsetPath', str(path),
                                 '-CaseIndex', '8', '-ValidateOnly'], cwd=ROOT, capture_output=True, text=True, timeout=20)
        self.assertEqual(list(self.directory.glob('case-*')), [])
        return result

    def reject(self, mutate):
        record = copy.deepcopy(self.record)
        mutate(record)
        result = self.admission(record)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_valid_scope_without_lab_import(self):
        result = self.admission()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('no Lab import or SQL', result.stdout)

    def test_authority_requires_boolean_true(self):
        self.reject(lambda r: r.update(explicit_qualification_approved=False))
        self.reject(lambda r: r.update(explicit_qualification_approved='true'))

    def test_deadline_expiry_and_extension(self):
        expired = datetime.now(timezone.utc) - timedelta(hours=2)
        self.reject(lambda r: r.update(started_utc=expired.isoformat(), deadline_utc=(expired + timedelta(minutes=45)).isoformat()))
        self.reject(lambda r: r.update(deadline_utc=(datetime.now(timezone.utc) + timedelta(hours=2)).isoformat()))

    def test_later_target_cannot_be_relabelled(self):
        self.reject(lambda r: r['cases'][8].update(Patch='base'))
        self.reject(lambda r: r['cases'][8].update(CL=170))

    def test_each_target_requires_both_declared_modes(self):
        for index in (0, 5, 6, 8):
            self.reject(lambda r: r['cases'][index].update(modes=['central']))

    def test_canonical_fixture_and_method_pins_are_mandatory(self):
        fixture = self.directory / 'imposter.sql'
        fixture.write_bytes(Path(self.record['fixtures'][0]).read_bytes())
        record = copy.deepcopy(self.record)
        record['fixtures'] = [str(fixture)]
        record['pins'].append(dict(path=str(fixture), sha256=hashlib.sha256(fixture.read_bytes()).hexdigest().upper()))
        self.assertNotEqual(self.admission(record).returncode, 0)
        self.reject(lambda r: r['pins'].pop(0))

    def test_changed_real_export_bytes_are_rejected(self):
        Path(self.record['exports']['local']).write_text('SELECT 2;\n', encoding='utf-8')
        self.assertNotEqual(self.admission().returncode, 0)

    def scope(self, text, from_file=False):
        quoted = "'" + str(text).replace("'", "''") + "'"
        payload = "([IO.File]::ReadAllText(" + quoted + "))" if from_file else quoted
        script = "$ErrorActionPreference='Stop';$errors=$null;" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile('" + str(DRIVER).replace("'", "''") + "',[ref]$null,[ref]$errors);" + \
            "$functions=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Assert-FileRepeatFixtureScope'},$true));" + \
            "if($errors.Count-or$functions.Count-ne1){throw 'SCOPE_FUNCTION'};. ([scriptblock]::Create($functions[0].Extent.Text));" + \
            "Assert-FileRepeatFixtureScope " + payload + ";'PASS fixture scope without SQL'"
        return subprocess.run(['pwsh', '-NoProfile', '-Command', script], cwd=ROOT, capture_output=True, text=True, timeout=20)

    def test_forbidden_fixture_rights_and_server_scope_rejected(self):
        for text in ('GRANT EXECUTE ON dbo.Synthetic TO Contoso;', 'CREATE USER Contoso WITHOUT LOGIN;',
                     'ALTER AUTHORIZATION ON SCHEMA::dbo TO Contoso;', 'ALTER DATABASE Synthetic SET TRUSTWORTHY ON;',
                     'EXEC sys.sp_configure N\'clr enabled\',1;', 'CREATE TRIGGER Synthetic ON ALL SERVER FOR CREATE_DATABASE AS SELECT 1;',
                     'CREATE ASSEMBLY Contoso FROM 0x00;'):
            result = self.scope(text)
            self.assertNotEqual(result.returncode, 0, text)
            self.assertIn('FILE_REPEAT_FIXTURE_EXCEEDS_SCOPE', result.stdout + result.stderr)

    def test_all_original_fixtures_remain_permitted(self):
        for path in self.record['fixtures']:
            result = self.scope(path, from_file=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def expand_repeat(self, fixture_text):
        fake = self.directory / 'synthetic-repo'
        deploy = fake / 'Modules/toolbelt.file.content/Deployment'
        runtime = fake / 'Modules/toolbelt.file.content/Tests/Runtime'
        deploy.mkdir(parents=True, exist_ok=True)
        runtime.mkdir(parents=True, exist_ok=True)
        (runtime / 'RepeatCurrent.Contract.sql').write_bytes(fixture_text.encode('utf-8'))
        (deploy / 'Deploy.sql').write_text("SELECT N'$(DeploymentMode)';", encoding='utf-8')
        quote = lambda p: "'" + str(p).replace("'", "''") + "'"
        script = "$ErrorActionPreference='Stop';$repo=" + quote(fake) + ";$errors=$null;" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile(" + quote(DRIVER) + ",[ref]$null,[ref]$errors);" + \
            "$f=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Get-FileRepeatText'},$true));" + \
            "if($errors.Count-or$f.Count-ne1){throw 'EXPANSION_FUNCTION'};. ([scriptblock]::Create($f[0].Extent.Text));Get-FileRepeatText 'central'"
        return subprocess.run(['pwsh', '-NoProfile', '-Command', script], cwd=ROOT, capture_output=True, text=True, timeout=20)

    def test_repeat_uses_fixed_deployment_working_directory(self):
        for newline in ('\n', '\r\n'):
            result = self.expand_repeat((':r Deploy.sql' + newline) * 2)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(result.stdout.count("SELECT N'central';"), 2)
            self.assertNotIn(':r ', result.stdout)

    def test_repeat_rejects_escape_cycle_and_dynamic_include(self):
        for include, expected in (('../../outside.sql', 'FILE_REPEAT_INCLUDE_OUTSIDE_OR_CYCLE'),
                                  ('../Tests/Runtime/RepeatCurrent.Contract.sql', 'FILE_REPEAT_INCLUDE_OUTSIDE_OR_CYCLE'),
                                  ('$(Input).sql', 'FILE_REPEAT_DYNAMIC_INCLUDE')):
            result = self.expand_repeat(':r ' + include + '\n')
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(expected, result.stdout + result.stderr)

    def test_fresh_audit_binds_original_target_journal_and_complete_witnesses(self):
        source = DRIVER.read_text(encoding='utf-8-sig')
        for guard in ('FILE_REPEAT_AUDIT_TARGET_DRIFT', 'originalJournalSHA256',
                      '$prior.witnesses.Count-eq2', '.compatibilityLevel-ne$case.CL',
                      'serverConfigurationAndTrustUnchanged', 'Assert-ReleaseOwnIdentity',
                      'FILE_REPEAT_PRODUCT_DEFINITION_DRIFT', 'FILE_REPEAT_UNEXPECTED_CLR',
                      'FILE_REPEAT_ACTUAL_CL', 'FILE_REPEAT_INCOMPLETE_FIXTURES'):
            self.assertIn(guard, source)
        self.assertNotRegex(source, r'(?i)\bEXEC(?:UTE)?\s+(?:sys\.)?sp_(?:configure|add_trusted_assembly)\b')
        self.assertLess(source.index('if($ValidateOnly)'), source.index('$lab=Resolve-LabContract'))


if __name__ == '__main__':
    unittest.main()
