"""Originale XLSX-Zellfixture-Ausführung und aktuelle Anwendbarkeit trennen."""
from pathlib import Path
import json
import validate_xlsx_native_package as native

REPORT='Releases/1.0.0/XLSX-CELL-API-REST-QUALIFICATION.json'
NAMES=['Types.Contract.sql','Types.Safety.sql','Display.Contract.sql','Display.Safety.sql']


def validate(root, record=None):
    root=Path(root)
    record=record if record is not None else json.loads((root/REPORT).read_bytes())
    require=native.require
    require(record['schema_version']=='toolbelt-xlsx-cell-api-rest/v1' and record['status']=='PASS_FOR_DECLARED_SCOPE','cell scope')
    require(record['publication_authorized'] is False and record['product_code_changed'] is False and record['rights_granted'] is False,'cell authority')
    require(record['package']=={'path':native.PACKAGE,'sha256':native.digest((root/native.PACKAGE).read_bytes())},'cell package bytes')
    require([m['scope'] for m in record['methods']]==['cell-api-rest','cell-display-rest'],'cell method scopes')
    for method in record['methods']:
        names=NAMES if method['scope']=='cell-api-rest' else NAMES[2:]
        required=set(native.METHOD_FILES) | {'Tests/Release/Invoke-XlsxFullSizeLab.ps1','Tests/Release/Invoke-XlsxFullSizeMatrix.ps1',
                  'Tests/Release/Prepare-XlsxCellApiRunset.ps1','Tests/Release/Xlsx.CellApi.Workload.ps1'}
        required.update('Modules/toolbelt.file.xlsx-memory/Tests/Runtime/'+n for n in names)
        require(required<=set(method['source_sha256']),'cell method dependency missing')
        sources=native.git_sources(root,method['source_commit'],list(method['source_sha256']))
        require(all(native.digest(data)==method['source_sha256'][name] for name,data in sources.items()),'cell original source drift')
    cases=record['cases']
    require([c['index'] for c in cases]==list(range(1,12)),'cell exact disjoint matrix')
    matrix=native.expected_matrix()
    for case in cases:
        i=case['index']; platform,version,cl=matrix[i]
        require((case['platform'],case['version'],case['cl'])==(platform,version,cl),'cell matrix context')
        patch='latest' if platform=='linux' else {'2019':'cu32','2022':'cu26','2025':'cu8'}[version]
        require(case['patch']==patch,'cell patch')
        modes=['central'] if i==11 else ['local','central']
        names=NAMES if i<9 else NAMES[2:]
        require(case['scope']==('cell-api-rest' if i<9 else 'cell-display-rest') and case['modes']==modes,'cell disjoint modes')
        require(case['fixtures']==[mode+'/'+name for mode in modes for name in names],'cell complete original fixtures')
        require(case['state']=='COMPLETE' and case['audit']=='PASS' and case['databases_removed']==len(modes),'cell cleanup/audit')
    require(record['totals']==dict(fixture_executions=74,successful_cases=11,fresh_audits=11,target_audit_dispatches=22,actual_databases_removed=21),'cell totals')
    expected=[dict(scope='cell-api-rest',native_max=20,db_reservations_max=20,dispatches=16,db_reservations=16,native_minutes_max=60,native_closed=True,native_within_bound=True),
              dict(scope='cell-display-rest',native_max=6,db_reservations_max=6,dispatches=6,db_reservations=6,native_minutes_max=60,native_closed=True,native_within_bound=True)]
    require(record['waves']==expected,'cell closed bounds')
    require(record['controller_history']==['INITIAL_BUDGET_DUPLICATE_COMPLETED_KEYS; stopped before dispatch; corrected private initialization; no SQL/resources'],'cell controller failure history')
    require(record['not_claimed']==['new_minimal_rights_test','new_crossdb_identity','genuine_upgrade_matrix','full_collision_matrix','heap_or_capacity','authenticated_tls','whole_module_qualification'],'cell claim boundaries')
    result=native.validate(root)
    return dict(status=record['status'],current_product_source_match=result['current_product_source_match'])


if __name__=='__main__':
    print(json.dumps(validate(Path(__file__).resolve().parents[2]),sort_keys=True))
