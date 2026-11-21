-- ============================================================================
-- Objekt: toolbelt_metadata.USP_ScriptTableClone; Stored Procedure
-- Zweck: Script-only-Vorschau für explizite same-database Tabellenziele
-- Vertrag: USP_CONTRACT 1.0; Documentation/USP_ScriptTableClone.md
-- Parameter: SourceSchema/SourceTable/TargetSchema/TargetTable nvarchar(max)=NULL,
--            IncludeIdentity/IncludeExtendedProperties bit=0; TableMap sysname=NULL,
--            ExternalReferenceRule varchar(16)=REJECT; IncludeTriggers bit=0; Standardtail
-- Resultset: Ordinal int, ObjectKind varchar(32), TargetName nvarchar(776),
--            ScriptText nvarchar(max); alle NOT NULL
-- Dependencies: toolbelt.core.result-table >=1.0.0 same_database;
--               IncludeTriggers=1: exakt gepinnter Parser 2.0.1 same_database
-- Rechte: EXECUTE, datenbankweite VIEW DEFINITION für vollständige FK-/Kollisionssicht
-- Versionen/Plattformen: SQL Server 2019/2022/2025 CL150+, Windows/Linux;
--                       Trigger-Opt-in ausschließlich Windows
-- Fehler: 53900-53909; Enginefehler unverändert; keine DDL-Ausführung/Datenkopie
-- Performance: begrenzte Metadatenmaterialisierung, vollständiger Plan vor Ausgabe
-- Einschränkungen: Momentaufnahme; Unsupported bricht ab; kein Drift-/Recoveryversprechen
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_metadata.USP_ScriptTableClone
    @SourceSchema nvarchar(max)=NULL,
    @SourceTable nvarchar(max)=NULL,
    @TargetSchema nvarchar(max)=NULL,
    @TargetTable nvarchar(max)=NULL,
    @IncludeIdentity bit=0,
    @IncludeExtendedProperties bit=0,
    @TableMap sysname=NULL,
    @ExternalReferenceRule varchar(16)='REJECT',
    @IncludeTriggers bit=0,
    @ResultTable sysname=NULL,
    @KeepData bit=0,
    @Debug tinyint=0,
    @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-metadata-usp-scripttableclone"
