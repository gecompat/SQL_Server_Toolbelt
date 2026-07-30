# toolbelt_conversion.SVF_IntegerToBase

Codiert `@Value bigint` mit `@Alphabet varchar(93)` und liefert
`varchar(65)`. Basis und Ziffernzuordnung ergeben sich aus dem Alphabet; das
erste Zeichen steht für Null.

Ungültige oder `NULL`-Alphabete und `NULL`-Werte liefern `NULL`. Ein Alphabet
muss 2 bis 93 binär eindeutige Zeichen aus ASCII `!` bis `~` enthalten; `-`
ist ausgeschlossen. Negative Werte erhalten ein führendes `-`.

```sql
SELECT toolbelt_conversion.SVF_IntegerToBase
(
    -255,
    '0123456789ABCDEF'
); -- -FF
```

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30518087070
