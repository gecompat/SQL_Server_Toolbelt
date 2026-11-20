---
name: "toolbelt-fs-clr-create-directory"
description: "Interner Windows-CLR-Provider zum Anlegen autorisierter relativer Verzeichnisse."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "CLR_CreateDirectory"
object_type: "CLR_USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_CreateDirectory"]
---

# CLR_CreateDirectory

## Zweck und Einsatzfälle

Interner Windows-CLR-Provider zum Anlegen autorisierter relativer Verzeichnisse. Internes Implementierungsdetail. Regulär die öffentliche USP_CreateDirectory mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.

## Voraussetzungen

Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowCreateDirectory erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |

## Ergebnisse

Eine Zeile: RootAlias nvarchar(128), RelativePath nvarchar(4000), State varchar(16)=created. created unterscheidet nicht zwischen bereits vorhandenem und neu angelegtem Verzeichnis. Keine OUTPUT-Parameter. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.

## Aufrufbeispiele

```sql
-- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- Regulärer öffentlicher Einstieg für diese Operation:
EXEC toolbelt_filesystem.USP_CreateDirectory @Hilfe=1;
-- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
EXEC toolbelt_filesystem.CLR_CreateDirectory @RootAlias=N'ContosoWrite',@RelativePath=N'output';
```

## Rechte

Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.

## Ressourcenbedarf

Parenthandles proportional zur Anzahl der Pfadkomponenten. Keine eigene feste Komponentenquote; Pfad-/Betriebssystemgrenzen gelten.

## Nebenwirkungen

Legt fehlende Komponenten des konfigurierten Zielpfads an. Die physische Rootkonfiguration muss deshalb von einer autorisierten Verwaltung stammen; sie wird hier nicht angelegt oder geändert. Leerer relativer Pfad wählt den Root; auch NativeParents(create=true) muss im vorgesehenen autorisierten Kontext laufen. Bei späterem Fehler können bereits angelegte Komponenten bestehen bleiben. Kein SQL-ROLLBACK für Dateioperationen.

## Fehlerbehandlung

Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.

## Aussagegrenzen

Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
