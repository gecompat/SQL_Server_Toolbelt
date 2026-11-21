-- ============================================================================
-- Objekt: toolbelt_json.USP_ValidateJsonSchema; Typ: Stored Procedure
-- Zweck: Read-only Schemaurteil im begrenzten Profil toolbelt-2020-12-v1.
-- Vertrag: Documentation/Architecture/JSON_SCHEMA_CONTRACT.md; USP 1.0.
-- Parameter: zwei JSON-Inputs, explizites Profil, nur absenkbare Ressourcen.
-- Resultset: SUMMARY plus bis MaxErrors ERROR; zehn typisierte Spalten.
-- Dependencies: SAFE JsonCore/JsonSchema; ResultTable >=1.0.0, same_database.
-- Rechte: bestehende EXECUTE-/SELECT-Rechte; keine Rechteausweitung.
-- Versionen: SQL Server 2019/2022/2025, Compatibility >=150; Windows/Linux.
-- Fehler: 55600/1 Argument, 55601/1 Bridge; Engine-/Helperfehler unverändert.
-- Performance: iterativer, global budgetierter CLR-Pfad ohne SQL-Kontextzugriff.
-- Grenzen: kein volles Draftprofil; kein Download, Coercion oder Datenänderung.
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_json.USP_ValidateJsonSchema
 @Json nvarchar(max)=NULL,
 @Schema nvarchar(max)=NULL,
 @Profile varchar(32)='toolbelt-2020-12-v1',
 @MaxDocumentBytes bigint=16777216,
 @MaxSchemaBytes bigint=1048576,
 @MaxDepth int=128,
 @MaxEvaluationSteps bigint=1000000,
 @MaxErrors int=100,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-json-usp-validatejsonschema"
