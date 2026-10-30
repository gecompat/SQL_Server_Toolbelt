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

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MultipartName` | `nvarchar(1035)` | `kein Default` | Input | Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 Zeichen. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#identifier).
