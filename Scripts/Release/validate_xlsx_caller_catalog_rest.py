"""Callertransaktionen und Katalog-/Clientnullability auf exakt erklärte Routen begrenzen."""
from pathlib import Path
import json
import validate_xlsx_native_package as native

REPORT='Releases/1.0.0/XLSX-CALLER-CATALOG-REST-QUALIFICATION.json'


def validate(root,record=None):
    root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());require=native.require
    require(r['schema_version']=='toolbelt-xlsx-caller-catalog-rest/v1' and r['status']=='PASS_FOR_DECLARED_SCOPE','lifecycle status')
    require(r['publication_authorized'] is False and r['product_code_changed'] is False and r['rights_granted'] is False,'lifecycle authority')
    require(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'lifecycle current package')
    method=r['method'];required=set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1',
        'Tests/Release/Xlsx.CellApi.Workload.ps1','Tests/Release/Prepare-XlsxCallerCatalogRunset.ps1',
        'Tests/Release/Xlsx.LifecycleNegative.Workload.ps1','Tests/Release/Xlsx.CallerCatalog.Workload.ps1',
        'Tests/Release/Test-XlsxCallerCatalogAdmission.ps1','Tests/CI/run-xlsx-types-lab.ps1',
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
        require(c['caller_catalog_groups']==[dict(mode=m,profiles=['OFF/intact','OFF/doomed','ON/intact','ON/doomed'],caller_rejections=8,nullability=1,status='PASS') for m in c['modes']],'caller/catalog exact profiles')
        require(c['lifecycle']==[m+'/'+a for m in c['modes'] for a in ['InstallAndRepeat','Uninstall','UninstallAbsent']],'caller/catalog public closure')
    require(r['native_failures']==[] and r['green_replay'] is False,'caller/catalog original history')
    require(r['totals']==dict(target_pairs=12,routes=24,catalog_witnesses=24,caller_rejections=192,
        intact_rejections=96,doomed_rejections=96,nullability_checks=24,successful_cases=12,failed_cleaned_cases=0,fresh_audits=12,
        target_audit_dispatches=24,actual_databases_removed=24),'lifecycle totals')
    require(r['bounds']==dict(native_max=28,db_reservations_max=28,dispatches=24,db_reservations=24,
        changed_adapter_cases_max=2,changed_adapter_cases=0,native_minutes_max=60,native_closed=True,native_within_bound=True),'lifecycle finite bounds')
    require(r['not_claimed']==['real_lowpriv_or_other_owner_visibility','full_collision_matrix','new_crossdb_login',
        'hard_os_loss_or_sqlcmd_process','heap_or_capacity','authenticated_tls','whole_module_qualification'],'lifecycle scope limits')
    current=native.validate(root)
    return dict(status=r['status'],current_product_source_match=current['current_product_source_match'])


if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
