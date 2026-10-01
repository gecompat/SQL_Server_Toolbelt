# USP_CreateZipFromEntries

Erzeugt ein vollständig finalisiertes In-memory-ZIP aus einer vorhandenen lokalen Temp-Tabelle des Aufrufers. Implementierungsfreigabe am 2026-10-01 nach Besprechung von PR #121: „Unquoting, Split-USP und ZIP-Writer implementieren“. Datei-I/O, XLSX, TVP, ZIP64, Verzeichnis-Entries, Symlinks, Verschlüsselung und Multi-Disk sind nicht enthalten.

## Eingabe und Defaults

`@EntryTable sysname = NULL` bezeichnet eine vorhandene lokale `#Temp` mit `Ordinal int`, `EntryName nvarchar(max)` und `Payload varbinary(max)`. Zusatzspalten werden ignoriert; berechnete oder verschlüsselte Pflichtspalten sind ausgeschlossen. Nullable Spaltenmetadaten sind erlaubt, tatsächliche Werte dürfen nie NULL sein. Ordinals müssen positiv und eindeutig sein; sortiert wird aufsteigend, Lücken sind erlaubt. Eine leere Tabelle ergibt ein ZIP mit ausschließlich EOCD (22 Bytes). Input und ResultTable dürfen nicht auf dieselbe Objekt-ID aufgelöst werden.

| Parameter | Default | Zulässiger Bereich |
|---|---:|---:|
| `@CompressionMethod varchar(max)` | `Stored` | exakt ASCII Stored oder Deflate |
| `@MaxEntries int` | 256 | 1–1024 |
| `@MaxEntryNameCodeUnits int` | 1024 | 1–2048 UTF-16-Codeeinheiten |
| `@MaxEntryBytes bigint` | 16777216 | 1–33554432 |
| `@MaxTotalPayloadBytes bigint` | 67108864 | 1–134217728 |
| `@MaxArchiveBytes bigint` | 71303168 | 1–150994944 |
| `@MaxEnvelopeBytes bigint` | 71303168 | 1–142606336 |
| `@WriterBudgetMilliseconds int` | 30000 | 1–60000 |

Alle Limits können unabhängig gesenkt oder erhöht werden. Explizites NULL ist ungültig; eine unbegrenzte Einstellung gibt es nicht. Die Obergrenzen sind konservative Engineering-Ceilings, keine ZIP-Formatgrenze, SQL-2-GB-Zusage oder allgemeine Kapazitäts- bzw. Parallelitätsgarantie. Die praktische Qualifikation wird separat ausgewiesen. Envelope und Archiv zählen Framing, Namen und Header zusätzlich zur Payloadsumme.

Die Signatur endet mit `@ResultTable sysname = NULL`, `@KeepData bit = 0`, `@Debug tinyint = 0` und `@Hilfe bit = 0`. Explizite NULLs der drei Steuerparameter werden zu 0 normalisiert. Die Hilfe ignoriert fachliche Argumente, Dependencies und ResultTable und liefert den Helpvertrag 1.0. Ohne ResultTable wird SELECT ausgegeben; andernfalls wird nach PrepareResultTable >= 1.0.0 in die vorhandene Caller-Temp geschrieben. Replace/Append folgt USP_CONTRACT. Erfolgsreturn ist 0.

Namen bleiben ordinal sowie case- und längensensitiv, einschließlich nachgestellter Leerzeichen. Ungültiges UTF-16 wird vor dem UTF-8-Encoding abgelehnt. Relative Dateinamen mit `/` sind erlaubt; NUL, Backslash, **jegliche** Doppelpunkte, führende oder abschließende `/`, leere Segmente, `.` und `..` sind verboten. Es gibt keine Normalisierung; binär identische Namen sind Fehler. Das ZIP-UTF-8-Flag wird gesetzt. Der Writer erlaubt bis 2048 Codeeinheiten nur mit explizitem Limit; der unveränderte Reader mit 1024 Codeeinheiten kann solche längeren Namen nicht konsumieren.

## Resultset und Fehler

Genau eine Zeile mit fünf NOT-NULL-Spalten: `ArchivePayload varbinary(max)`, `ArchiveBytes bigint`, `EntryCount int`, `TotalPayloadBytes bigint` und `CompressionMethod int` (0 oder 8). Es gibt keine Teilarchive.

| Fehler | Kategorie |
|---|---|
| 51350 | INVALID_ARGUMENT |
| 51351 | INPUT_SCHEMA |
| 51352 | INVALID_NAME |
| 51353 | DUPLICATE_NAME |
| 51354 | RESOURCE_LIMIT |
| 51355 | FORMAT_LIMIT |
| 51356 | TIMEOUT |
| 51357 | DEPENDENCY |
| 51358 | TRANSPORT_INVALID |
| 51359 | PROVIDER_FAILURE |

Messages beginnen mit `TBX_ZIP_WRITE_`. Erwartete CLR-Fehler liefern eine interne Statuszeile, aus der T-SQL ein THROW erzeugt. Ein SQL6522-Messageparser ist keine Vertragsgrundlage. Unerwartete Enginefehler bleiben Originalfehler. Die internen `TVF_InternalZipWriterName` und `TVF_InternalZipWriterArchive` sind keine öffentliche Fach-API.

## Ressourcen, Transaktion, Sicherheit

