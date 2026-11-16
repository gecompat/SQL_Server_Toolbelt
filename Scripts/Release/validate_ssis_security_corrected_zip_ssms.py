"""Frische ZIP-/SSMS-Abnahme des sicherheitskorrigierten Providers; kein neuer SQL-Lauf."""
from pathlib import Path
import hashlib
import json
from new_ssis_current_package import SECURITY_PROFILE, validate_native_record
from validate_ssis_current_package import validate as validate_package
ROOT=Path(__file__).resolve().parents[2]
AREA='Modules/toolbelt.tsql.ssis-debug/'
REPORT=AREA+'Tests/Qualification/Current.ZipSsms.20261116.json'
BUILD=AREA+'Tests/Qualification/CopyColumn.Build.20261116.json'
PACKAGE=AREA+'Tests/Qualification/CopyColumn.Package.20261116.json'
CONTEXTS={(v,p,cl,mode) for v,p,levels in [('2019','CU32',[150]),('2022','CU26',[150,160]),('2025','CU8',[150,160,170])] for cl in levels for mode in ('local','central')}

def require(ok,label):
    if not ok:raise ValueError('SSIS_CURRENT_ZIP_SSMS_'+label)

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def _validate_scope(record=None,*,check_files=True):
    r=record if record is not None else json.loads((ROOT/REPORT).read_bytes())
    require(r['kind']=='ssis_security_corrected_zip_ssms_qualification' and r['date']=='2026-11-16' and r['result']=='PASS_FOR_DECLARED_SCOPE','IDENTITY')
    require(r['scope']=={'fresh_current_windows_zip_matrix':True,'fresh_windows_ssms':True,'same_provider_strict_tls_reused':True,'same_provider_security_acceptance_reused':True,'full_module_qualification':False,'current_linux_host_reexecuted':False,'publication_authorized':False},'SCOPE')
    require(all(type(v) is bool for v in r['scope'].values()),'SCOPE_TYPES')
    b=json.loads((ROOT/BUILD).read_bytes());p=json.loads((ROOT/PACKAGE).read_bytes())
    validate_native_record(b,SECURITY_PROFILE)
    require(r['provider']==b['provider'] and r['package']==p['package'],'CURRENT_ARTIFACT_BINDING')
    cases=r['zip_matrix']['cases']
    require(len(cases)==12 and {(c['sql_version'],c['patch'],c['compatibility_level'],c['deployment_mode']) for c in cases}==CONTEXTS,'MATRIX')
    for c in cases:
        require(c['platform']=='Windows' and c['result']=='PASS_CLEANED' and c['fresh_independent_audit']=='PASS' and c['audit_binds_final_journal'] is True,'CASE_AUDIT')
        require(c['package_assertions']==8 and c['procedure_assertions']==222 and c['functional_assertions']==(1082 if c['compatibility_level']==170 else 1028),'CASE_ASSERTIONS')
        require(c['owned_databases_removed']==2 and c['owned_procedure_login_removed'] is True and c['configuration_restored_or_unchanged'] is True and c['own_trust_absence_audited'] is True,'CASE_CLEANUP')
        require(c['test_purpose']=='Functional' and c['authenticated_tls']=='not executed','FUNCTIONAL_TRANSPORT')
    total=sum(c['package_assertions']+c['procedure_assertions']+c['functional_assertions'] for c in cases)
    require(total==r['zip_matrix']['assertions']==15204 and r['zip_matrix']['fresh_audits']==12,'TOTALS')
    gui=r['ssms']
    require(gui['target']=={'platform':'Windows','sql_version':'2025','patch':'CU8','compatibility_level':150,'deployment_mode':'local','test_purpose':'Functional','authentication':'Windows','auth_scheme':'NTLM','encrypt':True,'trust_server_certificate':True},'GUI_TARGET')
    c=gui['case']
    require(c['coordinator_result']=='PASS_CLEANED' and c['checks']==17 and c['completed_cases']==1 and c['public_installer_passes']==2 and c['visible_gui_executions']==4,'GUI_TOTAL_CASE')
    require(c['copied_utf16_lf_units']==184441 and c['native_expected_error']==51001 and c['negative_receipt_phase_unchanged']==1 and c['receipt_phase']==2 and c['result_rows']==2 and c['unexpected_execution_errors']==0,'GUI_RECEIPT')
    for key in ('same_owned_ssms_instance','exact_lab_target','windows_preflight','complete_unicode_grid_copy','copy_hash_verified_before_execution','sqlcmd_mode','later_batch_stopped','executed_editor_text_verified','full_script_and_receipt_executed','own_ssms_closed'):
        require(c[key] is True,'GUI_'+key.upper())
    require(gui['audit']=={'result':'PASS','fresh_independent_windows_process':True,'binds_exact_final_journal':True,'owned_databases_removed':1,'configuration_restored':True,'trust_restored':True,'other_consumers_unchanged':True},'GUI_AUDIT')
    require(gui['assistance']=={'authentication_automated':False,'manual_steps':['Windows authentication','per-query grid copy options'],'gui_executions_by_agent':4},'GUI_ASSISTANCE')
    require(r['accounting']['completed_native_calls']==26 and r['accounting']['owned_databases_removed']==25 and r['accounting']['owned_logins_removed']==12 and r['accounting']['native_failures']==0 and r['accounting']['retries']==0 and r['accounting']['closed'] is True,'ACCOUNTING')
    required={BUILD,PACKAGE,'Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1'}
    required.update(AREA+'Tests/WindowsClientRecovery/'+p for p in ('Invoke-SecurityCorrectedSsms.ps1','SecurityCorrectedArtifacts.ps1','Invoke-CurrentBuildSsms.ps1','RecoveryFixture.ps1','SsmsSqlcmdHook.ps1','New-SsmsSqlcmdEnvelope.ps1','Test-SsmsScriptCopy.ps1'))
    for folder in ('Tests/Runtime','Tests/Fixtures','Clr','Exchange/Core'):
        required.update(str(p.relative_to(ROOT)).replace('\\','/') for p in (ROOT/AREA/folder).rglob('*') if p.is_file() and ('/bin/' not in p.as_posix() and '/obj/' not in p.as_posix()) and (folder!='Clr' or p.suffix in ('.cs','.csproj')))
    require(required<=set(r['source_sha256']),'SOURCE_CLOSURE')
    if check_files:
        validate_package(ROOT/r['package']['path'],profile=SECURITY_PROFILE)
        for path,digest in r['source_sha256'].items():
            resolved=(ROOT/path).resolve()
            require(resolved.is_relative_to(ROOT.resolve()) and sha(resolved)==digest,'SOURCE_'+path)
        for path,digest in r['evidence_reuse'].items():
            require(path in b['evidence'] and sha(ROOT/path)==digest==b['evidence'][path],'REUSED_EVIDENCE')
        require(set(r['evidence_reuse'])==set(b['evidence']),'REUSED_EVIDENCE_SET')
    return r


