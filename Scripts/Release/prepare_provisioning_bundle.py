"""rc.4-Lieferung: neue Vorbereitung, unveränderte SQL-Basis, getrennte Nachweise."""
import argparse
import json
from pathlib import Path
import re
import prepare_one_call_bundle as base

TAG = 'v1.0.0-rc.4'
ENTRY = base.ENTRY
HELPER = 'Deployment/Toolbelt.Provisioning.ps1'
EVIDENCE = 'Deployment/Tests/Qualification/InstallerProvisioning.20261119.json'
GUIDE = 'Releases/1.0.0/RC4-INSTALL.md'
DOCS = {'START-HERE.md': GUIDE, 'INSTALL.md': 'INSTALL.md',
        'Deployment/ONE-CALL-INSTALL.md': 'Deployment/ONE-CALL-INSTALL.md',
        'Deployment/PROVISIONING.md': 'Deployment/PROVISIONING.md'}
ENTRY_GUARD_ANCHOR = b"                $preparationJournal.Record.state='PREPARATION_COMPLETE'\n"
ENTRY_GUARD_DELTA = b"""                if($null -ne $parsed.database_guid -and $preparedGuid -ne [guid]$parsed.database_guid){Stop-ToolbeltInstall 'TBX_TARGET_CHANGED' 'Die vorhandene Datenbank wurde w\xc3\xa4hrend der Vorbereitung ersetzt.'}
                if($created.Count -eq 1 -and $preparedGuid -ne [guid]$created[0].Groups[1].Value){Stop-ToolbeltInstall 'TBX_TARGET_CHANGED' 'Die angelegte Datenbank wurde w\xc3\xa4hrend der Vorbereitung ersetzt.'}
"""


