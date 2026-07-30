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
