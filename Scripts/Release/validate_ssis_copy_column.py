"""Exact Copy Column delta evidence; never a whole-module or fresh ZIP claim."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
MODULE='Modules/toolbelt.tsql.ssis-debug/'
REPORT=MODULE+'Tests/Qualification/CopyColumn.V1.20261114.json'
CONTEXTS={(v,cl,m) for v,levels in [('2019',[150]),('2022',[150,160]),('2025',[150,160,170])] for cl in levels for m in ['local','central']}
PROCEDURE_GUARD='''            // Die Einzelfreigabe umfasst nur Debug-SQL. Der gemeinsame
            // Stagebuilder darf die Komponente nicht stillschweigend auch
            // für die getrennte Prozedurdefinition zulassen.
            if (options.ProcedureDefinition)
                throw new DebugFault("procedure_profile", "Copy Column V1 ist ausschließlich für explain freigegeben.");
'''.encode('utf-8')


def require(value,message):
    if not value: raise ValueError('SSIS_COPY_QUALIFICATION: '+message)


def validate(record=None,*,check_files=True):
    record=record if record is not None else json.loads((ROOT/REPORT).read_bytes())
    require(record.get('kind')=='ssis_copy_column_v1_native_qualification' and record.get('profile')=='ssis-debug-copy-column-v1' and record.get('result')=='PASS_FOR_COMPOSED_DELTA','identity')
    require(record.get('publication_authorized') is False and record.get('full_module_qualification') is False and record.get('fresh_zip_matrix') is False,'scope cannot be enlarged')
    require(record.get('scope')=={'operation':'explain','sql_api_parameters':40,'mutation':False,'external_io':False,'actual_ssis_runtime_executed':False,'fresh_ssms':False,'fresh_authenticated_tls':False,'new_principals_or_grants':False},'declared feature scope')
    require(all(record['scope'][key] is False for key in ('mutation','external_io','actual_ssis_runtime_executed','fresh_ssms','fresh_authenticated_tls','new_principals_or_grants')),'strict scope booleans')
    require(record.get('framework')=={'profile':'Full','bounded_children':29,'result':'PASS','copy_column_formats':[6,8]},'framework')
    require(record.get('model_parity')=={'checks':232,'framework':'net48','external_host':'net10.0','platform':'Windows','result':'PASS','native_linux_host':'not executed'},'model parity')
    cases=record.get('cases',[])
    require(len(cases)==12 and {(c.get('sql_version'),c.get('compatibility_level'),c.get('deployment_mode')) for c in cases}==CONTEXTS,'all twelve contexts')
    for case in cases:
        require(case.get('platform')=='windows' and case.get('patch')=={'2019':'CU32','2022':'CU26','2025':'CU8'}[case['sql_version']] and case.get('test_purpose')=='Functional','exact target profile')
        require(case.get('result')=='PASS_CLEANED' and case.get('cleanup_audit')=='PASS' and case.get('profiles')==4 and case.get('assertions')==92 and case.get('authenticated_tls')=='not executed','actual result and audit')
        require(case.get('assembly_sha256')==record.get('native_explain_assembly_sha256') and case.get('applicability')=='unchanged_explain_branch','explicit reused build')
    guards=record.get('procedure_guard_cases',[])
    require(len(guards)==2 and {c.get('deployment_mode') for c in guards}=={'local','central'} and all(c.get('sql_version')=='2025' and c.get('patch')=='CU8' and c.get('compatibility_level')==170 and c.get('result')=='PASS_CLEANED' and c.get('cleanup_audit')=='PASS' and c.get('profiles')==4 and c.get('assertions')==4 and c.get('assembly_sha256')==record.get('qualified_assembly_sha256') for c in guards),'current procedure guard bridge')
    require(record.get('assertions')==1112 and record.get('profiles')==56 and record.get('fresh_audits')==14,'actual totals')
    require(record.get('accounting')=={'target_audit_calls':28,'database_reservations':14,'owned_databases_removed':14,'native_failed_cases':0,'closed':True},'closed accounting')
    require(record.get('reuse_method')=='exact_product_projection_excluding_procedure_guard' and record.get('native_explain_assembly_sha256')!=record.get('qualified_assembly_sha256'),'distinct original and corrected builds')
    sources=record.get('source_sha256',{})
    require(len(sources)>=45 and all(MODULE+p in sources for p in ['Clr/Translator.cs','Exchange/Core/ComponentProfiles.cs','Exchange/Core/PackageDocument.cs','Clr/SqlSafety.cs','Contracts/Api.json','Tests/Framework/CopyColumnTests.cs','Tests/Runtime/Invoke-CopyColumnCases.ps1','Tests/Runtime/Invoke-CopyColumnLab.ps1']),'source closure')
    require(record.get('pre_copy_column_baseline')=='6e1985aee3e0ded746d1a32c6d494b370049872b' and record.get('original_records_preserved') is True,'archived evidence')
    require(isinstance(record.get('pre_guard_product_sha256'),dict) and len(record['pre_guard_product_sha256'])==24 and MODULE+'Clr/Translator.cs' in record['pre_guard_product_sha256'],'required complete reuse projection')
    if check_files:
        for name,digest in sources.items():
            path=(ROOT/name).resolve()
            require(path.is_relative_to(ROOT.resolve()) and path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest()==digest,'source drift: '+name)
        expected={p.relative_to(ROOT).as_posix() for p in (ROOT/MODULE/'Clr').iterdir() if p.suffix in ('.cs','.csproj')}
        expected.update(p.relative_to(ROOT).as_posix() for p in (ROOT/MODULE/'Exchange/Core').glob('*.cs'))
        expected.add('Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs')
        original=record.get('pre_guard_product_sha256',{})
        require(set(original)==expected,'complete explain reuse projection')
        for name,digest in original.items():
            data=(ROOT/name).read_bytes()
            if name==MODULE+'Clr/Translator.cs':
                require(data.count(PROCEDURE_GUARD)==1,'single exact procedure guard')
                data=data.replace(PROCEDURE_GUARD,b'',1)
            require(hashlib.sha256(data).hexdigest()==digest,'changed explain branch: '+name)
    return record


if __name__=='__main__':
    from ssis_historical_scope import copy_column_v1_scope
    with copy_column_v1_scope(ROOT):
        validate()
    print('SSIS_COPY_COLUMN_COMPOSED_DELTA_PASS; no whole-module/fresh-ZIP/SSMS/TLS claim')
