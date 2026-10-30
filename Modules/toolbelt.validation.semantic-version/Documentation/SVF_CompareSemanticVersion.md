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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | Linke SemVer-Version. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | Rechte SemVer-Version. |

## Beispielaufruf

```sql
SELECT toolbelt_validation.SVF_CompareSemanticVersion(N'1.2.3', N'2.0.0') AS ResultValue;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_CompareSemanticVersion.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
