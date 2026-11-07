"""Verbindungslose Admission für die einzeln freigegebenen Planner-Testrechte."""
from pathlib import Path
from datetime import datetime, timedelta, timezone
import copy
import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-TableClonePlannerRightsLab.ps1'
UTF8='[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false);$OutputEncoding=[Console]::OutputEncoding;'

def quote(value):return "'"+str(value).replace("'","''")+"'"

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class ClonePlannerRightsAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='clone-rights-admission-',dir=ROOT/'.runtime')
        self.directory=Path(self.temp.name)
        exports={}
        for mode in ('local','central'):
            path=self.directory/(mode+'.sql')
            path.write_text('-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n-- BEGIN MODULE toolbelt.metadata.table-clone\nSELECT 1;\n',encoding='utf-8')
            exports[mode]=str(path)
        fixture=ROOT/'Modules/toolbelt.metadata.table-clone/Tests/Runtime/MinimumRights.Contract.sql'
        files=[DRIVER,fixture,*(Path(p) for p in exports.values()),*(ROOT/p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1','Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1',
            'Tests/CI/Set-SqlClientTlsPolicy.ps1','Tests/CI/Assert-LabQualifiedTlsBinding.ps1'))]
        cases=[]
        for platform in ('windows','linux'):
            for version,patch,levels in (('2019','CU32',(150,)),('2022','CU26',(150,160)),('2025','CU8',(150,160,170))):
                cases.extend(dict(Platform=platform,Version=version,Patch=patch if platform=='windows' else 'latest',CL=level,modes=['local','central']) for level in levels)
        start=datetime.now(timezone.utc)-timedelta(seconds=5)
        self.record=dict(schema_version='table-clone-planner-rights/v1',explicit_qualification_approved=True,cases=cases,
            started_utc=start.isoformat(),deadline_utc=(start+timedelta(minutes=60)).isoformat(),fixtures=[str(fixture)],exports=exports,
            rights_approval=dict(explicit=True,user='TbxCloneReader',permissions=[
                'EXECUTE/OBJECT/toolbelt_metadata.USP_ScriptTableClone','EXECUTE/OBJECT/toolbelt_core.USP_PrepareResultTable',
                'VIEW DEFINITION/OBJECT/dbo.SyntheticRightsSource','VIEW DEFINITION/SCHEMA/dbo','VIEW DEFINITION/DATABASE/OWN']),
            pins=[dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files])

    def tearDown(self):self.temp.cleanup()

    def admission(self,record):
        path=self.directory/'runset.json';path.write_text(json.dumps(record),encoding='utf-8')
        command=UTF8+'& '+quote(DRIVER)+' -RunsetPath '+quote(path)+' -CaseIndex 11 -ValidateOnly'
        result=subprocess.run(['pwsh','-NoProfile','-NonInteractive','-Command',command],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',timeout=20)
        self.assertEqual(list(self.directory.glob('case-*')),[])
        return result

    def reject(self,mutate,category):
        record=copy.deepcopy(self.record);mutate(record);result=self.admission(record)
        self.assertNotEqual(result.returncode,0)
        self.assertIn(category,result.stdout+result.stderr)

    def test_valid_scope_without_lab_import(self):
        result=self.admission(self.record)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertIn('OFFLINE_ADMISSION',result.stdout)

    def test_qualification_flag_requires_bool(self):
        self.reject(lambda r:r.update(explicit_qualification_approved='true'),'RUNSET_SCOPE')

    def test_rights_flag_requires_bool(self):
        self.reject(lambda r:r['rights_approval'].update(explicit='true'),'EXPLICIT_PERMISSION_AUTHORITY_REQUIRED')

    def test_rights_authority_cannot_be_missing(self):
        self.reject(lambda r:r.pop('rights_approval'),'EXPLICIT_PERMISSION_AUTHORITY_REQUIRED')

    def test_internal_execute_cannot_be_added(self):
        self.reject(lambda r:r['rights_approval']['permissions'].append('EXECUTE/OBJECT/toolbelt_metadata.USP_ScriptTableCloneInternal'),'EXPLICIT_PERMISSION_AUTHORITY_REQUIRED')

    def test_existing_identity_cannot_be_selected(self):
        self.reject(lambda r:r['rights_approval'].update(user='dbo'),'EXPLICIT_PERMISSION_AUTHORITY_REQUIRED')

    def test_exact_engine_cl_tuple(self):
        self.reject(lambda r:r['cases'][0].update(CL=160),'CONTEXT_SCOPE')

    def test_central_mode_cannot_be_removed(self):
        self.reject(lambda r:r['cases'][0].update(modes=['local']),'CONTEXT_SCOPE')

    def test_deadline_cannot_be_extended(self):
        self.reject(lambda r:r.update(deadline_utc=(datetime.fromisoformat(r['started_utc'])+timedelta(minutes=61)).isoformat()),'ADMISSION_CLOSED')

    def test_expired_window_is_closed(self):
        def mutate(r):
            start=datetime.now(timezone.utc)-timedelta(hours=2)
            r.update(started_utc=start.isoformat(),deadline_utc=(start+timedelta(minutes=60)).isoformat())
        self.reject(mutate,'ADMISSION_CLOSED')

    def test_actual_fixture_is_mandatory(self):
        self.reject(lambda r:r.update(fixtures=[]),'CANONICAL_FIXTURES_REQUIRED')

    def test_tls_policy_pin_is_required(self):
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if Path(p['path']).name!='Set-SqlClientTlsPolicy.ps1']),'REQUIRED_PIN_MISSING')

    def test_scope_widening_and_core_denial_derivation(self):
        command=UTF8+"$ErrorActionPreference='Stop';$repo="+quote(ROOT)+";$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile("+quote(DRIVER)+",[ref]$null,[ref]$e);"+ \
            "foreach($name in @('Assert-CloneRightsFixtureScope','Get-CloneRightsFixtureText')){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'SCOPE_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))};"+ \
            "$text=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Tests/Runtime/MinimumRights.Contract.sql'));$derived=Get-CloneRightsFixtureText $text;if(([regex]::Matches($derived,'EXEC toolbelt_metadata.USP_ScriptTableCloneInternal @Hilfe=1;')).Count-ne1-or$derived.IndexOf('ERROR_NUMBER()<>229')-gt$derived.IndexOf(\"EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo'\")){throw 'CORE_DENIAL_INSERTION'};"+ \
            "$bad=@($text+\"`nGRANT CONTROL TO TbxCloneReader;\",$text+\"`nGRANT EXECUTE ON toolbelt_metadata.USP_ScriptTableCloneInternal TO TbxCloneReader;\",$text+\"`nEXEC(N'GRANT CONTROL TO TbxCloneReader;');\",$text+\"`nDROP USER ContosoExistingUser;\",$text+\"`nUSE master;\",$text.Replace('WITHOUT LOGIN;','FOR LOGIN ContosoLogin;'));foreach($candidate in $bad){$caught=$false;try{Assert-CloneRightsFixtureScope $candidate}catch{$caught=$true};if(-not$caught){throw 'SCOPE_WIDENING'}};'PURE_SCOPE_PASS'"
        result=subprocess.run(['pwsh','-NoProfile','-NonInteractive','-Command',command],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertIn('PURE_SCOPE_PASS',result.stdout)

if __name__=='__main__':unittest.main()
