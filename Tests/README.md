# Tests – SQL Server Toolbelt

Dieses Verzeichnis enthält die gemeinsame Test-Infrastruktur und Testdokumentation.

## Aktueller Stand

Der Repository-Grundaufbau ist abgeschlossen. 28 Module sind implementiert;
für alle existieren statische sowie synthetische Runtime- und
Lifecycle-Contract-Testartefakte.

Die ResultTable-Runtime-Action auf GitHub-hosted Linux war am 2026-07-29 mit
der vollständigen Suite für SQL Server 2019, 2022 und 2025 erfolgreich.
Die Base64- und Generate-Series-Runtime-Workflows für SQL Server 2025 und
Compatibility Levels 150, 160 und 170 waren erfolgreich. Für das
Identifier-Modul ist SQL Server 2025 Linux mit denselben Compatibility Levels
ebenfalls erfolgreich. Split-Characters, Semantic-Version, Integer-Base,
Calendar-Difference, Directional-TRIM und URI-Component sind dort ebenfalls
erfolgreich. Die drei W2a-Module sind dort einschließlich
Wiederholungsdeployment, Lifecycle, Central und Uninstall ebenfalls
erfolgreich. Physische SQL-Server-2019-/2022-, Windows- und weitere
modulspezifische Matrixfälle bleiben offen.
Das Date-Spine-Modul ist mit lokalen, zentralen, Lifecycle-, Dependency-,
Kollisions-, Grenz-, `DATEFIRST`- und Skalierungsverträgen auf den physischen
Linux-Zielen 2019, 2022 und 2025 erfolgreich. Die Windows-Ziele waren beim
SQL-Anmeldungs-Preflight nicht erreichbar; die Windows-Runtime blieb daher
`not executed`.
`toolbelt.json.path-exists` ist dort einschließlich nativer Parität,
Wiederholungsdeployment, Lifecycle, Central und Uninstall ebenfalls
erfolgreich.

Die E1b Work Queue ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich. Der vollständige
Scope umfasst Lease, Heartbeat, explizite Recovery, Token-Invaliderung, den
echten Upgradepfad `1.0.0 → 1.1.0`, Parallelität und Lifecycle. Das Modul ist
`validated` und `unreleased`.

Der R1a-Research-Slice unter [`Research/Regex`](./Research/Regex/README.md)
vergleicht die native SQL-Server-2025-RE2-Semantik reproduzierbar mit .NET
Framework 4.8. Er erzeugt kein Modul und keine öffentliche Runtime-API. Die
native Linux-2025-Matrix unter Compatibility 150/160/170 und der lokale
.NET-Framework-Harness sind erfolgreich; Windows-SQL-Runtime ist
`not executed`.

Das daraus getrennt freigegebene R1b-Modul `toolbelt.string.regex` ist mit
seinem begrenzten Dialekt, SAFE-CLR-/SHA2-512-Vertrag, Grenzen, Timeout,
Fehlerpräfixen und Lifecycle auf physischen SQL-Server-2019-/2022-/2025-
Zielen unter Windows base und Linux latest erfolgreich. Es ist `validated`
und `unreleased`.

Die W2c-Module sind dort einschließlich Langtext-/Unicode-, Marker-/Drift-,
Wiederholungsdeployment, Lifecycle, Central und Uninstall ebenfalls
erfolgreich.
Das Modul `toolbelt.file.content` ist auf SQL Server 2025 Linux mit
Compatibility Levels 150, 160 und 170 einschließlich synthetischer
Text-/Binary-Fixtures, Allowlist, Lifecycle und Uninstall erfolgreich.

## Pflicht-Testarten je Modul

| Testtyp | Inhalt |
|---|---|
| statisch | Naming, Header, Datenschutz, Manifest, Links und Vertragskonsistenz |
| API-Contract | Parameter, Defaults, Resultsets, Help, Fehler und Rechte |
| USP-Contract | `@Hilfe`, `@Debug`, `@ResultTable`, `@KeepData`, verschachtelte Aufrufe |
| Deploy | Erstinstallation, kontrollierte Wiederholung und jede unterstützte Vorgängerversion |
| Uninstall | vollständige Entfernung und Dependency-Schutz |
| Collation | unterschiedliche Server-, Datenbank- und TempDB-Collations |
| Deployment | lokal, zentral und Cross-database, soweit unterstützt |
| Plattform | SQL Server 2019, 2022 und 2025; Windows und Linux getrennt |
| Provider | jeder alternative Provider als eigener Nachweis |
| Recovery | Cleanup und Zustand nach Fehlern |
| Dokumentationskonsistenz | diff-basierte Prüfung registrierter Status-, Link- und Kopplungsartefakte |

## Modulspezifische Testmatrizen

