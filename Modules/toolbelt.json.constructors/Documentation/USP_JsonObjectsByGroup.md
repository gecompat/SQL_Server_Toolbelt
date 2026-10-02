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
