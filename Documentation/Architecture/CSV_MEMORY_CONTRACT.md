# CSV im Speicher – genehmigter Vertrag

Stand 2026-10-05. Der Benutzer hat nach der konkreten Besprechung der beiden
CSV-USPs, des eigenen SAFE-Providers und der vorgeschlagenen Grenzen die
autonome Umsetzung ausdrücklich fortgesetzt. Dieser Vertrag konkretisiert
diesen freigegebenen Scope; ein besonderes Zustimmungswort ist nicht erforderlich.
Source, Build, Framework-, IL-, SQL- und Clientnachweise sind bei Anlage dieses
Vertrags noch `not executed`. Keine Veröffentlichung oder vollständige
Plattformqualifikation wird daraus abgeleitet.

## 1. Modul und Grenzen

`toolbelt.file.csv-memory` verarbeitet caller-gelieferten Unicode-Text und
Textzellen im Speicher. Genau zwei öffentliche APIs im Schema `toolbelt_file`:
`USP_ParseCsv` und `USP_WriteCsv`. Eigene portable SAFE-Assembly auf
.NET Framework 4.8, ohne Drittanbieterpakete, Datei-/Netzwerk-I/O, Context
Connection, Worker, Encoding-/BOM-Interpretation oder automatisches Casting.
Es gibt keine zusätzliche öffentliche TVF, SVF oder Helper-USP.

Ein kanonischer zustandsbehafteter Scanner und ein gemeinsamer Quotingkern
vermeiden fachliche Doppelimplementierungen. Reines T-SQL wurde als Alternative
betrachtet; CLR wird für die begrenzte Zeichenanalyse gewählt, ohne eine
gemessene Performanceüberlegenheit zu behaupten. Der Provider erweitert weder
XLSX noch ZIP. SQL Server 2019 und neuer, Windows und Linux, sind Zielplattformen;
die tatsächliche Qualifikation erfolgt getrennt. Lokale und zentrale Installation
verwenden dieselbe Fachlogik und die vorhandene ResultTable-Infrastruktur in der
Installationsdatenbank.

## 2. Öffentliche Parameter

`toolbelt_file.USP_ParseCsv`:

```sql
@Text nvarchar(max) = NULL,
@Separator nvarchar(2) = N',',
@HasHeader bit = 0,
@NullToken nvarchar(128) = NULL,
@MaxRows bigint = 100000,
@MaxColumns int = 1024,
@MaxCells bigint = 1000000,
@MaxInputBytes bigint = 16777216,
@ResultTable sysname = NULL,
@KeepData bit = 0,
@Debug tinyint = 0,
@Hilfe bit = 0
```

`toolbelt_file.USP_WriteCsv`:

```sql
@CellsTable sysname = NULL,
@Separator nvarchar(2) = N',',
@HasHeader bit = 0,
@NullToken nvarchar(128) = NULL,
@LineEnding varchar(4) = 'CRLF',
@MaxRows bigint = 100000,
@MaxColumns int = 1024,
@MaxCells bigint = 1000000,
@MaxValueBytes bigint = 16777216,
@MaxOutputBytes bigint = 16777216,
@ResultTable sysname = NULL,
@KeepData bit = 0,
@Debug tinyint = 0,
@Hilfe bit = 0
```

Alle Budgets sind positive, nicht NULL-gültige Ganzzahlen und dürfen nur auf
Werte zwischen 1 und ihrem jeweiligen Default abgesenkt werden. NULL für
`HasHeader` ist Argumentfehler. Der unveränderte
[USP-Vertrag](../Standards/USP_CONTRACT.md) gilt für Hilfe, Debug,
ResultTable, KeepData und genau ein fachliches Resultset. Hilfe umgeht alle
fachlichen Eingaben und Seiteneffekte.

## 3. Zell- und Ausgabeform

Das Parserresultat hat genau vier Spalten in dieser Reihenfolge:

| Spalte | Typ | Bedeutung |
|---|---|---|
| RowKind | varchar(6) NOT NULL | Exakt `HEADER` oder `DATA` |
| RowOrdinal | bigint NOT NULL | HEADER=0, DATA ab1 |
| ColumnOrdinal | int NOT NULL | Ab1, ohne Lücken |
| Value | nvarchar(max) NULL | Unveränderter decodierter Text oder SQL-NULL |

