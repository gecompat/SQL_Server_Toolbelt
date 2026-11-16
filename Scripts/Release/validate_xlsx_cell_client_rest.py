"""Native XLSX-Clientmetadaten mit erhaltener Fehler-/Quellenhistorie prüfen."""
from pathlib import Path
import json
import validate_xlsx_native_package as native

REPORT='Releases/1.0.0/XLSX-CELL-CLIENT-REST-QUALIFICATION.json'


def validate(root,record=None):
    root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());require=native.require
    require(r['schema_version']=='toolbelt-xlsx-cell-client-rest/v1' and r['status']=='PASS_FOR_DECLARED_SCOPE','client status')
    require(r['publication_authorized'] is False and r['product_code_changed'] is False and r['rights_granted'] is False,'client authority')
    require(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'client package bytes')
    require([m['role'] for m in r['methods']]==['failed','qualified'],'client method history')
    required=set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1',
        'Tests/Release/Prepare-XlsxCellApiRunset.ps1','Tests/Release/Xlsx.CellApi.Workload.ps1',
        'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.Metadata.ps1',
        'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Metadata.ps1'}
    for method in r['methods']:
        require(required<=set(method['source_sha256']),'client source dependency')
        sources=native.git_sources(root,method['source_commit'],list(method['source_sha256']))
        require(all(native.digest(v)==method['source_sha256'][k] for k,v in sources.items()),'client original source drift')
    require([c['index'] for c in r['cases']]==list(range(1,12)),'client disjoint matrix')
    for c in r['cases']:
        i=c['index'];platform,version,cl=native.expected_matrix()[i]
        require((c['platform'],c['version'],c['cl'])==(platform,version,cl),'client actual context')
        patch='latest' if platform=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[version]
        require(c['patch']==patch,'client patch')
        modes=['central'] if i==11 else ['local','central']
        names=['Display.Metadata.ps1'] if i>=9 else ['Types.Metadata.ps1','Display.Metadata.ps1']
        require(c['modes']==modes and c['helpers']==[m+'/'+n for m in modes for n in names],'client no green replay or omitted helper')
        require(c['state']=='COMPLETE' and c['audit']=='PASS' and c['databases_removed']==len(modes),'client completion/cleanup')
    require(r['totals']==dict(successful_cases=11,helper_invocations=37,reader_cases=95,fresh_case_audits=11,failure_audits=1,target_audit_dispatches=24,actual_databases_removed=22),'client totals')
    require(r['history']==dict(state='FAILED_CLEANED',completed_helpers=0,audit='PASS',cause='CALLBACK_SCRIPT_SCOPE_LOST'),'client failure must remain')
    require(r['bounds']==dict(target_audit_max=24,db_reservations_max=24,target_audit_dispatches=24,db_reservations=24,changed_adapter_cases=1,native_minutes_max=60,native_within_bound=True,native_closed=True),'client closed bounds')
    require(r['not_claimed']==['new_minimal_rights_test','new_crossdb_identity','catalog_nullability','linux_client_host','genuine_upgrade_matrix','heap_or_capacity','authenticated_tls','whole_module_qualification'],'client claim boundaries')
    result=native.validate(root)
    return dict(status=r['status'],current_product_source_match=result['current_product_source_match'])


if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
