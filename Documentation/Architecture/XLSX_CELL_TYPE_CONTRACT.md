# XLSX-Zelltypinterpretation: Vor-Source-Vertrag

Stand: 2026-10-02. Kanonischer Vertrag für genau eine öffentliche Funktion
`toolbelt_file.TVF_InterpretXlsxCell` im bestehenden Modul
`toolbelt.file.xlsx-memory`. Der konkrete Vertrag wurde vor Source am
2026-10-02 durch Root geprüft und eingefroren; die freigegebene V3-Typwelle
ist umgesetzt. Die ausgewählte native Qualifikation ist erfolgreich;
der öffentliche Adapterport ist erfolgreich; aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft.

## Freigabe und Scope

Die individuelle Benutzerfreigabe vom 2026-10-01 für Typinterpretation und
Anzeigeformatierung ist in [.ai/BACKLOG.md](../../.ai/BACKLOG.md) dokumentiert.
Am 2026-10-02 bestätigte der Benutzer die konkret besprochene V3-Entscheidung
mit „Xlsx typeninterpretation -> freigegeben“. Dies umfasst die sieben
Parameter, 14 Spalten, exakten Zahltransport, Temporalregeln und die sichtbare
Echoausnahme bei Ressourcenfehlern dieses Vertrags.

Diese Welle interpretiert eine bereits gelesene Zelle. Sie erweitert die
bestehende SAFE-Assembly; eine interne CLR-FT und eine öffentliche Inline-TVF
sind technische Bindungen derselben Fachfunktion. Bestehende Raw-Reader,
ZIP-/XML-Kern und deren Verträge bleiben unverändert. Die Funktion liest kein
Workbook erneut und verwendet keine Context Connection, Dateien, Netzwerke,
neue Bibliothek oder SDK. Style-/Formatkataloge und Workbook-Datumssystem
werden nicht zusätzlich ermittelt: der Caller übergibt die benötigten Werte.
Anzeigeformatierung und Formelberechnung gehören nicht zu dieser Welle.

## Öffentliche Form

Alle Parameter haben den Default `NULL`, in dieser Reihenfolge:

| Parameter | SQL-Typ |
|---|---|
| StoredType | nvarchar(max) |
| ValuePresent | bit |
| RawValue | nvarchar(max) |
| TextValue | nvarchar(max) |
| TargetType | nvarchar(max) |
| FormatCode | nvarchar(max) |
| Date1904 | bit |

Das logische Resultat enthält genau eine Zeile, auch bei ausschließlich
NULL-Argumenten. Keine `ReturnsNullOnNullInput`-Abkürzung ist zulässig.

| Ordinal | Spalte | SQL-Typ | Logische NULL-Semantik |
|---:|---|---|---|
| 1 | StoredType | nvarchar(32) | nullable |
| 2 | ValuePresent | bit | nullable |
| 3 | RawValue | nvarchar(max) | nullable |
| 4 | TextValue | nvarchar(max) | nullable |
| 5 | EchoPreserved | bit | immer 0 oder 1 |
| 6 | ResolvedType | nvarchar(16) | nullable |
| 7 | NumberValue | sql_variant | nullable |
| 8 | BooleanValue | bit | nullable |
| 9 | DateValue | date | nullable |
| 10 | DateTimeValue | datetime2(7) | nullable |
| 11 | TimeValue | time(7) | nullable |
| 12 | DurationTicks | bigint | nullable |
| 13 | TypedTextValue | nvarchar(max) | nullable |
| 14 | StatusCode | int | immer 0 bis 11 |

Die interne CLR-FT deklariert alle Spalten nullable. Tatsächliche öffentliche
SQL-Nullability ist erst durch Katalog- und Clientnachweise festzustellen;
logisch nicht-NULL ist noch kein Metadaten-PASS. Ein unerwarteter interner
NULL-Status ergibt öffentlich Status 11, EchoPreserved 0 und NULL in allen
übrigen zwölf Spalten. Andere Provider-/Enginefehler bleiben Originalfehler.

