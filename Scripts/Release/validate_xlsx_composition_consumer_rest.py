"""Installierte und providerfreie XLSX-Kompositionen nur für erklärte Identitäten qualifizieren."""
from pathlib import Path
import json
import validate_xlsx_native_package as native

REPORT='Releases/1.0.0/XLSX-COMPOSITION-CONSUMER-REST-QUALIFICATION.json'

HELPER_NAMES=['Types.Metadata.ps1','Display.Metadata.ps1','Invoke-TypesComposition.ps1','Invoke-DisplayComposition.ps1']
FIXTURE_HASHES={
 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.Composition.xlsx':'7b690c7c0ec6c2eebbea180b031c7bdaed1a6d1dc5f2d3cec360135b8f530bc1',
 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.Composition.sql':'9c63e84b28b066555a20d6354f2154e8c5a830ca3372c52d40f73b02f13b923e',
 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Composition.sql':'a44f37281dec7d74e82de44d62d9a6a929a47aaf9849d4458e68278713901a44'}


def expected_groups():
    return [dict(mode=m,installed_helpers=HELPER_NAMES[2:],consumer_helpers=HELPER_NAMES if m=='central' else [],
        provider_free_witnesses=2 if m=='central' else 0,nullability=1 if m=='central' else 0,
        confirm0=1 if m=='central' else 0,status='PASS') for m in ['local','central']]


def validate(root,record=None):
    root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());require=native.require
    require(r['schema_version']=='toolbelt-xlsx-composition-consumer-rest/v1' and r['status']=='PASS_FOR_DECLARED_SCOPE','composition consumer status')
    require(r['publication_authorized'] is False and r['product_code_changed'] is False and r['rights_granted'] is False,'composition consumer authority')
    require(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'composition consumer current package')
    require(r['fixture_source_sha256']==FIXTURE_HASHES and all(native.digest((root/p).read_bytes())==h for p,h in FIXTURE_HASHES.items()),'composition original fixture bytes')
    method=r['method'];required=set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1',
        'Tests/Release/Xlsx.CellApi.Workload.ps1','Tests/Release/Prepare-XlsxCompositionConsumerRunset.ps1',
        'Tests/Release/Xlsx.LifecycleNegative.Workload.ps1','Tests/Release/Xlsx.CallerCatalog.Workload.ps1',
        'Tests/Release/Xlsx.OwnedDatabase.ps1','Tests/Release/Xlsx.CompositionConsumer.Workload.ps1',
        'Tests/Release/Test-XlsxCompositionConsumerAdmission.ps1','Tests/CI/run-xlsx-types-lab.ps1',
        'Modules/toolbelt.file.xlsx-memory/Deployment/Uninstall.sql',
        'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql',
        *FIXTURE_HASHES,
        *['Modules/toolbelt.file.xlsx-memory/Tests/Runtime/'+n for n in HELPER_NAMES]}
    require(required<=set(method['source_sha256']),'composition consumer method closure')
    sources=native.git_sources(root,method['source_commit'],list(method['source_sha256']))
    require(all(native.digest(v)==method['source_sha256'][k] for k,v in sources.items()),'composition consumer original executed source')
    cases=r['cases'];require(len(cases)==12 and [c['index'] for c in cases]==list(range(12)),'composition consumer target selection')
    for c in cases:
        platform,version,cl=native.expected_matrix()[c['index']]
        require((c['platform'],c['version'],c['cl'])==(platform,version,cl),'composition consumer engine/CL')
        patch='latest' if platform=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[version]
        require(c['patch']==patch and c['modes']==['local','central'],'composition consumer exact patch/modes')
        require(c['state']=='COMPLETE' and c['audit']=='PASS' and c['databases_removed']==3 and c['database_suffixes']==['l','c','u'] and c['consumer_collation']=='Latin1_General_100_CS_AS','composition consumer case/audit/cleanup')
        require(c['helpers']==[m+'/Display.Lifecycle.sql' for m in c['modes']],'composition consumer original catalog fixture')
        require(c['composition_groups']==expected_groups(),'composition exact original helpers/consumer witnesses')
        require(c['lifecycle']==[m+'/'+a for m in c['modes'] for a in ['InstallAndRepeat','Uninstall','UninstallAbsent']],'composition consumer public closure')
    require(r['native_failures']==[] and r['green_replay'] is False,'composition consumer original history')
    require(r['totals']==dict(target_pairs=12,installed_routes=24,provider_free_consumer_contexts=12,
        composition_helpers=72,consumer_metadata_helpers=24,consumer_nullability_checks=12,provider_free_witnesses=24,
        central_confirm0_rejections=12,catalog_witnesses=24,successful_cases=12,failed_cleaned_cases=0,fresh_audits=12,
        target_audit_dispatches=24,actual_databases_removed=36),'composition totals')
    require(r['bounds']==dict(native_max=28,db_reservations_max=42,dispatches=24,db_reservations=36,
        changed_adapter_cases_max=2,changed_adapter_cases=0,native_minutes_max=60,native_closed=True,native_within_bound=True),'composition consumer finite bounds')
    require(r['not_claimed']==['real_lowpriv_or_other_owner','new_mapped_crossdb_login','linux_clienthost_or_network_tls',
        'all_other_consumer_namespaces','heap_or_capacity','hard_os_loss','whole_module_qualification'],'composition scope limits')
    current=native.validate(root)
    return dict(status=r['status'],current_product_source_match=current['current_product_source_match'])


if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
