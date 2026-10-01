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
| Namen | Nicht leer, maximal 1.024 UTF-16-Codeeinheiten, binär eindeutig und als relativer ZIP-Pfad ohne NUL, `..`, Laufwerkspräfix oder führenden Separator. |
| Payload | `varbinary(max)` ist zulässig; SQL-`NULL`-Payload ist Fehler, leere Payload ist ein regulärer Entry. |
| Methode | `Stored` oder `Deflate`, pro Aufruf fest gewählt. Zusätzliche Methoden bleiben spätere Provider. |
| Metadaten | Keine Caller-gesteuerten Dateizeiten, Attribute, Kommentare oder Extra Fields in V1; der Output bleibt reproduzierbar. |
| Grenzen | Anpassbare konservative Callerlimits innerhalb separat qualifizierter harter Grenzen; kein `0 = unlimited`. Größen-/Anzahllimits werden vor großen Kopien und während Finalisierung geprüft. Hohe Ratio ist keine implizite Writerablehnung; das Readerlimit bleibt eigenständig. |
| Ergebnis | Ein `varbinary(max)`-Archiv plus nicht sensible Metadaten; keine Persistierung und keine fachlichen Daten in Debug-/Fehlerausgaben. |

V1 erzeugt keine verschlüsselten, ZIP64-, Multi-Disk-, symlink- oder
Verzeichnisentries. Duplicate-Namen werden vor der Kompression abgelehnt.
Der Namevertrag verhindert spätere Zip-Slip-Interpretation auch dann, wenn
eine andere Komponente das Archiv entpackt.

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
- [PKWARE: ZIP APPNOTE](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT)
- [bestehendes ZIP-Moduldesign](./ZIP_ARCHIVE_MODULE_DESIGN.md)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-034-zip-archive-kontrolliert-extrahieren-und-erzeugen)