Die Ordinals definieren die Reihenfolge; eine Zieltabelle garantiert keine
physische Sortierung. Die normale Parserausgabe wird nach RowOrdinal und
ColumnOrdinal sortiert. Die erste Recordbreite bestimmt die Breite aller
folgenden Records, einschließlich Header. Unterschiedliche Breiten sind Fehler.
Leere und doppelte Headernamen werden unverändert erhalten. Headerwerte sind
immer Text, nie SQL-NULL; NullToken gilt beim Parsen nur für DATA.

Der Writer liest genau diese vier benannten Spalten aus einer bereits vorhandenen
caller-lokalen Temp-Tabelle. Keine globale Temp-Tabelle, permanente Tabelle,
Tabellenvariable oder beliebige SQL-Abfrage. Metadaten verlangen genau vier
eingebaute Typen mit den genannten Längen; Alias-/UDT-Typen, weitere Spalten,
computed columns und versteckte Spalten sind ausgeschlossen. Die deklarierte
Nullability der Quelle darf abweichen; tatsächliche NULLs in RowKind und
Ordinals sind ungültig, Value darf NULL enthalten. Identität und Metadaten werden
über die einmal aufgelöste tatsächliche `tempdb`-Objekt-ID geprüft. Reservierte
interne `#tbx_`-Namen sind keine Callerquellen.

RowKind wird byteexakt einschließlich Länge geprüft: keine Casefaltung oder
SQL-Vergleichspadding. Pro Record müssen genau die ColumnOrdinals 1..ColumnCount
vorliegen, ohne Duplikate. DATA-RowOrdinals sind genau 1..DataRows, ohne Lücken;
HEADER besitzt nur RowOrdinal0. `HasHeader=1` verlangt genau einen vollständigen
Headerrecord, `HasHeader=0` verlangt dessen Abwesenheit. Header-NULL ist Fehler.
Eine leere Writerquelle bei HasHeader1 ist ungültig: der Header fehlt.

Writerresultat, genau eine Zeile:

| Spalte | Typ |
|---|---|
| CsvText | nvarchar(max) NOT NULL |
| DataRows | bigint NOT NULL |
| ColumnCount | int NOT NULL |

Leere Zellmenge ohne Header ergibt leeren Text, DataRows0 und ColumnCount0.
Header-only ergibt DataRows0 und die positive Headerbreite. Die Quelle bleibt
read-only. Falls CellsTable und ResultTable dieselbe tatsächliche Objekt-ID
auflösen, erfolgt Abbruch vor jeder Mutation, unabhängig von Namensschreibweise.

## 4. CSV-Dialekt und Texttreue

Separator ist exakt eine UTF-16-Codeeinheit, weder U+0022, CR, LF, NUL noch
High-/Low-Surrogate. Quote ist fest U+0022; innerhalb quoted Felder wird es
verdoppelt. Separator und NullToken werden anhand Codeeinheiten und Länge geprüft,
nicht über LEN, Collationgleichheit oder Trim.

Recordgrenzen sind CRLF oder LF, auch gemischt; einzelnes unquoted CR ist
ungültig. Quoted CR/LF bleibt unverändert Wertinhalt. Eine Quote darf nur am
Feldanfang öffnen; nach ihrem Abschluss sind nur Separator, Recordgrenze oder
EOF zulässig. Whitespace nach der Schlussquote ist Fehler. Keine Kommentare,
Leerzeilenunterdrückung, Normalisierung oder Formkorrektur.

SQL-NULL als ganzer Parsertext ist Argumentfehler. Leerer Text ergibt keine
Zellen, auch bei HasHeader1. Ein einzelner Zeilenumbruch ergibt einen leeren
Einspaltenrecord; ein finaler Recordabschluss erzeugt keinen zusätzlichen Record.
Leeres unquoted oder quoted Feld ist leerer Text. NUL und ungepaarte Surrogate
in Zellwerten werden erhalten; sie werden nicht durch eine zusätzliche
Unicode-Ablehnungsregel oder einen Encoder ersetzt. Ein führendes U+FEFF ist
normaler Zelltext, kein automatisch entferntes BOM.

