"""Executor admission, owned identity and hash protocol; no Lab or SQL."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy,hashlib,importlib.util,json,shutil,subprocess,tempfile,unittest
ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-TableCloneExecutorRightsLab.ps1'
FIXTURE=ROOT/'Tests/Release/Runtime/TableClone.ExecutorRights.Contract.ps1'
def quote(p):return "'"+str(p).replace("'","''")+"'"
def ps(text):return subprocess.run(['pwsh','-NoProfile','-NonInteractive','-Command',"$ErrorActionPreference='Stop';"+text],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',timeout=25)
@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class ExecutorRightsTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='executor-admission-',dir=ROOT/'.runtime');self.folder=Path(self.temp.name)
        exports={}
        for mode in ('local','central'):
            p=self.folder/(mode+'.sql');p.write_text('-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n-- BEGIN MODULE toolbelt.metadata.table-clone\nSELECT 1;\n',encoding='utf-8');exports[mode]=str(p)
        files=[DRIVER,FIXTURE,*(Path(p) for p in exports.values()),*(ROOT/p for p in ('Tests/Release/Invoke-ApiQualificationLab.ps1','Tests/Release/Invoke-StablePackageLab.ps1','Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1','Tests/CI/Set-SqlClientTlsPolicy.ps1','Tests/CI/Assert-LabQualifiedTlsBinding.ps1'))]
        for module in ('toolbelt.core.result-table','toolbelt.metadata.table-clone'):
            d=ROOT/'Modules'/module;files += [d/'module.yaml',*(d/'Source').rglob('*.sql'),*(d/'Deployment').rglob('*.sql')]
        cases=[dict(Platform=p,Version=v,Patch=('latest' if p=='linux' else {'2019':'CU32','2022':'CU26','2025':'CU8'}[v]),CL=cl,modes=['local','central']) for p in ('windows','linux') for v in ('2019','2022','2025') for cl in {'2019':[150],'2022':[150,160],'2025':[150,160,170]}[v]]
        now=datetime.now(timezone.utc)-timedelta(seconds=2)
        self.record=dict(schema_version='table-clone-executor-rights/v1',explicit_qualification_approved=True,temporary_identity_rights_approved=True,permission_plan='ExecutorBasic13/v1',cases=cases,fixtures=[str(FIXTURE)],exports=exports,started_utc=now.isoformat(),deadline_utc=(now+timedelta(minutes=45)).isoformat(),pins=[dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in dict.fromkeys(files)])
    def tearDown(self):self.temp.cleanup()
    def admission(self,r):
        p=self.folder/'runset.json';p.write_text(json.dumps(r),encoding='utf-8')
        result=ps('& '+quote(DRIVER)+' -RunsetPath '+quote(p)+' -CaseIndex 11 -ValidateOnly')
        self.assertEqual(list(self.folder.glob('case-*')),[]);return result
    def reject(self,mutate):
        r=copy.deepcopy(self.record);mutate(r);v=self.admission(r);self.assertNotEqual(v.returncode,0,v.stdout+v.stderr)
    def test_admission_without_lab(self):
        r=self.admission(self.record);self.assertEqual(r.returncode,0,r.stdout+r.stderr)
    def test_authority_is_boolean(self):
        self.reject(lambda r:r.update(temporary_identity_rights_approved='true'))
        self.reject(lambda r:r.update(explicit_qualification_approved=False))
    def test_permission_plan_closed(self):self.reject(lambda r:r.update(permission_plan='ExecutorFull/v1'))
    def test_matrix_exact(self):
        self.reject(lambda r:r['cases'][0].update(CL=160))
        self.reject(lambda r:r['cases'][0].update(modes=['local']))
    def test_time_bound(self):
        self.reject(lambda r:r.update(deadline_utc=(datetime.fromisoformat(r['started_utc'])+timedelta(minutes=46)).isoformat()))
        old=datetime.now(timezone.utc)-timedelta(hours=2)
        self.reject(lambda r:r.update(started_utc=old.isoformat(),deadline_utc=(old+timedelta(minutes=45)).isoformat()))
    def test_product_and_fixture_pins(self):
        self.reject(lambda r:r.update(fixtures=[]))
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if not p['path'].endswith('USP_ExecuteTableClone.sql')]))
        self.reject(lambda r:r['pins'][0].update(sha256='0'*64))
    def test_owned_identity_and_closed_grants(self):
        v=ps('. '+quote(FIXTURE)+r"""