| Modul | Matrix | Status |
|---|---|---|
| `toolbelt.archive.zip-memory` | [ZIP_MEMORY_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.archive.zip-memory/Tests/ZIP_MEMORY_CONTRACT_TEST_MATRIX.md) | `partially validated`; Windows-Runtime offen |
| `toolbelt.core.event-log` | [EVENT_LOG_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.event-log/Tests/EVENT_LOG_CONTRACT_TEST_MATRIX.md) | `partially validated`; Rollback-/uncommittable-/Context-/Retention-/Concurrency-/Central-Verträge auf SQL Server 2025 Linux CL150/160/170, Evidenz https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410 |
| `toolbelt.core.error-envelope` | [ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.error-envelope/Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux CL150/160/170, Evidence https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948 |
| `toolbelt.core.execution-context` | [EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.execution-context/Tests/EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md) | `partially validated`; Context-Lifecycle und Sessionisolation auf SQL Server 2025 Linux CL150/160/170, Evidence https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948 |
| `toolbelt.core.second-session` | [SECOND_SESSION_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.second-session/Tests/SECOND_SESSION_CONTRACT_TEST_MATRIX.md) | `partially validated`; Loopback-Provider-Spike auf SQL Server 2025 Linux erfolgreich; physische SQL-Server-2019-/2022- und Windows-Läufe bleiben `not executed` |
| `toolbelt.core.work-type` | [WORK_TYPE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.work-type/Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md) | `partially validated`; Version 1.1.0 einschließlich kontrollierter Removal-Capability auf SQL Server 2025 Linux CL150/160/170, Evidenz https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31016136937 |
| `toolbelt.file.content` | [FILE_CONTENT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.file.content/Tests/FILE_CONTENT_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich, Evidenz https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356 |
| `toolbelt.filesystem.windows` | [WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.filesystem.windows/Tests/WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md) | `not executed`; manueller Windows-SQL-Server-/NTFS-Nachweis offen |
| `toolbelt.core.result-table` | [RESULT_TABLE_CONTRACT_TEST_MATRIX.md](./RESULT_TABLE_CONTRACT_TEST_MATRIX.md) | `partially validated`; natürlicher Savepoint-Enginefehler auf SQL Server 2019/2022/2025 Linux erfolgreich ([Run 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855)); Windows/Performance-Baseline offen |
| `toolbelt.core.work-queue` | [WORK_QUEUE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.work-queue/Tests/WORK_QUEUE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige SQL-Server-2019-/2022-/2025-Matrix unter Windows base und Linux latest einschließlich E1b, Upgrade, Parallelität und Lifecycle erfolgreich |
| `toolbelt.conversion.base64` | [BASE64_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.base64/Tests/BASE64_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.core.generate-series` | [GENERATE_SERIES_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.generate-series/Tests/GENERATE_SERIES_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.metadata.identifier` | [IDENTIFIER_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.identifier/Tests/IDENTIFIER_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.string.split-characters` | [SPLIT_CHARACTERS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.split-characters/Tests/SPLIT_CHARACTERS_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.string.regex` | [REGEX_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.regex/Tests/REGEX_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige SQL-Server-2019-/2022-/2025-Matrix unter Windows base und Linux latest einschließlich SAFE CLR, Dialekt, Timeout, Lifecycle und Cleanup erfolgreich |
| `toolbelt.validation.semantic-version` | [SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.validation.semantic-version/Tests/SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.conversion.integer-base` | [INTEGER_BASE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.integer-base/Tests/INTEGER_BASE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.datetime.calendar-difference` | [CALENDAR_DIFFERENCE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.calendar-difference/Tests/CALENDAR_DIFFERENCE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.datetime.date-spine` | [DATE_SPINE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.date-spine/Tests/DATE_SPINE_CONTRACT_TEST_MATRIX.md) | `partially validated`; physische SQL-Server-2019-/2022-/2025-Linux-Ziele erfolgreich, Windows `not executed` |
| `toolbelt.string.directional-trim` | [DIRECTIONAL_TRIM_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.directional-trim/Tests/DIRECTIONAL_TRIM_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.conversion.uri-component` | [URI_COMPONENT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.uri-component/Tests/URI_COMPONENT_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.datetime.truncate` | [DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.truncate/Tests/DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.datetime.bucket` | [DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.bucket/Tests/DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.binary.bit-operations` | [BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.binary.bit-operations/Tests/BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.json.path-exists` | [JSON_PATH_EXISTS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.json.path-exists/Tests/JSON_PATH_EXISTS_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.core.console-message` | [CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.console-message/Tests/CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.metadata.capability-catalog` | [CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.capability-catalog/Tests/CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.tsql.script-parser` | [TSQL_SCRIPT_PARSER_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.tsql.script-parser/Tests/TSQL_SCRIPT_PARSER_CONTRACT_TEST_MATRIX.md) | `partially validated`; .NET 4.8 Build und statische Verträge validiert |

Eine Testmatrix ist noch kein Nachweis einer erfolgreichen Ausführung.

## Testdaten

- ausschließlich deterministische synthetische Testdaten;
- keine Produktions- oder Originaldaten, personenbezogenen oder sensiblen Daten sowie internen oder vertraulichen Informationen;
- keine nicht öffentlichen Infrastrukturangaben, realen Runtime-Ausgaben oder konkreten Remote-Runner-Hardwarewerte;
- fachlich relevante öffentliche Organisations-/Projektnamen und öffentliche Links sind zulässig;
- Rand- und Fehlerwerte ausdrücklich abdecken.

## Evidenz

Jede ausgeführte Prüfung nennt Befehl oder Workflow, Scope, Version, Plattform, Provider, Ergebnis, Datum und Einschränkungen. Nicht ausgeführte Prüfungen bleiben als `not executed` sichtbar.

## CI

Die capability-bezogene GitHub-hosted Linux-CI ist aktiv. Der
[Dokumentationsvalidator](./Documentation/README.md) prüft Pull Requests
inkrementell. Eine Dokumentationsänderung benötigt keine vollständige
Runtime-Matrix.

Details: [TEST_AND_VALIDATION_POLICY.md](../Documentation/Standards/TEST_AND_VALIDATION_POLICY.md)
