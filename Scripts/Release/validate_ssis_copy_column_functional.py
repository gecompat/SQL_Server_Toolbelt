"""Strikte aktuelle ZIP-/Prozedur-/Rechtematrix, keine Modul- oder TLS-Aufwertung."""
import hashlib
import json
import re
from pathlib import Path
import validate_ssis_copy_column_delivery as delivery

ROOT=Path(__file__).resolve().parents[2]
MODULE=delivery.MODULE
REPORT=MODULE+'Tests/Qualification/CopyColumn.Functional.20261115.json'
METHODS=(MODULE+'Tests/Qualification/Current.Build.20261104.json',
         MODULE+'Tests/Qualification/CopyColumn.Delivery.20261115.json',
         MODULE+'Tests/Qualification/CopyColumn.V1.20261114.json',
         delivery.ARCHIVE,'Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1',
         'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs')

def require(value,label):
    if not value:raise ValueError('SSIS_COPY_FUNCTIONAL_'+label)

def source_paths():
    paths=set(METHODS)
    for folder in ('Tests/Runtime','Tests/Fixtures'):
        paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT/MODULE/folder).rglob('*') if p.is_file())
    paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT/MODULE/'Clr').iterdir() if p.suffix in ('.cs','.csproj'))
    paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT/MODULE/'Exchange/Core').glob('*.cs'))
    return paths

def validate(record=None,*,check_files=True):
    r=record if record is not None else json.loads((ROOT/REPORT).read_bytes())
    require(set(r)=={'kind','profile','date','result','scope','runtime_source_commit','package','framework_reuse',
        'rights_scope','user_rights_exception_recorded','cases','contexts','package_assertions','functional_assertions',
        'procedure_assertions','assertions','fresh_audits','owned_databases_removed','owned_procedure_logins_removed',
        'temporary_api_users_removed_with_own_scope','accounting','source_sha256'},'ROOT_KEYS')
    require(r['kind']=='ssis_copy_column_functional_zip_native_qualification' and
            r['profile']=='ssis-debug-copy-column-v1' and r['date']=='2026-11-15' and
            r['result']=='PASS_FOR_DECLARED_SCOPE','IDENTITY')
    require(r['scope']=={'fresh_full_functional_zip_matrix':True,'actual_procedure_and_rights':True,
        'cross_database_consumer':True,'temporary_principals_and_grants':True,'fresh_ssms':False,
        'fresh_authenticated_tls':False,'full_module_qualification':False,'publication_authorized':False}
        and all(type(v) is bool for v in r['scope'].values()),'SCOPE')
    require(r['runtime_source_commit']=='123bf820fa44bc1d70d534775b78011dcc24937a','RUNTIME_SOURCE')
    require(r['framework_reuse']=={'profile':'Full','bounded_children':29,'same_qualified_dll':True,'new_execution':False}
        and r['framework_reuse']['same_qualified_dll'] is True and r['framework_reuse']['new_execution'] is False,'FRAMEWORK_REUSE')
    require(r['rights_scope']=='synthetic-api-user-and-procedure-login-v1' and
            r['user_rights_exception_recorded'] is True,'RIGHTS_SCOPE')
    totals={'contexts':12,'package_assertions':96,'functional_assertions':12444,'procedure_assertions':2664,
            'assertions':15204,'fresh_audits':12,'owned_databases_removed':24,'owned_procedure_logins_removed':12,
            'temporary_api_users_removed_with_own_scope':12}
    require(all(type(r[k]) is int and r[k]==v for k,v in totals.items()),'TOTALS')
    require(len(r['cases'])==12,'CONTEXTS')
    keys={'platform','sql_version','patch','compatibility_level','deployment_mode','result','package_assertions',
          'functional_assertions','procedure_assertions','functional_subcase_assertions','fresh_independent_audit',
          'audit_binds_final_journal','owned_databases_created','owned_databases_removed','owned_procedure_login_removed',
          'configuration_restored_or_unchanged','own_trust_absence_audited','test_purpose','authenticated_tls'}
    for c,(v,p,cl,m) in zip(r['cases'],delivery.CONTEXTS):
        require(set(c)==keys and (c['sql_version'],c['patch'],c['compatibility_level'],c['deployment_mode'])==(v,p,cl,m)
                and type(c['compatibility_level']) is int,'ROSTER')
        require(c['platform']=='Windows' and c['result']=='PASS_CLEANED' and c['fresh_independent_audit']=='PASS'
                and c['test_purpose']=='Functional' and c['authenticated_tls']=='not executed','CASE_RESULT')
        expected={'SSIS_CURRENT_NATIVE_PASS':208,'SSIS_CURRENT_QUALIFICATION_SEMANTICS_PASS':742 if cl==170 else 688,
                  'SSIS_NATIVE_API_PASS':87,'SSIS_RELEASE_RIGHTS_PASS':30,'SSIS_NATIVE_LIFECYCLE_PASS':15}
        require(c['functional_subcase_assertions']==expected and
                all(type(n) is int for n in c['functional_subcase_assertions'].values()),'SUBCASES')
        require(all(type(c[k]) is int and c[k]==n for k,n in
            [('package_assertions',8),('functional_assertions',1082 if cl==170 else 1028),
             ('procedure_assertions',222),('owned_databases_created',2),('owned_databases_removed',2)]),'CASE_COUNTS')
        require(all(c[k] is True for k in ('audit_binds_final_journal','owned_procedure_login_removed',
            'configuration_restored_or_unchanged','own_trust_absence_audited')),'CASE_CLEANUP')
    a=r['accounting']
    require(a=={'reserved_target_audit_calls':24,'actual_driver_dispatches':24,'database_reservations':24,
        'login_reservations':12,'db_only_user_reservations':12,'maximum_minutes':180,'failed_native_cases':0,'retries':0,
        'within_original_window':True,'closed':True,'previous_failures_and_closed_limits_preserved':True}
        and all(a[k] is True for k in ('within_original_window','closed','previous_failures_and_closed_limits_preserved'))
        and all(type(a[k]) is int for k in ('reserved_target_audit_calls','actual_driver_dispatches','database_reservations',
            'login_reservations','db_only_user_reservations','maximum_minutes','failed_native_cases','retries')),'ACCOUNTING')
    original=json.loads((ROOT/delivery.REPORT).read_bytes())
    require(r['package']==original['package'],'PACKAGE_BINDING')
    sources=r['source_sha256']
    require(set(sources)==source_paths() and all(type(h) is str and re.fullmatch('[0-9a-f]{64}',h) for h in sources.values()),'SOURCE_CLOSURE')
    if check_files:
        for path,digest in sources.items():
            require(hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,'SOURCE_DRIFT')
        delivery.validate()
    return r

if __name__=='__main__':
    from ssis_historical_scope import copy_column_v1_scope
    with copy_column_v1_scope(ROOT):
        validate()
    print('SSIS_COPY_COLUMN_FUNCTIONAL_ZIP_PASS; 12contexts/15204assertions/12freshaudits; no whole-module/TLS claim')
