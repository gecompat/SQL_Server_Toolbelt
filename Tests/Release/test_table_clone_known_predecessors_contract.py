"""Verbindungslose Quellen-/Scopegegenproben für echte bekannte Vorgänger."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-TableCloneKnownPredecessorsLab.ps1'
UTF8='[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false);$OutputEncoding=[Console]::OutputEncoding;'

def quote(value):return "'"+str(value).replace("'","''")+"'"
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest().upper()

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class CloneKnownPredecessorAdmissionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.shared=tempfile.TemporaryDirectory(prefix='clone-known-originals-',dir=ROOT/'.runtime')
        cls.shared_path=Path(cls.shared.name)
        raw=DRIVER.read_text(encoding='utf-8-sig')
        match=re.search(r"\$script:knownExpected=ConvertFrom-Json -AsHashtable @'\r?\n(.*?)\r?\n'@",raw,re.S)
        if not match:raise RuntimeError('Original public source specification missing')
        cls.expected=json.loads(match.group(1))
        for version,row in cls.expected.items():
            target=cls.shared_path/('genuine-'+version);records=[]
            for name,digest in row['files'].items():
                value=subprocess.check_output(['git','cat-file','blob',row['publicCommit']+':Modules/toolbelt.metadata.table-clone/'+name],cwd=ROOT,timeout=10)
                if hashlib.sha256(value).hexdigest().upper()!=digest:raise RuntimeError('Original public bytes unavailable; no fallback')
                path=target/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(value)
                records.append(dict(path=name,sha256=digest))
            (target/'provenance.json').write_text(json.dumps(dict(version=version,publicCommit=row['publicCommit'],files=records)),encoding='utf-8')
        command=UTF8+"$ErrorActionPreference='Stop';$repo="+quote(ROOT)+";$folder="+quote(cls.shared_path)+";$e=$null;"+ \
            "$a=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Deployment/Deploy-All.ps1'),[ref]$null,[ref]$e);foreach($name in @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'PURE_HELPER'};. ([scriptblock]::Create($n[0].Extent.Text))};"+ \
            "$old=@();foreach($v in @('2.0.0','3.0.0','3.1.0','4.0.0','4.1.0')){$root=Join-Path $folder ('genuine-'+$v);$texts=@{};foreach($m in @('local','central')){$n=Get-SqlcmdScriptTree -Path (Join-Path $root 'Deployment/Deploy.sql') -Cache @{};$text=ConvertTo-StandaloneSql -Node $n -Values @{DeploymentMode=$m;ConfirmNoExternalConsumers='1'} -ModulesRoot $root;$path=Join-Path $folder ($v+'.'+$m+'.sql');[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));$texts[$m]=$path};$old+=@(@{version=$v;root=$root;texts=$texts})};"+ \
            "$current=@{};foreach($m in @('local','central')){$current[$m]=@{};foreach($kind in @('Deploy','Uninstall')){$n=Get-SqlcmdScriptTree -Path (Join-Path $repo ('Modules/toolbelt.metadata.table-clone/Deployment/'+$kind+'.sql')) -Cache @{};$text=ConvertTo-StandaloneSql -Node $n -Values @{DeploymentMode=$m;ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules');$path=Join-Path $folder ($m+'.'+$kind+'.sql');[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));$current[$m][$kind]=$path}};@{predecessors=$old;currentTexts=$current}|ConvertTo-Json -Depth 8 -Compress"
        result=subprocess.run(['pwsh','-NoProfile','-NonInteractive','-Command',command],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',timeout=30)
        if result.returncode:raise RuntimeError(result.stdout+result.stderr)
        cls.rendered=json.loads(result.stdout)

    @classmethod
    def tearDownClass(cls):cls.shared.cleanup()

    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='clone-known-admission-',dir=ROOT/'.runtime')
        self.directory=Path(self.temp.name)
        for path in self.shared_path.iterdir():
            if path.is_dir():shutil.copytree(path,self.directory/path.name)
            else:shutil.copyfile(path,self.directory/path.name)
        def localize(value):
            if isinstance(value,dict):return {k:localize(v) for k,v in value.items()}
            if isinstance(value,list):return [localize(v) for v in value]
            return str(self.directory/Path(value).name) if isinstance(value,str) and value.startswith(str(self.shared_path)) else value
        rendered=localize(self.rendered)
        exports={}
        for mode in ('local','central'):
            path=self.directory/(mode+'.dependency.sql');path.write_text('-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n',encoding='utf-8');exports[mode]=str(path)
        required=[ROOT/p for p in ('Tests/Release/Invoke-ApiQualificationLab.ps1','Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1','Tests/CI/Set-SqlClientTlsPolicy.ps1','Tests/CI/Assert-LabQualifiedTlsBinding.ps1',
            'Deployment/Deploy-All.ps1','Modules/toolbelt.metadata.table-clone/Deployment/Deploy.sql','Modules/toolbelt.metadata.table-clone/Deployment/Uninstall.sql')]
        required.extend((ROOT/'Modules/toolbelt.metadata.table-clone/Source').glob('*.sql'))
        files=[DRIVER,*required,*(p for p in self.directory.rglob('*') if p.is_file())]
        cases=[]
        for platform in ('windows','linux'):
            for version,patch,levels in (('2019','CU32',(150,)),('2022','CU26',(150,160)),('2025','CU8',(150,160,170))):
                cases.extend(dict(Platform=platform,Version=version,Patch=patch if platform=='windows' else 'latest',CL=level,modes=['local','central']) for level in levels)
        start=datetime.now(timezone.utc)-timedelta(seconds=5)
        self.record=dict(schema_version='table-clone-known-predecessors/v1',explicit_qualification_approved=True,cases=cases,exports=exports,
            started_utc=start.isoformat(),deadline_utc=(start+timedelta(minutes=60)).isoformat(),pins=[dict(path=str(p),sha256=sha(p)) for p in files],**rendered)

    def tearDown(self):self.temp.cleanup()

    def admission(self,record):
        path=self.directory/'runset.json';path.write_text(json.dumps(record),encoding='utf-8')
        result=subprocess.run(['pwsh','-NoProfile','-NonInteractive','-Command',UTF8+'& '+quote(DRIVER)+' -RunsetPath '+quote(path)+' -CaseIndex 11 -ValidateOnly'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',timeout=30)
        self.assertEqual(list(self.directory.glob('case-*')),[])
        return result

    def reject(self,mutate,category):
        record=copy.deepcopy(self.record);mutate(record);result=self.admission(record)
        self.assertNotEqual(result.returncode,0)
        self.assertIn(category,result.stdout+result.stderr)

    def repin(self,record,path):
        matches=[p for p in record['pins'] if p['path']==str(path)];self.assertEqual(len(matches),1);matches[0]['sha256']=sha(path)

    def test_valid_all_originals_without_lab(self):
        result=self.admission(self.record);self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_approval_requires_bool(self):
        self.reject(lambda r:r.update(explicit_qualification_approved='true'),'RUNSET_SCOPE')

    def test_no_missing_original_version(self):
        self.reject(lambda r:r['predecessors'].pop(),'PREDECESSOR_SET')

    def test_no_reordered_originals(self):
        self.reject(lambda r:r['predecessors'].reverse(),'VERSION_ORDER')

    def test_original_bytes_cannot_be_rehashed(self):
        def mutate(r):
            path=Path(r['predecessors'][0]['root'])/'Source/USP_ScriptTableClone.sql';path.write_bytes(path.read_bytes()+b'\n-- Synthetic forged original\n');self.repin(r,path)
        self.reject(mutate,'ORIGINAL_BYTES')

    def test_original_provenance_cannot_be_rehashed(self):
        def mutate(r):
            path=Path(r['predecessors'][2]['root'])/'provenance.json';v=json.loads(path.read_text(encoding='utf-8'));v['publicCommit']='0'*40;path.write_text(json.dumps(v),encoding='utf-8');self.repin(r,path)
        self.reject(mutate,'PUBLIC_PROVENANCE')

    def test_rendered_original_cannot_be_rehashed(self):
        def mutate(r):
            path=Path(r['predecessors'][3]['texts']['central']);path.write_bytes(path.read_bytes()+b'\nSELECT 1;\n');self.repin(r,path)
        self.reject(mutate,'ORIGINAL_RENDER')

    def test_current_tree_pin_is_required(self):
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if Path(p['path']).name!='USP_CopyTableCloneData.sql' or not str(ROOT/'Modules') in p['path']]),'SOURCE_TREE_PIN')

    def test_wrong_cl_is_rejected(self):
        self.reject(lambda r:r['cases'][0].update(CL=160),'CONTEXT_SCOPE')

    def test_central_mode_is_required(self):
        self.reject(lambda r:r['cases'][0].update(modes=['local']),'CONTEXT_SCOPE')

    def test_deadline_cannot_extend(self):
        self.reject(lambda r:r.update(deadline_utc=(datetime.fromisoformat(r['started_utc'])+timedelta(minutes=61)).isoformat()),'ADMISSION_CLOSED')

    def test_dependency_export_cannot_include_clone(self):
        def mutate(r):
            path=Path(r['exports']['local']);path.write_bytes(path.read_bytes()+b'-- BEGIN MODULE toolbelt.metadata.table-clone\nSELECT 1;\n');self.repin(r,path)
        self.reject(mutate,'DEPENDENCY_ONLY_EXPORT')

    def test_tls_policy_is_pinned(self):
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if Path(p['path']).name!='Set-SqlClientTlsPolicy.ps1']),'REQUIRED_PIN_MISSING')

if __name__=='__main__':unittest.main()