def payload(commit):
    commit = base.source.git('rev-parse', commit+'^{commit}').decode().strip()
    base.require(bool(re.fullmatch('[0-9a-f]{40}', commit)), 'Quellcommit fehlt')
    # Unveränderte historische Wahrheit aus der rc.3-Integration übernehmen.
    original = base.payload('857383be62543e9c918b518dec5c841148368897')
    files = {p:b for p,b in original.items() if p in (base.INNER, base.EVIDENCE, 'LICENSE.md') or p.startswith('ThirdParty/')}
    evidence_bytes = base.git_file(commit, EVIDENCE)
    evidence = json.loads(evidence_bytes)
    base.require(evidence['kind'] == 'installer_provisioning' and evidence['result'] == 'PASS_FOR_DECLARED_SCOPE', 'Vorbereitungsnachweis fehlt')
    expected = {(p,v) for p in ('windows','linux') for v in ('2019','2022','2025')}
    base.require(len(evidence['cases']) == 6 and {(c['platform'],c['sql_version']) for c in evidence['cases']} == expected
        and all(c['result'] == 'PASS_FOR_DECLARED_SCOPE' and c['audit'] == 'PASS' and c['modes'] == ['local','central']
                and c['databases_created'] == 2 for c in evidence['cases']), 'Native Matrix unvollständig')
    base.require(evidence['actual_clr_activations'] >= 1 and evidence['new_tls_gui_tests'] is False, 'CLR-Übergang/Scope fehlt')
    base.require(evidence['safety'] == {'result':'COMPLETE','checks':3,'audit':'PASS','new_databases':0}, 'Native Sicherheitsgrenzen fehlen')
    base.require(evidence['history']['initial_native_state'] == 'FAILED_CLEANED'
                 and evidence['history']['initial_fresh_audit'] == 'PASS'
                 and evidence['history']['failed_coordinator_promoted_to_pass'] is False, 'Frühere Fehler/Audit fehlen')
    base.require(evidence['scope']['authentication'] == 'explicit SqlCredential'
        and evidence['scope']['native_windows_integrated_login'] == 'not executed'
        and evidence['scope']['module_requalification'] is False
        and evidence['module_release_status_changed'] is False, 'Qualifikationsscope aufgewertet')
    for case in evidence['cases']:
        profiles=case['profile_sources']
        base.require(len(profiles)==2 and {p['mode'] for p in profiles} == {'local','central'}, 'Profilzuordnung fehlt')
        for profile in profiles:
            expected_count=(45 if profile['mode']=='local' else 43) if case['platform']=='windows' else 41
            partial=case['platform']=='windows' and case['sql_version']=='2019' and profile['mode']=='local'
            base.require(profile['receipt']=='INSTALLED' and profile['fresh_audit']=='PASS'
                and profile['modules']==expected_count and profile['native_state']==('FAILED_CLEANED' if partial else 'COMPLETE'),
                'Profil-/Fehlernachweis falsch zugeordnet')
    base.require(evidence['offline']['synthetic_assertions']==122 and
        evidence['offline']['source_sha256']==base.sha(base.git_file(commit,'Deployment/Tests/Test-InstallerProvisioning.ps1').replace(b'\r\n',b'\n')), 'Offline-Gegenprobenbindung fehlt')
    for path,digest in evidence['method_source_sha256'].items():
        base.require(base.sha(base.git_file(commit,path).replace(b'\r\n',b'\n')) == digest, 'Methodendrift: '+path)
    matrix_commit=evidence['matrix_source_commit']
    for path,digest in evidence['matrix_method_source_sha256'].items():
        matrix_bytes=base.git_file(matrix_commit,path).replace(b'\r\n',b'\n')
        base.require(base.sha(matrix_bytes) == digest, 'Originale Matrixbindung abweichend: '+path)
        current_bytes=base.git_file(commit,path).replace(b'\r\n',b'\n')
        if path == ENTRY:
            base.require(matrix_bytes.count(ENTRY_GUARD_ANCHOR) == 1 and
                current_bytes == matrix_bytes.replace(ENTRY_GUARD_ANCHOR,ENTRY_GUARD_DELTA+ENTRY_GUARD_ANCHOR), 'Nicht belegte Erweiterung des Matrix-Einstiegs')
        else:
            base.require(matrix_bytes == current_bytes, 'Unbelegte Methodenänderung gegenüber Matrix: '+path)
    base.require(evidence['identity_guard_fresh_case'] == {'result':'COMPLETE','audit':'PASS','modes':['local'],'platform':'windows','sql_version':'2025'}, 'Frischer Gesamtfall des Identitätsguards fehlt')
    base.require({ENTRY,HELPER,'Deployment/Tests/Invoke-InstallerProvisioningLab.ps1','Deployment/Tests/Invoke-ProvisioningSafetyLab.ps1'} <= evidence['method_source_sha256'].keys(), 'Methoden fehlen')
    files.update({p:base.git_file(commit,p) for p in (ENTRY,HELPER,EVIDENCE)})
    delivered = set(files)|DOCS.keys()
    for destination,origin in DOCS.items():
        files[destination] = base.relocate_doc(base.git_file(commit,origin),origin,destination,delivered,commit,DOCS)
    files[base.MANIFEST] = base.encoded({'kind':'provisioning_install_bundle','project_prerelease':TAG,'source_commit':commit,
        'entrypoint':ENTRY,'base_release':'v1.0.0-rc.2','base_package':{'path':base.INNER,'sha256':base.INNER_SHA},
        'preparation_evidence':{'path':EVIDENCE,'sha256':base.sha(evidence_bytes)},
        'historical_evidence':{'path':base.EVIDENCE,'qualified_entry_commit':'857383be62543e9c918b518dec5c841148368897',
            'scope':'original client only; no automatic extension to changed preparation'},
        'new_tls_gui_tests':False,'module_release_status_changed':False,
        'files':{p:{'bytes':len(b),'sha256':base.sha(b)} for p,b in sorted(files.items())}})
    files[base.SUMS] = ''.join(base.sha(b)+'  '+p+'\n' for p,b in sorted(files.items())).encode()
    base.require(sum(map(len,files.values())) <= base.MAX_BYTES, 'Lieferbudget')
    return files


def verify(path):
    path=Path(path);data=path.read_bytes()
    base.require(Path(str(path)+'.sha256').read_text().split() == [base.sha(data),path.name], 'Äußere Prüfsumme')
    files=base.read_zip(data);record=json.loads(files[base.MANIFEST])
    base.require(record.get('kind') == 'provisioning_install_bundle' and record.get('project_prerelease') == TAG, 'Liefervertrag')
    base.require(files == payload(record['source_commit']), 'Abweichende Lieferbytes')
    return record


def build(commit,output):
    output=Path(output);sidecar=Path(str(output)+'.sha256')
    base.require(output.parent.is_dir() and not output.exists() and not sidecar.exists(), 'Neues Ausgabeziel erforderlich')
    data=base.write_zip(payload(commit));output.write_bytes(data)
    sidecar.write_text(base.sha(data)+'  '+output.name+'\n',encoding='ascii')
    verify(output)


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--build',action='store_true');group.add_argument('--verify',type=Path)
    parser.add_argument('--source-commit');parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    if args.verify:verify(args.verify)
    else:build(args.source_commit,args.output)
    print('PASS PROVISIONING_BUNDLE exact Git bytes and separate native binding')
