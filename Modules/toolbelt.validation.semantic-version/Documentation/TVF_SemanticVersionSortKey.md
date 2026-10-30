# toolbelt_validation.TVF_SemanticVersionSortKey

**Typ:** Inline Table-valued Function

Erzeugt für `@Version varchar(8000)` genau eine Zeile mit
`SortKey varbinary(max)`. Ungültige Eingaben ergeben `NULL`. Build Metadata
fließt nicht in den Schlüssel ein; Versionen gleicher SemVer-Präzedenz
besitzen daher denselben Sort Key.

```sql
SELECT source.VersionValue, sort_key.SortKey
FROM
(
    VALUES ('1.0.0-alpha'), ('1.0.0-rc.1'), ('1.0.0')
) AS source(VersionValue)
OUTER APPLY
    toolbelt_validation.TVF_SemanticVersionSortKey
    (
        source.VersionValue
    ) AS sort_key
ORDER BY sort_key.SortKey;
```

Die Binärdarstellung ist ein technischer Modulwert und kein
versionsübergreifendes Austauschformat. Die inline TVF ist der kanonische
relationale Kern; die SVF bleibt für skalare Einzelaufrufe erhalten.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |
<!-- API_PARAMETERS:END -->

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#semver).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_SemanticVersionSortKey.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
