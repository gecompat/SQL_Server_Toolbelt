"""Aktuellen gemeinsamen Installer aus einem geschlossenen Git-Bytesnapshot abnehmen."""
from __future__ import annotations
import hashlib
import io
import json
import zipfile

PACKAGE="Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Current-Install.zip"
RECORD="Releases/1.0.0/CURRENT-INSTALL-QUALIFICATION.json"
METHODS={"Tests/Release/Invoke-CurrentInstallLab.ps1","Tests/Release/Runtime/Invoke-ParameterHelpCases.ps1",
         "Tests/Release/ClrCaller.Environment.ps1","Tests/Release/Invoke-ApiQualificationLab.ps1",
         "Tests/Release/Invoke-StablePackageLab.ps1","Tests/CI/run-csv-memory-lab.ps1",
         "Tests/CI/run-lab-local.ps1","Tests/CI/LabQualifiedContract.ps1"}


def require(value,message):
    if not value: raise ValueError("CURRENT_INSTALL_QUALIFICATION: "+message)


def sha(data):return hashlib.sha256(data).hexdigest()


def installer_inputs(files):
    """Keine alten Paketbytes zu aktuellen erklären; neue qualifizierte Bytes exakt binden."""
    require(PACKAGE in files and RECORD in files,"package and native record required")
    record=json.loads(files[RECORD])
    require(record['kind']=='current_combined_fresh_install_qualification' and record['result']=='PASS_FOR_DECLARED_SCOPE',"native result")
    require(all(record[k] is False for k in ('publication_authorized','full_business_requalification','new_tls_execution','new_gui_execution')),"scope")
    require(record['package']['path']==PACKAGE and record['package']['sha256']==sha(files[PACKAGE]),"executed archive")
    require(files[PACKAGE+'.sha256'].decode('ascii').split()==[sha(files[PACKAGE]),PACKAGE.rsplit('/',1)[1]],"archive checksum")
    with zipfile.ZipFile(io.BytesIO(files[PACKAGE])) as archive:
        names=archive.namelist()
        require(len(names)==len(set(names)),"duplicate archive names")
        payload={n:archive.read(n) for n in names}
    require(record['package']['payload_sha256']=={n:sha(b) for n,b in payload.items()},"exact executed payload")
    metadata=json.loads(payload['PACKAGE.json'])
    require(metadata['scope']=='CURRENT_COMBINED_FRESH_INSTALL' and metadata['publication_authorized'] is False,"package scope")
    require(metadata['files']=={n:sha(b) for n,b in payload.items() if n not in ('PACKAGE.json','SHA256SUMS')},"payload manifest")
    require(payload['SHA256SUMS']==''.join(sha(b)+'  '+n+'\n' for n,b in sorted(payload.items()) if n!='SHA256SUMS').encode(),"payload checksums")
    for path,digest in metadata['source_sha256'].items():
        require(path in files and sha(files[path].replace(b'\r\n',b'\n'))==digest,"current deployment source: "+path)
    provenance=json.loads(payload['BINARY-PROVENANCE.json'])
    current={p:sha(b.replace(b'\r\n',b'\n')) for p,b in files.items() if p.startswith('Modules/') and '/Clr/' in p and p.endswith(('.cs','.csproj')) and not {'bin','obj'} & set(p.split('/'))}
    require(provenance['compiled_source_sha256']==current,"complete current compiler source closure")
    require(set(record['method_source_sha256'])==METHODS,"native method closure")
    for path,digest in record['method_source_sha256'].items():
        require(path in files and sha(files[path].replace(b'\r\n',b'\n'))==digest,"native method source: "+path)
    expected={(p,v,{'2019':150,'2022':160,'2025':170}[v]) for p in ('windows','linux') for v in ('2019','2022','2025')}
    require(len(record['cases'])==6 and {(c['platform'],c['sql_version'],c['compatibility_level']) for c in record['cases']}==expected,"six target pairs")
    for case in record['cases']:
        require(case['result']=='COMPLETE' and case['fresh_independent_audit']=='PASS' and case['audit_binds_final_journal'] is True,"fresh audit")
        require(case['body_exit_code']==0 and case['audit_exit_code']==0 and case['capture_complete'] is True and case['stderr_empty'] is True,"process receipts")
        require(case['owned_databases_removed']==2 and case['own_trust_removed_or_preexisting'] is True and case['configuration_restored_or_unchanged'] is True,"cleanup")
        require([p['mode'] for p in case['profiles']]==['local','central'] and all(p['profile']==('Windows' if case['platform']=='windows' else 'Portable') for p in case['profiles']),"installed profiles")
    require(record['history']['failed_total_cases']==2 and record['history']['failed_case_audits_pass']==2 and record['history']['original_failures_and_receipts_preserved'] is True,"failure history")
    require(record['accounting']['closed'] is True and record['accounting']['reserved_target_audit_dispatches']==17 and record['accounting']['reserved_databases']==18 and record['accounting']['owned_databases_removed']==14 and record['accounting']['original_start_and_deadline_preserved'] is True,"closed common budget")
    require(record['totals']=={'profiles':12,'fresh_success_audits':6,'parameter_help_assertions':126810,'help_calls_including_internal':1578,'module_inventory_checks':510},"declared totals")
    require(payload['LICENSE.md']==files['LICENSE.md'],"license")
    return {'path':PACKAGE,'sha256':sha(files[PACKAGE]),'evidence':RECORD,'evidence_sha256':sha(files[RECORD]),'scope':record['scope'],'profiles':metadata['profiles']}
