"""ANSI-Sicherheitsdelta; C7 bleibt historisch, TLS und Gesamtmodul separat."""
from pathlib import Path
import hashlib
import json
from ssis_historical_scope import copy_column_v1_scope, COPY_COLUMN_BASELINE

ROOT=Path(__file__).resolve().parents[2]
MODULE='Modules/toolbelt.tsql.ssis-debug/'
REPORT=MODULE+'Tests/Qualification/CopyColumn.SecurityCorrection.20261115.json'
REVIEW=MODULE+'Tests/Qualification/Security.CopyColumn.20261115.json'
CONTEXTS={('2019',150,'local'),('2019',150,'central'),('2025',170,'local'),('2025',170,'central')}
METHODS={MODULE+'Tests/Runtime/'+p for p in ('Invoke-CopyColumnAnsiLab.ps1','Invoke-CopyColumnAnsiCases.ps1','Invoke-LabContract.ps1','Invoke-CurrentCases.ps1','Invoke-ComponentsV2Lab.ps1','Invoke-ComponentsV2Audit.ps1')}
METHODS.update(MODULE+'Tests/Framework/'+p for p in ('ContractTests.cs','CopyColumnTests.cs','Invoke-Contract.ps1'))
METHODS.update(('Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1',MODULE+'Contracts/Api.json'))
# Exakte Rückprojektion schützt die Wiederverwendung vor zusätzlichen,
# selbstkonsistent neu gehashten Produktänderungen.
ADDITIONS=(
    '        // ANSI-Lineage nur nach Katalogprüfung setzen; kein Encoding raten.\n        internal int? SourceCodePage;\n',
    '                col.SourceCodePage = outputColumn.Type == "str" ? (int?)outputColumn.CodePage : null;\n',
    '                // Übereinstimmende XML-Ports beweisen keine ANSI-Identität:\n                // beide können dieselbe falsche Codepage deklarieren. Die\n                // tatsächliche Encodinggrenze folgt der aufgelösten Quelle.\n                if (selected[0].Type == "str" && (selected[0].CodePage <= 0 || !input.SourceCodePage.HasValue || input.SourceCodePage.Value != selected[0].CodePage))\n                    throw new DebugFault("unsupported_component", "Copy Column-ANSI-Codepage stimmt nicht mit der aufgelösten Quellcollation überein.");\n',
    '                outputColumn.SourceCodePage = input.SourceCodePage;\n')

def require(ok,label):
    if not ok: raise ValueError('SSIS_COPY_SECURITY_'+label)

def validate(record=None,*,check_files=True):
    r=record if record is not None else json.loads((ROOT/REPORT).read_bytes())
    require(r['kind']=='ssis_copy_column_ansi_security_correction' and r['result']=='PASS_FOR_DECLARED_SCOPE','IDENTITY')
    require(r['scope']=={'ansi_lineage_correction':True,'full_module_qualification':False,'fresh_zip_matrix':False,'fresh_ssms':False,'fresh_authenticated_tls':False,'security_total_acceptance':False,'publication_authorized':False},'SCOPE')
    require(all(type(value) is bool for value in r['scope'].values()),'SCOPE_TYPES')
    require(r['provider']=={'sha256':'04f2e29becfa551a985537fbc74447984cde416eb8ffde17afbd8e2453a7360f','sha512':'b10c498e58a2fc1dddb2d7e7cab3a823523c870cdc3f8378f030d59182664d7cf2e017193e52b5cb24ff50f21973162daf037784ec3ea9a409bbb9f56b04b40b'},'PROVIDER')
    require(r['baseline']==COPY_COLUMN_BASELINE and r['prior_evidence_unchanged'] is True,'BASELINE')
    require(r['framework']=={'full_bounded_children':29,'changed_copy_children_rechecked':2,'result':'PASS','sql_executed':False},'FRAMEWORK')
    cases=r['cases'];require(len(cases)==4 and {(c['sql_version'],c['compatibility_level'],c['deployment_mode']) for c in cases}==CONTEXTS,'CONTEXTS')
    require(all(c['result']=='PASS_CLEANED' and c['cleanup_audit']=='PASS' and c['assertions']==93 and c['profiles']==4 and c['platform']=='windows' and c['test_purpose']=='Functional' and c['patch']=={'2019':'CU32','2025':'CU8'}[c['sql_version']] for c in cases),'RESULTS')
    require(r['assertions']==372 and r['profiles']==16 and r['fresh_audits']==4,'TOTALS')
    require(r['history']=={'first_total_case':'FAILED_CLEANED','first_audit':'PASS','recovery_fourth_audit_admission':'BLOCKED_BEFORE_SQL_SOURCE_DRIFT','recovery_fourth_fresh_audit':'PASS','failures_preserved':True},'HISTORY')
    require(r['accounting']=={'target_audit_dispatches':11,'database_reservations':5,'owned_databases_removed':5,'closed':True},'ACCOUNTING')
    if check_files:
        with copy_column_v1_scope(ROOT) as snapshot:
            import validate_ssis_copy_column_functional as prior
            prior.validate()
            product={p.relative_to(ROOT).as_posix() for p in (ROOT/MODULE/'Clr').iterdir() if p.suffix in ('.cs','.csproj')}
            product.update(p.relative_to(ROOT).as_posix() for p in (ROOT/MODULE/'Exchange/Core').glob('*.cs'))
            product.add('Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs')
            require(set(r['product_projection'])==product,'COMPLETE_PRODUCT')
            require(set(r['source_sha256'])==product|METHODS,'COMPLETE_METHODS')
            for name,digest in r['product_projection'].items():
                old=(snapshot/name).read_bytes();data=(ROOT/name).read_bytes()
                require(hashlib.sha256(old).hexdigest()==digest,'BASELINE_SOURCE')
                if name==MODULE+'Clr/Translator.cs':
                    text=data.decode('utf-8')
                    for addition in ADDITIONS:
                        require(text.count(addition)==1,'EXACT_DELTA')
                        text=text.replace(addition,'',1)
                    data=text.encode('utf-8')
                require(data==old,'PRODUCT_PROJECTION')
        for name,digest in r['source_sha256'].items():
            p=(ROOT/name).resolve()
            require(p.is_relative_to(ROOT.resolve()) and hashlib.sha256(p.read_bytes()).hexdigest()==digest,'SOURCE_DRIFT')
    return r

