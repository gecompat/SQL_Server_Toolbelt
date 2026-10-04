# ZIP-Dateifassaden 1.0 – öffentlicher Vertrag

## Freigabe und Stand

Die beiden APIs wurden am 2026-10-01 einzeln besprochen und ausdrücklich
freigegeben; siehe [BACKLOG](../../.ai/BACKLOG.md#zip-datei-io-zwei-windows-fassaden).
Die technische Konkretisierung ist innerhalb dieses Scopes genehmigt.
Modul `toolbelt.archive.zip-files` 1.0.0: genau zwei öffentliche T-SQL-P-Slots
im bestehenden Schema `toolbelt_archive`. Source vorhanden; begrenzte native
Windows-local-Teilnachweise vorhanden, vollständige Qualifikation offen;
unveröffentlicht. Keine Assembly, kein weiterer ZIP-Kern.

## Dependencies und Deployment

Objektmarker werden rollenbezogen nur dort verlangt, wo der bestehende
Dependencyvertrag sie tatsächlich erzeugt (`RequireObjectMarkers`). Alle vier
Dependencies benötigen weiterhin ihren exakten P-Slot und den kanonischen
DB-Versionsmarker mindestens in der angegebenen Version. ZIP und ResultTable
behalten den DB-Modemarker `local`; nur Core verlangt zusätzlich den
Objektmodemarker. Keine Marker werden ergänzt oder repariert.

| Dependency-P | Minimum | Objekt-ModuleId/ModuleVersion |
|---|---|---|
| `USP_CreateZipFromEntries` | ZIP1.4.0 | erforderlich |
| `USP_ExtractZipEntryFromBinary` | ZIP1.4.0 | Legacyreader ohne Pflichtmarker |
| `USP_WriteBinaryFile` | Filesystem1.0.0 | bestehende Form ohne Pflichtmarker |
| `USP_PrepareResultTable` | ResultTable1.0.0 | erforderlich |


Windows ausschließlich local: ZIP Memory >=1.4.0, Windows Filesystem
>=1.0.0 und ResultTable >=1.0.0 in derselben DB. Drei bestehende öffentliche
USPs werden statisch aufgerufen; Providerconsumer bleiben dadurch im Katalog.
Deployment führt denselben Metadaten-/Dependency-/Zwei-P-Releasegate vor
Mutation und frisch unter transaktionsgebundenem AppLock aus. Nur bekannte
1.0.0-Slots werden wiederholt; kein fremder P/PC, keine partiellen oder
unbekannten Marker werden adoptiert. Uninstall prüft gleiche eigene Marker
und sichtbare same-database Consumer und entfernt nur eigene P-Slots und
DB-Modulmarker. Dependencies, Schema, Assemblys, Trust, Root-Aliase und Dateien
bleiben erhalten. Vorhandene DDL-/Metadatenrechte verwenden; keine GRANTs,
kein EXECUTE AS, keine Owner-, Config- oder Truständerung.

Exakte Binary-/Trustbindung bleibt administrative Aufgabe der Providermodule,
keine automatische Installation. Normale Runtime benötigt keine zusätzliche
administrative Hash- oder DB-weite Sichtpflicht. Lifecycle benötigt vorhandenes
DB-VIEW DEFINITION, SELECT auf sys.sql_expression_dependencies und Sicht auf
sys.dm_os_host_info sowie DDL-Rechte; fehlende Sicht bricht vor Mutation ab.

## API

Feste Reihenfolge und Defaults:
[Create](../../Modules/toolbelt.archive.zip-files/Documentation/USP_CreateZipFileFromEntries.md),
[Extract](../../Modules/toolbelt.archive.zip-files/Documentation/USP_ExtractZipEntryToFile.md).
Standardtail: ResultTable, KeepData, Debug, Hilfe. Hilfe zuerst, auch bei
aktiver/doomed Callertransaktion; Control-NULL Hilfe/Debug/KeepData wird 0.
Overwrite und ExecutionIdentity unverändert an den Filesystemprovider:
Caller als Default, ServiceAccount nur ausdrücklich, kein Fallback.
Fachliche Aufrufe lehnen aktive Caller-TX vor Temp-/ZIP-/Dateiarbeit ab.

Create übernimmt die vorhandene lokale Entry-#Temp mit Ordinal int,
EntryName nvarchar(max), Payload varbinary(max). Positive eindeutige
Ordinals und keine NULLs; Zusatzspalten ignoriert der Writer.
Namens-, Encoding-, Duplikat-, Reihenfolge- und Stored/Deflate-Regeln bleiben
im Writer. Extract entnimmt genau einen ordinal benannten Entry mit
FailIfEncrypted=1. NULL/encrypted Payload wird niemals zu 0x umgedeutet.
Ein erfolgreicher leerer Entry erzeugt eine **0-Byte-Datei**; leere Entryliste
erzeugt das vollständige 22-Byte-Leerarchiv. Keine zusätzliche Encryption-API.

Ziel ausschließlich RootAlias und expliziter RelativePath. Entrynames werden
nie zu Pfaden. Zielverzeichnis muss bestehen: keine mkdir-, absolute/UNC-,
Reparse- oder Root-Umgehung.

## Grenzen und Ergebnis

Writerdefaults/Ceilings unverändert: 256/1024 Entries, 1024/2048
UTF-16-Name-Codeeinheiten, 16/32 MiB je Entry, 64/128 MiB Payloadsumme,
71303168/150994944 Archivbytes, 71303168/142606336 Envelopebytes und
30000/60000 ms kooperatives Writerbudget. Readerdefault 104857600 Entrybytes,
maximal 2147483647; Ratio default 200.00, mindestens 1. Providergrenzen
268435456 Archivbytes, 134217728 komprimierte Entrybytes und 10000 Entries.
Vererbte Limits sind keine Kapazitäts-, Heap- oder harte Gesamtfristzusage.
Vollständige Materialisierung bleibt erforderlich.

Eine Filesystem-Erfolgszeile: BytesWritten bigint NOT NULL,
RootAlias nvarchar(128) NOT NULL, RelativePath nvarchar(4000) NOT NULL,
State varchar(16) NOT NULL. State unverändert completed aus WriteBinaryFile.
ResultTable=NULL: genau ein SELECT; vorhandene lokale Caller-Temp:
kein fachliches SELECT. KeepData Replace/Append, RETURN 0, Debug nur Messages.

## Eigene Brücken und Fehlergrenze

ResultTable 1.0 lehnt Zielnamen mit #tbx_ ab. Die technische Codex-Entscheidung vom 2026-10-04 innerhalb des bereits
freigegebenen Zwei-Fassaden-Scopes zur engen Namingausnahme umfasst nur #ZipFiles_CreateStage,
#ZipFiles_ExtractStage und #ZipFiles_WriteStage als eigene feste Brücken-
Zieltemps dieser zwei Fassaden. Alle drei Namen werden vor CREATE auf
Objekt-IDs geprüft; niemals adoptieren oder fremde Temps entfernen.
Input/Caller-ResultTable dürfen sie nicht referenzieren. Andere interne
Temps bleiben #tbx_; eigenes Procedure-Scope-Cleanup. Keine Coreänderung,
siehe [Naming](../Standards/SQL_OBJECT_NAMING.md#interne-lokale-temp-objekte).

Vor Dateiarbeit: exakt eine vollständige Writer-/Readerzeile,
Payload NOT NULL und plausible Größen-/Encryption-/CRC-Metadaten.
Staging und Publish allein durch bestehenden Filesystemprovider.
Kein verschachteltes INSERT EXEC im neuen Modul.

**Keine gemeinsame SQL-/Dateisystematomarität:** Nach Publish können
SQL-Ausgabe, Schemaumbau, Insert/Constraint oder Client/Verbindung scheitern;
Datei bleibt bestehen. PrepareResultTable und Insert gemeinsam in eigener
später SQL-TX; frühere SQL-Zieldaten bleiben bei Fehler erhalten.
Kein kompensierender Delete. Fehler beweist keine Dateiabsenz; Zielzustand
vor Retry klären. ZIP-Vorbereitungsfehler beginnen keine Dateiarbeit.
NoOverwrite/Overwrite, Race/NTFS/Stagecleanup beim Filesystemprovider;
kein unsicherer Direct-Write-Fallback.

54620 INVALID_FACADE_ARGUMENT; 54621 CALLER_TRANSACTION_UNSUPPORTED;
54622 DEPENDENCY; 54623 INTERNAL_RESULT_INVALID; 54624 PRIVATE_TEMP_COLLISION:
State1, Prefix TBX_ZIP_FILE_. Lifecycle State1: 54631 Argument/Plattform,
54632 Sicht, 54633 Dependency, 54634 Release/Kollision, 54635 AppLock,
54636 Installation, 54637 Consumer. Bestehende ZIP-/Filesystem-/Helper-/
Enginefehler per THROW erhalten. Sekundärer eigener Rollbackfehler als feste
separate Message, kein Primärfehlerersatz. Keine Rohmessageauswertung.

## Offene Pflichtnachweise

[Tests](../../Modules/toolbelt.archive.zip-files/Tests/README.md) und
[Matrix](../../Modules/toolbelt.archive.zip-files/Tests/ZIP_FILES_TEST_MATRIX.md)
trennen Sourcekontrollen, elf erfolgreiche Fälle früherer Teilabläufe und zwei
anschließend gezielt erfolgreiche AppLock-Aliasfälle auf Windows2025/CU8
CL170 mit identischen Produktbytes. Kein gemeinsamer 13-Fälle-Erfolgslauf;
historische Fehlstatus bleiben erhalten. Kein vollständiger Modul-/NTFS-,
Linux/Central-, Race-/Minimalrechte-, Extremgrößen- oder aktueller Head-CI-Nachweis.

Lifecycle prüft zusätzlich vor Mutation und unter AppLock kollationgleiche
anders geschriebene Slotnamen und weist sie mit 54634/state1 ab; bekannte
Slotnamen und Marker bleiben bytegenau. Kein CREATE OR ALTER fremder Aliase.
