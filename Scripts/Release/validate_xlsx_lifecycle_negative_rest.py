"""Aktuelle negative XLSX-Lifecyclefälle von echten Callerrechten trennen."""
from pathlib import Path
import json
import validate_xlsx_native_package as native

REPORT='Releases/1.0.0/XLSX-LIFECYCLE-NEGATIVE-REST-QUALIFICATION.json'


def validate(root,record=None):
    root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());require=native.require
    require(r['schema_version']=='toolbelt-xlsx-lifecycle-negative-rest/v1' and r['status']=='PASS_FOR_DECLARED_SCOPE','lifecycle status')
    require(r['publication_authorized'] is False and r['product_code_changed'] is False and r['rights_granted'] is False,'lifecycle authority')
    require(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'lifecycle current package')
    method=r['method'];required=set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1',
        'Tests/Release/Xlsx.CellApi.Workload.ps1','Tests/Release/Prepare-XlsxLifecycleNegativeRunset.ps1',
        'Tests/Release/Xlsx.LifecycleNegative.Workload.ps1','Tests/CI/run-xlsx-types-lab.ps1',
        'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'}
    require(required<=set(method['source_sha256']),'lifecycle method closure')
    sources=native.git_sources(root,method['source_commit'],list(method['source_sha256']))
    require(all(native.digest(v)==method['source_sha256'][k] for k,v in sources.items()),'lifecycle original executed source')
    cases=r['cases'];require(len(cases)==12 and [c['index'] for c in cases]==list(range(12)),'lifecycle target selection')
    for c in cases:
        platform,version,cl=native.expected_matrix()[c['index']]
        require((c['platform'],c['version'],c['cl'])==(platform,version,cl),'lifecycle engine/CL')
        patch='latest' if platform=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[version]
        require(c['patch']==patch and c['modes']==['local','central'],'lifecycle exact patch/modes')
        require(c['state']=='COMPLETE' and c['audit']=='PASS' and c['databases_removed']==2,'lifecycle case/audit/cleanup')
        require(c['helpers']==[m+'/Display.Lifecycle.sql' for m in c['modes']],'lifecycle original catalog fixture')
        require(c['negative_groups']==[dict(mode=m,rollback=4,locks=2,visibility=16,status='PASS') for m in c['modes']],'lifecycle exact negative guards')
    require(r['totals']==dict(target_pairs=12,routes=24,catalog_witnesses=24,rollback_cases=96,lock_cases=48,
        synthetic_visibility_cases=384,negative_cases=528,successful_cases=12,fresh_audits=12,
        target_audit_dispatches=24,actual_databases_removed=24),'lifecycle totals')
    require(r['bounds']==dict(native_max=28,db_reservations_max=28,dispatches=24,db_reservations=24,
        changed_adapter_cases_max=2,changed_adapter_cases=0,native_minutes_max=60,native_closed=True,native_within_bound=True),'lifecycle finite bounds')
    require(r['visibility_method']=='synthetic0/NULL for2 predicates at2 phases in Deploy/Uninstall; no real permission changes','lifecycle visibility scope')
    require(r['not_claimed']==['real_lowpriv_or_other_owner_visibility','full_collision_matrix','new_crossdb_login',
        'caller_doomed_or_hard_os_loss','heap_or_capacity','authenticated_tls','whole_module_qualification'],'lifecycle scope limits')
    current=native.validate(root)
    return dict(status=r['status'],current_product_source_match=current['current_product_source_match'])


if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