def validate_review(record=None):
    r=record if record is not None else json.loads((ROOT/REVIEW).read_bytes())
    delta=validate()
    require(r['kind']=='ssis_independent_copy_column_security_acceptance' and r['result']=='SOURCE_ACCEPTED' and r['review_kind']=='static_security_contract','REVIEW_IDENTITY')
    require(r['independent_reviewer'] is True and r['runtime_executed_by_reviewer'] is False and r['reviewer_agents']==1 and r['changed_input_followups']==2,'INDEPENDENCE')
    require(r['scope']=={'current_product_source':True,'bounded_tls_method_source':True,'native_tls_result':False,'full_module_qualification':False,'publication_authorized':False} and all(type(v) is bool for v in r['scope'].values()),'REVIEW_SCOPE')
    require(r['provider']==delta['provider'] and r['open_findings']==[],'REVIEW_PROVIDER_FINDINGS')
    require([(f['id'],f['severity'],f['status']) for f in r['resolved_findings']]==[('F-C7-01','P1','closed'),('F-C7-02','P2','closed'),('F-C7-03','P2','closed'),('F-C7-04','P2','closed')],'FINDING_DISPOSITIONS')
    reuse=r['historical_reuse'];p=ROOT/reuse['record']
    require(reuse['record']==MODULE+'Tests/Qualification/Security.CurrentBuild.20261104.json' and hashlib.sha256(p.read_bytes()).hexdigest()==reuse['sha256'] and reuse['unchanged_reviewed_sources']==12 and reuse['original_records_preserved'] is True,'REVIEW_HISTORY')
    prior=json.loads(p.read_bytes())['reviewed_product_sha256']
    require(set(r['source_sha256'])==set(prior)|set(delta['source_sha256']),'REVIEW_SOURCE_CLOSURE')
    for name,digest in r['source_sha256'].items():
        require(hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,'REVIEW_SOURCE_DRIFT')
    require(sum(r['source_sha256'][name]==digest for name,digest in prior.items())==12,'REVIEW_REUSE_PROJECTION')
    method=r['bounded_tls_method']
    require(method['repository']=='gecompat/SQL_Server_Lab' and method['path']=='Tests/Integration/Invoke-ToolbeltSsisCopyColumnTlsAcceptance.ps1' and method['sha256']=='65503e7c01ffc07bd5645fc303998bd93c23f055c34fa4a0f92f8181478c6b99' and method['private_bootstrap_originals_retained'] is True and method['review_result']=='SOURCE_ACCEPTED','TLS_METHOD_REVIEW')
    lab_review=r['lab_context_revision_review']
    require(all(type(lab_review[k]) is bool for k in ('native_revision_committed','native_tls_executed','registry_freshness_floor_preserved')),'LAB_REVIEW_TYPES')
    require(lab_review=={
        'result':'SOURCE_ACCEPTED','finding':'F-LAB-CTX-01','status':'closed_source_side',
        'repository':'gecompat/SQL_Server_Lab',
        'source_sha256':{
            'Private/AuthenticatedTlsAuthority.ps1':'aa4db12b0ba8a4571f7af928eb8f10a742001d8856f5f604ed392a05c1d1c7ac',
            'Tests/Static/Invoke-AuthenticatedTlsContextSelectionChecks.ps1':'28d1e585f17637c6a23bb60b668ce71e6701f460f8613b2c32d4e5c373d9ac8e'},
        'native_revision_committed':False,'native_tls_executed':False,
        'registry_freshness_floor_preserved':True},'LAB_REVIEW_SCOPE')
    return r

if __name__=='__main__':
    validate()
    validate_review()
    print('SSIS_COPY_SECURITY_DELTA_PASS; 4contexts/372assertions/4fresh audits; TLS/security-total separate')
