---
name: "toolbelt-archive-tvf-internallistzipentriesclr"
description: "Interner strukturgeprüfter ZIP-Metadatenprovider ohne Payload-CRC-Prüfung."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-memory"
schema_name: "toolbelt_archive"
object_name: "TVF_InternalListZipEntriesClr"
object_type: "CLR_TVF"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@ZipArchive", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl 1..10000 Central-Directory-Entries, öffentlicher Fassaden-Default 10000. NULL/0/negativ/höher ungültig. Überschreitung verwirft den gesamten Aufruf, kein gültiges TOP-Präfix; keine Payloadextraktion durch dieses Limit. Kein SQL-Default im internen Einstieg; Argument explizit übergeben."}]
source_paths: ["Modules/toolbelt.archive.zip-memory/Source/TVF_InternalListZipEntriesClr.sql", "Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs", "Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs"]
review_status: "verified"
source_module_version: "1.4.0"
public_entrypoints: ["toolbelt_archive.USP_ListZipEntriesFromBinary"]
---

# TVF_InternalListZipEntriesClr

## Zweck und Einsatzfälle

Interner strukturgeprüfter ZIP-Metadatenprovider ohne Payload-CRC-Prüfung.

## Voraussetzungen

ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | kein Default | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@MaxEntries` | `int` | kein Default | Input | Ganzzahl 1..10000 Central-Directory-Entries, öffentlicher Fassaden-Default 10000. NULL/0/negativ/höher ungültig. Überschreitung verwirft den gesamten Aufruf, kein gültiges TOP-Präfix; keine Payloadextraktion durch dieses Limit. Kein SQL-Default im internen Einstieg; Argument explizit übergeben. |

InternerCLR-Einstieg:alleArgumenteexplizit,keineSQL-Defaults,keinHilfe-/ResultTableparameter. ÖffentlicheFassadebevorzugen;notwendigegezielteProvider-SELECT-Rechtebleibenmodulabhängig.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `ErrorNumber` | `int` | NULL; Writer0=Erfolg;ReaderNULL=Erfolg;sonst erwarteterFehlercode |
| `ErrorMessage` | `nvarchar(4000)` | NULL; NULL beiErfolg,erwarteteFehlermeldungbeiFehler |
| `EntryOrdinal` | `int` | NULL; 1-basierteCentralDirectory-Reihenfolge |
| `EntryName` | `nvarchar(1024)` | NULL; unveränderterdecodierterZIPname |
| `IsDirectory` | `bit` | NULL; Name endet mitSlashoderBackslash |
| `CompressedBytes` | `bigint` | NULL; deklariertekomprimierteBytes |
| `UncompressedBytes` | `bigint` | NULL; deklarierteentpackteBytes |
| `CompressionMethod` | `int` | NULL; 0Stored,8Deflate;ListekannweitereMethodenbeschreiben |
| `Crc32` | `int` | NULL; CRC32-Bitmuster als signedint,negativeWerte sindgültig |
| `IsEncrypted` | `bit` | NULL; Verschlüsselungsflag,keineEntschlüsselungszusage |
| `IsExtractionSupported` | `bit` | NULL; nurMethod0/8undnichtEncrypted,keinvollständigerExtraktionsbeweis |
| `DuplicateCount` | `int` | NULL; ordinaleNamenshäufigkeit |
| `IsPathSafe` | `bit` | NULL; lexikalischePfadklasse safe,keineWindowsautorisierung |
| `PathStatus` | `nvarchar(32)` | NULL; safe/absolute/drive-qualified/parent-traversal/noncanonical |
| `LastModifiedAt` | `datetime2(0)` | NULL; DOS-ZeitohneZeitzone,unbekannt/ungültigNULL |

Reader-Liste:nullbisMaxEntries Datenzeilen beiErfolg,beiFehlergenaueineStatuszeilemitFehlercodeundNULLDaten.

## Aufrufbeispiele

```sql
-- InternerProvider:öffentlicheFassadeverwenden.
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche Memory-USP und gezielte SELECT-Rechte auf benötigte interne CLR-TVFs gemäß Modulvertrag. Writer braucht die ResultTable-Schnittstelle für beide Ausgaben; Reader Helper-EXECUTE nur bei ResultTable. Leserechte auf Caller-Temps und Metadatensicht für Writer, tempdb.sys.columns und spezifische sys.parameters-Sicht. Interne Kennzeichnung ist kein Verbot notwendiger Providerberechtigungen, aber kein Freibrief für allgemeine Direktnutzung. Keine Filesystemrechte für den Memorypfad.

## Ressourcenbedarf

