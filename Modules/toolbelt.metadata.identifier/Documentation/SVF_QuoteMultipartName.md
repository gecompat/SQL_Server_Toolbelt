# `toolbelt_metadata.SVF_QuoteMultipartName`

## Zweck

Liefert die kanonisch mit eckigen Klammern begrenzte Form eines gültigen
Multipart-Namens. Die Funktion ist der kompakte Aufruf für dynamisches SQL,
wenn die Einzelteile nicht separat benötigt werden.

## Signatur

```sql
toolbelt_metadata.SVF_QuoteMultipartName
(
    @MultipartName nvarchar(1035)
)
RETURNS nvarchar(1035)
```

## Verhalten

```text
Database..Object
→ [Database]..[Object]

[Database].dbo.[Object.Name]
→ [Database].[dbo].[Object.Name]
```

Ungültige Eingaben und `NULL` liefern `NULL`. Die Funktion verwendet
`TVF_ParseMultipartName` als einzigen kanonischen Parser und führt keine
Objekt-, Schema- oder Berechtigungsauflösung durch.

## Rechte und Grenzen

Erforderlich sind `SELECT` oder `REFERENCES` auf der Function sowie auf ihrer
Parserabhängigkeit. Der Rückgabewert ist erst nach zusätzlicher fachlicher
Autorisierung zur Auswahl eines tatsächlichen Zielobjekts geeignet.
