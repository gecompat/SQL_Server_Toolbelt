---
name: "toolbelt-json-usp-jsonobject"
description: "JSON-Object aus Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet."
skill_format_version: "1.0"
module_id: "toolbelt.json.constructors"
schema_name: "toolbelt_json"
object_name: "USP_JsonObject"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@EntriesTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Leere Tabelle ergibt genau [] beziehungsweise {}. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {\"x\":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung."}, {"name": "@MaxTotalValueBytes", "sql_type": "bigint", "sql_default": "2097152", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig."}, {"name": "@MaxResultBytes", "sql_type": "bigint", "sql_default": "2097152", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei >0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.json.constructors/Source/USP_JsonObject.sql", "Modules/toolbelt.json.constructors/Source/USP_JsonConstructInternal.sql", "Modules/toolbelt.json.constructors/Clr/JsonEntryEvaluateBridge.cs", "Modules/toolbelt.json.core/Clr/JsonCanonicalCore.cs", "Modules/toolbelt.json.core/Clr/JsonSyntaxScanner.cs", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.3.0"
---

# USP_JsonObject

## Zweck und Einsatzfälle

JSON-Object aus Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.

## Voraussetzungen

Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Leere Tabelle ergibt genau [] beziehungsweise {}. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei >0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

ValueKind ist bytegenau string,number,boolean,null oderjson,ohneTrim/Casefold. string nimmt unquotierten Text,escaped/quotiert ihn; leer ist gültig. number nimmt ein vollständiges JSON-Zahlenliteral ohne Spaces/Quotes: optionalMinus,0 oder führende1..9 mitZiffern,optionalBruch/Exponent; keine numerische Normalisierung. boolean exakttrue/false. null verlangt SQLNULL inValue; andereKinds verbieten SQLNULL. json verlangt vollständiges Objekt/Array,keinen Scalarroot; Originalformat,Whitespace und innere doppelte Keys bleiben erhalten. Raw-UTF16 und decodierte Unicode-Escapes müssen wohlgeformt sein. Escape verarbeitet Quote,Backslash,Slash und Controls; keine Typinferenz,Trim,Coercion oderSQL-Ausführung ausWerten.

EntriesTable ist ein einzelner Caller-Tempname,kein ausführbarer SQL-Ausdruck. Alle Prozedurargumente haben technische Defaults für Hilfe; Pflicht-NULLwerte bleiben fachlich ungültig. Eingabedaten während des Aufrufs nicht parallel ändern.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `JsonValue` | `nvarchar(max)` | NOT NULL;Latin1_General_100_BIN2 |

Genau eineZeile,leereEingabe[] oder{}. ResultTableNULL direkte materialisierteAusgabe,nach eigenenCommit;sonst lokalesCallerziel ohne zusätzlichenFachresultset. Hilfe: bisherige zwölfspaltigeStandardhilfe plusgenaueineSkillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)). FrüheHilfe vorFachprüfungen/Compilation/Mutation;imCore vor dessenFachpfad,keinErsatzfürdieWrappergrenze. Öffentliche Hilfe: explizites RETURN0. Interne Hilfe: ursprüngliches RETURN; mit impliziter0. Normaler Fachabschluss ohne explizites RETURN ebenfalls implizit0, kein separater Geschäftsbeweis.

## Aufrufbeispiele

