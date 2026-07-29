# toolbelt_core.USP_PrepareResultTable

**Typ:** Infrastruktur-Stored-Procedure ohne eigenes fachliches Resultset

**Version:** `1.0.0`

**Status:** `implemented`; Runtime-Validierung `partially validated`

## Zweck

`USP_PrepareResultTable` bereitet eine vorhandene lokale Temp-Tabelle so vor, dass eine fachliche Toolbelt-USP ihr bekanntes Resultset anschließend mit expliziter Spaltenliste einfügen kann. Das gewünschte Spaltenschema stammt aus einer bereits vorhandenen Referenztabelle.

Die Procedure löst damit nicht die fachliche Datenerzeugung und führt kein generisches `INSERT ... EXEC` aus. Eine resultseterzeugende USP behält genau eine kanonische Fachlogik und entscheidet selbst zwischen normalem `SELECT` und explizitem Insert in `@ResultTable`.

## Signatur

```sql
CREATE OR ALTER PROCEDURE toolbelt_core.USP_PrepareResultTable
(
      @ResultTableToAlter sysname       = NULL
    , @LikeTable          nvarchar(776) = NULL
    , @KeepData           bit           = 0
    , @Debug              tinyint       = 0
    , @Hilfe              bit           = 0
)
```

Die Parameterreihenfolge ist Teil des öffentlichen Vertrags.

## Parameter

| Name | Typ | Default | Fachlich erforderlich | Beschreibung |
|---|---|---:|---:|---|
| `@ResultTableToAlter` | `sysname` | `NULL` | ja | Vorhandene lokale Ziel-Temp-Tabelle. Genau ein führendes `#`, höchstens 116 Zeichen, kein reservierter Präfix `#tbx_`. |
| `@LikeTable` | `nvarchar(776)` | `NULL` | ja | Referenztabelle als `#LocalTemplate`, `Schema.Table` oder `Database.Schema.Table`. |
| `@KeepData` | `bit` | `0` | nein | `0` = Replace; `1` = vorhandene Daten nur bei passendem Schema erhalten. |
| `@Debug` | `tinyint` | `0` | nein | Debug-Messages gemäß Stufenvertrag. |
| `@Hilfe` | `bit` | `0` | nein | Gibt ausschließlich das standardisierte Help-Resultset aus. |

Explizit übergebenes `NULL` für die optionalen Steuerparameter `@KeepData`, `@Debug` oder `@Hilfe` verwendet den jeweiligen technischen Default.

## Schema- und Datenverhalten

| Zielzustand | `@KeepData = 0` | `@KeepData = 1` |
|---|---|---|
| leer, Schema passt | keine Mutation | keine Mutation |
| leer, Schema weicht ab | in-place anpassen | in-place anpassen |
| Daten vorhanden, Schema passt | Daten mit `TRUNCATE` entfernen | Daten erhalten |
| Daten vorhanden, Schema weicht ab | Daten entfernen und in-place anpassen | Fehler `51025` vor jeder Mutation |

Der Schemaumbau:

1. führt den vollständigen read-only Preflight aus;
2. startet eine eigene Transaktion oder setzt einen Invocation-spezifischen Savepoint;
3. fügt eine eindeutige Anchor-Spalte hinzu;
4. ersetzt die alten Spalten durch das normalisierte Referenzschema;
5. entfernt die Anchor-Spalte;
6. erhält die Identität und den Scope des lokalen Temp-Objekts.

Die Zieltable wird nicht gedroppt und neu erstellt.

## Unterstützte Schemaquellen

- lokale Temp-Tabelle;
- reguläre User Table als `Schema.Table`;
- reguläre User Table als `Database.Schema.Table`.

Nicht unterstützt:

- dieselbe lokale Temp-Tabelle als Ziel und Referenz;
- globale Temp-Tabelle;
- View oder Synonym;
- Tabellenvariable;
- einteiliger regulärer Name;
- Linked Server beziehungsweise vierteiliger Name;
- nicht sichtbare Catalog-Metadaten.

Bei zentraler Installation bezieht sich `Schema.Table` auf die Installationsdatenbank. Eine Tabelle in einer konsumierenden Datenbank benötigt daher den dreiteiligen Namen.

## Datentypvertrag

Version `1.0.0` verwendet eine Whitelist:

- Ganzzahl- und Bit-Typen;
- `decimal`, `numeric`, Money- und Gleitkommatypen;
- Datum-/Zeittypen einschließlich Scale;
- `char`, `varchar`, `nchar`, `nvarchar` einschließlich `max`;
- `binary`, `varbinary` einschließlich `max`;
- `uniqueidentifier`, `sql_variant`, untypisiertes `xml`;
- `hierarchyid`, `geometry` und `geography`.

Länge, Precision, Scale, Nullability und Zeichencollation bleiben erhalten. Alias Types werden auf ihren Systemtyp, typisiertes XML auf untypisiertes `xml` und Sparse-Spalten auf normale Spalten normalisiert.

Nicht unterstützt sind unter anderem Identity, computed, hidden, generated-always, Column Set, verschlüsselte Spalten, `rowversion`/`timestamp`, `text`/`ntext`/`image`, benutzerdefinierte CLR Types und neue, noch nicht versioniert freigegebene Systemtypen.