-- description: "Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.metadata.table-clone"
-- schema_name: "toolbelt_metadata"
-- object_name: "USP_ScriptTableClone"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@SourceSchema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@SourceTable", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@TargetSchema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@TargetTable", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@IncludeIdentity", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen."}, {"name": "@IncludeExtendedProperties", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern."}, {"name": "@TableMap", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen."}, {"name": "@ExternalReferenceRule", "sql_type": "varchar(16)", "sql_default": "'REJECT'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig."}, {"name": "@IncludeTriggers", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt vorhandene Trigger ab (Default); 1 rendert unterstützte gewöhnliche gemappte DML-Trigger im genehmigten Script-only-Pfad. Erfordert Windows SQL2019/2022/2025 und exakt vorhandene qualifizierte Parserbindung. Kein freies Rewrite beliebiger Trigger, keine Ausführung und keine automatische Parserinstallation. NULL ungültig."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql"]
-- review_status: "verified"
-- source_module_version: "4.1.1"
-- ---
--
-- # USP_ScriptTableClone
--
-- ## Zweck und Einsatzfälle
--
-- Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.
--
-- ## Voraussetzungen
--
-- Modul4.1.1 in der tatsächlich ausgewählten Installationsdatenbank; ausschließlich SameDB-Quell-/Zielobjekte. Ein dreiteiliger zentraler Prozeduraufruf verlegt die Quellobjekte nicht in die Caller-Datenbank. Bestehender ResultTable-Helper>=1.0.0. Basisplanung/Executor/Copy sind TSQL auf Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Trigger-Opt-in ist gesondert Windows-only mit bereits vorhandenem exakt gebundenem Parser2.0.1 und vier Parser-TVFs; kein Nachinstallieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@SourceSchema` | `nvarchar(max)` | `NULL` | Input | Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
-- | `@SourceTable` | `nvarchar(max)` | `NULL` | Input | Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
-- | `@TargetSchema` | `nvarchar(max)` | `NULL` | Input | Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
-- | `@TargetTable` | `nvarchar(max)` | `NULL` | Input | Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
-- | `@IncludeIdentity` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen. |
-- | `@IncludeExtendedProperties` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern. |
-- | `@TableMap` | `sysname` | `NULL` | Input | NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen. |
-- | `@ExternalReferenceRule` | `varchar(16)` | `'REJECT'` | Input | Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig. |
-- | `@IncludeTriggers` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene Trigger ab (Default); 1 rendert unterstützte gewöhnliche gemappte DML-Trigger im genehmigten Script-only-Pfad. Erfordert Windows SQL2019/2022/2025 und exakt vorhandene qualifizierte Parserbindung. Kein freies Rewrite beliebiger Trigger, keine Ausführung und keine automatische Parserinstallation. NULL ungültig. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | NULL | Bedeutung |
-- |---|---|---|---|
-- | `Ordinal` | `int` | nein | 1-basiert/lückenlos; COPY_FK kann nullZeilen liefern |
-- | `ObjectKind` | `varchar(32)` | nein | Planart |
-- | `TargetName` | `nvarchar(776)` | nein | gequoteter Zielname |
-- | `ScriptText` | `nvarchar(max)` | nein | vollständiger Batchtext,keine Ausführung |
--
-- ResultTableNULL direkte Fachausgabe, sonst Routing in vorhandene lokale Caller-#Temp. Plantexte/Resultshape Latin1_General_100_BIN2. Hilfe: bisherige zwölfspaltige Standardhilfe plus genau eine Skillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühe Rückkehr ohne Fachprüfung oder Mutation. Öffentliche Planner-/Execute-/Copy-Hilfe RETURN0; interne Corehilfe behält ihr ursprüngliches RETURN; unverändert. Kein zusätzliches Fachresultset bei Zielrouting.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;
-- -- Vorhandene synthetische Quelle und freies Ziel in dieser DB vorausgesetzt.
-- EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'ContosoSource',
--  @TargetSchema=N'dbo',@TargetTable=N'ContosoClone';
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf öffentliche Vorschau/benötigte Ownershipchain, DB-weites VIEW DEFINITION für vollständige FK-/Kollisionssicht, sichtbare Quelle und Zielschema mit deren VIEW DEFINITION. Computed zusätzlich SELECT sys.sql_expression_dependencies. Trigger-Opt-in zusätzlich SELECT sys.assembly_files/sys.assembly_modules/sys.sql_expression_dependencies und vier Parser-TVFs sowie vollständig sichtbare exakt gebundene Parserassemblies. Keine Source-Daten-SELECT- oder Ziel-DDL-Rechte allein für Vorschau. Bei ResultTable Helper-EXECUTE und Caller-Temp-DDL/Schreibrechte.
--
-- ## Ressourcenbedarf
--
-- Planner:Map1..64,jeQuelle<=1024Spalten/128Indizes/2048Childobjekte,globale Childobjekt-plus-FK-Spaltentupelquote2048. Definitions-/minimaler Outputpreflight und tatsächliche globale Scripttextquote2097152UTF16Bytes. Properties:Payload<=7500Bytes,Varianttotal<=8016;Stringmetadaten rekonstruierbar. Trigger zusätzlich vier atomare Parserresultate und erneute Fehlerprüfung mit Input2097152/ASTTiefe100, tatsächliche Parserguardgrenzen bleiben erhalten. PrivateTemp-/LOB-/AST-/Token-/Scriptkopien und Katalogcursor kosten CPU/Tempdb; kein hartes Wallclock-/Peak-/Produktionskapazitätsversprechen.
--
-- ## Nebenwirkungen
--
-- Frühe Hilfe vor Fachprüfung. Öffentliche Vorschau prüft IncludeTriggers und reservierte #tbx_-Namen/sichtbare private Temps vor separatem Core-EXEC. Core normalisiert KeepData/DebugNULL zu0, prüft internen Zweck und DB-weites VIEW DEFINITION. Einzelmodus verlangt vier längengeprüfte unquotierte Identifierwerte; Mapmodus eine vorhandene lokale Temp mit genau fünf NOTNULL-Basisspalten,1..64 positiven eindeutigen Mapordinals, ohne Alias-/Computed-/Zusatztypen, vier EinzelargumenteNULL. SQL-Katalogidentifier unter DATABASE_DEFAULT, Scripttexte BIN2. Quell-/Zielsicht und Zielkollision prüfen; PREVIEW verlangt neue Ziele, COPY_FK bestehende eindeutige disjunkte Ziele.
--
-- Begrenzte gewöhnliche Tabellen: vorhandene Collations, NULLability, unterstützte Systemtypen, Computed/PERSISTED mit tabellenlokalen Dependencies, Defaults, trusted/enabled CHECK, PK/UQ, BTree-Indexkeys/Includes/Filter/Optionen/Filegroups. Keine CLR-/Aliastypen, gebundene Legacydefaults/-rules, Sparse/Filestream/Rowguid/Encryption/Masking/typedXML/generated/hidden, Spezial-/Memory-/Temporal-/Graph-/Ledger-/Replikations-/CDC-/External-/FileTabletabellen, Partition/Compression/Fulltext oder unsupported Index-/Constraintzustände. Definitionen wörtlich; keine allgemeine Definitionserfindung. IncludeIdentity=1 übernimmt nur Seed/Increment, niemals Zählerstand. Deterministische gehashte Constraint-/Indexnamen; kataloggleiche Kollision bricht ab statt umzubenennen.
--
-- PREVIEW beginnt mit sieben festen SESSION_OPTION-Zeilen, dann alle Tabellen, unterstützte Tabellenobjekte, optionale originale Extended Properties, gemappte FOREIGN_KEY-/Zustandszeilen und gegebenenfalls Trigger/Zustände. Map-FKs zeigen auf gemappte Ziele; ungemappte Referenzen nur bei explizitem KEEP im PREVIEW-Mapmodus, sonst Reject. Vorhandene relevante Properties bei IncludeExtendedProperties=0 führen zum Abbruch statt stillem Verlust; Opt-in rendert nur unterstützte Originalwerte/Owner, keine Toolbelt.-Ownershipmarker oder FK-/Triggerproperties. Diese bestehende fachliche Kopieroption ist kein eigener Installer-Metadatenspeicher. Originale Variantmetadaten einschließlich Stringlänge/Collation/Precision/Scale erhalten, feste DECLARE-plus-sp_addextendedproperty-Batches werden nur als Text ausgegeben.
--
-- Trigger-Opt-in kontrolliert Windows/Version, exakte Provider-/ScriptDombytes, CLR-Bindings, alle fünf Parameter und sämtliche Resultspalten der vier Parser-FTs, vorhandene SELECT-/Assembly-/Dependency-Sicht. Nur gewöhnliche sichtbare DML-Trigger ohne CLR/Verschlüsselung/EXECUTE AS/dynamischen EXEC-Body, keine externen/ungelösten/unmapped Tabellenreferenzen. AST/Tokenstrom muss Quell-UTF16 vollständig rekonstruieren. Scope-/CTE-/Alias-/inserted/deleted-Bindung und bytegenaue nicht überlappende Identifierfragmente umschreiben, Kommentare/Literale erhalten, Ergebnis erneut parsen; keine abhängigen Funktionen kopieren. Originale ANSI_NULLS/QUOTED_IDENTIFIER, Ereignisse, First/Last und Disabledzustand werden in Scriptbatches abgebildet. Diese DDL wird vom Planer nicht ausgeführt.
--
-- Vollständigen Plan und globale Quoten vor Ausgabe prüfen. Direktausgabe nach Ordinal ohne eigene fachliche Transaktion. Optionales ResultTable-Routing prüft genaue fünfparametrige Helper-Signatur und verwendet eigenen TX oder zufälligen Caller-Savepoint nur für Vorbereitung/INSERT, eigenen Commit beziehungsweise committablen Savepointrollback. Quellstrukturen während Planung stabil halten; keine spätere Drift-/Recoverygarantie. Debug>0 abstrakte Planmessage, gegebenenfalls Helperdiagnose.
--
-- ## Fehlerbehandlung
--
-- 53900 Argument/Zweck/Map,53901 Source-/Katalogsicht,53902 Ziel/Sicht/Kollision,53903 Unsupported/abweichende FKs,53904 deterministische Namekollision,53905 fehlende/inkohärente Definition,53906 Ressourcen,53907 Dependency/Parserbindung,53908 öffentlicher Namespace. Core übernimmt öffentliche53908-Guards nicht. Kein fachlicher Teilplan vor globaler Prüfung; Engine-/Parser-/Helperfehler original.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/DDL-/Copy-/Installerabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Keine Installations-/Rechteattestation; Vorschau ist kein Ausführungsauftrag, Hash ist keine Herkunftssignatur. Keine automatische Rechte-/Owner-/Konfigurationsänderung, Trustvorbereitung oder externe Kopie. Reale Kataloge, Definitionen, DB-Identitäten, Hashkontexte und Nutzdaten privat halten.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_metadata' AS sysname) AS SchemaName,
            CAST(N'USP_ScriptTableClone' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'Ordinal', N'int', 1, 0, NULL, CAST(N'1-basiert lückenlos; Ausführung ausschließlich außerhalb dieser API.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ObjectKind', N'varchar(32)', 1, 0, NULL, CAST(N'SESSION_OPTION, TABLE, DEFAULT, CHECK, PRIMARY_KEY, UNIQUE_CONSTRAINT, INDEX, EXTENDED_PROPERTY, FOREIGN_KEY, FOREIGN_KEY_STATE sowie beim Trigger-Opt-in TRIGGER und TRIGGER_STATE.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'TargetName', N'nvarchar(776)', 1, 0, NULL, CAST(N'Gequoteter Zielname; Indexnamen mit Zieltabellenqualifier.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ScriptText', N'nvarchar(max)', 1, 0, NULL, CAST(N'Eine Anweisung; EXTENDED_PROPERTY ist ein typisierter DECLARE-plus-EXEC-Batch, TRIGGER ein fester Quell-SET-plus-sp_executesql-Batch mit innerem CREATE zuerst. Sieben SET-Zeilen zuerst; Latin1_General_100_BIN2.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'53900 Argumente,53901 Quelle/Sichtbarkeit,53902 Ziel/Sichtbarkeit,53903 Unsupported,53904 Namekollision,53905 Definitionen,53906 Ressourcen,53907 Dependency,53908 Namespace.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Computed/PERSISTED und Filter unterstützt; W1 ohne FK, W2 mit begrenzten FK-Zuständen. Trigger-Opt-in ohne dynamischen Body, EXECUTE AS, CLR, Verschlüsselung oder externe/unklare Referenzen; kein Kopieren von Funktionen/Prozeduren. Quelle während Planung strukturell stabil halten. Kein späterer Drift-/Kapazitätsnachweis.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE plus datenbankweite VIEW DEFINITION für vollständige FK-/Kollisionssicht; Computed und Trigger-Opt-in zusätzlich vorhandenes SELECT sys.sql_expression_dependencies. Trigger-Opt-in verlangt vollständige Assembly-/Binding-Sicht und SELECT auf vier Parser-TVFs. ResultTable zusätzlich Helper-EXECUTE. Keine Rechteausweitung.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetische Vorschau.' AS nvarchar(max)), CAST(N'EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N''dbo'',@SourceTable=N''SyntheticSource'',@TargetSchema=N''dbo'',@TargetTable=N''SyntheticClone'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@SourceSchema', N'nvarchar(max)', 1, 1, N'NULL', CAST(N'Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@SourceTable', N'nvarchar(max)', 1, 1, N'NULL', CAST(N'Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@TargetSchema', N'nvarchar(max)', 1, 1, N'NULL', CAST(N'Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@TargetTable', N'nvarchar(max)', 1, 1, N'NULL', CAST(N'Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@IncludeIdentity', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@IncludeExtendedProperties', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@TableMap', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@ExternalReferenceRule', N'varchar(16)', 0, 0, N'''REJECT''', CAST(N'Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@IncludeTriggers', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt vorhandene Trigger ab (Default); 1 rendert unterstützte gewöhnliche gemappte DML-Trigger im genehmigten Script-only-Pfad. Erfordert Windows SQL2019/2022/2025 und exakt vorhandene qualifizierte Parserbindung. Kein freies Rewrite beliebiger Trigger, keine Ausführung und keine automatische Parserinstallation. NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_metadata' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ScriptTableClone' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-metadata-usp-scripttableclone"
description: "Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch."
skill_format_version: "1.0"
module_id: "toolbelt.metadata.table-clone"
schema_name: "toolbelt_metadata"
object_name: "USP_ScriptTableClone"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@SourceSchema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@SourceTable", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@TargetSchema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische N' AS nvarchar(max)) + N'amensableitung."}, {"name": "@TargetTable", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@IncludeIdentity", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen."}, {"name": "@IncludeExtendedProperties", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern."}, {"name": "@TableMap", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalte' + N'n. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen."}, {"name": "@ExternalReferenceRule", "sql_type": "varchar(16)", "sql_default": "''REJECT''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig."}, {"name": "@IncludeTriggers", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt vorhandene Trigger ab (Default); 1 rendert unterstützte gewöhnliche gemappte DML-Trigger im genehmigten Script-only-Pfad. Erfordert Windows SQL2019/2022/2025 und exakt vorhandene qualifizierte Parserbindung. Kein freies Rewrite beliebiger Trigger, keine Ausführung und keine automatische Parserinstallation. NULL ungültig."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine glo' + N'bale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql"]
review_status: "verified"
source_module_version: "4.1.1"
---

# USP_ScriptTableClone

## Zweck und Einsatzfälle

Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.

## Voraussetzungen

Modul4.1.1 in der tatsächlich ausgewählten Installationsdatenbank; ausschließlich SameDB-Quell-/Zielobjekte. Ein dreiteiliger zentraler Prozeduraufruf verlegt die Quellobjekte nicht in die C' + N'aller-Datenbank. Bestehender ResultTable-Helper>=1.0.0. Basisplanung/Executor/Copy sind TSQL auf Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Trigger-Opt-in ist gesondert Windows-only mit bereits vorhandenem exakt gebundenem Parser2.0.1 und vier Parser-TVFs; kein Nachinstallieren.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@SourceSchema` | `nvarchar(max)` | `NULL` | Input | Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@SourceTable` | `nvarchar(max)` | `NULL` | Input | Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetSchema` | `nvarchar(max)` | `NULL` | Input | Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetTable` | `nvarchar(max)` | `NULL` | Input | Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@IncludeIden' + N'tity` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen. |
| `@IncludeExtendedProperties` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern. |
| `@TableMap` | `sysname` | `NULL` | Input | NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen. |
| `@ExternalReferenceRule` | `varchar(16)` | `''REJECT''` | Input | Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig. |
| `@IncludeTriggers` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt v' + N'orhandene Trigger ab (Default); 1 rendert unterstützte gewöhnliche gemappte DML-Trigger im genehmigten Script-only-Pfad. Erfordert Windows SQL2019/2022/2025 und exakt vorhandene qualifizierte Parserbindung. Kein freies Rewrite beliebiger Trigger, keine Ausführung und keine automatische Parserinstallation. NULL ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

