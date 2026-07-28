# USP-Vertrag – SQL Server Toolbelt

Dieser Vertrag ist verbindlich für alle öffentlichen und internen Toolbelt-Stored-Procedures (USPs). Er wird dokumentiert, aber in diesem PR noch nicht implementiert.

---

## 1. Standardparameter

### Jede Toolbelt-USP (öffentlich oder intern)

```sql
@Hilfe bit = 0
```

### Jede sinnvoll diagnostizierbare Toolbelt-USP zusätzlich

```sql
@Debug tinyint = 0
```

### Jede Toolbelt-USP mit fachlichem tabellarischem Resultset

Als letzte Standardparameter exakt in dieser Reihenfolge:

```sql
@ResultTable sysname  = NULL,
@KeepData   bit       = 0,
@Debug      tinyint   = 0,
@Hilfe      bit       = 0
```

### Infrastrukturprozeduren

Infrastrukturprozeduren ohne eigenes Resultset erhalten keinen bedeutungslosen `@ResultTable`-Parameter. Sie verwenden fachlich eindeutige Namen, z. B. `@ResultTableToAlter`.

---

## 2. Hilfe-Verhalten (`@Hilfe = 1`)

Bei `@Hilfe = 1`:
- Ausschließlich das standardisierte Help-Resultset ausgeben (Struktur siehe Abschnitt 4).
- Fachliche Funktion und Seiteneffekte **nicht** ausführen.
- Pflichtparameter **nicht** fachlich validieren.
- `@ResultTable`, `@KeepData`, `@Debug` ignorieren.
- Keine ResultTable prüfen oder ändern.
- Keine Debug-Messages erzeugen.

Für reine Hilfeaufrufe erhalten fachlich verpflichtende Parameter technische Defaults (meist `NULL`). Das Help-Resultset kennzeichnet diese Parameter als `IsRequired = 1` für `@Hilfe = 0`.

---

## 3. Fachliches Resultset (`@Hilfe = 0`)

- Höchstens ein fachliches Resultset.
- Debug-Ausgaben sind **Messages**, keine Resultsets.
- Keine unbeabsichtigten zusätzlichen `SELECT`-Resultsets.

### Routing über `@ResultTable`

| Wert | Verhalten |
|---|---|
| `@ResultTable IS NULL` | Normales `SELECT`; Ergebnis direkt zurückgeben. |
| `@ResultTable = N'#Result1'` | Bereits vorhandene lokale Temp-Tabelle; Ergebnis dort einfügen; kein fachliches `SELECT`. Verschachtelte USPs verwenden ebenfalls deren `@ResultTable`. |

Kein generisches verschachteltes `INSERT ... EXEC` bei `@ResultTable`.

---

## 4. Help-Resultset (Struktur)

Das Help-Resultset ist stabil, maschinenlesbar und KI-lesbar.

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

### Pflicht-Sections

| Section | Inhalt |
|---|---|
| `DESCRIPTION` | Funktionsbeschreibung |
| `PARAMETER` | Je Parameter: Name, Typ, technischer Default, fachliche Pflicht (`IsRequired`) |
| `RESULT_COLUMN` | Resultset-Spalten: Reihenfolge, Name, Typ, Nullability, fachliche Beschreibung |
| `EXAMPLE` | Mindestens ein vollständiger Beispielaufruf |

### Optionale Sections

`ERROR`, `PERMISSION`, `LIMITATION`

---

## 5. `@KeepData`-Semantik

Für Einfügeoperationen in eine `@ResultTable`:

| Zustand der Temp-Tabelle | `@KeepData = 0` | `@KeepData = 1` |
|---|---|---|
| Leer + passendes Schema | Einfügen | Einfügen |
| Leer + unpassendes Schema | Schema anpassen, einfügen | Schema anpassen, einfügen |
| Daten + passendes Schema | Daten ersetzen (Replace-Semantik) | Anfügen (Append-Semantik) |
| Daten + unpassendes Schema | Daten entfernen, Schema anpassen, einfügen | Abbruch mit verständlicher Meldung |

`@KeepData = 0` ist ausdrücklich Replace-Semantik.

**Bei passendem Schema:** Indizes und Constraints dürfen bestehen bleiben; sie gehören nicht zum Resultvertrag. Falls ein Index oder Constraint den Insert verhindert, ist der tatsächliche Fehler sauber weiterzugeben.

**Bei nötigem Schemaumbau mit blockierendem Index, Constraint, Computed Column oder anderer Dependency:**
- Vollständiger Preflight vor der ersten Mutation.
- Vor erster Mutation abbrechen; nichts automatisch entfernen; keine Daten vorzeitig löschen.
- Fehlermeldung nennt das blockierende Objekt und die benötigte Änderung.

---

## 6. Debug-Verhalten (`@Debug`)

| Wert | Ausgabe |
|---|---|
| 0 | Keine Ausgabe |
| 1 | Hauptschritte |
| 2 | Entscheidungen, Objekte, Zeilenzahlen |
| 3 | Detailmetadaten, generiertes SQL |
| > 3 | Reserviert |

Nur RAISERROR/PRINT-Messages; keine Resultsets. Echte Secrets (Passwörter, Tokens, API-Keys, private Schlüssel) dürfen nie ausgegeben werden.

---

## 7. Implementierungshinweis

Dieser Vertrag wird in diesem PR ausschließlich dokumentiert, nicht implementiert.