def qualification_records(record=None,*,check_files=True):
    r=_validate_scope(record,check_files=check_files)
    if not check_files:return r,None
    import validate_ssis_copy_column_tls_security as tls
    from ssis_historical_scope import security_corrected_tls_scope
    original=json.loads((ROOT/tls.REPORT).read_bytes())
    # Kein alter PASS wird auf geänderte konsumierte Eingaben übertragen.
    for path,digest in original['source_sha256'].items():
        require(sha(ROOT/path)==digest,'REUSED_TLS_INPUT_DRIFT')
    added=tls.source_paths()-set(original['source_sha256'])
    require(added=={AREA+'Tests/Runtime/Invoke-SecurityCorrectedFunctionalLab.ps1'} and added<=set(r['source_sha256']),
            'REUSED_TLS_UNQUALIFIED_ADDITION')
    with security_corrected_tls_scope(ROOT):
        reused=tls.validate(original)
    require(reused['provider']==r['provider'],'REUSED_TLS_PROVIDER')
    return r,reused


def validate(record=None,*,check_files=True):
    return qualification_records(record,check_files=check_files)[0]

if __name__=='__main__':
    validate();print('SSIS_CURRENT_ZIP_SSMS_QUALIFICATION_PASS; private originals retained; no SQL or GUI repetition')