-- description: "Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.json.schema"
-- schema_name: "toolbelt_json"
-- object_name: "USP_ValidateJsonSchema"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Json", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Vollständiger JSON-Wert (Objekt, Array oder Skalar), maximal MaxDocumentBytes UTF-16-Bytes. Leerer/fehlerhafter Text ergibt INVALID_JSON; doppelte Keys sind ungültig und ungepaarte Surrogate UNSUPPORTED. NULL (Default) in Json oder Schema ergibt SQL_NULL nach Argumentprüfung. Keine Typkonvertierung oder Änderung des Dokuments."}, {"name": "@Schema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Boolean-Schema true/false oder Schemaobjekt des Profils toolbelt-2020-12-v1, maximal MaxSchemaBytes UTF-16-Bytes. Unterstützte Formen/Keywordtypen siehe JSON_SCHEMA_CONTRACT.md, Abschnitt Sichtbarer Profilumfang: $schema nur Draft2020-12; $defs, nichtrekursive lokale $ref, type, required, properties, additionalProperties, items, prefixItems, minItems/maxItems, minProperties/maxProperties, minLength/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum sowie title/description/$comment. Keine externen Referenzen, Zyklen, format, pattern, enum/const, Kombinatoren oder unbekannten Keywords. Alle Schemaorte einschließlich ungenutzter Definitionen werden vor der Instanz geprüft; NULL ergibt SQL_NULL nach Argumentprüfung."}, {"name": "@Profile", "sql_type": "varchar(32)", "sql_default": "'toolbelt-2020-12-v1'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Einziger erlaubter Wert, exakt ASCII und längensensitiv: toolbelt-2020-12-v1 (Default) wählt die dokumentierte begrenzte Draft2020-12-Teilmenge. Kein Trim/Casefold; NULL/leer/andere Werte werfen 55600/1. Keine Behauptung vollständiger Draftkonformität."}, {"name": "@MaxDocumentBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Bytes, Default 16777216; NULL/außerhalb wirft 55600/1, Dokumentüberschreitung liefert LIMIT/DOCUMENT_BYTES."}, {"name": "@MaxSchemaBytes", "sql_type": "bigint", "sql_default": "1048576", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1048576 UTF-16-Bytes, Default 1048576; NULL/außerhalb wirft 55600/1, Schemaüberschreitung liefert LIMIT/SCHEMA_BYTES."}, {"name": "@MaxDepth", "sql_type": "int", "sql_default": "128", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..128 offene Container in Dokument und Schema, Default 128; NULL/außerhalb wirft 55600/1. Parser beendet eine Überschreitung als LIMIT, nicht als gültiges Boolurteil."}, {"name": "@MaxEvaluationSteps", "sql_type": "bigint", "sql_default": "1000000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1000000 abstrakte Arbeitseinheiten über sämtliche Prüfphasen, Default 1000000; NULL/außerhalb wirft 55600/1. Keine Millisekunden-/CPUzeitangabe; Erschöpfung ergibt LIMIT/IsValid=NULL."}, {"name": "@MaxErrors", "sql_type": "int", "sql_default": "100", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 0..100 Diagnosezeilen, Default 100; 0 unterdrückt ERROR-Zeilen, SUMMARY bleibt. NULL/außerhalb wirft 55600/1. Begrenzt nur die Diagnose, nicht die vollständige Evaluation; ErrorsTruncated weist Kürzung aus."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Argument-/Namespace-/Helper-/CLR-/Fachprüfung oder Zielmutation. 0 oder NULL: Fachpfad. Alle SQL-Argumente besitzen technische Defaults."}]
-- source_paths: ["Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql", "Modules/toolbelt.json.schema/Source/JsonSchemaBridge.sql", "Modules/toolbelt.json.schema/Clr/JsonSchemaBridge.cs", "Modules/toolbelt.json.schema/Clr/SchemaValidator.cs", "Modules/toolbelt.json.schema/Clr/SchemaPreflight.cs", "Modules/toolbelt.json.schema/Clr/SchemaTree.cs", "Modules/toolbelt.json.schema/Clr/LocalSchemaReference.cs", "Modules/toolbelt.json.schema/Clr/ExactJsonNumber.cs", "Modules/toolbelt.json.schema/Clr/SignedDecimalDigits.cs", "Modules/toolbelt.json.core/Clr/JsonCanonicalCore.cs", "Modules/toolbelt.json.core/Clr/JsonSyntaxScanner.cs", "Modules/toolbelt.json.core/Clr/JsonTokenDocument.cs", "Modules/toolbelt.json.core/Clr/JsonOrdinalComparer.cs", "Modules/toolbelt.json.core/Clr/JsonWorkBudget.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.1"
-- ---
--
-- # USP_ValidateJsonSchema
--
-- ## Zweck und Einsatzfälle
--
-- Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen. Öffentliches Boolurteil nur bei vollständiger Evaluation.
--
-- ## Voraussetzungen
--
-- Installiertes Schema1.0.1 mit autorisierten SAFE-Assemblies tlblt_JsonSchema und tlblt_JsonCore, SQL2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Einziges Profil toolbelt-2020-12-v1, exakte ordinale Schreibweise/Länge ohne Trim. Boolean-Schema true/false oder Schemaobjekt. Kein vollständiges Draft2020-12-Profil. Taxative 22 Keywords: `$schema`, `$ref`, `$defs`, `title`, `description`, `$comment`, `type`, `required`, `properties`, `additionalProperties`, `items`, `prefixItems`, `minItems`, `maxItems`, `minProperties`, `maxProperties`, `minLength`, `maxLength`, `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`. $schema nur String https://json-schema.org/draft/2020-12/schema, keine andere Draftkennung. title/description/$comment nur Stringannotation ohne Validierungseffekt. Unknowns einschließlich enum,const,format,pattern,multipleOf,allOf/anyOf/oneOf,not,if/then/else,contains,uniqueItems,$id/$anchor/$dynamicRef und unevaluated* ergeben UNSUPPORTED, nicht stilles Ignorieren. `type`: einer von null/boolean/number/string/object/array/integer als String oder nichtleere Arraymenge ohne doppelte Typnamen. `required`: Array eindeutiger Strings, leer erlaubt. `properties` und `$defs`: Objekte mit Boolean-/Objektschemas. `additionalProperties` und `items`: einzelnes Boolean-/Objektschema, keine alte Array-items-Tupleform. `prefixItems`: nichtleeres Array von Schemas; `items` gilt für Positionen dahinter oder alle ohne prefixItems. Object-/Array-/Stringkeywords greifen nur auf den passenden Instanztyp. Zählerbounds min*/max* sind mathematisch nichtnegative ganze JSON-Zahlen, keine auf SQL-int beschränkten Eingabeparameter. minLength/maxLength zählen Unicode-Skalare, nicht UTF16-Codeunits/Grapheme. Numeric minimum/maximum/exclusive* verlangen JSON-Zahlen, keine alten Boolean-exclusive-Schalter. integer wird mathematisch bestimmt: z.B. 1.0 ist integer, ohne Coercion oder Gleitkommarundung. Nur nichtrekursive lokale URIfragment-$ref: beginnt mit #, danach einmal strict Percentbytes/UTF8 und dann einmal RFC6901 ~0/~1 decodieren. Rootfragment # möglich, aber Selbst-/Referenzzyklen im gesamten Schema-/Containmentgraph sind UNSUPPORTED/REF_CYCLE. Kein Netzwerk, Dateizugriff oder externer Resolver; leere/externe Referenz ohne # ist UNSUPPORTED/EXTERNAL_REF. Fehlerhafte Prozent-/UTF8-/~-/Fragmentlexik INVALID_SCHEMA/REF_SYNTAX; fehlendes/nicht als Schema erschlossenes Ziel bzw. ungeeigneter Arrayindex INVALID_SCHEMA/REF_TARGET. Alle bekannten Schemaorte einschließlich ungenutzter $defs werden zuerst geprüft, inklusive Formen, lokaler Targets und Zyklen. Schemaorte/Graphkanten stabil nach vollständig codierten Pointern, Instanzmember nach decodierter UTF16-Identität und Instanzarrays numerisch; keine Kultur-/SQL-Padding-Normalisierung. SameDB core.result-table>=1.0.0 mit exakt fünf erwarteten Parametern ist auch für direkten SELECT erforderlich: seine Metadatensignatur wird vor CLR-Auswertung geprüft. Diese Routine installiert/erweitert keine Abhängigkeit.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Json` | `nvarchar(max)` | `NULL` | Vollständiger JSON-Wert (Objekt, Array oder Skalar), maximal MaxDocumentBytes UTF-16-Bytes. Leerer/fehlerhafter Text ergibt INVALID_JSON; doppelte Keys sind ungültig und ungepaarte Surrogate UNSUPPORTED. NULL (Default) in Json oder Schema ergibt SQL_NULL nach Argumentprüfung. Keine Typkonvertierung oder Änderung des Dokuments. |
-- | `@Schema` | `nvarchar(max)` | `NULL` | Boolean-Schema true/false oder Schemaobjekt des Profils toolbelt-2020-12-v1, maximal MaxSchemaBytes UTF-16-Bytes. Unterstützte Formen/Keywordtypen siehe JSON_SCHEMA_CONTRACT.md, Abschnitt Sichtbarer Profilumfang: $schema nur Draft2020-12; $defs, nichtrekursive lokale $ref, type, required, properties, additionalProperties, items, prefixItems, minItems/maxItems, minProperties/maxProperties, minLength/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum sowie title/description/$comment. Keine externen Referenzen, Zyklen, format, pattern, enum/const, Kombinatoren oder unbekannten Keywords. Alle Schemaorte einschließlich ungenutzter Definitionen werden vor der Instanz geprüft; NULL ergibt SQL_NULL nach Argumentprüfung. |
-- | `@Profile` | `varchar(32)` | `'toolbelt-2020-12-v1'` | Einziger erlaubter Wert, exakt ASCII und längensensitiv: toolbelt-2020-12-v1 (Default) wählt die dokumentierte begrenzte Draft2020-12-Teilmenge. Kein Trim/Casefold; NULL/leer/andere Werte werfen 55600/1. Keine Behauptung vollständiger Draftkonformität. |
-- | `@MaxDocumentBytes` | `bigint` | `16777216` | Ganzzahl 1..16777216 UTF-16-Bytes, Default 16777216; NULL/außerhalb wirft 55600/1, Dokumentüberschreitung liefert LIMIT/DOCUMENT_BYTES. |
-- | `@MaxSchemaBytes` | `bigint` | `1048576` | Ganzzahl 1..1048576 UTF-16-Bytes, Default 1048576; NULL/außerhalb wirft 55600/1, Schemaüberschreitung liefert LIMIT/SCHEMA_BYTES. |
-- | `@MaxDepth` | `int` | `128` | Ganzzahl 1..128 offene Container in Dokument und Schema, Default 128; NULL/außerhalb wirft 55600/1. Parser beendet eine Überschreitung als LIMIT, nicht als gültiges Boolurteil. |
-- | `@MaxEvaluationSteps` | `bigint` | `1000000` | Ganzzahl 1..1000000 abstrakte Arbeitseinheiten über sämtliche Prüfphasen, Default 1000000; NULL/außerhalb wirft 55600/1. Keine Millisekunden-/CPUzeitangabe; Erschöpfung ergibt LIMIT/IsValid=NULL. |
-- | `@MaxErrors` | `int` | `100` | Ganzzahl 0..100 Diagnosezeilen, Default 100; 0 unterdrückt ERROR-Zeilen, SUMMARY bleibt. NULL/außerhalb wirft 55600/1. Begrenzt nur die Diagnose, nicht die vollständige Evaluation; ErrorsTruncated weist Kürzung aus. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Argument-/Namespace-/Helper-/CLR-/Fachprüfung oder Zielmutation. 0 oder NULL: Fachpfad. Alle SQL-Argumente besitzen technische Defaults. |
--
-- ## Ergebnisse
--
-- RowKind varchar(8) NOT NULL,ErrorOrdinal int NOT NULL,Status varchar(24) NOT NULL,Profile varchar(32) NOT NULL,IsValid bit NULL,DocumentPointer nvarchar(max) NULL,SchemaPointer nvarchar(max) NULL,Keyword nvarchar(128) NULL,ErrorCode varchar(32) NULL,ErrorsTruncated bit NOT NULL; Textfelder BIN2. Genau eine SUMMARY mit ErrorOrdinal=0, danach höchstens MaxErrors ERROR-Zeilen mit lückenlosen Ordinals ab1. Alle Zeilen tragen denselben endgültigen Status/Profile/IsValid/ErrorsTruncated. Status taxativ: VALID (IsValid=1), INVALID_INSTANCE (0), INVALID_SCHEMA/INVALID_JSON/UNSUPPORTED/SQL_NULL/LIMIT (SQL-NULL). Summary.ErrorCode bei Instanzverletzung INSTANCE_VIOLATION, bei VALID NULL, sonst begrenzter Fehlercode. Pointers sind RFC6901-Stringpfade, Root leer, null bei nicht bestimmtem Ort; Keyword kann NULL sein, z.B. root-false oder nicht darstellbarem langem unbekanntem Keyword. Kein vollständiger Dokument-/Schemaecho und keine freie Enginefehlermeldung in den fachlichen Zeilen, aber Pointer können vertrauliche Keynamen enthalten. Direkter SELECT ORDER BY ErrorOrdinal, ResultTable keine gespeicherte Ordnung. Bei Zielrouting kein zusätzlicher Fach-SELECT, KeepData=0 ersetzt/1 hängt kompatibel an/NULL=>0. Normaler impliziter Prozedurreturn0 bedeutet nicht automatisch VALID; SUMMARY auswerten. Hilfe liefert bestehende Standardhilfe und genau eine zusätzliche Zeile SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max).
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'{"quantity":3}',@Schema=N'{"type":"object","required":["quantity"],"properties":{"quantity":{"type":"integer","minimum":1}}}';
-- -- SUMMARY VALID,IsValid=1; keine ERROR-Zeilen.
-- EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf USP_ValidateJsonSchema und sameDB USP_PrepareResultTable plus SELECT auf FT_ValidateJsonSchemaInternal nach bestehendem Callerprofil. Der CLR-Aufruf erfolgt in dynamischem SQL; öffentlicher USP-Grant allein genügt nicht. Objekt-/sys.parameters-Metadatensichtbarkeit für die exakte Helper-Signatur nötig, auch bei direkter Ausgabe. Zielrouting zusätzlich Caller-Temp-Rechte. Assembly-/Trust-/Datenbankrechte separat bereits erfüllen; keine automatische Vergabe/Principalumschaltung oder Serverkonfiguration. Zentrale Dreiteilnamen ersetzen kein gültiges DBmapping/Objektrecht.
--
-- ## Ressourcenbedarf
--
-- Obergrenzen nur absenkbar: MaxDocumentBytes 16777216 UTF16-Bytes, MaxSchemaBytes1048576, MaxDepth128 offene Container je Dokument/Schema, MaxEvaluationSteps1000000 abstrakte globale Einheiten, MaxErrors0..100. Der Arbeitszähler umfasst beide Inputs, deren Kopien/Scanner/Token-/Key-/Pointerstrukturen, Preflight/Graph/Sortierung, Referenzen, exakte Zahlen und Evaluation. Er ist keine CPUinstruktions-, Millisekunden-, Heap-/SqlClient-/Transportallokationsquote. Schon Inputkopie belastet 2*UTF16-Länge vor der Kopie; ein erlaubtes Byte-Maximum garantiert deshalb keine Auswertung innerhalb des unabhängigen Workbudgets. Iterative Scanner-/Graph-/Evaluationstacks, keine expandierten riesigen Exponenten-Nullpads oder double/decimal-Rundung; Zahlen als Vorzeichen/Ziffern/Dezimalexponenten vergleichen. MaxErrors begrenzt nur gespeicherte Diagnosen, Evaluation läuft weiter: selbst mit0 kann vollständiges Boolurteil entstehen. ErrorsTruncated meldet Diagnosecap, kein Vollständigkeitsbeweis bei LIMIT. Bei Arbeitsabbruch können bereits gesammelte ERRORs mit final LIMIT/IsValid=NULL erhalten bleiben; sie sind kein abgeschlossenes INVALID_INSTANCE-Urteil. Feste terminale Kontrollhülle höchstens101 Zeilen, keine zusätzliche frei anhebbare Output-/Heapquote.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON,KeepData/Debug/Hilfe NULL=>0. Frühe Hilfe vor sämtlichen Fachprüfungen. Reservierte Caller-Temp #tbx_JsonSchema_Result oder caseinsensitiver #tbx_-ResultTable-Präfix wird vor separater Batchkompilierung abgewiesen. CLR-Antwort vollständig in private Tabellenvariable materialisieren und Rowkind/Ordinal/Status/Profile/IsValid/Truncation/Anzahl konsistent prüfen, dann typisierte Ergebnistemp. Erst danach Zielrouting mit eigener Transaktion oder zufälligem Caller-Savepoint; eigener Commit/Rollback nur im eigenen Scope, Caller-Savepoint nur bei XACT_STATE=1, niemals gesamte fremde Transaktion committen/rollbacken. Rollbackfehler nicht gesondert geschützt, technischer Fehler kann Caller uncommittable lassen. Direkter SELECT kein eigener BEGIN/COMMIT. Debug>0 abstrakte Severity-10-NOWAIT-Message ohne Payload, bei Routing zusätzlich Helperdiagnose. Ungültiger fachlicher Status ist ein normales Ergebnis und kann eine ResultTable füllen/ersetzen, kein automatischer SQL-Rollback für INVALID_INSTANCE/INVALID_SCHEMA/LIMIT.
--
-- ## Fehlerbehandlung
--
-- 55600/State1 ungültiges Profil/NULL-oder-außerhalb Ressourcen vor Namespace-/Dependencyprüfung. 55601/State1 reservierter Tempnamespace, fehlender/unsichtbarer/abweichender Helper oder inkonsistenter CLR-Transport. Das ist keine allgemeine Umschreibung fehlender Bridge-/SELECT-/Enginefehler; diese bleiben technisch. Auch SQL_NULL-Datenpfad durchläuft zuerst öffentlichen Argument-/Namespace-/Helperpreflight. Argumentprüfung zuerst, dann SQL_NULL falls Json oder Schema SQL-NULL. Danach Schema-Länge, Schemakopie/-syntax/-tiefe, String-Unicode, alle decodierten Duplikatkeys, vollständiger Schema-/Refgraph-Preflight; erst danach Dokumentlänge/-kopie/-syntax/-tiefe/Unicode/alle Duplikate und Evaluation. Damit kann Schemafehler vor übergroßem/fehlerhaftem Dokument stehen. Syntax-/Tiefengrenze folgen dem gemeinsamen Scanner am zuerst erkannten Problem, Worklimit kann jede budgetierte Phase abbrechen. Ungepaarte rohe/escaped Surrogate in Strings/Keys: UNSUPPORTED/UNPAIRED_SURROGATE; Duplikatkeys ordinal/längensensitiv auch in ungenutzten Teilen: INVALID_SCHEMA oder INVALID_JSON/DUPLICATE_KEY. Keine Coercion, Default-Injektion oder Mutation. LIMIT-Codes SCHEMA_BYTES,DOCUMENT_BYTES,DEPTH_LIMIT,EVALUATION_LIMIT. Schema-/Referenzcodes JSON_SYNTAX,SCHEMA_FORM,KEYWORD_FORM,DRAFT,KEYWORD_UNSUPPORTED,EXTERNAL_REF,REF_SYNTAX,REF_TARGET,REF_CYCLE. Instanzdiagnosen FALSE_SCHEMA,TYPE,MIN_PROPERTIES,MAX_PROPERTIES,REQUIRED,ADDITIONAL_PROPERTY,MIN_ITEMS,MAX_ITEMS,MIN_LENGTH,MAX_LENGTH,MINIMUM,MAXIMUM,EXCLUSIVE_MINIMUM,EXCLUSIVE_MAXIMUM. Nur eigene Worklimit-/SchemaFailure werden in fachliche Status überführt; unerwartete technische Exceptions bleiben sichtbar. Details/Faultpointer bei Schemafehler vor DocumentStage liegen in SchemaPointer, danach in DocumentPointer; bei globalem Worklimit nicht generell ein genauer Faultort.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Profil-/Minimalrechte-/Installer-/Ressourcenabnahme. Historische unveränderte Fachkernbelege behalten ihre ursprüngliche Bindung; neue Hilfe/DDL/Installer werden dadurch nicht nativ qualifiziert. Kein vollständiger JSON-Schema-Draftvalidator, SQL-Abfragegenerator, Inputcoercer oder Datenbereiniger. Nicht-NULL Boolurteil nur für vollständig abgeschlossene Evaluation; ErrorsTruncated allein beweist keinen vollständigen Lauf. Ausgabe kann Keys/Pointers offenlegen und ist privat zu behandeln. Keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON;
 SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0),@Hilfe=COALESCE(@Hilfe,0);
 IF @Hilfe=1
 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_json' AS sysname) AS SchemaName,
            CAST(N'USP_ValidateJsonSchema' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Vollständiges Urteil im begrenzten Profil; Diagnosekürzung beendet die Evaluation nicht. LIMIT hat kein Boolurteil.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'RowKind', N'varchar(8)', 1, 0, NULL, CAST(N'SUMMARY oder ERROR.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ErrorOrdinal', N'int', 1, 0, NULL, CAST(N'SUMMARY=0, ERROR=1..N; explizite Ergebnisordnung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(24)', 1, 0, NULL, CAST(N'VALID/INVALID_INSTANCE/INVALID_SCHEMA/INVALID_JSON/UNSUPPORTED/SQL_NULL/LIMIT.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'Profile', N'varchar(32)', 1, 0, NULL, CAST(N'Exaktes angewandtes Profil.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'IsValid', N'bit', 0, 1, NULL, CAST(N'1 bei VALID, 0 bei vollständigem INVALID_INSTANCE; sonst NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'DocumentPointer', N'nvarchar(max)', 0, 1, NULL, CAST(N'RFC6901-Ort in der Instanz; leer=root, NULL=unbekannt/nicht betroffen.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'SchemaPointer', N'nvarchar(max)', 0, 1, NULL, CAST(N'RFC6901-Ort im Schema; vollständige unveränderte decoded Keys.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'Keyword', N'nvarchar(128)', 0, 1, NULL, CAST(N'Zuständiges Keyword; NULL wenn nicht bekannt oder länger als 128 Einheiten.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'ErrorCode', N'varchar(32)', 0, 1, NULL, CAST(N'Kanonischer Fehlercode; VALID-SUMMARY ohne Code.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'ErrorsTruncated', N'bit', 1, 0, NULL, CAST(N'Unterdrückte Diagnosen; auf allen Zeilen gleicher Endzustand.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'55600/1', NULL, NULL, NULL, NULL, CAST(N'Ungültiges Profil oder Ressourcenargument.' AS nvarchar(max)), NULL),
        (N'ERROR', 2, N'55601/1', NULL, NULL, NULL, NULL, CAST(N'Interner Transport-/Namespace-/Dependencyvertrag verletzt; kein Fachurteil.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein volles Draft2020-12; lokale nichtrekursive Refs, exakte Zahlen/Unicode, kein externer Zugriff.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetische Instanz mit einfachem Schema.' AS nvarchar(max)), CAST(N'EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N''42'',@Schema=N''{"type":"integer"}'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@Json', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Vollständiger JSON-Wert (Objekt, Array oder Skalar), maximal MaxDocumentBytes UTF-16-Bytes. Leerer/fehlerhafter Text ergibt INVALID_JSON; doppelte Keys sind ungültig und ungepaarte Surrogate UNSUPPORTED. NULL (Default) in Json oder Schema ergibt SQL_NULL nach Argumentprüfung. Keine Typkonvertierung oder Änderung des Dokuments.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Schema', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Boolean-Schema true/false oder Schemaobjekt des Profils toolbelt-2020-12-v1, maximal MaxSchemaBytes UTF-16-Bytes. Unterstützte Formen/Keywordtypen siehe JSON_SCHEMA_CONTRACT.md, Abschnitt Sichtbarer Profilumfang: $schema nur Draft2020-12; $defs, nichtrekursive lokale $ref, type, required, properties, additionalProperties, items, prefixItems, minItems/maxItems, minProperties/maxProperties, minLength/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum sowie title/description/$comment. Keine externen Referenzen, Zyklen, format, pattern, enum/const, Kombinatoren oder unbekannten Keywords. Alle Schemaorte einschließlich ungenutzter Definitionen werden vor der Instanz geprüft; NULL ergibt SQL_NULL nach Argumentprüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Profile', N'varchar(32)', 0, 0, N'''toolbelt-2020-12-v1''', CAST(N'Einziger erlaubter Wert, exakt ASCII und längensensitiv: toolbelt-2020-12-v1 (Default) wählt die dokumentierte begrenzte Draft2020-12-Teilmenge. Kein Trim/Casefold; NULL/leer/andere Werte werfen 55600/1. Keine Behauptung vollständiger Draftkonformität.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxDocumentBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216 UTF-16-Bytes, Default 16777216; NULL/außerhalb wirft 55600/1, Dokumentüberschreitung liefert LIMIT/DOCUMENT_BYTES.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxSchemaBytes', N'bigint', 0, 0, N'1048576', CAST(N'Ganzzahl 1..1048576 UTF-16-Bytes, Default 1048576; NULL/außerhalb wirft 55600/1, Schemaüberschreitung liefert LIMIT/SCHEMA_BYTES.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxDepth', N'int', 0, 0, N'128', CAST(N'Ganzzahl 1..128 offene Container in Dokument und Schema, Default 128; NULL/außerhalb wirft 55600/1. Parser beendet eine Überschreitung als LIMIT, nicht als gültiges Boolurteil.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxEvaluationSteps', N'bigint', 0, 0, N'1000000', CAST(N'Ganzzahl 1..1000000 abstrakte Arbeitseinheiten über sämtliche Prüfphasen, Default 1000000; NULL/außerhalb wirft 55600/1. Keine Millisekunden-/CPUzeitangabe; Erschöpfung ergibt LIMIT/IsValid=NULL.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxErrors', N'int', 0, 0, N'100', CAST(N'Ganzzahl 0..100 Diagnosezeilen, Default 100; 0 unterdrückt ERROR-Zeilen, SUMMARY bleibt. NULL/außerhalb wirft 55600/1. Begrenzt nur die Diagnose, nicht die vollständige Evaluation; ErrorsTruncated weist Kürzung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Argument-/Namespace-/Helper-/CLR-/Fachprüfung oder Zielmutation. 0 oder NULL: Fachpfad. Alle SQL-Argumente besitzen technische Defaults.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_json' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ValidateJsonSchema' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-json-usp-validatejsonschema"
description: "Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen."
skill_format_version: "1.0"
module_id: "toolbelt.json.schema"
schema_name: "toolbelt_json"
object_name: "USP_ValidateJsonSchema"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Json", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Vollständiger JSON-Wert (Objekt, Array oder Skalar), maximal MaxDocumentBytes UTF-16-Bytes. Leerer/fehlerhafter Text ergibt INVALID_JSON; doppelte Keys sind ungültig und ungepaarte Surrogate UNSUPPORTED. NULL (Default) in Json oder Schema ergibt SQL_NULL nach Argumentprüfung. Keine Typkonvertierung oder Änderung des Dokuments."}, {"name": "@Schema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Boolean-Schema true/false oder Schemaobjekt des Profils toolbelt-2020-12-v1, maximal MaxSchemaBytes UTF-16-Bytes. Unterstützte Formen/Keywordtypen siehe JSON_SCHEMA_CONTRACT.md, Abschnitt Sichtbarer Profilumfang: $schema nur Draft2020-12; $defs, nichtrekursive lokale $ref, type, required, properties, additionalProperties, items, prefixItems, minItems/maxItems, minProperties/maxProperties, minLength/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum sowie title/description/$comment. Keine externen Referenzen, Zyklen, format, pattern, enum/const, Kombinatoren oder unbekannten Keywords. Alle Schemaorte einschließlich ungenutzter Definitionen werden vor der Instanz geprüft; NULL ergibt SQL_NULL nach Argumentprüfung."}, {"name": "@Profile", "sql_type": "varchar(32)", "sql_default": "''toolbelt-2020-12-v1''", "is_output": false, "argument_required": false, "busi' AS nvarchar(max)) + N'ness_required": false, "nullable": false, "description": "Einziger erlaubter Wert, exakt ASCII und längensensitiv: toolbelt-2020-12-v1 (Default) wählt die dokumentierte begrenzte Draft2020-12-Teilmenge. Kein Trim/Casefold; NULL/leer/andere Werte werfen 55600/1. Keine Behauptung vollständiger Draftkonformität."}, {"name": "@MaxDocumentBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Bytes, Default 16777216; NULL/außerhalb wirft 55600/1, Dokumentüberschreitung liefert LIMIT/DOCUMENT_BYTES."}, {"name": "@MaxSchemaBytes", "sql_type": "bigint", "sql_default": "1048576", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1048576 UTF-16-Bytes, Default 1048576; NULL/außerhalb wirft 55600/1, Schemaüberschreitung liefert LIMIT/SCHEMA_BYTES."}, {"name": "@MaxDepth", "sql_type": "int", "sql_default": "128", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..128 offene Container in Dokument und Schema, Default 128; NULL/außerhalb wirft 55600/1. Parser beendet eine Überschreitung als LIMIT, nicht als gültiges Boolurteil."}, {"name": "@MaxEvaluationSteps", "sql_type": "bigint", "sql_default": "1000000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1000000 abstrakte Arbeitseinheiten über sämtliche Prüfphasen, Default 1000000; NULL/außerhalb wirft 55600/1. Keine Millisekunden-/CPUzeitangabe; Erschöpfung ergibt LIMIT/IsValid=NULL."}, {"name": "@MaxErrors", "sql_type": "int", "sql_default": "100", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 0..100 Diagnosezeilen, Default 100; 0 unterdrückt ERROR-Zeilen, SUMMARY bleibt. NULL/außerhalb wirft 55600/1.' + N' Begrenzt nur die Diagnose, nicht die vollständige Evaluation; ErrorsTruncated weist Kürzung aus."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Argument-/Namespace-/Helper-/CLR-/Fachprüfung oder Zielmutation. 0 oder NULL: Fachpfad. Alle SQL-Argumente besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql' + N'", "Modules/toolbelt.json.schema/Source/JsonSchemaBridge.sql", "Modules/toolbelt.json.schema/Clr/JsonSchemaBridge.cs", "Modules/toolbelt.json.schema/Clr/SchemaValidator.cs", "Modules/toolbelt.json.schema/Clr/SchemaPreflight.cs", "Modules/toolbelt.json.schema/Clr/SchemaTree.cs", "Modules/toolbelt.json.schema/Clr/LocalSchemaReference.cs", "Modules/toolbelt.json.schema/Clr/ExactJsonNumber.cs", "Modules/toolbelt.json.schema/Clr/SignedDecimalDigits.cs", "Modules/toolbelt.json.core/Clr/JsonCanonicalCore.cs", "Modules/toolbelt.json.core/Clr/JsonSyntaxScanner.cs", "Modules/toolbelt.json.core/Clr/JsonTokenDocument.cs", "Modules/toolbelt.json.core/Clr/JsonOrdinalComparer.cs", "Modules/toolbelt.json.core/Clr/JsonWorkBudget.cs"]
review_status: "verified"
source_module_version: "1.0.1"
---

# USP_ValidateJsonSchema

## Zweck und Einsatzfälle

Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen. Öffentliches Boolurteil nur bei vollständiger Evaluation.

## Voraussetzungen

Installiertes Schema1.0.1 mit autorisierten SAFE-Assemblies tlblt_JsonSchema und tlblt_JsonCore, SQL2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Einziges Profil toolbelt-2020-12-v1, exakte ordinale Schreibweise/Länge ohne Trim. Boolean-Schema true/false oder Schemaobjekt. Kein vollständiges Draft2020-12-Profil. Taxative 22 Keywords: `$schema`, `$ref`, `$defs`, `title`, `description`, `$comment`, `type`, `required`, `properties`, `additionalProperties`, `items`, `prefixItems`, `minItems`, `maxItems`, `minProperties`, `maxProperties`, `minLength`, `maxLength`, `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`. $schema nur String https://json-schema.org/draft/2020-12/schema, keine andere Draftkennung. title/description/$comment nur Stringannotation ohne Validierungseffekt. Unknowns einschließlich enum,const,format,pattern,multipleOf,allOf/anyOf/oneOf,not,if/then/else,contains,uniqueItems,' + N'$id/$anchor/$dynamicRef und unevaluated* ergeben UNSUPPORTED, nicht stilles Ignorieren. `type`: einer von null/boolean/number/string/object/array/integer als String oder nichtleere Arraymenge ohne doppelte Typnamen. `required`: Array eindeutiger Strings, leer erlaubt. `properties` und `$defs`: Objekte mit Boolean-/Objektschemas. `additionalProperties` und `items`: einzelnes Boolean-/Objektschema, keine alte Array-items-Tupleform. `prefixItems`: nichtleeres Array von Schemas; `items` gilt für Positionen dahinter oder alle ohne prefixItems. Object-/Array-/Stringkeywords greifen nur auf den passenden Instanztyp. Zählerbounds min*/max* sind mathematisch nichtnegative ganze JSON-Zahlen, keine auf SQL-int beschränkten Eingabeparameter. minLength/maxLength zählen Unicode-Skalare, nicht UTF16-Codeunits/Grapheme. Numeric minimum/maximum/exclusive* verlangen JSON-Zahlen, keine alten Boolean-exclusive-Schalter. integer wird mathematisch bestimmt: z.B. 1.0 ist integer, ohne Coercion oder Gleitkommarundung. Nur nichtrekursive lokale URIfragment-$ref: beginnt mit #, danach einmal strict Percentbytes/UTF8 und dann einmal RFC6901 ~0/~1 decodieren. Rootfragment # möglich, aber Selbst-/Referenzzyklen im gesamten Schema-/Containmentgraph sind UNSUPPORTED/REF_CYCLE. Kein Netzwerk, Dateizugriff oder externer Resolver; leere/externe Referenz ohne # ist UNSUPPORTED/EXTERNAL_REF. Fehlerhafte Prozent-/UTF8-/~-/Fragmentlexik INVALID_SCHEMA/REF_SYNTAX; fehlendes/nicht als Schema erschlossenes Ziel bzw. ungeeigneter Arrayindex INVALID_SCHEMA/REF_TARGET. Alle bekannten Schemaorte einschließlich ungenutzter $defs werden zuerst geprüft, inklusive Formen, lokaler Targets und Zyklen. Schemaorte/Graphkanten stabil nach vollständig codierten Pointern, Instanzmember nach decodierter UTF16-Identität und Instanzarrays numerisch; keine Kultur-/SQL-Padding-Normalisierung. SameDB core.result-table>=1.0.0 mit exakt fünf erwarteten Parametern ist auch für direkten SELECT erforderlich: seine Metadatensignatur' + N' wird vor CLR-Auswertung geprüft. Diese Routine installiert/erweitert keine Abhängigkeit.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Json` | `nvarchar(max)` | `NULL` | Vollständiger JSON-Wert (Objekt, Array oder Skalar), maximal MaxDocumentBytes UTF-16-Bytes. Leerer/fehlerhafter Text ergibt INVALID_JSON; doppelte Keys sind ungültig und ungepaarte Surrogate UNSUPPORTED. NULL (Default) in Json oder Schema ergibt SQL_NULL nach Argumentprüfung. Keine Typkonvertierung oder Änderung des Dokuments. |
| `@Schema` | `nvarchar(max)` | `NULL` | Boolean-Schema true/false oder Schemaobjekt des Profils toolbelt-2020-12-v1, maximal MaxSchemaBytes UTF-16-Bytes. Unterstützte Formen/Keywordtypen siehe JSON_SCHEMA_CONTRACT.md, Abschnitt Sichtbarer Profilumfang: $schema nur Draft2020-12; $defs, nichtrekursive lokale $ref, type, required, properties, additionalProperties, items, prefixItems, minItems/maxItems, minProperties/maxProperties, minLength/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum sowie title/description/$comment. Keine externen Referenzen, Zyklen, format, pattern, enum/const, Kombinatoren oder unbekannten Keywords. Alle Schemaorte einschließlich ungenutzter Definitionen werden vor der Instanz geprüft; NULL ergibt SQL_NULL nach Argumentprüfung. |
| `@Profile` | `varchar(32)` | `''toolbelt-2020-12-v1''` | Einziger erlaubter Wert, exakt ASCII und längensensitiv: toolbelt-2020-12-v1 (Default) wählt die dokumentierte begrenzte Draft2020-12-Teilmenge. Kein Trim/Casefold; NULL/leer/andere Werte werfen 55600/1. Keine Behauptung vollständiger Draftkonformität. |
| `@MaxDocumentBytes` | `bigint` | `16777216` | Ganzzahl 1..16777216 UTF-16-Bytes, Default 16777216; NULL/außerhalb wirft 55600/1, Dokumentüberschreitung liefert LIMIT/DOCUMENT_BYTES. |
| `@MaxSchemaBytes` | `bigint` | `1048576` | Ganzzahl 1..1048576 UTF-16-Bytes, Default 1048576; NULL/außerhalb wirft 55600/1, Schemaüberschreitung liefert LIMIT/SCHEMA_BYTES.' + N' |
| `@MaxDepth` | `int` | `128` | Ganzzahl 1..128 offene Container in Dokument und Schema, Default 128; NULL/außerhalb wirft 55600/1. Parser beendet eine Überschreitung als LIMIT, nicht als gültiges Boolurteil. |
| `@MaxEvaluationSteps` | `bigint` | `1000000` | Ganzzahl 1..1000000 abstrakte Arbeitseinheiten über sämtliche Prüfphasen, Default 1000000; NULL/außerhalb wirft 55600/1. Keine Millisekunden-/CPUzeitangabe; Erschöpfung ergibt LIMIT/IsValid=NULL. |
| `@MaxErrors` | `int` | `100` | Ganzzahl 0..100 Diagnosezeilen, Default 100; 0 unterdrückt ERROR-Zeilen, SUMMARY bleibt. NULL/außerhalb wirft 55600/1. Begrenzt nur die Diagnose, nicht die vollständige Evaluation; ErrorsTruncated weist Kürzung aus. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe. |
| `@Hilfe` | `bit` | `0` | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Argument-/Namespace-/Helper-/CLR-/Fachprüfung oder Zielmutation. 0 oder NULL: Fachpfad. Alle SQL-Argumente besitzen technische Defaults. |

## Ergebnisse

RowKind varchar(8) ' + N'NOT NULL,ErrorOrdinal int NOT NULL,Status varchar(24) NOT NULL,Profile varchar(32) NOT NULL,IsValid bit NULL,DocumentPointer nvarchar(max) NULL,SchemaPointer nvarchar(max) NULL,Keyword nvarchar(128) NULL,ErrorCode varchar(32) NULL,ErrorsTruncated bit NOT NULL; Textfelder BIN2. Genau eine SUMMARY mit ErrorOrdinal=0, danach höchstens MaxErrors ERROR-Zeilen mit lückenlosen Ordinals ab1. Alle Zeilen tragen denselben endgültigen Status/Profile/IsValid/ErrorsTruncated. Status taxativ: VALID (IsValid=1), INVALID_INSTANCE (0), INVALID_SCHEMA/INVALID_JSON/UNSUPPORTED/SQL_NULL/LIMIT (SQL-NULL). Summary.ErrorCode bei Instanzverletzung INSTANCE_VIOLATION, bei VALID NULL, sonst begrenzter Fehlercode. Pointers sind RFC6901-Stringpfade, Root leer, null bei nicht bestimmtem Ort; Keyword kann NULL sein, z.B. root-false oder nicht darstellbarem langem unbekanntem Keyword. Kein vollständiger Dokument-/Schemaecho und keine freie Enginefehlermeldung in den fachlichen Zeilen, aber Pointer können vertrauliche Keynamen enthalten. Direkter SELECT ORDER BY ErrorOrdinal, ResultTable keine gespeicherte Ordnung. Bei Zielrouting kein zusätzlicher Fach-SELECT, KeepData=0 ersetzt/1 hängt kompatibel an/NULL=>0. Normaler impliziter Prozedurreturn0 bedeutet nicht automatisch VALID; SUMMARY auswerten. Hilfe liefert bestehende Standardhilfe und genau eine zusätzliche Zeile SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N''{"quantity":3}'',@Schema=N''{"type":"object","required":["quantity"],"properties":{"quantity":{"type":"integer","minimum":1}}}'';
-- SUMMARY VALID,IsValid=1; keine ERROR-Zeilen.
EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf USP_ValidateJsonSchema und sameDB USP_PrepareResultTable plus SELECT auf FT_ValidateJsonSchemaInternal nach bestehendem Callerprofil. Der CLR-Aufruf erfolgt in dynamischem SQL; öffentlicher USP-Gran' + N't allein genügt nicht. Objekt-/sys.parameters-Metadatensichtbarkeit für die exakte Helper-Signatur nötig, auch bei direkter Ausgabe. Zielrouting zusätzlich Caller-Temp-Rechte. Assembly-/Trust-/Datenbankrechte separat bereits erfüllen; keine automatische Vergabe/Principalumschaltung oder Serverkonfiguration. Zentrale Dreiteilnamen ersetzen kein gültiges DBmapping/Objektrecht.

## Ressourcenbedarf

Obergrenzen nur absenkbar: MaxDocumentBytes 16777216 UTF16-Bytes, MaxSchemaBytes1048576, MaxDepth128 offene Container je Dokument/Schema, MaxEvaluationSteps1000000 abstrakte globale Einheiten, MaxErrors0..100. Der Arbeitszähler umfasst beide Inputs, deren Kopien/Scanner/Token-/Key-/Pointerstrukturen, Preflight/Graph/Sortierung, Referenzen, exakte Zahlen und Evaluation. Er ist keine CPUinstruktions-, Millisekunden-, Heap-/SqlClient-/Transportallokationsquote. Schon Inputkopie belastet 2*UTF16-Länge vor der Kopie; ein erlaubtes Byte-Maximum garantiert deshalb keine Auswertung innerhalb des unabhängigen Workbudgets. Iterative Scanner-/Graph-/Evaluationstacks, keine expandierten riesigen Exponenten-Nullpads oder double/decimal-Rundung; Zahlen als Vorzeichen/Ziffern/Dezimalexponenten vergleichen. MaxErrors begrenzt nur gespeicherte Diagnosen, Evaluation läuft weiter: selbst mit0 kann vollständiges Boolurteil entstehen. ErrorsTruncated meldet Diagnosecap, kein Vollständigkeitsbeweis bei LIMIT. Bei Arbeitsabbruch können bereits gesammelte ERRORs mit final LIMIT/IsValid=NULL erhalten bleiben; sie sind kein abgeschlossenes INVALID_INSTANCE-Urteil. Feste terminale Kontrollhülle höchstens101 Zeilen, keine zusätzliche frei anhebbare Output-/Heapquote.

## Nebenwirkungen

SET NOCOUNT ON,KeepData/Debug/Hilfe NULL=>0. Frühe Hilfe vor sämtlichen Fachprüfungen. Reservierte Caller-Temp #tbx_JsonSchema_Result oder caseinsensitiver #tbx_-ResultTable-Präfix wird vor separater Batchkompilierung abgewiesen. CLR-Antwort vollständig in private Tabellenvariable materialisieren und Rowkind/Ordinal/St' + N'atus/Profile/IsValid/Truncation/Anzahl konsistent prüfen, dann typisierte Ergebnistemp. Erst danach Zielrouting mit eigener Transaktion oder zufälligem Caller-Savepoint; eigener Commit/Rollback nur im eigenen Scope, Caller-Savepoint nur bei XACT_STATE=1, niemals gesamte fremde Transaktion committen/rollbacken. Rollbackfehler nicht gesondert geschützt, technischer Fehler kann Caller uncommittable lassen. Direkter SELECT kein eigener BEGIN/COMMIT. Debug>0 abstrakte Severity-10-NOWAIT-Message ohne Payload, bei Routing zusätzlich Helperdiagnose. Ungültiger fachlicher Status ist ein normales Ergebnis und kann eine ResultTable füllen/ersetzen, kein automatischer SQL-Rollback für INVALID_INSTANCE/INVALID_SCHEMA/LIMIT.

## Fehlerbehandlung

55600/State1 ungültiges Profil/NULL-oder-außerhalb Ressourcen vor Namespace-/Dependencyprüfung. 55601/State1 reservierter Tempnamespace, fehlender/unsichtbarer/abweichender Helper oder inkonsistenter CLR-Transport. Das ist keine allgemeine Umschreibung fehlender Bridge-/SELECT-/Enginefehler; diese bleiben technisch. Auch SQL_NULL-Datenpfad durchläuft zuerst öffentlichen Argument-/Namespace-/Helperpreflight. Argumentprüfung zuerst, dann SQL_NULL falls Json oder Schema SQL-NULL. Danach Schema-Länge, Schemakopie/-syntax/-tiefe, String-Unicode, alle decodierten Duplikatkeys, vollständiger Schema-/Refgraph-Preflight; erst danach Dokumentlänge/-kopie/-syntax/-tiefe/Unicode/alle Duplikate und Evaluation. Damit kann Schemafehler vor übergroßem/fehlerhaftem Dokument stehen. Syntax-/Tiefengrenze folgen dem gemeinsamen Scanner am zuerst erkannten Problem, Worklimit kann jede budgetierte Phase abbrechen. Ungepaarte rohe/escaped Surrogate in Strings/Keys: UNSUPPORTED/UNPAIRED_SURROGATE; Duplikatkeys ordinal/längensensitiv auch in ungenutzten Teilen: INVALID_SCHEMA oder INVALID_JSON/DUPLICATE_KEY. Keine Coercion, Default-Injektion oder Mutation. LIMIT-Codes SCHEMA_BYTES,DOCUMENT_BYTES,DEPTH_LIMIT,EVALUATION_LIMIT. Schema-/Referenzcodes JSON_SYNTAX,SCH' + N'EMA_FORM,KEYWORD_FORM,DRAFT,KEYWORD_UNSUPPORTED,EXTERNAL_REF,REF_SYNTAX,REF_TARGET,REF_CYCLE. Instanzdiagnosen FALSE_SCHEMA,TYPE,MIN_PROPERTIES,MAX_PROPERTIES,REQUIRED,ADDITIONAL_PROPERTY,MIN_ITEMS,MAX_ITEMS,MIN_LENGTH,MAX_LENGTH,MINIMUM,MAXIMUM,EXCLUSIVE_MINIMUM,EXCLUSIVE_MAXIMUM. Nur eigene Worklimit-/SchemaFailure werden in fachliche Status überführt; unerwartete technische Exceptions bleiben sichtbar. Details/Faultpointer bei Schemafehler vor DocumentStage liegen in SchemaPointer, danach in DocumentPointer; bei globalem Worklimit nicht generell ein genauer Faultort.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Profil-/Minimalrechte-/Installer-/Ressourcenabnahme. Historische unveränderte Fachkernbelege behalten ihre ursprüngliche Bindung; neue Hilfe/DDL/Installer werden dadurch nicht nativ qualifiziert. Kein vollständiger JSON-Schema-Draftvalidator, SQL-Abfragegenerator, Inputcoercer oder Datenbereiniger. Nicht-NULL Boolurteil nur für vollständig abgeschlossene Evaluation; ErrorsTruncated allein beweist keinen vollständigen Lauf. Ausgabe kann Keys/Pointers offenlegen und ist privat zu behandeln. Keine Installations-/Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 IF @Profile IS NULL OR CONVERT(varbinary(max),@Profile)<>CONVERT(varbinary(max),'toolbelt-2020-12-v1')
 OR @MaxDocumentBytes IS NULL OR @MaxDocumentBytes NOT BETWEEN 1 AND 16777216
 OR @MaxSchemaBytes IS NULL OR @MaxSchemaBytes NOT BETWEEN 1 AND 1048576
 OR @MaxDepth IS NULL OR @MaxDepth NOT BETWEEN 1 AND 128
 OR @MaxEvaluationSteps IS NULL OR @MaxEvaluationSteps NOT BETWEEN 1 AND 1000000
 OR @MaxErrors IS NULL OR @MaxErrors NOT BETWEEN 0 AND 100
 THROW 55600,N'JSON Schema: ungültiges Profil oder Ressourcenargument.',1;
 -- Guard vor der separaten Batchcompilation verhindert Temp-Eclipsing.
 IF OBJECT_ID(N'tempdb..#tbx_JsonSchema_Result',N'U') IS NOT NULL
 OR LEFT(LOWER(@ResultTable COLLATE Latin1_General_100_BIN2),5) COLLATE Latin1_General_100_BIN2=N'#tbx_'
 THROW 55601,N'JSON Schema: reservierter interner Temp-Namespace ist belegt.',1;

 DECLARE @Dependency int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
 IF @Dependency IS NULL
 OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@Dependency)<>5
 OR EXISTS(SELECT 1 FROM (VALUES (1,N'@ResultTableToAlter',231,256),(2,N'@LikeTable',231,1552),
(3,N'@KeepData',104,1),(4,N'@Debug',48,1),(5,N'@Hilfe',104,1)) expected(id,name,typeid,bytes)
     WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=@Dependency
       AND p.parameter_id=expected.id AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),expected.name)
       AND p.system_type_id=expected.typeid AND p.max_length=expected.bytes AND p.is_output=0))
 THROW 55601,N'ResultTable-Schnittstelle fehlt oder ist abweichend.',1;
 DECLARE @Sql nvarchar(max)=N'
 SET NOCOUNT ON;
 DECLARE @Bridge TABLE(RowKind varchar(8) COLLATE Latin1_General_100_BIN2,ErrorOrdinal int,
 Status varchar(24) COLLATE Latin1_General_100_BIN2,Profile varchar(32) COLLATE Latin1_General_100_BIN2,
 IsValid bit,DocumentPointer nvarchar(max) COLLATE Latin1_General_100_BIN2,SchemaPointer nvarchar(max) COLLATE Latin1_General_100_BIN2,
 Keyword nvarchar(128) COLLATE Latin1_General_100_BIN2,ErrorCode varchar(32) COLLATE Latin1_General_100_BIN2,ErrorsTruncated bit);
 INSERT @Bridge(RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated)
 SELECT RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated
 FROM toolbelt_json.FT_ValidateJsonSchemaInternal(@Json,@Schema,@Profile,@MaxDocumentBytes,@MaxSchemaBytes,@MaxDepth,@MaxEvaluationSteps,@MaxErrors);
 DECLARE @Count int=(SELECT COUNT(*) FROM @Bridge),@Status varchar(24),@Truncated bit;
 SELECT @Status=Status,@Truncated=ErrorsTruncated FROM @Bridge WHERE RowKind=''SUMMARY'' AND ErrorOrdinal=0;
 IF @Count NOT BETWEEN 1 AND @MaxErrors+1
 OR (SELECT COUNT(*) FROM @Bridge WHERE RowKind=''SUMMARY'' AND ErrorOrdinal=0)<>1
 OR EXISTS(SELECT 1 FROM @Bridge WHERE RowKind IS NULL OR ErrorOrdinal IS NULL OR Status IS NULL OR Profile IS NULL OR ErrorsTruncated IS NULL
  OR CONVERT(varbinary(max),Profile)<>CONVERT(varbinary(max),@Profile)
  OR Status NOT IN (''VALID'',''INVALID_INSTANCE'',''INVALID_SCHEMA'',''INVALID_JSON'',''UNSUPPORTED'',''SQL_NULL'',''LIMIT'')
  OR DATALENGTH(Status)<>CASE Status WHEN ''VALID'' THEN 5 WHEN ''INVALID_INSTANCE'' THEN 16 WHEN ''INVALID_SCHEMA'' THEN 14 WHEN ''INVALID_JSON'' THEN 12 WHEN ''UNSUPPORTED'' THEN 11 WHEN ''SQL_NULL'' THEN 8 WHEN ''LIMIT'' THEN 5 END
  OR CONVERT(varbinary(max),Status)<>CONVERT(varbinary(max),@Status) OR ErrorsTruncated<>@Truncated
  OR (Status=''VALID'' AND (IsValid IS NULL OR IsValid<>1))
  OR (Status=''INVALID_INSTANCE'' AND (IsValid IS NULL OR IsValid<>0))
  OR (Status NOT IN (''VALID'',''INVALID_INSTANCE'') AND IsValid IS NOT NULL)
  OR (ErrorOrdinal=0 AND RowKind<>''SUMMARY'') OR (ErrorOrdinal>0 AND RowKind<>''ERROR'')
  OR DATALENGTH(RowKind)<>CASE WHEN ErrorOrdinal=0 THEN 7 ELSE 5 END
  OR ErrorOrdinal NOT BETWEEN 0 AND @Count-1)
 OR EXISTS(SELECT ErrorOrdinal FROM @Bridge GROUP BY ErrorOrdinal HAVING COUNT(*)<>1)
 THROW 55601,N''JSON Schema: interner Bridgevertrag verletzt.'',1;
 CREATE TABLE #tbx_JsonSchema_Result(RowKind varchar(8) COLLATE Latin1_General_100_BIN2 NOT NULL,ErrorOrdinal int NOT NULL,
 Status varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,Profile varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
 IsValid bit NULL,DocumentPointer nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,SchemaPointer nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
 Keyword nvarchar(128) COLLATE Latin1_General_100_BIN2 NULL,ErrorCode varchar(32) COLLATE Latin1_General_100_BIN2 NULL,ErrorsTruncated bit NOT NULL);
 INSERT #tbx_JsonSchema_Result(RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated)
 SELECT RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated FROM @Bridge;
 IF @Debug>0 RAISERROR(N''JSON Schema: vollständige Antwort materialisiert; Routing folgt.'',10,1) WITH NOWAIT;
 IF @ResultTable IS NULL
 BEGIN
  SELECT RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated
  FROM #tbx_JsonSchema_Result ORDER BY ErrorOrdinal;
  RETURN;
 END;
 DECLARE @Own bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,@Saved bit=0,
 @Savepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),''-'',''''),@Insert nvarchar(max);
 BEGIN TRY
  IF @Own=1 BEGIN TRANSACTION;
  ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @Saved=1; END;
  EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N''#tbx_JsonSchema_Result'',@KeepData=@KeepData,@Debug=@Debug;
  SET @Insert=N''INSERT ''+QUOTENAME(@ResultTable)+N''(RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated)
  SELECT RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated FROM #tbx_JsonSchema_Result;'';
  EXEC sys.sp_executesql @Insert;
  IF @Own=1 COMMIT;
 END TRY
 BEGIN CATCH
  IF @Own=1 AND XACT_STATE()<>0 ROLLBACK;
  ELSE IF @Saved=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
  THROW;
 END CATCH;';
 EXEC sys.sp_executesql @Sql,N'@Json nvarchar(max),@Schema nvarchar(max),@Profile varchar(32),@MaxDocumentBytes bigint,@MaxSchemaBytes bigint,@MaxDepth int,@MaxEvaluationSteps bigint,@MaxErrors int,@ResultTable sysname,@KeepData bit,@Debug tinyint',
 @Json,@Schema,@Profile,@MaxDocumentBytes,@MaxSchemaBytes,@MaxDepth,@MaxEvaluationSteps,@MaxErrors,@ResultTable,@KeepData,@Debug;
END;
GO
