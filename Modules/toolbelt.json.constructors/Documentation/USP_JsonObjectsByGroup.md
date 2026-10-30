# toolbelt_json.USP_JsonObjectsByGroup

Öffentliche T-SQL-USP ab additiver Version 1.1.0; genau ein JSON-Object je
vorhandener positiver GroupOrdinal. Einzelfreigabe vom 2026-10-01 und
[kanonischer Vertrag](../../../Documentation/Architecture/JSON_GROUP_CONSTRUCTORS_CONTRACT.md).
Source implementiert; ausgewählte native API-/Budget-/Clientprüfungen erfolgreich innerhalb insgesamt fehlgeschlagener früherer Adapter. Finale fokussierte Metadaten-/Lifecycleadapter erfolgreich; neue Minimalrechte und separater aktueller CI-/PR-Mergegate offen. Abgegrenzte Evidenz siehe [Tests](../Tests/README.md).

## Signatur und Input

```sql
EXEC toolbelt_json.USP_JsonObjectsByGroup
 @EntriesTable = N'#Entries', @MaxEntries = 10000,
 @MaxTotalValueBytes = 2097152, @MaxResultBytes = 2097152,
 @ResultTable = NULL, @KeepData = 0, @Debug = 0, @Hilfe = 0;
```

EntriesTable ist caller-lokale #Temp mit GroupOrdinal int, Ordinal int,
ValueKind nvarchar(max), Value nvarchar(max), Key nvarchar(max).
Exakte Systemtypen, keine Alias-/computed-Typen; zusätzliche Spalten ignoriert.
GroupOrdinal und Ordinal positiv/nicht NULL, (GroupOrdinal,Ordinal) eindeutig,
Lücken erlaubt. Alle bestehenden ValueKind-/Literal-/Unicode-/Escapingregeln
verwenden den einzigen USP_JsonConstructInternal-Kern.
Keys nicht NULL/leer, maximal 1024 UTF-16-Codeeinheiten; vollständige Bytes und Längen bestimmen Identität. Duplicate Keys nur innerhalb derselben Gruppe verboten.

## Ausgabe, Grenzen und Fehler

GroupOrdinal int NOT NULL, JsonValue nvarchar(max) NOT NULL mit BIN2-Collation.
SELECT sortiert nach GroupOrdinal; Entry-Ordinal bestimmt die Serialisierung.
ResultTable garantiert keine physische Reihenfolge. Leerer Input hat null
Zeilen; Replace leert trotzdem das Ziel, Append bewahrt kompatible Daten.
Die bisherigen ungruppierten APIs behalten eine Zeile und [] beziehungsweise {}.

Ressourcen gelten global: MaxEntries bis 100000, Value- und Ergebnisbytes
je bis 16777216; Defaults 10000/2097152/2097152. Keine Unlimited-/Resetgrenze
je Gruppe. Ergebnisbytes zählen UTF-16 einschließlich Keys/Escapes/Syntax;
Gruppenordinals/SQL-Overhead sind nicht Teil dieses Nutzdatenbudgets.
Help zuerst ohne fachliche Prüfung oder Mutation, Debug nur sichere Messages.
NULL für KeepData/Debug/Hilfe entspricht 0; Ressourcen-NULL ist ungültig.

Die feste Fehlerpriorität und States stehen im Vertrag: insbesondere
GroupOrdinal 53602/2, Composite-Ordinal 53602/1, Duplicate Key 53604/1,
globale Ressourcen 53609. Enginefehler unverändert. Alle Gruppen vollständig
validieren und materialisieren vor der ersten Ausgabe/Zielmutation; keine
Teilmutation bei spätem Gruppenfehler. Keine atomare Netzwerkübertragungszusage.
Eigene Transaktion oder Caller-savepoint; niemals Callercommit/fullrollback.

Dependency toolbelt.core.result-table >=1.0.0 same_database. Lokale/zentrale
Verwendung derselben Source, keine CLR-/Provider-/Rechte-/Configänderung.
Beispiele: [JsonGroups.sql](../Examples/JsonGroups.sql).

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Zusätzlich GroupOrdinal int, positiv/nicht NULL; Ordinals und Keys müssen nur innerhalb dieser Gruppe eindeutig sein. Ausgabe nach GroupOrdinal; leere Tabelle ergibt keine Gruppenzeilen. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#json-konstruktion).