`NumberValue` enthält ausschließlich `SqlDecimal`, SQL-Basetyp `decimal` oder
dessen Synonym `numeric`, mit Precision 1 bis 38 und Scale 0 bis 38. Wert,
Precision und Scale bleiben exakt; keine Double-/System.Decimal-Näherung und
kein festes decimal(38,18). Die übrigen typisierten Spalten tragen jeweils
den gewählten Typ. Bei Erfolg sind unzutreffende Typedspalten NULL.

## Status, Echo und Ressourcen

| Code | Bedeutung |
|---:|---|
| 0 | OK |
| 1 | ABSENT_OR_NULL |
| 2 | ARGUMENT_OR_METADATA |
| 3 | INPUT_OR_OUTPUT_LIMIT |
| 4 | INVALID_LEXICAL_OR_UTF16 |
| 5 | NUMBER_RANGE |
| 6 | UNSUPPORTED_FORMAT_OR_STOREDTYPE |
| 7 | EXCEL_1900_SERIAL60 |
| 8 | TEMPORAL_RANGE |
| 9 | PRECISION_LOSS |
| 10 | EXCEL_ERROR |
| 11 | UNEXPECTED_NULL_BINDING |

Bei fachlichen Fehlern sind Spalten 7 bis 13 NULL. EchoPreserved 1 bedeutet
vollständig unveränderte StoredType-/Presence-/Raw-/Text-Echos. ResolvedType
darf nach erfolgreicher Zielauswahl auch bei einem späteren Fehler erhalten
bleiben; davor ist es NULL. Status 3 und 11 verwerfen die gesamte Echo- und
Typedausgabe atomar, EchoPreserved 0; kein Text wird abgeschnitten.

| Input | Grenze in UTF-16-Codeeinheiten |
|---|---:|
| StoredType / TargetType jeweils | 32 |
| FormatCode | 128 |
| RawValue / TextValue jeweils | 65536 |
| RawValue nur im Number-/Serialparser | 128 |

Das feste Ausgabebudget beträgt 262144 Chargebytes:
`256 + 4 * Summe(UTF16Units aller tatsächlich ausgegebenen Stringfelder)`.
Die Summe umfasst StoredType, RawValue, TextValue, ResolvedType und
TypedTextValue; gleicher Inhalt zählt pro Feld. Feste Werte einschließlich
NumberValue sind im 256-Byte-Anteil berücksichtigt. Die finale Quote gilt
auch für Fehler- und Absentzeilen und kann deren Status durch 3 ersetzen.
Kein öffentlich erhöhbares Budget. Vor unnötiger Materialisierung sind
Inputlängen zu prüfen; gesamte Heap-, SQL-Memorygrant- oder Laufzeitgrenzen
werden daraus nicht behauptet.

Harte Quote: `s`, Presence 1, Raw `0`, Text mit 32733 Einheiten und Ziel text
erreicht exakt 262144; 32734 scheitert atomar. Bei `str` mit gleichem Raw-/Text-
und Typedtext erreichen 21821 Einheiten 262136, 21822 bereits 262148. Diese
beiden Rasterwerte sind kein exakt-at-262144-Witness.

## Metadaten und genaue Fehlerreihenfolge

Vergleiche sind ordinal nach UTF-16, case- und trailing-space-sensitiv,
unabhängig von Caller-Collation. Es gibt kein Trim oder Culturemapping.
Der vorhandene Raw-Reader normalisiert fehlendes XML-`c@t` bereits zu `n`;
ein hier ausdrücklich NULL übergebenes StoredType wird nicht normalisiert.

Die folgende Reihenfolge konkretisiert die qualifizierte V3-Semantik:

1. Allgemeine Inputlängen, dann striktes UTF-16 sämtlicher übergebener Strings,
   auch ungenutzter Target-/Format-/Textwerte.
2. NULL StoredType oder NULL ValuePresent ergibt 1.
3. `inlineStr`: Presence 1 oder Raw nicht NULL ergibt 2; Text NULL ergibt 1.
   Andere Typen: Presence 0 ergibt 1 bei Raw und Text NULL, sonst 2.