## Ergebnisse

| Spalte | SQL-Typ | NULL | Bedeutung |
|---|---|---|---|
| `Ordinal` | `int` | nein | 1-basiert/lückenlos; COPY_FK kann nullZeilen liefern |
| `ObjectKind` | `varchar(32)` | nein | Planart |
| `TargetName` | `nvarchar(776)` | nein | gequoteter Zielname |
| `ScriptText` | `nvarchar(max)` | nein | vollständiger Batchtext,keine Ausführung |

' + N'ResultTableNULL direkte Fachausgabe, sonst Routing in vorhandene lokale Caller-#Temp. Plantexte/Resultshape Latin1_General_100_BIN2. Hilfe: bisherige zwölfspaltige Standardhilfe plus genau eine Skillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühe Rückkehr ohne Fachprüfung oder Mutation. Öffentliche Planner-/Execute-/Copy-Hilfe RETURN0; interne Corehilfe behält ihr ursprüngliches RETURN; unverändert. Kein zusätzliches Fachresultset bei Zielrouting.

## Aufrufbeispiele

```sql
EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;
-- Vorhandene synthetische Quelle und freies Ziel in dieser DB vorausgesetzt.
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N''dbo'',@SourceTable=N''ContosoSource'',
 @TargetSchema=N''dbo'',@TargetTable=N''ContosoClone'';
```

