# Vorschlag: In-memory-ZIP-Erzeugung (`TC-2026-034`)

## Status

Die bestehende ZIP-Memory-Funktion extrahiert einen einzelnen Entry und bleibt
unverändert. Dieses Dokument bereitet eine getrennte Erzeugungsfunktion vor.
Es autorisiert weder ein SQL-Objekt noch Datei-I/O, Archivschreiben oder eine
Änderung am validierten Extraktionsvertrag.

## Nutzeranforderung vom 2026-10-01

Der Benutzer hat In-memory-ZIP-Erzeugung als Startscope bestätigt. Spätere
Datei-I/O ist ein verpflichtender Roadmap-Folgeslice unter `TC-2026-034`,
nicht lediglich eine unverbindliche Provideroption. Vor dessen Implementierung
werden Dateioperationen, Roots, Identität, ACLs, Overwrite, Atomicity, Limits
und Plattformunterstützung in einem eigenen Sicherheits-, Provider- und
Funktionsvertrag besprochen und ausdrücklich freigegeben.

Die bestätigte Reihenfolge autorisiert keine pauschale Datei-I/O und legt
noch keinen fertigen öffentlichen Writervertrag fest. Die konkreten
In-memory-Signaturen, Typdefinitionen, Grenzen und Provider bleiben offen.

Präzisierung vom 2026-10-01: Der Benutzer hat den vorgeschlagenen
In-memory-Schnitt mit konservativen Defaults bestätigt. Die caller-lokale
`#Temp`-Eingabe verwendet logisch `Ordinal`, `EntryName` und `Payload`.
`Stored` ist Default; `Deflate` ist explizit wählbar. Ressourcenparameter
dürfen nach unten und nach oben angepasst werden, jedoch nur innerhalb
separat technisch zu qualifizierender harter Grenzen. `0 = unlimited`
ist nicht vorgesehen. Hohe Compression Ratios sind beim Writer erlaubt;
notwendige Readerlimits werden ausdrücklich dokumentiert. Diese
Richtungsbestätigung ist keine zusätzliche öffentliche
Implementierungsfreigabe; Signatur, Transport, Fehler- und harter
Ressourcenvertrag bleiben vor Umsetzung konkret zu besprechen.

## Empfohlener V1-Schnitt

V1 erzeugt ein einzelnes ZIP-Binary im Speicher aus einer expliziten,
typisierten Entry-Liste. Es schreibt keine Dateien, liest keine Pfade, nimmt
keine bestehenden Archive entgegen und fügt ihnen keine Einträge hinzu.

Die Entry-Liste besitzt logisch drei Felder: positive Ordinalspalte,
Entryname und Binarypayload. Ein öffentlicher Table Type ist eine mögliche
T-SQL-Eingabeoberfläche, aber kein direkt an SQL CLR übergebbarer Parameter.
Type, Signatur und Transport bleiben bis zur Funktionsbesprechung offen.

## Transportprüfung vom 2026-10-01

Microsoft dokumentiert, dass ein User-defined Table Type nicht als TVP an eine
im SQL Server ausgeführte managed Procedure oder Function übergeben werden
kann. Ein TVP benötigt daher einen T-SQL-Wrapper mit eigener Übergabe an den
CLR-Kern. Table Types und Treiberbindung sind datenbankgebunden; identische
lokale und zentrale Typdefinitionen begründen keine pauschale
Cross-database-Kompatibilität.

Der Benutzer hat am 2026-10-01 die caller-lokale `#Temp`-Tabelleneingabe
für lokale und zentrale Nutzung gewählt; kein öffentlicher TVP ist für V1
vorgesehen. Die interne CLR-Übergabe ist noch offen. Die folgenden
Alternativen bleiben Research, keine endgültige Implementierungswahl:

