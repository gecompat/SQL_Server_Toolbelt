# Modul `toolbelt.metadata.identifier`

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

## Zweck

Das Modul zerlegt ein- bis vierteilige SQL-Objektnamen und erzeugt daraus eine
sicher mit eckigen Klammern begrenzte Darstellung. Es unterstützt
`[...]`-Identifier, Punkte innerhalb begrenzter Teile, `]]` als Escape sowie
die von SQL Server dokumentierten ausgelassenen mittleren Bestandteile.

Das Modul löst keine Objekte auf, ergänzt kein Standardschema und prüft keine
Berechtigungen. Es ist syntaktische Absicherung für nachgelagerten dynamischen
SQL-Code, kein Autorisierungsmechanismus.

## Öffentliche Objekte

| Objekt | Typ | Zweck |
|---|---|---|
| `toolbelt_metadata.TVF_ParseMultipartName` | Multi-statement TVF | Validiert und zerlegt einen Multipart-Namen in genau einer Ergebniszeile. |
| `toolbelt_metadata.SVF_QuoteMultipartName` | Scalar UDF | Liefert den kanonisch begrenzten Namen oder `NULL`. |

## Vertrag

- ein bis vier Teile, rechtsbündig als Server, Datenbank, Schema und Objekt;
- Objektteil immer erforderlich;
- ausgelassene Teile ausschließlich in mittleren Positionen von drei- oder
  vierteiligen Namen;
- maximal 128 decodierte Zeichen je Teil;
- keine stille Kürzung, Normalisierung, Groß-/Kleinschreibung oder
  Objektauflösung;
- unquoted Metazeichen, Steuerzeichen und äußere Leerzeichen sind ungültig;
- doppelte Anführungszeichen werden nicht als Identifier-Delimiter behandelt.

## Deployment

```bash
sqlcmd -S localhost -d ZielDb -i Deployment/Deploy.sql -v DeploymentMode=local
```

Für eine zentrale Installation wird `DeploymentMode=central` verwendet.
Aufrufer können die Funktionen dann über dreiteilige Namen referenzieren.

## Validierungsstatus

`implementation_status: implemented`, `validation_status: partially validated`,
`release_status: unreleased`.

Der
[Identifier-Runtime-Lauf 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
einschließlich Parser-, Quote-, Escape-, Omission-, Längen-, Fehler-,
Deployment- und Lifecycle-Contracts erfolgreich. Der vollständige Adapter ist
am 2026-08-29 zusätzlich auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen
erfolgreich; Windows-Läufe bleiben `not executed`.

## Quellen

- Microsoft (2026): [Transact-SQL-Syntaxkonventionen](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/transact-sql-syntax-conventions-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [`QUOTENAME`](https://learn.microsoft.com/en-us/sql/t-sql/functions/quotename-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [`CREATE FUNCTION`](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver17).

## Bekannte Grenzen

- Die lineare Zeichenverarbeitung ist für Identifier optimiert, nicht für
  beliebig große Texte.
- Doppelte Anführungszeichen bleiben ausgeschlossen, weil ihre Interpretation
  von `QUOTED_IDENTIFIER` abhängt.
- Die Funktion bestätigt nicht, dass ein Name als reales SQL-Server-Objekt
  existiert.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
