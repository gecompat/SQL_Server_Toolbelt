"""ZIP2-Sourcekopplung; keine SQL-, CLR- oder Filesystemausführung."""
from pathlib import Path
import re,json
ROOT=Path(__file__).resolve().parents[4]
MODULE=ROOT/"Modules/toolbelt.archive.zip-files"
def require(ok,message):
    if not ok: raise AssertionError(message)
expected=json.loads((MODULE/"Tests/Static/ExpectedSignatures.json").read_text(encoding="utf-8"))
bridges=["#ZipFiles_CreateStage","#ZipFiles_ExtractStage","#ZipFiles_WriteStage"]
for name,params in expected.items():
    source=(MODULE/"Source"/(name+".sql")).read_text(encoding="utf-8")
    signature=source.split("CREATE OR ALTER PROCEDURE",1)[1].split("\nAS\n",1)[0]
    actual=[{"name":p,"type":t.lower().replace(" ",""),"default":d.strip()} for p,t,d in re.findall(r"(@\w+)\s+([\w]+(?:\([^)]*\))?)\s*=\s*([^\n,]+)",signature)]
    require(actual==params,name+": exact signature/defaults")
    require(not re.search(r"INSERT\s+[^;]*?\bEXEC(?:UTE)?\b",source,re.I),name+": no INSERT EXEC")
    require("N'"+name+"',v.Section" in source and "N'NAME'" not in source,name+": exact Help object")
    help_at=source.index("IF @Hilfe=1")
    tx_at=source.index("IF @@TRANCOUNT<>0")
    zip_at=source.index("EXEC toolbelt_archive.",tx_at)
    fs_at=source.index("EXEC toolbelt_filesystem.USP_WriteBinaryFile")
    begin_at=source.index("BEGIN TRANSACTION;")
    prepare_at=source.index("EXEC toolbelt_core.USP_PrepareResultTable")
    insert_at=source.index("EXEC sys.sp_executesql @Sql")
    commit_at=source.index("COMMIT TRANSACTION;")
    require(help_at<tx_at<zip_at<fs_at<begin_at<prepare_at<insert_at<commit_at,name+": priority and late SQL TX")
    for bridge in bridges:
        require("OBJECT_ID(N'tempdb.."+bridge+"',N'U') IS NOT NULL" in source,name+": guard "+bridge)
        require(bridge.lower() in source,name+": caller reference rejection "+bridge)
    require("CONVERT(bigint,DATALENGTH(@Payload))" in source,name+": actual write length")
    require("IF @ResultTable IS NULL SELECT BytesWritten,RootAlias,RelativePath,State" in source,name+": one resultshape")
    require("TBX_ZIP_FILE_SECONDARY_SQL_ROLLBACK_FAILED" in source and "THROW;" in source,name+": primary error preserved")
    require("ISNULL(@Overwrite" not in source and "ISNULL(@ExecutionIdentity" not in source,name+": identity/overwrite unchanged")
    require("d.ModuleId<>N'toolbelt.filesystem.windows' AND NOT EXISTS" in source,name+": bestehende FS-Markerform")
    require("d.ModuleId=N'toolbelt.core.result-table' AND NOT EXISTS" in source,name+": Objektmodus nur Core")
    if "Extract" in name:
        require("@FailIfEncrypted=1" in source and "IsEncrypted<>0" in source and "EntryPayload IS NULL" in source,name+": encrypted/null fail closed")
        require("UncompressedBytes<>CONVERT(bigint,DATALENGTH(EntryPayload))" in source,name+": payload length")
    else:
        for p in ["CompressionMethod","MaxEntries","MaxEntryNameCodeUnits","MaxEntryBytes","MaxTotalPayloadBytes","MaxArchiveBytes","MaxEnvelopeBytes","WriterBudgetMilliseconds"]:
            require("@"+p+"=@"+p in source,name+": inherited parameter "+p)
