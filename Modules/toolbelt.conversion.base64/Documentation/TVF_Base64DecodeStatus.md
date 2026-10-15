# toolbelt_conversion.TVF_Base64DecodeStatus

**Status:** implemented; teilweise validiert, unveröffentlicht.

## Zweck und Vertrag

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Rohtextprüfung vor REPLACE, berechnete Ergebnisgröße vor XML. Standard-/URL-Alphabet und definierter Whitespace bleiben. Die bisherige TVF/SVF behält Syntaxfehler unterhalb der Grenzen und liefert bei LIMIT NULL.

## Parameter

- `@Value`: varchar(max); höchstens 25165824 Rohtextbytes einschließlich Whitespace und 16777216 Ergebnisbytes.

## Ergebnis

DecodedValue varbinary(max), Status varchar(16).

## Beispiel

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('YWJj');
```

## Freigabe und Nachweise

Ausdrücklich am 2026-10-15 mit Zweck, Vertrag, Alternativen, Risiken und Grenzverhalten freigegeben. Siehe [Security-Härtung](../../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md). Neue Runtime-/CI-Nachweise werden dort getrennt vom Implementierungsstand geführt. Keine Parallelitäts-, Heap- oder harte Echtzeitzusage.
