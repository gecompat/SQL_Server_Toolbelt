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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | Strikte SemVer-2.0.0-Version, z. B. 1.2.3-alpha.1+build.7. |

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
