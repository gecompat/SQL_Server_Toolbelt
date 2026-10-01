# Vorschlag: Regex-Erweiterungen nach R1b (`TC-2026-010`)

## Freigegebener relationaler R2b-Slice (2026-10-01)

Die ausdrückliche Benutzerbestätigung „ok, passt so“ nach Besprechung der
sechs Detailverträge aktiviert ausschließlich `TVF_RegexMatches` und
`TVF_RegexSplit` im Regexmodul; Freigabe in `.ai/BACKLOG.md`, nächster
Entwicklungswellenabschnitt. Keine Captures, Backreferences oder Wrapper-
Typfamilien. Die nachfolgenden älteren R2b-Nichtfreigabeformulierungen sind
historisch und werden nicht auf die heutigen zwei APIs übertragen.

Release1.2 liefert vier bigint/bigint/bigint/nvarchar(max)-Spalten über
Inline-T-SQL-Fassaden vor intern markierten SAFE-CLR-TVFs. Kanonischer
R2a-Kontext/Parser, NULL-Kurzschluss, MaxRows10000/Ceiling100000 und explizite
Standard-/Large-Profile. Vor Enumeratorrückgabe vollständig materialisiert;
keine verwertbaren Teilresultate bei Vertragsfehlern. Empty-Split verschiebt
ausschließlich den Suchcursor, niemals den Tokenanfang um das Suchinkrement.
Die exakten Signaturen, Prioritäten und Beispiele stehen in
`Modules/toolbelt.string.regex/Documentation/TVF_RegexMatches.md` und
`Modules/toolbelt.string.regex/Documentation/TVF_RegexSplit.md`.
Build-/Test-Evidence bleibt im Manifest und der Modul-Testmatrix; dieser
Eintrag ist weder Runtime-Nachweis noch vollständige Native-Paritätszusage.

## Status

Aktualisierung 2026-10-01: Der folgende R2a-Vertrag wurde ausdrücklich zur
Implementierung freigegeben; dauerhafte Freigabe in `.ai/BACKLOG.md`, R2a.
Die nachfolgenden Vorschlagsformulierungen dokumentieren die besprochene
Entscheidungsvorlage. Ihre Aussage einer ausstehenden Freigabe ist für R2a
durch diesen datierten Eintrag ersetzt; R2b bleibt separat und unfreigegeben.
Version 1.1.0 setzt R2a um; tatsächliche Validierung ergibt sich ausschließlich
aus Modulmanifest und reproduzierbaren Tests, nicht aus diesem Designdokument.

Technische Qualifikation: Gruppen maximal 64, Alternation maximal 1.024 und
übersetzte Pattern maximal 64.000 Codeeinheiten; Quantifiergrenze 1.000.
Restbudget wird durch Wiederverwendung eines Regexobjekts bis zur notwendigen
Verkleinerung seines Timeouts auf höchstens die Hälfte des Restbudgets umgesetzt.
Neukonstruktion parst das übersetzte Pattern erneut. Public max-Defaults
erfordern T-SQL-Fassaden vor intern markierten CLR-Kernen (SQL-Fehler 1096).
Diese technischen Grenzen verändern die bestehenden R1b-Verträge nicht.

Der bestehende R1b-Slice `toolbelt.string.regex` ist `validated` und
exportiert bewusst nur Is-Match, Instr und Count. Dieses Dokument bereitet
einen späteren Erweiterungsslice vor. Es autorisiert keine Änderung des
Moduls, keine Assembly und kein neues öffentliches SQL-Objekt.

## Nutzeranforderung vom 2026-10-01

Für die weitere R2a-Vertragsbesprechung sind `varchar` und `nvarchar`
einschließlich ihrer `max`-Varianten zu berücksichtigen. Gezielte Varianten
werden nur bei einem begründeten Semantik- oder Performance-Nutzen vorgesehen;
eine pauschale Vervielfachung aller Signaturen ist nicht verlangt.

