# TVF_TrimDirectionalVarchar

`toolbelt_string.TVF_TrimDirectionalVarchar(@Value, @Characters = ' ', @Direction = 'BOTH')` liefert genau eine `varchar(max)`-Spalte `Value`. Der Vertrag entspricht der Unicode-Variante; ein `varchar`-Zeichen wird bytepositionsbasiert verarbeitet. UTF-8-`varchar` ist deshalb kein Unicode-Codepoint-Vertrag und wird separat bewertet.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | Text als varchar(max) unter der Installationscodepage einschließlich gegebenenfalls UTF8. SUBSTRING/CHARINDEX und NUL-Probe verwenden dieselben Zeichenpositionen der Installationscollation; SC zählt Supplementaryzeichen zusammen. Die obere Seriengrenze ist physisch DATALENGTH/2 bei nvarchar beziehungsweise DATALENGTH bei varchar und kann mehr Positionen als tatsächliche Zeichen enthalten. Leer bleibt leer, NULL ergibt NULL; keine dynamische Caller-Collation. NUL wird nicht entfernt. |
| `@Characters` | `varchar(8000)` | `' '` | Input | Bis 8000 Bytes als varchar(8000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalVarchar('  Contoso  ', N' ', 'BOTH');
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_TrimDirectionalVarchar.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
