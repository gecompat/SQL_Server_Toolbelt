"""Originale Marker-/Versions-/Modus-/Dependencykollisionen und eigene Restores begrenzen."""
from pathlib import Path
import json
import validate_xlsx_native_package as native

REPORT='Releases/1.0.0/XLSX-MARKER-COLLISION-REST-QUALIFICATION.json'


def validate(root,record=None):
    root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());require=native.require
    require(r['schema_version']=='toolbelt-xlsx-marker-collision-rest/v1' and r['status']=='PASS_FOR_DECLARED_SCOPE','marker collision status')
    require(r['publication_authorized'] is False and r['product_code_changed'] is False and r['rights_granted'] is False,'marker collision authority')
    require(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'marker collision current package')
    method=r['method'];required=set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1',
        'Tests/Release/Xlsx.CellApi.Workload.ps1','Tests/Release/Prepare-XlsxMarkerCollisionRunset.ps1',
        'Tests/Release/Xlsx.LifecycleNegative.Workload.ps1','Tests/Release/Xlsx.MarkerCollision.Workload.ps1',
        'Tests/Release/Test-XlsxMarkerCollisionAdmission.ps1','Tests/CI/run-xlsx-types-lab.ps1',
        'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql',
        'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.CollisionFixture.sql'}
    require(required<=set(method['source_sha256']),'marker collision method closure')
    sources=native.git_sources(root,method['source_commit'],list(method['source_sha256']))
    require(all(native.digest(v)==method['source_sha256'][k] for k,v in sources.items()),'marker collision original executed source')
    cases=r['cases'];require(len(cases)==12 and [c['index'] for c in cases]==list(range(12)),'marker collision target selection')
    for c in cases:
        platform,version,cl=native.expected_matrix()[c['index']]
        require((c['platform'],c['version'],c['cl'])==(platform,version,cl),'marker collision engine/CL')
        patch='latest' if platform=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[version]
        require(c['patch']==patch and c['modes']==['local','central'],'marker collision exact patch/modes')
        require(c['state']=='COMPLETE' and c['audit']=='PASS' and c['databases_removed']==2,'marker collision case/audit/cleanup')
        require(c['helpers']==[m+'/Display.Lifecycle.sql' for m in c['modes']],'marker collision original catalog fixture')
        require(c['collision_groups']==[dict(mode=m,completed_faults=['VersionUnknown','VersionPadded','ModePadded','MarkerPadded','MarkerMissing','Dependency'],deploy_rejections=5,uninstall_rejections=1,status='PASS') for m in c['modes']],'marker/collision exact original profiles')
        require(c['lifecycle']==[m+'/'+a for m in c['modes'] for a in ['InstallAndRepeat','Uninstall','UninstallAbsent']],'marker collision public closure')
    require(r['native_failures']==[] and r['green_replay'] is False,'marker collision original history')
    require(r['totals']==dict(target_pairs=12,routes=24,catalog_witnesses=24,collision_cases=144,
        deploy_rejections=120,uninstall_rejections=24,restores=144,successful_cases=12,failed_cleaned_cases=0,fresh_audits=12,
        target_audit_dispatches=24,actual_databases_removed=24),'marker collision totals')
    require(r['bounds']==dict(native_max=28,db_reservations_max=28,dispatches=24,db_reservations=24,
        changed_adapter_cases_max=2,changed_adapter_cases=0,native_minutes_max=60,native_closed=True,native_within_bound=True),'marker collision finite bounds')
    require(r['not_claimed']==['real_lowpriv_or_other_owner_visibility','full_collision_matrix','new_crossdb_login',
        'hard_os_loss_or_sqlcmd_process','heap_or_capacity','authenticated_tls','whole_module_qualification'],'marker collision scope limits')
    current=native.validate(root)
    return dict(status=r['status'],current_product_source_match=current['current_product_source_match'])


if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
