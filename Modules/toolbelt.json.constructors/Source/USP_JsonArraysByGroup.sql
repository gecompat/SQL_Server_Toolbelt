-- ============================================================================
-- Objekt: toolbelt_json.USP_JsonArraysByGroup; Typ: Stored Procedure
-- Zweck: Begrenzte JSON-Konstruktion aus caller-lokaler #Temp mit expliziten Kinds.
-- Vertrag: Documentation/USP_JsonArraysByGroup.md; USP_CONTRACT 1.0
-- Parameter: EntriesTable sysname; positive MaxEntries/MaxTotalValueBytes/MaxResultBytes
-- Resultset: GroupOrdinal int NOT NULL; JsonValue nvarchar(max) NOT NULL, eine Zeile je vorhandener Gruppe.
-- Dependencies: toolbelt.core.result-table >=1.0.0 same_database
-- Rechte: EXECUTE; eigene lokale Temps; keine Rechteausweitung.
-- Versionen: SQL Server 2019/2022/2025, Compatibility >=150; Windows/Linux.
-- Fehler: 53600-53610; vollständige Prüfung vor Zielmutation, Originalenginefehler.
-- Performance: begrenzter Snapshot, Fragmente und geordnete LOB-Aggregation.
-- Grenzen: keine Inferenz/PrettyPrint/Aggregate/Patch; kein unbegrenzter Aufruf.
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_json.USP_JsonArraysByGroup
 @EntriesTable sysname=NULL,
 @MaxEntries int=10000,
 @MaxTotalValueBytes bigint=2097152,
 @MaxResultBytes bigint=2097152,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0),@Hilfe=COALESCE(@Hilfe,0);
 IF @Hilfe=1
 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_json' AS sysname) AS SchemaName,
            CAST(N'USP_JsonArraysByGroup' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'JSON-Array aus GroupOrdinal/Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'GroupOrdinal', N'int', 1, 0, NULL, CAST(N'Positive Gruppenordinal, Lücken erlaubt; SELECT sortiert danach.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'JsonValue', N'nvarchar(max)', 1, 0, NULL, CAST(N'Ein JSON-Wert je Gruppe, BIN2; leere Eingabe erzeugt null Zeilen.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'53600-53610', NULL, NULL, NULL, NULL, CAST(N'Parameter/Schema/Ordinal/Key/Kind/NULL/Unicode/Literal/Ressourcen/Dependency; Enginefehler unverändert.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE und lokale Temp-Sicht; ResultTable-Pfad zusätzlich Helper-EXECUTE.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Nur string/number/boolean/null/json; json ist vollständiges Objekt/Array, kein Scalar. Keine Typinferenz.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Caller-Eingabe wird nicht mutiert.' AS nvarchar(max)), CAST(N'CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max)); EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N''#Entries'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@EntriesTable', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich GroupOrdinal int, positiv/nicht NULL; Ordinals und Keys müssen nur innerhalb dieser Gruppe eindeutig sein. Ausgabe nach GroupOrdinal; leere Tabelle ergibt keine Gruppenzeilen. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@MaxEntries', N'int', 0, 0, N'10000', CAST(N'Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxTotalValueBytes', N'bigint', 0, 0, N'2097152', CAST(N'Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxResultBytes', N'bigint', 0, 0, N'2097152', CAST(N'Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei >0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 -- Diese Sicherheitsgrenze liegt vor Core-Compilation: ein Callerobjekt im
 -- reservierten Namespace kann sonst interne #Temp-Metadaten eclipsen und
 -- schon beim Compile statt des Vertragsfehlers einen Enginefehler auslösen.
 IF LEFT(LOWER(@EntriesTable COLLATE Latin1_General_100_BIN2),5) COLLATE Latin1_General_100_BIN2=N'#tbx_'
 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructor_Input',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructor_Fragments',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructor_Units',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructor_Result',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructor_GroupResult',N'U') IS NOT NULL
 THROW 53601,N'JSON: reservierter interner Temp-Namespace ist im Caller belegt.',5;
 EXEC toolbelt_json.USP_JsonConstructInternal @ObjectMode=0,@EntriesTable=@EntriesTable,@MaxEntries=@MaxEntries,
 @MaxTotalValueBytes=@MaxTotalValueBytes,@MaxResultBytes=@MaxResultBytes,@GroupMode=1,@ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
END;
GO
