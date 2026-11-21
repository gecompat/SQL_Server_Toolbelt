-- Interner Ausgabekern hinter der öffentlichen Compilergrenze.
-- Parameter/Caller-Shapes/alle privaten Tempnamen validiert ausschließlich
-- die Fassade vor diesem Aufruf. Keine direkten Caller-Grants auf den Core.
-- Kanonisches Mapping, Materialisierung, Transaktion und ResultTable-Routing
-- existieren genau einmal hier; der eigene Hilfezweig liegt vor dem Fachpfad.
CREATE OR ALTER PROCEDURE [toolbelt_pseudonymization].[USP_DeterministicLookupCore]
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
    , @InputObjectId int = NULL
    , @LookupObjectId int = NULL
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-usp-deterministiclookupcore"
-- description: "Interner Materialisierungs- und Routingkern hinter der Lookup-Compilergrenze."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.pseudonymization.deterministic"
-- schema_name: "toolbelt_pseudonymization"
-- object_name: "USP_DeterministicLookupCore"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@InputTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Key varbinary(max): NULL wird als NULL-Ergebnis weitergeführt, sonst 1..8000 Bytes. Leere Eingabe zulässig. Kein ResultTable-Identitätsoverlap."}, {"name": "@LookupTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Value nvarchar(max), auch NULL/leer ist als Poolwert zulässig. Pool muss mindestens eine Zeile enthalten. Auswahlposition folgt der Ordinalsortierung, nicht dem konkreten lückenhaften Ordinalwert. Nicht dieselbe tatsächliche Tabelle wie ResultTable."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive int-Kontextversion 1..2147483647; NULL/0/negativ wirft 54000. Zusammen mit Seed und LookupVersion deterministischer Mappingkontext."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Jeder nicht-NULL-bigint im gesamten 64-Bit-Bereich, Default 0; NULL wirft 54000. Deterministischer Variantenkontext, kein Secret/Zufallsaufruf."}, {"name": "@LookupVersion", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-Poolversion 1..9223372036854775807; NULL/0/negativ wirft 54000. Caller muss sie bei Pooländerungen ändern; keine automatische Hash-/Versionsableitung."}, {"name": "@MaxInputRows", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..100000 Inputzeilen, Default 10000; NULL/außerhalb ungültig. Kein Teilresultat bei Überschreitung."}, {"name": "@MaxLookupRows", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..100000 Poolzeilen, Default 10000; NULL/außerhalb ungültig. Pool muss unabhängig davon nicht leer sein."}, {"name": "@MaxLookupTextBytes", "sql_type": "bigint", "sql_default": "2097152", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..16777216 Bytes als Summe DATALENGTH(Value) im Pool, Default 2097152; NULL-Werte zählen 0. NULL/außerhalb beim Budget ungültig."}, {"name": "@MaxResultBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..16777216 Bytes als Summe DATALENGTH der zugeordneten Ergebniswerte, Default 16777216. Wiederholte Poolwerte zählen pro Ergebniszeile erneut; NULL zählt 0. NULL/außerhalb ungültig."}, {"name": "@InputObjectId", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Von öffentlicher Fassade vorab ermittelte tempdb-Objekt-ID für Diagnose. Im Core nicht erneut zur Autorisierung oder Namensbindung geprüft. Fachlich gebundener nichtNULL-Wert,technischerNULL-Helpdefault."}, {"name": "@LookupObjectId", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Von öffentlicher Fassade vorab ermittelte Pool-Objekt-ID für Diagnose; kein eigenständiger Sicherheitsguard im Core."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf keine der beiden Eingabetabellen sein."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0, NULL wirkt wie 0: 0 still; 1 Phasenmessages; 2 zusätzlich Zeilen-/Bytezahlen; 3..255 zusätzlich Temp-Objektmetadaten. Keine Keys, Werte, Seeds oder Hashes; bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookupCore.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRangeCore.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookup.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.2.0"
-- public_entrypoints: ["toolbelt_pseudonymization.USP_DeterministicLookup"]
-- ---
--
-- # USP_DeterministicLookupCore
--
-- ## Zweck und Einsatzfälle
--
-- Interner Materialisierungs- und Routingkern hinter der Lookup-Compilergrenze. Kein eigener öffentlicher Fachaufrufweg.
--
-- ## Voraussetzungen
--
-- Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Eigene Caller-Temps ohne parallele Mutation; Fassade vor Core verwenden. Ein gesunder Caller-TX mit Savepoint ist möglich. Kein eigener Reparaturvertrag für doomed Caller-TX.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@InputTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Key varbinary(max): NULL wird als NULL-Ergebnis weitergeführt, sonst 1..8000 Bytes. Leere Eingabe zulässig. Kein ResultTable-Identitätsoverlap. |
-- | `@LookupTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Value nvarchar(max), auch NULL/leer ist als Poolwert zulässig. Pool muss mindestens eine Zeile enthalten. Auswahlposition folgt der Ordinalsortierung, nicht dem konkreten lückenhaften Ordinalwert. Nicht dieselbe tatsächliche Tabelle wie ResultTable. |
-- | `@MappingVersion` | `int` | `NULL` | Input | Fachlich erforderliche positive int-Kontextversion 1..2147483647; NULL/0/negativ wirft 54000. Zusammen mit Seed und LookupVersion deterministischer Mappingkontext. |
-- | `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint im gesamten 64-Bit-Bereich, Default 0; NULL wirft 54000. Deterministischer Variantenkontext, kein Secret/Zufallsaufruf. |
-- | `@LookupVersion` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-Poolversion 1..9223372036854775807; NULL/0/negativ wirft 54000. Caller muss sie bei Pooländerungen ändern; keine automatische Hash-/Versionsableitung. |
-- | `@MaxInputRows` | `int` | `10000` | Input | Ganzzahl 1..100000 Inputzeilen, Default 10000; NULL/außerhalb ungültig. Kein Teilresultat bei Überschreitung. |
-- | `@MaxLookupRows` | `int` | `10000` | Input | Ganzzahl 1..100000 Poolzeilen, Default 10000; NULL/außerhalb ungültig. Pool muss unabhängig davon nicht leer sein. |
-- | `@MaxLookupTextBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 Bytes als Summe DATALENGTH(Value) im Pool, Default 2097152; NULL-Werte zählen 0. NULL/außerhalb beim Budget ungültig. |
-- | `@MaxResultBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 Bytes als Summe DATALENGTH der zugeordneten Ergebniswerte, Default 16777216. Wiederholte Poolwerte zählen pro Ergebniszeile erneut; NULL zählt 0. NULL/außerhalb ungültig. |
-- | `@InputObjectId` | `int` | `NULL` | Input | Von öffentlicher Fassade vorab ermittelte tempdb-Objekt-ID für Diagnose. Im Core nicht erneut zur Autorisierung oder Namensbindung geprüft. Fachlich gebundener nichtNULL-Wert,technischerNULL-Helpdefault. |
-- | `@LookupObjectId` | `int` | `NULL` | Input | Von öffentlicher Fassade vorab ermittelte Pool-Objekt-ID für Diagnose; kein eigenständiger Sicherheitsguard im Core. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf keine der beiden Eingabetabellen sein. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0, NULL wirkt wie 0: 0 still; 1 Phasenmessages; 2 zusätzlich Zeilen-/Bytezahlen; 3..255 zusätzlich Temp-Objektmetadaten. Keine Keys, Werte, Seeds oder Hashes; bei ResultTable zusätzlich Helperdiagnose. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
--
-- Alle technischen Defaults dienen auch der frühen Hilfe; fachliche Pflichtwerte bleiben erforderlich. Core-Objekt-IDs sind Diagnosebindungen,kein weiterer Sicherheitsnachweis.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `InputOrdinal` | `bigint` | NOT NULL;je Inputordinal |
-- | `LookupOrdinal` | `bigint` | NULL beiNULLKey,sonst gewählter tatsächlicher Poolordinal |
-- | `Value` | `nvarchar(max)` | Latin1_General_100_BIN2;Poolwert unverändert,auchNULL/leer |
--
-- Direkte Ausgabe geordnet InputOrdinal oder geroutet in lokales ResultTable,ohne zusätzlichen Fachresultset. Je Input genau eine Zuordnung;leererInput nullZeilen,leererPool Fehler. Hilfe liefert bisherige zwölfspaltige Standardhilfe plus genau eine Skillzeile:SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). FrüherHelp- und normalerReturn0. Beide Prozeduren haben eigene frühe Hilfe; kein delegierter fachlicher Corelauf im Hilfepfad.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Interner Helfer: öffentlichen Einstieg verwenden.
-- EXEC toolbelt_pseudonymization.USP_DeterministicLookupCore @Hilfe=1;
-- EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1;
-- CREATE TABLE #ContosoInput(Ordinal bigint,[Key] varbinary(max));
-- CREATE TABLE #ContosoPool(Ordinal bigint,[Value] nvarchar(max));
-- INSERT #ContosoInput VALUES(1,0x010203),(2,NULL);
-- INSERT #ContosoPool VALUES(10,N'Contoso alpha'),(30,N'Contoso beta');
-- EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#ContosoInput',@LookupTable=N'#ContosoPool',@MappingVersion=1,@LookupVersion=1;
-- DROP TABLE #ContosoInput;DROP TABLE #ContosoPool;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Lookup-Fassade, bei ResultTable zusätzlich Helper-EXECUTE. Caller muss seine eigenen #Temps lesen können und deren Metadaten über tempdb.sys.columns sehen. Die optionale Helperschnittstelle wird über sys.parameters geprüft. Dynamisches SQL greift nur auf QUOTENAME-gebundene Caller-Temps zu; der interne Rangeaufruf ist statisch für die reguläre Ownership-Chain. Keine direkten Fachcallergrants auf den Core. Zentrale Dreiteilnamen brauchen gültigen Datenbankzugriff und Identitätsmapping. Tatsächliche Ownership-Chains und Objektrechte bleiben maßgeblich.
--
-- ## Ressourcenbedarf
--
-- Input und Pool sind auf je 1..100000 Zeilen begrenzt. Textbudgets je 1..16777216 Bytes, Pooldefault2097152, Ergebnisdefault16777216. MaxInputRows*8000 begrenzt private Keynutzdaten, nicht Peak-RAM. TOP(limit+1)-Preflight erfolgt vor privater LOB-Kopie. Gruppierungen, Sortierungen, TABLOCK/HOLDLOCK, tempdb, Log und die Locklebensdauer im Caller-TX verursachen weiterhin Aufwand. Keine harte Zeit-, CPU- oder Gesamtheapquote.
--
-- ## Nebenwirkungen
--
-- Die öffentliche Fassade normalisiert KeepData/Debug/HilfeNULL zu0 und liefert frühe Hilfe. Danach positive MappingVersion/LookupVersion,nichtNULL Seed und Ressourcenlimits prüfen. Caller-lokale #Tabellennamen sichtbar,einzeln QUOTENAME-gebunden,höchstens116UTF-16-Einheiten,kein ## oder case-insensitives #tbx_-Präfix. tempdb.sys.columns muss bytegenaue Basisspalten ohne Alias-/Computedtyp zeigen: Input Ordinal bigint/Key varbinary(max),Pool Ordinal bigint/Value nvarchar(max); Zusatzspalten zulässig. ResultTable darf nicht mit einer Eingabetabelle identisch sein. Vier reservierte private #tbx_DeterministicLookup_-Namen dürfen noch nicht sichtbar sein. Erst danach genau ein Aufruf des Kerns hinter eigener Compilergrenze. Die beiden Eingabe-Objekt-IDs dienen dort nur Diagnose,keiner erneuten Autorisierung. Nicht direkt am Core vorbei aufrufen.
--
-- Core: eigene Transaktion oder zufällig benannter Savepoint im Caller-TX. Keine eigene XACT_ABORT-Umschaltung; doomed/distributed Caller können an Engine-/Savepointregeln scheitern. TOP(limit+1)-Preflight zählt Input/Pool,prüft positive/eindeutige Ordinals und nichtNULL Keys1..8000Bytes; leerer Pool unzulässig,leerer Input zulässig. TABLOCK/HOLDLOCK hält einen stabilen Lesescope,unter Caller-TX bis dessen Abschluss. Pooltextsumme vor privater Textkopie prüfen. Pool nach Ordinal ordnen und lückenlose PoolPosition bilden; danach begrenzte Keykopie. Statischer RangeCore-Aufruf mit DomainTBXDLKP1,ContextLookupVersion und Bereich1..PoolCount erhält reguläre Ownership-Chain. NULLKey ergibt NULL-Zuordnung. Map vollständig prüfen und private Keykopie sofort droppen. Ergebnistextsumme zählt wiederholte Pooltexte je Input erneut. Erst danach Value-LOBs in eigene Ergebnistabelle kopieren.
--
-- Optionales ResultTable: bestehende fünfparametrige PrepareResultTable-Schnittstelle im Katalog exakt prüfen,vorbereiten und alle Ergebniszeilen innerhalb derselben Transaktion einfügen. Eigener COMMIT beziehungsweise Caller-TX erhalten,erst danach direkterSELECT geordnet InputOrdinal. Im CATCH eigener ROLLBACK oder committable eigener Savepointrollback. Keine erfolgreiche Teilausgabe. Debug1 Phasen,2 zusätzlich Zeilen/Bytes,3..255 zusätzlich Temp-Objekt-IDs; keine Keys/Values/Seed-/Hashausgabe. Der Code besitzt keine persistent gespeicherte Poolhistorie oder Driftprüfung; Caller muss LookupVersion bei Pooländerung pflegen.
--
-- ## Fehlerbehandlung
--
-- THROW54000 Konfiguration;54001 ungültige Limits oder Input-/Poolzeilengrenze;54002 fehlende/unzulässige Tabellen,Shape oder ResultTable-Overlap;54003 unzulässige/duplizierte Ordinals;54004 Keybreite;54005 leererPool;54006 Pool-/Ergebnistextsumme;54007 Range-Mappingfehler;54008 fehlende/abweichende ResultTable-Schnittstelle;54009 reservierter privater Tempname sichtbar. Engine-/Lock-/Savepoint-/Rollback-/Binderfehler unverändert. Keine automatische Wiederholung oder erfolgreiche Teilausgabe. Direkte Coreaufrufe durchlaufen die Fassadenprüfungen nicht und sind kein freigegebener Fachvertrag. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0),@Hilfe=COALESCE(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        DECLARE @Help TABLE(HelpContractVersion varchar(16),SchemaName sysname,ObjectName sysname,Section varchar(32),Ordinal int,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max),ExampleSql nvarchar(max) NULL);
        INSERT @Help VALUES
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Interner Materialisierungskern der öffentlichen DeterministicLookup-Fassade; prüft und verarbeitet ausschließlich deren gebundene Caller-Temp-Tabellen.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',1,N'@InputTable','sysname',1,0,N'NULL',N'Gebundene caller-lokale Eingabetabelle mit Ordinal bigint und Key varbinary(max).',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',2,N'@LookupTable','sysname',1,0,N'NULL',N'Gebundene caller-lokale Lookup-Tabelle mit Ordinal bigint und Value nvarchar(max).',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',3,N'@MappingVersion','int',1,0,N'NULL',N'Positive Mapping-Kontextversion.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',4,N'@Seed','bigint',0,0,N'0',N'Deterministischer Varianten-Seed.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',5,N'@LookupVersion','bigint',1,0,N'NULL',N'Explizite positive Poolversion.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',6,N'@MaxInputRows','int',0,0,N'10000',N'Positive Obergrenze für Eingabezeilen.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',7,N'@MaxLookupRows','int',0,0,N'10000',N'Positive Obergrenze für Lookup-Zeilen.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',8,N'@MaxLookupTextBytes','bigint',0,0,N'2097152',N'Gesamtbudget für Lookup-Text.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',9,N'@MaxResultBytes','bigint',0,0,N'16777216',N'Gesamtbudget für Ergebnistext.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',10,N'@InputObjectId','int',0,1,N'NULL',N'Vorab gebundene Eingabeobjekt-ID der öffentlichen Fassade.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',11,N'@LookupObjectId','int',0,1,N'NULL',N'Vorab gebundene Lookupobjekt-ID der öffentlichen Fassade.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',12,N'@ResultTable','sysname',0,1,N'NULL',N'Optionales caller-lokales ResultTable-Ziel.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',13,N'@KeepData','bit',0,0,N'0',N'0 Replace, 1 Append.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',14,N'@Debug','tinyint',0,0,N'0',N'Nur Metadatenmeldungen, keine Schlüssel oder Werte.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PARAMETER',15,N'@Hilfe','bit',0,0,N'0',N'1 liefert Hilfe vor fachlicher Prüfung oder Mutation.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','RESULT_COLUMN',1,N'InputOrdinal','bigint',1,0,NULL,N'Gebundener Eingabeordinal.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','RESULT_COLUMN',2,N'LookupOrdinal','bigint',1,1,NULL,N'Gewählter Lookupordinal; bei NULL-Key NULL.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','RESULT_COLUMN',3,N'Value','nvarchar(max)',1,1,NULL,N'Unveränderter Lookuptext; bei NULL-Key NULL.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','ERROR',1,N'54000-54009',NULL,NULL,NULL,NULL,N'Ungültige Konfiguration, Tabellen, Ordinals, Keys oder Budgets.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Kein direkter Callerzugriff; nur Aufruf über die öffentliche Fassade.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Interner Kern; keine eigenständige Mapping- oder Privacy-Zusage.',NULL),
        ('1.0',N'toolbelt_pseudonymization',N'USP_DeterministicLookupCore','EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Aufruf über die öffentliche Fassade mit eigenen lokalen Tabellen.',N'CREATE TABLE #Input(Ordinal bigint,[Key] varbinary(max)); CREATE TABLE #Pool(Ordinal bigint,[Value] nvarchar(max)); INSERT #Input VALUES(1,0x0102); INSERT #Pool VALUES(1,N''synthetic alpha''); EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N''#Input'',@LookupTable=N''#Pool'',@MappingVersion=1,@LookupVersion=1;');
        SELECT HelpContractVersion,SchemaName,ObjectName,Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
        FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_pseudonymization' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_DeterministicLookupCore' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-usp-deterministiclookupcore"