Ein Patternumfang bis 8.000 Zeichen ist nach Nutzerangabe ausreichend.
8.000 Zeichen sind nicht mit dem bisherigen R1b-Limit von 8.000 UTF-16-Bytes
gleichzusetzen. Die konkrete Unicode-Zählweise und LOB-Ressourcenlimits für
Quelle, Ersatztext und Ergebnis sind noch zu entscheiden. Die bestehenden
R1b-Verträge werden durch diese Gesprächsanforderung nicht geändert.

Diese datierte Anforderung ist noch kein fertiger öffentlicher Vertrag und
autorisiert keine Implementierung der offenen Signaturen oder Limits.

## Ausgangslage

SQL Server 2025 bietet zusätzlich Replace, Substring, Matches und
Split-to-Table. Die aktuelle Microsoft-Dokumentation beschreibt dafür
unterschiedliche Ergebnisformen: Replace liefert Text, Substring einen Wert
oder SQL-`NULL`, und Matches liefert Zeilen einschließlich einer JSON-
Beschreibung der Captures. Diese Breite ist nicht Teil des vorhandenen
Toolbelt-Dialekts und SQL Server 2019/2022 besitzen keine native
Regex-Engine.

R1b übersetzt alle akzeptierten Gruppen in nicht-capturing Gruppen. Damit
schützt der Parser den engen Matching-Vertrag, kann aber keine Capture-Gruppen
oder Replacement-Backreferences nachträglich korrekt hinzufügen. Eine
Erweiterung darf die validierten R1b-Signaturen und ihre Dialektzusage nicht
stillschweigend verändern.

## Empfohlene Welle

Die nächste Welle sollte in zwei getrennten Verträgen erfolgen:

1. **R2a: skalare Transformationsfunktionen.** Ein neuer, klar benannter
   Slice für Replace und Substring im vorhandenen Modul. Die folgende
   Entscheidungsvorlage konkretisiert Typen, Größenprofile und Zeitbudgets;
   Pattern-Grunddialekt und culture-invariante Flags bleiben erhalten.
2. **R2b: relationale Ergebnisse.** Captures, Matches und Regex-Split als
   eigene TVF- oder ResultTable-Entscheidung. Dieser Slice benötigt stabile
   Ordinals, leere Treffer, Capture-Nullwerte und ein Resultset-Schema; er
   bleibt nach R2a separat.

R2a soll ohne Capture-Backreferences beginnen: der Replacement-Text ist
literal und die ganze Übereinstimmung wird ersetzt. Damit ist der erste
Transformationsvertrag klein und eindeutig. Capture-Gruppen und `\\1` bis
`\\9` gehören erst zu R2b oder einem ausdrücklich erweiterten R2a-Vertrag.

## Vorgeschlagener R2a-Vertrag

| Aspekt | Vorschlag |
|---|---|
| Pattern-Dialekt | Derselbe begrenzte R1b-Grunddialekt; keine Capture-Erweiterung in R2a. |
| Replace | Startposition ist 1-basiert; `occurrence = 0` ersetzt alle, positive Werte genau den n-ten Treffer. Kein Treffer liefert den unveränderten Eingabetext. |
| Substring | Startposition und occurrence sind 1-basiert; kein Treffer liefert SQL-`NULL`. Der erste Slice liefert den Gesamttreffer, keine Capture-Gruppe. |
| Empty matches | Nach einem leeren Treffer rückt die Suche um eine UTF-16-Codeeinheit vor; am Inputende ist genau ein terminaler leerer Treffer möglich. Replace fügt dort den literal Replacement-Text einmal ein; Substring liefert für diesen Treffer einen leeren String. |
| SQL `NULL` | Quelle oder Pattern `NULL`, bei Replace zusätzlich Replacement `NULL`, liefern unmittelbar SQL-`NULL`, bevor Flags, Profil oder Positionsparameter geprüft werden. Andernfalls ist Flags-`NULL` wie in R1b ein Fehler. |
| Grenzen | Standard- und Large-Profil gemäß folgender Tabelle; Pattern höchstens 8.000 UTF-16-Codeeinheiten. Keine implizite Wahl eines größeren Profils. |
| Ergebnis | Beide Funktionen liefern zunächst `nvarchar(max)`; Positionen zählen UTF-16-Codeeinheiten. Weitere Typvarianten benötigen einen belegten Nutzen und einen verlustfreien Konvertierungsvertrag. |

