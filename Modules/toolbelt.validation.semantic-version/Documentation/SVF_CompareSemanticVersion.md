# `SVF_CompareSemanticVersion`

Vergleicht zwei `varchar(8000)`-Werte nach SemVer 2.0.0. Ergebnis: `-1`, `0`,
`1`; `NULL`, falls mindestens eine Eingabe ungültig ist. Build Metadata wird
ignoriert. Zahlen werden über Länge und anschließend ASCII-binär verglichen.

Die SVF delegiert an
[`TVF_CompareSemanticVersion`](./TVF_CompareSemanticVersion.md). Für
mengenorientierte Vergleiche ist die inline TVF mit `APPLY` zu bevorzugen.

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | Linker Vergleichsoperand. ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | Rechter Vergleichsoperand. ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT toolbelt_validation.SVF_CompareSemanticVersion(N'1.2.3', N'2.0.0') AS ResultValue;
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#semver).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_CompareSemanticVersion.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
