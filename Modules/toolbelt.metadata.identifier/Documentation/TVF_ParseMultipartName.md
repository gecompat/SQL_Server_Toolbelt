# `toolbelt_metadata.TVF_ParseMultipartName`

## Zweck

Validiert und zerlegt einen ein- bis vierteiligen SQL-Namen. Die Funktion gibt
auch bei ungültiger Eingabe genau eine Zeile zurück.

## Signatur

```sql
toolbelt_metadata.TVF_ParseMultipartName
(
    @MultipartName nvarchar(1035)
)
```

## Resultset

| Spalte | Typ | Bedeutung |
|---|---|---|
| `IsValid` | `bit NOT NULL` | `1`, wenn der vollständige Vertrag erfüllt ist. |
| `ValidationCode` | `varchar(32) NOT NULL` | Stabiler abstrakter Validierungsstatus. |
| `PartCount` | `tinyint NULL` | Anzahl syntaktischer Bestandteile. |
| `ServerName` | `sysname NULL` | Serverteil bei vierteiligen Namen. |
| `DatabaseName` | `sysname NULL` | Datenbankteil bei drei-/vierteiligen Namen. |
| `SchemaName` | `sysname NULL` | Schemateil bei zwei- bis vierteiligen Namen. |
| `ObjectName` | `sysname NULL` | Erforderlicher rechter Objektteil. |
| `QuotedName` | `nvarchar(1035) NULL` | Kanonisch mit `[...]` begrenzter Name. |

Bei ungültiger Eingabe sind alle Namensspalten und `QuotedName` `NULL`.

## Unterstützte Formen

```text
Object
Schema.Object
Database.Schema.Object
Server.Database.Schema.Object
Database..Object
Server.Database..Object
Server..Schema.Object
Server...Object
```

Begrenzte Teile unterstützen Punkte und verdoppelte schließende Klammern:

```text
[Database].dbo.[Object.Name]
[Db]]Name].[Object]]Name]
```

## Validation Codes

`VALID`, `NULL_INPUT`, `EMPTY_INPUT`, `CONTROL_CHARACTER`,
`BRACKET_SYNTAX`, `TEXT_AFTER_DELIMITER`, `UNQUOTED_META_CHARACTER`,
`PART_TOO_LONG`, `TOO_MANY_PARTS`, `UNCLOSED_DELIMITER`,
`EMPTY_IDENTIFIER`, `OUTER_WHITESPACE`, `INVALID_OMISSION` und
`INVALID_IDENTIFIER`.

Die Codes enthalten keine Eingabewerte und sind für programmgesteuerte
Verzweigungen vorgesehen. Neue Codes innerhalb derselben Modul-Major-Version
dürfen nur neue, zuvor nicht als gültig dokumentierte Eingaben unterscheiden.

## Collation und Performance

Delimiter-, Escape- und Metazeichen werden explizit binär verglichen. Der
Parser arbeitet mit einem begrenzten linearen Zustandsautomaten und benötigt
keine Catalog Views, temporären Tabellen oder rekursive CTE.
