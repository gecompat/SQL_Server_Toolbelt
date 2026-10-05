# XLSX-Anzeigeformatierung – genehmigter Vertragsumfang

Stand 2026-10-03. Konkreter Vertragsumfang und Implementierung sind ausdrücklich
freigegeben. Bestätigt sind die drei expliziten Kulturen, half-away-from-zero,
Datetimecarry/time24h-Status8 und die unveränderte Typquote. Additive Version1.2.0
im bestehenden SAFE-Provider, keine neue fachliche API außerhalb dieser TVF.
Begrenzte Offline-/lokale Nativequalifikation vom 2026-10-04 und zentrale Upgrade-/Consumerqualifikation auf Linux2019 vom 2026-10-05 bestanden; vollständige Matrix, Minimalrechte und aktuelle Head-CI bleiben separate Gates.
Kein vollständiger Produktnachweis; historische Kern-/Transportproben bleiben getrennt.
Nur öffentliche Quellen und synthetische Beispiele.

## 1. Herkunft und unveränderter Scope

Der persönliche Ideenpool wurde zuerst vollständig gelesen, anschließend
.ai/BACKLOG.md, insbesondere die individuell freigegebene XLSX-Typ-/Anzeige-
Welle. XLSX_CELL_TYPE_CONTRACT.md ist die Quelle der bestehenden sieben
Raw-/Typinputs, Status 0..11, exakten SqlDecimal- und Temporalregeln.
Vorhandene Raw-USPs und TVF_InterpretXlsxCell bleiben unverändert.

Genau eine neue logische Anzeige-TVF im bestehenden SAFE-Workbookprovider.
Eine interne CLR-FT und öffentliche IF sind technische Bindungen dieser einen
Fachfunktion. Kein Workbook-/Stylekatalog, kein neuer Reader, keine Library,
Datei, Context Connection, Netzwerk, Worker, Formelberechnung oder Rechte.
Die bestehende XML-/ZIP-Fassade wird nicht verändert. Formatcode, aufgelöster
Text und Datumssystem sind ausdrücklich vom Caller übergebene Inputs.

## 2. Reviewbare öffentliche Form

Öffentlicher Name: toolbelt_file.TVF_FormatXlsxCell.
Alle acht Parameter haben Default NULL, in dieser Reihenfolge:

| Ordinal | Input | SQL-Typ |
|---:|---|---|
| 1 | StoredType | nvarchar(max) |
| 2 | ValuePresent | bit |
| 3 | RawValue | nvarchar(max) |
| 4 | TextValue | nvarchar(max) |
| 5 | TargetType | nvarchar(max) |
| 6 | FormatCode | nvarchar(max) |
| 7 | Date1904 | bit |
| 8 | CultureName | nvarchar(max) |

Genau eine Resultrow; Spalte 1 DisplayText nvarchar(max), Spalte 2 StatusCode
int. Logischer Status immer 0..11. FT-Metadaten sind nullable; öffentliche
Native SQL-/Clientmetadaten sind auf den zwei ausgewählten lokalen Zielen
vom 2026-10-04 begrenzt qualifiziert; keine allgemeine Nullability-Matrix. Unerwarteter interner
NULL-Status wird durch die IF zu Status 11 und DisplayText NULL, niemals zu
Erfolg. Keine ReturnsNullOnNullInput-Abkürzung. Andere Engine-/Providerfehler
bleiben Fehler; keine pauschale Exception-zu-Status-Umdeutung.

Erfolg kann leeren Text enthalten. Absent/Fehler liefert DisplayText NULL.
Kein Echo in dieser Zweispalten-API; Rohwert bleibt im unveränderten Raw-/Typ-
Resultat verfügbar. CROSS/OUTER APPLY kann Raw, Type und Display zusammensetzen.
Kein Formula-/Cache-Frischeflag wird erfunden.

## 3. Endliche erste Grammatik

Nur exakt folgende zehn Strings; UTF-16-ordinal, case- und padding-sensitiv,
kein Trim, kein Excel-/NET-Formatparser für zusätzliche Muster:

| FormatCode | Typklasse / Anzeige |
|---|---|
| 0 | number, ganzzahlig |
| 0.00 | number, zwei Nachkommastellen |
| #,##0.00 | number, Dreiergruppen und zwei Nachkommastellen |
| 0% | number, mal 100, ganzzahlig, unmittelbar % |
| 0.00% | number, mal 100, zwei Nachkommastellen, unmittelbar % |
| 0.00E+00 | number, drei signifikante Stellen, großes E, Exponentvorzeichen |
| yyyy-mm-dd | date, Gregorianisch, vierstelliger Year |
| yyyy-mm-dd hh:mm:ss | datetime, Gregorianisch, 24h |
| hh:mm:ss | time, 24h |
| @ | text, vollständige unveränderte TypedTextValue |