$n='ContosoCloneExecutor_'+('a'*32)
$expected=@{name=$n;sid=('A'*32);id=301;created=('B'*16);consumer='ContosoOwn'}
$row=@{Name=$n;Sid=('A'*32);Id=301;Created=('B'*16);DefaultDatabase='ContosoOwn';Type='S';Disabled=0;Policy=1;Expiration=1}
if(-not(Test-ExecutorLoginIdentity $expected @($row))){throw 'POSITIVE_IDENTITY'}
foreach($field in @('Name','Sid','Id','Created','DefaultDatabase','Type','Disabled','Policy','Expiration')){
 $copy=$row.Clone();$copy[$field]=if($field-in@('Id','Disabled','Policy','Expiration')){99}else{'wrong'}
 if(Test-ExecutorLoginIdentity $expected @($copy)){throw 'IDENTITY_DRIFT_ACCEPTED'}
}
if(Test-ExecutorLoginIdentity $expected @($row,$row)){throw 'DUPLICATE_IDENTITY'}
$commands=@('CONNECT','EXECUTE','METADATA','DDL'|ForEach-Object{Get-ExecutorDatabaseGrant $n $_})-join''
if(([regex]::Matches($commands,'GRANT ')).Count-ne6-or$commands-match'CONTROL|REFERENCES|USP_PrepareResultTable|USP_ScriptTableClone'){throw 'RIGHTS_SCOPE'}
foreach($bad in @('dbo','ContosoCloneExecutor_'+('A'*32),"x];GRANT CONTROL TO public;--")){
 $caught=$false;try{Get-ExecutorDatabaseGrant $bad DDL}catch{$caught=$true};if(-not$caught){throw 'FOREIGN_NAME_ACCEPTED'}
}
$caught=$false;try{Get-ExecutorDatabaseGrant $n CONTROL}catch{$caught=$true};if(-not$caught){throw 'UNKNOWN_PERMISSION_ACCEPTED'}
'IDENTITY_GRANTS_PASS'
""")
        self.assertEqual(v.returncode,0,v.stdout+v.stderr)
    def test_hash_matches_canonical_client_example(self):
        plan=[dict(Ordinal=i,ObjectKind='SESSION_OPTION' if i<8 else 'TABLE',TargetName='ContosoCloneTarget.ContosoExecutorTarget',ScriptText='synthetic '+str(i)+' Ω\n') for i in range(1,9)]
        p=self.folder/'plan.json';p.write_text(json.dumps(plan),encoding='utf-8')
        v=ps('. '+quote(FIXTURE)+';$p=Get-Content '+quote(p)+' -Raw|ConvertFrom-Json;[Convert]::ToHexString((Get-ExecutorPlanHash 42 ContosoOwn @($p)))')
        self.assertEqual(v.returncode,0,v.stdout+v.stderr)
        spec=importlib.util.spec_from_file_location('canonical_hash',ROOT/'Modules/toolbelt.metadata.table-clone/Examples/CalculatePlanHash.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        request=dict(install_db_id=42,install_db_name='ContosoOwn',include_identity=False,include_extended_properties=False,map_mode=False,external_reference_rule='REJECT',foreign_key_mode='CREATE',mapping=[dict(MapOrdinal=1,SourceSchema='dbo',SourceTable='ContosoExecutorSource',TargetSchema='ContosoCloneTarget',TargetTable='ContosoExecutorTarget')],plan=plan)
        self.assertEqual(v.stdout.strip(),module.calculate(request).hex().upper())
    def test_grant_oracle_rejects_right_on_wrong_object(self):
        v=ps('. '+quote(FIXTURE)+r"""
$rows=@(@{Permission='ALTER';Class=3;Major=77;State='G'},@{Permission='CONNECT';Class=0;Major=0;State='G'},@{Permission='CREATE TABLE';Class=0;Major=0;State='G'},@{Permission='EXECUTE';Class=1;Major=88;State='G'},@{Permission='SELECT';Class=1;Major=-5;State='G'},@{Permission='VIEW DEFINITION';Class=0;Major=0;State='G'})
if(-not(Test-ExecutorGrantRows $rows 88 -5 77)){throw 'EXACT_GRANT_ORACLE'}
foreach($field in @('Class','Major','State')){
 $copy=@($rows|ForEach-Object{$_.Clone()});$copy[3][$field]=if($field-ceq'State'){'W'}else{99}
 if(Test-ExecutorGrantRows $copy 88 -5 77){throw 'GRANT_DRIFT_ACCEPTED'}
}
if(Test-ExecutorGrantRows @($rows+$rows[0]) 88 -5 77){throw 'EXTRA_GRANT_ACCEPTED'}
""")
        self.assertEqual(v.returncode,0,v.stdout+v.stderr)
if __name__=='__main__':unittest.main()
