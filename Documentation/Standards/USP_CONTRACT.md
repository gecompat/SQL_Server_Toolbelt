# USP-Vertrag – SQL Server Toolbelt

Dieser Vertrag ist verbindlich für öffentliche und interne Toolbelt-Stored-Procedures. Er ist als Architekturvertrag definiert; eine gemeinsame Runtime-Infrastruktur wird erst durch ein freigegebenes Arbeitspaket implementiert.

## 1. Standardparameter

### Jede Toolbelt-USP

```sql
@Hilfe bit = 0
```

### Jede sinnvoll diagnostizierbare Toolbelt-USP zusätzlich

```sql
@Debug tinyint = 0
```

### Jede USP mit fachlichem tabellarischem Resultset

Die letzten Standardparameter stehen exakt in dieser Reihenfolge:

```sql
@ResultTable sysname = NULL,
@KeepData   bit      = 0,
@Debug      tinyint  = 0,
@Hilfe      bit      = 0
```

Infrastrukturprozeduren ohne eigenes fachliches Resultset erhalten keinen bedeutungslosen `@ResultTable`-Parameter. Eine zu bearbeitende Tabelle erhält einen eindeutigen fachlichen Parameternamen, beispielsweise `@ResultTableToAlter`.

## 2. Hilfevertrag

Sobald `@Hilfe = 1` gilt:

- wird ausschließlich das standardisierte Help-Resultset ausgegeben;
- wird die fachliche Funktion nicht ausgeführt;
- entstehen keine fachlichen Seiteneffekte;
- werden fachliche Pflichtparameter nicht validiert;
- werden `@ResultTable`, `@KeepData` und `@Debug` ignoriert;
- wird keine ResultTable geprüft oder verändert;
- werden keine Debug-Messages erzeugt.

Damit ein reiner Hilfeaufruf möglich ist, erhalten fachlich verpflichtende Parameter technische Defaults, normalerweise `NULL`. Das Help-Resultset kennzeichnet getrennt, ob ein Parameter bei `@Hilfe = 0` fachlich erforderlich ist.

## 3. Einheitliches Help-Resultset

```text
HelpContractVersion  varchar(16)    NOT NULL
SchemaName           sysname        NOT NULL
ObjectName           sysname        NOT NULL
Section              varchar(32)    NOT NULL
Ordinal              int            NOT NULL
ItemName             sysname        NULL
SqlDataType          varchar(256)   NULL
IsRequired           bit            NULL
IsNullable           bit            NULL
DefaultValue         nvarchar(4000) NULL
Description          nvarchar(max)  NOT NULL
ExampleSql           nvarchar(max)  NULL
```

Pflicht-Sections:

- `DESCRIPTION` – fachliche Beschreibung;
- `PARAMETER` – Name, Typ, technischer Default, fachliche Pflicht und Beschreibung;
- `RESULT_COLUMN` – Reihenfolge, Name, Typ, Nullability und fachliche Bedeutung;
- `EXAMPLE` – mindestens ein vollständiger Beispielaufruf.

Optionale Sections: `ERROR`, `PERMISSION`, `LIMITATION`.

Das Format ist stabil, maschinenlesbar und für KI-Systeme ohne Quellcodeanalyse verständlich.

## 4. Fachliches Resultset

Bei `@Hilfe = 0` liefert eine USP höchstens ein fachliches Resultset.

- Debug-Ausgaben sind Messages, keine Resultsets.
- Unbeabsichtigte zusätzliche `SELECT`-Resultsets sind unzulässig.
- Eine Tabelle garantiert keine Zeilenreihenfolge. Falls Reihenfolge fachlich relevant ist, enthält der Vertrag eine explizite Ordinal- oder Sortierspalte.

## 5. Routing über `@ResultTable`

| Wert | Verhalten |
|---|---|
| `@ResultTable IS NULL` | Fachliches Resultset normal mit `SELECT` ausgeben. |
| lokaler Temp-Tabellenname, z. B. `N'#Result1'` | Resultset in die bereits vorhandene lokale Temp-Tabelle schreiben; kein fachliches `SELECT` ausgeben. |

Weitere Regeln:

- Globale Temp-Tabellen, permanente Tabellen und Tabellenvariablen gehören nicht zu diesem Vertrag.
- Die USP kennt ihren eigenen Resultset-Vertrag und verwendet eine explizite Spaltenliste.
- Verschachtelte USPs rufen andere USPs über deren `@ResultTable`-Vertrag auf.
- Generisches verschachteltes `INSERT ... EXEC` ist nicht Bestandteil der Architektur.
- Name und Datentyp einer vorhandenen Dummyspalte sind beliebig.
- Eine leere Tabelle mit abweichendem Schema gilt als zur Anpassung freigegeben.

## 6. `@KeepData`

| Zustand der Temp-Tabelle | `@KeepData = 0` | `@KeepData = 1` |
|---|---|---|
| leer, Schema passt | einfügen | einfügen |
| leer, Schema passt nicht | Schema anpassen, einfügen | Schema anpassen, einfügen |
| enthält Daten, Schema passt | vorhandene Daten ersetzen | Ergebnis anhängen |
| enthält Daten, Schema passt nicht | Daten entfernen, Schema anpassen, einfügen | mit verständlichem Fehler abbrechen |

`@KeepData = 0` ist ausdrücklich Replace-Semantik.

### Passendes Schema

- Vorhandene Indizes und Constraints dürfen bestehen bleiben.
- Sie gehören nicht zum Resultset-Vertrag und werden nicht allein deshalb geprüft oder entfernt.
- Verhindert ein Index oder Constraint den Insert, wird der tatsächliche Fehler mit angemessenem Kontext weitergegeben.

### Notwendiger Schemaumbau

- Vollständiger Preflight vor der ersten Mutation.
- Blockiert ein Index, Constraint, eine computed column oder eine andere Dependency die Änderung, erfolgt Abbruch.
- Keine blockierende Dependency wird automatisch entfernt.
- Daten werden nicht vorzeitig gelöscht.
- Die Fehlermeldung nennt Zieltable, blockierendes Objekt und notwendige Änderung.

## 7. Debug

| Wert | Grundbedeutung |
|---:|---|
| `0` | keine Debug-Ausgabe |
| `1` | wesentliche Verarbeitungsschritte |
| `2` | Entscheidungen, ermittelte Objekte und Zeilenzahlen |
| `3` | Detailmetadaten und generiertes dynamisches SQL |
| `4` bis `254` | für modulbezogene Stufen reserviert |
| `255` | maximaler interner Trace; kein stabiler öffentlicher Detailvertrag |

Debug verwendet Messages, nicht `SELECT`-Resultsets. Vertrauliche Runtime-Werte dürfen diagnostisch erscheinen; echte Secrets werden nicht aktiv ausgegeben. Fehler werden mit `THROW` signalisiert; Debug-Messages ersetzen kein Error Handling.

## 8. Error Handling

- Parameter und fachliche Voraussetzungen einmalig an geeigneten Grenzen prüfen.
- `TRY/CATCH` verwenden, wenn Transaktionen, Cleanup, dynamisches SQL oder gekoppelte Mutationen dies erfordern.
- Originalfehler und Cleanup-Fehler nicht verschleiern.
- Kein zeilenweises oder nach jedem Einzelstatement wiederholtes Error Handling ohne fachlichen Nutzen.
- Inline TVFs werden nicht wegen eines allgemeinen Error-Handling-Wunsches in Multi-statement TVFs umgebaut.

## 9. Pflicht-Contract-Tests

Für jede USP mit tabellarischem Resultset mindestens:

1. Parameternamen, Datentypen, Defaults und Reihenfolge;
2. reiner `@Hilfe = 1`-Aufruf ohne fachliche Pflichtparameter;
3. Help-Resultset-Struktur und alle Pflicht-Sections;
4. Help-Modus ignoriert `@ResultTable`, `@KeepData` und `@Debug` und verändert keine Tabelle;
5. `@ResultTable IS NULL` gibt genau ein fachliches Resultset aus;
6. gesetzte `@ResultTable` gibt kein fachliches `SELECT` aus;
7. beliebiger Dummyspaltenname und beliebiger Dummyspaltentyp;
8. alle vier `@KeepData`-Konstellationen;
9. passendes Schema mit zusätzlichen nicht blockierenden Indizes;
10. blockierende Dependency führt vor der ersten Mutation zum Fehler;
11. verschachtelter USP-Aufruf über `@ResultTable` ohne `INSERT ... EXEC`;
12. Collation- und Datentypvertrag des Resultsets;
13. Debug-Ausgabe nur als Messages;
14. Fehlersemantik und Transaktionszustand.
