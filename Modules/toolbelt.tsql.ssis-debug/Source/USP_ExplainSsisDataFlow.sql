-- ============================================================================
-- Generiert durch Scripts/New-ContractSources.py aus Contracts/Api.json.
-- Objekt: toolbelt_tsql.USP_ExplainSsisDataFlow; öffentliche T-SQL-Fassade.
-- Zweck: DTSX2 erklären, JSON-Vorlage und lesende CTE-Debugskripte erzeugen.
-- Vertrag: SSIS_CURRENT_API_CONTRACT.md; USP_CONTRACT1.0; Version1.0.0.
-- Parameter/Resultset: vollständig in Contracts/Api.json und @Hilfe=1.
-- Aktuelle Ergänzungen: schema-validiertes Contracts/ComponentsV2.json Help-Overlay.
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
CREATE OR ALTER PROCEDURE toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes varbinary(max) = NULL,
    @Operation varchar(32) = N'explain',
    @ProjectContext nvarchar(max) = NULL,
    @Bindings nvarchar(max) = NULL,
    @CatalogBindings nvarchar(max) = NULL,
    @TargetFlow varchar(64) = NULL,
    @InspectStage varchar(64) = NULL,
    @LookupPolicies nvarchar(max) = NULL,
    @ComparisonCollation sysname = NULL,
    @TSqlVersion smallint = 150,
    @MaxPackageBytes bigint = 134217728,
    @MaxXmlCharacters bigint = 134217728,
    @MaxXmlNodes bigint = 1048576,
    @MaxModelNodes bigint = 262144,
    @MaxModelEdges bigint = 1048576,
    @MaxComponents bigint = 4096,
    @MaxPaths bigint = 8192,
    @MaxColumns bigint = 65536,
    @MaxInputs bigint = 8192,
    @MaxJsonDocumentBytes bigint = 4194304,
    @MaxAllJsonBytes bigint = 8388608,
    @MaxJsonNodes bigint = 131072,
    @MaxExpressionBytes bigint = 4194304,
    @MaxExpressionTokens bigint = 262144,
    @MaxExpressionNodes bigint = 131072,
    @MaxPlanUnits bigint = 8192,
    @MaxCatalogObjects bigint = 4096,
    @MaxCatalogQueries bigint = 4096,
    @MaxParserCalls bigint = 32768,
    @MaxArtifacts bigint = 65536,
    @MaxDiagnostics bigint = 16384,
    @MaxSqlArtifactBytes bigint = 2097152,
    @MaxTotalOutputBytes bigint = 134217728,
    @MaxAnalysisMilliseconds bigint = 0,
    @ResultTable sysname = NULL,
    @KeepData bit = 0,
    @Debug tinyint = 0,
    @Hilfe bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        DECLARE @helpObjectName sysname=N'USP_ExplainSsisDataFlow';
SELECT CONVERT(varchar(16),'1.0') AS HelpContractVersion,
 CONVERT(sysname,N'toolbelt_tsql') AS SchemaName,CONVERT(sysname,@helpObjectName) AS ObjectName,
 CONVERT(varchar(32),v.Section) AS Section,CONVERT(int,v.Ordinal) AS Ordinal,
 CONVERT(sysname,v.ItemName) AS ItemName,CONVERT(varchar(256),v.SqlDataType) AS SqlDataType,
 CONVERT(bit,v.IsRequired) AS IsRequired,CONVERT(bit,v.IsNullable) AS IsNullable,
 CONVERT(nvarchar(4000),v.DefaultValue) AS DefaultValue,CONVERT(nvarchar(max),v.Description) AS Description,
 CONVERT(nvarchar(max),v.ExampleSql) AS ExampleSql
