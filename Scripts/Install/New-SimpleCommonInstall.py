"""Erzeugt einen gemeinsamen create-only-Funktionsinstaller ohne SQLCMD/Marker."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import re
import subprocess
import zipfile
from markerless_manifest import scalar, section, objects, dependencies, list_values, unquote

ROOT=Path(__file__).resolve().parents[2]
BASELINE='Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Maintenance.zip'
BASELINE_SHA256='e3753ce8c1e1a7af7dd573837104c2b9ff7552cc90565069f106a6fe9c2193a1'
CONSTRUCTOR_DELIVERY='Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Current-Install.zip'
CONSTRUCTOR_DELIVERY_SHA256='5a425e740cc9a4b3af6b6a4df74b66a7c5deb6fe13af39e889b282f784a29823'
WINDOWS_ONLY={'toolbelt.archive.zip-files','toolbelt.filesystem.windows','toolbelt.tsql.script-parser','toolbelt.tsql.ssis-debug'}
LOCAL_ONLY={'toolbelt.archive.zip-files','toolbelt.filesystem.windows'}
# Diese klassischen Deployments betten generierte CREATE-Payloads ein statt
# Source-Dateien per :r zu laden. Im gemeinsamen Weg die kanonischen TVFs
# direkt aufnehmen; Preflight/Release-Marker bleiben außerhalb dieses Wegs.
INLINE_SOURCE_MODULES={'toolbelt.conversion.safe-cast','toolbelt.json.pointer'}
SKIP={'Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql',
      'Modules/toolbelt.file.content/Source/FileContentRootPredicate.sql'}
TABLE_GROUPS={
    'toolbelt.core.event-log/EventLog.sql','toolbelt.core.execution-cancel/ExecutionCancellation.sql',
    'toolbelt.core.second-session/SecondSessionProvider.sql','toolbelt.core.work-queue/WorkItem.sql',
    'toolbelt.core.work-queue/WorkQueueManagedGate.sql','toolbelt.core.work-type/WorkType.sql',
    'toolbelt.core.work-type/WorkTypePermission.sql','toolbelt.core.worker-control/WorkerControlTables.sql',
    'toolbelt.file.content/FileContentRootAllowlist.sql','toolbelt.filesystem.windows/FileSystemRoot.sql',
}
CONDITIONAL_ROUTINES={'toolbelt.json.constructors/JsonAggregates.sql',
                      'toolbelt.json.constructors/JsonEntryEvaluate.sql',
                      'toolbelt.json.schema/JsonSchemaBridge.sql'}


def require(value, message):
    if not value: raise ValueError('SIMPLE_COMMON: '+message)


def sha(data, algorithm='sha256'):
    return hashlib.new(algorithm,data).hexdigest()


def literal(text):
    return "N'"+text.replace("'","''")+"'"


def normalize(data):
    return data.replace(b'\r\n',b'\n')


def load_script(name, path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    return module


caps=load_script('markerless_capabilities',ROOT/'Scripts/Install/New-MarkerlessCapabilities.py')


def modules(platform, mode):
    available={}
    for path in sorted((ROOT/'Modules').glob('*/module.yaml')):
        text=path.read_text(encoding='utf-8-sig');module=scalar(text,'module_id')
        require(module==path.parent.name,'manifest identity')
        available[module]={'id':module,'text':text,'schemas':list_values(text,'schemas'),
                           'dependencies':dependencies(text),'objects':objects(text)}
    selected={key:value for key,value in available.items()
              if not (platform=='Portable' and key in WINDOWS_ONLY) and not (mode=='central' and key in LOCAL_ONLY)}
    if platform=='Portable':
        clone=selected['toolbelt.metadata.table-clone']
        expected='required_when: "Runtime: IncludeTriggers = 1 auf Windows; IncludeTriggers = 0 und Moduldeployment benötigen den Parser nicht."'
        require(expected in section(clone['text'],'dependencies'),'conditional parser contract drift')
        # Nur diese dokumentierte Windows-Laufzeitoption ist beim portablen
        # Deployment keine Pflichtabhängigkeit. Keine allgemeine Textheuristik.
        clone['dependencies']=[d for d in clone['dependencies'] if d!='toolbelt.tsql.script-parser']
    ordered=[];pending=set(selected)
    while pending:
        ready=sorted(m for m in pending if set(selected[m]['dependencies'])<=set(ordered))
        require(ready,'missing dependency or cycle')
        ordered.extend(ready);pending.difference_update(ready)
    return [selected[m] for m in ordered]


def assembly_permission(text):
    """Den vorhandenen Modulvertrag verwenden; keinen PermissionSet raten."""
    values=re.findall(r'^  permission_set:[ \t]*([^\r\n]+)',section(text,'clr'),re.M)
    require(len(values)==1,'assembly permission declaration')
    value=unquote(values[0])
    require(value in ('SAFE','EXTERNAL_ACCESS','UNSAFE'),'assembly permission value')
    return value


def binary_inputs(inputs):
    """Originale Binärbytes nur bei unveränderten Compilerquellen wiederverwenden."""
    prefix='SQL-Server-Toolbelt-1.0.0-CLR-Install/'
    replaced={'toolbelt.json.constructors','toolbelt.tsql.script-parser','toolbelt.tsql.ssis-debug'}
    require(sha((ROOT/BASELINE).read_bytes())==BASELINE_SHA256,'baseline package identity')
    with zipfile.ZipFile(ROOT/BASELINE) as archive:
        metadata=json.loads(archive.read(prefix+'CLR-PACKAGE.json'))
        data={}
        for item in metadata['artifacts']:
            payload=archive.read(prefix+'Binaries/'+item['file'])
            require(sha(payload,'sha512')==item['sha512'].lower(),'baseline binary drift')
            data[item['file']]=payload
        compiler_count=0
        for name in archive.namelist():
            if not name.startswith(prefix+'Sources/'): continue
            relative=name[len(prefix+'Sources/'):]
            parts=Path(relative).parts
            if '/Clr/' in relative and relative.endswith(('.cs','.csproj')) and parts[1] not in replaced:
                require(normalize(archive.read(name))==normalize((ROOT/relative).read_bytes()),'compiler drift: '+relative)
                compiler_count+=1
        require(compiler_count>0,'baseline compiler inventory')
    registry=json.loads((ROOT/'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json').read_bytes())
    ctor=next(a['Fields'] for a in registry['artifacts'] if a['Fields']['moduleId']=='toolbelt.json.constructors')
    if (inputs/'Toolbelt.JsonConstructors.dll').exists():
        payload=(inputs/'Toolbelt.JsonConstructors.dll').read_bytes()
    else:
        # Bekannte unveränderte Compilerbytes aus der erhaltenen Lieferung
        # wiederverwenden; kein Download, Umbau oder neuer Qualifikationsanspruch.
        delivery=ROOT/CONSTRUCTOR_DELIVERY
        require(sha(delivery.read_bytes())==CONSTRUCTOR_DELIVERY_SHA256,'constructor delivery identity')
        with zipfile.ZipFile(delivery) as archive:
            sql=archive.read('Install-Portable-local.sql')
        candidates=(bytes.fromhex(m[1].decode()) for m in re.finditer(rb'0x(4[dD]5[aA][0-9a-fA-F]{512,})',sql))
        matching=[b for b in candidates if sha(b,'sha512')==ctor['binarySha512']]
        require(len(matching)==1,'constructor delivery binary')
        payload=matching[0]
    require(sha(payload)==ctor['binarySha256'] and sha(payload,'sha512')==ctor['binarySha512'],'constructor binary')
    require(sha((ROOT/'Modules/toolbelt.json.constructors/Clr/Toolbelt.JsonConstructors.csproj').read_bytes())==ctor['projectSha256'],'constructor project')
    for name,expected in ctor.items():
        if name.startswith('source/'):
            require(sha((ROOT/'Modules/toolbelt.json.constructors/Clr'/name[7:]).read_bytes())==expected,'constructor source')
    data['Toolbelt.JsonConstructors.dll']=payload
    parser=json.loads((inputs/'parser/Toolbelt.Tsql.ScriptParser.trust-manifest.json').read_bytes())
    parser_payload=(inputs/'parser/Toolbelt.Tsql.ScriptParser.dll').read_bytes()
    dom=(inputs/'parser/tlblt.Microsoft.SqlServer.TransactSql.ScriptDom.dll').read_bytes()
    require(sha(parser_payload,'sha512').upper()==parser['sha512']=='F849CE8E6018EB7B7F547E3C8FF7FEF45DEE85E57E45D90D197CA07E3A997B184BFF437EB0295D378EB1996DB158283ADD057A5C04F3F23C4DC0BD82C98DB123','current reproduced parser binary')
    require(sha(dom,'sha512').upper()=='634EBA3C4D7AB7EBEA4B59C68C3B0C78081686F54359595B8206EADE989BFC51D02A91DAB4CA23065854C1624E93A2B4C2216AB6AA7DF9CA191541BF0F795813','private dependency')
    inventory={p.resolve() for p in (ROOT/'Modules/toolbelt.tsql.script-parser/Clr').rglob('*')
               if p.suffix in ('.cs','.csproj') and not {'bin','obj'}&set(p.parts)}
    declared=set()
    for entry in parser['sourceFiles']:
        name,expected=entry.rsplit(':',1);path=(ROOT/'Modules/toolbelt.tsql.script-parser'/name).resolve()
        require(path.is_relative_to(ROOT) and sha(path.read_bytes()).upper()==expected,'parser source')
        declared.add(path)
    require(declared==inventory,'parser compiler inventory')
    ssis=load_script('simple_ssis_install',ROOT/'Modules/toolbelt.tsql.ssis-debug/Scripts/New-SimpleInstall.py')
    # Dessen strikte Zulassung bindet sämtliche SSIS-Compiler-/Facadequellen,
    # reproduzierten Build und die private ScriptDom-Abhängigkeit.
    ssis.render(inputs/'ssis',inputs/'parser/tlblt.Microsoft.SqlServer.TransactSql.ScriptDom.dll','hash')
    data['Toolbelt.Tsql.ScriptParser.dll']=parser_payload
    data['Toolbelt.Tsql.SsisDebug.dll']=(inputs/'ssis/Toolbelt.Tsql.SsisDebug.dll').read_bytes()
    data['Microsoft.SqlServer.TransactSql.ScriptDom.dll']=dom
    return metadata['artifacts'],data


def source_files(selected):
    files=[];seen=set();hashes={}
    def visit(path,stack):
        path=path.resolve(strict=True)
        require(path.is_relative_to(ROOT) and not path.is_symlink(),'source boundary')
        require(path not in stack and len(stack)<32,'include cycle/depth')
        relative=path.relative_to(ROOT).as_posix()
        payload=path.read_bytes();hashes[relative]=sha(normalize(payload))
        text=payload.decode('utf-8-sig')
        for match in re.finditer(r'^\s*:r\s+([^\r\n]+)',text,re.M):
            visit(path.parent/match[1].strip().strip('\"\''),[*stack,path])
        if '/Source/' in relative and relative not in seen and relative not in SKIP:
            files.append((relative,path));seen.add(relative)
    for module in selected:
        directory=ROOT/'Modules'/module['id']
        visit(directory/'Deployment/Deploy.sql',[])
        if module['id'] in INLINE_SOURCE_MODULES:
            for obj in objects(module['text']):
                require(obj['type']=='TVF' and re.fullmatch(r'TVF_[A-Za-z0-9_]+',obj['name']),
                        'inline source contract')
                visit(directory/'Source'/(obj['name']+'.sql'),[])
        require(any(path.startswith('Modules/'+module['id']+'/') for path,_ in files)
                or scalar(section(module['text'],'clr'),'  used')=='true',
                'module without executable source: '+module['id'])
    def expand(path,stack=()):
        require(path not in stack and len(stack)<32,'source include cycle')
        text=path.read_text(encoding='utf-8-sig')
        def include(match):
            child=(path.parent/match[1].strip().strip('\"\'')).resolve(strict=True)
            require(child.is_relative_to(ROOT) and not child.is_symlink(),'source include boundary')
            return expand(child,(*stack,path))
        return re.sub(r'^\s*:r\s+([^\r\n]+)',include,text,flags=re.M)
    return [{'path':relative,'sql':expand(path)} for relative,path in files],hashes


def emit_sources(parsed, alias):
    output=[]
    for source in parsed:
        path=source['path'];parts=Path(path).parts;key=parts[1]+'/'+parts[-1]
        statements=[s for s in source['statements'] if s['kind']!='PredicateSetStatement']
        def rewrite(text):
            for old,new in alias.items():
                text=text.replace('['+old+']','['+new+']').replace("N'"+old+"'","N'"+new+"'")
            return text
        output.append('-- Quelle: '+path+'\n')
        if key in TABLE_GROUPS:
            # Diese historischen Dateien enthalten auch Migrationen/Indexpflege.
            # Ihre Gesamtfolge darf ausschließlich frisch eigene Tabellen ändern.
            text='\n'.join(s['sql'] for s in statements)
            names=sorted(set('.'.join(x.replace('[','').replace(']','').split('.')) for x in
                             re.findall(r'CREATE TABLE\s+((?:\[?toolbelt_\w+\]?\.)\[?\w+\]?)',text,re.I)))
            require(names,'table group without table')
            count=' + '.join("CASE WHEN OBJECT_ID("+literal(name)+",N'U') IS NULL THEN 0 ELSE 1 END" for name in names)
            output.append('IF ('+count+') NOT IN(0,'+str(len(names))+') THROW 51000,N\'Unvollständige bestehende Tabellengruppe; kein automatisches Upgrade.\',1;\n')
            output.append('IF ('+count+')=0\nBEGIN\n')
            for statement in statements:
                output.append('EXEC sys.sp_executesql '+literal(rewrite(statement['sql']))+';\n')
            if key=='toolbelt.core.work-type/WorkType.sql': output.append('SET @NewWorkType=1;\n')
            output.append('END;\n')
            continue
        for statement in statements:
            kind=statement['kind'];text=rewrite(statement['sql'])
            if kind.startswith('Create') and statement['name']:
                text=re.sub(r'^CREATE OR ALTER\b','CREATE',text,flags=re.I)
                flags={'toolbelt_core.USP_RegisterWorkType':'@NewRegistrar','toolbelt_core.USP_WriteEventInternal':'@NewEventHandler'}
                action='EXEC sys.sp_executesql '+literal(text)+';'
                if statement['name'] in flags: action+=' SET '+flags[statement['name']]+'=1;'
                output.append('IF OBJECT_ID('+literal(statement['name'])+') IS NULL BEGIN '+action+' END;\n')
            elif kind=='IfStatement' and key in CONDITIONAL_ROUTINES:
                require('DROP ' not in text.upper() and 'ALTER ' not in text.upper(),'conditional routine mutation')
                output.append('EXEC sys.sp_executesql '+literal(text)+';\n')
            elif key=='toolbelt.archive.zip-memory/TVF_InternalExtractZipEntryClr.sql' and kind=='IfStatement':
                require('DROP FUNCTION' in text,'unexpected ZIP preparation')
                # Der separat erstellte CREATE-Slot erhält einen Existenzguard.
            else: raise ValueError('SIMPLE_COMMON: unhandled source statement '+path+'/'+kind)
    return ''.join(output)


def build(inputs,work,output,platform,mode,trust):
    require(not output.exists() and not Path(str(output)+'.manifest.json').exists(),'new output required')
    require(work.is_relative_to(ROOT/'.runtime') and not work.exists(),'new private work directory required')
    selected=modules(platform,mode)
    artifacts,binaries=binary_inputs(inputs)
    sources,hashes=source_files(selected)
    require((ROOT/caps.TARGET).read_text(encoding='utf-8-sig')==caps.render(),'capability projection drift')
    alias={a['sql_name']:caps.assembly_name(a['sql_name']) for a in artifacts}
    work.mkdir(parents=True)
    input_file=work/'source-inputs.json';parsed_file=work/'source-statements.json'
    input_file.write_text(json.dumps(sources,ensure_ascii=False),encoding='utf-8')
    command=['pwsh','-NoProfile','-NonInteractive','-File',str(ROOT/'Scripts/Install/Export-MarkerlessSource.ps1'),
             '-InputFile',str(input_file),'-OutputFile',str(parsed_file),'-ScriptDomDllPath',str(inputs/'parser/tlblt.Microsoft.SqlServer.TransactSql.ScriptDom.dll')]
    result=subprocess.run(command,capture_output=True,timeout=120)
    (work/'parse.private.log').write_bytes(result.stdout+result.stderr)
    require(result.returncode==0,'offline source parsing failed; inspect private log')
    parsed=json.loads(parsed_file.read_bytes())
    used_schemas={statement['name'].split('.')[0] for source in parsed
                  for statement in source['statements'] if statement['name']}
    require(used_schemas<={schema for module in selected for schema in module['schemas']},'source schema unbound')
    body=emit_sources(parsed,alias)
    require(not re.search(r'Toolbelt\.(?:Module|Managed|Visibility|DeploymentMode|AssemblySha512|ArtifactId)',body),'runtime marker remains')
    for source in sources:
        if 'extended_properties' in source['sql'] or 'sp_addextendedproperty' in source['sql']:
            require(source['path']=='Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableCloneInternal.sql','unexpected Extended Property usage')
            # Fachliches Kopieren von Quelltabellen-Eigenschaften ist ein
            # ausdrücklich vorhandener Table-Clone-Vertrag, keine Installation.
    prefix='''USE [ContosoToolbelt];
/* Gemeinsamer Funktionsinstaller: nur USE anpassen, als normale SQL-Abfrage ausführen.
Keine SQLCMD-Direktiven, Installationsmarker, Deploymentlogs oder Rechtevergabe.
Die Datenbank und CLR-Konfiguration müssen vorhanden sein. Domain-Tabellen der
gewählten Module gehören zur Funktionalität, nicht zu einer Deploymentregistry.
Kein Upgrade/Uninstall, keine Änderung bestehender Objekte oder Fremdassemblies.
Bei Teilfehlern bleiben zuvor erstellte Objekte bestehen. Enginefehler bleiben erhalten.
auto nutzt bereits TRUSTWORTHY ON, andernfalls die exakten Hashfreigaben.
trustworthy-checked vergleicht Binaries ohne Hashregistrierung; trustworthy
nutzt vorhandenen DB-Trust ohne Toolbelt-Hashprüfung. Kein Fallback oder Einschalten
von TRUSTWORTHY, CLR oder Abschalten von Strict Security. Vorhandene Rechte gelten.
*/
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
DECLARE @NewWorkType bit=0,@NewRegistrar bit=0,@NewEventHandler bit=0;
DECLARE @TrustMethod varchar(24)='''+literal(trust)+''';
IF @TrustMethod='auto' SET @TrustMethod=CASE WHEN EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND is_trustworthy_on=1) THEN 'trustworthy' ELSE 'hash' END;
IF @TrustMethod IN('trustworthy','trustworthy-checked') AND NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND is_trustworthy_on=1)
 THROW 51000,N'Gewählter Weg verlangt vorhandenes TRUSTWORTHY ON; keine automatische Aktivierung.',1;
BEGIN TRY
'''
    for license_file in ('LICENSE.md','Modules/toolbelt.tsql.ssis-debug/InstallPackages/ThirdParty/ScriptDom-180.117.0/LICENSE','Modules/toolbelt.string.phonetic/ThirdParty/ApacheCommonsCodec/LICENSE.txt','Modules/toolbelt.string.phonetic/ThirdParty/ApacheCommonsCodec/NOTICE.txt'):
        text=(ROOT/license_file).read_text(encoding='utf-8-sig')
        require('*/' not in text,'license comment boundary')
        prefix+='/* '+license_file+'\n'+text+'\n*/\n'
    for schema in sorted({s for module in selected for s in module['schemas']}):
        prefix+='IF SCHEMA_ID('+literal(schema)+') IS NULL EXEC sys.sp_executesql '+literal('CREATE SCHEMA ['+schema+'];')+';\n'
    selected_ids={m['id'] for m in selected}
    chosen=[a for a in artifacts if a['module_id'] in selected_ids or (a['module_id'] is None and platform=='Windows')]
    chosen.sort(key=lambda a:(0 if a['module_id'] is None else 1 if a['module_id']=='toolbelt.json.core' else 2,a['sql_name']))
    for index,item in enumerate(chosen):
        data=binaries[item['file']];digest=sha(data,'sha512').upper();name=alias[item['sql_name']]
        permission='UNSAFE' if item['module_id'] is None else assembly_permission((ROOT/'Modules'/item['module_id']/'module.yaml').read_text(encoding='utf-8-sig'))
        variable='@bits'+str(index)
        prefix+='DECLARE '+variable+' varbinary(max)=0x'+data.hex().upper()+';\n'
        prefix+="IF @TrustMethod IN('hash','trustworthy-checked') BEGIN\n IF HASHBYTES('SHA2_512',"+variable+')<>0x'+digest+" THROW 51000,N'Assemblybinary abweichend.',1;\n"
        prefix+=' IF EXISTS(SELECT 1 FROM sys.assemblies WHERE name='+literal(name)+') AND NOT EXISTS(SELECT 1 FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name='+literal(name)+" AND HASHBYTES('SHA2_512',f.content)=0x"+digest+") THROW 51000,N'Vorhandene Assembly abweichend oder nicht prüfbar; kein Upgrade.',1; END;\n"
        trust_sql='IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x'+digest+') EXEC master.sys.sp_add_trusted_assembly @hash=0x'+digest+',@description='+literal('Toolbelt '+name)+';'
        prefix+="IF @TrustMethod='hash' EXEC sys.sp_executesql "+literal(trust_sql)+';\n'
        prefix+='IF NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE name='+literal(name)+') BEGIN DECLARE @ddl'+str(index)+' nvarchar(max)='+literal('CREATE ASSEMBLY ['+name+'] FROM ')+"+CONVERT(nvarchar(max),"+variable+",1)+"+literal(' WITH PERMISSION_SET='+permission+';')+'; EXEC sys.sp_executesql @ddl'+str(index)+'; END;\n'
    tail=''
    if 'toolbelt.core.event-log' in selected_ids:
        # Nur fehlenden fachlichen WorkType registrieren; keinen bestehenden
        # Handler umleiten/reaktivieren. Keine Deployment-/Versionszeile.
        tail="""IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write')
