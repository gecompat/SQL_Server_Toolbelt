"""Genuine Zukunftsslots, Ablehnung, Fremderhalt und eigene Fehler getrennt prüfen."""
from pathlib import Path
import json
import validate_xlsx_native_package as native
import validate_xlsx_genuine11_rest as genuine

REPORT='Releases/1.0.0/XLSX-FUTURE-COLLISION-REST-QUALIFICATION.json'
FAULTS=['FuturePublic','ImitatedFuturePublic','FutureInternal','ImitatedFutureInternal']


def validate(root,record=None):
    root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());require=native.require
    require(r['schema_version']=='toolbelt-xlsx-future-collision-rest/v1' and r['status']=='PASS_FOR_DECLARED_SCOPE','future status')
    require(r['publication_authorized'] is False and r['product_code_changed'] is False and r['rights_granted'] is False,'future authority')
    require(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'future current package')
    old=json.loads((root/genuine.REPORT).read_bytes())
    require(r['legacy_reference']==dict(path=genuine.REPORT,sha256=native.digest((root/genuine.REPORT).read_bytes()),
        artifact_sha256=old['legacy']['artifact_sha256'],independent_builds_reused=2,rebuild=False,copied_bytes_verified=True),'future reused genuine provenance')
    genuine.validate(root)
    method=r['method'];required=set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1',
        'Tests/Release/Xlsx.CellApi.Workload.ps1','Tests/Release/Prepare-XlsxFutureCollisionRunset.ps1',
        'Tests/Release/Xlsx.FutureCollision.Workload.ps1','Tests/Release/Prepare-XlsxGenuine11Runset.ps1',
        'Tests/Release/Xlsx.Genuine11.Workload.ps1','Tests/Release/Xlsx.LifecycleNegative.Workload.ps1',
        'Tests/CI/run-xlsx-types-lab.ps1','Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.CollisionFixture.sql',
        'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'}
    require(required<=set(method['source_sha256']),'future method closure')
    sources=native.git_sources(root,method['source_commit'],list(method['source_sha256']))
    require(all(native.digest(v)==method['source_sha256'][k] for k,v in sources.items()),'future original executed source')
    cases=r['cases'];require(len(cases)==12 and [c['index'] for c in cases]==list(range(12)),'future target selection')
    for c in cases:
        platform,version,cl=native.expected_matrix()[c['index']]
        require((c['platform'],c['version'],c['cl'])==(platform,version,cl),'future engine/CL')
        patch='latest' if platform=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[version]
        require(c['patch']==patch and c['modes']==['local','central'],'future exact patch/modes')
        require(c['state']=='COMPLETE' and c['audit']=='PASS' and c['databases_removed']==2,'future case/audit/cleanup')
        require(c['helpers']==[m+'/Display.Lifecycle.sql' for m in c['modes']],'future post-collision current witness')
        require(c['future_groups']==[dict(mode=m,legacy_witnesses=5,completed_faults=FAULTS,status='PASS') for m in c['modes']],'future exact original cases/restores')
        require(c['lifecycle']==[m+'/'+a for m in c['modes'] for a in ['InstallAndRepeat','Uninstall','UninstallAbsent']],'future public recovery and closure')
    require(r['initial_failure']==dict(index=0,state='FAILED_CLEANED',stage='PREPARE',reason='RELEASE_PRIVATE_PATH_REQUIRED',
        completed_modes=[],databases_created=0,audit='PASS',target_audit_dispatches=2,preserved=True),'future original failure retained')
    require(r['correction']=='exact qualified legacy/repro bytes copied into own runtime; no rebuild/guard weakening/green replay; original budget/start retained','future correction scope')
    require(r['totals']==dict(target_pairs=12,routes=24,collision_fixtures=96,deploy_rejections=96,
        foreign_preservation_checks=96,genuine_legacy_witnesses=120,post_collision_recoveries=24,
        successful_cases=12,failed_cleaned_cases=1,fresh_audits=13,target_audit_dispatches=26,actual_databases_removed=24),'future totals')
    require(r['bounds']==dict(native_max=28,db_reservations_max=28,dispatches=26,db_reservations=26,
        changed_adapter_cases_max=2,changed_adapter_cases=1,native_minutes_max=60,native_closed=True,native_within_bound=True),'future finite bounds')
    require(r['not_claimed']==['all_other_slot_collisions','other_owner_or_real_lowpriv_visibility','new_crossdb_login',
        'original_legacy_uninstaller_or_api','heap_or_capacity','authenticated_tls','whole_module_qualification'],'future scope limits')
    current=native.validate(root)
    return dict(status=r['status'],current_product_source_match=current['current_product_source_match'])


if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
