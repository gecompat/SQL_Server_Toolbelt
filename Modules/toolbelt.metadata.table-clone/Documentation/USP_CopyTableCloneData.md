# USP_CopyTableCloneData

Kopiert einen ausdrücklich gemappten Verbund innerhalb der Installationsdatenbank
in leere formgleiche Ziele. Die einzeln freigegebene Erweiterung gehört zu
`toolbelt.metadata.table-clone` 4.1.0. Sourcevorbereitung ist kein Runtime-Nachweis;
der normale Copy-/Client-/Lifecycle-Scope ist auf Linux2019 und Windows2025/CU8
bestanden; vier dynamische Identity-Zustände und zwei SNAPSHOT-Konkurrenzfälle
separat auf Linux2019 geprüft. Abgeschlossene Teilnachweise aus Fehlerläufen
bleiben ausdrücklich getrennt. Head-CI separat im PR; Release unveröffentlicht.
Genaue Grenzen im Architekturvertrag.
Maßgeblich ist der [Datenkopievertrag](../../../Documentation/Architecture/TABLE_CLONE_DATA_COPY_CONTRACT.md).

## Parameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@TableMap` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Fachlich erforderlich, NULL ungültig. Hier müssen die fünf Spalten zusätzlich exakt in der genannten Reihenfolge und ohne IDENTITY stehen. Source und Target müssen beide existieren, formgleich und als Mengen von ObjectIDs disjunkt sein; jedes Ziel muss leer sein. Keine Filter/Upserts/CrossDB oder impliziten Typkonvertierungen. |
| `@IdentityMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: KEEP kopiert Identitywerte unter vorhandenen erforderlichen Rechten; REGENERATE lässt Identityspalten beim Transport weg und erzeugt neue Zielwerte. REGENERATE ist bei identityabhängigen Beziehungen ausgeschlossen. NULL/leer/andere Werte ungültig. Keine neue ID-Zuordnung/RESEED; Identity-Zählerfortschritt kann trotz Rollback bleiben. |
| `@ConsistencyMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: SNAPSHOT verwendet die bereits aktivierte Datenbankoption; SERIALIZABLE hält Quellbereichssperren. NULL/leer/andere Werte ungültig. Keine automatische Optionsänderung; aktive Callertransaktion wird abgelehnt. |
| `@RowLimit` | `bigint` | `100000` | Input | Ganzzahl 1..100000 global kopierte Zeilen über alle gemappten Tabellen, Default 100000. NULL/außerhalb ungültig; Überschreitung verhindert die gesamte Kopie, kein TOP-Teilimport. |
| `@PayloadByteLimit` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 Bytes globaler tatsächlich transportierter SQL-Nutzdaten, Default 16777216. Summe bigint-DATALENGTH, NULL zählt 0; computed/rowversion und bei REGENERATE Identity zählen nicht. Kein Gesamt-Heap-/Dateigrößenbudget; NULL/außerhalb ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht TableMap. Die späte ResultTable-Ausgabe ist Teil derselben eigenen Transaktion wie Kopie/FK-DDL. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Aktuell keine eigenen zusätzlichen Copy-Diagnosemessages; bei ResultTable wird der Wert an den Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

Hilfe umgeht fachliche Pflichtparameter und führt keine Datenkopie aus.
Map ist die bestehende Form MapOrdinal int und vier nvarchar(max)-Identifier,
alle NOT NULL; 1..64 positive eindeutige Ordinals, je Name 1..128 UTF16-Einheiten.
Quelle/Ziel sind normale SameDB-Tabellen mit eindeutigen disjunkten ObjectIDs.
Kein Filter, CrossDB, Upsert oder Überschreiben. Keine implizite Typkonvertierung.

## Ergebnis

Genau eine Erfolgszeile mit MappedTables int, CopiedRows bigint,
PayloadBytes bigint, CreatedForeignKeys int und Status varchar(16), sämtlich
NOT NULL. Status ist COPIED. PayloadBytes zählt bigint-DATALENGTH tatsächlich
transportierter Werte; NULL zählt 0, computed/rowversion und bei REGENERATE
Identity werden ausgelassen. ResultTable liefert kein fachliches SELECT.

## Transaktion und Grenzen

Keine aktive Callertransaktion. SNAPSHOT benötigt bereits aktivierte DB-Option;
SERIALIZABLE verwendet gehaltene Quellsperren. Die eigene Transaktion umfasst
Targetwrites, fehlende FK-DDL und späte ResultTable-Ausgabe. Targets werden aktuell
auf Leerheit geprüft und bis Commit exklusiv geschützt. Keine automatische
Konfiguration oder externe Atomikzusage. Identity-Zählerfortschritt kann trotz
Rollback bleiben; kein RESEED oder neue ID-Zuordnung. Fremder Identityzustand
wird nicht durch pauschales OFF repariert. Normale Transportspalten werden
mengenbasiert kopiert; nur bei null Transportspalten gilt begrenztes DEFAULT VALUES.

Bestehende passende Target-FKs bleiben unverändert; zusätzliche oder abweichende
FKs blockieren. Fehlende gemappte FKs werden nach Datenkopie mit ihren bekannten
Quellzuständen angelegt. Vorhandene aktive Target-FK-Zyklen blockieren, Self-FKs
werden als ein mengenbasiertes INSERT geprüft. REGENERATE bei identityabhängigen
Beziehungen ist ausgeschlossen. Keine Constraint-Deaktivierung. Aktive Target-
Trigger, RLS und nicht tabellenlokale DEFAULT/CHECK/computed-Ausführung blockieren.

Vorhandene DB-VIEW DEFINITION und lesbare Dependency-/RLS-Kataloge sowie
Source-SELECT/Target-SELECT/INSERT sind erforderlich. Nur bei fehlenden FKs
gelten zusätzlich Server-DDL-Vollsicht und erforderliche ALTER-/REFERENCES-Rechte;
relevante oder unbekannte DDL-Seiteneffekte blockieren. KEEP benötigt vorhandenes
Identity-ALTER. Keine Rechteerteilung, Parserinstallation oder Owneränderung.

## Beispiel

```sql
CREATE TABLE #CopyMap
(
    MapOrdinal int NOT NULL,
    SourceSchema nvarchar(max) NOT NULL,
    SourceTable nvarchar(max) NOT NULL,
    TargetSchema nvarchar(max) NOT NULL,
    TargetTable nvarchar(max) NOT NULL
);
-- Beide synthetischen Tabellen bestehen bereits; TargetOrders ist leer und formgleich.
INSERT #CopyMap VALUES (1, N'dbo', N'SourceOrders', N'dbo', N'TargetOrders');
EXEC toolbelt_metadata.USP_CopyTableCloneData
    @TableMap = N'#CopyMap', @IdentityMode = 'KEEP',
    @ConsistencyMode = 'SERIALIZABLE';
DROP TABLE #CopyMap;
```

Eigene Daten-/FK-Fehler 53940..53946 sowie bestehende Core-/Helper- und Enginefehler
bleiben getrennt. Caller-TX: nichtdoomendes RAISERROR/RETURN mit
TBX_TABLE_CLONE_COPY_CALLER_TRANSACTION. Testscope, offene Nachweise und Lifecycle
stehen im [Manifest](../module.yaml) und in der [Testmatrix](../Tests/TABLE_CLONE_CONTRACT_TEST_MATRIX.md).

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#tabellenklon).
