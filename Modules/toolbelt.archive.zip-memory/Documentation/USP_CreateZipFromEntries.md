# USP_CreateZipFromEntries

Erzeugt ein vollständig finalisiertes In-memory-ZIP aus einer vorhandenen lokalen Temp-Tabelle des Aufrufers. Implementierungsfreigabe am 2026-10-01 nach Besprechung von PR #121: „Unquoting, Split-USP und ZIP-Writer implementieren“. Datei-I/O, XLSX, TVP, ZIP64, Verzeichnis-Entries, Symlinks, Verschlüsselung und Multi-Disk sind nicht enthalten.

## Eingabe und Defaults

`@EntryTable sysname = NULL` bezeichnet eine vorhandene lokale `#Temp` mit `Ordinal int`, `EntryName nvarchar(max)` und `Payload varbinary(max)`. Zusatzspalten werden ignoriert; berechnete oder verschlüsselte Pflichtspalten sind ausgeschlossen. Nullable Spaltenmetadaten sind erlaubt, tatsächliche Werte dürfen nie NULL sein. Ordinals müssen positiv und eindeutig sein; sortiert wird aufsteigend, Lücken sind erlaubt. Eine leere Tabelle ergibt ein ZIP mit ausschließlich EOCD (22 Bytes). Input und ResultTable dürfen nicht auf dieselbe Objekt-ID aufgelöst werden.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. |
| `@CompressionMethod` | `varchar(max)` | `'Stored'` | Input | Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer. |
| `@MaxEntries` | `int` | `256` | Input | Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEnvelopeBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@WriterBudgetMilliseconds` | `int` | `30000` | Input | Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

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

## Berechtigung

Das geprüfte schmale Callerprofil benötigt `EXECUTE` auf dieser Procedure,
`SELECT` auf `toolbelt_archive.TVF_InternalZipWriterName` und
`toolbelt_archive.TVF_InternalZipWriterArchive` sowie `EXECUTE` auf
`toolbelt_core.USP_PrepareResultTable` für beide Ausgabewege. Der
[ZIP-Callerbericht](../../../Releases/1.0.0/ZIP-CALLER-PROFILE.md) begrenzt den
Nachweis; er behauptet weder mathematische Minimalität noch den Ausschluss
anderer möglicher Profile.

## Ressourcen, Transaktion, Sicherheit

HOLDLOCK stabilisiert Preflight und Snapshot innerhalb einer eigenen Transaktion oder eines Caller-Savepoints bis zur Ergebnisübergabe. Locks und Transaktionslog bleiben damit über Snapshot, Serialisierung und Kompression gehalten. Konkurrierendes MARS oder Mutieren derselben Temps wird nicht unterstützt. Ein Savepoint wird erst nach erfolgreichem SAVE als gesetzt geführt. Die vollständige Callertransaktion wird niemals zurückgerollt; ein nicht mehr committbarer Callerzustand bleibt dessen Verantwortung. Zielmutationen sind rückrollbar.

Der FAST_FORWARD-Cursor serialisiert ausschließlich den bereits geprüften, begrenzten Snapshot ordinal; er ist kein fachlicher Alternativparser. LOB-`.WRITE` vermeidet naive quadratische Komplettkonkatenation. Das Binary-Envelope enthält TBZW, Version 1 und Count, anschließend little-endian Ordinal, Namensbyteanzahl und Payloadbyteanzahl sowie strikte UTF-8-Namen und Payloads. Der SAFE-CLR-Kern ist datenzugriffsfrei und verwendet weder ContextConnection noch Dateifallback.

Snapshot, SQL-Envelope, aktuelle Payloadvariable, CLR-Envelope-Kapazität, Namensmetadaten, Output-Kapazität, ToArray und ResultTable tragen kumulativ zum Bedarf an RAM, Tempdb und Log bei. MemoryStream-Wachstum kopiert zusätzlich; parallele Aufrufe multiplizieren die Ressourcen. Es gibt keine Streaming-, MemoryGrant- oder harte Fristzusage. Das kooperative Budget beginnt im CLR-Kern und prüft Copy, Parser, Kompression, Finalisierung und Output. Die SQL-Vorbereitung ist kein End-to-End-Budget; native Kompression und Allokationen sind nicht hart unterbrechbar.

Metadaten sind fest auf 1980-01-01 und Attribute 0 gesetzt. Stored ist bei identischem Input byteidentisch; Deflate hat keine Byteidentitätsgarantie über Framework- oder OS-Versionen. Ein leerer Deflate-Entry erhält den expliziten raw-Endblock `0300`, niemals einen stillen Stored-Fallback. Der Writer erlaubt hohe Kompressionsratio; der Readerdefault 200 ist unabhängig und muss gegebenenfalls explizit erhöht werden.

Release 1.3.0 koppelt Assembly, Manifest, exakten Trusthash, Bindings und Uninstall. Readersignaturen und -limits bleiben unverändert. Ein belegter vorhandener Empty-Payload-Marshallingdefekt (SqlBytes mit Länge 0 wurde im SQL-Host NULL) wird intern durch SqlBinary-FillRow korrigiert: erfolgreiche leere Payload bleibt `0x`, tatsächliches encrypted NULL bleibt NULL. Der Konstruktor `SqlBinary(byte[])` erzeugt tatsächlich eine zusätzliche begrenzte Payloadkopie beim Reader; der Value-Getter kopiert bei Zugriff erneut. Beide sind konservativ zum kumulativen Reader-Peak zu zählen. Daraus entsteht keine Beschleunigungs-, Streaming- oder MemoryGrant-Zusage. HashSet wurde wegen tatsächlicher HostProtectionException durch ein ordinales Dictionary aus mscorlib ersetzt; Trust wurde niemals erhöht. SAFE und strict security bleiben erhalten; Trust wird separat administrativ eingerichtet, Instanzänderungen erfolgen nicht. Lokale und zentrale Caller-Temps verwenden dieselbe Sitzung. Es gibt keine Rechteausweitung.

## Evidence

Der echte Framework-4.8-Build und `Writer.Framework.ps1` mit unabhängigem ZipArchive belegen synthetische Stored-/Deflate-Roundtrips einschließlich leerer Payloads, Unicode, nachgestellter Leerzeichen, Determinismus, 22-/21-Byte-Outputgrenze, Transportfehlern und parallelen Aufrufen. Das allein belegt keine SQL-SAFE-Lauffähigkeit. `Writer.Contract.sql` läuft im Adapter lokal und zentral. Historische Binaryupgrades, größere Grenzen, Transaktions-, Help- und Kollisiontests sowie plattformbezogene Labs werden separat abstrahiert protokolliert. Offene Evidence darf niemals als PASS geführt werden.

Am 2026-10-01 bestand der finale Adapter auf SQL Server 2019 unter Linux (Compatibility 150) sowie SQL Server 2025 unter Windows (Compatibility 150, 160 und 170), jeweils lokal und zentral. Der Scope enthält tatsächliche 16-MiB-Payloads mit Stored/Deflate und Hash-/Längenvergleich, leere Payloads an allen drei Reader-Ausgabegrenzen, erhaltenes encrypted NULL, tatsächliche SQLClient-Metadaten, Fehleratomarität, Callertransaktionen, Help-Vorrang sowie historische Upgrades und Lebenszyklusgrenzen. Frameworktests verarbeiten zusätzlich tatsächlich 32 MiB je Entry und 128 MiB Gesamtpayload mit 1024 Entries und 2048 Name-Codeeinheiten. Höhere SQL-Live-Ceilings, Produktionsarchive und globale Kapazitäts-/Parallelitätsgrenzen bleiben offen; `partially validated` ist weiterhin der Modulstatus.

## Beispielaufruf

```sql
CREATE TABLE #ZipInput(Ordinal int, EntryName nvarchar(max), Payload varbinary(max)); INSERT #ZipInput VALUES(1,N'hello.txt',0x4869); EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput';
```

Die Beispiele verwenden synthetische Werte. Vorlagen mit registrierten
Handlern, Tabellen oder Dateien setzen deren beschriebene Vorbereitung voraus.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zip).