BEGIN
 IF @NewWorkType<>1 OR @NewRegistrar<>1 OR @NewEventHandler<>1
  THROW 51000,N'Fehlender Event-WorkType bei bestehenden Objekten; keine automatische Änderung oder fremder Prozeduraufruf.',1;
 EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='toolbelt.event-log.write',@HandlerSchema=N'toolbelt_core',
 @HandlerProcedure=N'USP_WriteEventInternal',@ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object"}',
 @DefaultTimeoutSeconds=30,@IsIdempotent=0,@Description=N'Interner Handler für Toolbelt-Events.',@AllowUpdate=0,@Reactivate=0;
END;
"""
    if tail:
        # Erst nach dynamischem CREATE kompilieren; keine statische Bindung an
        # die vor Laufbeginn noch nicht vorhandene fachliche Tabelle.
        tail='EXEC sys.sp_executesql '+literal(tail)+','+literal('@NewWorkType bit,@NewRegistrar bit,@NewEventHandler bit')+',@NewWorkType=@NewWorkType,@NewRegistrar=@NewRegistrar,@NewEventHandler=@NewEventHandler;\n'
    content=prefix+body+tail+'END TRY\nBEGIN CATCH THROW; END CATCH;\n'
    require(not re.search(r'^\s*(?:GO\s*$|:\w|GRANT\b|REVOKE\b|DENY\b|RECONFIGURE\b)',content,re.M|re.I),'forbidden installer control')
    for path in (ROOT/'Modules').glob('*/Clr/**/*'):
        if path.suffix in ('.cs','.csproj') and not {'bin','obj'}&set(path.parts):
            hashes[path.relative_to(ROOT).as_posix()]=sha(normalize(path.read_bytes()))
    for path in (ROOT/'Scripts/Install').glob('*'):
        if path.suffix in ('.py','.ps1'): hashes[path.relative_to(ROOT).as_posix()]=sha(normalize(path.read_bytes()))
    for path in (ROOT/'Modules').glob('*/module.yaml'):
        hashes[path.relative_to(ROOT).as_posix()]=sha(normalize(path.read_bytes()))
    output.parent.mkdir(parents=True,exist_ok=True);output.write_text(content,encoding='utf-8',newline='\n')
    record={'schema':'toolbelt-markerless-install/v1','platform':platform,'mode':mode,'trust':trust,
            'modules':[m['id'] for m in selected],'source_sha256':hashes,'sql_sha256':sha(output.read_bytes()),
            'binary_sha512':{alias[a['sql_name']]:sha(binaries[a['file']],'sha512') for a in chosen},
            'native_qualification':'not executed','publication_authorized':False}
    Path(str(output)+'.manifest.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
    return record


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--inputs',type=Path,required=True)
    parser.add_argument('--work',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--platform',choices=('Windows','Portable'),default='Windows')
    parser.add_argument('--mode',choices=('local','central'),default='local')
    parser.add_argument('--trust-mode',choices=('auto','hash','trustworthy-checked','trustworthy'),default='auto')
    args=parser.parse_args()
    build(args.inputs.resolve(),args.work.resolve(),args.output.resolve(),args.platform,args.mode,args.trust_mode)
