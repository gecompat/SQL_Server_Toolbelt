"""Originale genuine 1.0-Installation und disjunkte aktuelle Upgraderouten prüfen."""
from pathlib import Path
import json
import validate_xlsx_native_package as native

REPORT='Releases/1.0.0/XLSX-GENUINE10-REST-QUALIFICATION.json'


def validate(root,record=None):
    root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());require=native.require
    require(r['schema_version']=='toolbelt-xlsx-genuine10-rest/v1' and r['status']=='PASS_FOR_DECLARED_SCOPE','genuine status')
    require(r['publication_authorized'] is False and r['product_code_changed'] is False and r['rights_granted'] is False,'genuine authority')
    require(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'genuine current package')
    legacy=r['legacy'];require(legacy['source_commit']=='fdafa8038e4d5240dd727096f144c8d5fd884117','genuine original revision')
    require(len(legacy['source_sha256'])==12 and legacy['independent_builds']==2 and legacy['reproducible_bytes'] is True,'genuine build provenance')
    require(legacy['installed_version']=='1.0.0' and legacy['installed_slots']==5 and legacy['installed_clr_bindings']==2 and legacy['installed_safe'] is True,'genuine native baseline')
    require(len(legacy['artifact_sha256'])==64 and all(c in '0123456789abcdef' for c in legacy['artifact_sha256']),'genuine artifact fingerprint')
    sources=native.git_sources(root,legacy['source_commit'],['Modules/toolbelt.file.xlsx-memory/'+p for p in legacy['source_sha256']])
    require(all(native.digest(v)==legacy['source_sha256'][p.removeprefix('Modules/toolbelt.file.xlsx-memory/')] for p,v in sources.items()),'genuine original source bytes')
    require([m['scope'] for m in r['methods']]==['genuine10-rest','genuine10-central-rest'],'genuine original method scopes')
    required=set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1','Tests/Release/Prepare-XlsxGenuine10Runset.ps1',
       'Tests/Release/Xlsx.Genuine10.Workload.ps1','Tests/Release/Xlsx.CellApi.Workload.ps1',
       'Modules/toolbelt.file.xlsx-memory/Scripts/New-Xlsx10LegacyFixture.ps1'}
    for method in r['methods']:
        require(required<=set(method['source_sha256']),'genuine method dependency')
        inputs=native.git_sources(root,method['source_commit'],list(method['source_sha256']))
        require(all(native.digest(v)==method['source_sha256'][k] for k,v in inputs.items()),'genuine executed method')
    cases=r['cases'];require(len(cases)==13 and [c['index'] for c in cases]==list(range(12))+[0],'genuine case selection')
    routes=[]
    for offset,c in enumerate(cases):
        i=c['index'];platform,version,cl=native.expected_matrix()[i]
        require((c['platform'],c['version'],c['cl'])==(platform,version,cl),'genuine engine/CL')
        patch='latest' if platform=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[version]
        require(c['patch']==patch,'genuine patch')
        modes=['central'] if offset==12 else ['local'] if i==0 else ['local','central']
        require(c['scope']==('genuine10-central-rest' if offset==12 else 'genuine10-rest') and c['modes']==modes,'genuine disjoint modes')
        require(c['helpers']==[m+'/'+n for m in modes for n in ['Types.Metadata.ps1','Display.Metadata.ps1']],'genuine current metadata helpers')
        require(c['state']=='COMPLETE' and c['audit']=='PASS' and c['genuine_baselines']==len(modes) and c['databases_removed']==len(modes),'genuine completion and audit')
        routes.extend((platform,version,cl,m) for m in modes)
    require(len(routes)==len(set(routes))==24,'genuine route replay or omission')
    require(r['totals']==dict(target_pairs=12,routes=24,genuine_baselines=24,helper_invocations=48,reader_cases=120,successful_cases=13,fresh_audits=13,target_audit_dispatches=26,actual_databases_removed=24),'genuine totals')
    require(r['bounds']==dict(native_max=28,db_reservations_max=28,dispatches=26,db_reservations=26,native_minutes_max=60,native_closed=True,native_within_bound=True),'genuine closed bounds')
    require(r['plan_revision']=='At24/28 before closure add only current-build Linux2019 CL150 central; prior central proof qualifies earlier provider; no local replay; original limits/start retained','genuine plan history')
    require(r['not_claimed']==['genuine_1_1_upgrade_matrix','full_collision_or_owner_matrix','new_minimal_rights','new_crossdb_login','heap_or_capacity','authenticated_tls','whole_module_qualification'],'genuine scope limits')
    current=native.validate(root)
    return dict(status=r['status'],current_product_source_match=current['current_product_source_match'])


if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
