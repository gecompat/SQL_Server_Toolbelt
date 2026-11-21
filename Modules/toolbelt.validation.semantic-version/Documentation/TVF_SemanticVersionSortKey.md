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
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |
<!-- API_PARAMETERS:END -->

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#semver).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_SemanticVersionSortKey.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