### Öffentliche Signaturen zur Freigabe

Diese Signaturen, Namen und Defaults sind **Vorschläge zur Freigabe**, weder
implementiert noch validiert. Die Tabelle beschreibt den Vertrag und ist
kein ausführbares SQL. Standard und Large sind Profile derselben API;
separate Funktionsgenerationen oder Large-Pattern-Funktionen sind nicht
vorgesehen.

| Vorgeschlagenes Objekt | Parameter in Reihenfolge | Ergebnis |
|---|---|---|
| `toolbelt_string.SVF_RegexReplace` | `@Input nvarchar(max)`, `@Pattern nvarchar(max)`, `@Replacement nvarchar(max)`, `@Start int = 1`, `@Occurrence int = 0`, `@Flags nvarchar(max) = N'c'`, `@Profile nvarchar(max) = N'standard'` | `nvarchar(max)` |
| `toolbelt_string.SVF_RegexSubstring` | `@Input nvarchar(max)`, `@Pattern nvarchar(max)`, `@Start int = 1`, `@Occurrence int = 1`, `@Flags nvarchar(max) = N'c'`, `@Profile nvarchar(max) = N'standard'` | `nvarchar(max)` |

`@Profile` akzeptiert ausschließlich die exakten ASCII-Werte `standard`
und `large`; `NULL`, andere Schreibweisen und zusätzliche Zeichen sind
ungültig. Die ungekürzten Konfigurationsparameter erlauben die Prüfung vor
einer stillen Kürzung am Parameterübergang und sind direkt CLR-kompatibel.
Flags werden auf höchstens vier Codeeinheiten geprüft und übernehmen die
R1b-Regeln für `c/i/m/s`, einschließlich
Duplikatverbot, Ausschluss von `c` mit `i` und kulturinvariantem Matching.
`@Start` muss positiv sein; Replace erlaubt `@Occurrence >= 0`, Substring
verlangt `@Occurrence >= 1`. Positionsparameter-`NULL` ist ein Fehler, sofern
nicht bereits der oben beschriebene Input-NULL-Kurzschluss greift.

Bei nicht-NULL-Eingaben werden zuerst Profil, Parameter, Flags, Größen und
Patterngültigkeit geprüft. Ein gültiger Start größer als `InputLength + 1`
liefert danach bei Replace die unveränderte Quelle und bei Substring SQL-
`NULL`; er verdeckt keine Vertragsfehler. `Start = InputLength + 1` erlaubt
einen passenden terminalen leeren Treffer. Beim leeren Input ist Start 1
dieselbe terminale Position. Es gibt keine überlappenden Treffer und keine
Interpretation von `$1`, `\\1` oder ähnlichen Folgen im Replacement-Text.

### LOB-Profile und Unicode-Zählweise zur Freigabe

| Ressource | `standard` | `large` |
|---|---|---|
| Dekodierte Quelle | 2 MiB UTF-16 / 1.048.576 Codeeinheiten | 16 MiB UTF-16 / 8.388.608 Codeeinheiten |
| Literal-Ersatztext | 2 MiB UTF-16 | 16 MiB UTF-16 |
| Fertiges Ergebnis | 2 MiB UTF-16 | 16 MiB UTF-16 |
| Pattern, beide Profile | 8.000 UTF-16-Codeeinheiten / 16.000 Bytes | gleiche Grenze |
| Kooperatives Gesamtbudget | 500 ms | 2.000 ms |

Alle Werte sind zu qualifizierende Vertragsvorschläge, keine gemessenen
Leistungszusagen. Large wird ausdrücklich gewählt. Die SQL-Signatur `max`
sagt keine Verarbeitung bis zur theoretischen SQL-LOB-Grenze von 2 GB zu.
Die Ressourcenlimits gelten nach Unicode-Decoding, nicht für die ursprüngliche
varchar-Bytezahl. Ersatztext, Quelle, Builder und fertiger Ergebnisstring
können gleichzeitig Speicher belegen; das Outputlimit begrenzt daher nicht
den gesamten Speicherverbrauch. Vor jedem Append wird die Ergebnisgröße mit
überlaufgeprüfter Arithmetik geprüft. Überschreitung erzeugt einen stabilen
Größenfehler, keine Truncation und kein Teilergebnis.

