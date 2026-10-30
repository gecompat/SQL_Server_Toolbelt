# `TVF_ParseSemanticVersion`

Signatur: `TVF_ParseSemanticVersion(@Version varchar(8000))`.

Die Funktion liefert genau eine Zeile mit `IsValid`, `ValidationCode`,
`Major`, `Minor`, `Patch`, `PreRelease`, `BuildMetadata` und
`CanonicalVersion`. Gültig ist ausschließlich SemVer 2.0.0. Numerische Core-
und Pre-release-Identifier dürfen keine führenden Nullen besitzen.

## Ergebnis verstehen

Verwende die Funktion, um Versionsangaben vor Vergleich oder Sortierung
zu validieren und ihre Bestandteile getrennt auszuwerten. Sie korrigiert
keine Eingaben: Leerzeichen, ein `v`-Präfix oder führende Nullen sind
keine zulässige Normalisierung.

| Spalte | Bedeutung |
|---|---|
| `IsValid` | `1` für eine gültige SemVer-Version, sonst `0` |
| `ValidationCode` | `VALID` oder der konkrete Validierungsgrund, etwa `NULL_INPUT` oder `EMPTY_INPUT` |
| `Major`, `Minor`, `Patch` | Versionszahlen als Text; auch große Zahlen werden ohne bigint-Konvertierung erhalten |
| `PreRelease` | Optionaler Teil nach `-`, ohne das Trennzeichen |
| `BuildMetadata` | Optionaler Teil nach `+`; beeinflusst die SemVer-Präzedenz nicht |
| `CanonicalVersion` | Bei gültiger Eingabe deren unveränderter Text |

Bei ungültiger Eingabe sind alle Komponenten und `CanonicalVersion` NULL.
Es bleibt eine Statuszeile erhalten. Für das folgende Beispiel werden
`IsValid=1`, `ValidationCode='VALID'`, die Komponenten `1`, `2`, `3`,
`PreRelease='alpha.1'` und `BuildMetadata='build.7'` erwartet.
Dies ist eine aus dem Vertrag abgeleitete Ergebniserwartung.

Historischer Einzelbeleg (aktuelle Testgrenzen siehe Modulbeschreibung):
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT * FROM toolbelt_validation.TVF_ParseSemanticVersion(N'1.2.3-alpha.1+build.7');
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#semver).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_ParseSemanticVersion.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
