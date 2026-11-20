---
name: "toolbelt-fs-clr-remove-directory"
description: "Interner Windows-CLR-Provider zum geplanten begrenzten Löschen eines relativen Verzeichnisses."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "CLR_RemoveDirectory"
object_type: "CLR_USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@Recursive", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: nur direktes Verzeichnis. 1 traversiert Unterverzeichnisse innerhalb der expliziten Grenzen. NULL ist für CLR-bool nicht unterstützt."}, {"name": "@MaxDepth", "sql_type": "int", "sql_default": "32", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Startverzeichnis hat Tiefe 0. Listing akzeptiert 0..64, Entfernung nur die Untergrenze 0 ohne eigene feste Obergrenze. Rekursiv nötiger Abstieg jenseits der Grenze ist ein Fehler, keine stille Kürzung. Default 32; NULL ist für CLR-int nicht unterstützt."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Default 10000. Listing akzeptiert 1..10000; Entfernung prüft nur >=1 ohne eigene feste Obergrenze. Überschreitung ist ein Fehler, keine gekürzte Erfolgsmenge. NULL ist für CLR-int nicht unterstützt."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_RemoveDirectory"]
---

# CLR_RemoveDirectory

## Zweck und Einsatzfälle

Interner Windows-CLR-Provider zum geplanten begrenzten Löschen eines relativen Verzeichnisses. Internes Implementierungsdetail. Regulär die öffentliche USP_RemoveDirectory mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.

## Voraussetzungen

Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowDelete erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
| `@Recursive` | `bit` | `0` | bit, Default 0: nur direktes Verzeichnis. 1 traversiert Unterverzeichnisse innerhalb der expliziten Grenzen. NULL ist für CLR-bool nicht unterstützt. |
| `@MaxDepth` | `int` | `32` | Startverzeichnis hat Tiefe 0. Listing akzeptiert 0..64, Entfernung nur die Untergrenze 0 ohne eigene feste Obergrenze. Rekursiv nötiger Abstieg jenseits der Grenze ist ein Fehler, keine stille Kürzung. Default 32; NULL ist für CLR-int nicht unterstützt. |
| `@MaxEntries` | `int` | `10000` | Default 10000. Listing akzeptiert 1..10000; Entfernung prüft nur >=1 ohne eigene feste Obergrenze. Überschreitung ist ein Fehler, keine gekürzte Erfolgsmenge. NULL ist für CLR-int nicht unterstützt. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |

## Ergebnisse

Eine Zeile nach erfolgreicher Entfernung: RootAlias nvarchar(128), RelativePath nvarchar(4000), State varchar(16)=removed. Keine OUTPUT-Parameter. Keine Ausgabe einer Löschliste. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.

## Aufrufbeispiele

```sql
-- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- Regulärer öffentlicher Einstieg für diese Operation:
EXEC toolbelt_filesystem.USP_RemoveDirectory @Hilfe=1;
-- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
EXEC toolbelt_filesystem.CLR_RemoveDirectory @RootAlias=N'ContosoWrite',@RelativePath=N'obsolete',@Recursive=0;
```

## Rechte

Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.

## Ressourcenbedarf

Vollständiger Löschplan mit offenen nativen Handles vor erster Löschung, proportional zur akzeptierten Eintragszahl. Der raw CLR-Einstieg prüft für MaxEntries nur >=1 und MaxDepth nur >=0; die Obergrenzen des Listingpfads gelten nicht für die Entfernung. Anzahlgrenze zählt Kinder, nicht das Startverzeichnis.

## Nebenwirkungen

Recursive=0 verlangt ein leeres Verzeichnis; Recursive=1 entfernt geplante Kinder rückwärts und danach den Start. Rootlöschung ist verboten. Preflightfehler führen vor Mutation zum Abbruch; Fehler während nativer Löschung können eine Teilentfernung hinterlassen. Kein SQL-Rollback und keine pauschale Garantie gegen alle konkurrierenden Dateisystemänderungen.

## Fehlerbehandlung

Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.

## Aussagegrenzen

Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