NullToken ist optional: NULL deaktiviert ihn; sonst exakt 1..128 UTF-16-Einheiten,
ohne Separator, Quote, CR, LF, NUL oder ungepaarte Surrogate. Gültige
Surrogatpaare sind zulässig. Nur ein unquoted DATA-Feld gleicher Länge und
gleicher Codeeinheiten ist SQL-NULL. Quoted Token bleibt Text; trailing spaces
sind Bestandteil des Tokens und des Werts. Bei deaktiviertem Token weist der
Writer SQL-NULL zurück. Bei aktiviertem Token wird DATA-NULL unquoted als Token
geschrieben; Header-NULL bleibt unzulässig.

Kanonischer Writer quoted einen Textwert genau dann, wenn er Separator, Quote,
CR/LF enthält oder wörtlich dem aktiven NullToken entspricht. Die Tokenregel
gilt auch für Headertext. Ansonsten bleibt er unquoted; keine Spreadsheet-
Formelprävention oder Textumdeutung. Quote wird im quoted Wert verdoppelt.
LineEnding ist exakt `CRLF` oder `LF`, case- und längensensitiv. Jeder nichtleere
Ausgaberecord erhält den gewählten Abschluss, auch der letzte Record.

## 5. Budgets, Messung und private Stufen

MaxRows zählt ausschließlich DATA-Records, MaxCells HEADER+DATA, MaxColumns
die rechteckige Recordbreite. MaxInputBytes zählt den gesamten Parsertext
einschließlich Quotes, Separatoren und Header. MaxValueBytes zählt die Summe
aller UTF-16-Bytes im vollständigen Writerwertsnapshot; SQL-NULL charge0.
Alle Textbytes werden als zwei Bytes pro UTF-16-Codeeinheit beziehungsweise
DATALENGTH(nvarchar) gerechnet. Kein UTF-8-/Unicode-Scalar-Zähler.

MaxOutputBytes zählt die komplette Ausgabe: Werte beziehungsweise Token,
Quoteverdoppelungen, Quotehüllen, Separatoren und sämtliche Recordabschlüsse.
Zellzahlen und Grenzen werden vor LOB-Kopien geprüft; Zähler und Summen
verwenden geprüfte ausreichend breite Ganzzahlarithmetik. Ein Millionenzelllimit
begrenzt auch Metadaten, ist aber keine Zusage eines 16MiB-Heaps oder SQL Grants.

Der Parser prüft Syntax, Form und Budgets vollständig vor der ersten internen
Zelle. Zwei Durchläufe desselben Scanners erlauben anschließende begrenzte
per-cell-Decodierung ohne Millionenelementliste. Die USP konsumiert trotzdem
alle internen Zellen zuerst privat; weder öffentliches SELECT noch
ResultTable-Mutation beginnt vor erfolgreicher vollständiger Materialisierung.

Der Writer übernimmt zunächst einen typgenauen privaten Snapshot. Der gemeinsame
CLR-Kern `AnalyzeCell` bestimmt exakte Quoteentscheidung und Bytecharge.
Interne skalare Bindungen `MeasureCell` und `QuoteCell` verwenden genau diesen
Kern: Messung ohne Ausgabeallokation, Quoting erst nach erfolgreicher globaler
Summe. Dadurch wird beispielsweise eine große Menge NULLs mit langem Token
vor ihrer gesamten Tokenexpansion abgewiesen. Danach private Fragmente einmal
erzeugen und geordnet zusammensetzen; nvarchar(max) in allen Zwischenschritten,
keine zeilenweise wachsende Verkettung und keine NULL-fragmentbedingten Lücken.

## 6. Interner CLR-Transport

Klasse `Toolbelt.Csv.CsvEntryPoints`, Attribute für SQL-Funktionen deterministisch,
DataAccess=None und SystemDataAccess=None. Keine globalen veränderlichen Zustände.
Die internen SQL-Bindungen heißen `TVF_InternalParseCsv`,
`SVF_InternalMeasureCsvCell` und `SVF_InternalQuoteCsvCell`; sie sind technische
Transporte und keine zusätzlich freigegebenen öffentlichen Fachfunktionen.