Die vorgeschlagene Patternzählweise entspricht den vorhandenen Positionen:
ein BMP-Zeichen zählt eine UTF-16-Codeeinheit, ein Supplementary-Zeichen mit
Surrogate Pair zwei. Grapheme oder visuell wahrgenommene Zeichen sind nicht
zugesagt. Die Alternative wären 8.000 Unicode-Skalarwerte mit zusätzlicher
Validierung und bis zu 16.000 UTF-16-Codeeinheiten / 32.000 Bytes; sie ist
eine gesonderte Entscheidung. Der R1b-Vertrag mit 8.000 **Bytes** bleibt
unverändert. Für das vorgeschlagene R2a-Patternlimit wird `nvarchar(max)`
verwendet; `nvarchar(8000)` wäre keine gültige bounded Typdeklaration.

### Suchbudget und Komplexität

Das kooperative Gesamtbudget beginnt vor Patternparser und Regex-Konstruktor
und umfasst Konstruktion, vollständige Trefferenumeration und Ergebnisbau.
Es wird vor und nach dem nicht unterbrechbaren Konstruktor sowie zwischen
Such-/Append-Schritten geprüft. Ein Konstruktor, der das Budget überschreitet,
führt nach seiner Rückkehr zum Timeoutfehler. Jeder Engine-Suchschritt erhält
höchstens 250 ms und, soweit technisch möglich, höchstens das verbleibende
Gesamtbudget. Die spätere Umsetzung muss nachweisen, wie die feste Timeout-
Bindung eines Regex-Objekts das Restbudget bei `NextMatch` respektiert.

Diese Grenzen garantieren keine harte Wall-Clock-Abbruchfrist während
Kompilation, Speicherallokation, GC oder SQL-Scheduling. Vorgeschlagene
zusätzliche Limits für Gruppenverschachtelung, Alternationsanzahl,
Quantifier-Komplexität und übersetzte Patternlänge sind vor der Runtime-
Implementierung konkret zu qualifizieren; ausreichende Werte sind bisher
nicht belegt. Parser und Timeout begründen weiterhin keine lineare Laufzeit.
Chunking begründet keine Regex-Parität: Chunkgrenzen verändern unter anderem
Anker, grenzüberschreitende Treffer und unbeschränkte Quantifier.

### Typfamilien, zentrale Verwendung und Performance

Der gemeinsame CLR-Kern verarbeitet Unicode. `nvarchar` wird direkt
übergeben; klassisches oder UTF-8-`varchar` wird am Caller ausdrücklich
unter seiner Quell-Collation nach `nvarchar(max)` konvertiert, bevor der
zentrale Cross-database-Aufruf erfolgt. Ein `varchar`-Parameter der zentralen
Datenbank kann bereits vor dem Funktionskörper in eine andere Codepage
konvertieren und Information verlieren. `varchar` ist zudem kein direkt
zu `SqlString` gemappter SQL-CLR-Parametertyp. Ein einfacher v-Wrapper ist
deshalb kein Nachweis sicherer zentraler Nutzung.

Zuerst wird Unicode-Output vorgeschlagen. Typbewahrende varchar-Wrapper
benötigen eine deklarierte Zielcodepage, nachgewiesene verlustfreie
Konvertierung oder einen stabilen Fehler sowie Semantik- oder Messnutzen.
Stille Ersatzzeichen und Abschneiden sind ausgeschlossen. Positionen zählen
auch bei ursprünglichen UTF-8-/Codepagequellen den dekodierten UTF-16-Text.

Bounded-/max-Varianten und Wrapper um denselben Kern schaffen keinen
belegten Speedup. Der vorhandene `.Value`-Pfad materialisiert den tatsächlichen
Text vollständig; eine `max`-Signatur bedeutet umgekehrt nicht, dass jeder
Wert groß ist. Messungen sollen Vorfilter, Konvertierungskosten, LOB-
Materialisierung, Ergebnisexpansion und konkurrierende Aufrufe berücksichtigen.
Varianten entstehen erst bei nachvollziehbarem Nutzen; Parallelität,
SARGability und Scalar-UDF-Inlining werden nicht zugesagt.