4. `s` verlangt einen nichtnegativen invarianten Int32-Dezimalindex in Raw
   (ASCII-Ziffern, führende Nullen erlaubt). `str` verlangt exakte Gleichheit
   von Raw und Text einschließlich NULL. Verstöße ergeben 2.
5. Unbekannter StoredType ergibt 6; danach unbekannter Target 2, unbekannter
   Formatcode 6, Widerspruch zwischen gültigem Target und Formatklasse 2.
6. Ziel auswählen; `e` ergibt nun 10. Anschließend zielbezogene Presence-,
   Kompatibilitäts-, Lexik-, Bereichs- und Präzisionsprüfungen.
7. Finale atomare Ausgabequote.

Insbesondere wird fehlender Text für `s` erst im Textzweig geprüft; ein
unbekannter Formatcode kann deshalb davor 6 liefern. Fehlender Rawwert bei
`n` wird ebenfalls erst im gewählten Zweig geprüft. Diese Fälle dürfen nicht
durch einen pauschalen früheren Presencefehler umgeordnet werden.
Ein 129-Zeichen-Number-/Serialraw ergibt nach Kompatibilität, aber vor
fehlendem Date1904 und Parsing, Status 3. Ein als Text behandelter Rawwert
unterliegt diesem separaten 128-Limit nicht.

`ValuePresent` bezeichnet XML-`<v>`, nicht allgemein einen Zellwert. Eine
gültige inlineStr-Zelle hat Presence 0, Raw NULL, Text gesetzt. `s` verwendet
bereits aufgelösten Text; SST-Existenz und Workbook-Konsistenz außerhalb der
Inputs werden nicht erneut geprüft. Gespeicherter Formelcache kann als
vorhandener Raw-/Textwert verarbeitet werden; Formeln werden nicht berechnet.
Leerer Text bleibt leer, leerer numerischer Rawwert ist Lexikfehler 4.

## Ziele und endliche Formatgrammatik

Targets: `number`, `boolean`, `text`, `date`, `datetime`, `time`, `duration`.
Explizites Ziel hat Vorrang, muss aber zur angegebenen Formatklasse passen.
Ohne Ziel bestimmt ein bekannter Formatcode den Typ. Ohne beides gilt
`n -> number`, `b -> boolean`, `d -> datetime`, `s/str/inlineStr -> text`.
Zahlen werden nie nach ihrer Größe als Datum interpretiert.

| Exakte Formatcodes | Klasse |
|---|---|
| `0`, `0.00`, `#,##0.00`, `0%`, `0.00%`, `0.00E+00` | number |
| `yyyy-mm-dd` | date |
| `yyyy-mm-dd hh:mm:ss` | datetime |
| `hh:mm:ss` | time |
| `[h]:mm:ss` | duration |
| `@` | text |

Dies ist Klassifikation, keine Formatierung, Prozentumrechnung oder
Anzeigerundung. General, Farben, Bedingungen, Mehrfachabschnitte,
Locale-Direktiven und andere Escapeformen sind unsupported. Der einzelne
Code `#` gehört nicht zur Grammatik.

Text nimmt bei `s/str/inlineStr` TextValue, sonst RawValue; NULL im gewählten
Textfeld ergibt 2. Boolean ist nur für `b` zulässig, Raw exakt `0` oder `1`,
sonst 4. `d` unterstützt außer Text ausschließlich date/datetime. Alle
anderen Number-/Temporalziele erfordern `n`, sonst 2. `e` ergibt immer 10
nach gültiger Ziel-/Formatauswahl.

## Exakte Zahlen und Zeitwerte