Writergrenzen:Entries1..1024, Namen1..2048Codeunits, Entry1..33554432, Summe1..134217728, ZIP1..150994944, Envelope1..142606336, Budget1..60000ms. Readergrenzen:268435456Archivbytes,10000Entries,1024Namenseinheiten, komprimiert134217728, extrahiert maximal67108864. Reader hat keinen eigenen Timer. Snapshot-, Envelope-, Seek- und Transportkopien, Deflatepuffer und CRC kosten zusätzlich Speicher/CPU. Kooperatives Writerbudget ist keine harte Wallclock-, Heap- oder SQL-Transportquote.

## Nebenwirkungen

Dieser interne Einstieg führt nur den beschriebenen CLR-Providerteil aus. Die zusätzlichen SQL-Validierungen, Transaktionen und das Routing liegen in der öffentlichen Fassade und werden hier nicht nachgebildet.

Die öffentliche Fassade normalisiert KeepData/Debug/Hilfe bei NULL zu0, bei Extraktion FailIfEncrypted bei NULL zu1, und liefert frühe Hilfe. Nichtleeres Archiv und Argumente prüfen. Der interne Reader akzeptiert höchstens268435456Archivbytes,10000Entries und1024Namenseinheiten. Nichtseekender Input wird begrenzt in eigenen seekbaren Speicher kopiert, ohne Dateifallback. EOCD am Archivende mit Kommentargröße prüfen; kein ZIP64 oder Multi-Disk. CentralDirectory muss exakt bis EOCD reichen. Alle Datensätze und LocalHeader werden auf Flags, Method, rohe Namensbytes und Größen-/Payloadbereiche geprüft. UTF8 bei Flag11, sonst CP437, jeweils streng. Auch ein unbeteiligter defekter Header kann Einzelextraktion verhindern.

Liste: CentralDirectory-Reihenfolge ab Ordinal1, ordinale Duplikatanzahl, unveränderte lexikalische Pfadklasse und DOS-Zeit ohne Zeitzone; ungültige Zeit wird NULL. Keine Dekompression oder Prüfung aller Payload-CRCs. IsExtractionSupported bedeutet nur Method0/8 und nicht verschlüsselt; CRC, Quoten, Duplikate und PathSafe werden damit nicht attestiert. Ein Leerarchiv liefert null Zeilen. Ein erwarteter Fehler liefert eine einzelne Statuszeile statt einer gemischten Teilmenge.

Extraktion: genau ein ordinal gleicher Name, sonst51322/51323. Encrypted mit Fail1 ergibt51324. Fail0 liefert nur Metadaten mit IsEncrypted1 und PayloadNULL, vor Method-, Payloadgrößen-, Ratio- und CRC-Extraktionsprüfung. Die LocalHeader sind zu diesem Zeitpunkt bereits indexseitig geprüft. Sonst nur Method0/8, komprimiert höchstens134217728 und entpackt bis MaxEntryBytes≤67108864; Ratio vor und während der Dekompression. Exakter deklarierter Zielbuffer, bounded Kompressionsstream, Endlänge und CRC32 prüfen. Echte leere Payload bleibt0x durch SqlBinary. Binaryextraktion nutzt den Entrynamen nicht als Dateisystemziel und lehnt ihn nicht allein wegen PathStatus ab.

Reader-Erfolg verwendet ErrorNumberNULL, nicht die Writer-Konvention0. Erwartete Struktur-, Stream- und Decoderfehler werden Statuszeilen; unerwartete CLR-/Enginefehler bleiben Exceptions. Die Fassade prüft Status/Shape und entfernt Fehlerfelder aus der Fachausgabe. Kein eigener TX, Savepoint oder XACT_ABORT im Readerwrapper. ResultTablehelper erst nach vollständiger Prüfung und nur bei Ausgabeziel; dessen Vertrag und Caller-TX bestimmen die Rollbackwirkung. Debug wird nur an den Helper weitergegeben.

## Fehlerbehandlung

Reader:51320 Argumente,51321 Struktur/Encoding/Stream,51322 Name fehlt,51323 gesuchter Name doppelt,51324 Encryption verboten,51325 Ressourcen,51326 Ratio,51327 Format/Method,51328 Integrität,51329 Wrapper/Dependency. Writer:51350 Argumente,51351 SQL-Inputshape,51352 Name,51353 Namensduplikat,51354 Ressourcen,51355 Format/Overflow,51356 Timeout,51357 Dependency,51358 Transport,51359 Providerstatus. Status-TVFs wandeln nur explizit gefangene Fehler um; unerwartete CLR-/Enginefehler bleiben Originalexceptions. Reader-ErfolgNULL, Writer-Erfolg0. Öffentliche Fassaden werfen statt einer Teilpayload.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/ZIP-/Dateipublikationsabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. CRC32, Status und PathSafe sind keine Signatur, Malwareprüfung oder Herkunftsauthentifizierung. Kein allgemeiner ZIP64-, Encryption-, Streaming- oder Mehrdatei-Unpacker. Keine Installations- oder Rechteattestation. ZIPnamen, Payloads, Dateipfade und Runtimebefunde privat halten.