```sql
EXEC toolbelt_json.USP_JsonObject @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #ContosoEntries VALUES(1,N'contoso',N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche USP sowie Leserechte und Metadatensicht für Caller-Temps. tempdb.sys.columns für Shapes und sys.parameters für die Helperschnittstelle sind notwendig. Helper-EXECUTE bei ResultTable und reguläre Ownership-Chain zum internen Entrykern. Keine direkten Core-/Bridgegrants. Zentrale Dreiteilnamen benötigen Datenbankzugriff und Identitätsmapping. Keine Serverrolle oder Rechtevergabe aus dem Skill ableiten.

## Ressourcenbedarf

MaxEntries gilt mit 1..100000 global. MaxTotalValueBytes und MaxResultBytes liegen jeweils in 1..16777216 UTF16-Bytes; Defaults10000/2097152/2097152. Gruppierung multipliziert die Budgets nicht. Input-LOBs, Keys, Kindtexte, Fragmente, Sortierung, Cursor mit zwei Pässen, tempdb, Log und TABLOCK/HOLDLOCK verursachen zusätzlichen Aufwand. Das Ergebnisbudget umfasst Escaping, Keys, Container und Kommas. Keine CPU-, Peakheap- oder Wallclockgarantie.

## Nebenwirkungen

Öffentliche Wrapper normalisieren KeepData/Debug/HilfeNULL zu0 und liefern eigene frühe Hilfe. Danach reserviertes #tbx_-Eingabepräfix und fünf sichtbare private Tempnamen vor der Core-Compilation abweisen. Genau ein Coreaufruf bindet ObjectMode/GroupMode fest. Core hat eigene frühe Hilfe; er ersetzt die Wrapper-Compilergrenze nicht.

Core prüft Modi,positive MaxEntries1..100000 und Bytebudgets1..16777216. Die fünfparametrige PrepareResultTable-Schnittstelle wird über sys.parameters auch ohne ResultTable exakt geprüft. Caller-lokale sichtbare #EntriesTable,kein##/reserviertesPräfix,keinIdentitätsoverlap mitResultTable. Exakte Basisspalten ohne Alias-/Computedtypen in tempdb.sys.columns:Ordinal int,ValueKind/Value nvarchar(max),beiObject zusätzlichKey nvarchar(max),beiGroup zusätzlichGroupOrdinal int; Zusatzspalten ignorieren.

Eigene Transaktion oder eigener zufällig benannter Savepoint im Caller-TX,keine eigene XACT_ABORT-Zuweisung. TOP(MaxEntries+1)-Preflight unter TABLOCK/HOLDLOCK vor privater LOBkopie: globaler Count/Bytes,positive eindeutige Ordinals jeGruppe,positiveGroupOrdinal,Objectkeys1..1024Codeunits,Kindlänge≤7 und vorläufige Ergebnisuntergrenze. Privaten Snapshot bilden und erneut prüfen. Objectkeys werden über varbinary plusDATALENGTH jeGruppe verglichen; a und aSpace sind verschieden. Exakte Kinds,Kind/SQLNULL-Kohärenz und Rohwert-/starke Ergebnisuntergrenze prüfen.

Entries nach GroupOrdinal/Ordinal zweimal durchlaufen. Einzige Entrylogik ist die bekannte CLR-Bridge:Stage0 prüft RawUTF16,beiKindjson echtes SQLISJSON danach,Stage1 prüft Literale/decodiertesUTF16 und materialisiert. Vollständige Bridge-Metadaten/Phasen/Breite kontrollieren,sonst53611. Erster Kostenpass nutzt fürStringwerte höchstens1024Codeunit-Spans ohne Surrogatpaartrennung; globale exakte Ergebnisbytes prüfen bevor vollständige expandierte Stringfragmente entstehen. Zweiter Pass materialisiert Fragmente. Kein eigenes AGF-Depthlimit auf diesem Legacy-USP-Pfad.

STRING_AGG in Ordinalreihenfolge erzeugt ein Array/Object beziehungsweise eine Zeile je vorhandener Gruppe. Alle Gruppen teilen globale Limits. Ungruppiert leer ergibt[]/{},gruppiert leer ergibt nullZeilen. Debug>0 abstrakte Severity10-NOWAIT-Message vor Routing/Commit; Helper kann weitere Diagnose liefern. Vollständige Validierung vor Zielmutation; optionales Helper-DDL/INSERT gehört zur eigenen Transaktion oder zum Caller-Savepoint. Eigener Commit vor direkter materialisierter Ausgabe; Caller-TX bleibt erhalten. CATCH rollt eigenen TX oder committable eigenen Savepoint zurück. Keine erfolgreiche Teilmenge oder automatische Wiederholung.

## Fehlerbehandlung

THROW53600 Ressourcen/Modi;53601 Tabellen/Shape/Overlap/reservierterNamespace;53602 Ordinal/GroupOrdinal;53603 KeyNULL/leer/zuLang;53604 exakte doppelte Objectkeys;53605 Kindlänge oderKind;53606 Kind/SQLNULL;53607 Raw-/decodiertesUTF16;53608 Boolean/Zahlenliteral oder nativesISJSON;53609 Entry-/Raw-/Mindest-/exaktesErgebnisbudget;53610 Helperinterface;53611 inkohärente interneBridge/Kostenspans. Ursprüngliche Engine-/Binder-/Savepoint-/Lock-/Ressourcenfehler bleiben sichtbar. Kein Erfolgsteilresultat.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Merge-/Spill-/Grenzabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Kein allgemeines SQL/JSON-Abfrage-, Patch-, PrettyPrint-, Schema- oder Typinferenzwerkzeug. Geprüfte Bytebudgets sind keine Peakheap- oder Gesamtquerygarantie. Keine Installations- oder Rechteattestation. Inputdaten, Keys und Runtimebefunde privat halten.
