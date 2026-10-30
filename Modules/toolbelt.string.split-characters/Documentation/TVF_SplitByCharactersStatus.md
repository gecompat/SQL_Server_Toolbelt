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

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_SplitByCharacters.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