| Alternative | Nutzen | Kosten und offene Nachweise |
|---|---|---|
| T-SQL validiert eine ausschließlich caller-lokale `#Temp`-Entrytabelle und serialisiert eine versionierte, längencodierte `varbinary(max)`-Nachricht an einen reinen Writer | Keine Datenbankabfrage im CLR-Kern; kein JSON/Base64; dieselben drei logischen Felder lokal und zentral | Zusätzliche Kopien und Serialisierungskosten; feste Byteordnung, Längen-/Overflowprüfung und Vorablimit auch für den Transport; keine Streamingzusage |
| T-SQL validiert dieselbe `#Temp`-Eingabe, erzeugt einen eigenen Temp-Snapshot und übergibt dessen validierten Namen an einen CLR-Writer mit Context Connection | Kein Binary-Envelope; zeilenweises Lesen des Snapshots möglich | Zusätzliche TempDB-Mutation und Cleanup-/Reentrancy-Vertrag; ausschließlich gequoteter, geprüfter interner Tabellenname; SAFE-, Linux-, Berechtigungs- und Central-Nachweis offen |
| T-SQL-TVP-Wrapper vor einer der beiden internen Übergaben | Statisch typisierte Eingabe | Öffentlicher Type und dessen Namenskonvention, datenbankbezogene Aufruf-/Clientadapter sowie getrennte Central-Tests erforderlich |

Die Context Connection verwendet den ursprünglichen Session-/Transaktionskontext;
das ist Primärquellenevidenz für die Machbarkeit, kein Runtime-Nachweis dieses
Writers. Reguläre Tabellen, globale Temps, freies SQL und persistentes Staging
sind keine impliziten Alternativen. Ein Temp-Inputparameter und ein TVP sind
unterschiedliche öffentliche Verträge und werden vor Implementierung entschieden.

Bestätigte konservative V1-Default-Zielwerte vom 2026-10-01, keine
gemessenen Kapazitäten oder bereits qualifizierten harten Obergrenzen:
256 Entries, 1.024 UTF-16-
Codeeinheiten je Name, 16 MiB je Payload, 64 MiB Payloadsumme und 68 MiB
Archivoutput; bei Binarytransport zusätzlich 68 MiB Envelope.
Die konkreten Parameter und zulässigen Anhebungen müssen vom jeweils
technisch qualifizierten Maximum begrenzt werden; niedrigere Werte bleiben
möglich. Defaults, Callerlimits und unveränderbare technische Ceilings sind
unterschiedliche Ebenen; kein Nullwert oder `0` wird hier als unbegrenzte
Verarbeitung definiert.
Ein kooperatives Writerbudget von 30 Sekunden ist ein Vorschlag, keine harte
Echtzeit- oder gesamte SQL-Ausführungsfrist. Grenzen müssen vor großen Kopien
und während Schreiben/Finalisierung technisch qualifiziert werden.

`Stored` als Default und `Deflate` als explizite Wahl wurden bestätigt.
Der Benutzer hat am 2026-10-01 gültige Deflate-Archive auch oberhalb des
Readerdefaults `@MaxCompressionRatio = 200.00` gewählt. Dieses Readerlimit
ist deshalb keine implizite Writergrenze. Das erforderliche, vom Caller
bewusst gesetzte Readerlimit für stärker komprimierte erzeugte Archive wird
ausdrücklich dokumentiert. Absolute Ressourcen-/Größengrenzen bleiben davon
unberührt. Eine stille Änderung der angeforderten Methode ist nicht vereinbart.

## Vertragsvorschlag

| Aspekt | Vorschlag |
|---|---|
| Reihenfolge | Eindeutige, positive Ordinals bestimmen die Central-Directory- und Eintragsreihenfolge. |
| Namen | Nicht leer; Default-Zielwert 1.024 UTF-16-Codeeinheiten, anpassbar innerhalb des separat zu qualifizierenden technischen Maximums (Vorschlag 2.048); binär eindeutig und relativer ZIP-Pfad ohne NUL, `..`, Laufwerkspräfix oder führenden Separator. |
| Payload | `varbinary(max)` ist zulässig; SQL-`NULL`-Payload ist Fehler, leere Payload ist ein regulärer Entry. |
| Methode | `Stored` oder `Deflate`, pro Aufruf fest gewählt. Zusätzliche Methoden bleiben spätere Provider. |
| Metadaten | Keine Caller-gesteuerten Dateizeiten, Attribute, Kommentare oder Extra Fields in V1; feste Metadaten. Stored-Byteidentität als Testziel, keine Deflate-Byteidentitätszusage über Runtime-/Plattformgrenzen. |
| Grenzen | Anpassbare konservative Callerlimits innerhalb separat qualifizierter harter Grenzen; kein `0 = unlimited`. Größen-/Anzahllimits werden vor großen Kopien und während Finalisierung geprüft. Hohe Ratio ist keine implizite Writerablehnung; das Readerlimit bleibt eigenständig. |
| Ergebnis | Ein `varbinary(max)`-Archiv plus nicht sensible Metadaten; keine Persistierung und keine fachlichen Daten in Debug-/Fehlerausgaben. |

