"""Prove unchanged business paths apart from declared SQL assembly aliases.

This transition check permits reuse of component evidence, never acceptance of
new deployment code, exact install packages or new Skill/help outputs. Exact
reviewed passive Skill comments, constant help SELECTs and explicitly generated
trailing default-0 help parameters/early guards are checked separately and removed
for comparison. This proves the old default-call path only, not the new signature
or help execution. Every remaining byte stays bound; business changes need new
qualification.
"""
from pathlib import Path
import io
import re
import subprocess
import tarfile

ROOT=Path(__file__).resolve().parents[2]
BASELINE='2fbe8e3e86f370b22ad2ce9f9716d971072a052b'
ALIASES={
    'Toolbelt_Archive_ZipMemory':'tlblt_Archive_ZipMemory',
    'Toolbelt_File_CsvMemory':'tlblt_File_CsvMemory',
    'Toolbelt_File_XlsxMemory':'tlblt_File_XlsxMemory',
    'Toolbelt_Filesystem_Windows':'tlblt_Filesystem_Windows',
    'Toolbelt_JsonConstructors':'tlblt_JsonConstructors',
    'Toolbelt_JsonCore':'tlblt_JsonCore',
    'Toolbelt_JsonSchema':'tlblt_JsonSchema',
    'Toolbelt_String_EditDistance':'tlblt_String_EditDistance',
    'Toolbelt_String_Phonetic':'tlblt_String_Phonetic',
    'Toolbelt_String_Regex':'tlblt_String_Regex',
}
EVENT_HELP_PATH='Modules/toolbelt.core.event-log/Source/USP_WriteEventInternal.sql'
EVENT_HELP_OLD=(b"N'EXEC toolbelt_core.USP_WriteEvent @EventName=''Contoso.HelpExample'',"
                b"@EventLevel=''INFO'',@Message=N''Synthetic example'';'")
EVENT_HELP_NEW=EVENT_HELP_OLD.replace(b'Contoso.HelpExample',b'contoso.helpexample')
SCHEMA_HELP_PATH='Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql'
SCHEMA_HELP_OLD=("Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.").encode('utf-8')
SCHEMA_HELP_NEW=("1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Argument-/Namespace-/Helper-/CLR-/Fachprüfung oder Zielmutation. 0 oder NULL: Fachpfad. Alle SQL-Argumente besitzen technische Defaults.").encode('utf-8')
WORKER_CONFIG_HELP_PATHS={
    'Modules/toolbelt.core.worker-control/Source/'+name+'.sql'
    for name in ('USP_EnableManagedWorkers','USP_DisableManagedWorkers','USP_SetWorkerConcurrency','USP_SetWorkerIntervals',
                 'USP_RegisterWorker','USP_HeartbeatWorker','USP_SetWorkerCapacity','USP_SetWorkerState')}
WORKER_CONFIG_HELP_NEW=("1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig.").encode('utf-8')


def corrected_historical_help(original,path):
    if path in WORKER_CONFIG_HELP_PATHS and SCHEMA_HELP_OLD in original:
        start=b' IF ISNULL(@Hilfe,0)=1 BEGIN\n'
        end=b'        RETURN 0;'
        if original.count(start)!=1 or original.count(SCHEMA_HELP_OLD)!=1:
            raise ValueError('NONCANONICAL_WORKER_CONFIG_HELP_DESCRIPTION')
        a=original.index(start)+len(start)
        b=original.find(end,a)
        if b<0 or original[a:b].count(SCHEMA_HELP_OLD)!=1:
            raise ValueError('NONCANONICAL_WORKER_CONFIG_HELP_DESCRIPTION')
        original=original[:a]+original[a:b].replace(SCHEMA_HELP_OLD,WORKER_CONFIG_HELP_NEW)+original[b:]
    # This exact description correction belongs only to the existing early
    # Schema help branch. New help is not upgraded to historical runtime proof.
    if path==SCHEMA_HELP_PATH and SCHEMA_HELP_OLD in original:
        start=b' IF @Hilfe=1\n BEGIN\n'
        end=b'        RETURN 0;'
        if original.count(start)!=1 or original.count(SCHEMA_HELP_OLD)!=1:
            raise ValueError('NONCANONICAL_SCHEMA_HELP_DESCRIPTION')
        a=original.index(start)+len(start)
        b=original.find(end,a)
        if b<0 or original[a:b].count(SCHEMA_HELP_OLD)!=1:
            raise ValueError('NONCANONICAL_SCHEMA_HELP_DESCRIPTION')
        original=original[:a]+original[a:b].replace(SCHEMA_HELP_OLD,SCHEMA_HELP_NEW)+original[b:]
    # Admit this one invalid lowercase-name example only in the original early
    # help branch. Never normalize current SQL or a business literal. The new
    # help remains a separate contract, not historical runtime qualification.
    if path!=EVENT_HELP_PATH or EVENT_HELP_OLD not in original:
        return original
    start=b'    IF ISNULL(@Hilfe, 0) = 1\n    BEGIN\n'
    end=b'        RETURN 0;\n    END;'
    if original.count(start)!=1 or original.count(EVENT_HELP_OLD)!=1:
        raise ValueError('NONCANONICAL_EVENT_HELP_EXAMPLE')
    a=original.index(start)+len(start)
    b=original.find(end,a)
    if b<0 or original[a:b].count(EVENT_HELP_OLD)!=1:
        raise ValueError('NONCANONICAL_EVENT_HELP_EXAMPLE')
    return original[:a]+original[a:b].replace(EVENT_HELP_OLD,EVENT_HELP_NEW)+original[b:]


