"""Aktuelle Windows-/Linux-Modellhostevidenz; keine SQL- oder Gesamtabnahme."""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parents[2]
MODULE='Modules/toolbelt.tsql.ssis-debug/'
REPORT=MODULE+'Tests/Qualification/ExportHost.CopyColumn.20261115.json'
PRODUCT_COMMIT='8a495ae4303e50bd7367aaa07e1d7adf422e5122'
HOST_SHA256='ae8f9041482dde6cc15c94fbaa439034d3fc943462e4dde290052934a3d91c77'
sys.path.insert(0,str(ROOT/MODULE/'Exchange/Tests'))
import qualify_copy_column_host as method
from validate_ssis_linux_export import NAMES, COUNTS, EXITS, RUNTIME_SHA512


def require(condition,label):
    if not condition:
        raise ValueError('SSIS_COPY_HOST_'+label)


def sha(value):
    return type(value) is str and re.fullmatch('[0-9a-f]{64}',value) is not None


def validate(record=None,*,check_files=True):
    r=record if record is not None else json.loads((ROOT/REPORT).read_bytes())
    require(set(r)=={'contract','date','result','scope','runtime','case_count','assertions','runs','history'},'RECORD_KEYS')
    require(r.get('contract')=='ssis-copy-column-export-host-qualification/1' and
            r.get('date')=='2026-11-15' and r.get('result')=='PASS_FOR_DECLARED_SCOPE','HEADER')
    require(r.get('scope')=={'current_model_and_cli':True,'sql_executed':False,
        'sql_clr_linux':False,'full_module_qualification':False,'native_ssis_runtime':False,
        'fresh_zip_matrix':False,'fresh_ssms':False,'fresh_authenticated_tls':False,
        'publication_authorized':False} and all(type(v) is bool for v in r['scope'].values()),'SCOPE')
    require(r.get('runtime')=={'version':'10.0.14','rid':'linux-x64',
        'archive_url':'https://builds.dotnet.microsoft.com/dotnet/Runtime/10.0.14/dotnet-runtime-10.0.14-linux-x64.tar.gz',
        'archive_sha512':RUNTIME_SHA512,'installation':'private test directory; no global installation'},'RUNTIME')
    require(type(r.get('case_count')) is int and r['case_count']==50 and
            type(r.get('assertions')) is int and r['assertions']==610,'TOTALS')
    require(r.get('history')=={'platform_dispatches':4,'complete_platform_runs':2,
        'pre_profile_failed_dispatches':2,'successful_host_profile_processes':50,
        'windows_success_reused_without_repeat':True,'private_runtime_absence_verified':True,
        'original_failures_preserved':True,'closed':True} and all(r['history'][key] is True
        for key in ('windows_success_reused_without_repeat','private_runtime_absence_verified','original_failures_preserved','closed')),'HISTORY')
    runs=r.get('runs',[])
    require(len(runs)==2 and [run.get('platform') for run in runs]==['Windows','Linux'],'PLATFORMS')
    pins=method.source_pins(ROOT)
    expected_copy=tuple(f'copy-column-{version}-{kind}:version{component_version}'
        for version in (6,8) for kind in ('int','text') for component_version in (1,2))
    for run in runs:
        require(set(run)=={'contract','date','platform','result','sql_executed','host_sha256','source_commit',
                          'source_sha256','base','copy_cases','case_count','assertions'},'NATIVE_KEYS')
        require(run.get('contract')=='ssis-copy-column-export-host-native/1' and
                run.get('date')==r['date'] and run.get('result')=='PASS' and
                run.get('sql_executed') is False,'NATIVE_SCOPE')
        require(run.get('host_sha256')==HOST_SHA256 and run.get('source_commit')==PRODUCT_COMMIT,'HOST_IDENTITY')
        require(type(run.get('case_count')) is int and run['case_count']==25 and
                type(run.get('assertions')) is int and run['assertions']==305,'NATIVE_COUNTS')
        require(set(run.get('source_sha256',{}))==set(pins) and
                all(sha(value) for value in run['source_sha256'].values()),'SOURCE_CLOSURE')
        if check_files:
            require(run['source_sha256']==pins,'SOURCE_DRIFT')
        base=run['base']
        require(base.get('contract')=='ssis-export-host-native/1' and base.get('result')=='PASS' and
                base.get('platform')==run['platform'] and base.get('date')==r['date'] and
                base.get('sql_executed') is False and base.get('case_count')==17 and
                type(base.get('case_count')) is int and base.get('assertions')==169 and
                type(base.get('assertions')) is int,'BASE_SCOPE')
        for key in ('host_sha256','source_commit'):
            require(base[key]==run[key],'BASE_IDENTITY')
        base_sources=method.base.source_pins(ROOT)
        require(set(base['source_sha256'])==set(base_sources) and
                all(base['source_sha256'][key]==run['source_sha256'][key] for key in base_sources),'BASE_SOURCES')
        require(len(base['cases'])==17,'BASE_CASES')
        for case,name,count,exit_code in zip(base['cases'],NAMES,COUNTS,EXITS):
            require(case.get('name')==name and type(case.get('assertions')) is int and
                    case['assertions']==count and type(case.get('exit_code')) is int and
                    case['exit_code']==exit_code and sha(case.get('output_sha256')),'BASE_ORACLE')
            require((case['output_sha256']==hashlib.sha256(b'').hexdigest())==(exit_code!=0),'BASE_OUTPUT')
        require(len(run['copy_cases'])==8,'COPY_CASES')
        for case,name in zip(run['copy_cases'],expected_copy):
            require(case.get('name')==name and type(case.get('exit_code')) is int and
                    case['exit_code']==0 and type(case.get('assertions')) is int and
                    case['assertions']==17 and sha(case.get('output_sha256')) and
                    case['output_sha256']!=hashlib.sha256(b'').hexdigest(),'COPY_ORACLE')
    for key in ('host_sha256','source_commit','source_sha256','copy_cases'):
        require(runs[0][key]==runs[1][key],'CROSS_PLATFORM_EQUALITY')
    require(runs[0]['base']['cases']==runs[1]['base']['cases'],'BASE_CROSS_PLATFORM_EQUALITY')
    return r


if __name__=='__main__':
    validate()
    print('SSIS_COPY_COLUMN_EXPORT_HOST_SCOPE_PASS; 50cases/610assertions; no SQL or module-total claim')
