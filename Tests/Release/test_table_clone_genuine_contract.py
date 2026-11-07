"""Verbindungslose Admission des echten historischen Lifecycle-Eingangs."""
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
DRIVER = ROOT / 'Tests/Release/Invoke-TableCloneGenuineLab.ps1'
UTF8 = '[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false);$OutputEncoding=[Console]::OutputEncoding;'


def quote(value):
    return "'" + str(value).replace("'", "''") + "'"


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class CloneGenuineAdmissionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original_temp = tempfile.TemporaryDirectory(prefix='clone-genuine-original-', dir=ROOT / '.runtime')
        cls.original = Path(cls.original_temp.name) / 'genuine-v1'
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-File',
            str(ROOT / 'Modules/toolbelt.metadata.table-clone/Deployment/New-LegacyTestArtifacts.ps1'),
            '-OutputDirectory', str(cls.original)], cwd=ROOT, capture_output=True, timeout=90)
        if result.returncode:
            cls.original_temp.cleanup()
            raise RuntimeError('Original public V1 fixture unavailable; no fallback')

    @classmethod
    def tearDownClass(cls):
        cls.original_temp.cleanup()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='clone-genuine-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        legacy = self.directory / 'genuine-v1'
        shutil.copytree(self.original, legacy)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.dependency.sql')
            path.write_text('-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        required = [ROOT / name for name in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1',
            'Tests/CI/Set-SqlClientTlsPolicy.ps1', 'Tests/CI/Assert-LabQualifiedTlsBinding.ps1',
            'Deployment/Deploy-All.ps1',
            'Modules/toolbelt.metadata.table-clone/Deployment/New-LegacyTestArtifacts.ps1',
            'Modules/toolbelt.metadata.table-clone/Deployment/Deploy.sql',
            'Modules/toolbelt.metadata.table-clone/Deployment/Uninstall.sql',
            'Modules/toolbelt.metadata.table-clone/module.yaml',
            'Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql',
            'Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableCloneInternal.sql',
            'Modules/toolbelt.metadata.table-clone/Source/USP_ExecuteTableClone.sql',
            'Modules/toolbelt.metadata.table-clone/Source/USP_CopyTableCloneData.sql')]
        command = UTF8 + "$ErrorActionPreference='Stop';$repo=" + quote(ROOT) + ';$legacy=' + quote(legacy) + ';$folder=' + quote(self.directory) + ";$e=$null;" + \
            "$a=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Deployment/Deploy-All.ps1'),[ref]$null,[ref]$e);" + \
            "foreach($name in @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'PURE_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))};" + \
            "$texts=@{};foreach($mode in @('local','central')){$texts[$mode]=@{};foreach($kind in @('Deploy','Uninstall','Legacy')){" + \
            "$source=if($kind-ceq'Legacy'){Join-Path $legacy 'Deployment/Deploy.sql'}else{Join-Path $repo ('Modules/toolbelt.metadata.table-clone/Deployment/'+$kind+'.sql')};" + \
            "$boundary=if($kind-ceq'Legacy'){$legacy}else{Join-Path $repo 'Modules'};$node=Get-SqlcmdScriptTree -Path $source -Cache @{};" + \
            "$text=ConvertTo-StandaloneSql -Node $node -Values @{DeploymentMode=$mode;ConfirmNoExternalConsumers='1'} -ModulesRoot $boundary;" + \
            "$path=Join-Path $folder ($mode+'.'+$kind+'.sql');[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));$texts[$mode][$kind]=$path}};$texts|ConvertTo-Json -Depth 5 -Compress"
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', command],
            cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        texts = json.loads(result.stdout)
        files = [DRIVER, *required, *(Path(p) for p in exports.values()), *legacy.rglob('*')]
        files.extend(Path(p) for mode in texts.values() for p in mode.values())
        cases = []
        for platform in ('windows', 'linux'):
            for version, patch, levels in (('2019', 'CU32', (150,)), ('2022', 'CU26', (150, 160)), ('2025', 'CU8', (150, 160, 170))):
                cases.extend(dict(Platform=platform, Version=version, Patch=patch if platform == 'windows' else 'latest',
                    CL=level, modes=['local', 'central']) for level in levels)
        start = datetime.now(timezone.utc) - timedelta(seconds=5)
        self.record = dict(schema_version='table-clone-genuine/v1', explicit_qualification_approved=True,
            cases=cases, started_utc=start.isoformat(), deadline_utc=(start + timedelta(minutes=60)).isoformat(),
            exports=exports, legacyRoot=str(legacy), lifecycleTexts=texts,
            pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files if p.is_file()])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record), encoding='utf-8')
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command',
            UTF8 + '& ' + quote(DRIVER) + ' -RunsetPath ' + quote(path) + ' -CaseIndex 11 -ValidateOnly'],
            cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=30)
        self.assertEqual(list(self.directory.glob('case-*')), [])
        return result

    def reject(self, mutate, category):
        record = copy.deepcopy(self.record)
        mutate(record)
        result = self.admission(record)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(category, result.stdout + result.stderr)

    def repin(self, record, path):
        matches = [p for p in record['pins'] if p['path'] == str(path)]
        self.assertEqual(len(matches), 1)
        matches[0]['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest().upper()

    def test_rollback_anchor_checked_without_sql(self):
        command = UTF8 + "$ErrorActionPreference='Stop';$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile(" + quote(DRIVER) + ",[ref]$null,[ref]$e);" + \
            "$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'New-CloneGenuineFaultText'},$true));if($e.Count-or$n.Count-ne1){throw 'FAULT_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text));" + \
            "$anchor='    DROP TABLE #tbx_TableCloneReleaseObjects;';foreach($bad in @('SELECT 1;',($anchor+[char]10+$anchor))){$caught=$false;try{[void](New-CloneGenuineFaultText $bad)}catch{if($_.Exception.Message-cne'CLONE_GENUINE_ROLLBACK_ANCHOR'){throw};$caught=$true};if(-not$caught){throw 'AMBIGUOUS_FAULT_ACCEPTED'}};" + \
            "$text='BEGIN TRANSACTION;'+[char]10+$anchor+[char]10+'COMMIT TRANSACTION;';$fault=New-CloneGenuineFaultText $text;if($fault.IndexOf('THROW 54932')-lt0-or$fault.IndexOf('THROW 54932')-gt$fault.IndexOf($anchor)){throw 'FAULT_ORDER'};'PURE_FAULT_PASS'"
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', command],
            cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('PURE_FAULT_PASS', result.stdout)
        self.assertEqual(list(self.directory.glob('case-*')), [])

    def test_carry_cannot_select_another_mode(self):
        self.reject(lambda r: r.update(carry=dict(schema_version='genuine-v1-prefix/v1', caseIndex=0, mode='central', profileCount=4)), 'CARRY_SCOPE')

    def test_carry_cannot_change_prefix_size(self):
        self.reject(lambda r: r.update(carry=dict(schema_version='genuine-v1-prefix/v1', caseIndex=0, mode='local', profileCount=3)), 'CARRY_SCOPE')

    def test_carried_profiles_cannot_run_again(self):
        command = UTF8 + "$ErrorActionPreference='Stop';$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile(" + quote(DRIVER) + ",[ref]$null,[ref]$e);" + \
            "$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Get-CloneGenuineProfiles'},$true));if($e.Count-or$n.Count-ne1){throw 'PROFILE_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text));" + \
            "$script:carryActive=$true;$l=@(Get-CloneGenuineProfiles 'local');$c=@(Get-CloneGenuineProfiles 'central');if($l.Count-ne6-or$c.Count-ne10-or$l[0]-cne'genuine-upgrade-rollback'){throw 'REMAINDER_SCOPE'};foreach($p in @('clean-current-rollback','genuine-install','current-uninstall-genuine','genuine-reinstall')){if($l-ccontains$p){throw 'GREEN_PROFILE_REPLAY'}};$script:carryActive=$false;if(@(Get-CloneGenuineProfiles 'local').Count-ne10){throw 'UNTESTED_CASE_TRUNCATED'};'PROFILE_PASS'"
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', command],
            cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('PROFILE_PASS', result.stdout)

    def test_legacy_session_closes_on_success_and_failure(self):
        path = self.directory / 'synthetic-legacy.sql'
        path.write_text('-- Synthetic test text; executor is mocked.\n', encoding='utf-8')
        command = UTF8 + "$ErrorActionPreference='Stop';$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile(" + quote(DRIVER) + ",[ref]$null,[ref]$e);" + \
            "$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Invoke-CloneGenuineLegacySession'},$true));if($e.Count-or$n.Count-ne1){throw 'LEGACY_SESSION_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text));" + \
            "$script:closed=0;$script:executed=0;$script:fail=$false;$script:fresh=[pscustomobject]@{Database='Contoso'};$script:fresh|Add-Member ScriptMethod Dispose {$script:closed++};$observer=[pscustomobject]@{Database='Contoso'};" + \
            "$script:runset=@{lifecycleTexts=@{local=@{Legacy=" + quote(path) + "}}};" + \
            "function Open-ReleaseConnection($Database){if($Database-cne'Contoso'){throw 'WRONG_DATABASE'};return $script:fresh};" + \
            "function Invoke-CloneGenuineSqlBatches($Connection,$Text){if(-not[object]::ReferenceEquals($Connection,$script:fresh)){throw 'OBSERVER_REUSED'};$script:executed++;if($script:fail){throw 'SYNTHETIC_FAILURE'}};" + \
            "function Invoke-ReleaseSql($Connection,$Text,[switch]$Rows){return [pscustomobject]@{TranCount=0;XactState=0}};" + \
            "Invoke-CloneGenuineLegacySession $observer 'local';if($script:closed-ne1-or$script:executed-ne1){throw 'SUCCESS_SESSION_LEAK'};$script:fail=$true;$caught=$false;try{Invoke-CloneGenuineLegacySession $observer 'local'}catch{if($_.Exception.Message-cne'SYNTHETIC_FAILURE'){throw};$caught=$true};if(-not$caught-or$script:closed-ne2-or$script:executed-ne2){throw 'FAILURE_SESSION_LEAK'};'LEGACY_SESSION_PASS'"
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', command],
            cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('LEGACY_SESSION_PASS', result.stdout)

    def test_valid_original_tree_without_lab_import(self):
        result = self.admission(self.record)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('OFFLINE_ADMISSION', result.stdout)

    def test_approval_requires_boolean(self):
        self.reject(lambda r: r.update(explicit_qualification_approved='true'), 'RUNSET_SCOPE')

    def test_target_cl_is_exact(self):
        self.reject(lambda r: r['cases'][0].update(CL=160), 'CONTEXT_SCOPE')

    def test_central_mode_is_required(self):
        self.reject(lambda r: r['cases'][3].update(modes=['local']), 'CONTEXT_SCOPE')

    def test_deadline_cannot_extend(self):
        self.reject(lambda r: r.update(deadline_utc=(datetime.fromisoformat(r['started_utc']) + timedelta(minutes=61)).isoformat()), 'ADMISSION_CLOSED')

    def test_expired_window_cannot_admit(self):
        def mutate(r):
            start = datetime.now(timezone.utc) - timedelta(hours=2)
            r.update(started_utc=start.isoformat(), deadline_utc=(start + timedelta(minutes=60)).isoformat())
        self.reject(mutate, 'ADMISSION_CLOSED')

    def test_original_file_pin_required(self):
        self.reject(lambda r: r.update(pins=[p for p in r['pins'] if p['path'] != str(Path(r['legacyRoot']) / 'module.yaml')]), 'ORIGINAL_PIN')

    def test_rehashed_original_source_forgery_rejected(self):
        def mutate(r):
            p = Path(r['legacyRoot']) / 'Source/USP_ScriptTableClone.sql'
            p.write_bytes(p.read_bytes() + b'\n-- Synthetic forged original\n')
            self.repin(r, p)
        self.reject(mutate, 'ORIGINAL_BYTES')

    def test_rehashed_provenance_forgery_rejected(self):
        def mutate(r):
            p = Path(r['legacyRoot']) / 'provenance.json'
            value = json.loads(p.read_text(encoding='utf-8-sig'))
            value['publicCommit'] = '0' * 40
            p.write_text(json.dumps(value), encoding='utf-8')
            self.repin(r, p)
        self.reject(mutate, 'ORIGINAL_PROVENANCE')

    def test_rehashed_canonical_text_forgery_rejected(self):
        def mutate(r):
            p = Path(r['lifecycleTexts']['central']['Deploy'])
            p.write_bytes(p.read_bytes() + b'\nSELECT 1;\n')
            self.repin(r, p)
        self.reject(mutate, 'CANONICAL_TEXT')

    def test_dependency_export_cannot_install_clone(self):
        def mutate(r):
            p = Path(r['exports']['local'])
            p.write_bytes(p.read_bytes() + b'-- BEGIN MODULE toolbelt.metadata.table-clone\nSELECT 1;\n')
            self.repin(r, p)
        self.reject(mutate, 'DEPENDENCY_ONLY_EXPORT_REQUIRED')

    def test_current_source_dependency_pin_is_mandatory(self):
        self.reject(lambda r: r.update(pins=[p for p in r['pins'] if Path(p['path']).name != 'USP_CopyTableCloneData.sql']), 'SOURCE_TREE_PIN')

    def test_tls_policy_input_is_mandatory(self):
        self.reject(lambda r: r.update(pins=[p for p in r['pins'] if not p['path'].endswith('Set-SqlClientTlsPolicy.ps1')]), 'REQUIRED_PIN_MISSING')


if __name__ == '__main__':
    unittest.main()
