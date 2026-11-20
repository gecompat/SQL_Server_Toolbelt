---
name: "toolbelt-fs-clr-list-directory"
description: "Interner Windows-CLR-Provider zum begrenzten Auflisten von Dateien und Verzeichnissen."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "CLR_ListDirectory"
object_type: "CLR_USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "N''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@Recursive", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: nur direktes Verzeichnis. 1 traversiert Unterverzeichnisse innerhalb der expliziten Grenzen. NULL ist für CLR-bool nicht unterstützt."}, {"name": "@MaxDepth", "sql_type": "int", "sql_default": "32", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Startverzeichnis hat Tiefe 0. Listing akzeptiert 0..64, Entfernung nur die Untergrenze 0 ohne eigene feste Obergrenze. Rekursiv nötiger Abstieg jenseits der Grenze ist ein Fehler, keine stille Kürzung. Default 32; NULL ist für CLR-int nicht unterstützt."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Default 10000. Listing akzeptiert 1..10000; Entfernung prüft nur >=1 ohne eigene feste Obergrenze. Überschreitung ist ein Fehler, keine gekürzte Erfolgsmenge. NULL ist für CLR-int nicht unterstützt."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_ListDirectory"]
---

# CLR_ListDirectory

## Zweck und Einsatzfälle

Interner Windows-CLR-Provider zum begrenzten Auflisten von Dateien und Verzeichnissen. Internes Implementierungsdetail. Regulär die öffentliche USP_ListDirectory mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.

## Voraussetzungen

Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowList erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
| `@RelativePath` | `nvarchar(4000)` | `N''` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
| `@Recursive` | `bit` | `0` | bit, Default 0: nur direktes Verzeichnis. 1 traversiert Unterverzeichnisse innerhalb der expliziten Grenzen. NULL ist für CLR-bool nicht unterstützt. |
| `@MaxDepth` | `int` | `32` | Startverzeichnis hat Tiefe 0. Listing akzeptiert 0..64, Entfernung nur die Untergrenze 0 ohne eigene feste Obergrenze. Rekursiv nötiger Abstieg jenseits der Grenze ist ein Fehler, keine stille Kürzung. Default 32; NULL ist für CLR-int nicht unterstützt. |
| `@MaxEntries` | `int` | `10000` | Default 10000. Listing akzeptiert 1..10000; Entfernung prüft nur >=1 ohne eigene feste Obergrenze. Überschreitung ist ein Fehler, keine gekürzte Erfolgsmenge. NULL ist für CLR-int nicht unterstützt. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |

## Ergebnisse

Null bis MaxEntries Zeilen: EntryOrdinal bigint ab 1, RelativePath nvarchar(4000) relativ zum Root, EntryType varchar(16) file oder directory, SizeBytes bigint (Verzeichnis 0), LastWriteTimeUtc datetime2, IsReparsePoint bit. Keine zugesicherte alphabetische Sortierung oder stabile Reihenfolge zwischen Aufrufen. Keine OUTPUT-Parameter. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.

## Aufrufbeispiele

```sql
-- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- Regulärer öffentlicher Einstieg für diese Operation:
EXEC toolbelt_filesystem.USP_ListDirectory @Hilfe=1;
-- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
EXEC toolbelt_filesystem.CLR_ListDirectory @RootAlias=N'ContosoRead',@RelativePath=N'',@Recursive=0,@MaxEntries=100;
```

## Rechte

Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.

## Ressourcenbedarf

Sammelt die vollständige begrenzte Liste vor SendResultsStart. Höchstens 10000 Einträge und 16 MiB aufsummierter relativer UTF-16-Pfadtext. Rekursionsgrenze 64; Verzeichnisqueue und native Handles zusätzlich. Limitüberschreitung liefert keinen gekürzten Erfolg.

## Nebenwirkungen

Nur lesende Verzeichnis-/Dateimetadatenabfragen. Kein Snapshot; parallele Dateisystemänderungen können Fehler oder abweichende Metadaten verursachen. Ausgabefehler nach SendResultsStart können bereits gesendete Zeilen nicht zurücknehmen.

## Fehlerbehandlung

Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.

## Aussagegrenzen

Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