General, andere Platzhalter, Farben, Bedingungen, Mehrfachabschnitte,
Währungen, Skalierungskommas, Locale-/Calendar-Direktiven, quoted literals,
Escapes, AM/PM, Width/Layout und bedingte Formate sind Status 6.
[h]:mm:ss bleibt in der vorhandenen Typklassifikation gültig, ist in diesem
Anzeige-Slice Status 6: elapsed-duration-Anzeige wird aus der freigegebenen
Datum/Uhrzeit-Liste nicht zusätzlich abgeleitet. Kein Boolean-Anzeigeformat;
über @ und Ziel text darf Raw 0/1 unverändert als Text angezeigt werden.

## 4. Explizite Culture – konkreter erster Vorschlag

CultureName ist für vorhandene erfolgreich interpretierbare Zellen notwendig,
auch bei @ und Temporalformaten. Erste geschlossene Menge: en-US, de-DE,
tr-TR; keine Aliase, Parentculture, leere Culture, CurrentCulture, OS-User-
Overrides oder implizite InvariantCulture. Unbekannt/NULL -> Status 2.

| Name | Dezimalzeichen | Gruppierung | Minus | Prozent |
|---|---|---|---|---|
| en-US | . | , | - | % |
| de-DE | , | . | - | % |
| tr-TR | , | . | - | % |

Die festgeschriebenen Zeichen sind Vertragsdaten, keine aus dem aktuellen
Betriebssystem gelesenen Daten. Gruppen immer drei ASCII-Ziffern, Zahlen mit
ASCII-Ziffern. Prozentzeichen unmittelbar ohne Kulturabstand: dies folgt dem
literal vorgegebenen Format, nicht NET-Standardformat P. Datumstrennzeichen
'-', Zeit ':', Zwischenraum U+0020 und Gregorianischer Kalender sind literal.
Culture ändert weder Inputlexik noch text, ISO-Kalender oder Typwahl.

Reviewentscheidung vor Source: diese erste endliche Culture-Menge bestätigen
oder konkret ersetzen. Beliebige CultureInfo-Namen würden zusätzliche
Plattform-/Version-/Calendar-/Useroverride-Gates erfordern; sie werden hier
nicht stillschweigend unterstützt. Das ist eine technische Scopepräzisierung,
keine neue Freigabe für einen Provider oder eine weitere Funktion.

## 5. Zahlen, Rundung und Überlauf

Kanonischer Typkern interpretiert unverändert exakt SqlDecimal (bis Precision
38/Scale38), keine .Value-Konvertierung zu System.Decimal und kein Double.
Anzeige verarbeitet den exakten vorzeichenbehafteten Dezimalkoeffizienten
und Scale; keine zweite Numberlexik. Wiederverwendbarer vorhandener
Koeffizientzugriff oder eng begrenzter SqlDecimal.Data-Zugriff vor Source
qualifizieren; neue Bibliothek nicht voraussetzen.

Vorschlag: exact nearest, halfway away from zero, anhand Ganzzahlrest und
Dezimalpotenz. 0/0% mit 0, übrige Festformate mit 2 Dezimalstellen; Prozent
skaliert mathematisch exakt um 100 VOR Anzeigerundung. Das verändert weder
Typedwert noch dessen Precision/Scale. Eine 38-stellige Ganzzahl darf in
Prozentanzeige 40 Integerstellen bekommen: kein versehentlicher decimal38-
Zwischenspeicher. Eine Rundung auf null zeigt kein negatives Nullzeichen.

Wissenschaftlich: Normalform eine Integerstelle, zwei Fractionstellen,
Exponent +/- und mindestens zwei Dezimalziffern; exakt drei signifikante
Stellen, Carry 9.995 -> 1.00E+01. Null -> 0.00E+00. Gleiches Kulturdecimal;
kein Kulturzeichen für E/sign. Normalisierung läuft auf höchstens 38
Koeffizientziffern; carry und Exponent sind checked. Keine freigegebene
Numerikzahl wird wegen eines unpassenden System.Decimal-Zwischentyps verworfen.

Diese Tie-Regel ist der konkrete Toolbelt-Vorschlag, keine qualifizierte
universelle Excel-/Binary64-Parität. Sichtbare Rundung ist Teil der Anzeige,
kein Status9; Typinterpretation selbst bleibt exakt.

## 6. Temporal, 1900/1904 und Cache

