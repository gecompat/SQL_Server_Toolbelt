---
name: "toolbelt-toolbelt-toolbelt-file-usp-loadbinaryfile"
description: "Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen."
skill_format_version: "1.0"
module_id: "toolbelt.file.content"
schema_name: "toolbelt_file"
object_name: "USP_LoadBinaryFile"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@FilePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox."}, {"name": "@MaxBytes", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Pfad-/Transaktions-/Temp-/Root-/Dateiarbeit. 0/NULL: Fachaufruf. Alle Parameter besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql", "Modules/toolbelt.file.content/Source/FileContentRootPredicate.sql", "Modules/toolbelt.file.content/Source/FileContentRootAllowlist.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_LoadBinaryFile

## Zweck und Einsatzfälle

Liest eine erlaubte Datei über genau einen serverseitigen OPENROWSET(BULK,SINGLE_BLOB)-Zugriff als unveränderte varbinary(max)-Bytes. Kein Dateischreiben oder Clientdatei-Upload.

## Voraussetzungen

SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. Datenbanktabelle mit administrativ gepflegtem aktivem Root. Provider-/Plattform-/OS-Leserechte unabhängig von Rootfreigabe erfüllen. Für ResultTable sameDB core.result-table>=1.0.0. Aktueller gemeinsamer Offlinebuilder expandiert FileContentRootPredicate.sql in normale SQL-DDL; rohe Source-Prozedurdatei enthält noch :r-Quellinclude und ist kein direkt unverändert auszuführender SQLCMD-freier Installer. Eingabepfad LTRIM/RTRIM normaler Spaces und NULLIF leer; dann zwei REPLACE-Schritte für doppelte/einfache Backslashes nach Slash nur für den Allowlistvergleich. Absolutheit nach Laufwerkbuchstabe:/ oder führendem /; geprüftes ../-Traversal wird abgewiesen, keine vollständige OS-Kanonisierung aller Punkt-/Device-/Aliasformen. Aktive Roots werden ebenfalls slashnormalisiert, nicht generell getrimmt. Vergleich literal BIN2 an exakter Rootlänge oder Verzeichnisgrenze mit angehängtem /; Prozent/Unterstrich/Klammern sind dort keine Wildcards. Ein exakter Rootpfad selbst kann zugelassen sein, nicht nur dessen Kinder. Keine Symlink-/Junction-/Hardlink-/Handleprüfung; tatsächlicher BULK-Aufruf liest den getrimmten Originalpfad. Keine handlegebundene Sandbox oder TOCTOU-/Dateisystemidentitätsgarantie.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
| `@MaxBytes` | `bigint` | `NULL` | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Pfad-/Transaktions-/Temp-/Root-/Dateiarbeit. 0/NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

## Ergebnisse

Content varbinary(max) NULL, BytesRead bigint NOT NULL, IsValid bit NOT NULL, ValidationCode int NULL, ValidationMessage nvarchar(4000) NULL. Genau eine fachliche Zeile bei normalem Abschluss. Erfolg IsValid=1 und NULL-Fehlerfelder; fachliche Ablehnung IsValid=0, Content=NULL und Code/Text. BytesRead zählt gelesene Rohbytes einschließlich BOM, bei Pfad-/Rootprüfung vor dem Lesen 0. RETURN 0 bedeutet auch bei IsValid=0 nur normalen Prozedurabschluss; Status unbedingt auswerten. Kein fachlicher OUTPUT-Parameter. ResultTable=NULL SELECT, sonst Ziel-INSERT mit demselben Schema. Hilfe liefert zuerst Standardhilfe und zusätzlich genau eine Zeile SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max),vor Fachausführung.

## Aufrufbeispiele

