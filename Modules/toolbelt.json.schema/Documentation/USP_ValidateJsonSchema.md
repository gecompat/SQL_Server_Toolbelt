# toolbelt_json.USP_ValidateJsonSchema

Die USP prüft ein JSON-Dokument gegen ein Schema des begrenzten Profils
`toolbelt-2020-12-v1`. Sie schreibt keine fachlichen Daten. Der optionale
ResultTable-Pfad verwendet den bestehenden Toolbelt-Helpervertrag.

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema
 @Json=N'{"quantity":3}',
 @Schema=N'{"type":"object","required":["quantity"],"properties":{"quantity":{"type":"integer","minimum":1}}}';
```

| Parameter | Default und Grenze |
|---|---|
| Json nvarchar(max) | NULL; SQL NULL ergibt SQL_NULL nach Parameterprüfung |
| Schema nvarchar(max) | NULL; gleiche NULL-Regel |
| Profile varchar(32) | exakt toolbelt-2020-12-v1 |
| MaxDocumentBytes bigint | 16777216; positiv und nur absenkbar |
| MaxSchemaBytes bigint | 1048576; positiv und nur absenkbar |
| MaxDepth int | 128;1 bis128, Dokument und Schema |
| MaxEvaluationSteps bigint | 1000000; positiv und nur absenkbar |
| MaxErrors int | 100;0 bis100, nur Diagnosen begrenzen |
| ResultTable sysname | NULL; Helpervertrag, vorhandene Rechte |
| KeepData bit | 0; Helpervertrag |
| Debug tinyint | 0; payloadfreie Diagnose |
| Hilfe bit | 0;1 liefert Help zuerst, ohne Dependency- oder fachliche Prüfung |

Die zehn Spalten haben die feste Reihenfolge:
`RowKind varchar(8) NOT NULL`, `ErrorOrdinal int NOT NULL`,
`Status varchar(24) NOT NULL`, `Profile varchar(32) NOT NULL`,
`IsValid bit NULL`, `DocumentPointer nvarchar(max) NULL`,
`SchemaPointer nvarchar(max) NULL`, `Keyword nvarchar(128) NULL`,
`ErrorCode varchar(32) NULL`, `ErrorsTruncated bit NOT NULL`.
Zeichenfelder verwenden BIN2. SUMMARY hat Ordinal0; ERROR-Zeilen folgen mit
aufeinanderfolgenden Ordinals. Alle Zeilen tragen den endgültigen Status und
Truncationwert. `IsValid` ist nur bei VALID1 und INVALID_INSTANCE0 gesetzt.

Der [Gesamtvertrag](../../../Documentation/Architecture/JSON_SCHEMA_CONTRACT.md)
ist autoritativ für Keywords, Fehlercodes, RFC-Pointer, Priorität und Kosten.
Insbesondere ist dieses Profil keine vollständige2020-12-Implementierung.
Unbekannte Keywords, andere Drafts, externe oder rekursive Referenzen werden
explizit abgewiesen. Auch ungenutzte Definitionen werden geprüft. Zahlen
werden ohne Rundung oder Gleitkomma verglichen; Stringlängen zählen Unicode-
Skalare. Duplikatschlüssel und ungepaarte Surrogate sind keine gültigen Inputs.

Ungültige Argumente werfen55600/1. Ein inkohärenter interner Bridge-/
Transportvertrag wirft55601/1. Technische CLR-/Engine-/Helperfehler bleiben
technische Fehler. Eine reservierte Caller-TempTable wird vor dem internen
Batch abgewiesen. Die vollständige Antwort entsteht vor einer ResultTable-
Mutation; eigene Transaktionen oder committable Caller-Savepoints schützen
diesen Schreibpfad, ohne fremde oder doomed Callertransaktionen zurückzurollen.

Native API-, Clientmetadaten-, Rechte- und Lifecycle-Nachweise sind noch offen.