```csharp
public static IEnumerable Parse(SqlChars text, SqlChars separator,
    SqlBoolean hasHeader, SqlChars nullToken, SqlInt64 maxRows,
    SqlInt32 maxColumns, SqlInt64 maxCells, SqlInt64 maxInputBytes);
public static void FillCell(object cell, out SqlString rowKind,
    out SqlInt64 rowOrdinal, out SqlInt32 columnOrdinal, out SqlChars value,
    out SqlInt32 errorCode);
public static SqlInt64 MeasureCell(SqlChars value, SqlChars separator,
    SqlChars nullToken, SqlBoolean isHeader);
public static SqlChars QuoteCell(SqlChars value, SqlChars separator,
    SqlChars nullToken, SqlBoolean isHeader, SqlInt64 maxOutputBytes);
```

Interne FT-Ausgabe: RowKind nvarchar(6), RowOrdinal bigint, ColumnOrdinal int,
Value nvarchar(max), ErrorCode int, ohne NOT-NULL-Deklaration. CLR-TVFs unterstützen weder
nicht-Unicode-Textspalten noch NOT-NULL-Ausgabedeklarationen. FillCell liefert
gültige Enum-/Ordinalwerte bei Erfolg und ErrorCode0. Ein eigener fachlicher
Parserfehler liefert genau eine interne Sentinelzeile mit ErrorCode aus
55300..55309 und SQL-NULL in allen vier Zellspalten; keine vorherigen Zellzeilen.
Auch bei leerem erfolgreichem Text gibt es keine Sentinelzeile, sondern null
Zeilen. Die private T-SQL-Stufe prüft alle ErrorCodes vor der Übernahme in den
öffentlichen NOT-NULL-/varchar-Vertrag; ErrorCode wird niemals öffentlich
ausgegeben. NULL, unbekannter Code oder mit Nutzdaten gemischter Sentinel ist
eine Transportinvariantenverletzung55309. Kein TVP oder Binary-Envelope.

MeasureCell liefert nichtnegative exakte UTF-16-Bytecharge; 0 ist für einen
leeren Textwert gültig. Ein eigener fachlicher Fehler wird als negativer
Code -55300..-55309 transportiert. Die T-SQL-Stufe prüft die Allowlist und wirft
den entsprechenden positiven fachlichen Code vor QuoteCell oder öffentlicher
Ausgabe. Andere negative Codes und SQL-NULL sind Transportfehler55309.
QuoteCell wird ausschließlich nach erfolgreicher Messung und globaler
Outputprüfung mit identischen Wert-/Dialektinputs aufgerufen. Es prüft die
Charge vor der Allokation zusätzlich gegen den gültigen positiven Outputdeckel;
ein unerwarteter Fehler bleibt ursprünglicher technischer Fehler, kein
Fachstatus oder NULL-Ergebnis.

## 7. Atomik und Fehlergrenzen

