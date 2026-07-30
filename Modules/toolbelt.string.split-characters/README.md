# toolbelt.string.split-characters

## Zweck

Das Modul teilt Unicode-Text an einer Menge einzelner literal
interpretierter Separatorzeichen. Es stellt stabile, bei 1 beginnende
Ordinals bereit und definiert leere Tokens, `NULL`, Collation und LOB-Verhalten
explizit.

## Status

- Version: `1.0.0`
- Implementation: `implemented`
- Validation: `not executed`
- Release: `unreleased`

Die statische und dokumentarische Prüfung ist Teil dieses Slices. Eine
erfolgreiche Runtime-Ausführung wird erst nach einem tatsächlich grünen
Workflow als Evidenz ergänzt.

Aktuelle Evidenz:
[Split-Characters Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/split-characters-runtime.yml)
ist vorhanden, aber noch `not executed`.

## Öffentliche Oberfläche

```sql
toolbelt_string.TVF_SplitByCharacters
(
    @Input      nvarchar(max),
    @Separators nvarchar(4000),
    @KeepEmpty  bit = 1
)
```

Resultset:

| Spalte | Typ | Bedeutung |
|---|---|---|
| `Value` | `nvarchar(max)` | Unverändertes Token |
| `Ordinal` | `bigint` | Kontinuierliche Tokenposition ab 1 |

Die physische Zeilenreihenfolge ist nicht Teil des Vertrags. Verbraucher
müssen `ORDER BY Ordinal` verwenden.

## Semantik

- Jedes UTF-16-Codeelement in `@Separators` ist ein eigenständiger Separator.
- Separatoren werden binär mit `Latin1_General_100_BIN2` verglichen.
- `@KeepEmpty = 1` erhält leere Tokens an Rändern und zwischen Separatoren.
- `@KeepEmpty = 0` entfernt leere Tokens und nummeriert die verbleibenden
  Tokens lückenlos.
- Ein explizites `@KeepEmpty = NULL` entspricht dem Default `1`.
- Whitespace wird nicht getrimmt oder normalisiert.
- `@Input IS NULL`, `@Separators IS NULL` oder NUL in `@Separators` liefern
  eine leere Ergebnismenge.
- Eine leere Separatorliste liefert die vollständige Eingabe als ein Token.
- Zusammengesetzte Grapheme und supplementary characters werden nicht als ein
  einzelner Separator versprochen.

Mehrzeichige Separatorstrings, Quote- und Escape-Semantik gehören nicht zu
Version 1. Sie sind separat in `TC-2026-032` erfasst.

## Dependency

`toolbelt.core.generate-series` Version `1.0.0` muss in derselben Datenbank
installiert sein. Das Deployment prüft Modulmarker und
`toolbelt_core.TVF_GenerateSeriesBigInt` vor jeder Mutation.

## Deployment

Aus dem Deployment-Verzeichnis:

```bash
sqlcmd -S <server> -d <database> -i Deploy.sql -v DeploymentMode=local
```

Für eine zentrale Toolbelt-Datenbank wird `DeploymentMode=central` verwendet.
Cross-database-Aufrufe benötigen dann den dreiteiligen Funktionsnamen.

Kontrollierter Uninstall:

```bash
sqlcmd -S <server> -d <database> -i Uninstall.sql \
  -v ConfirmNoExternalConsumers=0
```

Bei zentraler Installation ist `ConfirmNoExternalConsumers=1` erforderlich.
Das Modul entfernt seine Generate-Series-Dependency nicht.

## Dokumentation

- [Objektvertrag](./Documentation/TVF_SplitByCharacters.md)
- [Beispiele](./Examples/SplitCharacters.sql)
- [Contract-Testmatrix](./Tests/SPLIT_CHARACTERS_CONTRACT_TEST_MATRIX.md)
- [Architekturdesign](../../Documentation/Architecture/SPLIT_CHARACTERS_MODULE_DESIGN.md)
