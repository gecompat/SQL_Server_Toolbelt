"""WrongType-Ablehnung und Fremderhalt von erfolgreichem Uninstall/Restore trennen."""
from pathlib import Path
import json
import validate_xlsx_native_package as native

REPORT='Releases/1.0.0/XLSX-WRONGTYPE-REST-QUALIFICATION.json'


def validate(root,record=None):
    root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());require=native.require
    require(r['schema_version']=='toolbelt-xlsx-wrongtype-rest/v1' and r['status']=='PARTIAL' and r['functional_status']=='PASS_FOR_DECLARED_SCOPE','wrongtype status')
    require(r['publication_authorized'] is False and r['product_code_changed'] is False and r['rights_granted'] is False,'wrongtype authority')
    require(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'wrongtype current package')
    required=set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1',
        'Tests/Release/Xlsx.CellApi.Workload.ps1','Tests/Release/Prepare-XlsxWrongTypeRunset.ps1',
        'Tests/Release/Xlsx.LifecycleNegative.Workload.ps1','Tests/Release/Xlsx.OwnedDatabase.ps1','Tests/Release/Xlsx.WrongType.Workload.ps1',
        'Tests/Release/Test-XlsxWrongTypeAdmission.ps1','Tests/CI/run-xlsx-types-lab.ps1',
        'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql',
        'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.CollisionFixture.sql'}
    require(list(r['methods'])==['initial','corrected','io_continuation'],'wrongtype method sequence')
    for name,method in r['methods'].items():
        expected=required|({'Tests/Release/Resume-XlsxWrongTypeAudit.ps1','Tests/Release/Test-XlsxWrongTypeAuditRecovery.ps1'} if name!='initial' else set())
        if name=='io_continuation':expected|={'Tests/Release/Resume-XlsxWrongTypeJournal.ps1','Tests/Release/Test-XlsxWrongTypeControllerRecovery.ps1'}
        require(expected<=set(method['source_sha256']),'wrongtype executed method closure')
        sources=native.git_sources(root,method['source_commit'],list(method['source_sha256']))
        require(all(native.digest(v)==method['source_sha256'][k] for k,v in sources.items()),'wrongtype original executed method')
    cases=r['cases'];require(len(cases)==12 and [c['index'] for c in cases]==list(range(12)),'wrongtype target selection')
    for c in cases:
        require(c['method_id']==('initial' if c['index']==0 else 'corrected' if c['index']<=4 else 'io_continuation') and c['audit_method_id']==('corrected' if c['index']<=3 else 'io_continuation'),'wrongtype exact native/audit methods')
        require(c['process_result']==('NOT_PRESERVED' if c['index']==4 else 'EXIT_ZERO_COMPLETE_CAPTURE'),'wrongtype process result remains unknown')
        platform,version,cl=native.expected_matrix()[c['index']]
        require((c['platform'],c['version'],c['cl'])==(platform,version,cl),'wrongtype engine/CL')
        patch='latest' if platform=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[version]
        require(c['patch']==patch and c['modes']==['local','central'],'wrongtype exact patch/modes')
        require(c['state']=='COMPLETE' and c['audit']=='PASS' and c['databases_removed']==2,'wrongtype case/audit/cleanup')
        require(c['helpers']==[m+'/Display.Lifecycle.sql' for m in c['modes']],'wrongtype original catalog fixture')
        require(c['wrongtype_groups']==[dict(mode=m,fixture='WrongType',deploy_rejections=1,uninstall_rejections=1,foreign_witnesses=3,status='PASS') for m in c['modes']],'wrongtype exact rejects/preservation')
        require(c['lifecycle']==[m+'/InstallAndRepeat' for m in c['modes']],'wrongtype no successful public uninstall or restore')
    require(r['run_failures']==[] and r['green_replay'] is False,'wrongtype original history')
    require(r['audit_failures']==[dict(index=0,state='AUDIT_FAILED',exit_code=1,guard_reproduced_without_sql='XLSX_FULL_SIZE_AUDIT_LIFECYCLE_SET',preserved=True,corrected_fresh_audit='PASS',same_original_journal=True)],'wrongtype original audit failure retained')
    require(r['controller_interruptions']==[dict(index=4,error='ATOMIC_JOURNAL_REPLACE_ACCESS_DENIED',preserved_dispatch_state='DISPATCHED',native_journal='COMPLETE',controller_return='NOT_PRESERVED',fresh_audit='PASS',replayed=False)],'wrongtype controller interruption retained')
    require(r['totals']==dict(target_pairs=12,routes=24,catalog_witnesses=24,wrongtype_fixtures=24,
        deploy_rejections=24,uninstall_rejections=24,foreign_function_witnesses=72,full_snapshot_preservations=48,
        complete_native_journals=12,retained_successful_process_results=11,unpreserved_process_results=1,failed_cleaned_cases=0,fresh_audits=12,failed_audits=1,controller_io_failures=1,target_audit_dispatches=25,actual_databases_removed=24),'wrongtype totals')
    require(r['bounds']==dict(native_max=28,db_reservations_max=28,dispatches=25,db_reservations=24,
        changed_adapter_cases_max=2,changed_adapter_cases=2,native_minutes_max=60,native_closed=True,native_within_bound=True),'wrongtype finite bounds')
    require(r['not_claimed']==['full_process_qualification_for_index4','whole_original_controller_PASS','fixture_restoration_or_normal_public_uninstall','real_different_owner_or_lowpriv',
        'all_other_slot_collisions','new_crossdb_login','heap_or_capacity','authenticated_tls','whole_module_qualification'],'wrongtype scope limits')
    current=native.validate(root)
    return dict(status=r['status'],functional_status=r['functional_status'],current_product_source_match=current['current_product_source_match'])


if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