FROM (VALUES
(N'DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,CAST(N'Erklärt unterstützte SSIS-Datenflüsse standardmäßig mit typisierter JSON-Eingabevorlage und vollständigen, einzeln prüfbaren Debug-SQL-Batches. Paket und enthaltenes SQL werden beim Analysieren niemals ausgeführt.' AS nvarchar(max)),NULL),
(N'PARAMETER',1,N'@PackageBytes',N'varbinary(max)',1,0,N'NULL',CAST(N'Genau ein vollständiges DTSX-XML-Paket als UTF-8-/UTF-16-Bytepuffer varbinary(max), kein Pfad/Base64-/XML-Stringparameter. DTSX-Formatprofile PackageFormatVersion 6 oder 8 werden unterstützt; kein verschlüsselter Container, DTD, externer Resolver oder XInclude. Leer/NULL ungültig, NULL ist nur technischer Help-Default. MaxPackageBytes begrenzt die Rohbytes; XML-Tiefe bleibt absolut 128. Paket/enthaltenes SQL werden beim Analysieren nicht ausgeführt.' AS nvarchar(max)),NULL),
(N'PARAMETER',2,N'@Operation',N'varchar(32)',0,0,N'N''explain''',CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: explain (Default) analysiert die gebundenen Datenflüsse und erzeugt Workflow, Stufenverzeichnis, Debug-SQL und Diagnosen; bindings-template erzeugt ausschließlich die paket-/kontextgebundene Schema-2-Eingabevorlage zum Bearbeiten unter values. Template verlangt Bindings=NULL und CatalogBindings=NULL. Kein -v2-Alias, kein Opt-in; NULL/leer/andere Schreibweisen ungültig.' AS nvarchar(max)),NULL),
(N'PARAMETER',3,N'@ProjectContext',N'nvarchar(max)',0,1,N'NULL',CAST(N'NULL (Default) bedeutet leeren Schema-2-Projektkontext. Sonst JSON-Objekt {"schemaVersion":2,"projectParameters":[...],"connectionManagers":[...]}; beide Arrays optional. Parameterentry: name, ssisType sowie optional designValue, required und sensitive (JSON-Booleans); Connectionentry: refId, name, provider. Provider taxativ sqlserver-oledb oder sqlserver-adonet, beide ordnen vorhandene SQL-Server-Connections zu; keine Connectionstrings/Credentials. Eindeutige Namen/refIds, Projektconnections dürfen Paketconnections nicht überlagern. Typ-/Wertabbildung im Abschnitt SSIS-Eingabetypen der Objektreferenz; unbekannte Typen sind nicht bindbar. Andere Rootkeys, resourceOptions und schemaVersion ungleich 2 ungültig. Feste Kontrollprotokollgrenze 4194304 UTF-16-Bytes zusätzlich zu den gewählten JSON-Limits; beim Zurückgeben der Bindings denselben Kontext verwenden.' AS nvarchar(max)),NULL),
(N'PARAMETER',4,N'@Bindings',N'nvarchar(max)',0,1,N'NULL',CAST(N'NULL (Default) verwendet vorhandene nicht sensitive Designdefaults; benötigte fehlende Laufzeitwerte bleiben als fehlender Kontext sichtbar. Sonst vollständiges von bindings-template zurückgegebenes JSON-Objekt mit schemaVersion=2, profile exakt ssis-debug-components-v2, packageSha256, contextSha256, availableInputs und values. Ausschließlich values nach generierten Eingabekeys bearbeiten; Paket-/Kontexthashes und vollständige Herkunftsmetadaten unverändert zurückgeben. values ist ein Objekt typisierter JSON-Werte: Stringtexte/ISO-Datum/-GUID/-Hex, JSON-Boolean für bit, exakte Zahlen gemäß SSIS-Eingabetypen; JSON-null als SQL-NULL, keine SQL-Ausdrücke. Sensitive/ unbekannte/nicht bindbare Keys abgewiesen. Im Template-Modus ausschließlich NULL; kein leeres Ersatzobjekt und keine Ressourcenoptionen.' AS nvarchar(max)),NULL),
(N'PARAMETER',5,N'@CatalogBindings',N'nvarchar(max)',0,1,N'NULL',CAST(N'NULL (Default) liefert keine explizite Katalogzuordnung; fehlende erforderliche Bindungen bleiben missing_context. Sonst JSON-Objekt mit schemaVersion 1 oder 2, defaultDatabase als Name, databases als Array eindeutiger erlaubter Same-instance-Datenbanknamen und connections als Objekt {importierteConnectionId:Datenbankname}. Default und jede Zuordnung müssen in databases stehen; Connection-IDs müssen im Paket/Projektkontext vorhanden sein. Version 1 erlaubt nur diese Felder; Version 2 ergänzt flatFileInputs als Objekt (auch {}). Je Flatfileentry: database, schema, object, columns als Mapping importierter Spalten-IDs zu SQL-Spaltennamen; optional rowOrdinalColumn und errorRows als entsprechender Quellobjekt-/Spaltenbeschreiber gemäß Komponentenvertrag. Keine freien SQL-Fragmente, Server-/Credential-/Dateipfade oder automatische Rechte. Template-Modus verlangt NULL; leer/andere Shapes ungültig.' AS nvarchar(max)),NULL),
(N'PARAMETER',6,N'@TargetFlow',N'varchar(64)',0,1,N'NULL',CAST(N'NULL (Default) berücksichtigt alle erkannten Zielflüsse getrennt. Sonst exakte modellinterne TargetFlowId aus der Workflow-/StageIndex-Ausgabe desselben Pakets, maximal varchar(64); keine frei gewählte Komponentenbezeichnung oder dauerhafte Projekt-ID. Groß-/Kleinschreibung/Whitespace werden nicht normalisiert; unbekannt/leer ungültig im Explain-Pfad.' AS nvarchar(max)),NULL),
(N'PARAMETER',7,N'@InspectStage',N'varchar(64)',0,1,N'NULL',CAST(N'Taxativ für Steuerwerte: NULL (Default) liefert Zielskript/Stufenverzeichnis ohne zusätzliche StageSql-Auswahl; all liefert die unterstützten Vorgängerstufen jedes gewählten Ziels. Alternativ eine exakte StageId aus dem StageIndex desselben Pakets; dann ist TargetFlow fachlich erforderlich und die Stufe muss zu dessen Vorgängerpfad gehören. all benötigt keinen expliziten TargetFlow. Kein Trim/Casefold; unbekannte/leere konkrete ID ungültig.' AS nvarchar(max)),NULL),
(N'PARAMETER',8,N'@LookupPolicies',N'nvarchar(max)',0,1,N'NULL',CAST(N'NULL (Default) bedeutet beliebige, pro relevantem Snapshot einmal materialisierte Trefferauswahl. Sonst exakt JSON-Objekt {"schemaVersion":1,"lookups":{"<Lookup-Komponenten-ID>":{"orderBy":[{"column":"<Referenzspalte>","direction":"asc"}]}}}. IDs müssen existierende Lookupkomponenten adressieren, orderBy nicht leer und ohne doppelte Spalten. direction taxativ asc = aufsteigend oder desc = absteigend, exakt kleingeschrieben. Keine freien ORDER-BY-Ausdrücke; vollständige Sortierbindung erforderlich, Gleichstände erhalten keine erfundene Eindeutigkeit.' AS nvarchar(max)),NULL),
(N'PARAMETER',9,N'@ComparisonCollation',N'sysname',0,1,N'NULL',CAST(N'NULL (Default) verwendet bei Katalogbindung die Collation der expliziten defaultDatabase. Sonst genau ein tatsächlich vom Server unterstützter Collationname als sysname, kein COLLATE-SQL-Fragment; Prüfung gegen sys.fn_helpcollations. Dynamische Serverwertemenge, kein festes erfundenes Inventar: SELECT name FROM sys.fn_helpcollations() zeigt sie. Dient Vergleichs-/Ausdrucksbindung und ändert keine DB-/Spaltencollation; leer/unbekannt ungültig.' AS nvarchar(max)),NULL),
(N'PARAMETER',10,N'@TSqlVersion',N'smallint',0,0,N'150',CAST(N'Taxativ: 150 = SQL-Server-2019-Grammatik (Default), 160 = 2022, 170 = 2025 für die Parser-/Sicherheitsprüfung erzeugten SQLs. Kein automatischer Dialektwechsel/Ablesen der Engineversion. NULL/andere smallint-Werte ungültig.' AS nvarchar(max)),NULL),
(N'PARAMETER',11,N'@MaxPackageBytes',N'bigint',0,0,N'134217728',CAST(N'bigint 0..9223372036854775807, Default 134217728: Rohbytes des DTSX-Pakets. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',12,N'@MaxXmlCharacters',N'bigint',0,0,N'134217728',CAST(N'bigint 0..9223372036854775807, Default 134217728: vom XML-Reader gezählte Zeichen des Pakets. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',13,N'@MaxXmlNodes',N'bigint',0,0,N'1048576',CAST(N'bigint 0..9223372036854775807, Default 1048576: gelesene XML-Knoten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',14,N'@MaxModelNodes',N'bigint',0,0,N'262144',CAST(N'bigint 0..9223372036854775807, Default 262144: Knoten des importierten Modells. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',15,N'@MaxModelEdges',N'bigint',0,0,N'1048576',CAST(N'bigint 0..9223372036854775807, Default 1048576: Kanten des importierten Modells. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',16,N'@MaxComponents',N'bigint',0,0,N'4096',CAST(N'bigint 0..9223372036854775807, Default 4096: SSIS-Komponenten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',17,N'@MaxPaths',N'bigint',0,0,N'8192',CAST(N'bigint 0..9223372036854775807, Default 8192: Datenflusskanten/Pfade. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',18,N'@MaxColumns',N'bigint',0,0,N'65536',CAST(N'bigint 0..9223372036854775807, Default 65536: importierte Spaltenmetadaten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',19,N'@MaxInputs',N'bigint',0,0,N'8192',CAST(N'bigint 0..9223372036854775807, Default 8192: entdeckte/gebundene Eingaben. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',20,N'@MaxJsonDocumentBytes',N'bigint',0,0,N'4194304',CAST(N'bigint 0..9223372036854775807, Default 4194304: UTF-16-Bytes je JSON-Eingabedokument; ProjectContext behält zusätzlich das feste Kontrollprotokolllimit. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',21,N'@MaxAllJsonBytes',N'bigint',0,0,N'8388608',CAST(N'bigint 0..9223372036854775807, Default 8388608: Summe der UTF-16-Bytes von Bindings, CatalogBindings und LookupPolicies, ohne ProjectContext. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',22,N'@MaxJsonNodes',N'bigint',0,0,N'131072',CAST(N'bigint 0..9223372036854775807, Default 131072: Knoten je begrenzt geparstem JSON-Dokument. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',23,N'@MaxExpressionBytes',N'bigint',0,0,N'4194304',CAST(N'bigint 0..9223372036854775807, Default 4194304: UTF-16-Bytes eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',24,N'@MaxExpressionTokens',N'bigint',0,0,N'262144',CAST(N'bigint 0..9223372036854775807, Default 262144: Tokens eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',25,N'@MaxExpressionNodes',N'bigint',0,0,N'131072',CAST(N'bigint 0..9223372036854775807, Default 131072: Knoten eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',26,N'@MaxPlanUnits',N'bigint',0,0,N'8192',CAST(N'bigint 0..9223372036854775807, Default 8192: geprüfte Debugplaneinheiten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',27,N'@MaxCatalogObjects',N'bigint',0,0,N'4096',CAST(N'bigint 0..9223372036854775807, Default 4096: gebundene Katalogobjekte. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',28,N'@MaxCatalogQueries',N'bigint',0,0,N'4096',CAST(N'bigint 0..9223372036854775807, Default 4096: Katalogabfragen. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',29,N'@MaxParserCalls',N'bigint',0,0,N'32768',CAST(N'bigint 0..9223372036854775807, Default 32768: SQL-Parser-/Sicherheitsprüfaufrufe. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',30,N'@MaxArtifacts',N'bigint',0,0,N'65536',CAST(N'bigint 0..9223372036854775807, Default 65536: erzeugte Ergebnisartefakte. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',31,N'@MaxDiagnostics',N'bigint',0,0,N'16384',CAST(N'bigint 0..9223372036854775807, Default 16384: erzeugte Diagnosen. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',32,N'@MaxSqlArtifactBytes',N'bigint',0,0,N'2097152',CAST(N'bigint 0..9223372036854775807, Default 2097152: UTF-16-Bytes je erzeugtem SQL-Artefakt. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',33,N'@MaxTotalOutputBytes',N'bigint',0,0,N'134217728',CAST(N'bigint 0..9223372036854775807, Default 134217728: UTF-16-Bytes der gezählten Gesamtausgabe. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',34,N'@MaxAnalysisMilliseconds',N'bigint',0,0,N'0',CAST(N'bigint 0..9223372036854775807, Default 0: Millisekunden kooperatives Analysezeitbudget, keine harte Gesamtwallclock-Garantie. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben.' AS nvarchar(max)),NULL),
(N'PARAMETER',35,N'@ResultTable',N'sysname',0,1,N'NULL',CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Name 2..116 UTF-16-Einheiten; der vollständige Artefaktsatz wird vor Zielmutation erzeugt.' AS nvarchar(max)),NULL),
(N'PARAMETER',36,N'@KeepData',N'bit',0,1,N'0',CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)),NULL),
(N'PARAMETER',37,N'@Debug',N'tinyint',0,1,N'0',CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. 0 still, 1..255 eine redigierte Abschlussmessage mit Artefakt-/SQL-Prüfeinheitenzählern. Kein zusätzliches Resultset und keine Quell-/Secretwerte; der interne ResultTable-Helper wird ausdrücklich mit Debug=0 aufgerufen.' AS nvarchar(max)),NULL),
(N'PARAMETER',38,N'@Hilfe',N'bit',0,1,N'0',CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',1,N'ArtifactKind',N'varchar(32)',1,0,NULL,CAST(N'BindingsTemplate, Workflow, StageIndex, PreparationSql, StageSql, PlanManifest, PlanUnitSql, TargetSql, RowCountSql, CleanupSql, DebugScript, FlatFileWriteProjection, ColumnLineage oder Diagnostic.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',2,N'TargetFlowId',N'varchar(64)',1,1,NULL,CAST(N'Modellinterne Zielfluss-ID; keine dauerhafte Projektreferenz.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',3,N'StageId',N'varchar(64)',1,1,NULL,CAST(N'Modellinterne Prüfpunkt-ID, innerhalb derselben Paketbindung stabil.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',4,N'Ordinal',N'int',1,0,NULL,CAST(N'Globale1-basierte Ausgabeordnung.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',5,N'ComponentId',N'nvarchar(4000)',1,1,NULL,CAST(N'Ursprüngliche gebundene Komponenten-ID.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',6,N'EvidenceClass',N'varchar(24)',1,0,NULL,CAST(N'descriptive, translated, pragmatic, missing_context oder unsupported.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',7,N'Severity',N'varchar(16)',1,1,NULL,CAST(N'info, warning oder error für Diagnosen.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',8,N'DiagnosticCode',N'varchar(64)',1,1,NULL,CAST(N'Stabiler maschinenlesbarer Diagnosecode.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',9,N'IsComplete',N'bit',1,0,NULL,CAST(N'Benötigter Pfad und Kontext vollständig im aktuellen Profil vorhanden.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',10,N'SafetyStatus',N'varchar(24)',1,0,NULL,CAST(N'not_applicable, not_checked, passed oder blocked.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',11,N'IsExecutable',N'bit',1,0,NULL,CAST(N'Vollständiger, im gebundenen Profil geprüfter Batch; kein bereits ausgeführter Runtime-Nachweis.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',12,N'Content',N'nvarchar(max)',1,0,NULL,CAST(N'Artefaktinhalt, insbesondere vollständiger SQL-Prüfblock oder JSON-Vorlage.' AS nvarchar(max)),NULL),
(N'RESULT_COLUMN',13,N'DetailsJson',N'nvarchar(max)',1,1,NULL,CAST(N'Zusätzliche gültige JSON-Metadaten.' AS nvarchar(max)),NULL),
(N'DESCRIPTION',2,NULL,NULL,NULL,NULL,NULL,CAST(N'Der aktuelle Komponentenvertrag ist der Standard für bindings-template und explain. Die editierbare Vorlage verwendet schemaVersion 2 und das Profil ssis-debug-components-v2.' AS nvarchar(max)),NULL),
(N'LIMITATION',2,NULL,NULL,NULL,NULL,NULL,CAST(N'Ressourcenlimits werden ausschließlich durch die benannten bigint-Parameter gesetzt. 0 bedeutet unbegrenzt; NULL und negative Werte sind ungültig. resourceOptions im ProjectContext wird abgewiesen.' AS nvarchar(max)),NULL),
(N'LIMITATION',3,NULL,NULL,NULL,NULL,NULL,CAST(N'Die Vorlage zeigt nicht-sensitive Paketdefaults als editierbare Debugwerte. Laufzeitzuweisungen und Ausdrücke bleiben als Herkunft markiert; das ist kein beobachteter SSIS-Laufzeitwert. Sensitive Werte bleiben redigiert.' AS nvarchar(max)),NULL),
(N'LIMITATION',4,NULL,NULL,NULL,NULL,NULL,CAST(N'DebugScript ist nur bei vollständigem Pfad und gebundenem SQL-Text ausführbar. Bei fehlendem Kontext nennt Workflow/StageIndex die Erstursache und verfügbare vollständige Teilpläne; SSIS-Aufgaben werden nicht ausgeführt.' AS nvarchar(max)),NULL),
(N'EXAMPLE',2,NULL,NULL,NULL,NULL,NULL,CAST(N'Aktuelle editierbare Parameter-Vorlage erzeugen.' AS nvarchar(max)),CAST(N'EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@PackageBytes,@Operation=''bindings-template'';' AS nvarchar(max))),
(N'EXAMPLE',3,NULL,NULL,NULL,NULL,NULL,CAST(N'Eine optionale Grenze direkt am SQL-Parameter setzen; 0 ist unbegrenzt.' AS nvarchar(max)),CAST(N'EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@PackageBytes,@MaxExpressionBytes=0;' AS nvarchar(max))),
(N'EXAMPLE',4,NULL,NULL,NULL,NULL,NULL,CAST(N'Gebundene Parameterwerte verwenden und bei vollständigem Kontext das gesamte DebugScript ausgeben lassen.' AS nvarchar(max)),CAST(N'EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@PackageBytes,@Operation=''explain'',@Bindings=@Bindings,@CatalogBindings=@CatalogBindings;' AS nvarchar(max))),
(N'EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,CAST(N'Reine Hilfe ohne Paket oder Katalogprüfung.' AS nvarchar(max)),CAST(N'EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;' AS nvarchar(max))),
(N'PERMISSION',1,NULL,NULL,NULL,NULL,NULL,CAST(N'CALLER; EXECUTE und vollständige Katalogsicht der ausdrücklich erlaubten Datenbanken. Keine Rechtevergabe.' AS nvarchar(max)),NULL),
(N'LIMITATION',1,NULL,NULL,NULL,NULL,NULL,CAST(N'Windows SQL Server 2019/2022/2025; UNSAFE/ScriptDom. NOLOCK erlaubt Dirty Reads und garantiert keine Sperrfreiheit. Keine Ausführung von Paket-SQL.' AS nvarchar(max)),NULL)
) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 WHEN 'PERMISSION' THEN 4 ELSE 5 END,v.Ordinal;
        RETURN;
    END;
    -- Nur im Prozedurscope: neutrale Vertragsfehler dürfen eine gesunde
    -- Callertransaktion nicht durch geerbtes XACT_ABORT ON doomen. SQL Server
    -- stellt die geerbte SET-Option beim Verlassen dieses Scopes wieder her.
    SET XACT_ABORT OFF;
    BEGIN TRY
        -- SQL CLR kann in einer bereits doomed Transaktion vor dem C#-Preflight
        -- mit3930 scheitern. Deshalb den Vertragsfehler hier vorziehen.
        IF XACT_STATE()=-1 THROW 50000,N'TBX_SSISDBG_unresolved_binding: Callertransaktion ist nicht schreibfähig.',1;
        EXEC toolbelt_tsql.USP_ExplainSsisDataFlowInternal
        @PackageBytes=@PackageBytes,
        @Operation=@Operation,
        @ProjectContext=@ProjectContext,
        @Bindings=@Bindings,
        @CatalogBindings=@CatalogBindings,
        @TargetFlow=@TargetFlow,
        @InspectStage=@InspectStage,
        @LookupPolicies=@LookupPolicies,
        @ComparisonCollation=@ComparisonCollation,
        @TSqlVersion=@TSqlVersion,
        @MaxPackageBytes=@MaxPackageBytes,
        @MaxXmlCharacters=@MaxXmlCharacters,
        @MaxXmlNodes=@MaxXmlNodes,
        @MaxModelNodes=@MaxModelNodes,
        @MaxModelEdges=@MaxModelEdges,
        @MaxComponents=@MaxComponents,
        @MaxPaths=@MaxPaths,
        @MaxColumns=@MaxColumns,
        @MaxInputs=@MaxInputs,
        @MaxJsonDocumentBytes=@MaxJsonDocumentBytes,
        @MaxAllJsonBytes=@MaxAllJsonBytes,
        @MaxJsonNodes=@MaxJsonNodes,
        @MaxExpressionBytes=@MaxExpressionBytes,
        @MaxExpressionTokens=@MaxExpressionTokens,
        @MaxExpressionNodes=@MaxExpressionNodes,
        @MaxPlanUnits=@MaxPlanUnits,
        @MaxCatalogObjects=@MaxCatalogObjects,
        @MaxCatalogQueries=@MaxCatalogQueries,
        @MaxParserCalls=@MaxParserCalls,
        @MaxArtifacts=@MaxArtifacts,
        @MaxDiagnostics=@MaxDiagnostics,
        @MaxSqlArtifactBytes=@MaxSqlArtifactBytes,
        @MaxTotalOutputBytes=@MaxTotalOutputBytes,
        @MaxAnalysisMilliseconds=@MaxAnalysisMilliseconds,
        @ResultTable=@ResultTable,
        @KeepData=@KeepData,
        @Debug=@Debug,
        @Hilfe=@Hilfe;
    END TRY
    BEGIN CATCH
        DECLARE @message nvarchar(4000)=ERROR_MESSAGE(),@start int,@stop int,@safe nvarchar(2048);
        SET @start=CHARINDEX(N'TBX_SSISDBG_',@message);
        IF @start>0
        BEGIN
            SET @stop=CHARINDEX(NCHAR(10),@message,@start);
            SET @safe=SUBSTRING(@message,@start,CASE WHEN @stop>@start THEN @stop-@start ELSE 2048 END);
        END
        ELSE SET @safe=N'TBX_SSISDBG_sql_error: SQL-/CLR-Fehler '+CONVERT(nvarchar(12),ERROR_NUMBER())+N', State '+CONVERT(nvarchar(12),ERROR_STATE())+N'. Keine Ausgabe vertraulicher Fehlerpayloads.';
        THROW 50000,@safe,1;
    END CATCH;
END;
GO
