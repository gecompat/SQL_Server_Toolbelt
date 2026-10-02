# TVF_InterpretXlsxCell

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
