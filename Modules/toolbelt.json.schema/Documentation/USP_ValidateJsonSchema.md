# toolbelt_json.USP_ValidateJsonSchema

Die USP prüft ein JSON-Dokument gegen ein Schema des begrenzten Profils
`toolbelt-2020-12-v1`. Sie schreibt keine fachlichen Daten. Der optionale
ResultTable-Pfad verwendet den bestehenden Toolbelt-Helpervertrag.

Für den qualifizierten Datenpfad benötigt der Caller gemeinsam EXECUTE auf dieser USP, EXECUTE auf `toolbelt_core.USP_PrepareResultTable` und SELECT auf `toolbelt_json.FT_ValidateJsonSchemaInternal`. Die Helper-Metadaten werden auch bei direkter Ausgabe geprüft; der TVF-Zugriff erfolgt aus dynamischem SQL. Nur EXECUTE auf der öffentlichen USP reicht dafür nicht. Fehlende Helper-Sichtbarkeit ergibt 55601; fehlende Aufruf-/SELECT-Rechte ergeben 229. Der [native Rechtebericht](../../../Releases/1.0.0/JSON-SCHEMA-CALLER-PROFILE.md) trennt diese Zustände und verbleibende Gates. Diese Beschreibung ändert keine Rechte automatisch.

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema
 @Json=N'{"quantity":3}',
 @Schema=N'{"type":"object","required":["quantity"],"properties":{"quantity":{"type":"integer","minimum":1}}}';
```

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `NULL` | Input | Vollständiger JSON-Wert (Objekt, Array oder Skalar), maximal MaxDocumentBytes UTF-16-Bytes. Leerer/fehlerhafter Text ergibt INVALID_JSON; doppelte Keys sind ungültig und ungepaarte Surrogate UNSUPPORTED. NULL (Default) in Json oder Schema ergibt SQL_NULL nach Argumentprüfung. Keine Typkonvertierung oder Änderung des Dokuments. |
| `@Schema` | `nvarchar(max)` | `NULL` | Input | Boolean-Schema true/false oder Schemaobjekt des Profils toolbelt-2020-12-v1, maximal MaxSchemaBytes UTF-16-Bytes. Unterstützte Formen/Keywordtypen siehe JSON_SCHEMA_CONTRACT.md, Abschnitt Sichtbarer Profilumfang: $schema nur Draft2020-12; $defs, nichtrekursive lokale $ref, type, required, properties, additionalProperties, items, prefixItems, minItems/maxItems, minProperties/maxProperties, minLength/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum sowie title/description/$comment. Keine externen Referenzen, Zyklen, format, pattern, enum/const, Kombinatoren oder unbekannten Keywords. Alle Schemaorte einschließlich ungenutzter Definitionen werden vor der Instanz geprüft; NULL ergibt SQL_NULL nach Argumentprüfung. |
| `@Profile` | `varchar(32)` | `'toolbelt-2020-12-v1'` | Input | Einziger erlaubter Wert, exakt ASCII und längensensitiv: toolbelt-2020-12-v1 (Default) wählt die dokumentierte begrenzte Draft2020-12-Teilmenge. Kein Trim/Casefold; NULL/leer/andere Werte werfen 55600/1. Keine Behauptung vollständiger Draftkonformität. |
| `@MaxDocumentBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Bytes, Default 16777216; NULL/außerhalb wirft 55600/1, Dokumentüberschreitung liefert LIMIT/DOCUMENT_BYTES. |
| `@MaxSchemaBytes` | `bigint` | `1048576` | Input | Ganzzahl 1..1048576 UTF-16-Bytes, Default 1048576; NULL/außerhalb wirft 55600/1, Schemaüberschreitung liefert LIMIT/SCHEMA_BYTES. |
| `@MaxDepth` | `int` | `128` | Input | Ganzzahl 1..128 offene Container in Dokument und Schema, Default 128; NULL/außerhalb wirft 55600/1. Parser beendet eine Überschreitung als LIMIT, nicht als gültiges Boolurteil. |
| `@MaxEvaluationSteps` | `bigint` | `1000000` | Input | Ganzzahl 1..1000000 abstrakte Arbeitseinheiten über sämtliche Prüfphasen, Default 1000000; NULL/außerhalb wirft 55600/1. Keine Millisekunden-/CPUzeitangabe; Erschöpfung ergibt LIMIT/IsValid=NULL. |
| `@MaxErrors` | `int` | `100` | Input | Ganzzahl 0..100 Diagnosezeilen, Default 100; 0 unterdrückt ERROR-Zeilen, SUMMARY bleibt. NULL/außerhalb wirft 55600/1. Begrenzt nur die Diagnose, nicht die vollständige Evaluation; ErrorsTruncated weist Kürzung aus. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

Die zehn Spalten haben die feste Reihenfolge:
`RowKind varchar(8) NOT NULL`, `ErrorOrdinal int NOT NULL`,
`Status varchar(24) NOT NULL`, `Profile varchar(32) NOT NULL`,
`IsValid bit NULL`, `DocumentPointer nvarchar(max) NULL`,
`SchemaPointer nvarchar(max) NULL`, `Keyword nvarchar(128) NULL`,
`ErrorCode varchar(32) NULL`, `ErrorsTruncated bit NOT NULL`.
Zeichenfelder verwenden BIN2. SUMMARY hat Ordinal0; ERROR-Zeilen folgen mit
aufeinanderfolgenden Ordinals. Alle Zeilen tragen den endgültigen Status und
Truncationwert. `IsValid` ist nur bei VALID1 und INVALID_INSTANCE0 gesetzt.

Der [Gesamtvertrag](../../../Documentation/Architecture/JSON_SCHEMA_CONTRACT.md)
ist autoritativ für Keywords, Fehlercodes, RFC-Pointer, Priorität und Kosten.
Insbesondere ist dieses Profil keine vollständige2020-12-Implementierung.
Unbekannte Keywords, andere Drafts, externe oder rekursive Referenzen werden
explizit abgewiesen. Auch ungenutzte Definitionen werden geprüft. Zahlen
werden ohne Rundung oder Gleitkomma verglichen; Stringlängen zählen Unicode-
Skalare. Duplikatschlüssel und ungepaarte Surrogate sind keine gültigen Inputs.

Ungültige Argumente werfen55600/1. Ein inkohärenter interner Bridge-/
Transportvertrag wirft55601/1. Technische CLR-/Engine-/Helperfehler bleiben
technische Fehler. Eine reservierte Caller-TempTable wird vor dem internen
Batch abgewiesen. Die vollständige Antwort entsteht vor einer ResultTable-
Mutation; eigene Transaktionen oder committable Caller-Savepoints schützen
diesen Schreibpfad, ohne fremde oder doomed Callertransaktionen zurückzurollen.

Native API-, Clientmetadaten-, Rechte- und Lifecycle-Nachweise sind noch offen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#json-schema).
