"""Originale genuine 1.1-Installation und disjunkte aktuelle Upgraderouten prüfen."""
from pathlib import Path
import json
import zipfile
import validate_xlsx_native_package as native

REPORT='Releases/1.0.0/XLSX-GENUINE11-REST-QUALIFICATION.json'


def validate(root,record=None):
    root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());require=native.require
    require(r['schema_version']=='toolbelt-xlsx-genuine11-rest/v1' and r['status']=='PASS_FOR_DECLARED_SCOPE','genuine status')
    require(r['publication_authorized'] is False and r['product_code_changed'] is False and r['rights_granted'] is False,'genuine authority')
    require(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'genuine current package')
    legacy=r['legacy'];require(legacy['source_commit']=='f64ee9eb8f6a7f66fd441821c7c40fcf2d92ee1e','genuine original revision')
    require(len(legacy['source_sha256'])==15 and legacy['independent_builds']==2 and legacy['reproducible_bytes'] is True,'genuine build provenance')
    require(legacy['installed_version']=='1.1.0' and legacy['installed_slots']==7 and legacy['installed_clr_bindings']==3 and legacy['installed_safe'] is True,'genuine native baseline')
    require(len(legacy['artifact_sha256'])==64 and all(c in '0123456789abcdef' for c in legacy['artifact_sha256']),'genuine artifact fingerprint')
    sources=native.git_sources(root,legacy['source_commit'],['Modules/toolbelt.file.xlsx-memory/'+p for p in legacy['source_sha256']])
    require(all(native.digest(v)==legacy['source_sha256'][p.removeprefix('Modules/toolbelt.file.xlsx-memory/')] for p,v in sources.items()),'genuine original source bytes')
    require([m['scope'] for m in r['methods']]==['genuine11-rest'],'genuine original method scopes')
    required=set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1','Tests/Release/Prepare-XlsxGenuine11Runset.ps1',
       'Tests/Release/Xlsx.Genuine11.Workload.ps1','Tests/Release/Xlsx.CellApi.Workload.ps1',
       'Modules/toolbelt.file.xlsx-memory/Scripts/New-Xlsx11LegacyFixture.ps1'}
    for method in r['methods']:
        require(required<=set(method['source_sha256']),'genuine method dependency')
        inputs=native.git_sources(root,method['source_commit'],list(method['source_sha256']))
        require(all(native.digest(v)==method['source_sha256'][k] for k,v in inputs.items()),'genuine original Git method')
        require(set(method['executed_source_sha256'])==set(inputs),'genuine checkout source set')
        artifact=method['checkout_artifact'];path='Releases/1.0.0/Artifacts/Xlsx-Genuine11-Method-Checkout.zip'
        require(artifact==dict(path=path,sha256=native.digest((root/path).read_bytes())),'genuine checkout artifact')
        expected={'Tests/Release/'+p for p in ['Invoke-XlsxFullSizeLab.ps1','Invoke-XlsxFullSizeMatrix.ps1','Xlsx.CellApi.Workload.ps1','Xlsx.Genuine11.Workload.ps1','Prepare-XlsxGenuine11Runset.ps1']}
        with zipfile.ZipFile(root/path) as archive:
            require(set(archive.namelist())==expected and len(archive.namelist())==5,'genuine checkout exact source entries')
            for k,v in inputs.items():
                actual=archive.read(k) if k in expected else v
                require(native.digest(actual)==method['executed_source_sha256'][k],'genuine executed checkout hash')
                require(actual.replace(b'\r\n',b'\n')==v and (k not in expected or actual!=v),'genuine checkout only CRLF')
    cases=r['cases'];require(len(cases)==12 and [c['index'] for c in cases]==list(range(12)),'genuine case selection')
    routes=[]
    for offset,c in enumerate(cases):
        i=c['index'];platform,version,cl=native.expected_matrix()[i]
        require((c['platform'],c['version'],c['cl'])==(platform,version,cl),'genuine engine/CL')
        patch='latest' if platform=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[version]
        require(c['patch']==patch,'genuine patch')
        modes=['local','central']
        require(c['scope']=='genuine11-rest' and c['modes']==modes,'genuine disjoint modes')
        require(c['helpers']==[m+'/'+n for m in modes for n in ['Types.Metadata.ps1','Display.Metadata.ps1']],'genuine current metadata helpers')
        require(c['state']=='COMPLETE' and c['audit']=='PASS' and c['genuine_baselines']==len(modes) and c['databases_removed']==len(modes),'genuine completion and audit')
        routes.extend((platform,version,cl,m) for m in modes)
    require(len(routes)==len(set(routes))==24,'genuine route replay or omission')
    require(r['totals']==dict(target_pairs=12,routes=24,genuine_baselines=24,helper_invocations=48,reader_cases=120,successful_cases=12,fresh_audits=12,target_audit_dispatches=24,actual_databases_removed=24),'genuine totals')
    require(r['bounds']==dict(native_max=24,db_reservations_max=24,dispatches=24,db_reservations=24,native_minutes_max=60,native_closed=True,native_within_bound=True),'genuine closed bounds')
    require(r['plan_revision']=='Single original1.1/current1.2 matrix; original limits/start retained; no correction or green replay','genuine plan history')
    require(r['invocation_history']==dict(pre_entry_argument_binding_error=True,native_dispatches=0,budget_start_unchanged=True),'genuine pre-entry history')
    require(r['not_claimed']==['original_1_1_api_or_consumer_matrix','full_collision_or_owner_matrix','new_minimal_rights','new_crossdb_login','heap_or_capacity','authenticated_tls','whole_module_qualification'],'genuine scope limits')
    current=native.validate(root)
    return dict(status=r['status'],current_product_source_match=current['current_product_source_match'])


if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