Serialparser und 100ns-Rundung ausschließlich aus dem vorhandenen Typkern:
1900 Original[60,61) -> 7 vor jeder Anzeige; 1904 Seriennull -> 1904-01-01;
Date1904 für numerische date/datetime nötig, time ignoriert es. ISO d bleibt
invariant ohne Offset/Z. Kein Serial erneut als Double; kein Datumraten.

Vorschlag für Sekundenanzeige: vorhandene 100ns-Ticks nearest auf volle
Sekunden, midpoint away from zero. Datetime-Carry darf Tag/Monat/Jahr ändern;
Carry jenseits SQL-Maxdatetime -> 8. Time-Carry auf 24:00:00 -> 8, kein
Modulo und keine stillschweigende Datumsinterpretation. Date ist schon
integral und erhält keine zusätzliche Rundung. Explizites Target muss exakt
zur Formatklasse passen, wie im Typvertrag.

Reviewentscheidung vor Source: Sekundenrundung und Time-Endcarry bestätigen.
Microsofts öffentlich gelesene Formatbeschreibung belegt hh/mm/ss und
Fractiondarstellung, aber nicht diese vollständige 100ns-Tie-/Carry-Regel.
Alternative wäre Präzisionsstatus9 bei nichtintegraler Sekunde; diese
Alternative ist NICHT zugleich Default oder heimlich implementiert.

Formula wird nie berechnet; gespeicherte Caches werden wie vorhandene Raw-
Inputs verarbeitet. s verwendet vom Reader aufgelöstes TextValue und Rawindex;
inlineStr hat Presence0/RawNULL; str benötigt unveränderten Raw==Text. Kein
Styletransport wird ergänzt: aktuelle Rawcells haben keinen allgemeinen
Stylekatalog. Caller mit FormatCode aus eigener freigegebener Quelle kann
komponieren; dieser Formatter liest das Workbook nicht erneut.

## 7. Ressourcen und genaue Statuspriorität

Bestehende Statusnamen und Werte 0..11 aus dem Typvertrag werden übernommen;
kein neuer Status und keine SQL-Fehlerreservierung. Cultureargumentfehler=2,
nicht unterstütztes Anzeigeformat=6, Anzeige-Temporalcarry=8, finale Quote=3.

Inputgrenzen: vorhandene StoredType/Target32, Format128, Raw/Text65536;
CultureName32 UTF16Units. Number-/Serialraw128 bleibt typzweigspezifisch.
UTF16 strikt, keine Normalisierung. Vor Materialisierung Länge prüfen.

Vorschlag bewusst ohne Bypass des bestehenden Type-Evaluate: dessen vollständige
Echo-/Typedquote262144 bleibt auch bei interner Wiederverwendung wirksam.
Ein langer Text kann deshalb am bisherigen Typ-Echobudget scheitern, obwohl
nur DisplayText zurückgegeben würde. Dies ist ausdrücklich reviewbare
Kompositionsgrenze, kein behaupteter Formatter-65536-Textnachweis. Eine
spätere shared-typed-only Refaktorierung wäre gesondertes Delta mit vollständiger
V3-Unverändertheitsqualifikation; hier nicht beauftragt.

Zusätzlich finale Anzeigequote262144 mit Charge=256+4*UTF16Units(DisplayText).
Maximal65472 Units nach genau dieser Formel.
Die isolierte Renderer-/Budgethelpergrenze65472/+1 ist kein erreichbarer
öffentlicher @-Grenzfall: das unverändert vorgeschaltete Type-Echobudget
blockiert lange Textwerte früher. Öffentliche Kompositionsorakel bleiben
s32733/32734 und str21821/21822. Ein späterer isolierter Helper-Test beweist
nur dessen lokale Budgetarithmetik, keinen öffentlichen API-PASS.
Fach-/Absentzeilen mit DisplayNULL charge256. Keine Teilstrings/Trunkierung;
vor Ausgabe Größe aus vorhandener Textlänge bzw. bounded Numerik-/Temporalform
ermitteln. Zwischencopies: höchstens vorhandene bounded Typeausgabe + eine
bounded Anzeige; kein allgemeiner Heap-/SQLgrant-/CPU-Nachweis daraus.

1. Alle acht allgemeinen Inputlängen, dann striktes UTF16 sämtlicher Strings;
   Längefehler3 vor UTF16fehler4. Bestehende sieben Inputs behalten ihre Ordnung.
2. Unveränderten kanonischen Type-Evaluate ausführen (inklusive Presence,
   Target/Format, Parser, Statuspriorität und atomarer Typequote). Jeder
   Type-Status ungleich0 wird identisch weitergegeben, DisplayNULL; keine
   Culturefehlerüberdeckung dieser fachlichen Typefehler.
