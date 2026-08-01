# Tests – SQL Server Toolbelt

Dieses Verzeichnis enthält die gemeinsame Test-Infrastruktur und Testdokumentation.

## Aktueller Stand

Der Repository-Grundaufbau ist abgeschlossen. 19 Module sind implementiert;
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
`toolbelt.json.path-exists` ist dort einschließlich nativer Parität,
Wiederholungsdeployment, Lifecycle, Central und Uninstall ebenfalls
erfolgreich.
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
| `toolbelt.file.content` | [FILE_CONTENT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.file.content/Tests/FILE_CONTENT_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich, Evidenz https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356 |
| `toolbelt.filesystem.windows` | [WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.filesystem.windows/Tests/WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md) | `not executed`; manueller Windows-SQL-Server-/NTFS-Nachweis offen |
| `toolbelt.core.result-table` | [RESULT_TABLE_CONTRACT_TEST_MATRIX.md](./RESULT_TABLE_CONTRACT_TEST_MATRIX.md) | `partially validated`; natürlicher Savepoint-Enginefehler auf SQL Server 2019/2022/2025 Linux erfolgreich ([Run 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855)); Windows/Performance-Baseline offen |
| `toolbelt.conversion.base64` | [BASE64_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.base64/Tests/BASE64_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.core.generate-series` | [GENERATE_SERIES_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.generate-series/Tests/GENERATE_SERIES_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.metadata.identifier` | [IDENTIFIER_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.identifier/Tests/IDENTIFIER_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.string.split-characters` | [SPLIT_CHARACTERS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.split-characters/Tests/SPLIT_CHARACTERS_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.validation.semantic-version` | [SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.validation.semantic-version/Tests/SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.conversion.integer-base` | [INTEGER_BASE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.integer-base/Tests/INTEGER_BASE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.datetime.calendar-difference` | [CALENDAR_DIFFERENCE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.calendar-difference/Tests/CALENDAR_DIFFERENCE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.string.directional-trim` | [DIRECTIONAL_TRIM_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.directional-trim/Tests/DIRECTIONAL_TRIM_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.conversion.uri-component` | [URI_COMPONENT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.uri-component/Tests/URI_COMPONENT_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.datetime.truncate` | [DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.truncate/Tests/DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.datetime.bucket` | [DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.bucket/Tests/DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.binary.bit-operations` | [BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.binary.bit-operations/Tests/BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.json.path-exists` | [JSON_PATH_EXISTS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.json.path-exists/Tests/JSON_PATH_EXISTS_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.core.console-message` | [CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.console-message/Tests/CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |
| `toolbelt.metadata.capability-catalog` | [CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.capability-catalog/Tests/CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich |

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