for filename in ["Deploy.sql","Uninstall.sql"]:
    source=(MODULE/"Deployment"/filename).read_text(encoding="utf-8")
    for token in ["WHILE @Pass<=2","VIEW DEFINITION","sys.sql_expression_dependencies","sys.sp_getapplock","LockOwner=N'Transaction'","CONVERT(varbinary(2),CONVERT(char(2),'P'))","@Present<>2","sys.dm_os_host_info"]:
        require(token in source,filename+": lifecycle "+token)
    alias_at=source.index("o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT")
    require(source.index("WHILE @Pass<=2")<alias_at<source.index("SET @Present=")<source.index("BEGIN TRANSACTION;"),filename+": Aliasgate in beiden Durchläufen vor Mutation")
    require("WHERE CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name)" in source,filename+": bekannte Slotnamen bleiben bytegenau")
    if filename=="Uninstall.sql":
        for token in ["d.referenced_id=o.object_id","d.referenced_server_name IS NULL","d.referenced_database_name COLLATE DATABASE_DEFAULT=DB_NAME() COLLATE DATABASE_DEFAULT","d.referenced_schema_name COLLATE DATABASE_DEFAULT=N'toolbelt_archive' COLLATE DATABASE_DEFAULT","d.referenced_entity_name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT"]:
            require(token in source,filename+": katalogäquivalente lokale Consumer "+token)
    code=re.sub(r"--[^\n]*","",source)
    require(not re.search(r"\b(?:GRANT|CREATE ASSEMBLY|ALTER ASSEMBLY|DROP ASSEMBLY|RECONFIGURE|ALTER AUTHORIZATION)\b",code,re.I),filename+": no rights/provider/config mutation")
    require("DROP SCHEMA" not in code,filename+": dependency schema retained")
require((MODULE/"Source").glob is not None,"source path")
require(len(list((MODULE/"Source").glob("*.sql")))==2,"exactly two persistent P sources")
naming=(ROOT/"Documentation/Standards/SQL_OBJECT_NAMING.md").read_text(encoding="utf-8")
require(all(x in naming for x in bridges),"specific three-bridge naming exception")
# Adversarial pure guard vectors: no namespace adoption.
def bridge_allowed(name): return name.lower() not in {x.lower() for x in bridges}
require(not bridge_allowed("#ZIPFILES_WRITESTAGE") and not bridge_allowed("#ZipFiles_CreateStage") and bridge_allowed("#Result"),"bridge vectors")
print("PASS ZIP_FILES_SOURCE_CONTRACT (source-only; no native execution)")

# Die feste Dependencyrolle verlangt nur vorhandene Writer-/Core-Objektmarker.
for file in ['Source/USP_CreateZipFileFromEntries.sql','Source/USP_ExtractZipEntryToFile.sql','Deployment/Deploy.sql']:
    text=(MODULE/file).read_text(encoding='utf-8')
    require('RequireObjectMarkers bit NOT NULL' in text,file+': explizite feste Markerrolle')
    for name,version,flag in [('USP_CreateZipFromEntries','1,4,0',1),('USP_ExtractZipEntryFromBinary','1,4,0',0),('USP_WriteBinaryFile','1,0,0',0),('USP_PrepareResultTable','1,0,0',1)]:
        require("N'"+name+"',"+version+','+str(flag)+')' in text,file+': Markerrolle '+name)
    require(text.count('d.RequireObjectMarkers=1 AND NOT EXISTS')==2,file+': Modul-/Versionsobjektmarker geschlossen')
    require("e.class=0 AND e.major_id=0 AND e.minor_id=0" in text and 'n.Major<d.MinimumMajor' in text,file+': DB-Version/Minimum erhalten')
safety=(MODULE/'Tests/Runtime/ZipFiles.Safety.sql').read_text(encoding='utf-8')
require("@level1name=N'USP_CreateZipFromEntries'" in safety and "@value=N'0.0.0'" in safety,'Writer-Markermanipulation bleibt negative Fixture')
zipdeploy=(ROOT/'Modules/toolbelt.archive.zip-memory/Deployment/Deploy.sql').read_text(encoding='utf-8')
writer=zipdeploy.split('DECLARE WriterMarkers CURSOR',1)[1].split('OPEN WriterMarkers',1)[0]
require("N'USP_CreateZipFromEntries'" in writer and "N'USP_ExtractZipEntryFromBinary'" not in writer,'vorhandene ZIP1.4-Legacy-Markerform')
print('PASS ZIP_FILES_DEPENDENCY_MARKER_ROLES (nur Sourcekopplung)')
