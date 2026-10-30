-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.USP_DeterministicLookup
-- Typ:             Stored Procedure
-- Vertrag:         Documentation/USP_DeterministicLookup.md; USP_CONTRACT 1.0.
-- Zweck:           Synthetischer, versionierter Ersatzwert aus geordnetem Pool.
-- Parameter:       Caller-#Temps InputTable/LookupTable; MappingVersion int,
--                  Seed bigint, LookupVersion bigint; positive Ressourcenlimits.
-- Standard:        ResultTable, KeepData, Debug, Hilfe gemäß USP_CONTRACT 1.0.
-- Resultset:       InputOrdinal bigint NOT NULL, LookupOrdinal bigint NULL,
--                  Value nvarchar(max) Latin1_General_100_BIN2 NULL.
-- Dependencies:    interner Range-Kern; core.result-table >=1.0.0 same_database.
-- Rechte:          EXECUTE; ResultTable-Pfad zusätzlich Helper-EXECUTE.
-- Versionen:       SQL Server 2019/2022/2025, Windows/Linux; CL >=150.
-- Plattformen:     Windows und Linux, portabler T-SQL-Kern.
-- Fehlerverhalten: 54000..54009; Enginefehler unverändert; keine Teilzeilen.
-- Performance:     begrenzter Key-/Pool-/Mapping-Snapshot vor Ergebnis-LOB-Kopie.
-- Einschränkungen: Keine 1:1-, Privacy- oder historische Pool-Drift-Garantie.
-- ============================================================================
CREATE OR ALTER PROCEDURE [toolbelt_pseudonymization].[USP_DeterministicLookup]
(
      @InputTable sysname = NULL
    , @LookupTable sysname = NULL
    , @MappingVersion int = NULL
    , @Seed bigint = 0
    , @LookupVersion bigint = NULL
    , @MaxInputRows int = 10000
    , @MaxLookupRows int = 10000
    , @MaxLookupTextBytes bigint = 2097152
    , @MaxResultBytes bigint = 16777216
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @KeepData = COALESCE(@KeepData, 0), @Debug = COALESCE(@Debug, 0), @Hilfe = COALESCE(@Hilfe, 0);
    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_pseudonymization' AS sysname) AS SchemaName,
            CAST(N'USP_DeterministicLookup' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Deterministischer synthetischer Lookup; explizite Poolversion, kein Anonymisierungs- oder Eins-zu-eins-Schutz.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'InputOrdinal', N'bigint', 1, 0, NULL, CAST(N'Positiver Eingabeordinal; SELECT nach dieser Spalte sortiert.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'LookupOrdinal', N'bigint', 1, 1, NULL, CAST(N'Expliziter Poolordinal; bei NULL-Key NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Value', N'nvarchar(max)', 1, 1, NULL, CAST(N'Unveränderter Pooltext, Latin1_General_100_BIN2; NULL-Key ergibt NULL.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'54000-54009', NULL, NULL, NULL, NULL, CAST(N'Konfiguration, Ressourcen, Tabellen, Ordinals, Keys, leerer Pool, Budgets, Sampling, Dependency oder interne Namenskollision; kein Teilresultat.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE; ResultTable zusätzlich Helper-EXECUTE; keine automatische Rechteausweitung.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Keine persistierte Überwachung alter Pools, keine Eins-zu-eins-Auswahl oder Privacy-Zusage. MARS-Änderungen gleicher Temps unsupported.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Nur synthetische Tabellen; fachliche Ordinals dürfen Lücken haben.' AS nvarchar(max)), CAST(N'CREATE TABLE #Input(Ordinal bigint, [Key] varbinary(max)); CREATE TABLE #Pool(Ordinal bigint, [Value] nvarchar(max)); INSERT #Input VALUES(10,0x010203); INSERT #Pool VALUES(20,N''synthetic''); EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N''#Input'',@LookupTable=N''#Pool'',@MappingVersion=1,@LookupVersion=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@InputTable', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Key varbinary(max): NULL wird als NULL-Ergebnis weitergeführt, sonst 1..8000 Bytes. Leere Eingabe zulässig. Kein ResultTable-Identitätsoverlap.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@LookupTable', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Value nvarchar(max), auch NULL/leer ist als Poolwert zulässig. Pool muss mindestens eine Zeile enthalten. Auswahlposition folgt der Ordinalsortierung, nicht dem konkreten lückenhaften Ordinalwert. Nicht dieselbe tatsächliche Tabelle wie ResultTable.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MappingVersion', N'int', 1, 0, N'NULL', CAST(N'Fachlich erforderliche positive int-Kontextversion 1..2147483647; NULL/0/negativ wirft 54000. Zusammen mit Seed und LookupVersion deterministischer Mappingkontext.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Seed', N'bigint', 0, 0, N'0', CAST(N'Jeder nicht-NULL-bigint im gesamten 64-Bit-Bereich, Default 0; NULL wirft 54000. Deterministischer Variantenkontext, kein Secret/Zufallsaufruf.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@LookupVersion', N'bigint', 1, 0, N'NULL', CAST(N'Fachlich erforderliche positive bigint-Poolversion 1..9223372036854775807; NULL/0/negativ wirft 54000. Caller muss sie bei Pooländerungen ändern; keine automatische Hash-/Versionsableitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxInputRows', N'int', 0, 0, N'10000', CAST(N'Ganzzahl 1..100000 Inputzeilen, Default 10000; NULL/außerhalb ungültig. Kein Teilresultat bei Überschreitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxLookupRows', N'int', 0, 0, N'10000', CAST(N'Ganzzahl 1..100000 Poolzeilen, Default 10000; NULL/außerhalb ungültig. Pool muss unabhängig davon nicht leer sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxLookupTextBytes', N'bigint', 0, 0, N'2097152', CAST(N'Ganzzahl 1..16777216 Bytes als Summe DATALENGTH(Value) im Pool, Default 2097152; NULL-Werte zählen 0. NULL/außerhalb beim Budget ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@MaxResultBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216 Bytes als Summe DATALENGTH der zugeordneten Ergebniswerte, Default 16777216. Wiederholte Poolwerte zählen pro Ergebniszeile erneut; NULL zählt 0. NULL/außerhalb ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf keine der beiden Eingabetabellen sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0, NULL wirkt wie 0: 0 still; 1 Phasenmessages; 2 zusätzlich Zeilen-/Bytezahlen; 3..255 zusätzlich Temp-Objektmetadaten. Keine Keys, Werte, Seeds oder Hashes; bei ResultTable zusätzlich Helperdiagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF @MappingVersion IS NULL OR @MappingVersion <= 0 OR @Seed IS NULL OR @LookupVersion IS NULL OR @LookupVersion <= 0
        THROW 54000, N'DeterministicLookup: MappingVersion/LookupVersion müssen positiv sein; Seed darf nicht NULL sein.', 1;
    IF @MaxInputRows IS NULL OR @MaxInputRows NOT BETWEEN 1 AND 100000
        OR @MaxLookupRows IS NULL OR @MaxLookupRows NOT BETWEEN 1 AND 100000
        OR @MaxLookupTextBytes IS NULL OR @MaxLookupTextBytes NOT BETWEEN 1 AND 16777216
        OR @MaxResultBytes IS NULL OR @MaxResultBytes NOT BETWEEN 1 AND 16777216
        THROW 54001, N'DeterministicLookup: ungültige positive Ressourcenlimits.', 1;

    DECLARE @InputId int, @LookupId int, @TableName sysname, @TableRole int = 0;
    WHILE @TableRole < 2
    BEGIN
        SET @TableName = CASE @TableRole WHEN 0 THEN @InputTable ELSE @LookupTable END;
        IF @TableName IS NULL OR DATALENGTH(@TableName) > 232
            OR LEFT(@TableName,1) COLLATE Latin1_General_100_BIN2 <> N'#'
            OR LEFT(@TableName,2) COLLATE Latin1_General_100_BIN2 = N'##'
            OR LEFT(LOWER(@TableName COLLATE Latin1_General_100_BIN2),5) COLLATE Latin1_General_100_BIN2 = N'#tbx_'
            OR QUOTENAME(@TableName) IS NULL
            THROW 54002, N'DeterministicLookup: caller-lokaler Temp-Tabellenname erforderlich.', 1;
        DECLARE @TableId int = OBJECT_ID(N'tempdb..' + QUOTENAME(@TableName), N'U');
        IF @TableId IS NULL THROW 54002, N'DeterministicLookup: Eingabetabelle fehlt oder ist nicht sichtbar.', 2;
        IF @TableRole = 0 SET @InputId = @TableId; ELSE SET @LookupId = @TableId;
        SET @TableRole += 1;
    END;
    IF @ResultTable IS NOT NULL AND OBJECT_ID(N'tempdb..' + QUOTENAME(@ResultTable),N'U') IN (@InputId,@LookupId)
        THROW 54002, N'DeterministicLookup: ResultTable darf keine Eingabetabelle sein.', 3;
    DECLARE @Required TABLE (ObjectId int, ColumnName sysname, TypeId int, MaxLength int);
    INSERT @Required VALUES (@InputId,N'Ordinal',127,8),(@InputId,N'Key',165,-1),
        (@LookupId,N'Ordinal',127,8),(@LookupId,N'Value',231,-1);
    IF EXISTS (SELECT 1 FROM @Required AS required WHERE NOT EXISTS
        (SELECT 1 FROM tempdb.sys.columns AS actual WHERE actual.object_id = required.ObjectId
            AND CONVERT(varbinary(256),actual.name) = CONVERT(varbinary(256),required.ColumnName)
            AND actual.system_type_id = required.TypeId AND actual.user_type_id = actual.system_type_id
            AND actual.max_length = required.MaxLength AND actual.is_computed = 0))
        THROW 54002, N'DeterministicLookup: Ordinal bigint, Key varbinary(max), Value nvarchar(max) erforderlich.', 4;
    IF OBJECT_ID(N'tempdb..#tbx_DeterministicLookup_Pool',N'U') IS NOT NULL
        OR OBJECT_ID(N'tempdb..#tbx_DeterministicLookup_Input',N'U') IS NOT NULL
        OR OBJECT_ID(N'tempdb..#tbx_DeterministicLookup_Map',N'U') IS NOT NULL
        OR OBJECT_ID(N'tempdb..#tbx_DeterministicLookup_ResultSource',N'U') IS NOT NULL
        THROW 54009, N'DeterministicLookup: reservierter interner Temp-Name bereits sichtbar.', 1;

    -- Separate Compilergrenze: bei sichtbaren fremden Shapes niemals den
    -- tempgebundenen Ausgabekern kompilieren oder ausführen. Hilfe lief zuvor.
    EXEC toolbelt_pseudonymization.USP_DeterministicLookupCore
        @InputTable=@InputTable,@LookupTable=@LookupTable,@MappingVersion=@MappingVersion,
        @Seed=@Seed,@LookupVersion=@LookupVersion,@MaxInputRows=@MaxInputRows,
        @MaxLookupRows=@MaxLookupRows,@MaxLookupTextBytes=@MaxLookupTextBytes,
        @MaxResultBytes=@MaxResultBytes,@InputObjectId=@InputId,@LookupObjectId=@LookupId,
        @ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug,@Hilfe=0;
    RETURN 0;
END;
GO