## Rechte

Vorhandenes EXECUTE auf öffentliche Vorschau/benötigte Ownershipchain, DB-weites VIEW DEFINITION für vollständige FK-/Kollisionssicht, sichtbare Quelle und Zielschema mit deren VIEW DEFINITION. Computed zusätzlich SELECT sys.sql_expression_dependencies. Trigger-Opt-in zusätzlich SELECT sys.assembly_files/sys.assembly_modules/sys.sql_expression_dependencies und vier Parser-TVFs sowie vollständig sichtbare exakt gebundene Parserassemblies. Keine Source-Daten-SELECT- oder Ziel-DDL-Rechte allein für Vorschau. Bei ResultTable Helper-EXECUTE und Caller-Temp-DDL/Schreibrechte.

## Ressourcenbedarf

Planner:Map1..64,jeQuelle<=1024Spalten/128Indizes/2048Childobjekte,globale Childobjekt-plus-FK-Spaltentupelquote2048. Definitions-/minimaler Outputpreflight und tatsächliche globale Scripttextquote2097152UTF16Bytes. Properties:Payload<=7500Bytes,Varianttotal<=8016;Stringmetadaten rekonstruierbar. Trigger zusätzlich vier atomare Parserresultate und erneute Fehlerprüfung mit Input2097152/ASTTiefe100, tatsächliche Parserguardgrenzen bleiben erhalten. PrivateTemp-/LOB-/AST-/Token-/Scriptkopien und Katalogcursor kosten CPU/Tempdb; kein hartes Wallclock-/Peak-/Pr' + N'oduktionskapazitätsversprechen.

