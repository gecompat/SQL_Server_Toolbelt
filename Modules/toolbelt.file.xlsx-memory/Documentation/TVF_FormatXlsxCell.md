# TVF_FormatXlsxCell

Version 1.2.0 ergänzt genau eine Anzeige-TVF im bestehenden SAFE-Workbookprovider.
[Genehmigter Vertrag](../../../Documentation/Architecture/XLSX_CELL_DISPLAY_CONTRACT.md).
Vorhandenes SELECT genügt; Deployment erteilt keine Rechte.

## Parameter und Resultset

Alle Parameter haben Default NULL. Die Reihenfolge ist verbindlich:

| Ordinal | Parameter | SQL-Typ |
|---:|---|---|
| 1 | StoredType | nvarchar(max) |
| 2 | ValuePresent | bit |
| 3 | RawValue | nvarchar(max) |
| 4 | TextValue | nvarchar(max) |
| 5 | TargetType | nvarchar(max) |
| 6 | FormatCode | nvarchar(max) |
| 7 | Date1904 | bit |
| 8 | CultureName | nvarchar(max) |

Genau eine Zeile: `DisplayText nvarchar(max) NULL`, `StatusCode int NOT NULL`.
Bei jedem Fehler ist DisplayText NULL; Default-NULL ergibt Status 1.
Die interne CLR-FT besitzt physisch zwei nullable Slots. Ein unerwarteter NULL-
Status wird von der öffentlichen IF auf Status 11 abgebildet.

## Endliche Formate und Kulturen

Exakte Literalformate: `0`, `0.00`, `#,##0.00`, `0%`, `0.00%`, `0.00E+00`,
`yyyy-mm-dd`, `yyyy-mm-dd hh:mm:ss`, `hh:mm:ss`, `@`.
Exakte Kulturen: `en-US`, `de-DE`, `tr-TR`; keine Umgebungskultur, Trim- oder
Case-Normalisierung. Keine Excel-General-, Locale-Tags-, Farb-, Bedingungs-,
Mehrsektions-, Dauer- oder Stylekatalog-Grammatik.

Die unveränderte Typinterpretation entscheidet NULL, Zahl, Text, Bool, Fehler,
Datumssystem und Cachewert. Formatierung benutzt exakte SqlDecimal-Daten ohne
Double/Decimal-Verlust. Rundung ist half-away-from-zero; negative gerundete Null
wird als Null angezeigt. Prozent skaliert exakt; wissenschaftliche Anzeige
normalisiert Mantisse und Exponent. Datetime darf bei Sekundenrundung das Datum
wechseln; der maximale Tag und ein time-Übertrag nach 24:00 ergeben Status 8.
Serial60 bleibt Status 7. Workbookformeln werden nicht berechnet: der Caller
übergibt den bereits gelesenen gespeicherten Cache als Raw-/Textwert.

## Status und Grenzen

| Code | Bedeutung |
|---:|---|
| 0 | Erfolg |
| 1 | Fehlender Wert |
| 2 | Ungültige Argumentkombination/Kultur |
| 3 | Budgetgrenze |
| 4 | Ungültige Lexik/UTF-16 |
| 5 | Zahlenbereich |
| 6 | Nicht unterstütztes Format |
| 7 | Fiktiver Excel-Tag 1900-02-29 |
| 8 | Temporalbereich/Übertrag |
| 9 | Präzisionsverlust |
| 10 | Gespeicherter Excel-Fehler |
| 11 | Unerwarteter NULL-Bindingstatus |

Typkern-Eingabe-, Echo- und Arbeitsbudgets bleiben unverändert. Kultur ist auf
32 UTF-16-Einheiten begrenzt. Displayquote 262144 Bytes einschließlich konservativer
Stringcharge; die geerbte Typquote kann vorher greifen. Deshalb sind Display-
65472/+1 isolierte Renderergrenzen, keine erreichbaren öffentlichen `@`-Grenzfälle.
`s` 32733/32734 und `str` 21821/21822 sind tatsächliche API-Grenzen.
Keine Datei-, Netzwerk-, Context-Connection-, Workbook- oder SST-Zugriffe.

```sql
SELECT * FROM toolbelt_file.TVF_FormatXlsxCell
 (N'n',1,N'1.235',NULL,N'number',N'0.00',NULL,N'en-US');
-- DisplayText=1.24, StatusCode=0
```

[Nachweisgrenzen und Reproduktion](../Tests/README.md): ausgewählte lokale
1.2-Nachweise und Offlinequalifikation bestanden am 2026-10-04. Vollständige
Produktmatrix, zentrale Nutzung, Minimalrechte und aktuelle Head-CI bleiben offen.