Die Engineering-Regel verlangt einen äquivalenten inline-TVF-Kern, soweit
die Fachlogik relational ausdrückbar ist. Für allgemeines Regex-Matching und
Transformation im CLR-Provider ist derzeit kein rein relationaler Ausdruck
belegt. Ein inline-TVF-Wrapper, der nur die CLR-SVF aufruft, erfüllt diese
Regel nicht und ist keine Performancealternative. Eine spätere Implementierung
muss die technische Ausnahme und geprüfte Alternativen ausdrücklich festhalten.

Die vorgeschlagene R2a-Semantik weicht bewusst an einzelnen Stellen von der
SQL-Server-2025-Oberfläche ab, etwa bei fehlenden Capture-Backreferences. Das
Modul darf deshalb keine vollständige Native-Parität behaupten. Wo der
Vertrag beabsichtigt mit 2025 verglichen wird, müssen die Abweichungen sichtbar
dokumentiert und getestet werden.

## R2b-Entscheidungen und Risiken

R2b kann nicht allein über eine skalare SQL-CLR-Funktion gelöst werden. Vor
dem ersten Objekt müssen Resultset-Form, Capture-Repräsentation und
Reihenfolge feststehen. Ein JSON-Blob pro Treffer, wie SQL Server 2025 ihn
für `REGEXP_MATCHES` nutzt, ist nicht automatisch ein guter Toolbeltvertrag:
er koppelt den Slice an JSON-Konstruktion und verdeckt SQL-`NULL`-Captures.
Ein normalisiertes Resultset mit Match- und Capture-Ordinalen bleibt eine
gleichwertige, aber andere öffentliche API.

Alle Erweiterungen behalten die wesentlichen R1b-Risiken: .NET-Backtracking
ist nicht linear garantiert, Regex-Aufrufe sind nicht SARGable und ein Timeout
ist keine Performancezusage. R2b fügt Materialisierung, Zeilenexplosion bei
leeren Treffern und größenabhängigen Speicherverbrauch hinzu. Tests müssen
deshalb mindestens Regressionen für R1b, Escape- und Unicodefälle, leere
Treffer, Start/Occurrence, Timeout, große Eingaben, Windows-/Linux-Deployment
und SQL-Server-2019-/2022-/2025-Lab-Ziele abdecken. Spezifische CUs sind nur
bei patchgebundenen Tests erforderlich.

## Entscheidungspunkt

Für eine spätere Implementierungsfreigabe wird der vorgeschlagene R2a-Schnitt
zur Bestätigung vorgelegt: Replace und Substring, keine Capture-
Backreferences, literal Replacement sowie die hier vorgeschlagenen
Signaturen, Standard-/Large-Profile, Unicode-Zählweise und kooperativen
Budgets. Die Freigabe steht weiterhin aus; dieses Dokument verändert weder
Runtime-Code noch Modulstatus. Die Komplexitätsgrenzen und die Restbudget-
Umsetzung müssen vor einer Runtime-Implementierung qualifiziert werden.
R2b bleibt bewusst eine getrennte Entscheidung.
Danach können Zweck, konkrete Signaturen, Alternativen, Risiken und Scope der
jeweiligen Funktionen verbindlich besprochen werden.

## Quellen

- [Microsoft: REGEXP_REPLACE](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-replace-transact-sql?view=sql-server-ver17)
- [Microsoft: REGEXP_SUBSTR](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-substr-transact-sql?view=sql-server-ver17)
- [Microsoft: REGEXP_MATCHES](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-matches-transact-sql?view=sql-server-ver17)
- [Microsoft: REGEXP_SPLIT_TO_TABLE](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-split-to-table-transact-sql?view=sql-server-ver17)
- [Microsoft: CLR-Parametertypen](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-types-net-framework/mapping-clr-parameter-data?view=sql-server-ver17)
- [Microsoft: char und varchar](https://learn.microsoft.com/en-us/sql/t-sql/data-types/char-and-varchar-transact-sql?view=sql-server-ver17)
- [bestehendes Regex-Moduldesign](./REGEX_MODULE_DESIGN.md)
