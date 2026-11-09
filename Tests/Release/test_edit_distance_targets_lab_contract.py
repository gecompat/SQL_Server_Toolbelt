"""Native Zielzulassung und Originalpaketbindung ohne Labzugriff oder SQL."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy,hashlib,json,shutil,subprocess,tempfile,unittest,zipfile
ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-EditDistanceTargetsLab.ps1'
Q=ROOT/'Releases/1.0.0/EDIT-DISTANCE-PACKAGE-QUALIFICATION.json'
FIXTURES=('Distance.Contract.sql','Distance.Boundaries.sql','Jaro.Contract.sql',
          'Jaro.Boundaries.sql','InstalledMetadata.Contract.sql','Lifecycle.Contract.sql')
@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class DistanceTargetAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='distance-target-admission-',dir=ROOT/'.runtime')
        self.directory=Path(self.temp.name)
        q=json.loads(Q.read_bytes());package=ROOT/q['package']['path']
        with zipfile.ZipFile(package) as z:
            bits=z.read('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.String.EditDistance.dll')
        binary=self.directory/'qualified.dll';binary.write_bytes(bits)
        exports={}
        for mode in ('local','central'):
            p=self.directory/(mode+'.sql');p.write_text('-- BEGIN MODULE toolbelt.string.edit-distance\nSELECT 1;\n',encoding='utf-8');exports[mode]=str(p)
        fixtures=[ROOT/'Modules/toolbelt.string.edit-distance/Tests/Runtime'/n for n in FIXTURES]
        files=[DRIVER,Q,package,binary,*fixtures,*(Path(p) for p in exports.values()),*(ROOT/p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1','Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/Release/ClrCaller.Environment.ps1','Tests/CI/run-csv-memory-lab.ps1',
            'Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1'))]
        files=list(dict.fromkeys([*files,*(ROOT/p for p in q['module_source_sha256'])]))
        started=datetime.now(timezone.utc)-timedelta(seconds=5)
        tuples=(('windows','2019','CU32',150),('windows','2022','CU26',150),('windows','2022','CU26',160),
                ('linux','2022','latest',150),('linux','2022','latest',160),('linux','2025','latest',150),
                ('linux','2025','latest',160),('linux','2025','latest',170))
        self.record=dict(schema_version='edit-distance-targets/v1',explicit_qualification_approved=True,
            started_utc=started.isoformat(),deadline_utc=(started+timedelta(minutes=45)).isoformat(),
            cases=[dict(Platform=p,Version=v,Patch=t,CL=c) for p,v,t,c in tuples],fixtures=list(map(str,fixtures)),
            provenance=str(Q),package=str(package),exports=exports,
            artifacts=[dict(module_id='toolbelt.string.edit-distance',sql_name='Toolbelt_String_EditDistance',path=str(binary),
                            sha256=hashlib.sha256(bits).hexdigest().upper(),sha512=hashlib.sha512(bits).hexdigest().upper())],
            module_versions={'toolbelt.string.edit-distance':'1.1.0'},
            pins=[dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files])
    def tearDown(self):
        self.temp.cleanup()
    def admission(self,record=None):
        p=self.directory/'runset.json';p.write_text(json.dumps(record or self.record),encoding='utf-8')
        result=subprocess.run(['pwsh','-NoProfile','-File',str(DRIVER),'-RunsetPath',str(p),
                               '-CaseIndex','7','-ValidateOnly'],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(list(self.directory.glob('case-*')),[])
        return result
    def reject(self,mutate):
        record=copy.deepcopy(self.record);mutate(record);result=self.admission(record)
        self.assertNotEqual(result.returncode,0,result.stdout+result.stderr)
    def test_valid_original_package_without_sql(self):
        result=self.admission();self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertIn('no Lab import or SQL',result.stdout)
    def test_authority_requires_true_boolean(self):
        self.reject(lambda r:r.update(explicit_qualification_approved=False))
        self.reject(lambda r:r.update(explicit_qualification_approved='true'))
    def test_expiry_and_extension_are_rejected(self):
        past=datetime.now(timezone.utc)-timedelta(hours=2)
        self.reject(lambda r:r.update(started_utc=past.isoformat(),deadline_utc=(past+timedelta(minutes=45)).isoformat()))
        self.reject(lambda r:r.update(deadline_utc=(datetime.now(timezone.utc)+timedelta(hours=1)).isoformat()))
    def test_targets_cannot_reuse_qualified_or_relabelled_context(self):
        self.reject(lambda r:r['cases'][0].update(Version='2025',Patch='CU8'))
        self.reject(lambda r:r['cases'][3].update(Version='2019'))
        self.reject(lambda r:r['cases'][7].update(CL=150))
    def test_canonical_fixture_and_method_pins_required(self):
        self.reject(lambda r:r['fixtures'].pop())
        self.reject(lambda r:r['pins'].pop(0))
    def test_changed_binary_rejected(self):
        Path(self.record['artifacts'][0]['path']).write_bytes(b'unqualified')
        self.assertNotEqual(self.admission().returncode,0)
    def test_repinning_other_binary_does_not_create_provenance(self):
        p=Path(self.record['artifacts'][0]['path']);p.write_bytes(b'unqualified')
        record=copy.deepcopy(self.record);record['artifacts'][0]['sha256']=hashlib.sha256(p.read_bytes()).hexdigest().upper()
        record['artifacts'][0]['sha512']=hashlib.sha512(p.read_bytes()).hexdigest().upper()
        next(x for x in record['pins'] if x['path']==str(p))['sha256']=record['artifacts'][0]['sha256']
        self.assertNotEqual(self.admission(record).returncode,0)
    def test_original_report_path_cannot_be_replaced(self):
        p=self.directory/'forged.json';p.write_bytes(Q.read_bytes())
        def mutate(r):
            r['provenance']=str(p);r['pins'].append(dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()))
        self.reject(mutate)
    def test_changed_export_rejected(self):
        Path(self.record['exports']['local']).write_text('SELECT 2;',encoding='utf-8')
        self.assertNotEqual(self.admission().returncode,0)
    def test_wrong_module_version_and_missing_source_pin(self):
        self.reject(lambda r:r['module_versions'].update({'toolbelt.string.edit-distance':'1.0.0'}))
        path=str(ROOT/'Modules/toolbelt.string.edit-distance/Clr/DistanceKernel.cs')
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if p['path']!=path]))
if __name__=='__main__':
    unittest.main()
