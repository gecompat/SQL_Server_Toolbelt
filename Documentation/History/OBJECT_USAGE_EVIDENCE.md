# Historische Nachweise aus Anleitungen

Die folgenden Passagen stammen aus den jeweils verlinkten Anleitungen. Datierte Prüfergebnisse und damalige Statusgrenzen gelten für den darin beschriebenen Stand. Aktuelle Nachweise stehen in den Modul- und [Releaseübersichten](../../Releases/1.0.0/CURRENT-QUALIFICATION-REST.md).

## TVF_GenerateSeriesBigInt

[Ursprünglicher Leseweg](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigInt.md)

## Teststatus

Der
[Generate-Series-Runtime-Lauf 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`; der Modulstatus ist `partially validated`.

## TVF_GenerateSeriesInt

[Ursprünglicher Leseweg](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesInt.md)

## Teststatus

Der
[Generate-Series-Runtime-Lauf 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`; der Modulstatus ist `partially validated`.

## SVF_IntegerToBase

[Ursprünglicher Leseweg](../../Modules/toolbelt.conversion.integer-base/Documentation/SVF_IntegerToBase.md)

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860

## SVF_TryBaseToInteger

[Ursprünglicher Leseweg](../../Modules/toolbelt.conversion.integer-base/Documentation/SVF_TryBaseToInteger.md)

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860

## SVF_CompareSemanticVersion

[Ursprünglicher Leseweg](../../Modules/toolbelt.validation.semantic-version/Documentation/SVF_CompareSemanticVersion.md)

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984

## SVF_SemanticVersionSortKey

[Ursprünglicher Leseweg](../../Modules/toolbelt.validation.semantic-version/Documentation/SVF_SemanticVersionSortKey.md)

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984

## TVF_ParseSemanticVersion

[Ursprünglicher Leseweg](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_ParseSemanticVersion.md)

Historischer Einzelbeleg (aktuelle Testgrenzen siehe Modulbeschreibung):
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984

## USP_ExtractZipEntryFromBinary

[Ursprünglicher Leseweg](../../Modules/toolbelt.archive.zip-memory/Documentation/USP_ExtractZipEntryFromBinary.md)

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206

## VW_ObjectUsageSkills

[Ursprünglicher Leseweg](../../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ObjectUsageSkills.md)

Die [native Abnahme für rc.5](https://github.com/gecompat/SQL_Server_Toolbelt/pull/630)
hat auf Windows SQL Server 2025 CU8, Compatibility Level 170, die lokale Erst-
und Wiederholungsinstallation sowie die vollständige Unicode-Ausgabe aller
257 Katalogzeilen bestätigt. Der frische Abschlussaudit war erfolgreich. Der
Nachweis für den Katalogabruf gilt für die Installationsanmeldung in diesem
lokalen Profil.

## CopyColumnV1

[Ursprünglicher Leseweg](../../Modules/toolbelt.tsql.ssis-debug/Documentation/CopyColumnV1.md)

Die [Prüfmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md#copy-column-v1-deltaabnahme)
trennt die ursprünglichen Explain-Läufe vom abschließenden Prozedurguard.
Paketintegrität, tatsächliche ZIP-Ausführung, SSMS, TLS und Linux-Exporthost
sind eigene Nachweise. Ältere Gesamtabnahmen bleiben an ihre ursprünglichen
Builds gebunden; der aktuelle Gesamtmodulstatus steht in `module.yaml`.

## PROVISIONING

[Ursprünglicher Leseweg](../../Deployment/PROVISIONING.md)

Die [separate Vorbereitungsabnahme](../../Deployment/Tests/Qualification/InstallerProvisioning.20261119.json)
bindet die sechs nativen Versions-/Plattformkontexte, die gezielte GUID-Delta-
Prüfung und den damaligen Gesamtfall. Sie belegt auch den tatsächlichen
CLR-Übergang 0 nach 1 sowie die nativen Fehlergrenzen und frischen Audits.
Die native Anmeldung verwendete SQL-Credentials von Windows; die allgemeinen
Modulnachweise und ursprünglichen rc.3-Clientbelege behalten ihren eigenen Scope.
Den Gesamtfall aus dem aktuellen ZIP mit beiden Schaltern und separatem
Zustandsvergleich beschreibt die
[Abnahme des gepackten Linux-Clients](../../Scripts/Install/Tests/QUALIFICATION.md#ein-aufruf-installer-auf-einem-linux-client).

## README

[Ursprünglicher Leseweg](../../Scripts/Install/README.md)

Der begrenzte native Gesamtfall vom 2026-11-20 ist für Windows SQL2025/CU8,
CL170, das lokale Windows-Profil und den Hashweg bestanden: Installation und
Wiederholung, XML-Aufruf, zentraler Aufruf mit Startwerten und tatsächliche
DebugScript-Ausführung. 13 Prüfungen und der separate frische Windows-Audit
mit zwei Prüfungen sind PASS. Zwei vorherige, bereinigte Fehlläufe deckten
ausgelassene kanonische Objektdateien auf; ihre Fehlernachweise bleiben erhalten.
Das ist keine vollständige native Abnahme aller Profile oder Trustwege.
Die [Prüfübersicht](../../Scripts/Install/Tests/QUALIFICATION.md) grenzt Teilnachweise und Restpunkt ab.

## USP_WriteConsoleMessage

Die [W2c-Runtime
30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
belegt den Enginevertrag auf SQL Server 2025 Linux mit Compatibility Levels
150, 160 und 170. Die Nachqualifikation vom 2026-10-19 ergänzt die
vollständige physische Windows-/Linux-Matrix auf SQL Server 2019/2022/2025
sowie zusätzliche ADO.NET-/ODBC-Prüfungen. Details und Aussagegrenzen:
[Clientprüfung](../../Modules/toolbelt.core.console-message/Tests/README.md#clientprüfung-2026-10-19).

## VW_ModuleCapabilities

Der aktuelle markerfreie Vertrag ist noch nicht nativ vollständig qualifiziert. Frühere Markerläufe qualifizieren ausschließlich die nachfolgend erhaltene alte Definition.

## VW_ModuleCapabilities

## Historischer Marker-Vertrag bis 2026-11-19

# toolbelt_metadata.VW_ModuleCapabilities

**Typ:** View
**Status:** `implemented`; Runtime `validated`

## Zweck

Projiziert Toolbelt-Modulmarker aus `sys.extended_properties` der aktuellen
Datenbank und weist Drift als `incomplete` oder `invalid` aus.

## Spalten

| Ordinal | Spalte | Typ | Nullable | Beschreibung |
|---:|---|---|---:|---|
| 1 | `ModuleId` | `sysname` | nein | Aus dem Markernamen extrahierte Modul-ID. |
| 2 | `ModuleVersion` | `nvarchar(4000)` | ja | Vorhandener Version-Marker; bei fehlendem Marker `NULL`. |
| 3 | `DeploymentMode` | `nvarchar(4000)` | ja | Vorhandener Modus-Marker; bei fehlendem Marker `NULL`. |
| 4 | `MetadataStatus` | `varchar(16)` | nein | `valid`, `incomplete` oder `invalid`. |

## Verwendung

```sql
SELECT
      ModuleId
    , ModuleVersion
    , DeploymentMode
    , MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities
ORDER BY ModuleId;
```

Die View garantiert ohne konsumierendes `ORDER BY` keine Reihenfolge.

## Validierungsregeln

`valid` verlangt kanonische Database-level Marker, eine kleingeschriebene
`toolbelt.*`-ID, Textwerte, eine dreiteilige stabile Release-Version ohne
führende Nullen und `local` oder `central`.

Ein fehlender Partner-Marker ergibt `incomplete`. Mehrfache, falsch
geschriebene, falsch typisierte oder syntaktisch ungültige Marker ergeben
`invalid`. Vorhandene Markerwerte bleiben in den Spalten sichtbar.

## Rechte, Performance und Grenzen

Erforderlich ist `SELECT` auf der View. Die normale SQL-Server-Metadata-
Visibility bleibt wirksam. Die View liest nur Database-level Extended
Properties der aktuellen Datenbank und mutiert nichts.

Nicht enthalten sind Objektinventar, Provider, Plattformen, Dependencies,
Supportmatrix, automatische Reparatur, Filter-TVF und persistente Registry.
Prerelease- und Build-Versionen sind in V1 ungültige installierte Marker.

Die [W2c-Runtime
30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
belegt den View-Vertrag auf SQL Server 2025 Linux mit Compatibility Levels
150, 160 und 170. Physische Zielversions-, Windows- und eingeschränkte
Metadata-Visibility-Läufe bleiben offen.

## SVF_Base64Encode

## Einschränkungen und Teststatus

Base64 schützt weder Vertraulichkeit noch Integrität. SQL Server 2025 unter
Linux ist mit Compatibility Levels 150, 160 und 170 erfolgreich geprüft.
Physische 2019-/2022- und Windows-Läufe bleiben `not executed`.

## SVF_Base64Decode

## Einschränkungen und Teststatus

Die Fehlernummern des XML-/Engine-Providers unterscheiden sich von der nativen
SQL-Server-2025-Funktion. Der Vertrag verspricht semantische Ablehnung, keine
Imitation nativer Fehlernummern. SQL Server 2025 unter Linux ist mit
Compatibility Levels 150, 160 und 170 erfolgreich geprüft. Physische
2019-/2022- und Windows-Läufe bleiben `not executed`.

## TVF_DeterministicTranslate

## Performance und Teststatus

Mappingrelationen bleiben klein; der Optimizer kann Ausdrücke wiederholt
auswerten. Status, tatsächlich ausgeführte SQL-API-/Lifecycle-/Metadaten-
Qualifikation und verbleibende Fälle stehen in der
[Testmatrix](../../Modules/toolbelt.pseudonymization.deterministic/Tests/CONTRACT_TEST_MATRIX.md).

Am 2026-10-02 bestehen vollständige Adapter auf Linux 2019/latest CL150
local/central und Windows 2025/CU8 CL150/160/170 central. Windows local:
API-/Safetyfälle im früheren Gesamtfehllauf bestanden; separate korrigierte
Metadaten-/Lifecycleprüfung erfolgreich. Aktuelle CI, neue Minimalrechte,
weitere physische Targets und Kapazität bleiben offen. Teilweise validiert,
unveröffentlicht; der frühere Fehllauf wird nicht als Gesamt-PASS geführt.

## WINDOWS_FILESYSTEM_PROCEDURES

[Microsoft dokumentiert](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/data-access/impersonation-and-credentials-for-connections?view=sql-server-ver17), dass lokale Datenzugriffe während Caller-Impersonation bis Undo nicht verfügbar sind. Die Korrektur trennt diese Zugriffe, verändert jedoch weder den öffentlichen Vertrag noch die Encoding-Semantik. Den aktuellen begrenzten Framework-/Auth-Probe-Nachweis beschreibt der folgende Evidenzabschnitt; vollständige NTFS-Qualifikation bleibt offen. Historische Nachweise gelten für ihre damaligen Sources.

## WINDOWS_FILESYSTEM_PROCEDURES

[Microsofts CONNECTIONPROPERTY-Vertrag](https://learn.microsoft.com/en-us/sql/t-sql/functions/connectionproperty-transact-sql?view=sql-server-ver17) beschreibt diese requestbezogenen Modi. Der vorbereitete Frameworktest ruft nur das echte reine Auth-Praedikat mit fuenf erlaubten und zehn abgewiesenen synthetischen Werten auf. Die neun NoOverwrite- und sieben Streaming-Faelle bleiben erhalten. Die aktuelle begrenzte Sourcebuild-/Framework-/Auth-Probe-Evidenz folgt unten. Direkte CLR-/RunAs- und vollständige NTFS-Nachweise bleiben offen; frühere Nachweise gelten für ihre historischen Sources.

## Aktueller begrenzter Nachweis 2026-10-04

Der Providerstand vom 2026-10-04 bestand einen privaten begrenzten produktiven C#-Sourcebuild und den sourcegebundenen Frameworklauf: neun NoOverwrite-Fälle/270 Assertions sowie sieben Streaming-Fälle/188 Assertions; darin enthalten ist die reine Caller-Policyprüfung mit fünf erlaubten und zehn abgewiesenen Werten. Vollständige Captures, Exit0, eigene Bereinigung und abschließende Sourcepins wurden geprüft. Die synthetischen Sequenzfälle beweisen keine echte Impersonation.

Die private native Zwei-Fall-Authentifizierungsprüfung auf SQL Server 2025/CU8 unter Windows bestand: Windows-Caller (NTLM) schrieb drei synthetische Bytes über `USP_WriteBinaryFile`; SQL-Authentifizierung wurde mit `51540/1` und `CallerWindowsAuthenticationRequired` vor Datei-/Staging-I/O abgewiesen. Eigene DB-, Root- und Trustbereinigung und eine separate frische Prüfung bestanden, ohne Konfigurations-, Rechte- oder Owneränderungen. Dieser begrenzte Probe-Scope ist kein vollständiger Produkttest.

Aktueller kanonischer Projektbuild/Releaseartefakt, direkte CLR-/RunAs-Qualifikation aller neun Einstiegspunkte, vollständige NTFS-/Caller-/ServiceAccount-Matrix, Races, weitere Ziele und aktuelle Head-CI bleiben separate offene Gates. Status `partially validated`, Version1.0.0 und `unreleased` bleiben erhalten; frühere Nachweise sind historisch.

## USP_ScriptTableClone

Der begrenzte lokale Windows2025/exakt-CU8-CL170-Triggernachweis bestand
am2026-10-04; Scope und verbleibende Grenzen stehen im
[Triggervertrag](../Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md).
Aktuelle Head-CI wird separat im PR nachgewiesen.

## TVF_FormatXlsxCell

[Nachweisgrenzen und Reproduktion](../../Modules/toolbelt.file.xlsx-memory/Tests/README.md): ausgewählte lokale
1.2-Nachweise und Offlinequalifikation bestanden am 2026-10-04. Vollständige
Produktmatrix, zentrale Nutzung, Minimalrechte und aktuelle Head-CI bleiben offen.

## USP_PrepareResultTable

Ein reproduzierbarer synthetischer CI-Workload für No-Mutation, `TRUNCATE` und
kleinen Schemaumbau wurde auf SQL Server 2019, 2022 und 2025 unter Linux
erfolgreich ausgeführt. Seine Duration-, CPU-, Logical-Read- und
TempDB-Nettoallokationswerte bleiben empirische Laufdaten des jeweiligen
Workflows und begründen keine allgemeine Performance-Zusage. Eine
plattformübergreifend vergleichbare Performance-Baseline ist weiterhin
`not executed`.

Der natürliche Fehlerpfad wurde im [GitHub-Actions-Lauf 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855) auf SQL Server 2019, 2022 und 2025 unter Linux mit Enginefehler 2705 geprüft. Der Savepoint stellte Zielschema und vor `TRUNCATE` vorhandene Daten wieder her; Caller-Marker, `XACT_STATE()` und `@@TRANCOUNT` blieben erhalten.

## TVF_InterpretXlsxCell

Server2019/2022/2025 Windows/Linux. Offlinekernqualifikation ist begrenzte
Evidenz. Native API-/FillRow-/Metadaten- und Lifecyclefälle bestehen im
ausgewählten Scope der [Testmatrix](../../Modules/toolbelt.file.xlsx-memory/Tests/XLSX_CONTRACT_TEST_MATRIX.md);
aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft;
tatsächliche Minimalrechte bleiben offen.

## USP_ExecuteTableClone

Stand 2026-10-04: historisches3.1 implementiert und unabhängig sourcegeprüft;
begrenzte lokale3.1-Nachweise bestanden. Der4.0-Hash-/Planner-/Lifecyclepfad
bestand den im [Triggervertrag](../Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md)
abgegrenzten lokalen Nachweis; vollständige Produktqualifikation bleibt offen.
Head-CI ist separat im PR nachzuweisen. Maßgeblich ist der
[Executor-Vertrag](../Architecture/TABLE_CLONE_EXECUTE_CONTRACT.md).
