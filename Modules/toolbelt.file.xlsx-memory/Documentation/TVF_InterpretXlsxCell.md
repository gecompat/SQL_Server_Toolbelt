# TVF_InterpretXlsxCell

Die [Callerergänzung vom2026-10-26](../../../Releases/1.0.0/XLSX-CELL-CALLER-QUALIFICATION.md) belegt genau ein SELECT auf diese öffentliche TVF auf Windows/Linux SQL2019 CL150,SQL2022 CL150/160 undSQL2025 CL150/160/170 lokal/direkt zentral. Andere Zugriffe bleiben gesperrt; vollständige Fach-/Client-/Lifecycle- und Ressourcenabnahme bleibt getrennt. Die folgenden datierten Nachweise behalten ihren ursprünglichen Scope.

Invariant typisierte Einzelzelle aus der bestehenden XLSX-Raw-Ausgabe.
Kanonischer Vertrag: [XLSX_CELL_TYPE_CONTRACT.md](../../../Documentation/Architecture/XLSX_CELL_TYPE_CONTRACT.md).

```sql
SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell
 (N'n',1,N'0.00000000000000000000000000000000000001',NULL,NULL,NULL,NULL);
SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell
 (N'n',1,N'61',NULL,N'date',NULL,0);
```

Sieben Parameter in dieser Reihenfolge, jeweils Default NULL: StoredType
nvarchar(max), ValuePresent bit, RawValue nvarchar(max), TextValue
nvarchar(max), TargetType nvarchar(max), FormatCode nvarchar(max), Date1904 bit.
Die Funktion interpretiert vorhandene Werte, berechnet keine Formeln und liest
kein Workbook, Styles oder SST erneut. Die separaten Anzeigeformatierungs-
Entscheidungen gelten hier nicht.

Eine logische Zeile mit 14 Spalten: StoredType nvarchar(32), ValuePresent bit,
RawValue/TextValue nvarchar(max), EchoPreserved bit, ResolvedType nvarchar(16),
NumberValue sql_variant, BooleanValue bit, DateValue date, DateTimeValue
datetime2(7), TimeValue time(7), DurationTicks bigint, TypedTextValue
nvarchar(max), StatusCode int. NumberValue trägt ausschließlich exaktes
SqlDecimal mit Precision bis 38; SQL-Basetyp decimal/numeric, keine Float-
Näherung. Öffentliche physische Nullability und Clientmetadaten sind auf
Linux 2019/latest CL150 sowie Windows 2025/CU8 CL150/160/170 jeweils
lokal/zentral nativ geprüft; übrige physische Ziele bleiben offen.

Status 0 ist Erfolg; 1 absent, 2 Argument/Metadaten, 3 Quote, 4 Lexik/UTF16,
5 Zahlbereich, 6 unsupported, 7 Excel1900-Serial60, 8 Zeitbereich,
9 Präzisionsverlust, 10 Excelzellfehler, 11 interner NULL-Bindungsfallback.
Fehler löschen Typedwerte. Status3/11 verwirft Echos atomar mit EchoPreserved0;
andere Statuszeilen erhalten vollständige Echos. ResolvedType kann nach
erfolgter Zielauswahl bei späterem Fehler erhalten bleiben.

Ziele number/boolean/text/date/datetime/time/duration und die endliche
Formatklassifikation stehen im Vertrag. Default n ist number, niemals
automatische Datumsinferenz. Date/Datetime aus n erfordert Date1904; das
Originalintervall [60,61) des 1900-Systems liefert vor Rundung Status7.
Time liegt unter24h, Duration darf negativ und über24h sein. Rundung auf100ns
ist exakt rational, halfway away from zero. ISO-d unterstützt keine Offsets/Z.

Feste Inputcaps32/32/128/65536/65536 UTF16, Number-/Serialparser separat128.
Outputcharge262144=256+4*alle tatsächlich ausgegebenen Stringunits, mehrfacher
Text pro Feld gezählt. Keine gesamte Heap-/Laufzeitgarantie.

