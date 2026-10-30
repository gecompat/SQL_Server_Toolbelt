# Technische Lösungswege

Diese Erläuterungen richten sich an Entwickler, die die besonderen
Entscheidungen hinter einer API nachvollziehen möchten. Beginne mit der
Objektseite im [API-Katalog](API_CATALOG.md), wenn du zunächst den Aufruf
suchst. Hier geht es um Algorithmen, Zustände, Repräsentationen und Grenzen,
die sich aus einer Signatur allein nicht erschließen. Die verlinkten
Implementierungen sind die Grundlage der Erklärung; fachliche Details und
Testgrenzen stehen weiterhin auf den Objekt- und Modulseiten.

| Fragestellung | Lösungsweg |
|---|---|
| Zahlen ohne Schleife erzeugen; Grenzen von bigint einhalten | [Zahlenreihen](#zahlenreihen), [Zahlensysteme](#zahlensysteme), [Safe-Cast](#safe-cast) |
| Kalendergrenzen und Zeiträume korrekt behandeln | [Kalenderarithmetik](#kalenderarithmetik) |
| Bytes, Text und Versionsreihenfolgen unterscheiden | [URI](#uri), [Base64](#base64), [SemVer](#semver) |
| Trennzeichen innerhalb von Quotes erhalten | [Tokenisierung](#tokenisierung), [CSV](#csv) |
| Ähnlichkeit und Lautgleichheit berechnen | [Textdistanz](#textdistanz), [Phonetik](#phonetik) |
| JSON prüfen, erzeugen und traversieren | [Pointer](#json-pointer), [Pfade](#json-pfade), [Konstruktion](#json-konstruktion), [Schema](#json-schema) |
| Reguläre Ausdrücke begrenzen | [Regex](#regex) |
| Archive, Tabellenzellen und Dateien lesen | [ZIP](#zip), [XLSX](#xlsx), [Dateisystem](#dateisystem) |
| Dateien mit dem SQL-Bulkprovider laden | [Dateiinhalte](#dateiinhalte) |
| SQL und SSIS in strukturierte Artefakte überführen | [SQL-Parser](#sql-parser), [SSIS](#ssis), [Tabellenklon](#tabellenklon) |
| Nebenläufige Arbeit und Transaktionsgrenzen verstehen | [Queue](#queue), [Worker](#worker), [Zweite Session](#zweite-session) |
| Ergebnisformen und Identifier sicher zusammensetzen | [ResultTable](#resulttable), [Identifier](#identifier) |
| Reproduzierbare Zuordnungen ohne Moduloverzerrung erzeugen | [Deterministische Zuordnung](#deterministische-zuordnung) |

## Zahlenreihen

`TVF_GenerateSeriesBigInt` berechnet zuerst die Zahl benötigter Werte und
erzeugt dann nullbasierte Ordinals mit `ROW_NUMBER`. Die CTEs `E1` bis `E64`
vergrößern einen konstanten Zeilenvorrat durch Kreuzprodukte; `TOP` begrenzt
den benötigten Ausschnitt. Das sind keine rekursiven Iterationen pro Zahl.
Diese Form kann als inline TVF in den aufrufenden Abfrageplan eingehen.
Sie verspricht weder eine bestimmte Ausführungsstrategie noch Reihenfolge:
Ergebnissortierung verlangt weiterhin ein äußeres `ORDER BY`.

Die weniger offensichtliche Schwierigkeit liegt in der Anzahlberechnung.
`Stop-Start` kann außerhalb von bigint liegen, obwohl beide Operanden gültig
sind. Deshalb werden Differenz und Schrittbetrag in `decimal(38,0)`
berechnet. Der Statuskern prüft außerdem die zulässige Zeilenzahl **vor**
der Expansion. Andernfalls würde erst nach der teuren Erzeugung auffallen,
dass der Aufruf zu groß war. Die mathematische Wertoberfläche und die
begrenzte Statusoberfläche haben deshalb unterschiedliche Grenzen.

Code: [Reihenerzeugung und Statuskern](../../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql).

## Zahlensysteme

Die Integer-Base-Funktionen verwenden rekursive CTEs mit einem expliziten
Zwischenzustand. Beim Encodieren enthält dieser den noch nicht verarbeiteten
Betrag und den bisherigen Text. Jeder Schritt bestimmt die nächste Ziffer
über den Rest und setzt den Quotienten als neuen Betrag ein. Die Ziffer wird
vorangestellt, weil diese Zerlegung am niederwertigen Ende beginnt.

Beim Decodieren trägt der Zustand den bisher gelesenen Zahlenwert. Vor
`Accumulated * Base + Digit` wird gegen
`floor((MagnitudeLimit-Digit)/Base)` geprüft. Eine Prüfung erst nach der
Multiplikation könnte bereits einen Überlauf ausgelöst haben. Für negative
bigint-Werte ist der erlaubte Betrag um eins größer als für positive;
`decimal(38,0)` stellt auch den Betrag des kleinsten bigint dar.
Alphabetprüfung und binärer Zeichenvergleich verhindern mehrdeutige Ziffern.

Code: [Encoding-CTE](../../Modules/toolbelt.conversion.integer-base/Source/TVF_IntegerToBase.sql)
und [Decoding-CTE](../../Modules/toolbelt.conversion.integer-base/Source/TVF_TryBaseToInteger.sql).

## Safe-Cast

Ein erfolgreiches `TRY_CONVERT` reicht für verlustfreie Konvertierung nicht
aus: SQL Server kann eine zu lange Nachkommastellenfolge runden oder bei
anderen Typen eine großzügigere Eingabesyntax annehmen als fachlich gewünscht.
Die TVFs prüfen daher erst die begrenzte Zeichenfolge, dann den Wertebereich
und erst danach den Zielwert.

Bei Decimal ermittelt der Code getrennt signifikante Ganzzahlziffern,
die ersten 18 Nachkommastellen und weitere von null verschiedene Stellen.
So unterscheidet er einen echten Bereichsfehler von einem Skalenverlust.
Die sichere Ersatzdarstellung vor `TRY_CONVERT` vermeidet, dass ungültige
Zwischenwerte trotz späterem Filter ausgewertet werden. Die SQL-Abfrage
setzt keine garantierte Auswertungsreihenfolge ihrer CTEs voraus.

Code: [Decimal-Prüfkette](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDecimal.sql).
Die übrigen Safe-Cast-Objektseiten beschreiben ihre jeweilige Lexik.

## Kalenderarithmetik

`DATEDIFF` zählt überschrittene Periodengrenzen, nicht vollständig verstrichene
Kalenderjahre oder Monate. `TVF_CalendarDifference` nutzt den Wert deshalb
zunächst als Kandidaten und addiert ihn zum früheren Datum zurück. Liegt
dieser Anker hinter dem späteren Datum, wird die Anzahl reduziert. Erst nach
den vollständigen Jahren werden Monate und Resttage bestimmt. Die
Monatsendklammerung von `DATEADD` ist dabei Teil der Anniversary-Regel.

Buckets benötigen zusätzlich eine mathematische Abrundung vor dem Origin:
Ein Abstand von -1 bei Breite 7 gehört in Bucket -1, während SQLs ganzzahlige
Division 0 ergibt. Der Kern korrigiert einen negativen Quotienten mit Rest.
Große Stunden-, Minuten- und Sekundenoffsets werden in Tage und Rest
aufgeteilt, damit die DATEADD-Schritte innerhalb ihrer unterstützten
Argumentbereiche bleiben. Der MSTVF-Kern begrenzt hier bewusst die
Optimizer-Expansion; er ist keine versehentlich verpasste inline TVF.

Date Spines erzeugen Periodenanfänge für einen halboffenen Bereich. Der Tag
vor der exklusiven Endgrenze bestimmt die letzte geschnittene Periode.
Ein sicherer Ersatzoperand verhindert bei ungültiger minimaler Endgrenze
einen date-Unterlauf, bevor der ungültige Bereich herausgefiltert wird.

Code: [Kalenderdifferenz](../../Modules/toolbelt.datetime.calendar-difference/Source/TVF_CalendarDifference.sql),
[Bucket-Kern](../../Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketCore.sql),
[Spine-Kern](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineCore.sql).
Grundlagen: [DATEDIFF](https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql?view=sql-server-ver17)
und [DATEADD](https://learn.microsoft.com/en-us/sql/t-sql/functions/dateadd-transact-sql?view=sql-server-ver17).

## URI

Percent-Encoding arbeitet auf UTF-8-Bytes, während ein `nvarchar`-Wert
UTF-16-Codeeinheiten enthält. Der Encoder konvertiert deshalb zunächst
über eine UTF-8-Collation in Bytes. Eine Zahlenreihe adressiert diese Bytes;
ASCII-unreserved Bytes bleiben erhalten, die übrigen werden `%HH`.
Ein einziges `ä` wird damit zu zwei Byte-Escapes `%C3%A4`, nicht zu einem
Escape seines UTF-16-Werts. `STRING_AGG ... WITHIN GROUP` setzt die Teile
in Byte-Reihenfolge zusammen.

Der Decoder prüft zuerst die Prozent-Triplets und dann die zulässigen
UTF-8-Bytefolgen einschließlich ihrer Fortsetzungsbytes. Eine bloße
Zeichenkonvertierung wäre als Syntaxprüfung zu nachgiebig. Die Statuskerne
begrenzen die Eingabe vor Series-Expansion bzw. Konvertierung; ihre
Wertfassaden reichen den Wert weiter. Eine Decodierrunde verarbeitet
`%252F` zu `%2F`; erneutes Decodieren wäre eine zusätzliche Operation mit
anderer Bedeutung für Pfadtrennzeichen.

Code: [Encoder](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql)
und [Decoder](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql).

## Base64

Die portable Implementierung verwendet SQL Servers XML/XQuery-Konvertierung
`xs:base64Binary`, nicht eine selbst geschriebene Bit-Schleife oder eine
SQL-Server-2025-spezifische Funktion. Das leere XML stellt hier den
XQuery-Auswertungskontext bereit; die Nutzdaten kommen über `sql:variable`.
Für Base64URL werden Alphabetzeichen übersetzt und beim Encodieren die
abschließenden Paddingzeichen entfernt.

Vor dem XML-Decoder prüft der Statuskern Rohtextgrenze, normalisiertes
Alphabet, Padding und erwartete Ergebnislänge. Die Rohgrenze liegt vor dem
Entfernen von Whitespace: Sonst könnte ein großer Input trotz sehr kleinem
Nutzwert bereits unbegrenzte Normalisierungsarbeit auslösen. Dieses Verfahren
materialisiert die Werte synchron; der XML-Ausdruck ist kein Streamingdecoder.

Code: [Encode](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql)
und [Decode](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql).

## SemVer

Versionszahlen bleiben Dezimalstrings. Nach Ausschluss führender Nullen
entspricht der Vergleich erst nach Länge, dann nach Ziffernfolge dem
numerischen Vergleich; eine bigint-Konvertierung ist nicht erforderlich.
Die Parser-Schleifen prüfen einzelne durch Punkte getrennte Identifier,
weil Core, Pre-release und Build-Metadaten unterschiedliche Regeln haben.

Der Sortierschlüssel übersetzt diese Regeln in binär sortierbare Fragmente:
Typmarker unterscheiden numerische und nicht numerische Identifier;
numerische Teile erhalten einen Längenpräfix vor ihren Ziffernbytes.
Trenner markieren die Fragmentenden. Für die finale Version steht ein
anderer Marker als für Pre-release, sodass sie nach derselben Core-Version
mit Pre-release liegt. Build-Metadaten werden bewusst nicht aufgenommen.
Damit folgt die Sortierung der SemVer-Präzedenz statt einer zufälligen
Datenbank-Collation. Der Schlüssel ist keine allgemeine Serialisierung für
beliebige Versionsformate.

Code: [Parser](../../Modules/toolbelt.validation.semantic-version/Source/TVF_ParseSemanticVersion.sql)
und [Schlüsselaufbau](../../Modules/toolbelt.validation.semantic-version/Source/TVF_SemanticVersionSortKey.sql).
Fachliche Grundlage: [SemVer 2.0.0, Präzedenzregeln](https://semver.org/).

## Tokenisierung

Der erweiterte Splitter läuft mit Position, Tokenbeginn und Quote-Zustand
vorwärts durch den Text. Ein Escape schützt die folgende Codeeinheit;
innerhalb eines Quotes werden Separatoren nicht ausgewertet. Passen mehrere
Separatoren an derselben Position, gewinnt der längste. Das lässt sich mit
einer pauschalen REPLACE-Kette nicht gleichwertig abbilden, weil eine
Ersetzung neue Treffer oder einen falschen Quote-Kontext erzeugen könnte.

Die Schleife speichert zunächst nur Start und Länge der Tokens. Erst wenn
auch das Ende ohne offenen Quote oder hängendes Escape erreicht ist,
werden die Teilstrings veröffentlicht. Deshalb kann ein Syntaxfehler am
Textende kein erfolgreiches Tokenpräfix hinterlassen. Die Tokenisierung
erhält den Originaltext; das getrennte Unquote-Objekt behandelt das
Entfernen der Syntax. Das ist wichtig für Aufrufer, die Originalpositionen
oder eine nachgelagerte, andere Wertinterpretation benötigen.

Code: [Zustandsautomat und Span-Puffer](../../Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql)
und [Unquote](../../Modules/toolbelt.string.split-advanced/Source/TVF_UnquoteToken.sql).

## CSV

Der CLR-Scanner unterscheidet unter anderem quoted und after-quote.
Ein Separator oder Zeilenumbruch kann innerhalb eines quoted Feldes
Wertinhalt sein; nach einer schließenden Quote gelten andere zulässige
Folgezeichen. Daher reicht weder das Aufteilen an Zeilenumbrüchen noch das
anschließende Splitten jeder Zeile an Kommas.

Derselbe Scanner validiert zunächst die gesamte begrenzte Eingabe ohne
Feldwerte zu allokieren. Danach liefert er Feldbeschreibungen mit Position,
Rohlänge und decodierter Länge. Dieser zweite Durchlauf ist beabsichtigt:
Ein später CSV-Fehler soll nicht erst nach bereits ausgegebenen gültigen
Zellen auffallen. Ein konfiguriertes NULL-Token wird gesondert geprüft;
SQL-NULL, leeres Feld und ein quoted Text sind dadurch nicht automatisch
derselbe Wert. Die CLR-Schicht ermöglicht den expliziten Scannerzustand;
sie macht CSV nicht zu einem beliebigen Tabellenimport.

Code: [CsvKernel.Scan](../../Modules/toolbelt.file.csv-memory/Clr/CsvKernel.cs)
und [Entry Points](../../Modules/toolbelt.file.csv-memory/Clr/CsvEntryPoints.cs).

## Textdistanz

Levenshtein und OSA berechnen dynamisch die Kosten von Präfixpaaren. Die
innere Schleife benötigt nicht die gesamte Matrix: Levenshtein hält die
vorherige und aktuelle Zeile, OSA zusätzlich eine ältere Zeile für die
benachbarte Transposition. Nach jeder äußeren Iteration werden die Arrays
weitergereicht und wiederverwendet. Das begrenzt den Matrixspeicher, beseitigt
aber nicht den ohne Distanzschranke quadratischen Rechenaufwand.

Mit einer Maximaldistanz berechnet der Kern nur das Band um die Diagonale.
Außerhalb dieses Bands kann ein Pfad die erlaubten Kosten nicht mehr
einhalten. Die Bandgrenzen werden mit einem unerreichbaren Wert besetzt,
damit recycelte Arrayinhalte keinen falschen günstigeren Pfad erzeugen.
Ein gemeinsamer strikter UTF-16-Decoder liefert Unicode-Skalarwerte:
Surrogatpaare sind eine Einheit, kombinierende Zeichen bleiben getrennt.
Es erfolgt keine Unicode-Normalisierung.

Jaro verwendet dagegen ein Suchfenster und markiert bereits zugeordnete
Zeichen, damit keines doppelt matcht. Bei Mehrdeutigkeit schafft die
kanonische Orientierung nach Länge und Scalarlexikographie einen
reproduzierbaren Vergleich. Der Winkler-Bonus wird an der 0,7-Schwelle
rational geprüft, bevor ein Floatwert für das Ergebnis verwendet wird.
Der Batchwrapper prüft zusätzlich gemeinsame Arbeitsbudgets und publiziert
bei globalen Fehlern keine Teilresultate.

Code: [Distanzmatrix](../../Modules/toolbelt.string.edit-distance/Clr/DistanceKernel.cs),
[Jaro](../../Modules/toolbelt.string.edit-distance/Clr/JaroKernel.cs),
[Unicode-Decoder](../../Modules/toolbelt.string.edit-distance/Clr/UnicodeScalar.cs),
[Batchwrapper](../../Modules/toolbelt.string.text-pairs/Source/USP_CompareTextPairs.sql).

## Phonetik

Die Kölner Phonetik ist ein kontextabhängiger Scanner. Derselbe Buchstabe
erhält je nach Nachbarbuchstaben einen anderen Code; außerdem werden
wiederholte Codes und Vokalcodes regelabhängig unterdrückt. Deshalb werden
`lastChar` und `lastCode` getrennt geführt. Der letzte gelesene Buchstabe
und der letzte erzeugte Code beantworten unterschiedliche Fragen.

Double Metaphone kann für eine Eingabe einen primären und einen alternativen
Code erzeugen. Sein Regelbaum untersucht Buchstabengruppen und überspringt
bereits konsumierte Positionen. Die Vorbereitung ist ebenfalls Teil des
Vertrags: Der begrenzte Zeichenvorrat und die expliziten Transformationen
ersetzen keine allgemeine kulturabhängige Normalisierung. Beide Kerne sind
markierte C#-Ports aus Apache Commons Codec; Herkunft und Anpassungen bleiben
in den Quellen erhalten. Gleiche Codes sind Kandidaten für Lautähnlichkeit,
kein Nachweis identischer Namen oder Identitäten.

Code: [Kölner Scanner](../../Modules/toolbelt.string.phonetic/Clr/CologneKernel.cs),
[Double Metaphone](../../Modules/toolbelt.string.phonetic/Clr/DoubleMetaphoneKernel.cs),
[Eingabevorbereitung](../../Modules/toolbelt.string.phonetic/Clr/PhoneticInput.cs).

## JSON-Pointer

Der native T-SQL-Kern benutzt `OPENJSON` für die eigentliche Navigation,
prüft aber vorher Pointer-Syntax, Unicode und eine feste strukturelle
Schutzgrenze. Insbesondere ist `ISJSON` nicht bei jeder beliebigen
Verschachtelung ein folgenloser boolescher Vorabtest. Der rohe Tiefenscan
kennt Quote- und Escape-Zustände, damit eine Klammer innerhalb eines Strings
keine zusätzliche Ebene zählt. Er prüft noch nicht die vollständige
Grammatik. Die späteren nativen Parser bekommen kontrollierte Operanden.

Die Schleifen haben unterschiedliche Aufgaben: Der Pointerscan validiert
auch noch nicht besuchte Suffixe; der Dokumentscan schützt die Parsergrenze;
die Traversalschleife löst anschließend ein Segment nach dem anderen auf.
Chunkweises Lesen vermeidet, für jedes Zeichen erneut einen großen LOB
abzusuchen. Exakte Keys werden von Arrayindizes und deren Lexik unterschieden.
`MISSING` und ein gefundenes JSON-null bleiben getrennte Ergebnisse.
Diese sequenziellen Zustände und sicheren Parseroperanden begründen die
MSTVF; ein inline Wrapper würde diese Arbeit nicht wegoptimieren.

Code: [Scans und Traversal](../../Modules/toolbelt.json.pointer/Source/TVF_ResolveJsonPointer.sql).
Grundlage: [RFC 6901](https://www.rfc-editor.org/rfc/rfc6901.html).

## JSON-Pfade

Ein Pointer folgt genau einem Weg; Wildcards im unterstützten JSON-Pfad
können mehrere Kandidaten erzeugen. Der Pfadkern hält deshalb eine
`Frontier` und eine `NextFrontier`: Pro Pfadsegment werden alle aktuellen
Kandidaten expandiert und gegen dieses Segment gefiltert. Erst danach
ersetzt die neue Frontier die alte. Eine leere Frontier bedeutet, dass
kein erreichbarer Kandidat mehr existiert.

Die Begrenzung muss diesen Zwischenzustand betreffen, nicht nur die eine
abschließende Exists-Zeile. Der Code nimmt höchstens 10001 Kandidaten auf,
um eine Überschreitung der 10000er-Grenze erkennen zu können. Vor jedem
Parserdurchlauf werden die betroffenen Fragmentbytes gegen das kumulative
Arbeitsbudget gebucht. Ein Limit ist ein eigener Status; es darf nicht
als vermeintlich erfolgreich geprüftes `MISSING` erscheinen.

Code: [Frontier-Expansion und Arbeitsbudget](../../Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql).

## JSON-Konstruktion

Die Konstruktoren unterscheiden einen Textwert von einem bereits typisierten
JSON-Literal. `string` muss Zeichen maskieren und Quotes erhalten; eine
Zahl oder ein JSON-Fragment muss stattdessen seine eigene Grammatik bestehen.
Der gemeinsame JSON-Kern führt dafür einen Syntaxautomaten mit Zuständen
und Budget. Er ermittelt auch die maskierte Ausgabelänge, bevor er das
Fragment tatsächlich allokiert. Das schützt vor einem kleinen Eingabetext,
der durch Escaping einen deutlich größeren Ausgabewert ergibt.

Die CLR-Aggregate erhalten eine explizite Ordinal-Spalte, weil SQL keine
bestimmte Reihenfolge der Accumulate-Aufrufe zusagt. Auch Merge und
Serialisierung gehören zum Aggregatzustand. Die Ausgabe richtet sich nach
der fachlichen Ordinalfolge, nicht nach dem zufälligen Eintreffen der Zeilen.
Doppelte Schlüssel oder Ordinals dürfen daher nicht abhängig von der
Ausführungsreihenfolge still überschrieben werden. Die USPs und Aggregate
haben ihre jeweiligen Verträge; gemeinsame Parserlogik bedeutet nicht
automatisch identische Oberflächen- oder Tiefengrenzen.

Code: [Syntaxautomat](../../Modules/toolbelt.json.core/Clr/JsonSyntaxScanner.cs),
[Wertbewertung](../../Modules/toolbelt.json.core/Clr/JsonCanonicalCore.cs),
[Aggregate](../../Modules/toolbelt.json.constructors/Clr/JsonAggregates.cs),
[Aggregatzustand](../../Modules/toolbelt.json.constructors/Clr/OwnedAggregateBuilder.cs).

## JSON-Schema

Die Implementierung baut auf dem gemeinsamen JSON-Scanner einen Tokenindex
und einen geprüften Schemabaum. Der Validator arbeitet eine explizite
Aufgabenliste ab: Ein Eintrag bindet eine Dokumentposition an eine
Schemaposition. Unterelemente erzeugen weitere Aufgaben. Diese Form macht
den verbleibenden Zustand und die Budgetbelastung kontrollierbar, statt
eine unbeschränkte rekursive Folge von Methodenaufrufen zu verwenden.

Ein besonders wichtiger Detailpfad sind JSON-Zahlen. Eine Konvertierung
aller Literale nach `double` würde unterschiedliche große oder sehr genaue
Werte gleichsetzen. `ExactJsonNumber` zerlegt deshalb Vorzeichen,
signifikante Dezimalziffern und einen separat dargestellten Zehnerexponenten.
Führende und nachgestellte Nullen werden mit entsprechender
Exponentenkorrektur behandelt. Zahlenvergleiche folgen dieser Darstellung,
nicht der Rundung eines SQL- oder CLR-Floattyps. Das bleibt ein begrenzter
Validator für den dokumentierten Schemaumfang, kein Versprechen beliebiger
JSON-Schema-Dialekte oder externer Referenzauflösung.

Code: [Aufgabenverarbeitung](../../Modules/toolbelt.json.schema/Clr/SchemaValidator.cs),
[Zahlendarstellung](../../Modules/toolbelt.json.schema/Clr/ExactJsonNumber.cs),
[Exponentenarithmetik](../../Modules/toolbelt.json.schema/Clr/SignedDecimalDigits.cs).

## Regex

Der Provider reicht ein Pattern nicht unverändert an .NET durch. Ein eigener
Parser akzeptiert den begrenzten Toolbelt-Dialekt und übersetzt zulässige
Elemente für die .NET-Engine. Dadurch hängen beispielsweise Zeichengruppen
und zugelassene Konstrukte nicht still von der Datenbank-Collation oder
jedem zusätzlichen .NET-Sprachmerkmal ab.

Ein Timeout pro Suche begrenzt noch nicht eine ganze Replace- oder
Count-Operation: Sehr viele kurze Treffer können zusammen teuer sein.
Deshalb prüfen Traversal und Transformation zusätzlich ein gemeinsames
verbleibendes Zeit- und Arbeitsbudget. Weil der .NET-Timeout an die
Regexinstanz gebunden ist, kann bei sinkendem Restbudget eine neue Instanz
mit kleinerem Timeout nötig sein. Die Schleife dafür ist eine
Budgetanpassung, kein fachlich wiederholtes Matching desselben Ergebnisses.

Nach leeren Treffern muss der Cursor kontrolliert weiterlaufen, sonst
könnte eine Enumeration dieselbe Position endlos erneut liefern. Capture-
und Replacementverarbeitung benötigen außerdem eigene begrenzte Zustände.
Diese Schutzmaßnahmen machen die Backtracking-Engine nicht linear und
unterbrechbare Suchschritte nicht zu einer harten Gesamtzeitgarantie.

Code: [Dialektparser und Traversal](../../Modules/toolbelt.string.regex/Clr/RegexProvider.cs),
[TransformationContext](../../Modules/toolbelt.string.regex/Clr/RegexTransformations.cs).
Hintergrund: [.NET-Backtracking](https://learn.microsoft.com/en-us/dotnet/standard/base-types/backtracking-in-regular-expressions).

## ZIP

Der Reader bestimmt das Central Directory aus dem Archivabschluss und
gleicht seine Einträge mit den lokalen Dateiköpfen ab. Nur die Namenliste
zu lesen würde widersprüchliche Methoden, Größen oder Offsets nicht
erkennen. Vor Zugriffen prüft der Code Bereichsgrenzen; beim Extrahieren
kommen tatsächliche Ausgabelänge, Kompressionsverhältnis und CRC hinzu.
Ein in den Metadaten behaupteter kleiner Inhalt darf die Laufzeitgrenzen
der Dekompression nicht ersetzen.

Die Leseschleife benötigt deshalb neben dem Dekompressor eigene Zähler
und Checkpoints. CRC schützt vor unbeabsichtigter Inhaltsabweichung, ist
aber kein Authentizitätsnachweis. Der Writer erzeugt umgekehrt lokale
Einträge und ein dazu passendes Central Directory aus einer begrenzten
Entrydarstellung; Größen und CRC gehören zu dieser Buchführung.

Die File-Fassaden kombinieren diese Speicheroperationen mit dem
Dateisystemmodul. Erfolgreiche Dateipublikation und die anschließende
SQL-Ausgabe werden dadurch nicht zu einer gemeinsamen atomaren Transaktion.

Code: [ZIP-Reader](../../Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs),
[gebundene Archivsession](../../Modules/toolbelt.archive.zip-memory/Clr/ArchiveSession.cs),
[ZIP-Writer](../../Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs).

## XLSX

Eine XLSX-Datei ist ein ZIP-Paket miteinander verknüpfter XML-Parts.
Worksheet und Shared Strings werden über Content Types und Relationships
gefunden. Ein fester Dateiname wie `sheet1.xml` wäre keine verlässliche
Zuordnung zur gewünschten Tabelle. Der Reader verwendet den begrenzten
ZIP-Reader, kontrolliert die Beziehungen und liest die XML-Struktur mit
`XmlReader`; DTD-Verarbeitung und externe XML-Auflösung sind ausgeschaltet.

Ein Zellwert kann ein Index in die Shared-String-Tabelle sein, ein numerischer
Rohtext oder ein anderer gespeicherter Zelltyp. Deshalb sind Part-Lesen,
Typinterpretation und Anzeigeformatierung getrennte Schritte. Ein numerischer
Wert allein verrät nicht, ob er fachlich ein Datum sein soll; Format und
Datumsbasis gehören dazu. Ebenso berechnet das Lesen eines gespeicherten
Formelergebnisses nicht die Formel neu. Die Formatierungsfunktion ist ein
endlicher Renderer für den dokumentierten Umfang, keine Excel-Engine.

Code: [Workbook und Zelllesen](../../Modules/toolbelt.file.xlsx-memory/Clr/Workbook.cs),
[Typinterpretation](../../Modules/toolbelt.file.xlsx-memory/Clr/XlsxCellType.cs),
[Anzeigeformatierung](../../Modules/toolbelt.file.xlsx-memory/Clr/XlsxCellDisplay.cs).
Formatgrundlage: [SpreadsheetML-Struktur](https://learn.microsoft.com/en-us/office/open-xml/spreadsheet/structure-of-a-spreadsheetml-document).

## Dateisystem

Ein geprüfter Pfadstring ist noch keine dauerhafte Bindung an dieselbe
Datei. Zwischen Prüfung und Öffnen können Dateisystemobjekte ausgetauscht
oder über Reparse Points umgeleitet werden. Der Windows-Provider bindet
Eltern und Datei deshalb über native Handles und prüft Eigenschaften am
geöffneten Objekt. Die gewählte Ausführungsidentität bleibt Teil des
Zugriffsvertrags; ein Fehler löst keinen stillen Identitätswechsel aus.

Schreiben erfolgt zunächst in eine eigene Stagingdatei. Nach vollständigem
Schreiben und `Flush(true)` veröffentlicht `NativePublish` das gebundene
Objekt. Das Handle bleibt bis dahin erhalten, damit die Stagingdatei nicht
zwischenzeitlich über ihren Namen ausgetauscht wird. Im Fehlerpfad wird
die eigene unpublizierte Datei über ihr Handle bereinigt. Die Reihenfolge
erklärt die zusätzliche Datei und die Cleanup-Schritte: Sie dienen der
kontrollierten Veröffentlichung, nicht einer unnötigen zweiten Nutzdatenkopie.
Eine SQL-Transaktion kann den externen Dateivorgang dennoch nicht zurückrollen.

Code: [WriteAtomicallyScoped, NativeOpen und NativePublish](../../Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs).

## Dateiinhalte

File Content verwendet den SQL-Provider `OPENROWSET(BULK ...)`. Der Dateipfad
muss dabei als SQL-Literal in die Anweisung eingehen; er ist kein normaler
gebundener Abfrageparameter. Deshalb prüft die Fassade zunächst Pfadform,
Traversierung und Root-Allowlist und baut erst danach den begrenzten
Bulkaufruf mit einem quotierten Literal auf.

Die Rootprüfung muss eine Verzeichnisgrenze berücksichtigen: Ein erlaubtes
`/safe` darf nicht auch `/safe-old` erlauben. Slash-Normalisierung und
literaler Rootvergleich gehören deshalb zum gemeinsamen Prädikat, nicht zu
einem vom Caller gelieferten LIKE-Muster. Dateizugriff und Decodierung erfolgen
anschließend im Bulkprovider. Die native Handlebindung des Windows-
Dateisystemmoduls ist ein eigener Providerweg; aus der lexikalischen
Allowlistprüfung folgt keine gleichwertige Bindung an ein geöffnetes Objekt.

Code: [Bulk-Fassade](../../Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql)
und [gemeinsames Rootprädikat](../../Modules/toolbelt.file.content/Source/FileContentRootPredicate.sql).

## SQL-Parser

ScriptDom liefert Token und einen Syntaxbaum mit Positionen im Originaltext.
Diese Grundlage unterscheidet etwa einen Objektnamen von gleich aussehendem
Text in einem Kommentar oder Stringliteral. Der Provider wählt den zur
angeforderten T-SQL-Version passenden Parser und stellt unterschiedliche
relationale Sichten auf Tokens, Knoten, Eigenschaften und Fehler bereit.

Für Änderungen werden Position und Länge der betroffenen Tokenbereiche
verwendet, statt den gesamten Text durch eine Such-/Ersetzungskette laufen
zu lassen. Zulässige, nicht überlappende Ersetzungen können so an den
Originalpositionen geprüft werden. Der Syntaxbaum ist dabei kein Binder:
Er beweist nicht, welches reale Objekt eine Referenz bei der späteren
Ausführung auflöst. Ebenso werden dynamisch erst zur Laufzeit gebildete
SQL-Texte nicht durch statisches Parsen vollständig erklärt.

Code: [ScriptDom-Provider](../../Modules/toolbelt.tsql.script-parser/Clr/ScriptParserProvider.cs)
und [gebundene Tokenersetzungen](../../Modules/toolbelt.tsql.script-parser/Source/USP_ApplyTokenReplacements.sql).
Grundlage: [TSqlParser und GetTokenStream](https://learn.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.transactsql.scriptdom.tsqlparser).

## SSIS

Die Debuganalyse liest das DTSX-Paket als Komponenten- und Verbindungsmodell
und übersetzt unterstützte Datenflussstufen in SQL-Artefakte. Entscheidend
sind Verbindungen, Spaltenherkunft und Projektionen: Gleiche Anzeigenamen
reichen nicht aus, um eine Spalte durch mehrere Transformationen eindeutig
zu verfolgen. Bindings ergänzen ausdrücklich die Werte und Datenbankbezüge,
die das Paket allein nicht als sicher verwendbaren Debugkontext festlegt.

Jede ausgegebene Debugstufe enthält die benötigten Vorgänger. So lässt sich
eine Zwischenstufe ausführen, ohne zuerst zufällig eine andere Stufe
ausgeführt haben zu müssen. Lookups benötigen besondere Behandlung: Eine
beliebige Auswahl unter mehreren passenden Zeilen könnte bei jeder
Zwischenabfrage anders ausfallen. Der erzeugte Code hält diese Auswahl
deshalb für denselben lokalen Debuglauf in einem kontrollierten Cache fest
und bindet ihn an seine Konfiguration. Das ist keine generelle Garantie
einer eindeutigen fachlichen Lookup-Reihenfolge; dafür ist eine passende
explizite Policy erforderlich. Die Analyse führt selbst weder Quell-SQL
noch das SSIS-Paket aus. Erst die bewusste Ausführung der erzeugten
SQL-Artefakte hat deren dokumentierte Wirkungen.

Code: [Engine](../../Modules/toolbelt.tsql.ssis-debug/Clr/Engine.cs),
[Projektionen](../../Modules/toolbelt.tsql.ssis-debug/Clr/Projection.cs),
[Lookupcache](../../Modules/toolbelt.tsql.ssis-debug/Clr/CacheSql.cs).

## Tabellenklon

Der Planner leitet einen geordneten DDL-Plan aus Metadaten ab. Ein späteres
Execute nimmt nicht beliebigen vom Caller gelieferten SQL-Text entgegen:
Es erzeugt den kanonischen Plan erneut und vergleicht dessen Hash mit
dem erwarteten Hash. Die Hashkette bindet Reihenfolge, Objektart, Zielnamen,
Text und weitere Planbestandteile. Ihre Cursor-Schleife ist erforderlich,
weil jeder Hashschritt den vorherigen Zustand einbezieht.

DDL wird in der vorgesehenen Reihenfolge ausgeführt, unter anderem weil
Constraints und Fremdschlüssel von zuvor erzeugten Objekten abhängen.
Ein passender Hash beweist dabei nur die Übereinstimmung des gebundenen
Plans, nicht die nötigen Rechte oder stabile Umgebungsbedingungen. Deshalb
gibt es gesonderte Prüfungen auf Metadatensicht und DDL-Seiteneffekte.
Datenkopie ist ein separater Vertrag und wird durch das Erstellen der
Zielstruktur nicht still mit ausgeführt.

Code: [Executor und HashPlan-Schleife](../../Modules/toolbelt.metadata.table-clone/Source/USP_ExecuteTableClone.sql)
und [separate Datenkopie](../../Modules/toolbelt.metadata.table-clone/Source/USP_CopyTableCloneData.sql).

## Queue

Ein Claim ist eine atomare Zustandsänderung, nicht erst ein SELECT und
später ein unabhängiges UPDATE. Der Kern wählt unter den vorgesehenen
Sperren und Schedulerregeln Arbeit aus und erzeugt neues ClaimToken,
Generation und Leasegrenze. `UPDATE ... OUTPUT` bindet die ausgegebene ID
an genau die tatsächlich vorgenommene Mutation. `READPAST` kann dabei
bereits gesperrte Kandidaten überspringen; Priorität ist deshalb keine
globale Zusage einer streng seriellen Reihenfolge.

Token und Generation verhindern, dass ein alter Worker nach Recovery
unbemerkt eine neue Ownership beendet. Die Lease wird gegen Enginezeit
geprüft, nicht gegen eine möglicherweise abweichende Clientuhr.
Barrier-Arbeit benötigt zusätzlich einen Snapshot der betroffenen aktiven
Claim-Generationen. Der Scheduler muss diese Voraussetzungen gemeinsam
prüfen; ein einfacher Filter auf den sichtbaren Status würde nicht reichen.
Retries und Recovery ändern technische Ownership. Bereits erfolgte externe
fachliche Wirkungen werden dadurch nicht rückgängig, weshalb fachliche
Idempotenz weiterhin Aufgabe des Handlers bleibt.

Code: [Claim-Kern](../../Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql),
[Barrier-Enqueue](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueBarrierWork.sql),
[Recovery](../../Modules/toolbelt.core.work-queue/Source/USP_RecoverExpiredWork.sql).

## Worker

Managed Admission verbindet Queueclaim und Kapazitätsreservierung. Eine
Generation unterscheidet eine aktuelle Workerinstanz von einer früheren
Instanz mit derselben fachlichen Identität. Reservations und Attempt-IDs
binden die anschließende Ausführung an diesen konkreten Versuch.

Bei einer unterbrochenen Ausführung ist „keine Antwort erhalten“ kein
Beweis für Rollback. Die Reconcile-Procedure prüft eine Sessionfence und
einen gesperrt gelesenen Commitwitness mit passender Reservation, Nonce,
Execution-ID und Claim-Generation. Dazu gehören unterschiedliche AppLocks
mit Session- und Transaktionsbesitz: Sie sichern verschiedene Lebensdauern
des Versuchs und seiner abschließenden Entscheidung. Kann der Code den
Zustand nicht eindeutig bestimmen, erhält er `UNKNOWN` und den Hold.
Ein blindes Replay könnte andernfalls bereits committete Arbeit verdoppeln.
Cooperative Cancellation ist ergänzend ein gespeichertes Signal, das ein
Worker an Checkpoints auswertet; das Speichern des Signals allein beendet
keine laufende SQL-Anweisung.

Code: [Reconcile und Commitwitness](../../Modules/toolbelt.core.worker-control/Source/USP_ReconcileWorkerExecution.sql),
[Cancellation-Anforderung](../../Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql).
Grundlage: [AppLock-Besitz und Lebensdauer](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-getapplock-transact-sql).

## Zweite Session

Ein verschachtelter Procedure-Aufruf allein erzeugt keine autonome
Transaktion. Der Second-Session-Provider dispatcht deshalb über einen
konfigurierten Loopback-Linked-Server in eine tatsächlich andere Session.
Der Probe prüft unter anderem, dass dieselbe Datenbank mit einer anderen
SPID erreicht wird. Provideroptionen und Drift werden vor der Ausführung
kontrolliert; ein Work Type bindet den zulässigen Handler statt beliebigen
SQL-Text entgegenzunehmen.

Das Event-Log nutzt diesen Weg, damit ein erfolgreich in der zweiten
Session committetes Event einen späteren Caller-Rollback übersteht. Das
ist eine bewusst andere Transaktionsgrenze, keine Ausnahme von SQLs
Rollbackregeln. Der synchron geprüfte Handler-Returncode und die gesonderte
Resultset-Unterdrückung sind dabei wichtig: Keine lokale Infrastrukturzeile
auszugeben darf nicht bedeuten, den Remote-Aufruf oder seinen Fehler zu
überspringen. Context-IDs werden ausdrücklich transportiert; Sessionwerte
werden nicht automatisch von einer Verbindung in die andere vererbt.

Code: [Dispatcher-Fassade](../../Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql)
und [Event-Fassade](../../Modules/toolbelt.core.event-log/Source/USP_WriteEvent.sql).

## ResultTable

Eine Stored Procedure kann ihre intern erzeugte lokale Temp-Tabelle nicht
einfach als dauerhaftes Ergebnisobjekt an den Caller übergeben. Der Caller
legt deshalb die Zieltabelle in seinem Scope an; der Helper passt ihre
Form anhand einer ausdrücklich bestimmten Vorlage an.

Die technische Arbeit besteht nicht allein aus dem Kopieren von Spaltennamen:
Catalog-Metadaten liefern Typdetails, Längen, Präzision, Skala, Nullability
und Collation. Der Helper prüft nicht unterstützte Formen und Blocker,
bevor er daraus begrenztes DDL aufbaut. Identifier werden einzeln quotiert;
das dynamische DDL ist hier wegen der variablen Ergebnisform erforderlich.
`KeepData` verlangt zusätzliche Kompatibilitätsprüfungen, weil ein
Formwechsel vorhandene Zeilen nicht still beschädigen darf. Das erklärt
die getrennten Prüf- und Änderungsphasen und warum eine beliebige
`SELECT INTO`-Abkürzung den Scope- und Datenvertrag nicht erfüllt.

Code: [Vorlagenmetadaten, Blockerprüfung und ALTER TABLE](../../Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql).

## Identifier

Ein Punkt trennt SQL-Namen nur außerhalb eines geklammerten Identifiers.
`[schema.with.dot].[table]` ist daher kein vierteiliger Name. Der Scanner
verfolgt Delimiterzustand, verdoppelte Schlussklammern und den Zustand
nach einem geschlossenen Teil. Erst die entpackten, einzeln geprüften
Teile werden mit `QUOTENAME` wieder zusammengesetzt.

Auch ausgelassene Teile und nachgestellte Leerzeichen müssen bewusst
behandelt werden. Das angehängte Sentinelzeichen bei der Längenbestimmung
verhindert, dass `LEN` relevante abschließende Spaces unsichtbar macht.
Das Parsen beweist weder Objektexistenz noch Zugriffsrechte; es liefert
einen syntaktisch geprüften Namen innerhalb des dokumentierten Dialekts.

Code: [Multipart-Zustandsautomat](../../Modules/toolbelt.metadata.identifier/Source/TVF_ParseMultipartName.sql).

## Deterministische Zuordnung

Der Range-Kern hasht ein binär definiertes Frame aus Domain, Context,
Version, Seed, Bereich und längengebundenem Schlüssel. Explizite Bytefelder
verhindern mehrdeutige Textkonkatenationen und eine Abhängigkeit von der
Datenbank-Collation. Ein Bereichs- oder Versionswechsel ist dadurch Teil
der Zuordnung und kein unsichtbarer Konfigurationswechsel.

Ein gleichverteilter 64-Bit-Kandidat lässt sich nicht für jede Bereichsgröße
unverzerrt allein mit Modulo abbilden. Der Kern verwirft Kandidaten oberhalb
von `2^64 - (2^64 % Span)` und verwendet erst danach den Rest. Die begrenzte
Kandidatenfolge mit höchstens 128 Versuchen ist deshalb erforderlich.
Wird kein Kandidat akzeptiert, entsteht ein expliziter Fehlerstatus statt
einer still verzerrten Ersatzwahl. `decimal(38,0)` trägt den unsigned
64-Bit-Raum und die gesamte bigint-Bereichsbreite. Reproduzierbarkeit und
vermiedene Moduloverzerrung begründen keine Anonymisierung, Kollisionsfreiheit
oder kryptografische Geheimhaltung.

Code: [Frame, AcceptanceLimit und Kandidatenauswahl](../../Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRangeCore.sql).

Die darauf aufbauenden Operationen verwenden unterschiedliche Konstruktionen:
Translate ordnet Alphabetzeichen nach einem versionsgebundenen Hashrang und
Originalordinal zu einer Permutation und verwendet diese in `TRANSLATE`.
Das erhält Länge und wiederkehrende Zeichenmuster; es ist kein unabhängiges
Neu-Hashen jedes Zeichenvorkommens. GeoJitter erzeugt zwei getrennte Samples
für Richtung und Fläche einer Kugelkappe und rechnet den versetzten Punkt
über eine räumliche Basis zurück in Breite/Länge. Der Ausdruck
`2*asin(sqrt(U)*sin(Radius/R/2))` verteilt den Abstand über die Kappenfläche,
statt bloß einen linearen Radius zu wählen. Die konservative Kugelkonstante
und die Nachbedingungen gehören zur Begrenzung; ein geografischer
Floatpfad verspricht keine bitweise Plattformidentität.

Code: [Alphabetpermutation](../../Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicTranslate.sql)
und [Kugelkappenrechnung](../../Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicGeoJitter.sql).
