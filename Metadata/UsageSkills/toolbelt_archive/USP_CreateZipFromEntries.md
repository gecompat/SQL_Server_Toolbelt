---
name: "toolbelt-archive-usp-createzipfromentries"
description: "Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-memory"
schema_name: "toolbelt_archive"
object_name: "USP_CreateZipFromEntries"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@EntryTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation."}, {"name": "@CompressionMethod", "sql_type": "varchar(max)", "sql_default": "'Stored'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "256", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryNameCodeUnits", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxTotalPayloadBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEnvelopeBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@WriterBudgetMilliseconds", "sql_type": "int", "sql_default": "30000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.archive.zip-memory/Source/USP_CreateZipFromEntries.sql", "Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs", "Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.4.0"
---

# USP_CreateZipFromEntries

## Zweck und Einsatzfälle

Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.

## Voraussetzungen

ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|
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
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

TechnischeDefaults ermöglichenHilfe;fachlichePflicht-NULLwertebleibenungültig. Typbindung/KürzungaufSQL-ParameterbreiteliegenvorderFachprüfung. KeineautomatischeRechte-/Root-/Identityeinrichtung.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `ArchivePayload` | `varbinary(max)` | NOT NULL; vollständigesZIPbinary |
| `ArchiveBytes` | `bigint` | NOT NULL; DATALENGTH desfinalisiertenArchivs |
| `EntryCount` | `int` | NOT NULL; AnzahlEntries,auch0 |
| `TotalPayloadBytes` | `bigint` | NOT NULL; Summe unkomprimierterEntrybytes |
| `CompressionMethod` | `int` | NOT NULL; 0Stored,8Deflate;ListekannweitereMethodenbeschreiben |

Genau einevollständigeFachzeilebeiErfolg. ResultTableNULL direkteAusgabe,sonstlokalesCallerzielohnezusätzlichenFachresultset. Hilfe liefert bisherigezwölfspaltigeStandardhilfe plusgenaueineSkillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühesRETURN0 vorFachprüfung. NormalerErfolgsreturn0. Datei-ReceiptattestiertkeinegemeinsameSQL-Atomarität.

## Aufrufbeispiele

```sql
EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #ContosoEntries VALUES(1,N'contoso.txt',0x010203);
EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche Memory-USP und gezielte SELECT-Rechte auf benötigte interne CLR-TVFs gemäß Modulvertrag. Writer braucht die ResultTable-Schnittstelle für beide Ausgaben; Reader Helper-EXECUTE nur bei ResultTable. Leserechte auf Caller-Temps und Metadatensicht für Writer, tempdb.sys.columns und spezifische sys.parameters-Sicht. Interne Kennzeichnung ist kein Verbot notwendiger Providerberechtigungen, aber kein Freibrief für allgemeine Direktnutzung. Keine Filesystemrechte für den Memorypfad.

## Ressourcenbedarf

Writergrenzen:Entries1..1024, Namen1..2048Codeunits, Entry1..33554432, Summe1..134217728, ZIP1..150994944, Envelope1..142606336, Budget1..60000ms. Readergrenzen:268435456Archivbytes,10000Entries,1024Namenseinheiten, komprimiert134217728, extrahiert maximal67108864. Reader hat keinen eigenen Timer. Snapshot-, Envelope-, Seek- und Transportkopien, Deflatepuffer und CRC kosten zusätzlich Speicher/CPU. Kooperatives Writerbudget ist keine harte Wallclock-, Heap- oder SQL-Transportquote.

## Nebenwirkungen

Die öffentliche Fassade normalisiert KeepData/Debug/Hilfe bei NULL zu 0 und liefert frühe Hilfe. Sie prüft Stored/Deflate byte- und längengenau, endliche Ressourcenlimits und die beiden Writer-TVFs. Die fünfparametrige PrepareResultTable-Schnittstelle wird auch ohne Ausgabeziel geprüft. Input und Output müssen verschiedene sichtbare lokale Caller-Temps ohne Punkt oder ## sein; Writer-Helpernamen sind reserviert. Inputspalten: Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed oder verschlüsselt. Geprüft werden system_type_id/max_length, kein zusätzlicher user_type_id-Gleichheitsguard. LEN-Namensgrenzen folgen SQL-Space-Semantik.

Doomed Caller werden abgewiesen. Eigene Transaktion oder eigener Savepoint; HOLDLOCK stabilisiert Preflight und Snapshot. Keine parallele MARS-/Caller-Mutation derselben Temps. Positive eindeutige Ordinals, nichtNULL-Fachwerte, Count-, Entry- und Summengrenzen vor privater Payloadkopie prüfen. Die Name-TVF codiert wohlgeformtes UTF16 streng nach UTF8. Duplikate nach exakten Namensbytes und Länge abweisen. Envelopegröße:12+Payloadsumme+16*Count+Namensbytes. In Ordinalreihenfolge Little-endian-TBZW-V1-Envelope mittels lokaler LOB-.WRITE-Operationen bilden.

Die Archive-TVF kopiert den begrenzten Envelope einmal in eigenen seekbaren Speicher. Header, Version, Count, steigende Ordinals, UTF8-Namen, Ressourcen und Restfreiheit prüfen. Stored0 oder Deflate8; CRC32 bei Payloadverarbeitung, UTF8-Flag und feste DOS-Zeit1980-01-01. Lokale Header nachtragen, CentralDirectory und EOCD finalisieren. Keine ZIP64-, Multi-Disk-, Encryption-, Verzeichnisentry- oder Extrafeldunterstützung. Leere Eingabe erzeugt ein22Byte-EOCD-ZIP. Der kooperative CLR-Timer umfasst Kopie, Writer und Finalisierung; SQL-Preflight, Envelopebau und Ergebnistransport liegen außerhalb.

Eine Writer-Statuszeile: ErrorNumber0 und nichtNULL-Payload bei Erfolg. Die Fassade prüft den Status und materialisiert fünf Ergebnisfelder. Optionales Helper-DDL/INSERT gehört zur Transaktion beziehungsweise zum Savepoint. Eigener Commit vor Abschluss-PRINT und direkter Ausgabe; im CATCH eigener Rollback oder committable eigener Savepointrollback. Kein Dateizugriff. Writer-Namenslimit2048 und Readerlimit1024 sind verschieden. Deflatebytes haben keine pauschale plattformübergreifende Bitgleichheitszusage.

## Fehlerbehandlung

Reader:51320 Argumente,51321 Struktur/Encoding/Stream,51322 Name fehlt,51323 gesuchter Name doppelt,51324 Encryption verboten,51325 Ressourcen,51326 Ratio,51327 Format/Method,51328 Integrität,51329 Wrapper/Dependency. Writer:51350 Argumente,51351 SQL-Inputshape,51352 Name,51353 Namensduplikat,51354 Ressourcen,51355 Format/Overflow,51356 Timeout,51357 Dependency,51358 Transport,51359 Providerstatus. Status-TVFs wandeln nur explizit gefangene Fehler um; unerwartete CLR-/Enginefehler bleiben Originalexceptions. Reader-ErfolgNULL, Writer-Erfolg0. Öffentliche Fassaden werfen statt einer Teilpayload.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/ZIP-/Dateipublikationsabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. CRC32, Status und PathSafe sind keine Signatur, Malwareprüfung oder Herkunftsauthentifizierung. Kein allgemeiner ZIP64-, Encryption-, Streaming- oder Mehrdatei-Unpacker. Keine Installations- oder Rechteattestation. ZIPnamen, Payloads, Dateipfade und Runtimebefunde privat halten.
