# toolbelt_datetime.TVF_TruncateDateTime2

Trunkiert einen `datetime2(7)`-Wert bis hinunter zu `microsecond`.

```sql
SELECT Value
FROM toolbelt_datetime.TVF_TruncateDateTime2
     ('millisecond', '2026-07-30T12:34:56.1234567');
```

`@DatePart varchar(16)` unterstützt die dokumentierten `DATETRUNC`-Dateparts
und Aliasse von `year` bis `microsecond`. `@Value` ist `datetime2(7)`.

Das Resultset besteht aus `Value datetime2(7)`, `IsValid bit` und
`ValidationCode tinyint`. Die Funktion ist ein dünner Inline-TVF-Typ-Wrapper
über den gemeinsamen `datetimeoffset(7)`-Kern. Sie ändert keine Zeitzone und
führt keine lokale Zeitzoneninterpretation aus.

Validation Codes und Grenzen:
[Moduldesign](../../../Documentation/Architecture/DATETIME_TRUNCATE_MODULE_DESIGN.md).