def selected(path):
    return path.startswith('Modules/') and ('/Source/' in path or '/Clr/' in path or '/Exchange/Core/' in path) and path.endswith(('.sql','.cs','.csproj'))


def compare(original,current,path):
    original=original.replace(b'\r\n',b'\n');current=current.replace(b'\r\n',b'\n')
    original=corrected_historical_help(original,path)
    if '/Source/' in path:
        for old,new in ALIASES.items():
            # Only the SQL assembly token may change; never a CLR class name,
            # dynamic SQL body or general string value with similar spelling.
            pattern=rb'(\bEXTERNAL\s+NAME\s+\[)'+re.escape(old.encode())+rb'(\])'
            original=re.sub(pattern,lambda m:m[1]+new.encode()+m[2],original,flags=re.I)
            original=re.sub(rb'(?m)^[ \t]*--[^\n]*',lambda m:m[0].replace(old.encode(),new.encode()),original)
            original=re.sub(rb'/\*.*?\*/',lambda m:m[0].replace(old.encode(),new.encode()),original,flags=re.S)
    if original!=current: raise ValueError('COMPONENT_REUSE_NOT_PROVEN: '+path)


def verify(root=ROOT,baseline=BASELINE,module_ids=None):
    scopes=['Modules/'+name for name in module_ids] if module_ids else ['Modules']
    raw=subprocess.check_output(['git','archive','--format=tar',baseline,*scopes],cwd=root,timeout=120)
    originals={}
    with tarfile.open(fileobj=io.BytesIO(raw),mode='r:') as archive:
        for member in archive:
            if member.isfile() and selected(member.name): originals[member.name]=archive.extractfile(member).read()
    actual={p.relative_to(root).as_posix() for p in (root/'Modules').glob('*/Source/**/*.sql')}
    actual.update(p.relative_to(root).as_posix() for p in (root/'Modules').glob('*/Clr/**/*')
                  if p.is_file() and p.suffix in ('.cs','.csproj') and not {'bin','obj'} & set(p.parts))
    actual.update(p.relative_to(root).as_posix() for p in (root/'Modules').glob('*/Exchange/Core/*.cs'))
    if module_ids: actual={p for p in actual if p.split('/')[1] in module_ids}
    generated='Modules/toolbelt.filesystem.windows/Clr/UsageSkillsGenerated.cs'
    fs_records=None
    if generated in actual:
        import sys
        sys.path.insert(0,str(root/'Scripts/Metadata'))
        import clr_usage_skills
        fs_records=clr_usage_skills.module_records(root,'toolbelt.filesystem.windows')
        clr_usage_skills.generate(root,'toolbelt.filesystem.windows','Toolbelt.Filesystem.Windows',root/generated,check=True)
        actual.remove(generated)
    projection='Modules/toolbelt.metadata.capability-catalog/Source/VW_ModuleCapabilities.sql'
    if projection in actual:
        # The known-object inventory is a current generated metadata surface,
        # not an unchanged component qualified by the original native receipts.
        import importlib.util
        import sys
        sys.path.insert(0,str(root/'Scripts/Install'))
        spec=importlib.util.spec_from_file_location('capability_projection',root/'Scripts/Install/New-MarkerlessCapabilities.py')
        generator=importlib.util.module_from_spec(spec);spec.loader.exec_module(generator)
        if (root/projection).read_text(encoding='utf-8-sig')!=generator.render(root):
            raise ValueError('CURRENT_CAPABILITY_PROJECTION_NOT_CANONICAL')
        actual.remove(projection)
        originals.pop(projection)
    if actual!=set(originals):raise ValueError('COMPONENT_REUSE_SOURCE_INVENTORY_CHANGED')
    # New passive Skill comments are a separate current projection. Admit only
    # exact, reviewed source-mapped Markdown and its canonical help projections;
    # retain strict comparison of every other byte. Never normalize arbitrary
    # comments, arbitrary help SQL or CLR changes.
    import sys
    sys.path.insert(0,str(root/'Scripts/Metadata'))
    import usage_skills
    for path,data in originals.items():
        current=(root/path).read_bytes()
        if fs_records is not None and path=='Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs':
            # Only exact new optional parameter/first help instruction pairs
            # are removed. Fresh binaries/new help still need current proof.
            current=clr_usage_skills.strip_provider_help(current.decode('utf-8').replace('\r\n','\n'),fs_records).encode('utf-8')
        if fs_records is not None and path=='Modules/toolbelt.filesystem.windows/Clr/Toolbelt.Filesystem.Windows.csproj':
            text=current.decode('utf-8').replace('\r\n','\n')
            item='    <Compile Include="UsageSkillsGenerated.cs" />\n'
            if text.count(item)!=1: raise ValueError('CURRENT_CLR_SKILL_COMPILE_ITEM_NOT_CANONICAL')
            current=text.replace(item,'',1).encode('utf-8')
        if '/Source/' in path and usage_skills.DDL_BEGIN.encode() in current:
            text=current.decode('utf-8')
            text=usage_skills.strip_clr_sql_help(root,path,text)
            text=usage_skills.strip_missing_help_projection(root,path,text)
            text=usage_skills.strip_help_projection(root,path,text)
            current=usage_skills.strip_ddl_projection(root,path,text).encode('utf-8')
        compare(data,current,path)
    return len(originals)


if __name__=='__main__':
    print('COMPONENT_SOURCE_REUSE_PROVEN files='+str(verify())+'; new skill/help/deployment/package qualification separate; no SQL executed')
