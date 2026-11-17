"""Fresh strict transport and security gates; historical ZIP/SSMS stay separate."""
from pathlib import Path
import hashlib
import json
from ssis_parser_binding_history import historical_dependency_source
import subprocess
import validate_ssis_copy_column_security as security

ROOT=Path(__file__).resolve().parents[2]
MODULE='Modules/toolbelt.tsql.ssis-debug/'
REPORT=MODULE+'Tests/Qualification/Tls.CopyColumn.SecurityCorrection.20261115.json'

def require(ok,label):
    if not ok:raise ValueError('SSIS_COPY_TLS_SECURITY_'+label)

def source_paths():
    # Authored public inputs, including new nonignored sources. CI-generated
    # bin/obj files are outputs, not additions to the admitted source closure.
    directories=[MODULE+p for p in ('Tests/Runtime','Tests/Fixtures','Contracts','Clr','Exchange/Core')]
    inventory=subprocess.check_output(['git','-C',str(ROOT),'ls-files','-z','--cached','--others','--exclude-standard','--',*directories])
    paths={name for name in inventory.decode('utf-8').split('\0') if name}
    paths.update(('Tests/CI/LabQualifiedContract.ps1','Tests/CI/run-lab-local.ps1'))
    paths.update(MODULE+'Tests/Qualification/'+name for name in (
        'CopyColumn.SecurityCorrection.20261115.json','CopyColumn.V1.20261114.json','CopyColumn.Delivery.20261115.json'))
    return paths

def validate(record=None):
    r=record if record is not None else json.loads((ROOT/REPORT).read_bytes())
    delta=security.validate();security.validate_review()
    require(r['kind']=='ssis_copy_column_strict_tls_security_acceptance' and r['result']=='PASS_FOR_DECLARED_SCOPE','IDENTITY')
    require(r['provider']==delta['provider'],'PROVIDER')
    require(r['scope']=={'current_strict_tls':True,'independent_source_security_review':True,'full_module_qualification':False,'fresh_zip_matrix':False,'fresh_ssms':False,'publication_authorized':False}
            and all(type(v) is bool for v in r['scope'].values()),'SCOPE')
    require(r['transport']=={'test_purpose':'AuthenticatedTls','authentication':'SQL','encrypt':True,'trust_server_certificate':False,'signed_v2_export':True,'same_bytes_per_open':True,'fallback_used':False,'wire_fingerprint_observed':False,'lab_client_stacks':['SYSTEM_DATA_SQLCLIENT','ODBC_SQLCMD'],'consumer_guarded_opens':4},'TRANSPORT')
    require(all(type(r['transport'][k]) is bool for k in ('encrypt','trust_server_certificate','signed_v2_export','same_bytes_per_open','fallback_used','wire_fingerprint_observed')),'TRANSPORT_TYPES')
    require(r['cases']==[{'platform':'windows','sql_version':'2025','build':'17.0.1000.7','compatibility_level':170,'deployment_mode':mode,'assertions':208,'result':'PASS'} for mode in ('local','central')],'CONTEXTS')
    require((r['assertions'],r['worker_cases'],r['supervisor_cases'])==(416,6,8),'TOTALS')
    cleanup=r['cleanup']
    require(cleanup=={'sql_journal':'PASS_CLEANED','fresh_sql_audit':'PASS','lab_coordinator':'PASS','fresh_lab_audit':'PASS','fresh_host_scope_audit':'PASS','sql_configuration_restored':True,'host_trust_restored':True,'owned_encrypted_ca_key_removed':True,'foreign_bindings_unchanged':True,'active_consumers':0,'sealed_private_root_retained':True},'CLEANUP')
    require(all(type(cleanup[k]) is bool for k in ('sql_configuration_restored','host_trust_restored','owned_encrypted_ca_key_removed','foreign_bindings_unchanged','sealed_private_root_retained')),'CLEANUP_TYPES')
    require(r['accounting']=={'native_total_cases':1,'target_audit_dispatches':2,'owned_databases_removed':4,'owned_vms_removed':1,'own_ca_trust_imports':1,'own_ca_trust_removals':1,'maximum_minutes':45,'retries':0,'closed':True},'ACCOUNTING')
    require(r['history']=={'selected_authority_revision':'BLOCKED_BEFORE_COMMIT','failed_reviews_preserved':True,'earlier_native_records_unchanged':True,'private_originals_retained':True},'HISTORY')
    review=r['source_review']
    require(review['path']==security.REVIEW and review['result']=='SOURCE_ACCEPTED' and hashlib.sha256((ROOT/review['path']).read_bytes()).hexdigest()==review['sha256'],'SOURCE_REVIEW')
    lab=r['lab_method']
    require(lab=={'repository':'gecompat/SQL_Server_Lab','native_source_commit':'f81406480d423cc92dcc41ddef0e8e99a8e8cd77','path':'Tests/Integration/Invoke-ToolbeltSsisCopyColumnTlsAcceptance.ps1','sha256':'65503e7c01ffc07bd5645fc303998bd93c23f055c34fa4a0f92f8181478c6b99','source_inventory_files':1723},'LAB_METHOD')
    require(r['toolbelt_input_count']==119 and r['authored_source_count']==103 and r['non_source_input_count']==16
            and len(r['source_sha256'])==103 and set(r['source_sha256'])==source_paths(),'SOURCE_CLOSURE')
    for name,digest in r['source_sha256'].items():
        p=(ROOT/name).resolve()
        require(p.is_relative_to(ROOT.resolve()) and hashlib.sha256(historical_dependency_source(ROOT,name)).hexdigest()==digest,'SOURCE_DRIFT')
    return r

if __name__=='__main__':
    validate()
    print('SSIS_COPY_TLS_SECURITY_PASS; current provider; local/central416; SQL/Lab/host audits; no whole-module upgrade')
