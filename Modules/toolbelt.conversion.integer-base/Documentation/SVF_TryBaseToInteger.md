# toolbelt_conversion.SVF_TryBaseToInteger

Decodiert `@EncodedValue varchar(65)` mit `@Alphabet varchar(93)` in
`bigint`. Ungültige Eingabe, ungültiges Alphabet, nicht kanonische Darstellung,
Overflow und `NULL` liefern `NULL`.

Die Decodierung ist strikt: `+`, Whitespace, Präfixe, führende Nullzeichen und
`-0` werden nicht akzeptiert. Alphabet und Eingabe werden binär verglichen.

```sql
SELECT toolbelt_conversion.SVF_TryBaseToInteger
(
    '-FF',
    '0123456789ABCDEF'
); -- -255
```

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/integer-base-runtime.yml
