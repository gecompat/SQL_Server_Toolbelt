"""JSON-Pointer-Security: echte Admission ohne Lab/SQL, keine grünen Linux-local-Wiederholungen."""
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
DRIVER = ROOT / 'Tests/Release/Invoke-JsonPointerSecurityLab.ps1'


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class PointerSecurityAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='clone-planner-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('-- BEGIN MODULE toolbelt.json.pointer\nSELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        fixtures = [ROOT / ('Modules/toolbelt.json.pointer/Tests/Runtime/' + name) for name in ('Security.Contract.sql',)]
        files = [DRIVER, *fixtures, *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1'))]
        files += [ROOT / 'Modules/toolbelt.json.pointer/Deployment/Uninstall.sql']
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        cases = []
        for platform in ('windows', 'linux'):
            for version, patch, levels in (('2019', 'CU32', (150,)), ('2022', 'CU26', (150, 160)),
                                            ('2025', 'CU8', (150, 160, 170))):
                for level in levels:
                    cases.append(dict(Platform=platform, Version=version, Patch=patch if platform == 'windows' else 'latest',
                                      CL=level, modes=['local', 'central'] if platform == 'windows' else ['central']))
        self.record = dict(schema_version='json-pointer-security/v1', explicit_qualification_approved=True,
                           started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=45)).isoformat(),
                           fixtures=list(map(str, fixtures)), exports=exports, cases=cases,
                           pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record=None):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record or self.record), encoding='utf-8')
        result = subprocess.run(['pwsh', '-NoProfile', '-File', str(DRIVER), '-RunsetPath', str(path),
                                 '-CaseIndex', '11', '-ValidateOnly'], cwd=ROOT, capture_output=True, text=True, timeout=20)
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
        self.reject(lambda r: r['cases'][8].update(CL=150))

    def test_context_modes_cannot_replay_qualified_linux_local(self):
        self.reject(lambda r: r['cases'][0].update(modes=['central']))
        self.reject(lambda r: r['cases'][6].update(modes=['local','central']))
        self.reject(lambda r: r['cases'][11].update(modes=['local']))

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
            "$functions=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Assert-PointerSecurityFixtureScope'},$true));" + \
            "if($errors.Count-or$functions.Count-ne1){throw 'SCOPE_FUNCTION'};. ([scriptblock]::Create($functions[0].Extent.Text));" + \
            "Assert-PointerSecurityFixtureScope " + payload + ";'PASS fixture scope without SQL'"
        return subprocess.run(['pwsh', '-NoProfile', '-Command', script], cwd=ROOT, capture_output=True, text=True, timeout=20)

    def test_forbidden_fixture_rights_and_server_scope_rejected(self):
        for text in ('GRANT EXECUTE ON dbo.Synthetic TO Contoso;', 'CREATE USER Contoso WITHOUT LOGIN;',
                     'ALTER AUTHORIZATION ON SCHEMA::dbo TO Contoso;', 'ALTER DATABASE Synthetic SET TRUSTWORTHY ON;',
                     'EXEC sys.sp_configure N\'clr enabled\',1;', 'CREATE TRIGGER Synthetic ON ALL SERVER FOR CREATE_DATABASE AS SELECT 1;',
                     'CREATE ASSEMBLY Contoso FROM 0x00;'):
            result = self.scope(text)
            self.assertNotEqual(result.returncode, 0, text)
            self.assertIn('POINTER_SECURITY_FIXTURE_EXCEEDS_SCOPE', result.stdout + result.stderr)

    def test_all_original_fixtures_remain_permitted(self):
        for path in self.record['fixtures']:
            result = self.scope(path, from_file=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)



    def test_fixture_timeout_does_not_extend_work_or_cleanup_window(self):
        script = "$ErrorActionPreference='Stop';$e=$null;" + \
            "$a=[Management.Automation.Language.Parser]::ParseFile('" + str(DRIVER).replace("'", "''") + "',[ref]$null,[ref]$e);" + r"""
$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Get-ReleaseTimeout'},$true))
if($e.Count-or$n.Count-ne1){throw 'TIMEOUT_FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
$script:clock=[pscustomobject]@{ElapsedMilliseconds=0};$script:cleanup=$false;$script:securityWorkload=$false
if((Get-ReleaseTimeout)-ne45){throw 'NORMAL_TIMEOUT'}
$script:securityWorkload=$true;if((Get-ReleaseTimeout)-ne180){throw 'FIXTURE_TIMEOUT'}
$script:clock.ElapsedMilliseconds=299000;if((Get-ReleaseTimeout)-ne1){throw 'WORK_WINDOW'}
$script:clock.ElapsedMilliseconds=299001;$blocked=$false
try{Get-ReleaseTimeout|Out-Null}catch{if($_.Exception.Message-ne'RELEASE_DEADLINE'){throw};$blocked=$true}
if(-not$blocked){throw 'WORK_EXTENDED'}
$script:cleanup=$true;$script:clock.ElapsedMilliseconds=300000
if((Get-ReleaseTimeout)-ne45){throw 'CLEANUP_COMMAND_LIMIT'}
$script:clock.ElapsedMilliseconds=359000;if((Get-ReleaseTimeout)-ne1){throw 'CLEANUP_WINDOW'}
$script:clock.ElapsedMilliseconds=359001;$blocked=$false
try{Get-ReleaseTimeout|Out-Null}catch{if($_.Exception.Message-ne'RELEASE_DEADLINE'){throw};$blocked=$true}
if(-not$blocked){throw 'CLEANUP_EXTENDED'}
'PASS bounded timeout'
"""
        result = subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,
                                capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertIn('PASS bounded timeout',result.stdout)


if __name__ == '__main__':
    unittest.main()
