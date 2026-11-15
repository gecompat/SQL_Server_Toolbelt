"""Strikte Anerkennung der aktuellen ZIP-Liefermatrix ohne SQL-Ausführung."""
import hashlib
import json
import re
from pathlib import Path
import zipfile

ROOT=Path(__file__).resolve().parents[2]
MODULE='Modules/toolbelt.tsql.ssis-debug/'
REPORT=MODULE+'Tests/Qualification/CopyColumn.Delivery.20261115.json'
ARCHIVE=MODULE+'InstallPackages/SSIS-Debug-CopyColumnV1-Install-Windows.zip'
PACKAGE_NAME='SSIS-Debug-CopyColumnV1-Install-Windows'
QUALIFICATION=MODULE+'Tests/Qualification/CopyColumn.V1.20261114.json'
CONTEXTS=tuple((v,p,cl,m) for v,p,levels in [('2019','CU32',[150]),('2022','CU26',[150,160]),('2025','CU8',[150,160,170])]
               for cl in levels for m in ('local','central'))
METHODS=tuple(MODULE+'Tests/Runtime/'+n for n in ('Invoke-CopyColumnDeliveryLab.ps1','Invoke-LabContract.ps1',
               'Invoke-PackageInstallCases.ps1','Invoke-ComponentsV2Lab.ps1','Invoke-ComponentsV2Audit.ps1'))+(
               'Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1',QUALIFICATION)


def require(value,label):
    if not value:raise ValueError('SSIS_COPY_DELIVERY_'+label)


def source_paths():
    paths=set(METHODS)
    paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT/MODULE/'Clr').iterdir() if p.suffix in ('.cs','.csproj'))
    paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT/MODULE/'Exchange/Core').glob('*.cs'))
    paths.add('Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs')
    return paths


def validate(record=None,*,check_files=True):
    r=record if record is not None else json.loads((ROOT/REPORT).read_bytes())
    require(set(r)=={'kind','profile','date','result','scope','package','framework_reuse','cases','contexts',
                    'package_assertions','fresh_audits','owned_databases_removed','history','source_sha256'},'ROOT_KEYS')
    require(r['kind']=='ssis_copy_column_zip_delivery_native_qualification' and r['profile']=='ssis-debug-copy-column-v1' and
            r['date']=='2026-11-15' and r['result']=='PASS_FOR_DECLARED_SCOPE','IDENTITY')
    require(r['scope']=={'actual_archive_install_matrix':True,'fresh_full_functional_zip_matrix':False,
        'full_module_qualification':False,'source_api_suites_reexecuted':False,'cross_database_consumer':False,
        'new_principals_or_grants':False,'fresh_ssms':False,'fresh_authenticated_tls':False,'publication_authorized':False}
        and all(type(v) is bool for v in r['scope'].values()),'SCOPE')
    require(r['framework_reuse']=={'profile':'Full','bounded_children':29,'same_qualified_dll':True,'new_execution':False}
            and r['framework_reuse']['same_qualified_dll'] is True and r['framework_reuse']['new_execution'] is False,'FRAMEWORK_REUSE')
    require(all(type(r[key]) is int and r[key]==value for key,value in
                [('contexts',12),('package_assertions',96),('fresh_audits',12),('owned_databases_removed',12)]),'TOTALS')
    cases=r['cases'];require(len(cases)==12,'CONTEXTS')
    keys={'platform','sql_version','patch','compatibility_level','deployment_mode','result','package_assertions',
          'fresh_independent_audit','audit_binds_final_journal','owned_databases_created','owned_databases_removed',
          'configuration_restored_or_unchanged','own_trust_absence_audited','test_purpose','authenticated_tls'}
    for case,(version,patch,cl,mode) in zip(cases,CONTEXTS):
        require(set(case)==keys and (case['sql_version'],case['patch'],case['compatibility_level'],case['deployment_mode'])==
                (version,patch,cl,mode) and type(case['compatibility_level']) is int,'ROSTER')
        require(case['platform']=='Windows' and case['result']=='PASS_CLEANED' and case['fresh_independent_audit']=='PASS' and
                case['test_purpose']=='Functional' and case['authenticated_tls']=='not executed','CASE_RESULT')
        require(all(type(case[key]) is int and case[key]==n for key,n in
                    [('package_assertions',8),('owned_databases_created',1),('owned_databases_removed',1)]),'CASE_COUNTS')
        require(all(case[key] is True for key in ('audit_binds_final_journal','configuration_restored_or_unchanged',
                                                'own_trust_absence_audited')),'CASE_CLEANUP')
    require(r['history']=={'pre_sql_failed_attempts':1,'failed_attempt_sql_executed':False,'failed_attempt_journal_created':False,
        'failed_attempt_independent_sql_audit':'not executed; no SQL or journal','original_failure_preserved':True,
        'reserved_target_audit_calls':26,'actual_driver_dispatches':25,'reserved_not_dispatched_audits':1,
        'database_reservations':13,'changed_adapter_contexts':1,'original_sixty_minute_clock_preserved':True,'closed':True}
        and all(r['history'][k] is True for k in ('original_failure_preserved','original_sixty_minute_clock_preserved','closed'))
        and all(r['history'][k] is False for k in ('failed_attempt_sql_executed','failed_attempt_journal_created')),'HISTORY')
    require(all(type(r['history'][key]) is int for key in ('pre_sql_failed_attempts','reserved_target_audit_calls',
        'actual_driver_dispatches','reserved_not_dispatched_audits','database_reservations','changed_adapter_contexts')),'HISTORY_TYPES')
    q=json.loads((ROOT/QUALIFICATION).read_bytes());package=r['package']
    require(set(package)=={'path','sha256','manifest_sha256','source_commit','provider_sha512','provider_sha256','qualified_source_record_sha256'}
            and package['path']==ARCHIVE and package['provider_sha512']==q['qualified_assembly_sha512'].lower() and
            package['provider_sha256']==q['qualified_assembly_sha256'],'QUALIFIED_PACKAGE')
    sources=r['source_sha256'];require(set(sources)==source_paths(),'SOURCE_CLOSURE')
    require(all(type(value) is str and re.fullmatch('[0-9a-f]{64}',value) is not None for value in sources.values()),'SOURCE_HASH_FORMAT')
    require(package['qualified_source_record_sha256']==sources[QUALIFICATION],'QUALIFICATION_BINDING')
    if check_files:
        for path,digest in sources.items():
            require(hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,'SOURCE_DRIFT')
        import validate_ssis_copy_column as delta
        delta.validate()
        archive=ROOT/ARCHIVE
        require(hashlib.sha256(archive.read_bytes()).hexdigest()==package['sha256'],'ARCHIVE_DRIFT')
        with zipfile.ZipFile(archive) as z:
            manifest=z.read(PACKAGE_NAME+'/PACKAGE-MANIFEST.json')
            m=json.loads(manifest)
            require(hashlib.sha256(manifest).hexdigest()==package['manifest_sha256'] and m['sourceCommit']==package['source_commit'],'MANIFEST_BINDING')
            provider=z.read(PACKAGE_NAME+'/'+MODULE+'Artifacts/Toolbelt.Tsql.SsisDebug.dll')
            require(hashlib.sha512(provider).hexdigest()==package['provider_sha512'],'ARCHIVE_DLL')
    return r


if __name__=='__main__':
    from ssis_historical_scope import copy_column_v1_scope
    with copy_column_v1_scope(ROOT):
        validate()
    print('SSIS_COPY_COLUMN_ZIP_DELIVERY_SCOPE_PASS; 12contexts/96assertions/12freshaudits; no full-module claim')
