---
name: "toolbelt-json-ft-jsonentryevaluateinternal"
description: "Interne reine CLR-Entrybrücke mit getrennten Raw-/Materialisierungsphasen hinter SQL-Preflight und ISJSON."
skill_format_version: "1.0"
module_id: "toolbelt.json.constructors"
schema_name: "toolbelt_json"
object_name: "FT_JsonEntryEvaluateInternal"
object_type: "CLR_TVF"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@ObjectMode", "sql_type": "bit", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "0=Arrayentry,1=Objectentry. NichtNULL; ungültiger Adapterkontext wirft technischen CLR-Fehler."}, {"name": "@Key", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Im Arraymodus ignoriert undNULL zulässig. Im Objectmodus erforderlich,1..1024UTF-16-Einheiten,wohlgeformtesUTF16. Keine globale Duplikatprüfung in dieser Bridge."}, {"name": "@ValueKind", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Exakt string/number/boolean/null/json. NichtNULL,höchstens7UTF-16-Einheiten; defensive Vertragsfehler werden als Entryfehlerzeile zurückgegeben."}, {"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Kindabhängiger Rohtext; SQLNULL genau für Kindnull,sonst nichtNULL. Höchstens8388608UTF-16-Einheiten. Überschreitung ist technischer Resourcefehler,kein begrenzter Teiltext."}, {"name": "@Stage", "sql_type": "tinyint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ0=Raw-UTF16/Kosten ohne Fragment,1=vollständige Entryvalidierung/Materialisierung. Bei json muss vorStage1 echtes SQL-ISJSON bereits erfolgreich gewesen sein."}, {"name": "@Policy", "sql_type": "tinyint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ1=LegacyJson-Adapterpolicy. Kein AGF-Policy-Umschalter; andere oderNULL Werte sind technische Adapterfehler."}]
source_paths: ["Modules/toolbelt.json.constructors/Source/JsonEntryEvaluate.sql", "Modules/toolbelt.json.constructors/Source/USP_JsonConstructInternal.sql", "Modules/toolbelt.json.constructors/Clr/JsonEntryEvaluateBridge.cs", "Modules/toolbelt.json.core/Clr/JsonCanonicalCore.cs", "Modules/toolbelt.json.core/Clr/JsonSyntaxScanner.cs"]
review_status: "verified"
source_module_version: "1.3.0"
public_entrypoints: ["toolbelt_json.USP_JsonArray", "toolbelt_json.USP_JsonObject", "toolbelt_json.USP_JsonArraysByGroup", "toolbelt_json.USP_JsonObjectsByGroup"]
---

# FT_JsonEntryEvaluateInternal

## Zweck und Einsatzfälle

Interne reine CLR-Entrybrücke mit getrennten Raw-/Materialisierungsphasen hinter SQL-Preflight und ISJSON. Interner Helfer; öffentlichen Einstieg verwenden.

## Voraussetzungen

Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@ObjectMode` | `bit` | kein Default | Input | 0=Arrayentry,1=Objectentry. NichtNULL; ungültiger Adapterkontext wirft technischen CLR-Fehler. |
| `@Key` | `nvarchar(max)` | kein Default | Input | Im Arraymodus ignoriert undNULL zulässig. Im Objectmodus erforderlich,1..1024UTF-16-Einheiten,wohlgeformtesUTF16. Keine globale Duplikatprüfung in dieser Bridge. |
| `@ValueKind` | `nvarchar(max)` | kein Default | Input | Exakt string/number/boolean/null/json. NichtNULL,höchstens7UTF-16-Einheiten; defensive Vertragsfehler werden als Entryfehlerzeile zurückgegeben. |
| `@Value` | `nvarchar(max)` | kein Default | Input | Kindabhängiger Rohtext; SQLNULL genau für Kindnull,sonst nichtNULL. Höchstens8388608UTF-16-Einheiten. Überschreitung ist technischer Resourcefehler,kein begrenzter Teiltext. |
| `@Stage` | `tinyint` | kein Default | Input | Taxativ0=Raw-UTF16/Kosten ohne Fragment,1=vollständige Entryvalidierung/Materialisierung. Bei json muss vorStage1 echtes SQL-ISJSON bereits erfolgreich gewesen sein. |
| `@Policy` | `tinyint` | kein Default | Input | Taxativ1=LegacyJson-Adapterpolicy. Kein AGF-Policy-Umschalter; andere oderNULL Werte sind technische Adapterfehler. |

ValueKind ist bytegenau string,number,boolean,null oderjson,ohneTrim/Casefold. string nimmt unquotierten Text,escaped/quotiert ihn; leer ist gültig. number nimmt ein vollständiges JSON-Zahlenliteral ohne Spaces/Quotes: optionalMinus,0 oder führende1..9 mitZiffern,optionalBruch/Exponent; keine numerische Normalisierung. boolean exakttrue/false. null verlangt SQLNULL inValue; andereKinds verbieten SQLNULL. json verlangt vollständiges Objekt/Array,keinen Scalarroot; Originalformat,Whitespace und innere doppelte Keys bleiben erhalten. Raw-UTF16 und decodierte Unicode-Escapes müssen wohlgeformt sein. Escape verarbeitet Quote,Backslash,Slash und Controls; keine Typinferenz,Trim,Coercion oderSQL-Ausführung ausWerten.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `Fragment` | `nvarchar(max)` | NULL inStage0/Fehler,materialisiert inStage1-Erfolg |
| `ErrorNumber` | `int` | 0 oder53603/53605/53606/53607/53608 |
| `ErrorState` | `int` | 0 beiErfolg,stabileEntry-UnterklassebeiFehler |
| `FaultPhase` | `tinyint` | 0Erfolg,1RawKey,2RawValue,3Literal,4DecodedUTF16,5defensiveMetadaten |
| `RawValueBytes` | `bigint` | UTF16-Valuebytes,NULLValue0 |
| `KeyBytes` | `bigint` | ObjectKeybytes,Array0 |
| `StrongMinimumBytes` | `bigint` | starkeUntergrenze,bei defensivenMetadatenfehlernNULL möglich |
| `FragmentBytes` | `bigint` | Stage0/Fehler0,Stage1 tatsächlicheUTF16-Fragmentbytes |

Genau eine materialisierte Zeile,keine successfulTeilmenge. SQL-DDL deklariert alle acht Spalten nullable;derAdapter verlangtphasenabhängigvollständigeMetadaten. Keine Hilfe-/ResultTable-/OUTPUT-Parameter.

## Aufrufbeispiele

```sql
-- Öffentlichen Konstruktor verwenden; die Bridge braucht SQL-Preflight und ISJSON.
EXEC toolbelt_json.USP_JsonArray @Hilfe=1;
```

## Rechte

Keine direkten Fachcallergrants. Die öffentliche USP nutzt die reguläre Ownership-Chain. Die CLR-Bridge hat DataAccess/SystemDataAccess=None und liest keinen SQL-Katalog. Zentrale Dreiteilnamen benötigen Datenbankzugriff und Identitätsmapping. Keine Serverrolle oder Rechtevergabe aus dem Skill ableiten.

## Ressourcenbedarf

Bridge-Valuegrenze8388608 Codeunits,Key1024,Kind7, Kopierblöcke bis32768. Globales SQL-Budget und natives ISJSON bleiben im Caller. Der Legacy-Scanner hat kein AGF-Depthlimit127. Keine Zusage für Peakheap, Laufzeit oder fremde Transportallokationen.

## Nebenwirkungen

Nur nach globalem SQL-Preflight im kontrollierten Core verwenden. Die Bridge ist rein und liest keinen SQL-Katalog. SqlChars-Length vor begrenzter Kopie prüfen,Kind≤7,Key≤1024,Value≤8388608Codeunits; keine SQL-Shape-/Gesamtbudget-/Gruppen-/Duplikatprüfung. ObjectMode,Stage0/1 undPolicy1 müssen gültig sein.

Stage0 führt RawOnlyEntry aus:Metadaten/Kosten und RawUTF16,Key vorValue,kein Literal-/JSON-Syntaxscan und kein Fragment. Bei Kindjson muss der SQL-Adapter anschließend echtes ISJSON prüfen. Stage1 verwendet LegacyJson im selben kanonischen Entrykern,prüft decodiertesUTF16 und Literale und materialisiert das Fragment. Ungültige JSON-Syntax nach behauptetem nativen Precheck ist ein technischer Adapterfehler,keine freigegebene Alternative zu ISJSON. Genau eine Ergebniszeile; defensive Entryfehler können StrongMinimumBytes=NULL liefern. SQL-Adapter prüft alle Felder und widersprüchliche Receipts streng. Alle unerwarteten Exceptions werden ohne originalen Inputtext auf feste technische Präfixe abgebildet.

## Fehlerbehandlung

Defensive Entryfehler erscheinen als Zeile mit53603/53605/53606/53607/53608. Technische SQL6522-Präfixe sind TBX_JSON_ENTRY_ADAPTER_CONTRACT oder TBX_JSON_ENTRY_RESOURCE_FAILURE, ohne originale Inputmeldungen. Keine verwendbare Fehlerteilmenge; den phasenabhängigen Adaptervertrag beachten.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Merge-/Spill-/Grenzabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Kein allgemeines SQL/JSON-Abfrage-, Patch-, PrettyPrint-, Schema- oder Typinferenzwerkzeug. Geprüfte Bytebudgets sind keine Peakheap- oder Gesamtquerygarantie. Keine Installations- oder Rechteattestation. Inputdaten, Keys und Runtimebefunde privat halten.
