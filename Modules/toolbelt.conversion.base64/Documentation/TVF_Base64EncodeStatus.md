# toolbelt_conversion.TVF_Base64EncodeStatus

**Status:** implemented; teilweise validiert, unveröffentlicht.

## Zweck und Vertrag

Genau eine Zeile. OK enthält den Wert; LIMIT und SQL_NULL enthalten NULL. Der kanonische MSTVF-Kern prüft vor XML. Die bisherige TVF/SVF delegiert und liefert bei Überschreitung NULL.

## Parameter

- `@Value`: varbinary(max); NULL ergibt SQL_NULL; höchstens 16777216 Bytes vor XML.
- `@UrlSafe`: bit=0; 1 erzeugt Base64URL ohne Padding; NULL entspricht 0.

## Ergebnis

EncodedValue varchar(max), Status varchar(16).

## Beispiel

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFE,0);
```

## Freigabe und Nachweise

Ausdrücklich am 2026-10-15 mit Zweck, Vertrag, Alternativen, Risiken und Grenzverhalten freigegeben. Siehe [Security-Härtung](../../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md). Neue Runtime-/CI-Nachweise werden dort getrennt vom Implementierungsstand geführt. Keine Parallelitäts-, Heap- oder harte Echtzeitzusage.