V1 erzeugt keine verschlüsselten, ZIP64-, Multi-Disk-, symlink- oder
Verzeichnisentries. Duplicate-Namen werden vor der Kompression abgelehnt.
Der Namevertrag verhindert spätere Zip-Slip-Interpretation auch dann, wenn
eine andere Komponente das Archiv entpackt.

## Zur gebündelten Freigabe: konkreter Writervertrag

Empfehlung vom 2026-10-01, kein implementierter Writer und keine neue
Implementierungsfreigabe. Öffentlicher Vorschlag im bestehenden ZIP-Modul:

~~~text
toolbelt_archive.USP_CreateZipFromEntries
    @EntryTable               sysname = NULL
    @CompressionMethod        varchar(max) = 'Stored'
    @MaxEntries               int = 256
    @MaxEntryNameCodeUnits     int = 1024
    @MaxEntryBytes             bigint = 16777216
    @MaxTotalPayloadBytes      bigint = 67108864
    @MaxArchiveBytes           bigint = 71303168
    @MaxEnvelopeBytes          bigint = 71303168
    @WriterBudgetMilliseconds  int = 30000
    @ResultTable               sysname = NULL
    @KeepData                  bit = 0
    @Debug                     tinyint = 0
    @Hilfe                     bit = 0
~~~

CompressionMethod exakt ASCII `Stored` oder `Deflate`, keine implizite
Case-/Space-Normalisierung. Grenzen positiv und nicht NULL; kein
`0 = unlimited`. Caller kann jeden Wert unabhängig innerhalb qualifizierter
Ceilings erhöhen/senken; kleinere Limits werden nicht automatisch vergrößert.

| Dimension | Bestätigter Default-Zielwert | Vorgeschlagene technische Ceiling, noch unqualifiziert |
|---|---:|---:|
| Entries | 256 | 1024 |
| Name, UTF-16-Codeeinheiten | 1024 | 2048 |
| Entrybytes | 16 MiB | 32 MiB |
| Payloadsumme | 64 MiB | 128 MiB |
| Archivbytes | 68 MiB | 144 MiB |
| Envelopebytes | 68 MiB | 136 MiB |
| kooperatives Writerbudget | 30000 ms | 60000 ms |

Keine gemessenen Kapazitäten. Ceilingqualifizierung muss tatsächliche
Kopien, Memorydruck und konkurrierende Aufrufe berücksichtigen; klassische
ZIP-Felder (16-Bit-Anzahl/Name, 32-Bit-Größe/Offset) sind zusätzlich unabhängig
zu prüfen. Kein ZIP64-Sentinel/Overflow, keine Gleichsetzung Formatlimit=RAM.

**Eingabe:** existierende caller-lokale `#Temp` derselben Session, logisch
`Ordinal int` (positiv/eindeutig, Lücken erlaubt), `EntryName nvarchar(max)`,
`Payload varbinary(max)`. Werte nicht NULL; nullable Spaltenmetadaten sind
zulässig, Werte werden geprüft. Extrafelder ignorieren. Keine permanente/
globale Tabelle, Tabellevariable, freies SQL oder TVP. Null Entries erzeugt
gültiges leeres ZIP; leere Payload gültig. EntryTable selbst darf im
fachlichen Aufruf nicht NULL sein.

Ordinals bestimmen Reihenfolge. Namen unverändert als relative ZIP-Pfade mit
`/`; nicht leer, kein NUL/Backslash/führender oder abschließender Separator,
leere Segmente, `.`/`..`, Drive-/Devicepfad. Strikte UTF-8-Kodierung:
ungültige UTF-16-Surrogates vor jeder potenziell verlustbehafteten Konvertierung
ablehnen; Ersatzzeichen dürfen ungültigen Input nicht verschleiern.
UTF-8-Bytegrenzen, binäre Namensduplikate und Formatfelder prüfen, keine
Casefold-/Normalisierung. Casevarianten könnten später auf Windows-Dateisystemen
kollidieren; der In-memory-Writer ist kein Dateisystemvertrag.