```sql
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath=N'C:\Contoso\Input\example.bin',@MaxBytes=1048576;
-- Synthetischer serverseitiger Pfad; aktiver Root und vorhandene Rechte nötig.
-- IsValid/ValidationCode prüfen; MaxBytes ist kein Vorallokationslimit.
EXEC toolbelt_file.USP_LoadBinaryFile @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf der öffentlichen USP und gültige Abhängigkeitsrechte auf die Allowlist. Zusätzlich für die konkrete SQL-Server-Version/Plattform ausreichende Bulkberechtigung (ADMINISTER BULK OPERATIONS bzw. ADMINISTER DATABASE BULK OPERATIONS, soweit unterstützt) und Lesezugriff des tatsächlich wirksamen Dateisystem-Sicherheitskontexts. Bei SQL-Authentifizierung ist regelmäßig der SQL-Server-Prozesskontext relevant, bei Windows-Anmeldung der passende delegierte Kontext. Linux-/Patchbesonderheiten separat beachten; kein versionsunabhängiger Minimalrechte-PASS behauptet. Eine Ad-hoc-Konfigurationsoption ersetzt keine Rechte. Die Procedure erteilt nichts und aktiviert keine Serveroption. [Microsoft-Bulkvertrag](https://learn.microsoft.com/en-us/sql/t-sql/functions/openrowset-bulk-transact-sql?view=sql-server-ver17), [Dateizugriffskontext](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/prepare-data-for-bulk-export-or-import-sql-server). Routing zusätzlich vorhandene Helper-/Temp-Rechte; keine neue Privilegienvergabe im Aufruf.

## Ressourcenbedarf

Pfadargument nvarchar(4000), aber aktuelles BULK-Literal nutzt QUOTENAME mit sysname-Grenze128; längere Pfade sind nicht als funktionierend belegt und können durch NULL-SQL in technischen Fehler münden. Ein vollständiger SINGLE_BLOB-Snapshot vor eigener MaxBytes-Prüfung. MaxBytes=NULL/0 deaktiviert Prüfung; positiv begrenzt erst das bereits gelesene Ergebnis; negativ ist nicht vorab Argumentfehler, sondern führt für gelesene nichtnegative Bytegröße zu Status51323. Kein I/O-,Heap-,CPU-/Wallclock-Vorabcap und kein Streaming. Gelesener varbinary(max)-LOB und privates Ergebnis können Speicher/TempDB beanspruchen. SQL-LOB-/Providergrenzen bleiben wirksam; kein erfolgreicher gekürzter Inhalt als Größenersatz.

## Nebenwirkungen

SET NOCOUNT ON, Hilfe NULL=>0 vor frühem Hilfezweig. Im Fachpfad private Ergebnistemp, KeepData/Debug NULL=>0. Nur bei ResultTable SET XACT_ABORT OFF und kontrollierter eigener Transaktionsscope oder zufälliger Caller-Savepoint; uncommittable bestehender Caller wird vorher abgewiesen. Wichtig: ResultTable-Helper bereitet/ersetzt das Ziel VOR Pfad-/Encoding-/Rootprüfung und Datei-I/O. Eine normale IsValid=0-Statuszeile wird regulär eingefügt/committed und kann vorherige Zieldaten bei KeepData=0 ersetzen. Das ist kein nebenwirkungsfreier Argumentfehler. Technischer Fehler rollt eigene Transaktion oder committable Caller-Savepoint zurück; fremde Transaktion nie vollständig committen/rollbacken. Rollbackfehler nicht separat geschützt. Ohne ResultTable kein eigener BEGIN/COMMIT. Kein Dateischreiben, jedoch tatsächliches Datei-/gegebenenfalls UNC-Netzwerklesen im wirksamen Serverkontext. Debug nur an den ResultTable-Helper weitergereicht, keine eigene Inhaltsdiagnose.

## Fehlerbehandlung

Fachliche Statuscodes, kein THROW:51320 Pfad leer/NULL/nicht absolut;51322 erkannte Parent-Traversalsegmente;51321 kein aktiver passender Root;51323 Bytezahl nach Lesen über MaxBytes. Technischer THROW51326 für Provider-/innere Readfehler mit übernommenem gekürztem Engine-ERROR_MESSAGE (bis1700 Zeichen, Prozentzeichen escaped). Fehlermeldung kann reale Pfade/Umgebungsdetails enthalten, privat behandeln. 51908 fehlender ResultTable-Helper und51028 ungeeigneter Callerzustand bleiben technische Fehler; sonstige Engine-/Binding-/Helperfehler ebenfalls sichtbar. Für Statusfehler nicht allein auf RETURN0 vertrauen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Datei-I/O-/Minimalrechte-/Skill-/Installerabnahme. Historische Nachweise behalten ihre ursprüngliche Bindung. Dateiinhalt, Pfade und Providerfehlermeldungen können vertrauliche Umgebungsdaten enthalten; nicht veröffentlichen. Keine Installation-/Rechteattestation, keine unbegrenzte Kapazität oder Garantie eines stabilen Dateisystems.