Aufruf setzt vorhandenes SELECT auf der öffentlichen IF voraus; keine
Berechtigungserteilung im Lifecycle. Provider: vorhandene XLSX-SAFE-Assembly,
Dependencies ZIP>=1.4.0 und ResultTable>=1.0.0 unverändert. Zielplattformen SQL
Server2019/2022/2025 Windows/Linux. Offlinekernqualifikation ist begrenzte
Evidenz. Native API-/FillRow-/Metadaten- und Lifecyclefälle bestehen im
ausgewählten Scope der [Testmatrix](../Tests/XLSX_CONTRACT_TEST_MATRIX.md);
aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft;
tatsächliche Minimalrechte bleiben offen.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StoredType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal/case- und trailing-space-sensitiv: n = numerischer Rawwert; b = Booleanraw 0/1; s = Shared-String-Index in Raw plus bereits aufgelöster Text; inlineStr = Inline-Text ohne v/Raw; str = gespeicherter Stringcache, Raw und Text exakt gleich; d = ISO-Datum/-Datetime ohne Offset; e = gespeicherter Excelzellfehler, Status 10. NULL ergibt Absent/Status 1 nach allgemeinen Längen-/Unicodeprüfungen; leer/andere Werte Status 6. Höchstens 32 UTF-16-Einheiten, keine Normalisierung. |
| `@ValuePresent` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 1 bedeutet XML-v-Element vorhanden, nicht allgemein Zellinhalt vorhanden; 0 bedeutet kein v. NULL ergibt Status 1. inlineStr verlangt 0 und RawValue=NULL, sonst Status 2. Bei anderen StoredTypes bedeutet 0 nur dann absent, wenn RawValue und TextValue beide NULL sind; widersprüchliche Inhalte ergeben Status 2. |
| `@RawValue` | `nvarchar(max)` | `NULL` | Input | Unveränderter Inhalt des gespeicherten v-Elements, maximal 65536 UTF-16-Einheiten; NULL bedeutet fehlendes v, leer bleibt von NULL verschieden. n akzeptiert ASCII-Zahlen mit optional +/- sowie Punkt/Exponent e/E, auch .5/1., ohne Spaces; für Number-/Serialparsing zusätzlich höchstens 128 Einheiten, exakter SqlDecimal-Bereich bis 38 Ziffern ohne Rundung. b verlangt exakt 0 oder 1; s einen nichtnegativen Int32-ASCII-Dezimalindex (führende Nullen erlaubt); str exakte Gleichheit zu TextValue; d ISO YYYY-MM-DD oder YYYY-MM-DDTHH:mm:ss[.1..7 Ziffern] passend zum Ziel, ohne Z/Offset. inlineStr verlangt NULL. Gespeicherter Formelcache kann übergeben werden, keine Formelberechnung. Allgemeine strikte UTF-16-Prüfung und atomare Ausgabequote gelten auch bei später ungenutztem Wert. |
| `@TextValue` | `nvarchar(max)` | `NULL` | Input | Bereits aufgelöster Shared-/Inline-/Stringcache-Text, maximal 65536 wohlgeformte UTF-16-Einheiten; leer ist gültiger Text, NULL bedeutet kein Text. s benötigt ihn im Textzweig, inlineStr benötigt ihn zusammen mit Presence=0/Raw=NULL; str muss bytegenau mit RawValue übereinstimmen. Kein erneuter SST-/Workbookzugriff oder Trim. Der feste Outputcharge zählt Echos/Typedtext mehrfach und kann vor diesem einzelnen Inputmaximum greifen. |
| `@TargetType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal ohne Trim: number = exakte SqlDecimal-Zahl; boolean = bit aus b; text = Stringtext beziehungsweise Rawdarstellung; date = Datum; datetime = datetime2(7); time = Uhrzeit unter 24h; duration = vorzeichenbehaftete 100ns-Ticks, auch über 24h. Maximal 32 UTF-16-Einheiten. NULL (Default) wählt zuerst die Formatklasse, ohne Format n→number, b→boolean, d→datetime, s/str/inlineStr→text. Leer/andere Werte oder Widerspruch zu Formatklasse ergeben Status 2. Kompatibilität mit StoredType bleibt erforderlich, keine allgemeine Cast-API. |
| `@FormatCode` | `nvarchar(max)` | `NULL` | Input | Taxativ und exakt: 0 = Zahl ganzzahlig; 0.00 = Zahl mit zwei Dezimalstellen; #,##0.00 = Zahl mit Gruppierung/zwei Stellen; 0% = Prozent ganzzahlig; 0.00% = Prozent mit zwei Stellen; 0.00E+00 = wissenschaftliche Zahl mit zwei Mantissenstellen; yyyy-mm-dd = date; yyyy-mm-dd hh:mm:ss = datetime; hh:mm:ss = time; @ = text. Keine Excel-General-/Farb-/Locale-/Mehrsektionsgrammatik, kein Trim/Casefold; höchstens 128 UTF-16-Einheiten. Zusätzlich [h]:mm:ss = duration. NULL (Default) wählt ohne Formatvorgabe nach TargetType/StoredType; Formatcode klassifiziert hier den Typ und erzeugt keinen Anzeigetext. Unbekannt/leer ergibt Status 6. |
| `@Date1904` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 0 = Excel1900-Datumssystem, 1 = Excel1904-Datumssystem. NULL (Default) ist nur bei numerischem date-/datetime-Ziel ungültig (Status 2); sonst kein implizites Workbookauslesen. Im 1900-System ist ursprüngliches Serialintervall [60,61) der fiktive Schalttag und ergibt Status 7 vor Rundung. Zeit-/Dauerwerte benötigen keinen Datumssystemdefault. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#xlsx).
