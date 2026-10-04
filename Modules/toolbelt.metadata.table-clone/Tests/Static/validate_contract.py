"""Deterministische Source-/Lifecyclekopplung; kein Runtime-Nachweis."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
MOD = ROOT / 'Modules/toolbelt.metadata.table-clone'
public = (MOD / 'Source/USP_ScriptTableClone.sql').read_text(encoding='utf-8')
core = (MOD / 'Source/USP_ScriptTableCloneInternal.sql').read_text(encoding='utf-8')
deploy = (MOD / 'Deployment/Deploy.sql').read_text(encoding='utf-8')
uninstall = (MOD / 'Deployment/Uninstall.sql').read_text(encoding='utf-8')
params = [('SourceSchema','nvarchar(max)','NULL'),('SourceTable','nvarchar(max)','NULL'),
          ('TargetSchema','nvarchar(max)','NULL'),('TargetTable','nvarchar(max)','NULL'),
          ('IncludeIdentity','bit','0'),('IncludeExtendedProperties','bit','0'),('TableMap','sysname','NULL'),('ExternalReferenceRule','varchar(16)',"'REJECT'"),('IncludeTriggers','bit','0'),('ResultTable','sysname','NULL'),('KeepData','bit','0'),
          ('Debug','tinyint','0'),('Hilfe','bit','0')]
signature = public.split('AS\nBEGIN',1)[0]
actual = re.findall(r"@(\w+)\s+(nvarchar\(max\)|varchar\(16\)|sysname|bit|tinyint)\s*=\s*(NULL|0|'REJECT')",signature)
assert actual == params, 'signature/default contract'
core_signature = core.split('AS\nBEGIN', 1)[0]
assert re.findall(r"@(\w+)\s+(nvarchar\(max\)|varchar\(16\)|sysname|bit|tinyint)\s*=\s*(NULL|0|'REJECT')", core_signature) == params, 'internal/public signature coupling'
assert public.index('IF @Hilfe=1') < public.index("N'#tbx_TableClone_Plan'") < public.index('EXEC toolbelt_metadata.USP_ScriptTableCloneInternal\n')
assert 'EXEC sys.sp_executesql @TableDdl' not in core and 'EXEC sys.sp_executesql @IndexDdl' not in core
assert 'INSERT ... EXEC' not in core
for name in ['USP_ScriptTableClone','USP_ScriptTableCloneInternal']:
    assert f':r ../Source/{name}.sql' in deploy
    assert f"N'{name}'" in uninstall
assert "'IF', 'TF'" in deploy and "'IF', 'TF'" in uninstall
assert 'NOT EXISTS' in uninstall and 'referencing_id NOT IN' not in uninstall
for lifecycle in (deploy,uninstall):
    assert lifecycle.index('IF @@TRANCOUNT>0') < lifecycle.index('SET XACT_ABORT ON;')
    assert 'TBX_TABLE_CLONE_CALLER_TRANSACTION:' in lifecycle and 'RAISERROR' in lifecycle
assert "HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION')" in core
assert "N'1.1.0'" not in deploy+uninstall
for token in ['is_computed','is_sparse','temporal_type','ledger_type','has_filter','is_ansi_padded',
              'VIEW DEFINITION','HASHBYTES','WITHIN GROUP','SAVE TRANSACTION','53904','53906']:
    assert token in core, token
for path in ['README.md','module.yaml','Tests/Runtime/TableClone.Contract.sql','Tests/Runtime/Lifecycle.Contract.sql',
             'Tests/Runtime/Central.Contract.sql','Tests/Runtime/MinimumRights.Contract.sql','Tests/Runtime/SelectMetadata.Contract.ps1',
             'Documentation/USP_ScriptTableClone.md','Documentation/USP_ScriptTableCloneInternal.md']:
    assert (MOD/path).is_file(), path
assert not re.search(r'\b(?:THEN|ELSE|WHEN)\d',public+core)
print('TableClone static source/contract/lifecycle coupling PASS (no runtime evidence).')

assert core.index('Computed-Dependency-Metadatensicht') < core.index('sys.sql_expression_dependencies d')
assert "VALUES(@PlanStart+1,'TABLE'" in core
assert 'SET NUMERIC_ROUNDABORT OFF;' in core
assert 'PERSISTED' in core and 'EXTENDED_PROPERTY' in core
# Technische Predicate-Injektionen gegen beide echten Lifecycle-Gatepositionen.
# Keine tatsächliche eingeschränkte Sicherheitsidentität und kein SQL-Nachweis.
for lifecycle in (deploy, uninstall):
    gate_predicates = ["COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1",
        "COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1"]
    for predicate in gate_predicates:
        positions = [m.start() for m in re.finditer(re.escape(predicate), lifecycle)]
        assert len(positions) == 2
        assert positions[0] < lifecycle.index('sys.sql_expression_dependencies d') if 'sys.sql_expression_dependencies d' in lifecycle else positions[0] < lifecycle.index('FROM sys.sql_expression_dependencies')
        assert positions[1] > lifecycle.index('sys.sp_getapplock')
        for position in positions:
            for result in ('0', 'NULL'):
                injected = lifecycle[:position] + f'COALESCE({result},0)<>1' + lifecycle[position+len(predicate):]
                assert injected.count(predicate) == 1
                assert "vollständige Lifecycle-Dependency-Metadatensicht fehlt.',2" in injected
print('Lifecycle metadata gates: two passes / sixteen 0-NULL injection forms PASS (offline only).')
for lifecycle in (deploy,uninstall):
    assert 'CONVERT(varbinary(max),@CurrentInstalledVersion)<>CONVERT(varbinary(max),@InstalledVersion)' in lifecycle
    assert 'ISNULL(@CurrentInstalledVersion' not in lifecycle
    assert lifecycle.count("o.type<>'P'") == 2
assert 'CONVERT(varbinary(max),@SchemaCategory)=CONVERT(varbinary(max),N\'metadata\')' in uninstall
assert deploy.count('name IN(@VersionPropertyName,') == 2
# Optionale Level2-Metadaten müssen trotz ANSI_NULL_DFLT_OFF NULL zulassen.
owners = re.search(r'DECLARE @Owners TABLE\((.*?)\);', core, re.S).group(1)
owner_columns = re.findall(r'(\w+)\s+(?:int|sysname|nvarchar\(\d+\))\s+(NOT NULL|NULL)', owners)
assert owner_columns == [('Class','NOT NULL'),('MajorId','NOT NULL'),('MinorId','NOT NULL'),
    ('SortKind','NOT NULL'),('SourceOrdinal','NOT NULL'),('Level1Type','NOT NULL'),
    ('Level1Name','NOT NULL'),('Level2Type','NULL'),('Level2Name','NULL'),('TargetName','NOT NULL')]
datetime_literal = "WHEN @EpBase=N'datetime' THEN N'N'''+CONVERT(nvarchar(128),CONVERT(datetime,@EpValue),126)+N''''"
assert datetime_literal in core
assert core.index(datetime_literal) < core.index("WHEN @EpBase IN(N'date',N'time',N'datetime',N'smalldatetime',N'datetime2')")
assert "WHEN @EpBase=N'datetimeoffset' THEN N'N'''+CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),@EpValue),121)+N''''" in core
wave1 = (MOD/'Tests/Runtime/Wave1.Contract.sql').read_text(encoding='utf-8-sig')
assert 'CONVERT(nvarchar(20),e.value)' not in wave1
for expected_value in ("N'column'", 'expected.Name', "N'index'"):
    assert f'CONVERT(varbinary(max),e.value)=CONVERT(varbinary(max),{expected_value})' in wave1
assert "Property owner mapping differs.',10" in wave1
permission = (MOD/'Tests/Runtime/Wave1.PermissionPredicate.sql').read_text(encoding='utf-8-sig')
assert 'EXEC sys.sp_executesql @Original;' not in permission
assert 'SET @Changed=REPLACE(@AlterOriginal,@Needle' in permission
assert 'DATALENGTH(@Prefix)/2+1' in permission and 'STUFF(@Original,@HeaderPosition,DATALENGTH(@Header)/2' in permission
assert 'CREATE OR ALTER PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal' in permission
assert 'ALTER PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal' in permission
assert permission.index('SET XACT_ABORT OFF;') < permission.index('BEGIN TRANSACTION;')
assert '@@TRANCOUNT<>1 OR XACT_STATE()<>1' in permission
assert 'AND uses_ansi_nulls=@Ansi AND uses_quoted_identifier=@Quoted' in permission
assert "name=N'Toolbelt.SourceHash' AND value IS NOT NULL" in permission
assert permission.count('IF @OriginalXactAbort=1 SET XACT_ABORT ON; ELSE SET XACT_ABORT OFF;') == 2

# Separate DTO18-Regression; bestehende Wave1.Contract.sql bleibt unveraendert.
dto = (MOD/'Tests/Runtime/Wave1.DateTimeOffset.sql').read_text(encoding='utf-8')
dto_rows = re.findall(r"INSERT @DtoCases VALUES\(N'([^']+)',([037]),[0-9]+,[0-9]+,CONVERT\(sql_variant,CONVERT\(datetimeoffset\(([037])\),N'2001-02-03T12:34:56\.([0-9]{7})([+-][0-9]{2}:[0-9]{2})'\)\)\);", dto)
assert len(dto_rows) == 18 and len({r[0] for r in dto_rows}) == 18
assert all(r[1] == r[2] for r in dto_rows)
assert {(r[1],r[3],r[4]) for r in dto_rows} == {(p,f,o) for p in ('0','3','7') for f in ('1234567','9999999') for o in ('+00:00','+05:30','-12:34')}
assert dto.count('EXEC toolbelt_metadata.USP_ScriptTableClone ') == 1
assert '@IncludeExtendedProperties=1' in dto and 'WITHIN GROUP(ORDER BY Ordinal)' in dto
assert dto.count('EXCEPT SELECT') == 4
for field in ('BaseType','Precision','Scale','MaxLength','Collation'):
    assert dto.lower().count("sql_variant_property(value,'" + field.lower() + "')") >= 8
assert 'ExpectedSecond' in dto and 'ExpectedNanosecond' in dto
assert 'COUNT(DISTINCT CONVERT(varbinary(256),Name))' in dto
assert 'COUNT(*) FROM #Wave1DtoPlan)<>26' in dto and "Ordinal=8 AND ObjectKind='TABLE'" in dto
assert 'wave1_datetimeoffset: "Tests/Runtime/Wave1.DateTimeOffset.sql"' in (MOD/'module.yaml').read_text(encoding='utf-8')

# V3-Sourcekopplung und Regelvektoren; keine Engine-/FK-Katalognachweise.
assert len(params)==13 and params[6:9]==[('TableMap','sysname','NULL'),('ExternalReferenceRule','varchar(16)',"'REJECT'"),('IncludeTriggers','bit','0')]
assert public.index('IF @Hilfe=1') < public.index("N'#tbx_TableClone_Map'")
for name in ('Map','Order','Names','EpOwners'):
    assert "N'#tbx_TableClone_"+name+"'" in public
assert 'CREATE TABLE #tbx_TableClone_Map' in core and 'INSERT #tbx_TableClone_Map SELECT MapOrdinal,SourceSchema,SourceTable,TargetSchema,TargetTable,NULL,NULL' in core
assert core.count('INSERT #tbx_TableClone_Map SELECT MapOrdinal')==1  # sole input snapshot; no later caller-map read
assert '@MapId=@ResultId' in core and 'GROUP BY SourceId HAVING COUNT_BIG(*)>1' in core
assert 'GROUP BY TargetSchemaId,TargetTable HAVING COUNT_BIG(*)>1' in core
assert '(f.is_disabled=1 AND f.is_not_trusted=0)' in core
assert 'f.key_index_id' in core and 'k.key_ordinal>0' in core
assert 'c.constraint_column_id' in core and 'FOREIGN_KEY_STATE' in core
assert core.index('CLOSE RenderCursor;') < core.index('DECLARE PropertyCursor') < core.index('DECLARE ForeignKeyCursor') < core.index('DECLARE @DependencyVersion')
assert core.count('DECLARE @ColumnDdl')==1 and core.count('DECLARE PropertyCursor')==1
assert core.count('CREATE TABLE #tbx_TableClone_Plan')==1
# Countvertrag an die zwei Katalogmengen gekoppelt; keine Python-SQL-Nachbildung als Runtime-Nachweis.
assert 'COUNT_BIG(*) FROM sys.objects o JOIN #tbx_TableClone_Map m ON m.SourceId=o.parent_object_id' in core
assert 'COUNT_BIG(*) FROM sys.foreign_key_columns c JOIN #tbx_TableClone_Map m ON m.SourceId=c.parent_object_id' in core
assert core.index('globale Objekt-/FK-Spaltentupelquote') < core.index('DECLARE @ColumnDdl')
for version in ('1.0.0','2.0.0','3.0.0'):
    assert "CONVERT(varbinary(max),N'"+version+"')" in deploy+uninstall
for fixture in ('Wave2.Contract.sql','Wave2.Safety.sql','Wave2.Caps.sql'):
    assert (MOD/'Tests/Runtime'/fixture).is_file()
print('W2 V3/map/FK/order/count source coupling PASS; SQL/roundtrip not executed.')

lifecycle_fixture=(MOD/'Tests/Runtime/Lifecycle.Contract.sql').read_text(encoding='utf-8')
assert "(7,N'@TableMap',N'sysname',256),(8,N'@ExternalReferenceRule',N'varchar',16)" in lifecycle_fixture
assert "(9,N'@IncludeTriggers',N'bit',1)" in lifecycle_fixture
assert "(13,N'@Hilfe',N'bit',1)" in lifecycle_fixture
assert lifecycle_fixture.count("<>13") == 2

# Beide Pässe erhalten aufgelöste Consumer und katalogäquivalente unaufgelöste sameDB-Namen.
for lifecycle in (deploy,uninstall):
    assert lifecycle.count('referenced_id IS NULL AND') == 2
    assert lifecycle.count('referenced_server_name IS NULL') == 2
    assert lifecycle.count('referenced_database_name COLLATE DATABASE_DEFAULT=DB_NAME() COLLATE DATABASE_DEFAULT') == 2
    assert lifecycle.count("referenced_schema_name COLLATE DATABASE_DEFAULT=N'toolbelt_metadata' COLLATE DATABASE_DEFAULT") == 2
    assert lifecycle.count("referenced_entity_name COLLATE DATABASE_DEFAULT IN(N'USP_ScriptTableClone',N'USP_ScriptTableCloneInternal',N'USP_ExecuteTableClone')") == 2
caps=(MOD/'Tests/Runtime/Wave2.Caps.sql').read_text(encoding='utf-8')
for witness in ('@c<=1024','@i<=2045',"ObjectKind='CHECK')<>2045","ObjectKind='PRIMARY_KEY')<>1","ObjectKind='FOREIGN_KEY')<>1",'@Number<>53906','@State<>1','CK_SyntheticW2Count2046'):
    assert witness in caps
assert caps.count('EXCEPT SELECT * FROM')==2
assert 'ADR-2026-10-04-TABLE-CLONE-W2' not in (ROOT/'Documentation/Architecture/DECISIONS.md').read_text(encoding='utf-8')
print('W2 consumer/count fixture source coupling PASS; no SQL execution.')

# Additiver Executor3.1: öffentliche Vertragskopplung, kein Engine-Nachweis.
execute=(MOD/'Source/USP_ExecuteTableClone.sql').read_text(encoding='utf-8')
execute_signature=execute.split('AS\nBEGIN',1)[0]
execute_actual=re.findall(r"@(\w+)\s+(nvarchar\(max\)|varbinary\(max\)|varchar\(16\)|sysname|bit|tinyint)\s*=\s*(NULL|0|'REJECT'|'CREATE')",execute_signature)
assert execute_actual == params[:8]+[('ExpectedPlanHash','varbinary(max)','NULL'),('ForeignKeyMode','varchar(16)',"'CREATE'")]+params[9:]
assert execute.index('IF @Hilfe=1') < execute.index('IF @@TRANCOUNT>0') < execute.index('CREATE TABLE #TableCloneExecute_MapStage')
assert 'INSERT ... EXEC' not in execute and 'INSERT EXEC' not in execute.upper()
assert execute.count('EXEC toolbelt_metadata.USP_ScriptTableClone ') == 2
assert '@TableMap=NULL,@ResultTable=' in execute and "@TableMap=N'#TableCloneExecute_MapStage'" in execute
assert execute.count("OBJECT_ID(N'tempdb..'+@TableMap,N'U')") == 1
assert 'DATALENGTH(@ExpectedPlanHash)<>32' in execute
for literal in ('Toolbelt.TableClone.Execute.Hash','Toolbelt.TableClone.Execute.Final','VIEW ANY DEFINITION',
    'sys.server_event_notifications','sys.server_trigger_events','sys.event_notifications','sys.trigger_events',
    'DEFAULT/CHECK/Computed','SECONDARY_ROLLBACK'):
    assert literal in execute,literal
assert execute.count('EXEC sys.sp_executesql @SafetySql,') == 2
assert "ObjectKind NOT IN('FOREIGN_KEY','FOREIGN_KEY_STATE')" in execute
assert 'SET @Script=@SetPrefix+@Script;' in execute
for option in ('ANSI_NULLS ON','ANSI_PADDING ON','ANSI_WARNINGS ON','ARITHABORT ON',
    'CONCAT_NULL_YIELDS_NULL ON','QUOTED_IDENTIFIER ON','NUMERIC_ROUNDABORT OFF'):
    assert f'SET {option};' in execute
assert execute.index('EXEC toolbelt_core.USP_PrepareResultTable') < execute.index('COMMIT TRANSACTION;')
for version in ('1.0.0','2.0.0','3.0.0','3.1.0','4.0.0'):
    assert f"CONVERT(varbinary(max),N'{version}')" in deploy+uninstall
assert ':r ../Source/USP_ExecuteTableClone.sql' in deploy
assert "VALUES(N'USP_ExecuteTableClone');" in uninstall
assert uninstall.index("INSERT INTO @ReleaseObjects (ObjectName) VALUES(N'USP_ExecuteTableClone');") < uninstall.index("VALUES(N'USP_ScriptTableClone'),(N'USP_ScriptTableCloneInternal');",uninstall.index('DECLARE @ReleaseObjects TABLE'))
for fixture in ('Execute.Contract.sql','Execute.Safety.sql'):
    assert (MOD/'Tests/Runtime'/fixture).is_file()
assert "SET @Text=N'4.0.0';" in execute
assert "frame('4.0.0')" in (MOD/'Examples/CalculatePlanHash.py').read_text(encoding='utf-8')
assert '@IncludeTriggers' not in execute_signature
print('Executor14 / Hash-v1 mit Release4.0 / triggerfreie Grenze gekoppelt; keine SQL-Ausführung.')

# Gemeinsame Namespacegrenze schützt auch alle neu eingeführten AST-Temps.
for temp in re.findall(r'CREATE TABLE\s+(#tbx_\w+)', core, re.IGNORECASE):
    assert f"N'{temp}'" in public, f'caller collision guard missing: {temp}'
assert 'EXEC sys.sp_executesql @TrScript' not in core
for fixture in ('Trigger.Contract.sql', 'Trigger.Safety.sql'):
    assert (MOD/'Tests/Runtime'/fixture).is_file()
assert 'required_when: "Runtime: IncludeTriggers = 1' in (MOD/'module.yaml').read_text(encoding='utf-8')
print('Trigger13 / interne Signatur / AST-Tempgrenze / opt-in Dependency gekoppelt; keine SQL-Ausführung.')
