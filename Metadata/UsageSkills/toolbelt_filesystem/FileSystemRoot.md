---
name: "toolbelt-filesystem-root-configuration"
description: "Persistente autorisierte Rootalias-Konfiguration des Windows-Dateisystemproviders."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "FileSystemRoot"
object_type: "TABLE"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.filesystem.windows/Source/FileSystemRoot.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
review_status: "verified"
source_module_version: "1.0.0"
---

# FileSystemRoot

## Zweck und Einsatzfälle

Persistente Konfiguration zulässiger Dateisystemroots. Fachcaller übergeben einen RootAlias und einen relativen Pfad an die öffentlichen Dateisystem-Prozeduren; sie bestimmen keinen freien physischen Root. Ausschließlich autorisierte Konfigurationsverwalter ändern diese Tabelle. Es gibt keine automatische Rootregistrierung durch Dateioperationen und keine mitgelieferten fachlichen Rootzeilen.

## Voraussetzungen

Lokales Windows-Dateisystemmodul mit passender CLR-Installation und bereits vorhandenen Rechten. Die Tabelle ist keine Linux-/Cross-DB-Dateisystemfreigabe. Physische Pfade müssen für den ausgewählten SQL-Server-Prozess und die bewusst gewählte Windowsidentität geeignet sein. Konfiguration erzeugt weder NTFS-Rechte noch eine Benutzer-/Gruppenmitgliedschaft.

## Parameter und Zugriff

Keine Aufrufparameter. Zeilenvertrag nach vollständiger Anwendung der kanonischen Definition:

| Spalte | Typ | NULL | Default und Bedeutung |
|---|---|---|---|
| RootAlias | sysname | nein | Kein Default; eindeutiger geclusterter Primärschlüssel und öffentlicher Alias. |
| RootPath | nvarchar(4000) | nein | Kein Default; administrativ ausgewählter physischer Rootpfad. |
| WorkPath | nvarchar(4000) | ja | Ohne expliziten Wert NULL; relativer Stagingpfad innerhalb des Roots. NULL/Whitespace verwendet im Provider das Zielverzeichnis. |
| AllowRead | bit | nein | 1; erlaubt den Leseprovider für diesen Root. |
| AllowWrite | bit | nein | 0; erlaubt den Schreibprovider nur bei explizitem 1. |
| AllowList | bit | nein | 1; erlaubt die Verzeichnisauflistung. |
| AllowDelete | bit | nein | 0; erlaubt Datei-/Verzeichnisentfernung nur bei explizitem 1. |
| AllowCreateDirectory | bit | nein | 0; erlaubt Verzeichnisanlage nur bei explizitem 1. |
| IsActive | bit | nein | 1; GetRoot berücksichtigt ausschließlich aktive Zeilen. |
| AllowServiceAccount | bit | nein | 0; zusätzliche Rootfreigabe für bewusst gewählte Dienstidentität, ersetzt nicht deren Rollenprüfung. |

RootAlias besitzt einen CHECK mit `NOT LIKE N'%[^A-Za-z0-9_-]%'`. Dieser Ausdruck verwendet die Datenbankcollation; er ist keine zusätzliche BIN2- oder Nichtleer-Prüfung. Der Provider weist NULL/Whitespace-Aliase vor der Abfrage zurück. WorkPath hat einen syntaktischen CHECK gegen Doppelpunkt, führenden Slash und führendes doppeltes Backslash; dies ersetzt keine vollständige Pfadprüfung. Der Provider normalisiert und prüft den tatsächlich verwendeten relativen Pfad zusätzlich. RootPath besitzt keinen vollständigen DDL-Pfadvalidator. Nur vertrauenswürdige Verwaltung darf physische Roots festlegen, insbesondere weil CreateDirectory fehlende Komponenten des konfigurierten Zielpfads anlegen kann.

## Ergebnisse

