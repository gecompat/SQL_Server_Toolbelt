"""Gezielter neuer Prozessnachweis, historische unbekannte Werte bleiben unverändert."""
from pathlib import Path
import json
import validate_xlsx_native_package as native
import validate_xlsx_wrongtype_rest as prior
REPORT='Releases/1.0.0/XLSX-WRONGTYPE-PROCESS-CLOSURE.json'

def validate(root,record=None):
 root=Path(root);r=record if record is not None else json.loads((root/REPORT).read_bytes());need=native.require
 need(r['schema_version']=='toolbelt-xlsx-wrongtype-process-closure/v1' and r['status']=='PASS_FOR_DECLARED_SCOPE','process closure status')
 need(not r['publication_authorized'] and not r['product_code_changed'] and not r['rights_granted'],'process authority')
 need(r['historical_reference']==dict(path=prior.REPORT,sha256=native.digest((root/prior.REPORT).read_bytes()),status='PARTIAL',unknown_original_return_preserved=True),'immutable partial predecessor')
 prior.validate(root)
 need(r['package']==dict(path=native.PACKAGE,sha256=native.digest((root/native.PACKAGE).read_bytes())),'same current package')
 m=r['method'];need(set(native.METHOD_FILES)|{'Tests/Release/Invoke-XlsxWrongTypeProcessOnce.ps1','Tests/Release/Xlsx.OwnedDatabase.ps1','Tests/Release/Xlsx.WrongType.Workload.ps1','Tests/Release/Prepare-XlsxWrongTypeRunset.ps1'}<=set(m['source_sha256']),'process original method closure')
 need(all(native.digest(v)==m['source_sha256'][p] for p,v in native.git_sources(root,m['source_commit'],list(m['source_sha256'])).items()),'process original executed bytes')
 need(r['case']==dict(index=4,platform='linux',version='2025',patch='latest',cl=160,modes=['local','central'],state='COMPLETE',fresh_audit='PASS',databases_removed=2,processes=[dict(phase=p,exit_code=0,capture_complete=True,stderr_empty=True,numeric_receipt_retained=True,bound_receipt_retained=True) for p in ['RUN','AUDIT']]),'exact case and two process receipts')
 need(r['receipt_method']==dict(numeric_return_before_other_metadata_reads=True,exclusive_create=True,write_through=True,flush_to_disk=True),'durable primary process observation')
 need(r['combined']==dict(reused_process_cases=11,new_process_cases=1,qualified_target_pairs=12,qualified_routes=24,other_historical_cases_replayed=False,original_failures_unchanged=True),'no broad replay or history upgrade')
 need(r['bounds']==dict(native_calls_max=2,database_max=2,minutes_max=45,dispatches=2,databases=2,retries=0,native_closed=True,within_bound=True),'new finite authority')
 need(r['not_claimed']==['original_unknown_return_reconstructed','original_failed_controllers_PASS','whole_module_qualification','new_owner_or_lowpriv','authenticated_tls','heap_or_capacity'],'process limits')
 return dict(status=r['status'],current_product_source_match=native.validate(root)['current_product_source_match'])
if __name__=='__main__':print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