description: "Interner Materialisierungs- und Routingkern hinter der Lookup-Compilergrenze."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "USP_DeterministicLookupCore"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@InputTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Key varbinary(max): NULL wird als NULL-Ergebnis weitergeführt, sonst 1..8000 Bytes. Leere Eingabe zulässig. Kein ResultTable-Identitätsoverlap."}, {"name": "@LookupTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Value nvarchar(max), auch NULL/leer ist als Poolwert zulässig. Pool muss mindestens eine Zeile enthalten. Auswahlposition folgt der Ordinalsortierung, nicht dem konkreten lückenhaften Ordinalwert. Nicht dieselbe tatsächliche Tabelle wie ResultTable."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "null' AS nvarchar(max)) + N'able": false, "description": "Fachlich erforderliche positive int-Kontextversion 1..2147483647; NULL/0/negativ wirft 54000. Zusammen mit Seed und LookupVersion deterministischer Mappingkontext."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Jeder nicht-NULL-bigint im gesamten 64-Bit-Bereich, Default 0; NULL wirft 54000. Deterministischer Variantenkontext, kein Secret/Zufallsaufruf."}, {"name": "@LookupVersion", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-Poolversion 1..9223372036854775807; NULL/0/negativ wirft 54000. Caller muss sie bei Pooländerungen ändern; keine automatische Hash-/Versionsableitung."}, {"name": "@MaxInputRows", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..100000 Inputzeilen, Default 10000; NULL/außerhalb ungültig. Kein Teilresultat bei Überschreitung."}, {"name": "@MaxLookupRows", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..100000 Poolzeilen, Default 10000; NULL/außerhalb ungültig. Pool muss unabhängig davon nicht leer sein."}, {"name": "@MaxLookupTextBytes", "sql_type": "bigint", "sql_default": "2097152", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..16777216 Bytes als Summe DATALENGTH(Value) im Pool, Default 2097152; NULL-Werte zählen 0. NULL/außerhalb beim Budget ungültig."}, {"name": "@MaxResultBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ga' + N'nzzahl 1..16777216 Bytes als Summe DATALENGTH der zugeordneten Ergebniswerte, Default 16777216. Wiederholte Poolwerte zählen pro Ergebniszeile erneut; NULL zählt 0. NULL/außerhalb ungültig."}, {"name": "@InputObjectId", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Von öffentlicher Fassade vorab ermittelte tempdb-Objekt-ID für Diagnose. Im Core nicht erneut zur Autorisierung oder Namensbindung geprüft. Fachlich gebundener nichtNULL-Wert,technischerNULL-Helpdefault."}, {"name": "@LookupObjectId", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Von öffentlicher Fassade vorab ermittelte Pool-Objekt-ID für Diagnose; kein eigenständiger Sicherheitsguard im Core."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf keine der beiden Eingabetabellen sein."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argumen' + N't_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0, NULL wirkt wie 0: 0 still; 1 Phasenmessages; 2 zusätzlich Zeilen-/Bytezahlen; 3..255 zusätzlich Temp-Objektmetadaten. Keine Keys, Werte, Seeds oder Hashes; bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookupCore.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRangeCore.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookup.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.2.0"
public_entrypoints: ["toolbelt_pseudonymization.USP_DeterministicLookup"]
---

# USP_DeterministicLookupCore

## Zweck und Einsatzfälle

Interner Materialisierungs- und Routingkern hinter der Lookup-Compilergrenze. Kein eigener öffentlicher Fachaufrufweg.

## Voraussetzungen

Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Eigene Caller-Temps ohne parallele Mutation; Fassade vor Core verwenden. Ein gesunder Caller-TX mit Savepoint ist möglich. Kein eigener Reparaturvertrag für doomed Caller-TX.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |' + N'
|---|---|---|---|---|
| `@InputTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Key varbinary(max): NULL wird als NULL-Ergebnis weitergeführt, sonst 1..8000 Bytes. Leere Eingabe zulässig. Kein ResultTable-Identitätsoverlap. |
| `@LookupTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Value nvarchar(max), auch NULL/leer ist als Poolwert zulässig. Pool muss mindestens eine Zeile enthalten. Auswahlposition folgt der Ordinalsortierung, nicht dem konkreten lückenhaften Ordinalwert. Nicht dieselbe tatsächliche Tabelle wie ResultTable. |
| `@MappingVersion` | `int` | `NULL` | Input | Fachlich erforderliche positive int-Kontextversion 1..2147483647; NULL/0/negativ wirft 54000. Zusammen mit Seed und LookupVersion deterministischer Mappingkontext. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint im gesamten 64-Bit-Bereich, Default 0; NULL wirft 54000. Deterministischer Variantenkontext, kein Secret/Zufallsaufruf. |
| `@LookupVersion` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-Poolversion 1..9223372036854775807; NULL/0/negativ wirft 54000. Caller muss sie bei Pooländerungen ändern; keine automatische Hash-/Versionsableitung. |
| `@MaxInputRows` | `int` | `10000` | Input | Ganzzahl 1..100000 Inputzeilen, Default 10000; NULL/außerhalb ungültig. Kein Teilresultat bei Ü' + N'berschreitung. |
| `@MaxLookupRows` | `int` | `10000` | Input | Ganzzahl 1..100000 Poolzeilen, Default 10000; NULL/außerhalb ungültig. Pool muss unabhängig davon nicht leer sein. |
| `@MaxLookupTextBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 Bytes als Summe DATALENGTH(Value) im Pool, Default 2097152; NULL-Werte zählen 0. NULL/außerhalb beim Budget ungültig. |
| `@MaxResultBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 Bytes als Summe DATALENGTH der zugeordneten Ergebniswerte, Default 16777216. Wiederholte Poolwerte zählen pro Ergebniszeile erneut; NULL zählt 0. NULL/außerhalb ungültig. |
| `@InputObjectId` | `int` | `NULL` | Input | Von öffentlicher Fassade vorab ermittelte tempdb-Objekt-ID für Diagnose. Im Core nicht erneut zur Autorisierung oder Namensbindung geprüft. Fachlich gebundener nichtNULL-Wert,technischerNULL-Helpdefault. |
| `@LookupObjectId` | `int` | `NULL` | Input | Von öffentlicher Fassade vorab ermittelte Pool-Objekt-ID für Diagnose; kein eigenständiger Sicherheitsguard im Core. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf keine der beiden Eingabetabellen sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0, NULL wirkt wie 0: 0 still; 1 Phasenmessages; 2 zusätzlich Zeilen-/Bytezahlen; 3..255 zusätzlich Temp-Objektmetadaten. Keine Ke' + N'ys, Werte, Seeds oder Hashes; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Alle technischen Defaults dienen auch der frühen Hilfe; fachliche Pflichtwerte bleiben erforderlich. Core-Objekt-IDs sind Diagnosebindungen,kein weiterer Sicherheitsnachweis.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `InputOrdinal` | `bigint` | NOT NULL;je Inputordinal |
| `LookupOrdinal` | `bigint` | NULL beiNULLKey,sonst gewählter tatsächlicher Poolordinal |
| `Value` | `nvarchar(max)` | Latin1_General_100_BIN2;Poolwert unverändert,auchNULL/leer |

Direkte Ausgabe geordnet InputOrdinal oder geroutet in lokales ResultTable,ohne zusätzlichen Fachresultset. Je Input genau eine Zuordnung;leererInput nullZeilen,leererPool Fehler. Hilfe liefert bisherige zwölfspaltige Standardhilfe plus genau eine Skillzeile:SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). FrüherHelp- und normalerReturn0. Beide Prozeduren haben eigene frühe Hilfe; kein delegierter fachlicher Corelauf im Hilfepfad.

