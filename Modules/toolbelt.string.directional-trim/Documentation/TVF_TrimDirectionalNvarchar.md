# TVF_TrimDirectionalNvarchar

`toolbelt_string.TVF_TrimDirectionalNvarchar(@Value, @Characters = N' ', @Direction = 'BOTH')` liefert genau eine `nvarchar(max)`-Spalte `Value`. Jeder Eintrag in `@Characters` ist ein einzelnes zu entfernendes UTF-16-Zeichen. Der Vergleich folgt der Collation der Toolbelt-Datenbank; eine dynamische Caller-Collation kann eine T-SQL-Funktion nicht portabel garantieren.

`NCHAR(0)` wird aus Sicherheits- und Plattformgründen nicht entfernt. Die Funktion verwendet keine Pattern-Syntax; `[` und `%` sind literale Zeichen.
