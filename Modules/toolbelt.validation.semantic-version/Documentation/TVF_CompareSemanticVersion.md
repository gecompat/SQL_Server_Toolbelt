# toolbelt_validation.TVF_CompareSemanticVersion

**Typ:** Inline Table-valued Function

Vergleicht zwei `varchar(8000)`-Werte strikt nach Semantic Versioning 2.0.0
und liefert genau eine Zeile mit `ComparisonResult smallint`:

- `-1`: linke Version besitzt niedrigere Präzedenz;
- `0`: gleiche Präzedenz;
- `1`: linke Version besitzt höhere Präzedenz;
- `NULL`: mindestens eine Eingabe ist ungültig.

Build Metadata beeinflusst den Vergleich nicht. Numerische Komponenten werden
ohne Integer-Konvertierung zuerst nach Länge und danach ASCII-binär
verglichen.

```sql
SELECT source.LeftVersion, source.RightVersion, compared.ComparisonResult
FROM
(
    VALUES ('1.0.0-alpha', '1.0.0'), ('1.0.0+1', '1.0.0+2')
) AS source(LeftVersion, RightVersion)
OUTER APPLY
    toolbelt_validation.TVF_CompareSemanticVersion
    (
          source.LeftVersion
        , source.RightVersion
    ) AS compared;
```

Die Funktion verwendet `TVF_ParseSemanticVersion` als gemeinsamen Parser und
ist der kanonische relationale Vergleichskern.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | Linker Vergleichsoperand. ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | Rechter Vergleichsoperand. ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |
<!-- API_PARAMETERS:END -->

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#semver).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_CompareSemanticVersion.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
