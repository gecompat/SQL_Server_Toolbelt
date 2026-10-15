# toolbelt_string.TVF_SplitByCharactersStatus

**Status:** implemented; teilweise validiert, unveröffentlicht.

## Zweck und Vertrag

Erst vollständige Spanprüfung, danach höchstens 10000 OK-Tokenzeilen. LIMIT, INVALID, SQL_NULL und EMPTY liefern genau eine Kontrollzeile ohne Value/Ordinal. Keine Tokenpräfixe. Die bisherige TVF filtert ausschließlich OK; bei Grenzüberschreitung liefert sie keine Zeilen. Positionen und Separatorvergleich zählen BIN2-Codeeinheiten.

## Parameter

- `@Input`: nvarchar(max); höchstens 65536 UTF-16-Bytes.
- `@Separators`: nvarchar(4000); höchstens 64 unterschiedliche UTF-16-Codeeinheiten; Duplikate zählen einmal; NUL ist ungültig.
- `@KeepEmpty`: bit=1; NULL entspricht 1; 0 verwirft leere Tokens.

## Ergebnis

Value nvarchar(max), Ordinal bigint, Status varchar(16).

## Beispiel

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharactersStatus(N'a,b',N',',1) ORDER BY Ordinal;
```

## Freigabe und Nachweise

Ausdrücklich am 2026-10-15 mit Zweck, Vertrag, Alternativen, Risiken und Grenzverhalten freigegeben. Siehe [Security-Härtung](../../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md). Neue Runtime-/CI-Nachweise werden dort getrennt vom Implementierungsstand geführt. Keine Parallelitäts-, Heap- oder harte Echtzeitzusage.
