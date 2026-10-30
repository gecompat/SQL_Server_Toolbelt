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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | Strikte SemVer-2.0.0-Version, z. B. 1.2.3-alpha.1+build.7. |

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#semver).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_SemanticVersionSortKey.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
