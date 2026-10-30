# TVF_TrimDirectionalNvarchar

`toolbelt_string.TVF_TrimDirectionalNvarchar(@Value, @Characters = N' ', @Direction = 'BOTH')` liefert genau eine `nvarchar(max)`-Spalte `Value`. Jeder Eintrag in `@Characters` ist ein einzelnes zu entfernendes UTF-16-Zeichen. Der Vergleich folgt der Collation der Toolbelt-Datenbank; eine dynamische Caller-Collation kann eine T-SQL-Funktion nicht portabel garantieren.

`NCHAR(0)` wird aus Sicherheits- und Plattformgründen nicht entfernt. Die Funktion verwendet keine Pattern-Syntax; `[` und `%` sind literale Zeichen.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max); Positionen zählen UTF-16-Codeeinheiten. Leer bleibt leer; NULL ergibt NULL. NUL wird nicht entfernt; Zeichenvergleiche verwenden die Installationscollation. |
| `@Characters` | `nvarchar(4000)` | `N' '` | Input | Bis 4000 UTF-16-Codeeinheiten als nvarchar(4000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'  Contoso-123  ', N' ', 'BOTH');
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_TrimDirectionalNvarchar.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
