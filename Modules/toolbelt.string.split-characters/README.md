# toolbelt.string.split-characters

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

## Zweck

Das Modul teilt Unicode-Text an einer Menge einzelner literal
interpretierter Separatorzeichen. Es stellt stabile, bei 1 beginnende
Ordinals bereit und definiert leere Tokens, `NULL`, Collation und LOB-Verhalten
explizit.

## Status

- Version: `1.0.0`
- Implementation: `implemented`
- Validation: `validated`
- Release: `unreleased`

Der
[Split-Characters Runtime Run 30516116708](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30516116708)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Der vollständige Adapter ist am 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Windows-Läufe
bleiben `not executed`.

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

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
