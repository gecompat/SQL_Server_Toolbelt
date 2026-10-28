"""Erzeugt API-/Help-Bindings aus genau einer kanonischen Modulbeschreibung."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def literal(value):
    if value is None: return "NULL"
    if isinstance(value, (bool, int)): return str(int(value))
    return "N'" + value.replace("'", "''") + "'"


def generate():
    api = json.loads((ROOT / "Contracts/Api.json").read_text(encoding="utf-8"))
    v2 = json.loads((ROOT / "Contracts/ComponentsV2.json").read_text(encoding="utf-8"))
    # V2 is a strict help overlay: it can add profile prose/examples but cannot
    # change the public parameter sequence or ResultTable column contract.
    if v2.keys() != {"schemaVersion", "contract", "baseContract", "operation", "bindingProfile", "projectContext", "catalogBindings", "help"}:
        raise ValueError("COMPONENTS_V2_OVERLAY_SHAPE")
    if v2["baseContract"] != "Contracts/Api.json" or v2["contract"] != "ssis-debug-components-v2":
        raise ValueError("COMPONENTS_V2_OVERLAY_BASE")
    for item in v2["help"]:
        if item.get("section") not in {"DESCRIPTION", "EXAMPLE", "LIMITATION"} or not isinstance(item.get("ordinal"), int) or not isinstance(item.get("description"), str):
            raise ValueError("COMPONENTS_V2_OVERLAY_HELP")
        if item["section"] == "EXAMPLE" and not isinstance(item.get("exampleSql"), str):
            raise ValueError("COMPONENTS_V2_OVERLAY_EXAMPLE")
        if item["section"] != "EXAMPLE" and "exampleSql" in item:
            raise ValueError("COMPONENTS_V2_OVERLAY_EXAMPLE")
    if v2["operation"] != "bindings-template-v2" or v2["bindingProfile"] != "ssis-debug-components-v2":
        raise ValueError("COMPONENTS_V2_OVERLAY_PROFILE")
    rows = [("DESCRIPTION", 1, None, None, None, None, None, api["description"], None)]
    for i, p in enumerate(api["parameters"], 1): rows.append(("PARAMETER", i, p["name"], p["type"], p["required"], p["nullable"], p["default"], p["description"], None))
    for i, c in enumerate(api["columns"], 1): rows.append(("RESULT_COLUMN", i, c["name"], c["type"], True, c["nullable"], None, c["description"], None))
    for entry in v2["help"]: rows.append((entry["section"], entry["ordinal"], None, None, None, None, None, entry["description"], entry.get("exampleSql")))
    rows += [("EXAMPLE", 1, None, None, None, None, None, "Reine Hilfe ohne Paket oder Katalogprüfung.", "EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;"),
             ("PERMISSION", 1, None, None, None, None, None, "CALLER; EXECUTE und vollständige Katalogsicht der ausdrücklich erlaubten Datenbanken. Keine Rechtevergabe.", None),
             ("LIMITATION", 1, None, None, None, None, None, "Windows SQL Server 2019/2022/2025; UNSAFE/ScriptDom. NOLOCK erlaubt Dirty Reads und garantiert keine Sperrfreiheit. Keine Ausführung von Paket-SQL.", None)]
    values = ",\n".join("(" + ",".join(map(literal, row)) + ")" for row in rows)
    help_sql = """SELECT CONVERT(varchar(16),'1.0') AS HelpContractVersion,
 CONVERT(sysname,N'toolbelt_tsql') AS SchemaName,CONVERT(sysname,@helpObjectName) AS ObjectName,
 CONVERT(varchar(32),v.Section) AS Section,CONVERT(int,v.Ordinal) AS Ordinal,
 CONVERT(sysname,v.ItemName) AS ItemName,CONVERT(varchar(256),v.SqlDataType) AS SqlDataType,
 CONVERT(bit,v.IsRequired) AS IsRequired,CONVERT(bit,v.IsNullable) AS IsNullable,
 CONVERT(nvarchar(4000),v.DefaultValue) AS DefaultValue,CONVERT(nvarchar(max),v.Description) AS Description,
 CONVERT(nvarchar(max),v.ExampleSql) AS ExampleSql