## Namens- und Collation-Semantik

Technische Namen werden explizit mit `Latin1_General_100_BIN2` verglichen. Diese Collation ist für die Zielversionen als deterministische BIN2-Semantik gewählt. Der reservierte interne Präfix `#tbx_` wird unabhängig von Groß-/Kleinschreibung erkannt.

Zeichenspalten erhalten ausdrücklich die Collation der Referenzspalte. Der Collation-Name stammt aus Catalog-Metadaten und wird gegen `sys.fn_helpcollations()` geprüft.

## Ergebnis- und Fehlervertrag

- kein fachliches Resultset;
- Erfolg: `RETURN 0`;
- `@Hilfe = 1`: genau ein Help-Resultset, keine Debug-Message und keine Mutation;
- Vertragsfehler: `THROW` im Bereich `51020` bis `51029`;
- Engine-Fehler während Metadatenzugriff oder DDL: ursprünglicher Fehler mit `THROW;`.

| Nummer | Bedeutung |
|---:|---|
| `51020` | Zielname fehlt oder ist unzulässig. |
| `51021` | Zieltable ist nicht sichtbar. |
| `51022` | Referenzname fehlt, besitzt eine unzulässige Form oder bezeichnet dieselbe lokale Temp-Tabelle wie das Ziel. |
| `51023` | Referenztabelle ist nicht sichtbar oder kein unterstützter Tabellentyp. |
| `51024` | Referenzspalte ist nicht unterstützt oder nicht einfügbar. |
| `51025` | `@KeepData = 1` verhindert den Schemaumbau. |
| `51026` | Dependency blockiert den Schemaumbau. |
| `51027` | Collation oder Typ kann nicht sicher in DDL überführt werden. |
| `51028` | Transaktionszustand oder Savepoint-Rollback ist nicht kontrollierbar. |
| `51029` | Generiertes DDL ist unvollständig oder überschreitet das dokumentierte Limit. |

Die Lifecycle-Skripte verwenden zusätzlich `51030` bis `51039` für Plattform-, Permission-, Manifest-, Kollisions-, Bestätigungs-, Dependency- und Parallelitäts-Gates. Ein Source-Hash ist ausschließlich diagnostisch und verhindert kein erneutes Deployment.

## Transaktionen

- Ohne Caller-Transaktion startet und committed die Procedure eine eigene Transaktion.
- In einer committable Caller-Transaktion verwendet sie ausschließlich einen eindeutigen Savepoint.
- Bei Fehler wird eine eigene Transaktion vollständig beziehungsweise eine Caller-Transaktion nur bis zum Savepoint zurückgerollt.
- Bei `XACT_STATE() = -1` wird kein unzulässiger Savepoint-Rollback versucht.
- Die Procedure committed oder rollt niemals die vollständige Caller-Transaktion zurück.

## Debug

| Stufe | Ausgabe |
|---:|---|
| `0` | keine Debug-Message |
| `1` | Hauptschritte |
| `2` | Objekt-IDs, Daten- und Schemaentscheidung, Löschverfahren |
| `3` | zusätzlich normalisierte Metadaten und DDL |
| `4` bis `254` | Verhalten wie Stufe `3` |
| `255` | maximaler interner Trace |

Messages werden mit sicherem Chunking ausgegeben und erzeugen kein zusätzliches Resultset.

## Dependencies und Rechte

Die Procedure besitzt keine Abhängigkeit zu einem anderen Toolbelt-Modul und verwendet kein `EXECUTE AS`. Erforderlich sind:

- `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable`;
- ausreichende Metadatensichtbarkeit auf eine reguläre Referenztabelle;
- die normale Kontrolle des Aufrufers über seine lokale Temp-Tabelle.

## Performance und Grenzen

Dokumentiert:

- Ziel- und Referenzmetadaten werden je Aufruf read-only ermittelt.
- DDL entsteht nur bei abweichendem Schema.
- Bei passendem Schema und `@KeepData = 1` ist keine Mutation erforderlich.
- Intern generierte Add-/Drop-Spaltenlisten sind auf jeweils 1.000.000 Unicode-Zeichen begrenzt.
- Maximal 1024 ResultTable-Spalten werden unterstützt. Am SQL-Server-Spaltenlimit
  teilt der Algorithmus den Umbau, damit die Anchor-Spalte keine 1025. Spalte erzeugt.

Empirische Laufzeit-, CPU-, TempDB- und Skalierungsaussagen sind noch `not executed` und werden nicht behauptet.

## Beispiel

Siehe [PrepareResultTable.sql](../Examples/PrepareResultTable.sql).

## Quellen

- Microsoft (2026): [PARSENAME](https://learn.microsoft.com/en-us/sql/t-sql/functions/parsename-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [QUOTENAME](https://learn.microsoft.com/en-us/sql/t-sql/functions/quotename-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [sys.columns](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-columns-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [sys.types](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-types-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [SAVE TRANSACTION](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/save-transaction-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [XACT_STATE](https://learn.microsoft.com/en-us/sql/t-sql/functions/xact-state-transact-sql?view=sql-server-ver17).
