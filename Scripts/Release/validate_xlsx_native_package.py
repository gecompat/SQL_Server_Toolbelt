"""Originale native XLSX-Paketqualifikation und aktuelle Anwendbarkeit trennen."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import zipfile

import new_xlsx_install_package as package

REPORT='Releases/1.0.0/XLSX-NATIVE-PACKAGE-QUALIFICATION.json'
PACKAGE='Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-XLSX-Install.zip'
FRAME='Releases/1.0.0/XLSX-FULL-SIZE-FRAMEWORK.json'
METHOD_FILES={
    'Tests/Release/Invoke-XlsxFullSizeLab.ps1', 'Tests/Release/Prepare-XlsxFullSizeRunset.ps1',
    'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1', 'Tests/Release/Runtime/Xlsx.FullSize.sql',
    'Tests/Release/Invoke-StablePackageLab.ps1', 'Tests/Release/ClrCaller.Environment.ps1',
    'Tests/Release/Test-XlsxFullSizeAdapter.ps1', 'Scripts/Release/new_xlsx_install_package.py',
    'Scripts/Release/Install-ClrPackage.ps1', 'Scripts/Release/prepare_clr_package.py',
}


def require(condition, message):
    if not condition: raise ValueError('XLSX native qualification: '+message)


def digest(data): return hashlib.sha256(data).hexdigest()


def git_sources(root, commit, names):
    require(len(commit)==40 and all(c in '0123456789abcdef' for c in commit),'method commit')
    for name in names:
        require(not Path(name).is_absolute() and '..' not in Path(name).parts and '\n' not in name and '\r' not in name and ':' not in name,'method path')
    completed=subprocess.run(['git','cat-file','--batch'],cwd=root,
        input=''.join(commit+':'+name+'\n' for name in names).encode(),capture_output=True,check=True)
    data=completed.stdout; offset=0; result={}
    for name in names:
        end=data.index(b'\n',offset);header=data[offset:end].split();offset=end+1
        require(len(header)==3 and header[1]==b'blob','method blob absent')
        size=int(header[2]);result[name]=data[offset:offset+size];offset+=size+1
    require(offset==len(data),'method stream tail')
    return result


def expected_matrix():
    return [(platform,version,cl) for platform in ('linux','windows')
            for version,levels in (('2019',(150,)),('2022',(150,160)),('2025',(150,160,170))) for cl in levels]


def validate(root, record=None):
    root=Path(root)
    record=record or json.loads((root/REPORT).read_bytes())
    require(record['schema_version']=='toolbelt-xlsx-native-package/v1' and record['status']=='PASS_FOR_DECLARED_SCOPE','scope status')
    require(record['publication_authorized'] is False and record['product_code_changed'] is False,'authority/product scope')
    frame=json.loads((root/FRAME).read_bytes())
    require(record['framework_record']=={'path':FRAME,'sha256':digest((root/FRAME).read_bytes())},'framework input')
    require(record['package']['path']==PACKAGE and digest((root/PACKAGE).read_bytes())==record['package']['sha256'],'qualified package bytes')
    metadata=package.verify(root/PACKAGE)
    require(record['package']['source_commit']==metadata['source_commit'],'package source commit')
    require(record['package']['xlsx_dll_sha256']==frame['xlsx_dll_sha256'] and record['package']['zip_dll_sha256']==frame['zip_dll_sha256'],'unchanged providers')
    old_path='Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
    old=json.loads((root/'Releases/1.0.0/xlsx-sst-budget-correction.json').read_bytes())
    require(digest((root/old_path).read_bytes())==old['original_package_sha256'],'historical global CLR package changed')
    require(record['workbooks']==frame['cases'],'exact executed workbook bytes and boundaries')
    method=record['method']
    require(METHOD_FILES<=set(method['source_sha256']),'missing executed source')
    sources=git_sources(root,method['source_commit'],list(method['source_sha256']))
    require(all(digest(data)==method['source_sha256'][name] for name,data in sources.items()),'original executed source differs')
    require(record['native']['routes']==24 and record['native']['public_calls']==192 and
            record['native']['positive_rows']==96 and record['native']['atomic_error_calls']==96 and
            record['native']['rows_before_error']==0 and record['native']['fresh_case_audits']==12,'native totals')
    cases=record['native']['cases']
    require([(c['platform'],c['sql_version'],c['compatibility_level']) for c in cases]==expected_matrix(),'complete native matrix')
    for case in cases:
        expected_patch='latest' if case['platform']=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[case['sql_version']]
        require(case['patch']==expected_patch,'explicit target patch')
        require(case['state']=='COMPLETE' and case['audit']=='PASS' and case['modes']==['local','central'],'native case status')
        require(case['positive_rows']==8 and case['atomic_error_calls']==8 and case['databases_created']==2 and case['databases_removed']==2,'case counts')
        require(case['lifecycle']=={'Install':2,'Repeat':2,'Uninstall':2,'UninstallAbsent':2},'package lifecycle')
    history=record['history']
    require(history['pre_sql_rejection']=={'state':'PRE_SQL_REJECTED','data_cases':0,'audit':'PASS_READ_ONLY_TARGET'},'pre-SQL failure must remain')
    require(history['metadata_oracle_failure']=={'state':'FAILED_CLEANED','data_cases':0,'audit':'PASS'},'first package failure must remain')
    require(history['intentional_state_diagnostic']=={'state':'FAILED_CLEANED','data_cases':0,'audit':'PASS','purpose':'diagnostic_only'},'diagnostic must not become qualification PASS')
    require(record['bounds']=={'initial_target_audit_max':28,'effective_target_audit_max':30,'target_audit_dispatches':30,
        'database_reservations':30,'actual_databases_created':26,'actual_databases_removed':26,'native_minutes_max':60,
        'native_within_bound':True,'native_closed':True},'closed budget/cleanup')
    require(record['not_claimed']==['authenticated_tls','new_sqlcmd_transport_run','linux_export_client_host','peak_heap','production_capacity','whole_module_qualification'],'claim boundary')
    # Aktuelle Produktanwendbarkeit ist eine berechnete Aussage, keine Änderung
    # der ursprünglichen Ausführungspins und kein Zwang, alte Quellen einzufrieren.
    original=package.source_files_at(metadata['source_commit'])
    current=package.source_files()
    return dict(status=record['status'],current_product_source_match=(original==current))


if __name__=='__main__':
    root=Path(__file__).resolve().parents[2]
    print(json.dumps(validate(root),sort_keys=True))
