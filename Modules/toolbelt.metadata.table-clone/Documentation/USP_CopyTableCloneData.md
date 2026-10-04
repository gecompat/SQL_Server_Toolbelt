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

| Position | Parameter | Typ / Default | Bedeutung |
|---|---|---|---|
| 1 | TableMap | sysname = NULL | Bestehende lokale fünfspaltige Map, fachlich erforderlich |
| 2 | IdentityMode | varchar(16) = NULL | Byteexakt KEEP oder REGENERATE, fachlich erforderlich |
| 3 | ConsistencyMode | varchar(16) = NULL | Byteexakt SNAPSHOT oder SERIALIZABLE, fachlich erforderlich |
| 4 | RowLimit | bigint = 100000 | Positiv; höchstens 100000 global, nur absenkbar |
| 5 | PayloadByteLimit | bigint = 16777216 | Positiv; höchstens 16 MiB SQL-Nutzdaten, nur absenkbar |
| 6 | ResultTable | sysname = NULL | Bestehende lokale Ausgabe-Temp-Tabelle oder SELECT |
| 7 | KeepData | bit = 0 | Kanonische Replace-/Append-Ausgabe |
| 8 | Debug | tinyint = 0 | Messages; kein zusätzliches Resultset |
| 9 | Hilfe | bit = 0 | Ausschließlich standardisierte Hilfe |

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