FROM (VALUES
""" + values + "\n) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)\nORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 WHEN 'PERMISSION' THEN 4 ELSE 5 END,v.Ordinal;"
    signature = ",\n".join("    " + p["name"] + " " + p["type"] + " = " + ("NULL" if p["default"] == "NULL" else literal(p["default"]) if p["type"].startswith("varchar") else p["default"]) for p in api["parameters"])
    header = """-- ============================================================================
-- Generiert durch Scripts/New-ContractSources.py aus Contracts/Api.json.
-- Objekt: toolbelt_tsql.USP_ExplainSsisDataFlow{suffix}; {kind}.
-- Zweck: DTSX2 erklären, JSON-Vorlage und lesende CTE-Debugskripte erzeugen.
-- Vertrag: SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md; USP_CONTRACT1.0; Version1.0.0.
-- Parameter/Resultset: vollständig in Contracts/Api.json und @Hilfe=1.
-- V2-Ergänzungen: schema-validiertes Contracts/ComponentsV2.json Help-Overlay.
-- Dependencies: Parser exakt2.0.1 mit gepinntem ScriptDom; ResultTable>=1.0.0.
-- Rechte: CALLER, EXECUTE; explizite Same-instance-Katalogvollsicht.
-- Plattform: Windows SQL Server2019/2022/2025 CL150/160/170; UNSAFE.
-- Fehler:50000/TBX_SSISDBG_; keine fachliche Teilresultatausgabe bei globalem Fehler.
-- Performance: endliches Import-/AST-/Katalog-/Ausgabebudget; kein harter Watchdog.
-- Grenzen: kein Datei-/Netzzugriff, kein SSIS-/Paket-SQL-Execute, keine Ziel-DML.
-- NOLOCK: mögliche Dirty-/Missing-/Duplicate-Reads und verbleibende Schemasperren.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
"""
    call = ",\n".join("        " + p["name"] + "=" + p["name"] for p in api["parameters"])
    public = header.format(suffix="", kind="öffentliche T-SQL-Fassade") + "CREATE OR ALTER PROCEDURE toolbelt_tsql.USP_ExplainSsisDataFlow\n" + signature + "\nAS\nBEGIN\n    SET NOCOUNT ON;\n    IF @Hilfe=1\n    BEGIN\n        DECLARE @helpObjectName sysname=N'USP_ExplainSsisDataFlow';\n" + help_sql + "\n        RETURN;\n    END;\n    -- Nur im Prozedurscope: neutrale Vertragsfehler dürfen eine gesunde\n    -- Callertransaktion nicht durch geerbtes XACT_ABORT ON doomen. SQL Server\n    -- stellt die geerbte SET-Option beim Verlassen dieses Scopes wieder her.\n    SET XACT_ABORT OFF;\n    BEGIN TRY\n        -- SQL CLR kann in einer bereits doomed Transaktion vor dem C#-Preflight\n        -- mit3930 scheitern. Deshalb den Vertragsfehler hier vorziehen.\n        IF XACT_STATE()=-1 THROW 50000,N'TBX_SSISDBG_unresolved_binding: Callertransaktion ist nicht schreibfähig.',1;\n        EXEC toolbelt_tsql.USP_ExplainSsisDataFlowInternal\n" + call + ";\n    END TRY\n    BEGIN CATCH\n        DECLARE @message nvarchar(4000)=ERROR_MESSAGE(),@start int,@stop int,@safe nvarchar(2048);\n        SET @start=CHARINDEX(N'TBX_SSISDBG_',@message);\n        IF @start>0\n        BEGIN\n            SET @stop=CHARINDEX(NCHAR(10),@message,@start);\n            SET @safe=SUBSTRING(@message,@start,CASE WHEN @stop>@start THEN @stop-@start ELSE 2048 END);\n        END\n        ELSE SET @safe=N'TBX_SSISDBG_sql_error: SQL-/CLR-Fehler '+CONVERT(nvarchar(12),ERROR_NUMBER())+N', State '+CONVERT(nvarchar(12),ERROR_STATE())+N'. Keine Ausgabe vertraulicher Fehlerpayloads.';\n        THROW 50000,@safe,1;\n    END CATCH;\nEND;\nGO\n"
    # SqlString hat am SQL-CLR-Einstieg ausschließlich eine Unicodebindung.
    # Die öffentliche T-SQL-Signatur bleibt unverändert; die Fassade konvertiert.
    # SQL CLR erlaubt bei LOB-Parametern auch kein DEFAULT NULL. Die Fassade
    # übergibt stets alle Argumente einschließlich expliziter NULLs.
    internal_signature = ",\n".join("    " + p["name"] + " " + ("n" + p["type"] if p["type"].startswith("varchar(") else p["type"]) + ("" if "(max)" in p["type"] else " = " + ("NULL" if p["default"] == "NULL" else literal(p["default"]) if p["type"].startswith("varchar") else p["default"])) for p in api["parameters"])
    internal = header.format(suffix="Internal", kind="interne CLR-USP mit Unicodebindung und gleichem Standardtail") + "CREATE OR ALTER PROCEDURE toolbelt_tsql.USP_ExplainSsisDataFlowInternal\n" + internal_signature + "\nAS EXTERNAL NAME [Toolbelt_Tsql_SsisDebug].[Toolbelt.Tsql.SsisDebug.SsisDebugProvider].[ExplainSsisDataFlow];\nGO\n"
    internal_help_sql = help_sql.replace("CONVERT(varchar(256),v.SqlDataType) AS SqlDataType", "CONVERT(varchar(256),CASE WHEN v.Section='PARAMETER' AND v.SqlDataType LIKE 'varchar(%' THEN 'n'+v.SqlDataType ELSE v.SqlDataType END) AS SqlDataType")
    internal_help_sql = internal_help_sql.replace("CONVERT(bit,v.IsRequired)", "CONVERT(bit,CASE WHEN v.Section='PARAMETER' AND v.SqlDataType IN('nvarchar(max)','varbinary(max)') THEN 1 ELSE v.IsRequired END)").replace("CONVERT(nvarchar(4000),v.DefaultValue)", "CONVERT(nvarchar(4000),CASE WHEN v.Section='PARAMETER' AND v.SqlDataType IN('nvarchar(max)','varbinary(max)') THEN NULL ELSE v.DefaultValue END)")
    columns = ",".join("[" + c["name"] + "]" for c in api["columns"])
    shape = ",".join("[" + c["name"] + "] " + c["type"] + (" COLLATE Latin1_General_100_BIN2" if "char" in c["type"] else "") + (" NULL" if c["nullable"] else " NOT NULL") for c in api["columns"])
    json_shape = ",".join("[" + c["name"] + "] " + c["type"] for c in api["columns"])
    fields = []
    for c in api["columns"]:
        expression = "[" + c["name"] + "]"
        # Ein als nvarchar(max) gecasteter Ersatzwert bleibt für SQL Server
        # nullable. Das direkte Literal erhält sowohl den ersten Datentyp
        # als auch die zugesicherte NOT-NULL-Clientmetadatenkennzeichnung.
        if not c["nullable"]: expression = "ISNULL(" + expression + "," + ("N''" if "char" in c["type"] else "CAST(0 AS " + c["type"] + ")") + ")"
        if "char" in c["type"]: expression += " COLLATE Latin1_General_100_BIN2"
        fields.append(expression + " AS [" + c["name"] + "]")
    select = "SELECT " + ",".join(fields) + " FROM OPENJSON(@rows) WITH (" + json_shape + ")"
    constants = {"Sql": internal_help_sql, "Columns": columns, "Shape": shape, "Select": select}
    cs = "// Generiert aus Contracts/Api.json; nicht manuell parallel pflegen.\nnamespace Toolbelt.Tsql.SsisDebug\n{\n    internal static class HelpContract\n    {\n" + "\n".join('        internal const string ' + name + ' = @"' + value.replace('"', '""') + '";' for name, value in constants.items()) + "\n    }\n}\n"
    files = {"Source/USP_ExplainSsisDataFlow.sql": public, "Source/USP_ExplainSsisDataFlowInternal.sql": internal, "Clr/HelpContract.Generated.cs": cs}
    for file, text in files.items():
        path = ROOT / file; path.parent.mkdir(parents=True, exist_ok=True); path.write_text(text, encoding="utf-8", newline="\n")


if __name__ == "__main__": generate()
