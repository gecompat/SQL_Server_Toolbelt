"""Gegenproben gegen ungebundene oder zu weit ausgelegte Hostnachweise."""
import copy
import hashlib
import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_ssis_copy_column_host as validator


def synthetic_record():
    # Synthetischer Validatorinput, kein behaupteter nativer Lauf.
    pins=validator.method.source_pins(ROOT)
    cases=[{'name':name,'assertions':count,'exit_code':exit_code,
            'output_sha256':hashlib.sha256(b'').hexdigest() if exit_code else 'a'*64}
           for name,count,exit_code in zip(validator.NAMES,validator.COUNTS,validator.EXITS)]
    base={'contract':'ssis-export-host-native/1','date':'2026-11-15','platform':'Windows',
          'result':'PASS','sql_executed':False,'host_sha256':validator.HOST_SHA256,'source_commit':validator.PRODUCT_COMMIT,
          'source_sha256':validator.method.base.source_pins(ROOT),'case_count':17,'assertions':169,'cases':cases}
    copies=[{'name':f'copy-column-{version}-{kind}:version{cv}','exit_code':0,'assertions':17,
             'output_sha256':'d'*64} for version in (6,8) for kind in ('int','text') for cv in (1,2)]
    run={'contract':'ssis-copy-column-export-host-native/1','date':'2026-11-15','platform':'Windows',
         'result':'PASS','sql_executed':False,'host_sha256':validator.HOST_SHA256,'source_commit':validator.PRODUCT_COMMIT,
         'source_sha256':pins,'base':base,'copy_cases':copies,'case_count':25,'assertions':305}
    linux=copy.deepcopy(run); linux['platform']='Linux';linux['base']['platform']='Linux'
    return {'contract':'ssis-copy-column-export-host-qualification/1','date':'2026-11-15',
            'result':'PASS_FOR_DECLARED_SCOPE', 'case_count':50,'assertions':610,
            'scope':{'current_model_and_cli':True,'sql_executed':False,'sql_clr_linux':False,
                     'full_module_qualification':False,'native_ssis_runtime':False,'fresh_zip_matrix':False,
                     'fresh_ssms':False,'fresh_authenticated_tls':False,'publication_authorized':False},
            'runtime':{'version':'10.0.14','rid':'linux-x64',
                       'archive_url':'https://builds.dotnet.microsoft.com/dotnet/Runtime/10.0.14/dotnet-runtime-10.0.14-linux-x64.tar.gz',
                       'archive_sha512':validator.RUNTIME_SHA512,
                       'installation':'private test directory; no global installation'},
            'history':{'platform_dispatches':4,'complete_platform_runs':2,
                       'pre_profile_failed_dispatches':2,'successful_host_profile_processes':50,
                       'windows_success_reused_without_repeat':True,'private_runtime_absence_verified':True,
                       'original_failures_preserved':True,'closed':True},
            'runs':[run,linux]}


class HostEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.record=synthetic_record()

    def reject(self,change,label):
        change(self.record)
        with self.assertRaisesRegex(ValueError,label):
            validator.validate(self.record)

    def test_synthetic_validator_input(self):
        validator.validate(self.record)

    def test_actual_bound_native_record(self):
        if not (ROOT/validator.REPORT).exists():
            self.skipTest('Native record not yet present; synthetic controls are not native qualification')
        validator.validate()

    def test_old_receipt_cannot_be_promoted(self):
        self.reject(lambda r:r.update(contract='ssis-linux-export-qualification/1'),'HEADER')

    def test_second_platform_required(self):
        self.reject(lambda r:r['runs'][1].update(platform='Windows'),'PLATFORMS')

    def test_actual_binary_and_semantic_outputs_equal(self):
        for key in ('host_sha256','source_commit'):
            with self.subTest(key=key):
                r=synthetic_record();r['runs'][1][key]='e'*len(r['runs'][1][key])
                with self.assertRaises(ValueError):validator.validate(r)
        self.reject(lambda r:r['runs'][1]['copy_cases'][0].update(output_sha256='e'*64),'CROSS_PLATFORM_EQUALITY')

    def test_missing_or_reordered_copy_profile_rejected(self):
        self.reject(lambda r:r['runs'][0]['copy_cases'].reverse(),'COPY_ORACLE')

    def test_inaccurate_counts_and_boolean_numbers_rejected(self):
        for field,value in (('assertions',609),('case_count',True)):
            with self.subTest(field=field):
                r=synthetic_record();r[field]=value
                with self.assertRaisesRegex(ValueError,'TOTALS'):validator.validate(r)
        self.reject(lambda r:r['runs'][0]['copy_cases'][0].update(exit_code=False),'COPY_ORACLE')

    def test_changed_source_and_runtime_rejected(self):
        key=next(iter(self.record['runs'][0]['source_sha256']))
        self.reject(lambda r:r['runs'][0]['source_sha256'].update({key:'e'*64}),'SOURCE_DRIFT')
        self.record=synthetic_record()
        self.reject(lambda r:r['runtime'].update(archive_sha512='0'*128),'RUNTIME')

    def test_scope_cannot_be_enlarged(self):
        for key in ('sql_executed','sql_clr_linux','full_module_qualification','native_ssis_runtime',
                    'fresh_zip_matrix','fresh_ssms','fresh_authenticated_tls','publication_authorized'):
            with self.subTest(key=key):
                r=synthetic_record();r['scope'][key]=True
                with self.assertRaisesRegex(ValueError,'SCOPE'):validator.validate(r)
        self.reject(lambda r:r['scope'].update(current_model_and_cli=1),'SCOPE')



# Historische C7-Quellenbindung bleibt von der aktuellen Korrektur getrennt.
import sys
sys.path.insert(0,str(ROOT/'Scripts/Release'))
from ssis_historical_scope import copy_column_v1_scope
def setUpModule():
    global _historical_scope, _original_paths
    _historical_scope=copy_column_v1_scope(ROOT)
    snapshot=_historical_scope.__enter__()
    _original_paths={key:value for key,value in list(globals().items())
                     if isinstance(value,Path) and value.is_relative_to(ROOT)}
    original=ROOT
    for key,value in _original_paths.items():
        globals()[key]=snapshot/value.relative_to(original)
def tearDownModule():
    globals().update(_original_paths)
    _historical_scope.__exit__(None,None,None)

if __name__=='__main__':
    unittest.main()