3. Bei Type-Erfolg: Culture NULL/unbekannt ->2; Format NULL ->2; von Type
   akzeptiertes, aber nicht unterstütztes Anzeigeformat ->6.
4. Zahl-/Text-/Temporalrenderer. Kein passender Typedslot oder unerwarteter
   NULL ->11. Anzeige-Carrybereich8; keine technischen Ausnahmen als Erfolg.
5. Finale Anzeigequote; Überschreitung3, atomarNULL.

AllNULL ergibt1 nach Type, nicht eine künstliche Culturepflicht-Fehlermeldung.
Erfolgreicher emptyText plus @ und bekannte Culture ergibt emptyText/0.
Ungenutzte Culture mit invalidUTF16 oder Länge33 kann nach Schritt1 dennoch
4/3 vor Absent ergeben, wie andere ungenutzte Inputs im Typvertrag.

## 8. Alternativen, Risiken und konkrete Vor-Source-Gates

SQL FORMAT delegiert CLR/.NET Formatsemantik, bildet aber diesen SqlDecimal38-
und endlichen Excelcodevertrag nicht unverändert ab; keine neue Context-
Connection/SQLFORMAT-Doppelimplementation. Externes Excel/OpenXML-SDK würde
IO/Library-/Workergrenzen erweitern; ausgeschlossen. Ein typed-only Formatter
würde eine andere öffentliche Signatur erfordern; dieser Kandidat bevorzugt
sichtbare Raw/Typekomposition innerhalb des bestehenden Providers.

Vor Source schließen Root+Queue: acht Inputs/zwei Outputs, genaue erste
Culturemenge, feste Rundung/Timecarry, Type-Echoquote als Kompositionsgrenze
und zehn Literalcodes. Materiell neue Library/Stylekatalog/elapsedDuration/
Culturecalendar-/Providergrenzen müssten gesondert besprochen werden; sie
sind nicht Teil dieses Vorschlags. Keine erneute Frage zur vorhandenen
Einzelfunktionsfreigabe aus diesem Dokument ableiten.

Danach erst private bounded Numerik-/Temporalreferenz und Frameworkcorpus
planen: independent integer/rational expected values, drei Ambientcultures
bei jedem expliziten Cultureinput, exact38/scale38/percent40digits, negative
Ties/scientificcarry; Output-/Typequote at/+1; invalidUTF16/alle Prioritäten,
Serial59/60/61/1904,cache/s/inlineStr/str/NULL. Jede Enumeration/Array/SqlChars-
FillRowausgabe und actualNoIOIL separat. SQL-Metadaten/nullableFallback,
Rawkomposition/konstanteAPPLY/OuterCASE und echter1.1Upgrade/Repeat/Future-
Collision/Caller/AppLock/Cleanup erst koordinierte weitere Root-Welle.
Keine bestehende Type-Runtimeevidenz auf Formatter übertragen.

## 9. Primärquellen und genaue Reichweite