Number-/Seriallexik ist ausschließlich ASCII:
`[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?`.
Kein Whitespace, NaN, Infinity, Hex oder Kulturtrennzeichen. Ungültige Lexik
ergibt 4; Exponent außerhalb [-64,64], mehr als 38 signifikante Ziffern oder
Scale über 38 ergeben 5. Führende Koeffizientnullen werden entfernt;
Nachkommastellen-Endnullen werden bei positiver Scale entfernt. Null wird
zu positiver 0 mit Precision 1 / Scale 0 normalisiert. Negative Scale wird
durch Endnullen erweitert, sofern die 38-Ziffern-Grenze eingehalten bleibt.
Precision ist max(1, Ziffernzahl, Scale). Exponentbereich wird vor Null-
Normalisierung geprüft; beispielsweise `0e-65` bleibt Fehler 5.

Datum/datetime aus `n` benötigt Date1904. 1900 verwendet Basis 1899-12-31:
Serial 1 ist 1900-01-01; 0 und negative Werte ergeben 8. Das gesamte
Originalintervall [60,61) ergibt 7, vor Rundung und date-Präzisionsprüfung.
Oberhalb davon wird der fiktive Schalttag abgezogen. 1904 verwendet
1904-01-01 als Serial 0; negative Werte ergeben 8.

Date verlangt integral, sonst 9. Datetime/Time/Duration werden exakt rational
mit 864000000000 Ticks pro Tag auf 100 ns gerundet, halfway away from zero,
ohne Double. Ein gültiger Wert knapp unter 60 darf zu 1900-03-01 tragen;
Originalwerte in [60,61) bleiben 7. Date/datetime reichen höchstens bis
9999-12-31 im jeweiligen SQL-Typ. Numberbereichsprüfung geht Temporalbereich
voraus. Time verlangt 0 <= Serial < 1; Rundung auf 24 h ergibt 8, kein Modulo.
Duration erlaubt negative Werte und mehr als 24 h, im symmetrischen Bereich
[-Int64Max, Int64Max]; Int64Min wird mit 8 abgewiesen. Time und Duration
ignorieren Date1904.

StoredType `d` akzeptiert invariant `yyyy-MM-dd` für date oder
`yyyy-MM-ddTHH:mm:ss` mit optional 1 bis 7 ASCII-Nachkommastellen für datetime.
Gregorianische Ungültigkeit, Offset/Z, mehr als sieben Fractiondigits und
Abschneiden einer Zeit zu date ergeben 4. Date1904 ist hier irrelevant.

## Vorhandene Evidenz und offene Integrationsgates

Historischer Vor-Source-Zwischenstand vom 2026-10-02: Die private
V3-Frameworkqualifikation prüfte drei getrennte Kulturen de-DE/en-US/tr-TR,
je 652 unabhängige API-Goldens, zusammen 1956, plus atomare Quotenseams.
Der frühere Numerik-/Temporalharness mit je 370 Fällen war zu diesem
Zwischenstand nicht erneut ausgeführt; frühere API-538-Läufe bleiben
historische, getrennte Evidenz.

Aktueller öffentlicher Frameworknachweis 2026-10-02:
`Modules/toolbelt.file.xlsx-memory/Tests/Framework/Invoke-Types.ps1` führte
je Kultur tatsächlich API652 und Numeric-/Temporal370 aus. Einschließlich
der zusätzlichen Orakel bestanden je 6437 Assertions in de-DE/en-US/tr-TR,
insgesamt 19311. Das ist begrenzte Zellkernevidenz; SQL/FillRow/SAFE/Lifecycle
werden separat nachgewiesen und gesamte Heapgrenzen nicht zugesagt.

Separate technische Hostqualifikation auf SQL Server 2019/Linux/latest und
SQL Server 2025/Windows/CU8 prüfte ein synthetisches FT-/IF-Binding:
14 nullable FT-Spalten, zwölf feste Cases einschließlich SQL-NULL-Input,
exakte 38-stellige SqlDecimal-Varianten und Scale 38, 100-ns-Temporaltransport
sowie NULL-Statusfallback. Der zunächst zu enge decimal-only-Basetyporacle
scheiterte am gültigen numeric-Synonym; der korrigierte Oracle behielt exakte
Wert-/Precision-/Scaleprüfungen. Eigene Testdatenbanken und eigener temporärer
Trustscope wurden anschließend bereinigt. Dies qualifiziert weder den
öffentlichen Zellparser noch die tatsächliche Modulinstallation.

