"""Laufzeitabhängigkeiten über tatsächliche Objekte statt Installationsmarker."""


def dependency_sql():
    # Hashfreigabe ist eine wählbare Installationsentscheidung. Die Runtime
    # verlangt unabhängig davon die konkrete Helper-Schnittstelle und die vier
    # echten CLR-Parserfunktionen; keine selbst vergebenen Versionslabels.
    return """IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL
 OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable'))<>5
 OR EXISTS(SELECT 1 FROM (VALUES
  (N'@ResultTableToAlter',231,256),(N'@LikeTable',231,1552),
  (N'@KeepData',104,1),(N'@Debug',48,1),(N'@Hilfe',104,1)) AS expected(name,typeid,bytes)
  WHERE NOT EXISTS(SELECT 1 FROM sys.parameters AS p WITH(NOLOCK)
   WHERE p.object_id=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable')
    AND p.name=expected.name AND p.system_type_id=expected.typeid
    AND p.max_length=expected.bytes AND p.is_output=0))
 OR EXISTS(SELECT 1 FROM (VALUES(N'TVF_ParseScriptNodes'),(N'TVF_ParseScriptNodeProperties'),(N'TVF_TokenizeScript'),(N'TVF_ParseScriptErrors')) AS expected(name)
  WHERE NOT EXISTS(SELECT 1 FROM sys.assembly_modules AS m WITH(NOLOCK)
   JOIN sys.objects AS o WITH(NOLOCK) ON o.object_id=m.object_id
   JOIN sys.assemblies AS a WITH(NOLOCK) ON a.assembly_id=m.assembly_id
   WHERE o.schema_id=SCHEMA_ID(N'toolbelt_tsql') AND o.name=expected.name
    AND o.type=N'FT' AND a.name=N'tlblt_Tsql_ScriptParser' AND a.permission_set=3))
 THROW 50000,N'TBX_SSISDBG_unresolved_dependency: Parserfunktionen oder ResultTable-Schnittstelle fehlen oder sind abweichend.',1;"""