## Nebenwirkungen

Frühe Hilfe vor Fachprüfung. Öffentliche Vorschau prüft IncludeTriggers und reservierte #tbx_-Namen/sichtbare private Temps vor separatem Core-EXEC. Core normalisiert KeepData/DebugNULL zu0, prüft internen Zweck und DB-weites VIEW DEFINITION. Einzelmodus verlangt vier längengeprüfte unquotierte Identifierwerte; Mapmodus eine vorhandene lokale Temp mit genau fünf NOTNULL-Basisspalten,1..64 positiven eindeutigen Mapordinals, ohne Alias-/Computed-/Zusatztypen, vier EinzelargumenteNULL. SQL-Katalogidentifier unter DATABASE_DEFAULT, Scripttexte BIN2. Quell-/Zielsicht und Zielkollision prüfen; PREVIEW verlangt neue Ziele, COPY_FK bestehende eindeutige disjunkte Ziele.

Begrenzte gewöhnliche Tabellen: vorhandene Collations, NULLability, unterstützte Systemtypen, Computed/PERSISTED mit tabellenlokalen Dependencies, Defaults, trusted/enabled CHECK, PK/UQ, BTree-Indexkeys/Includes/Filter/Optionen/Filegroups. Keine CLR-/Aliastypen, gebundene Legacydefaults/-rules, Sparse/Filestream/Rowguid/Encryption/Masking/typedXML/generated/hidden, Spezial-/Memory-/Temporal-/Graph-/Ledger-/Replikations-/CDC-/External-/FileTabletabellen, Partition/Compression/Fulltext oder unsupported Index-/Constraintzustände. Definitionen wörtlich; keine allgemeine Definitionserfindung. IncludeIdentity=1 übernimmt nur Seed/Increment, niemals Zählerstand. Deterministische gehashte Constraint-/Indexnamen; kataloggleiche Kollision bricht ab statt umzubenennen.