SELECT liefert die ausgewählten Konfigurationszeilen und Spalten; keine zugesicherte Reihenfolge ohne ORDER BY. GetRoot liest RootPath und WorkPath für genau den Alias mit IsActive=1, gesetztem Operationsflag und bei ServiceAccount zusätzlich AllowServiceAccount=1. Kein ResultTable-, OUTPUT- oder Hilfeparameter. Ein Skill beschreibt den Vertrag, nicht tatsächlich vorhandene Konfigurationsdaten.

## Aufrufbeispiele

```sql
-- Konfiguration prüfen, ohne physische Root-/Workpfade auszugeben:
SELECT RootAlias, IsActive, AllowRead, AllowWrite, AllowList,
       AllowDelete, AllowCreateDirectory, AllowServiceAccount
FROM toolbelt_filesystem.FileSystemRoot
ORDER BY RootAlias;

-- Fachliche Verwendung über öffentliche Prozedur zunächst erkunden:
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @Hilfe=1;
```

## Rechte

Vorhandenes SELECT im tatsächlichen Provider-/Caller-Kontext. INSERT, UPDATE und DELETE ausschließlich für ausdrücklich autorisierte Konfigurationsverwaltung; dieser Skill vergibt keine Rechte. SELECT auf der gesamten Tabelle kann reale physische Pfade offenlegen. Die zusätzliche dbo-eigene Rolle toolbelt_filesystem_service_account und passende Mitgliedschaft werden separat geprüft; Tabellenflags allein autorisieren keinen beliebigen Caller. Bestehende CLR-/Trust- und NTFS-Voraussetzungen gelten unabhängig davon.

## Ressourcenbedarf

Persistente Zeilen und geclusterter Aliasindex; kein eigenes Zeilen- oder Speicherbudget. Providerzugriffe verwenden einen parametrisierten Aliasvergleich und operationsabhängige feste Flagbedingungen. Konfigurationslesen traversiert selbst kein Dateisystem. Größen und Planverhalten hängen von Zeilenbestand, Collation und Datenbank ab; keine pauschale Performancezusage.

## Nebenwirkungen

SELECT verändert keine Konfiguration. Autorisierte DML ändert die Freigabe für spätere Dateioperationen; Deaktivierung ist keine Garantie, dass ein bereits gestarteter Provideraufruf stoppt. Konfigurations-DML unterliegt SQL-Transaktionen, tatsächliche Dateioperationen nicht deren Rollback. Die kanonische Quelldatei legt bei Bedarf die Tabelle und die dbo-eigene ServiceAccount-Rolle an; AllowServiceAccount wird in einem separaten bewachten ALTER-Abschnitt mit Default 0 ergänzt. Sie vergibt keine Rollenmitgliedschaft und trägt keine Rootzeilen ein. Eine vorhandene gleichnamige, anders kontrollierte Rolle führt zum Fehler statt Ownertransfer.

## Fehlerbehandlung

Primärschlüssel-, CHECK-, NOT-NULL- und Berechtigungsfehler stammen von SQL Server. Eine ungeeignete vorhandene ServiceAccount-Rolle führt bei Anwendung der Quelldatei zu THROW 51537. Nicht vorhandene/inaktive/nicht autorisierte Aliaszeilen werden vom Provider als RootNotAuthorized zurückgewiesen. Ungültige physische Konfiguration kann erst beim Provider-/NTFS-Zugriff scheitern; eine erfolgreiche Tabellenänderung beweist keinen funktionsfähigen Dateipfad. Keine automatische Reparatur, Pfadfreigabe oder Identitätsumschaltung.

## Aussagegrenzen

Quellgeprüfte Beschreibung, kein neuer nativer DDL-, Minimalrechte-, NTFS- oder Race-Gesamtnachweis. Eine vorhandene gleichnamige Tabelle wird durch den CREATE-Guard nicht auf vollständige strukturelle Gleichheit geprüft. Der gemeinsame Create-only-Installer hat seinen eigenen Lebenszyklus und überschreibt bestehende Definitionen nicht stillschweigend. Keine realen Rootpfade oder Konfigurationszeilen in öffentliche Dokumentation, Testartefakte oder Logs übernehmen.