HOLDLOCK stabilisiert Preflight und Snapshot innerhalb einer eigenen Transaktion oder eines Caller-Savepoints bis zur Ergebnisübergabe. Locks und Transaktionslog bleiben damit über Snapshot, Serialisierung und Kompression gehalten. Konkurrierendes MARS oder Mutieren derselben Temps wird nicht unterstützt. Ein Savepoint wird erst nach erfolgreichem SAVE als gesetzt geführt. Die vollständige Callertransaktion wird niemals zurückgerollt; ein nicht mehr committbarer Callerzustand bleibt dessen Verantwortung. Zielmutationen sind rückrollbar.

Der FAST_FORWARD-Cursor serialisiert ausschließlich den bereits geprüften, begrenzten Snapshot ordinal; er ist kein fachlicher Alternativparser. LOB-`.WRITE` vermeidet naive quadratische Komplettkonkatenation. Das Binary-Envelope enthält TBZW, Version 1 und Count, anschließend little-endian Ordinal, Namensbyteanzahl und Payloadbyteanzahl sowie strikte UTF-8-Namen und Payloads. Der SAFE-CLR-Kern ist datenzugriffsfrei und verwendet weder ContextConnection noch Dateifallback.

Snapshot, SQL-Envelope, aktuelle Payloadvariable, CLR-Envelope-Kapazität, Namensmetadaten, Output-Kapazität, ToArray und ResultTable tragen kumulativ zum Bedarf an RAM, Tempdb und Log bei. MemoryStream-Wachstum kopiert zusätzlich; parallele Aufrufe multiplizieren die Ressourcen. Es gibt keine Streaming-, MemoryGrant- oder harte Fristzusage. Das kooperative Budget beginnt im CLR-Kern und prüft Copy, Parser, Kompression, Finalisierung und Output. Die SQL-Vorbereitung ist kein End-to-End-Budget; native Kompression und Allokationen sind nicht hart unterbrechbar.

Metadaten sind fest auf 1980-01-01 und Attribute 0 gesetzt. Stored ist bei identischem Input byteidentisch; Deflate hat keine Byteidentitätsgarantie über Framework- oder OS-Versionen. Ein leerer Deflate-Entry erhält den expliziten raw-Endblock `0300`, niemals einen stillen Stored-Fallback. Der Writer erlaubt hohe Kompressionsratio; der Readerdefault 200 ist unabhängig und muss gegebenenfalls explizit erhöht werden.

Release 1.3.0 koppelt Assembly, Manifest, exakten Trusthash, Bindings und Uninstall. Readersignaturen und -limits bleiben unverändert. Ein belegter vorhandener Empty-Payload-Marshallingdefekt (SqlBytes mit Länge 0 wurde im SQL-Host NULL) wird intern durch SqlBinary-FillRow korrigiert: erfolgreiche leere Payload bleibt `0x`, tatsächliches encrypted NULL bleibt NULL. Der Konstruktor `SqlBinary(byte[])` erzeugt tatsächlich eine zusätzliche begrenzte Payloadkopie beim Reader; der Value-Getter kopiert bei Zugriff erneut. Beide sind konservativ zum kumulativen Reader-Peak zu zählen. Daraus entsteht keine Beschleunigungs-, Streaming- oder MemoryGrant-Zusage. HashSet wurde wegen tatsächlicher HostProtectionException durch ein ordinales Dictionary aus mscorlib ersetzt; Trust wurde niemals erhöht. SAFE und strict security bleiben erhalten; Trust wird separat administrativ eingerichtet, Instanzänderungen erfolgen nicht. Lokale und zentrale Caller-Temps verwenden dieselbe Sitzung. Es gibt keine Rechteausweitung.

## Evidence

Der echte Framework-4.8-Build und `Writer.Framework.ps1` mit unabhängigem ZipArchive belegen synthetische Stored-/Deflate-Roundtrips einschließlich leerer Payloads, Unicode, nachgestellter Leerzeichen, Determinismus, 22-/21-Byte-Outputgrenze, Transportfehlern und parallelen Aufrufen. Das allein belegt keine SQL-SAFE-Lauffähigkeit. `Writer.Contract.sql` läuft im Adapter lokal und zentral. Historische Binaryupgrades, größere Grenzen, Transaktions-, Help- und Kollisiontests sowie plattformbezogene Labs werden separat abstrahiert protokolliert. Offene Evidence darf niemals als PASS geführt werden.

Am 2026-10-01 bestand der finale Adapter auf SQL Server 2019 unter Linux (Compatibility 150) sowie SQL Server 2025 unter Windows (Compatibility 150, 160 und 170), jeweils lokal und zentral. Der Scope enthält tatsächliche 16-MiB-Payloads mit Stored/Deflate und Hash-/Längenvergleich, leere Payloads an allen drei Reader-Ausgabegrenzen, erhaltenes encrypted NULL, tatsächliche SQLClient-Metadaten, Fehleratomarität, Callertransaktionen, Help-Vorrang sowie historische Upgrades und Lebenszyklusgrenzen. Frameworktests verarbeiten zusätzlich tatsächlich 32 MiB je Entry und 128 MiB Gesamtpayload mit 1024 Entries und 2048 Name-Codeeinheiten. Höhere SQL-Live-Ceilings, Produktionsarchive und globale Kapazitäts-/Parallelitätsgrenzen bleiben offen; `partially validated` ist weiterhin der Modulstatus.
