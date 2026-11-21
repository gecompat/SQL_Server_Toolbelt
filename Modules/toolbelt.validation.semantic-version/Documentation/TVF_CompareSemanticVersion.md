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
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |
<!-- API_PARAMETERS:END -->

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#semver).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_CompareSemanticVersion.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