Vor Source: unabhängiger Review dieses Vertrags. Vor Runtime-/Merge-PASS:
integrierter Frameworkkern, echte FillRow-/öffentliche IF-/Katalog-/Client-
Metadaten, NULL-/Prioritäts-/Quote-/Collationoracles, Komposition mit dem
unveränderten Raw-Reader, unabhängiger NoIO-/SAFE-Providerreview, echte
historische Upgrade-/Repeat-/Collision-/CallerTX-/Rollback-/Consumer-/
Uninstalltests und grüne scopebezogene CI. Bestehende Raw-Reader-Evidenz wird
nicht auf diese API übertragen. Weitere Plattform-/Versionstests und
Minimalrechte bleiben offen, soweit nicht tatsächlich ausgeführt.

Ergänzende konkrete Lifecyclefreigabe 2026-10-02: Auf die separate Frage
antwortete der Benutzer „Ja, XLSX-Lifecycle-Sichtbarkeitsgate freigeben“.
Deploy und Uninstall benötigen vorhandenes Datenbank-`VIEW DEFINITION` und
`SELECT` auf `sys.sql_expression_dependencies`; 0, NULL oder unklare Prüfung
blockiert mit 51535/State 2 vor Mutationen und erneut unter dem AppLock.
Es werden keine Rechte erteilt. Synthetische Predicate-Injektionen qualifizieren
die Gatebehandlung, ersetzen aber keinen tatsächlichen Minimalrechtekontext.

Lab-Auswahl, Schema-/READY-/Zusatzpromptprüfung, eigener synthetischer
Datenbank-/Trustscope und Cleanup erfolgen erst separat koordiniert durch
Root. Weitere Rechteausweitung oder neue Sicherheitsgrenzen werden nicht
abgeleitet. Geschützte Lizenzinhalte bleiben unverändert.

Primärquellen: [CLR-Tabellenfunktionen](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions),
[CLR-Parametermapping](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-types-net-framework/mapping-clr-parameter-data),
[decimal/numeric](https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql).


## Ausgeführter Modulnachweis 2026-10-02

XLSX 1.1.0 ergänzt die einzeln freigegebene `TVF_InterpretXlsxCell` im bestehenden SAFE-Provider. Der finale öffentliche Typadapter bestand am 2026-10-02 auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral: drei Types-Runtime-Fixtures, exakte Zahlen-/100-ns-/NULL-/Clientmetadaten, clean/genuine 1.0/Repeat, Caller-TX OFF/ON intakt und doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, Sichtbarkeitsprädikate, Uninstall und eigene Bereinigung. Raw→Type-Komposition wurde nach den API-CL-Schleifen auf der jeweils letzten CL (2019:150, 2025:170) sowie separat im zentralen Caller geprüft. Keine Konfigurations- oder Rechteänderungen. Die öffentliche Pfadfassung bestand nach ihrem unabhängig geprüften Port auf beiden ausgewählten Targets einschließlich frischer eigener Bereinigungsprüfungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Minimalrechte, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. `partially validated`, `unreleased`; historische Raw-1.0-Evidenz bleibt getrennt.

Die Sichtbarkeitsfälle injizieren synthetisch 0/NULL vor und unter AppLock;
dies ist keine tatsächliche Lowpriv-Qualifikation. Intakte Callerfälle
verwenden direkte Clientbatches. Doomed-Callerfälle verwenden die exakten
Erstbatchbytes inline in Setup/CATCH/Oracle/Rollback mit zwingender
Resultrow-SelfWitness; sie sind keine SQLCMD-Prozessqualifikation. Ein
früheres nested-EXEC-Orakel war bei XACT_ABORT ON bereits ohne Toolbelt
doomend. Frühere fehlgeschlagene Adapterstände bleiben FAILED. Die
öffentlich portierte Testlogik enthält keine neue fachliche Semantik.
