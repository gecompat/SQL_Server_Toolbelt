# toolbelt_conversion.TVF_UriComponentEncodeStatus

**Status:** implemented; teilweise validiert, unveröffentlicht.

## Zweck und Vertrag

Genau eine Zeile: OK, SQL_NULL oder LIMIT. Eingang vor UTF-8-Konvertierung/Series prüfen. Aus höchstens 32768 Codeeinheiten entstehen selbst bei drei UTF-8-Bytes und drei Escapezeichen je Byte höchstens 589824 UTF-16-Ausgabebytes; die 1-MiB-Grenze ist damit schon vor Aggregation abgesichert. Altfassaden liefern bei LIMIT NULL.

## Parameter

- `@Value`: nvarchar(max); höchstens 65536 UTF-16-Bytes.

## Ergebnis

EncodedValue nvarchar(max), Status varchar(16).

## Beispiel

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(N'Contoso €');
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
- [SQL-Definition](../Source/TVF_UriComponentEncode.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
