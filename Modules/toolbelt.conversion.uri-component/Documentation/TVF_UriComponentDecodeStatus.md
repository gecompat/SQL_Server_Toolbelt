# toolbelt_conversion.TVF_UriComponentDecodeStatus

**Status:** implemented; teilweise validiert, unveröffentlicht.

## Zweck und Vertrag

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Strikte UTF-8-/Percent-/NUL-Regeln bleiben; bei LIMIT IsValid=0, ValidationCode=14, Wert NULL. Die Ausgabe ist durch den vor Series geprüften Eingang unter 1 MiB begrenzt. Altfassaden behalten ihre Spalten und liefern bei LIMIT NULL.

## Parameter

- `@Value`: nvarchar(max); höchstens 65536 UTF-16-Bytes.

## Ergebnis

DecodedValue nvarchar(max), IsValid bit, ValidationCode tinyint, Status varchar(16).

## Beispiel

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'%E2%82%AC');
```

## Freigabe und Nachweise

Ausdrücklich am 2026-10-15 mit Zweck, Vertrag, Alternativen, Risiken und Grenzverhalten freigegeben. Siehe [Security-Härtung](../../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md). Neue Runtime-/CI-Nachweise werden dort getrennt vom Implementierungsstand geführt. Keine Parallelitäts-, Heap- oder harte Echtzeitzusage.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | nvarchar(max); höchstens 65536 UTF-16-Bytes. |

## Voraussetzungen für den Aufruf

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_UriComponentDecode.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