PREVIEW beginnt mit sieben festen SESSION_OPTION-Zeilen, dann alle Tabellen, unterstützte Tabellenobjekte, optionale originale Extended Properties, gemappte FOREIGN_KEY-/Zustandszeilen und gegebenenfalls Trigger/Zustände. Map-FKs zeigen auf gemappte Ziele; ungemappte Referenzen nur bei explizitem KEEP im PREVIEW-Mapmodus, sonst Reject. Vorhandene relevante Properties bei IncludeExtendedProperties=0 führen zum Abbruch statt stillem Verlust; Opt-in rendert nur unterstützte Originalwerte/Owner, keine Too' + N'lbelt.-Ownershipmarker oder FK-/Triggerproperties. Diese bestehende fachliche Kopieroption ist kein eigener Installer-Metadatenspeicher. Originale Variantmetadaten einschließlich Stringlänge/Collation/Precision/Scale erhalten, feste DECLARE-plus-sp_addextendedproperty-Batches werden nur als Text ausgegeben.

Trigger-Opt-in kontrolliert Windows/Version, exakte Provider-/ScriptDombytes, CLR-Bindings, alle fünf Parameter und sämtliche Resultspalten der vier Parser-FTs, vorhandene SELECT-/Assembly-/Dependency-Sicht. Nur gewöhnliche sichtbare DML-Trigger ohne CLR/Verschlüsselung/EXECUTE AS/dynamischen EXEC-Body, keine externen/ungelösten/unmapped Tabellenreferenzen. AST/Tokenstrom muss Quell-UTF16 vollständig rekonstruieren. Scope-/CTE-/Alias-/inserted/deleted-Bindung und bytegenaue nicht überlappende Identifierfragmente umschreiben, Kommentare/Literale erhalten, Ergebnis erneut parsen; keine abhängigen Funktionen kopieren. Originale ANSI_NULLS/QUOTED_IDENTIFIER, Ereignisse, First/Last und Disabledzustand werden in Scriptbatches abgebildet. Diese DDL wird vom Planer nicht ausgeführt.

