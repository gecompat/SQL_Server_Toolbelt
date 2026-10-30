# `SVF_SemanticVersionSortKey`

Die SVF delegiert an
[`TVF_SemanticVersionSortKey`](./TVF_SemanticVersionSortKey.md). Für
mengenorientierte Sortierungen ist die inline TVF mit `APPLY` zu bevorzugen.

Liefert `varbinary(max)` mit derselben aufsteigenden Präzedenz wie der
Comparator oder `NULL` für ungültige Eingabe. Build Metadata beeinflusst den
Key nicht. Die Binärdarstellung ist ein technischer Modulwert, kein
versionsübergreifendes Austauschformat.

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT toolbelt_validation.SVF_SemanticVersionSortKey(N'1.2.3-alpha.1+build.7') AS ResultValue;
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#semver).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_SemanticVersionSortKey.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