[Microsoft Excel-Formatleitfaden](https://support.microsoft.com/en-us/excel/review-guidelines-for-customizing-a-number-format)
belegt Platzhalter, Dezimalanzeigerundung, Gruppierung, Prozent-mal100,
Exponentcodes, Textplatzhalter und Datums-/Zeitfamilien. Er belegt keinen
vollständigen Excelroundtrip für SqlDecimal38, keine 100ns-Tiegrenze und keine
Parität mit einer bestimmten Excel-Binary64-/Layout-Version.

[Microsoft .NET Zahlenformate](https://learn.microsoft.com/en-us/dotnet/standard/base-types/standard-numeric-format-strings)
unterscheidet Rundungs-Tie-Verhalten nach Runtimeversion. Unser Vorschlag
fixiert die Semantik selbst statt CurrentCulture oder System.Decimal/Double-
ToString für SqlDecimal38 einzusetzen.

[Microsoft Excel-Datumssysteme](https://support.microsoft.com/en-us/excel/date-systems-in-excel)
beschreibt unterschiedliche 1900-/1904-Basen. Die genaue Serial60- und
100ns-Behandlung ist der bestehende Toolbelt-Typvertrag, keine daraus neu
abgeleitete Excelanzeigeparität.

Alle Quellen am 2026-10-03 gelesen; keine längeren Zitate kopiert. Source,
Framework, native Bindings, NoIO-/IL, Lifecycle und CI waren im historischen
Vorbereitungsstand NOT_EXECUTED. Aktuell sind zusätzlich die19-Phasen-Offlinefolge und ausgewählte lokale
Clean-/genuine1.1-Upgrade-/Client-/Kompositions-/Lifecyclefälle begrenzt
qualifiziert. Zentrale Nutzung, vollständige Matrix und aktuelle CI bleiben offen. Die beiliegenden Tabellen sind vorgeschlagene synthetische
Revieworakel, keine tatsächlichen PASS-Ergebnisse.
## Zusätzliche Benutzerentscheidungen 2026-10-03

Nach Einzelbesprechung bestätigte der Benutzer die drei zusätzlichen Grenzen
mit „ja“: ausschließlich en-US/de-DE/tr-TR mit festen, von Betriebssystem-
einstellungen unabhängigen Zeichen; exakte Dezimalrundung mit halben Werten
von null weg, volle Sekunden mit zulässigem Datetime-Tagescarry und Ablehnung
eines Time-Carry auf 24 Stunden; unveränderte Eingabe- und Textbudgets der
bestehenden Typinterpretation. Damit sind die oben als Vorschlag bezeichneten
Culture-, Rundungs-/Carry- und Kompositionsbudgetentscheidungen genehmigt.
Die individuelle Funktionsfreigabe vom 2026-10-01 bleibt bestehen.

Der Benutzer hat anschließend die autonome Umsetzung mit unabhängigem Review,
erforderlicher grüner CI, PR-Merge nach origin/main und eigenem Branch-/
Worktree-Cleanup ausdrücklich wieder aufgenommen. Zustimmung ist kein
Implementierungs- oder Qualifikationsnachweis. Technische Vor-Source-Gates,
gebundene Produktartefakte und tatsächliche Native-/Lifecycle-Nachweise werden
separat geschlossen. Historische Aussagen der Vorbereitung bleiben als solche
erkennbar; keine Veröffentlichung ist freigegeben.
## Begrenzte aktuelle Evidenz 2026-10-04

Am 2026-10-04 bestand ein privater Qualifikationsadapter auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170 jeweils ausschließlich lokal: Clean1.2 und genuine installierte1.1→1.2 mit frischer Session, drei→vier CLR-Bindings und sieben→neun Slots am identischen aktuellen Binary. Je Ziel bestanden zwölf SQL-Fixtures, sechs Display-Clientprüfungen und zwei Raw→Type-/Raw→Type→Display-Kompositionen, Repeat sowie Uninstall/Repeat. Zwei eigene Datenbanken wurden entfernt und drei exakte Trust-Vorzustände wiederhergestellt; frische unabhängige Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte- oder Owneränderungen.

Dies ist ein begrenzter privater Adapternachweis, kein vollständiger öffentlicher Labadapter- oder Produkt-PASS. Zentrale1.2-Nutzung, genuine1.0→1.2, weitere CL/Ziele, vollständige Lifecycle-/Kollisionsmatrix, Minimalrechte, Heap und aktuelle exakte Head-CI bleiben offen. Status bleibt `partially validated`, `unreleased`.

## Ergänzende zentrale Qualifikation 2026-10-05

`Tests/CI/run-xlsx-types-lab.ps1 -QualificationScope DisplayCentral10Upgrade`
bestand auf Linux2019/latest CL150 zentral. Ein echter gepinnter Vorgänger1.0
wurde mit frischer Upgrade-Session auf1.2 aktualisiert: fünf→neun Slots und
zwei→vier CLR-Bindings, Release-/SAFE-Bindingzuordnung und Repeat bestanden.
Display.Contract/Safety liefen in der Installationsdatenbank; eine frische,
anders collierte Consumerdatenbank prüfte die dreiteiligen Clientmetadaten und
Raw→Type→Display-Komposition. Die Confirm0-Abweisung bewahrte den Snapshot;
Uninstall und die frische OwnDB-/Trustdisposition bestanden.

Der finale Lauf hatte einen äußeren eigenen Prozesswatchdog, Exit0 und
vollständige private Ausgabekanäle. Zwei eigene Datenbanken wurden entfernt,
drei exakte Trust-Vorzustände wiederhergestellt; ein unabhängiger Audit über eine
neue Verbindung bestätigte OwnDB-/OwnTrustabwesenheit. Keine Konfigurations- oder
Rechteänderungen. Diese Ergänzung schließt die genannten zentralen Upgrade- und
Consumerlücken für dieses Ziel. Vollständige Lifecycle-/Kollisionsmatrix,
weitere CL/Ziele, Minimalrechte und Heap bleiben offen. CI wird separat am
exakten PR-Head geprüft; Status bleibt `partially validated`, `unreleased`.