Vor öffentlichen Ergebnissen: Argumentprüfung, Quellenpreflight, vollständige
private Form-/Budgetprüfung und komplette Ergebnisvorbereitung. Änderungen
des Caller-ResultTable-Schemas, Replace/Append und Zielinsert bilden danach eine
zusammengehörige Transaktion gemäß
[DEC-2026-016](DECISIONS.md#dec-2026-016-savepoint-fähiger-transaktionsvertrag-und-zentrale-verwendbarkeit).
Callertransaktion und SET-Zustände werden nach bestehendem Vertrag erhalten;
eine bereits beschädigte Transaktion wird vor Mutation zurückgewiesen.
Späte Syntax-/Budgetfehler verändern das Ziel nicht. Ein fehlschlagender
Zielconstraintinsert wird korrekt zurückgerollt, ohne ursprüngliche Zielwerte
vorzeitig zu verlieren. Nur eigene Temps werden entfernt; fremde Temps werden
weder adoptiert noch überschrieben.

Reservierte fachliche THROW-Nummern, jeweils fester nicht-payloadhaltiger Text:

| Nummer | Kategorie |
|---|---|
| 55300 | Pflichtargument, Separator, NullToken, Flag oder LineEnding ungültig |
| 55301 | CSV-Quote-/Recordsyntax ungültig |
| 55302 | Parserrecords nicht rechteckig |
| 55303 | Budgetparameter oder tatsächliche Ressourcenüberschreitung |
| 55304 | Callerquelle fehlt oder ist kein zulässiger lokaler Tempname |
| 55305 | Quellmetadaten nicht exakt unterstützt |
| 55306 | RowKind, Ordinals, Duplikate, Header oder Writerrechteck ungültig |
| 55307 | SQL-NULL nicht darstellbar beziehungsweise Header-NULL |
| 55308 | Quelle und ResultTable identisch |
| 55309 | Eigene interne Transportinvariante verletzt |

Lifecycle reserviert 55320..55329, exakter Trust 55340..55349. Der gezielte
Repositoryscan vor Vertragsanlage fand keine bestehende Fehlerbelegung dieser
Bereiche; numerische Zufallstreffer in synthetischen Daten sind keine Belegung.
Die einzelnen Lifecycle-/Trustzustände werden mit ihren gekoppelten Tests
festgelegt. Fehler bestehender ResultTable-Infrastruktur bleiben deren Fehler.

Eigene CLR-Fachfehler werden ausschließlich über Parser-ErrorCode beziehungsweise
negative MeasureCell-Codes transportiert. Keine Klassifikation anhand des
Textes von CLR-Fehler6522 und kein LIKE auf Nutzdaten oder Fehlermeldungen.
Der Kern darf nur seine eigenen bekannten fachlichen Fehler in diese Statusform
übersetzen; kein allgemeines Abfangen sämtlicher Exceptions.
Unerwartete Engine-/CLR-/Allokationsfehler bleiben ursprüngliche Fehler;
kein Erfolg oder erfundener Fachfehler daraus. Keine Eingabetexte oder
Zellwerte in eigenen Fehlertexten. Fehlerkategorien sind stabil; bei mehreren
Fehlern gilt die tatsächliche Prüfphase, keine globale Mehrfachfehlerpriorität.

## 8. Deployment, Abnahme und Quellen

SAFE und clr strict security bleiben erhalten; kein TRUSTWORTHY ON, keine
Rechtevergabe oder automatische Abhängigkeits-/Trustinstallation. Offizielles
Binary über exakten SHA2-512 und ausdrückliches Trust-Opt-in prüfen.
Fünf Lifecycle-Slots umfassen zwei öffentliche USPs und drei interne Bindungen;
versionierte Ownershipmarker, Preflight, AppLock, Rollback, unbekannte
Fremdobjekte und bestätigter zentraler Uninstall folgen dem
[Deploymentmodell](DEPLOYMENT_MODEL.md) und dem
[CLR-Sicherheitsvertrag](CLR_SECURITY_AND_PORTABILITY.md).

Abnahme verbindet unabhängige synthetische Parser-/Writerorakel, Roundtrips,
leere/quoted Felder, Token/NULL/trailing spaces, Header-only, CRLF/LF und embedded
breaks, fehlerhafte Quotes und Breiten, NUL/unpaired UTF-16, jede Grenze exakt/+1
einschließlich NULL-Tokenexpansion sowie ResultTable-Atomik bei späten Fehlern.
Hinzu kommen Standardtail/Help, Inputaliasabweisung, exakte Clientmetadaten,
Framework-/IL-NoIO-Nachweise und begrenzte native Lifecyclequalifikation.
Kein vollständiger Matrix-, Heap-, Minimalrechte- oder Performance-PASS allein
aus diesem Vertrag oder einem begrenzten erfolgreichen Lauf.

Herkunft: [konkrete CSV-Besprechung und technische Vorprüfung](../Research/NEXT_DEVELOPMENT_WAVES_2026-10-04.md).
[RFC4180](https://www.rfc-editor.org/info/rfc4180/) ist Quotingreferenz;
Separatorwahl, LF, NULL-Token und UTF-16-Werttreue sind der Toolbelt-Dialekt,
keine uneingeschränkte RFC-Konformitätszusage.
[Microsoft CLR-TVFs](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions?view=sql-server-ver17)
belegt inkrementelle IEnumerable-Ausgabe, eingeschränkte CLR-Ausgabemetadaten
und den Ausschluss direkter Managed-TVPs.
[Microsoft STRING_AGG](https://learn.microsoft.com/en-us/sql/t-sql/functions/string-agg-transact-sql?view=sql-server-ver17)
belegt geordnete Zusammensetzung und den nvarchar(max)-Resultattyp bei
entsprechend typisiertem Eingang. Primärquellen am 2026-10-05 geprüft;
sie sind kein SQL-CLR-Runtimenachweis dieses Moduls.