Kompatibilitätsgrenze des vorhandenen Readers: dessen interne Namensgrenze
und öffentliche EntryName-Typen sind auf 1024 UTF-16-Codeeinheiten begrenzt.
Eine vorgeschlagene Writer-Anhebung darüber kann gültige ZIP-Archive erzeugen,
die dieser Reader weder listen noch extrahieren kann. Keine implizite
Reader-Limiterweiterung; Roundtrip-Parität mit dem vorhandenen Reader gilt
nur innerhalb seiner unveränderten Grenzen. Größere Namen benötigen einen
unabhängigen Leser oder einen gesondert freigegebenen Reader-Folgeslice.

**Transportempfehlung:** genau ein versionierter, längencodierter
Little-Endian-Binary-Envelope, strikte UTF-8-Namen, kein JSON/Base64.
T-SQL validiert privaten konsistenten Snapshot; CLR-Kern ohne Datenabfrage.
Archivindex/Input einmal übernehmen, keine naive wiederholte LOB-Konkatenation
mit quadratischem Kopierverhalten. Exakte Envelopegröße einschließlich
Versionsheader, Längenfeldern, UTF-8-Namen und Payloads vor großer Allokation
berechnen, nicht nur Payloadsumme. Decoder prüft checked Arithmetik,
Längen/Counts/Restgrenzen, keine unerwarteten trailing Bytes und alle Limits
erneut. Memory-/Kopierqualifizierung bleibt Voraussetzung, keine Streamingzusage.

**Ergebnis:** genau eine Erfolgszeile, jeweils NOT NULL:

| Feld | Typ |
|---|---|
| ArchivePayload | varbinary(max) |
| ArchiveBytes | bigint |
| EntryCount | int |
| TotalPayloadBytes | bigint |
| CompressionMethod | int, 0=Stored/8=Deflate |

Feste Metadaten: ZIP-Zeit 1980-01-01 und feste Attribute, keine Caller-
Kommentare/Extra Fields. CRC aus tatsächlichen Payloadbytes und korrekte
Local-/Central-Header/Finalisierung. Stored byteidentischer Output ist
Testziel; Deflatebyteidentität über Runtime-/Plattformversionen wird nicht
versprochen. Hohe Ratio erlaubt; Verbraucher müssen Reader-Ratiolimit
bewusst setzen. Keine stillschweigende Methodenänderung.

**Fehler-/Mutationspriorität:**

1. Hilfe vollständig nach USP-Vertrag: keine fachlichen Prüfungen, Debug,
   Providerarbeit oder ResultTablemutation.
2. Fachparameter/positive Limits/Ceilings, dann deklarierte Dependencies.
3. Input-/Output-Tempnamen und Schema sicher per tempdb-object_id auflösen;
   identische Input-/ResultTable-object_id ablehnen, auch bei Aliasnamen.
   Snapshot unter konsistenter Lesegrenze, keine Sicht auf gemischte Änderungen.
4. Ordinal-/NULL-/Namens-/Encoding-/Duplikatfehler vor Kompression; Mengen-,
   Größen-/Envelope-/klassische Formatlimits vor großen Kopien prüfen.
5. Envelope dekodieren/erneut validieren, CRC/Kompression/Finalisierung unter
   kooperativem Budget; vollständiges Archiv vor erster ResultTablemutation.
6. ResultTable-Preflight vollständig vor Mutation, dann kanonischer
   USP_PrepareResultTable mindestens 1.0.0 und expliziter Insert/SELECT.

Symbolische Kategorien als Vorschlag: TBX_ZIP_WRITE_INVALID_ARGUMENT,
INPUT_SCHEMA, INVALID_NAME, DUPLICATE_NAME, RESOURCE_LIMIT, FORMAT_LIMIT,
TIMEOUT, DEPENDENCY, TRANSPORT_INVALID, PROVIDER_FAILURE, jeweils mit
Präfix TBX_ZIP_WRITE_. Numerische THROW-Zuordnung erst technische
Kollisionsprüfung; bestehende 51320–49-Reservierungen werden nicht umgedeutet.
Fehler/Debug enthalten keine Payloads oder Namen aus realen Daten.

Budget umfasst CLR-Envelopeprüfung, CRC, Kompression und Finalisierung;
kooperativ, keine harte SQL-End-to-End-/Wallclockzusage. ResultTable/KeepData/
Debug/Hilfe vollständig nach [USP_CONTRACT](../Standards/USP_CONTRACT.md),
eigene Transaktion oder Savepoint für Mutation, Caller nicht pauschal committen
oder zurückrollen; XACT_STATE=-1 bleibt ursprünglicher Enginefehler mit
Callerrollbackpflicht. Private Snapshot-/Helperobjekte cleanup/reentrant;
kein INSERT EXEC. Central-Temps gleiche Session, explizite Metadaten/
Collation-/Minimalrechte, keine Rechte-/Trustausweitung.

