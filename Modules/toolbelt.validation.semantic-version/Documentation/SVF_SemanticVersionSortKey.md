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
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |
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