## Aufrufbeispiele

```sql
-- Interner Helfer: öffentlichen Einstieg verwenden.
EXEC toolbelt_pseudonymization.USP_DeterministicLookupCore @Hilfe=1;
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1;
CREATE TABLE #ContosoInput(Ordinal bigint,[Key] varbinary(max));
CREATE TABLE #ContosoPool(Ordinal bigint,[Value] nvarchar(max));
INSERT #ContosoInput VALUES(1,0x010203),(2,NULL);
INSERT #ContosoPool VALUES(10,N''Contoso alpha''),(30,N''Contoso beta'');
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N''#ContosoInput'',@LookupTable=N''#ContosoPool'',@MappingVersion=1,@LookupVersion=1;
DROP TABLE #ContosoInput;DROP TABLE #Contoso' + N'Pool;
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche Lookup-Fassade, bei ResultTable zusätzlich Helper-EXECUTE. Caller muss seine eigenen #Temps lesen können und deren Metadaten über tempdb.sys.columns sehen. Die optionale Helperschnittstelle wird über sys.parameters geprüft. Dynamisches SQL greift nur auf QUOTENAME-gebundene Caller-Temps zu; der interne Rangeaufruf ist statisch für die reguläre Ownership-Chain. Keine direkten Fachcallergrants auf den Core. Zentrale Dreiteilnamen brauchen gültigen Datenbankzugriff und Identitätsmapping. Tatsächliche Ownership-Chains und Objektrechte bleiben maßgeblich.

## Ressourcenbedarf

Input und Pool sind auf je 1..100000 Zeilen begrenzt. Textbudgets je 1..16777216 Bytes, Pooldefault2097152, Ergebnisdefault16777216. MaxInputRows*8000 begrenzt private Keynutzdaten, nicht Peak-RAM. TOP(limit+1)-Preflight erfolgt vor privater LOB-Kopie. Gruppierungen, Sortierungen, TABLOCK/HOLDLOCK, tempdb, Log und die Locklebensdauer im Caller-TX verursachen weiterhin Aufwand. Keine harte Zeit-, CPU- oder Gesamtheapquote.

## Nebenwirkungen

Die öffentliche Fassade normalisiert KeepData/Debug/HilfeNULL zu0 und liefert frühe Hilfe. Danach positive MappingVersion/LookupVersion,nichtNULL Seed und Ressourcenlimits prüfen. Caller-lokale #Tabellennamen sichtbar,einzeln QUOTENAME-gebunden,höchstens116UTF-16-Einheiten,kein ## oder case-insensitives #tbx_-Präfix. tempdb.sys.columns muss bytegenaue Basisspalten ohne Alias-/Computedtyp zeigen: Input Ordinal bigint/Key varbinary(max),Pool Ordinal bigint/Value nvarchar(max); Zusatzspalten zulässig. ResultTable darf nicht mit einer Eingabetabelle identisch sein. Vier reservierte private #tbx_DeterministicLookup_-Namen dürfen noch nicht sichtbar sein. Erst danach genau ein Aufruf des Kerns hinter eigener Compilergrenze. Die beiden Eingabe-Objekt-IDs dienen dort nur Diagnose,keiner erneuten Autorisierung. Nicht direkt am Core vorbei aufrufen.

Core: eigene Transaktion oder zufällig benannter Savepoint i' + N'm Caller-TX. Keine eigene XACT_ABORT-Umschaltung; doomed/distributed Caller können an Engine-/Savepointregeln scheitern. TOP(limit+1)-Preflight zählt Input/Pool,prüft positive/eindeutige Ordinals und nichtNULL Keys1..8000Bytes; leerer Pool unzulässig,leerer Input zulässig. TABLOCK/HOLDLOCK hält einen stabilen Lesescope,unter Caller-TX bis dessen Abschluss. Pooltextsumme vor privater Textkopie prüfen. Pool nach Ordinal ordnen und lückenlose PoolPosition bilden; danach begrenzte Keykopie. Statischer RangeCore-Aufruf mit DomainTBXDLKP1,ContextLookupVersion und Bereich1..PoolCount erhält reguläre Ownership-Chain. NULLKey ergibt NULL-Zuordnung. Map vollständig prüfen und private Keykopie sofort droppen. Ergebnistextsumme zählt wiederholte Pooltexte je Input erneut. Erst danach Value-LOBs in eigene Ergebnistabelle kopieren.

Optionales ResultTable: bestehende fünfparametrige PrepareResultTable-Schnittstelle im Katalog exakt prüfen,vorbereiten und alle Ergebniszeilen innerhalb derselben Transaktion einfügen. Eigener COMMIT beziehungsweise Caller-TX erhalten,erst danach direkterSELECT geordnet InputOrdinal. Im CATCH eigener ROLLBACK oder committable eigener Savepointrollback. Keine erfolgreiche Teilausgabe. Debug1 Phasen,2 zusätzlich Zeilen/Bytes,3..255 zusätzlich Temp-Objekt-IDs; keine Keys/Values/Seed-/Hashausgabe. Der Code besitzt keine persistent gespeicherte Poolhistorie oder Driftprüfung; Caller muss LookupVersion bei Pooländerung pflegen.

## Fehlerbehandlung

THROW54000 Konfiguration;54001 ungültige Limits oder Input-/Poolzeilengrenze;54002 fehlende/unzulässige Tabellen,Shape oder ResultTable-Overlap;54003 unzulässige/duplizierte Ordinals;54004 Keybreite;54005 leererPool;54006 Pool-/Ergebnistextsumme;54007 Range-Mappingfehler;54008 fehlende/abweichende ResultTable-Schnittstelle;54009 reservierter privater Tempname sichtbar. Engine-/Lock-/Savepoint-/Rollback-/Binderfehler unverändert. Keine automatische Wiederholung oder erfolgreiche Teilausgabe. Direkte Coreaufrufe ' + N'durchlaufen die Fassadenprüfungen nicht und sind kein freigegebener Fachvertrag. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
    END;
    DECLARE @OwnTransaction bit = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END,
        @SavepointSet bit = 0, @Savepoint varchar(32) = REPLACE(CONVERT(varchar(36),NEWID()),'-',''),
        @Sql nvarchar(max), @InputCount bigint, @PoolCount bigint, @PoolBytes bigint,
        @BadOrdinal bit, @BadKey bit, @DuplicateOrdinal bit;
    BEGIN TRY
        IF @OwnTransaction = 1 BEGIN TRANSACTION;
        ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @SavepointSet = 1; END;
        -- Begrenzter Metadaten-Preflight vor jeder privaten Key/Value-LOB-Kopie.
        -- S/HOLDLOCK-Snapshot: reguläre Locks bleiben in Callertransaktionen bestehen.
        SET @Sql = N'SELECT @Count=COUNT_BIG(*),@BadOrdinal=COALESCE(MAX(CONVERT(tinyint,CASE WHEN Ordinal IS NULL OR Ordinal<=0 THEN 1 ELSE 0 END)),0),'
            + N'@BadKey=COALESCE(MAX(CONVERT(tinyint,CASE WHEN [Key] IS NOT NULL AND (DATALENGTH([Key])=0 OR DATALENGTH([Key])>8000) THEN 1 ELSE 0 END)),0) '
            + N'FROM (SELECT TOP (@Limit) Ordinal,[Key] FROM ' + QUOTENAME(@InputTable) + N' WITH(TABLOCK,HOLDLOCK)) AS bounded;';
        DECLARE @InputLimit int = @MaxInputRows + 1, @PoolLimit int = @MaxLookupRows + 1;
        EXEC sys.sp_executesql @Sql,N'@Limit int,@Count bigint OUTPUT,@BadOrdinal bit OUTPUT,@BadKey bit OUTPUT',
            @InputLimit,@InputCount OUTPUT,@BadOrdinal OUTPUT,@BadKey OUTPUT;
        IF @InputCount > @MaxInputRows THROW 54001, N'DeterministicLookup: Eingabezeilenlimit überschritten.', 2;
        SET @Sql = N'SELECT @Duplicate=CASE WHEN EXISTS(SELECT Ordinal FROM ' + QUOTENAME(@InputTable)
            + N' WITH(TABLOCK,HOLDLOCK) GROUP BY Ordinal HAVING COUNT_BIG(*)>1) THEN 1 ELSE 0 END;';
        EXEC sys.sp_executesql @Sql,N'@Duplicate bit OUTPUT',@DuplicateOrdinal OUTPUT;
        IF @BadOrdinal = 1 OR @DuplicateOrdinal = 1 THROW 54003, N'DeterministicLookup: Eingabeordinals müssen positiv/eindeutig sein.', 1;
        IF @BadKey = 1 THROW 54004, N'DeterministicLookup: Nicht-NULL Keys müssen 1..8000 Byte enthalten.', 1;
        SET @Sql = N'SELECT @Count=COUNT_BIG(*),@Bytes=COALESCE(SUM(CONVERT(bigint,DATALENGTH([Value]))),0),'
            + N'@BadOrdinal=COALESCE(MAX(CONVERT(tinyint,CASE WHEN Ordinal IS NULL OR Ordinal<=0 THEN 1 ELSE 0 END)),0) '
            + N'FROM (SELECT TOP (@Limit) Ordinal,[Value] FROM ' + QUOTENAME(@LookupTable) + N' WITH(TABLOCK,HOLDLOCK)) AS bounded;';
        EXEC sys.sp_executesql @Sql,N'@Limit int,@Count bigint OUTPUT,@Bytes bigint OUTPUT,@BadOrdinal bit OUTPUT',
            @PoolLimit,@PoolCount OUTPUT,@PoolBytes OUTPUT,@BadOrdinal OUTPUT;
        IF @PoolCount > @MaxLookupRows THROW 54001, N'DeterministicLookup: Poolzeilenlimit überschritten.', 3;
        SET @Sql = N'SELECT @Duplicate=CASE WHEN EXISTS(SELECT Ordinal FROM ' + QUOTENAME(@LookupTable)
            + N' WITH(TABLOCK,HOLDLOCK) GROUP BY Ordinal HAVING COUNT_BIG(*)>1) THEN 1 ELSE 0 END;';
        EXEC sys.sp_executesql @Sql,N'@Duplicate bit OUTPUT',@DuplicateOrdinal OUTPUT;
        IF @BadOrdinal = 1 OR @DuplicateOrdinal = 1 THROW 54003, N'DeterministicLookup: Poolordinals müssen positiv/eindeutig sein.', 2;
        IF @PoolCount = 0 THROW 54005, N'DeterministicLookup: leerer Pool ist ungültig.', 1;
        IF @PoolBytes > @MaxLookupTextBytes THROW 54006, N'DeterministicLookup: Pooltextbudget überschritten.', 1;
        IF @Debug >= 2
            RAISERROR(N'DeterministicLookup: InputRows=%I64d, PoolRows=%I64d, PoolTextBytes=%I64d.',10,1,@InputCount,@PoolCount,@PoolBytes) WITH NOWAIT;
        IF @Debug >= 3
            RAISERROR(N'DeterministicLookup: InputObjectId=%d, PoolObjectId=%d; private Mapping-/Resultshape getrennt; keine Key-/Value-Diagnose.',10,1,@InputObjectId,@LookupObjectId) WITH NOWAIT;

        CREATE TABLE #tbx_DeterministicLookup_Pool
        (PoolPosition bigint NOT NULL PRIMARY KEY, LookupOrdinal bigint NOT NULL, [Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
        SET @Sql = N'INSERT #tbx_DeterministicLookup_Pool(PoolPosition,LookupOrdinal,[Value]) '
            + N'SELECT ROW_NUMBER() OVER(ORDER BY Ordinal),Ordinal,[Value] FROM ' + QUOTENAME(@LookupTable) + N' WITH(TABLOCK,HOLDLOCK);';
        EXEC sys.sp_executesql @Sql;
        -- Dynamisches SQL liest ausschließlich Caller-Temps. Den Range-Kern
        -- statisch aufrufen, damit die reguläre gleichbesitzige Ownershipchain
        -- ohne zusätzliche SELECT-Rechte auf internen Objekten gilt. Die
        -- begrenzte Keykopie ist bewusst: höchstens MaxInputRows * 8000 Byte
        -- Nutzdaten, kein behauptetes Peak-RAM-Limit. Nach Mapping sofort lösen.
        CREATE TABLE #tbx_DeterministicLookup_Input
        (InputOrdinal bigint NOT NULL, [Key] varbinary(8000) NULL);
        SET @Sql = N'INSERT #tbx_DeterministicLookup_Input(InputOrdinal,[Key]) SELECT Ordinal,[Key] FROM '
            + QUOTENAME(@InputTable) + N' WITH(TABLOCK,HOLDLOCK);';
        EXEC sys.sp_executesql @Sql;
        CREATE TABLE #tbx_DeterministicLookup_Map
        (InputOrdinal bigint NOT NULL, LookupOrdinal bigint NULL, ErrorCode int NOT NULL);
        INSERT #tbx_DeterministicLookup_Map(InputOrdinal,LookupOrdinal,ErrorCode)
        SELECT input.InputOrdinal,pool.LookupOrdinal,mapped.ErrorCode
        FROM #tbx_DeterministicLookup_Input AS input
        CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicRangeCore
            (0x544258444C4B5031,@LookupVersion,input.[Key],@MappingVersion,@Seed,CONVERT(bigint,1),@PoolCount) AS mapped
        LEFT JOIN #tbx_DeterministicLookup_Pool AS pool ON pool.PoolPosition=mapped.Value;
        DROP TABLE #tbx_DeterministicLookup_Input;
        IF EXISTS (SELECT 1 FROM #tbx_DeterministicLookup_Map WHERE ErrorCode <> 0)
            THROW 54007, N'DeterministicLookup: Range-Sampling hat keinen vollständigen gültigen Mapping-Snapshot geliefert.', 1;
        DECLARE @ResultBytes bigint;
        SELECT @ResultBytes = COALESCE(SUM(CONVERT(bigint,DATALENGTH(pool.[Value]))),0)
        FROM #tbx_DeterministicLookup_Map AS mapped LEFT JOIN #tbx_DeterministicLookup_Pool AS pool ON pool.LookupOrdinal = mapped.LookupOrdinal;
        IF @ResultBytes > @MaxResultBytes THROW 54006, N'DeterministicLookup: Ergebnistextbudget überschritten.', 2;
        CREATE TABLE #tbx_DeterministicLookup_ResultSource
        (InputOrdinal bigint NOT NULL, LookupOrdinal bigint NULL, [Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
        INSERT #tbx_DeterministicLookup_ResultSource(InputOrdinal,LookupOrdinal,[Value])
        SELECT mapped.InputOrdinal,mapped.LookupOrdinal,pool.[Value]
        FROM #tbx_DeterministicLookup_Map AS mapped LEFT JOIN #tbx_DeterministicLookup_Pool AS pool ON pool.LookupOrdinal = mapped.LookupOrdinal;
        IF @Debug > 0 RAISERROR(N'DeterministicLookup: vollständig validierter Mapping-Snapshot bereit.',10,1) WITH NOWAIT;

        IF @ResultTable IS NOT NULL
        BEGIN

 DECLARE @DependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
 IF @DependencyId IS NULL
 OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@DependencyId)<>5
 OR EXISTS(SELECT 1 FROM (VALUES (1,N'@ResultTableToAlter',231,256),(2,N'@LikeTable',231,1552),
(3,N'@KeepData',104,1),(4,N'@Debug',48,1),(5,N'@Hilfe',104,1)) expected(id,name,typeid,bytes)
     WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=@DependencyId
       AND p.parameter_id=expected.id AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),expected.name)
       AND p.system_type_id=expected.typeid AND p.max_length=expected.bytes AND p.is_output=0))
 THROW 54008,N'ResultTable-Schnittstelle fehlt oder ist abweichend.',1;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_DeterministicLookup_ResultSource',@KeepData=@KeepData,@Debug=@Debug;
            SET @Sql = N'INSERT ' + QUOTENAME(@ResultTable) + N' (InputOrdinal,LookupOrdinal,[Value]) SELECT InputOrdinal,LookupOrdinal,[Value] FROM #tbx_DeterministicLookup_ResultSource;';
            EXEC sys.sp_executesql @Sql;
        END;
        IF @OwnTransaction = 1 COMMIT TRANSACTION;
        -- Keine Zeilen vor eigenem Commit oder vollständig vorbereiteter Callerarbeit.
        IF @ResultTable IS NULL
            SELECT InputOrdinal,LookupOrdinal,[Value] FROM #tbx_DeterministicLookup_ResultSource ORDER BY InputOrdinal;
    END TRY
    BEGIN CATCH
        IF @OwnTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @SavepointSet = 1 AND XACT_STATE() = 1 ROLLBACK TRANSACTION @Savepoint;
        THROW;
    END CATCH;
    RETURN 0;
END;
GO