Dependencies/SAFE-/Windows-/Linuxfähigkeit sind technisch nachzuweisen,
nicht durch diesen Vorschlag gegeben. Alternative Context Connection bleibt
begründeter Vergleich, nicht zweite parallel implementierte Übergabe.
Risiken: Envelope-/Snapshotkopien, UTF-8-/Formatfehler, Budgetkooperation,
Deflateunterschiede; ein dateibasierter Writer wäre eigener Sicherheitsvertrag.

Geplante Tests, noch nicht ausgeführt: leer/Stored/Deflate, Unicode und
Surrogateablehnung, Namen/Ordinal-/NULL-/Duplikatfehler, exakte Grenzwerte,
CRC/Header/Outputlängen, unabhängiger Leser, hohe Ratio und Readerlimit,
Envelopeverletzungen, Budget, Helpbypass, ResultTable unberührt bei Fehler,
Input=Output-Alias, Replace/Append/Schema-/Constraint-/Callertransaktion,
Local/Central/Minrechte/Kollision/Upgrade/Uninstall. Nach Freigabe zuerst
2019 Linux und 2025 Windows, Erweiterung nur nach tatsächlichem Impact.

## Technologie und Integrität

Der vorhandene sichere ZIP-CLR-Provider ist ein möglicher Ausgangspunkt, aber
der Writer braucht einen eigenen, begrenzten Implementierungsteil. Er muss
Local Header, Central Directory, CRC32 und Deflate-Stream erzeugen und die
deklarierte Länge mit der tatsächlich geschriebenen Länge abgleichen. Ein
unabhängiger Leser testet jedes erzeugte Archiv gegen die öffentlichen
Metadaten.

Die spätere Assembly bleibt nur dann `SAFE`, wenn sie wie das bestehende Modul
keinen Datei-, Netzwerk-, Prozess- oder Registryzugriff benötigt. Ein
File-System-Writer, atomische Dateierstellung, Overwrite und ACLs gehören zu
einem späteren, eigenen Providervertrag.

## Tests und Entscheidungspunkt

Tests verwenden ausschließlich synthetische Entrynamen und Payloads. Sie
umfassen leer/nicht leer, Stored/Deflate, Unicode, Binärduplikate,
Namensfehler, Größen-/Anzahllimits, CRC-/Längenprüfung, deterministische
Reihenfolge, unabhängiges Lesen, Wiederholungsdeployment, Lifecycle und die
SQL_Server_Lab-Matrix für 2019, 2022 und 2025 auf Windows und Linux. CUs sind
nur bei patchgebundenen Tests relevant.

Vor einer Implementierungsfreigabe wird der V1-Schnitt bestätigt oder
geändert: In-memory-Entryliste mit drei logischen Feldern, gewählter
Eingabe-/CLR-Transport, zwei Methoden und ein Binaryoutput ohne Datei-I/O.
Danach werden gegebenenfalls der öffentliche Table Type, die Signatur,
konkrete Grenzen, Fehlerbereich und die Providerentscheidung als Funktion
besprochen und freigegeben.

## Quellen

- [Microsoft: CLR-TVFs und TVP-Grenze](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions?view=sql-server-ver17) – am 2026-10-01 geprüft.
- [Microsoft: Context Connection](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/data-access/context-connection) – am 2026-10-01 geprüft.
- [Microsoft: OLE DB TVP-Type-Bindung](https://learn.microsoft.com/en-us/sql/connect/oledb/ole-db-table-valued-parameters/ole-db-table-valued-parameter-type-support-properties?view=sql-server-ver17) – am 2026-10-01 geprüft; Treibervertrag, keine Runtimevalidierung der Central-Alternative.
- [Microsoft: DeflateStream und Runtime-/Kompressionsverhalten](https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.deflatestream?view=netframework-4.8.1).
- [PKWARE: ZIP APPNOTE](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT)
- [bestehendes ZIP-Moduldesign](./ZIP_ARCHIVE_MODULE_DESIGN.md)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-034-zip-archive-kontrolliert-extrahieren-und-erzeugen)
