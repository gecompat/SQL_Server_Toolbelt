# SVF- und inline-TVF-Audit

Stand: 2026-07-30

## Ziel

Dieses Dokument prüft alle vorhandenen öffentlichen Scalar-valued Functions
gegen `DEC-2026-022`. Wo die Funktionalität mengenorientiert verwendet werden
kann, soll eine semantisch äquivalente inline Table-valued Function für
`CROSS APPLY` und `OUTER APPLY` bereitstehen.

Eine TVF, die intern nur die SVF aufruft, gilt nicht als Erfüllung. Sie behält
den Scalar-UDF-Aufruf und damit dessen mögliche Optimizer- und
Parallelitätsnachteile bei.

## Bestandsprüfung

| Vorhandene SVF | Kanonischer relationaler Kern | Ergebnis | Maßnahme |
|---|---|---|---|
| `toolbelt_metadata.SVF_QuoteMultipartName` | `toolbelt_metadata.TVF_ParseMultipartName` | erfüllt | Keine Source-Änderung erforderlich; `OUTER APPLY` als bevorzugte Mengenverwendung deutlicher dokumentieren. |
| `toolbelt_conversion.SVF_Base64Encode` | `toolbelt_conversion.TVF_Base64Encode` | erfüllt | SVF delegiert an den relationalen Kern. |
| `toolbelt_conversion.SVF_Base64Decode` | `toolbelt_conversion.TVF_Base64Decode` | erfüllt | Fehler-, Leerzeilen- und LOB-Vertrag bleiben erhalten. |
| `toolbelt_conversion.SVF_IntegerToBase` | `toolbelt_conversion.TVF_IntegerToBase` | erfüllt | Rekursiver relationaler Kern deckt den vollständigen `bigint`-Bereich ab. |
| `toolbelt_conversion.SVF_TryBaseToInteger` | `toolbelt_conversion.TVF_TryBaseToInteger` | erfüllt | Kanonizität und Overflow-Prüfung bleiben erhalten. |
| `toolbelt_validation.SVF_CompareSemanticVersion` | `toolbelt_validation.TVF_CompareSemanticVersion` | erfüllt | Relationaler Kern baut auf dem Parservertrag auf. |
| `toolbelt_validation.SVF_SemanticVersionSortKey` | `toolbelt_validation.TVF_SemanticVersionSortKey` | erfüllt | Relationaler Kern baut auf dem Parservertrag auf. |

Es existieren keine weiteren öffentlichen SVFs im Stand dieses Audits.

## Verbindlicher Zielvertrag

Die neuen inline TVFs behalten Parameter, Datentypen, `NULL`-Semantik,
Collation-Vertrag und Fehlerverhalten der jeweils vorhandenen SVF bei. Bei
skalarer Semantik liefern sie genau eine Zeile mit einer fachlich benannten
Spalte:

| Inline TVF | Ergebnisspalte |
|---|---|
| `TVF_Base64Encode` | `EncodedValue` |
| `TVF_Base64Decode` | `DecodedValue` |
| `TVF_IntegerToBase` | `EncodedValue` |
| `TVF_TryBaseToInteger` | `DecodedValue` |
| `TVF_CompareSemanticVersion` | `ComparisonResult` |
| `TVF_SemanticVersionSortKey` | `SortKey` |

Die Resultsets liefern auch für `NULL` oder fachlich ungültige Eingaben eine
Zeile, soweit die bestehende SVF `NULL` zurückgibt. Enginefehler der
Base64-Decodierung bleiben Enginefehler; sie dürfen nicht durch eine leere
Ergebnismenge verschleiert werden.

## Verwendung

Für einzelne Werte bleibt der SVF-Aufruf zulässig:

```sql
SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.Example');
```

Für Spaltenwerte ist die relationale API bevorzugt:

```sql
SELECT
      source.MultipartName
    , quoted.QuotedName
FROM
(
    VALUES
          (N'dbo.Example')
        , (N'[Example.Database]..[Example.Object]')
) AS source(MultipartName)
OUTER APPLY
    toolbelt_metadata.TVF_ParseMultipartName(source.MultipartName) AS quoted;
```

`OUTER APPLY` erhält die äußere Zeile auch dann, wenn eine künftige relationale
Funktion für bestimmte Eingaben keine Zeile liefert. `CROSS APPLY` ist
geeignet, wenn eine solche Eingabe die äußere Zeile bewusst filtern soll.

## Abnahme der Remediation

`AP-2026-014` ist erst abgeschlossen, wenn für alle sechs offenen SVFs:

1. die inline TVF den kanonischen Fachkern enthält und die SVF nicht
   duplizierte Fachlogik führt;
2. lokales und zentrales Deployment, Upgrade, Wiederholungsdeployment,
   Kollision und Uninstall abgedeckt sind;
3. Parität für Normal-, Grenz-, `NULL`- und Fehlerfälle geprüft ist;
4. Objektseiten, Modul-README, Beispiele, Manifest und Testmatrix synchron
   sind;
5. Compatibility Levels 150, 160 und 170 geprüft sind;
6. ein Parallelitätsvorteil nur bei reproduzierbarer Evidenz behauptet wird.

Alle sechs Kriterien sind erfüllt. `AP-2026-014` ist abgeschlossen.

Runtime-Evidenz auf SQL Server 2025 Linux:

- [Base64 Runtime 30535377837](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377837)
- [Integer-Base Runtime 30535377860](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860)
- [Semantic-Version Runtime 30535377984](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984)

Alle drei Läufe prüfen Compatibility Levels 150, 160 und 170. Physische
SQL-Server-2019-/2022- und Windows-Läufe bleiben Releasevalidierung.

## Quellen

- [Microsoft: Scalar UDF Inlining](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver17)
- [Microsoft: Query Processing Architecture Guide](https://learn.microsoft.com/en-us/sql/relational-databases/query-processing-architecture-guide?view=sql-server-ver17)
- [Microsoft: CREATE FUNCTION](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver17)