Vollständigen Plan und globale Quoten vor Ausgabe prüfen. Direktausgabe nach Ordinal ohne eigene fachliche Transaktion. Optionales ResultTable-Routing prüft genaue fünfparametrige Helper-Signatur und verwendet eigenen TX oder zufälligen Caller-Savepoint nur für Vorbereitung/INSERT, eigenen Commit beziehungsweise committablen Savepointrollback. Quellstrukturen während Planung stabil halten; keine spätere Drift-/Recoverygarantie. Debug>0 abstrakte Planmessage, gegebenenfalls Helperdiagnose.

## Fehlerbehandlung

53900 Argument/Zweck/Map,53901 Source-/Katalogsicht,53902 Ziel/Sicht/Kollision,53903 Unsupported/abweichende FKs,53904 deterministische Namekollision,53905 fehlende/inkohärente Definition,53906 Ressourcen,53907 Dependency/Parserbindung,53908 öffentlicher Namespace. Core übernimmt öffentliche53908-Guards nicht. Kein fachlicher Teilplan vor globaler Prüfung; Engine-/Parser-/Helperfehler' + N' original.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/DDL-/Copy-/Installerabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Keine Installations-/Rechteattestation; Vorschau ist kein Ausführungsauftrag, Hash ist keine Herkunftssignatur. Keine automatische Rechte-/Owner-/Konfigurationsänderung, Trustvorbereitung oder externe Kopie. Reale Kataloge, Definitionen, DB-Identitäten, Hashkontexte und Nutzdaten privat halten.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    IF @IncludeTriggers IS NULL
        THROW 53900,N'TableClone: IncludeTriggers darf im Fachmodus nicht NULL sein.',10;
    -- Grenze VOR Kompilierung des Kerns: CI-tempdb darf CS-Callerobjekte nicht eclipsen.
    IF LOWER(LEFT(@TableMap,5)) COLLATE Latin1_General_100_BIN2=N'#tbx_' OR LOWER(LEFT(@ResultTable,5)) COLLATE Latin1_General_100_BIN2=N'#tbx_'
        THROW 53908,N'TableClone: reservierter interner Tempnamespace ist kein Caller-Ziel.',1;
    IF EXISTS(SELECT 1 FROM (VALUES(N'#tbx_TableClone_Plan'),(N'#tbx_TableClone_Map'),(N'#tbx_TableClone_Order'),(N'#tbx_TableClone_Names'),(N'#tbx_TableClone_EpOwners'),
        (N'#tbx_TableClone_AstNodes'),(N'#tbx_TableClone_AstProperties'),(N'#tbx_TableClone_AstTokens'),(N'#tbx_TableClone_AstErrors')) names(Name) WHERE OBJECT_ID(N'tempdb..'+Name,N'U') IS NOT NULL)
        THROW 53908,N'TableClone: reservierter interner Tempnamespace ist im Caller belegt.',1;
    EXEC toolbelt_metadata.USP_ScriptTableCloneInternal
        @SourceSchema=@SourceSchema,@SourceTable=@SourceTable,@TargetSchema=@TargetSchema,
        @TargetTable=@TargetTable,@IncludeIdentity=@IncludeIdentity,@IncludeExtendedProperties=@IncludeExtendedProperties,
        @TableMap=@TableMap,@ExternalReferenceRule=@ExternalReferenceRule,@IncludeTriggers=@IncludeTriggers,@InternalPurpose='PREVIEW',
        @ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug,@Hilfe=0;
END;
GO
