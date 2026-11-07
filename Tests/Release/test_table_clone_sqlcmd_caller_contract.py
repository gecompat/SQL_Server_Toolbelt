"""Vollständige SQLCMD-Caller-Admission: ausschließlich verbindungslose Gegenproben."""
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
DRIVER = ROOT / 'Tests/Release/Invoke-TableCloneSqlcmdCallerLab.ps1'
UTF8_CONSOLE = '[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false);$OutputEncoding=[Console]::OutputEncoding;'


def ps_quote(value):
    return "'" + str(value).replace("'", "''") + "'"


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class CloneSqlcmdCallerAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='clone-sqlcmd-caller-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n-- BEGIN MODULE toolbelt.metadata.table-clone\nSELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        fixtures = [ROOT / ('Modules/toolbelt.metadata.table-clone/Tests/Runtime/' + name) for name in ('Lifecycle.CallerTransaction.Deploy.sql', 'Lifecycle.CallerTransaction.Uninstall.sql')]
        files = [DRIVER, *fixtures, *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1',
            'Tests/CI/Set-SqlClientTlsPolicy.ps1', 'Tests/CI/Assert-LabQualifiedTlsBinding.ps1',
            'Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql',
            'Modules/toolbelt.metadata.table-clone/Deployment/Deploy.sql',
            'Modules/toolbelt.metadata.table-clone/Deployment/Uninstall.sql',
            'Deployment/Deploy-All.ps1', 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'))]
        tool = self.directory / 'synthetic-sqlcmd.exe'
        tool.write_bytes(b'Synthetic fixture only; never executable')
        render = UTF8_CONSOLE + "$ErrorActionPreference='Stop';$e=$null;$repo=" + ps_quote(ROOT) + ";$folder=" + ps_quote(self.directory) + ";" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Deployment/Deploy-All.ps1'),[ref]$null,[ref]$e);" + \
            "foreach($name in @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){$n=@($ast.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'RENDER_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))};" + \
            "$texts=@{};foreach($mode in @('local','central')){$texts[$mode]=@{};foreach($kind in @('Deploy','Uninstall')){$texts[$mode][$kind]=@{};foreach($abort in @('OFF','ON')){" + \
            "$source=Join-Path $repo ('Modules/toolbelt.metadata.table-clone/Tests/Runtime/Lifecycle.CallerTransaction.'+$kind+'.sql');$node=Get-SqlcmdScriptTree -Path $source -Cache @{};" + \
            "$node.Text=$node.Text.Replace('SET XACT_ABORT ON;','SET XACT_ABORT '+$abort+';');$body=ConvertTo-StandaloneSql -Node $node -Values @{DeploymentMode=$mode;ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules');" + \
            "$out=Join-Path $folder ($mode+'.'+$kind+'.'+$abort+'.sql');[IO.File]::WriteAllText($out,$body,[Text.UTF8Encoding]::new($false));$texts[$mode][$kind][$abort]=$out}}};$texts|ConvertTo-Json -Depth 5 -Compress"
        rendered = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', render], cwd=ROOT,
                                  capture_output=True, text=True, encoding='utf-8', timeout=20)
        self.assertEqual(rendered.returncode, 0, rendered.stdout + rendered.stderr)
        caller_texts = json.loads(rendered.stdout)
        files.append(tool)
        files.extend(Path(path) for mode in caller_texts.values() for kind in mode.values() for path in kind.values())
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        cases = []
        for platform in ('windows', 'linux'):
            for version, patch, levels in (('2019', 'CU32', (150,)), ('2022', 'CU26', (150, 160)),
                                            ('2025', 'CU8', (150, 160, 170))):
                for level in levels:
                    cases.append(dict(Platform=platform, Version=version, Patch=patch if platform == 'windows' else 'latest',
                                      CL=level, modes=['local', 'central']))
        self.record = dict(schema_version='table-clone-sqlcmd-caller/v1', explicit_qualification_approved=True,
                           started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=60)).isoformat(),
                           fixtures=list(map(str, fixtures)), exports=exports, cases=cases, callerTexts=caller_texts,
                           sqlcmd=dict(path=str(tool), sha256=hashlib.sha256(tool.read_bytes()).hexdigest().upper()),
                           pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record=None):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record or self.record), encoding='utf-8')
        command = UTF8_CONSOLE + "$ErrorActionPreference='Stop';& " + ps_quote(DRIVER) + \
            ' -RunsetPath ' + ps_quote(path) + ' -CaseIndex 11 -ValidateOnly'
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', command],
                                cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=20)
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
        self.reject(lambda r: r.update(started_utc=expired.isoformat(), deadline_utc=(expired + timedelta(minutes=60)).isoformat()))
        self.reject(lambda r: r.update(deadline_utc=(datetime.now(timezone.utc) + timedelta(hours=2)).isoformat()))

    def test_later_target_cannot_be_relabelled(self):
        self.reject(lambda r: r['cases'][11].update(Patch='base'))
        self.reject(lambda r: r['cases'][11].update(CL=160))

    def test_each_target_requires_both_declared_modes(self):
        for index in (0, 5, 6, 11):
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
        script = UTF8_CONSOLE + "$ErrorActionPreference='Stop';$errors=$null;" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile('" + str(DRIVER).replace("'", "''") + "',[ref]$null,[ref]$errors);" + \
            "$functions=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Assert-CloneSqlcmdCallerFixtureScope'},$true));" + \
            "if($errors.Count-or$functions.Count-ne1){throw 'SCOPE_FUNCTION'};. ([scriptblock]::Create($functions[0].Extent.Text));" + \
            "Assert-CloneSqlcmdCallerFixtureScope " + payload + ";'PASS fixture scope without SQL'"
        return subprocess.run(['pwsh', '-NoProfile', '-Command', script], cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=20)

    def test_forbidden_fixture_rights_and_server_scope_rejected(self):
        for text in ('GRANT EXECUTE ON dbo.Synthetic TO Contoso;', 'CREATE USER Contoso WITHOUT LOGIN;',
                     'ALTER AUTHORIZATION ON SCHEMA::dbo TO Contoso;', 'ALTER DATABASE Synthetic SET TRUSTWORTHY ON;',
                     'EXEC sys.sp_configure N\'clr enabled\',1;', 'CREATE TRIGGER Synthetic ON ALL SERVER FOR CREATE_DATABASE AS SELECT 1;',
                     'EXEC toolbelt_metadata.USP_ScriptTableClone @IncludeTriggers=1;'):
            result = self.scope(text)
            self.assertNotEqual(result.returncode, 0, text)
            self.assertIn('CLONE_SQLCMD_CALLER_FIXTURE_EXCEEDS_SCOPE', result.stdout + result.stderr)

    def test_all_original_fixtures_remain_permitted(self):
        for path in self.record['fixtures']:
            result = self.scope(path, from_file=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_canonical_caller_text_rejects_forgery_even_with_matching_pin(self):
        path = Path(self.record['callerTexts']['local']['Deploy']['OFF'])
        path.write_bytes(path.read_bytes().replace(b'TBX_TABLE_CLONE_CALLER_TRANSACTION:', b'Contoso_Changed_Guard:'))
        record = copy.deepcopy(self.record)
        for pin in record['pins']:
            if pin['path'] == str(path):
                pin['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest().upper()
        result = self.admission(record)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('SQLCMD_CALLER_CANONICAL_TEXT_DRIFT', result.stdout + result.stderr)

    def test_cli_and_caller_text_pins_required(self):
        for path in (self.record['sqlcmd']['path'], self.record['callerTexts']['central']['Uninstall']['ON']):
            record = copy.deepcopy(self.record)
            record['pins'] = [pin for pin in record['pins'] if pin['path'] != path]
            result = self.admission(record)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('PIN_REQUIRED', result.stdout + result.stderr)

    def test_synthetic_arguments_never_expose_password_or_relax_trust(self):
        command = UTF8_CONSOLE + "$ErrorActionPreference='Stop';$e=$null;" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile(" + ps_quote(DRIVER) + ",[ref]$null,[ref]$e);" + \
            "$n=@($ast.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'New-SqlcmdCallerArguments'},$true));if($e.Count-or$n.Count-ne1){throw 'ARGUMENT_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text));" + \
            "$b=[Data.SqlClient.SqlConnectionStringBuilder]::new();$b['Data Source']='tcp:127.0.0.1,1433';$b['User ID']='Contoso';$b['Password']='Synthetic_Contoso_Secret';$b['Encrypt']=$true;" + \
            "$file=" + ps_quote(self.directory / 'Contoso.sql') + ";foreach($trust in @($false,$true)){$b['TrustServerCertificate']=$trust;$a=@(New-SqlcmdCallerArguments $b ('Toolbelt_Release_'+('a'*32)+'_l') $file);" + \
            "if($a-ccontains$b.Password-or$a-ccontains'-P'-or$a-ccontains'-E'-or$a-cnotcontains'-N'-or$a-cnotcontains'-x'-or$a-ccontains'-X1'-or(($a-ccontains'-C')-ne$trust)){throw 'ARGUMENT_SECRET_OR_TRUST'} };$b.Clear();'PASS synthetic argument policy'"
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', command], cwd=ROOT,
                                capture_output=True, text=True, encoding='utf-8', timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_process_composition_preserves_unicode_and_closes_stdin(self):
        child = '[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false);' + \
            '[Console]::WriteLine([char]0x03A9);[Console]::Error.WriteLine([char]::ConvertFromUtf32(0x1F9EA));' + \
            'if($null-ne[Console]::In.ReadLine()){throw 42};' + \
            '$keys=@([Environment]::GetEnvironmentVariables().Keys|Where-Object{([string]$_).StartsWith("SQLCMD",[StringComparison]::OrdinalIgnoreCase)-or([string]$_).StartsWith("OSQL",[StringComparison]::OrdinalIgnoreCase)});' + \
            'if($keys.Count-ne1-or$keys[0]-cne"SQLCMDPASSWORD"-or[Environment]::GetEnvironmentVariable("SQLCMDPASSWORD")-cne"Synthetic_Child_Secret"){throw 43};'
        command = UTF8_CONSOLE + "$ErrorActionPreference='Stop';$e=$null;$repo=" + ps_quote(ROOT) + ";" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/Release/Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$e);$n=@($ast.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Import-ClrFunctions'},$true));. ([scriptblock]::Create($n[0].Extent.Text));" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile(" + ps_quote(DRIVER) + ",[ref]$null,[ref]$e);$n=@($ast.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Initialize-SqlcmdCallerProcess'},$true));if($e.Count-or$n.Count-ne1){throw 'PROCESS_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text));. (Initialize-SqlcmdCallerProcess);" + \
            "$env:SQLCMDINI='C:/Contoso/NotToRun.sql';$env:SQLCMDSERVER='Contoso_Unselected';$env:OSQLPASSWORD='Synthetic_Parent_Secret';$env:SQLCMDPASSWORD='Synthetic_Parent_Secret';$code=" + ps_quote(child) + ";" + \
            "$r=Invoke-SqlcmdCallerOwnedProcess -FileName (Get-Process -Id $PID).Path -Arguments @('-NoProfile','-NonInteractive','-Command',$code) -TimeoutMilliseconds 10000 -SqlcmdPassword 'Synthetic_Child_Secret';" + \
            "if($r.ExitCode-ne0-or-not$r.CaptureComplete-or-not$r.Stdout.Contains('Ω')-or-not$r.Stderr.Contains('🧪')){throw 'PROCESS_UNICODE_OR_STDIN_OR_ENV'};" + \
            "if($env:SQLCMDINI-cne'C:/Contoso/NotToRun.sql'-or$env:SQLCMDPASSWORD-cne'Synthetic_Parent_Secret'-or$env:OSQLPASSWORD-cne'Synthetic_Parent_Secret'){throw 'PARENT_ENV_DRIFT'};'PASS process policy'"
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', command], cwd=ROOT,
                                capture_output=True, text=True, encoding='utf-8', timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
