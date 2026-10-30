# TVF_FormatXlsxCell

Die [Callerergänzung vom2026-10-26](../../../Releases/1.0.0/XLSX-CELL-CALLER-QUALIFICATION.md) belegt genau ein SELECT auf diese öffentliche TVF auf Windows/Linux SQL2019 CL150,SQL2022 CL150/160 undSQL2025 CL150/160/170 lokal/direkt zentral. Andere Zugriffe bleiben gesperrt; vollständige Fach-/Client-/Lifecycle- und Ressourcenabnahme bleibt getrennt. Die folgenden datierten Nachweise behalten ihren ursprünglichen Scope.

Version 1.2.0 ergänzt genau eine Anzeige-TVF im bestehenden SAFE-Workbookprovider.
[Genehmigter Vertrag](../../../Documentation/Architecture/XLSX_CELL_DISPLAY_CONTRACT.md).
Vorhandenes SELECT genügt; Deployment erteilt keine Rechte.

## Parameter und Resultset

Alle Parameter haben Default NULL. Die Reihenfolge ist verbindlich:

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StoredType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal/case- und trailing-space-sensitiv: n = numerischer Rawwert; b = Booleanraw 0/1; s = Shared-String-Index in Raw plus bereits aufgelöster Text; inlineStr = Inline-Text ohne v/Raw; str = gespeicherter Stringcache, Raw und Text exakt gleich; d = ISO-Datum/-Datetime ohne Offset; e = gespeicherter Excelzellfehler, Status 10. NULL ergibt Absent/Status 1 nach allgemeinen Längen-/Unicodeprüfungen; leer/andere Werte Status 6. Höchstens 32 UTF-16-Einheiten, keine Normalisierung. |
| `@ValuePresent` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 1 bedeutet XML-v-Element vorhanden, nicht allgemein Zellinhalt vorhanden; 0 bedeutet kein v. NULL ergibt Status 1. inlineStr verlangt 0 und RawValue=NULL, sonst Status 2. Bei anderen StoredTypes bedeutet 0 nur dann absent, wenn RawValue und TextValue beide NULL sind; widersprüchliche Inhalte ergeben Status 2. |
| `@RawValue` | `nvarchar(max)` | `NULL` | Input | Unveränderter Inhalt des gespeicherten v-Elements, maximal 65536 UTF-16-Einheiten; NULL bedeutet fehlendes v, leer bleibt von NULL verschieden. n akzeptiert ASCII-Zahlen mit optional +/- sowie Punkt/Exponent e/E, auch .5/1., ohne Spaces; für Number-/Serialparsing zusätzlich höchstens 128 Einheiten, exakter SqlDecimal-Bereich bis 38 Ziffern ohne Rundung. b verlangt exakt 0 oder 1; s einen nichtnegativen Int32-ASCII-Dezimalindex (führende Nullen erlaubt); str exakte Gleichheit zu TextValue; d ISO YYYY-MM-DD oder YYYY-MM-DDTHH:mm:ss[.1..7 Ziffern] passend zum Ziel, ohne Z/Offset. inlineStr verlangt NULL. Gespeicherter Formelcache kann übergeben werden, keine Formelberechnung. Allgemeine strikte UTF-16-Prüfung und atomare Ausgabequote gelten auch bei später ungenutztem Wert. |
| `@TextValue` | `nvarchar(max)` | `NULL` | Input | Bereits aufgelöster Shared-/Inline-/Stringcache-Text, maximal 65536 wohlgeformte UTF-16-Einheiten; leer ist gültiger Text, NULL bedeutet kein Text. s benötigt ihn im Textzweig, inlineStr benötigt ihn zusammen mit Presence=0/Raw=NULL; str muss bytegenau mit RawValue übereinstimmen. Kein erneuter SST-/Workbookzugriff oder Trim. Der feste Outputcharge zählt Echos/Typedtext mehrfach und kann vor diesem einzelnen Inputmaximum greifen. |
| `@TargetType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal ohne Trim: number = exakte SqlDecimal-Zahl; boolean = bit aus b; text = Stringtext beziehungsweise Rawdarstellung; date = Datum; datetime = datetime2(7); time = Uhrzeit unter 24h; duration = vorzeichenbehaftete 100ns-Ticks, auch über 24h. Maximal 32 UTF-16-Einheiten. NULL (Default) wählt zuerst die Formatklasse, ohne Format n→number, b→boolean, d→datetime, s/str/inlineStr→text. Leer/andere Werte oder Widerspruch zu Formatklasse ergeben Status 2. Kompatibilität mit StoredType bleibt erforderlich, keine allgemeine Cast-API. Die Anzeige unterstützt keinen eigenen Boolean-/Dauerformatrenderer. |
| `@FormatCode` | `nvarchar(max)` | `NULL` | Input | Taxativ und exakt: 0 = Zahl ganzzahlig; 0.00 = Zahl mit zwei Dezimalstellen; #,##0.00 = Zahl mit Gruppierung/zwei Stellen; 0% = Prozent ganzzahlig; 0.00% = Prozent mit zwei Stellen; 0.00E+00 = wissenschaftliche Zahl mit zwei Mantissenstellen; yyyy-mm-dd = date; yyyy-mm-dd hh:mm:ss = datetime; hh:mm:ss = time; @ = text. Keine Excel-General-/Farb-/Locale-/Mehrsektionsgrammatik, kein Trim/Casefold; höchstens 128 UTF-16-Einheiten. NULL (Default) ergibt nach erfolgreicher Typinterpretation Status 2; unbekannt/leer Status 6. [h]:mm:ss wird vom geerbten Typkern erkannt, bleibt als Anzeigeformat unsupported/Status 6. Keine automatische Formatwahl; numerische Rundung half-away-from-zero, @ übernimmt Text unverändert. |
| `@Date1904` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 0 = Excel1900-Datumssystem, 1 = Excel1904-Datumssystem. NULL (Default) ist nur bei numerischem date-/datetime-Ziel ungültig (Status 2); sonst kein implizites Workbookauslesen. Im 1900-System ist ursprüngliches Serialintervall [60,61) der fiktive Schalttag und ergibt Status 7 vor Rundung. Zeit-/Dauerwerte benötigen keinen Datumssystemdefault. |
| `@CultureName` | `nvarchar(max)` | `NULL` | Input | Taxativ und exakt: en-US = Dezimalpunkt/Gruppierungskomma; de-DE = Dezimalkomma/Gruppierungspunkt; tr-TR = Dezimalkomma/Gruppierungspunkt. Auch bei @-/Temporalformaten explizit erforderlich nach erfolgreicher Typinterpretation; NULL/leer/Aliase/andere Schreibweisen ergeben Status 2. Höchstens 32 UTF-16-Einheiten; keine CurrentCulture/OS-Overrides, Culture beeinflusst keine Inputlexik/Typwahl. |
<!-- API_PARAMETERS:END -->

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

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#xlsx).
