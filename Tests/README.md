# Tests – SQL Server Toolbelt

Dieses Verzeichnis enthält die gemeinsame Test-Infrastruktur und Testdokumentation.

Die [CSV-/Phonetic-Framework-Paketprofile](../Releases/1.0.0/CLR-FRAMEWORK-PACKAGE-QUALIFICATION.md)
verknüpfen zwei vorhandene CLR-Harnesses mit den ausgelieferten DLL-Bytes.
Es handelt sich um begrenzte Offlinebelege ohne SQL-Ausführung oder Änderung
des Modulstatus.

Die [workflowübergreifende Impact-Prüfung](CI/CHANGE_IMPACT_REVIEW_2026-10-19.md)
beschreibt die tatsächlichen Consumer-Trigger, den deterministischen lokalen
Cleanup-Test und die Grenzen einer späteren Local-to-Remote-Wiederverwendung.

Die Offline-Prüfung des repositoryweiten SQL-Exports liegt unter
[`Deployment/Tests/Test-SqlExport.ps1`](../Deployment/Tests/Test-SqlExport.ps1).
Sie prüft die aktuelle vollständige Modulclosure, Dependency-Auswahl, rekursive
Includes, Eingaben, deterministische Dateierzeugung und Fehler ohne SQL-Zugriff.
Der Documentation-Workflow führt sie bei betroffenen Deployment-/Source-/
Manifeständerungen aus. Dies ist kein Nachweis für Datenmigrationen oder
gemeinsame SQL-Laufzeitkompatibilität; siehe
[Deployment-Grenzen](../Deployment/README.md#datenerhaltung-und-derzeitige-grenzen).

## Aktueller Stand

Der manuelle [SQLGlot-Research-Spike](Research/SqlDialect/README.md) prüft
synthetische T-SQL-/Databricks-Parser-/Generatorfälle mit gepinntem lokalem
Python-Paket. Der ergänzte native Lab-Runner hat 81 feste Fälle auf sechs
SQL-Server-Labzielen erfolgreich geprüft: Ergebnisse, NULL-Verhalten und
Clientdatentypen, insgesamt 486 Fallausführungen. Die drei COUNT-/ROW_NUMBER-
Roundtrip-Lücken sind behoben. Kein Toolbelt-Modul installiert; Databricks- und authentifizierte
TLS-Qualifikation bleiben getrennt offen. Performance ist wie unten beschrieben
teilweise qualifiziert.
Die [native Databricks-Prüfung](../Documentation/Research/SQLGLOT_NATIVE_DATABRICKS_PROBE.md)
bleibt wegen des aktuell fehlenden Zugangs auf Benutzerauftrag vom 2026-10-17
`not executed`. Es wird keine zusätzliche Infrastruktur eingerichtet.
Der ergänzende [lokale Spark-SQL-Lauf](../Documentation/Research/SQLGLOT_NATIVE_SPARK_PROBE.md)
bestand am 2026-10-17 auf Apache Spark 4.0.2 mit 57 positiven und neun
negativen Fällen. Gleiche synthetische Daten und Abfragen, Ergebnisparität
mit den gebundenen SQL-Server-Nachweisen; kein Databricks-Nachweis daraus.
Die portable Testlaufzeit liegt nur unter `.runtime/`, ohne Cloud-/Labänderung.
Die [anschließende Performance-/Planprüfung](../Documentation/Research/SQL_DIALECT_PERFORMANCE_PROBE.md)
bestand mit 34 SQL-Server- und 20 Spark-Ergebnis-/Planfällen auf größeren
synthetischen Mengen. 18 Zeitserien erfüllen das Stabilitätsgate, 36 bleiben
für Zeitvergleiche `not executed`; Performance insgesamt `partially validated`.
Messwerte und Rohpläne bleiben ausschließlich lokal unter `.runtime/`.

Der Repository-Grundaufbau ist abgeschlossen. 45 Module sind implementiert;
22 sind `validated`, 23 sind `partially validated`, 0 sind `not executed`. Für alle existieren
statische sowie synthetische Runtime- und Lifecycle-Contract-Testartefakte.

Die ResultTable-Runtime-Action auf GitHub-hosted Linux war am 2026-07-29 mit
der vollständigen Suite für SQL Server 2019, 2022 und 2025 erfolgreich.
Die Base64- und Generate-Series-Runtime-Workflows für SQL Server 2025 und
Compatibility Levels 150, 160 und 170 waren erfolgreich.

Die vollständige lokale Matrix `local: Tests/CI/run-lab-local.ps1` war am
2026-09-01 für alle automatisierten Adapter auf physischen SQL-Server-2019-,
2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich. Neben
lokalem und zentralem Deployment, Lifecycle und Uninstall umfasst sie die
modulspezifischen Kollisions-, Collation-, Transaktions-, Konkurrenz-,
Metadatensichtbarkeits- und Skalierungsfälle. Die sieben weiterhin nur
teilvalidierten Module haben getrennt dokumentierte Performance-,
Client-/Treiber-, Fixture-, Interoperabilitäts- oder manuelle Sicherheitsgates.

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
Zielen unter Windows base und Linux latest erfolgreich. Dieser historische
R1b-Nachweis ist vom aktuellen R2b-Stand 1.2.0 zu trennen: risikobasiert auf
2019 Linux und 2025 Windows/CU8 geprüft, `partially validated`, `unreleased`.

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

Die Tabelle ist das vorhandene modulbezogene Verzeichnis der ausdrücklich
benannten Restschritte. Der Text nach dem Status nennt jeweils den nächsten
belegten Schritt oder die dafür fehlende Voraussetzung; typische Gruppen sind
weitere zugesagte Ziele/CLs, Rechte und Identität, Lifecycle/Upgrade,
Datei-/Client-/Hostverhalten sowie Last und Recovery. Diese Gruppen erzeugen
keine zusätzlichen Kombinationen: maßgeblich sind die Supportdeklaration und
die jeweilige kanonische Modulmatrix. Ein als `validated` markierter Eintrag
deckt seinen beschriebenen Scope ab. Wenn für eine darüber hinausgehende
Abnahme hier kein Restschritt benannt ist, gilt: im Inventar nicht benannt;
vor weiterer Abnahme die kanonische Matrix und den zugesagten Umfang prüfen.
Nicht qualifizierter Umfang ist nicht automatisch eine Veröffentlichungspflicht.
Vor der nächsten Testwelle sind Supportumfang, Pflichtfall, feste Ergebnisorakel
und Voraussetzungen abzugleichen. Die Übersicht erweitert keine bestehenden
Funktionsfreigaben; optionale Messungen bleiben von Pflichtfällen getrennt.

Die neue JSON-Welle besitzt einen gemeinsamen Offline- und nativen Labdriver.
Ihre Teilnachweise sind getrennt von historischen Constructorständen dokumentiert.

| Modul | Matrix | Status | Nächster belegter Schritt / Voraussetzung |
|---|---|---|
| `toolbelt.json.core` | [TEST_MATRIX.md](../Modules/toolbelt.json.core/Tests/TEST_MATRIX.md) | `partially validated`; Offlineclosure und begrenzte Core-/Consumer-Lifecycles auf Linux2019 CL150/Windows2025 CU8 CL170 local/central bestanden; vollständige Matrix offen | Zielmatrix: den zugesagten Umfang gegen die Modulmatrix abgleichen und nur tatsächlich unterstützte, branch-/provider-/engineverschiedene fehlende Fälle ausführen; vollständige Matrix bleibt offen. |
| `toolbelt.json.schema` | [TEST_MATRIX.md](../Modules/toolbelt.json.schema/Tests/TEST_MATRIX.md) | `partially validated`; 26 Contractfälle, Safety/Help/ResultTable und direkte Clientmetadaten auf beiden Zielen local/central bestanden; zusätzliche Deploy-/Uninstall-Abweisungen für Callertransaktionen auf Windows 2025/CU8/CL170/local bestanden; volle Lifecycle-/Ziel-/Minimalrechtematrix offen | Ziele, Lifecycle und Rechte: verbleibende Fälle der kanonischen Matrix konkretisieren; der Caller-Transaktionsnachweis gilt nur für das feste Startprofil `QUOTED_IDENTIFIER ON`, `XACT_ABORT OFF`, `NOCOUNT OFF`. |
| `toolbelt.json.pointer` | [JSON_POINTER_TEST_MATRIX.md](../Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md) | `partially validated`; [aktuelle physische Windows-/Linux-Matrix](../Modules/toolbelt.json.pointer/Tests/QUALIFICATION_2026-10-19.md) SQL2019 CL150, SQL2022 CL150/160, SQL2025 CL150/160/170: zwölf vollständige local/central/Consumer-Adapter, je 3072 feste APPLY-Oracles, 15 Clientreader und 42 Lifecyclefälle; frische Input-/Fixture-/Cleanup-Audits, 36 eigene DBs abwesend. Minimalrechte, Heap/Parallelität, harte Host-Recovery und Release separat offen; frühere Fehlläufe getrennt | Rechte, Last und Recovery: Minimalrechte, Heap/Parallelität und harte Host-Recovery sowie den getrennten Releasegate-Scope abnehmen; nur zugesagte, fachlich unterschiedliche Kombinationen. |
| `toolbelt.conversion.safe-cast` | [SAFE_CAST_TEST_MATRIX.md](../Modules/toolbelt.conversion.safe-cast/Tests/SAFE_CAST_TEST_MATRIX.md) | `partially validated`; finale Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 local/central/Consumer, je 13104 API-Oracles, 54 Clientreader, 38 Lifecyclefälle und unabhängiger Bereinigungsaudit; weitere Ziele, Minimalrechte und Heap offen | Ziele, Rechte und Last: weitere zugesagte Zielkontexte, Minimalrechte und Heapfälle aus der Matrix prüfen. |
| `toolbelt.string.text-pairs` | [TEXT_PAIRS_TEST_MATRIX.md](../Modules/toolbelt.string.text-pairs/Tests/TEXT_PAIRS_TEST_MATRIX.md) | `partially validated`; fünf Fixtures lokal auf Linux 2019 und Windows 2025/CU8 sowie zentraler Windows-Client-/ResultTable-/Uninstall-Bestätigungsnachweis; Minimalrechte, weitere Lifecycle-Negativfälle und Ziele offen | Rechte und Lifecycle: Minimalrechte sowie die benannten Lifecycle-Negativfälle und zugesagten weiteren Ziele prüfen. |
| `toolbelt.file.csv-memory` | [CSV_TEST_MATRIX.md](../Modules/toolbelt.file.csv-memory/Tests/CSV_TEST_MATRIX.md) | `partially validated`; Framework/IL und finale Linux2019/latest CL150 sowie Windows2025/exaktCU8 CL170 lokal/zentral mit Consumer, Client, 29 gezielten Lifecyclefällen und unabhängigem Cleanup bestanden; weitere Ziele, Minimalrechte, Fremdslot-/Driftvollmatrix und Heap offen | Ziele, Rechte, Drift und Last: weitere zugesagte Ziele, Minimalrechte, Fremdslot-/Driftvollmatrix und Heapfälle konkretisieren. |
| `toolbelt.file.xlsx-memory` | [XLSX_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.file.xlsx-memory/Tests/XLSX_CONTRACT_TEST_MATRIX.md) | `partially validated`; finale Linux-2019-/Windows-2025-Adapter einschließlich SAFE, local/central, Clientmetadaten, atomarer ResultTable und Lifecycle erfolgreich; große Ceiling-, minimale Rechte- und übrige Zielmatrix offen | Ceiling, Rechte und Ziele: übrige Grenzfälle zunächst gegen die bereits belegten Blatt-/SST-Grenzen abgleichen; nur fehlende zugesagte Fälle, Minimalrechte und relevante weitere Ziele konkretisieren. |
| `toolbelt.archive.zip-files` | [ZIP_FILES_TEST_MATRIX.md](../Modules/toolbelt.archive.zip-files/Tests/ZIP_FILES_TEST_MATRIX.md) | `partially validated`; elf frühere und zwei gezielte AppLock-Fallnachweise auf Windows2025/CU8 CL170 local, kein gemeinsamer 13-Fälle-Erfolgslauf; vollständige Qualifikation offen | Prüfbindung: die elf früheren und zwei AppLock-Fälle nach Quellen und Scope abgleichen; noch benötigte aktuelle Fälle anhand der Matrix festlegen. Getrennte Nachweise bleiben getrennt. |
| `toolbelt.archive.zip-memory` | [ZIP_MEMORY_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.archive.zip-memory/Tests/ZIP_MEMORY_CONTRACT_TEST_MATRIX.md) | `partially validated`; automatisierte Windows-/Linux-Matrix 2019/2022/2025 erfolgreich; reale Archive, Extremgrößen, historische Upgrades und Interoperabilität offen | Eingabe und Interoperabilität: repräsentative Archive, Extremgrößen, deklarierte historische Upgrades und Interoperabilität prüfen; Upgradevoraussetzung nur für tatsächlich unterstützte Vorgänger. |
| `toolbelt.core.event-log` | [EVENT_LOG_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.event-log/Tests/EVENT_LOG_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Rollback-, uncommittable-, Context-, Retention- und Concurrency-Verträgen | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.error-envelope` | [ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.error-envelope/Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.execution-context` | [EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.execution-context/Tests/EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Context-Lifecycle und Sessionisolation | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.execution-cancel` | [EXECUTION_CANCELLATION_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.execution-cancel/Tests/EXECUTION_CANCELLATION_CONTRACT_TEST_MATRIX.md) | `validated`; Windows-/Linux-Matrix 2019/2022/2025 mit W6d-Contract, Idempotenz, Transaktionsschutz, Parallelität, Lifecycle und Central erfolgreich | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.second-session` | [SECOND_SESSION_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.second-session/Tests/SECOND_SESSION_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Loopback-Provider, Transaktion und Konkurrenz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.work-type` | [WORK_TYPE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.work-type/Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Removal- und Konkurrenzvertrag | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.file.content` | [FILE_CONTENT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.file.content/Tests/FILE_CONTENT_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux und Compatibility 150/160/170 erfolgreich, Evidenz https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356 | Matrixprüfung erforderlich: im Inventar ist kein konkreter weiterer Restpunkt benannt; zugesagte Plattform-/Versionsmatrix und kanonische Testmatrix vor weiterem Statusschluss prüfen. |
| `toolbelt.filesystem.windows` | [WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.filesystem.windows/Tests/WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md) | `partially validated`; Caller-Impersonation, NTFS-ACL- und breitere manuelle I/O-Matrix offen | Windows-Identität und I/O: Caller-Impersonation, NTFS-ACL und breitere manuelle I/O-Fälle mit geklärter Identität und passenden Fixtures prüfen. |
| `toolbelt.core.result-table` | [RESULT_TABLE_CONTRACT_TEST_MATRIX.md](./RESULT_TABLE_CONTRACT_TEST_MATRIX.md) | `validated`; Windows-/Linux-Fachmatrix 2019/2022/2025 und Pflicht-Lastfall auf SQL 2025 Linux CL170 erfolgreich; Zeitmessung optional | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.work-queue` | [WORK_QUEUE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.work-queue/Tests/WORK_QUEUE_CONTRACT_TEST_MATRIX.md) | `partially validated`; historische 2.0-Matrix, echter 2.0→2.1-Upgrade auf 2019 Linux und gezielte SQL-Managedkopplung auf 2019 Linux/2025 Windows CU8 bestanden; vollständiger Providerlauf offen | Providerlauf: den vollständigen zugesagten Providerlauf mit passender vorkonfigurierter Providerkombination durchführen. |
| `toolbelt.core.worker-control` | [WORKER_CONTROL_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.worker-control/Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL-Admission, Holds, private Gates, Help und Lifecycle-Abweisungen auf 2019 Linux bestanden; Linux-Workerhost und exakte Head-CI offen | Host und CI: Linux-Workerhost-Fälle sowie den exakten Head-CI-Nachweis ergänzen; geeigneter Workerhost ist Voraussetzung. |
| `toolbelt.conversion.base64` | [BASE64_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.base64/Tests/BASE64_CONTRACT_TEST_MATRIX.md) | `validated`; Windows-/Linux-Fachmatrix 2019/2022/2025 und Pflicht-Lastfall auf SQL 2025 Linux CL170 erfolgreich; Zeitmessung optional | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.generate-series` | [GENERATE_SERIES_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.generate-series/Tests/GENERATE_SERIES_CONTRACT_TEST_MATRIX.md) | `validated`; Windows-/Linux-Fachmatrix 2019/2022/2025 und Pflicht-Lastfall auf SQL 2025 Linux CL170 erfolgreich; Zeitmessung optional | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.metadata.identifier` | [IDENTIFIER_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.identifier/Tests/IDENTIFIER_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.string.split-characters` | [SPLIT_CHARACTERS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.split-characters/Tests/SPLIT_CHARACTERS_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.string.split-advanced` | [SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.split-advanced/Tests/SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md) | `partially validated`; risikobasiert 2019 Linux und 2025 Linux/Windows, andere Zielkombinationen nicht ausgeführt | Zielmatrix: die nicht ausgeführten zugesagten Zielkombinationen anhand unterschiedlicher Zweige/Provider/Engineverhalten auswählen; keine Wiederholung allein wegen OS-/Versionsunterschied. |
| `toolbelt.string.phonetic` | [PHONETIC_TEST_MATRIX.md](../Modules/toolbelt.string.phonetic/Tests/PHONETIC_TEST_MATRIX.md) | `partially validated`; begrenzte Build-/Framework-/IL- und private Native-Nachweise auf Linux2019/latest CL150 und Windows2025/exakt CU8 CL170; Java-Differential, weitere Ziele und Minimalrechte offen | Differential, Ziele und Rechte: Java-Differential, weitere zugesagte Zielkontexte und Minimalrechte qualifizieren. |
| `toolbelt.string.edit-distance` | [EDIT_DISTANCE_TEST_MATRIX.md](../Modules/toolbelt.string.edit-distance/Tests/EDIT_DISTANCE_TEST_MATRIX.md) | `partially validated`; neue 1.1-Offline Matrix/Framework/Releasebuilds/IL und private native Gesamtadapter auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral samt SC-UTF8 und unabhängigem Cleanup bestanden; tatsächliche Minimalrechte, Heap und weitere physische Ziele offen | Rechte, Last und Ziele: tatsächliche Minimalrechte, Heap und weitere zugesagte physische Zielkontexte abnehmen. |
| `toolbelt.string.regex` | [REGEX_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.regex/Tests/REGEX_CONTRACT_TEST_MATRIX.md) | `partially validated`; R2b 1.2.0 auf 2019 Linux CL150 und 2025 Windows/CU8 CL150/160/170 erfolgreich; historische R1b-/R2a-Nachweise getrennt, weitere R2b-Ziele offen | R2b-Zielmatrix: weitere zugesagte R2b-Ziele nachweisen; historische R1b-/R2a-Berichte bleiben getrennte Artefaktscopes. |
| `toolbelt.validation.semantic-version` | [SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.validation.semantic-version/Tests/SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.conversion.integer-base` | [INTEGER_BASE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.integer-base/Tests/INTEGER_BASE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.datetime.calendar-difference` | [CALENDAR_DIFFERENCE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.calendar-difference/Tests/CALENDAR_DIFFERENCE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Kollisionsschutz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.datetime.date-spine` | [DATE_SPINE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.date-spine/Tests/DATE_SPINE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Dependency-, Kollisions- und Skalierungsverträgen | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.string.directional-trim` | [DIRECTIONAL_TRIM_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.directional-trim/Tests/DIRECTIONAL_TRIM_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich CI-/CS-/UTF-8-Collations | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.conversion.uri-component` | [URI_COMPONENT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.uri-component/Tests/URI_COMPONENT_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich ASCII-, Unicode- und Large-Input-Verträgen | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.datetime.truncate` | [DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.truncate/Tests/DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich nativer Parität und Kollisionsschutz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.datetime.bucket` | [DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.bucket/Tests/DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich 100.000-Zeilen-Workload und Kollisionsschutz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.binary.bit-operations` | [BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.binary.bit-operations/Tests/BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich nativer Parität und Kollisionsschutz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.json.path-exists` | [JSON_PATH_EXISTS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.json.path-exists/Tests/JSON_PATH_EXISTS_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich nativer Parität und Kollisionsschutz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.json.constructors` | [JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.json.constructors/Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md) | `partially validated`; vollständiger neuer Adapter auf 2019 Linux/latest und 2025 Windows/CU8 erfolgreich; weitere Ziel-/Rechtekontexte und Produktionskapazität offen | Ziele und Rechte: weitere zugesagte Fälle konkretisieren. Die offene Kapazitätsangabe zunächst als fachliches Ergebnisorakel oder optionale Messung einordnen; daraus keine Produktionszusage ableiten. |
| `toolbelt.metadata.table-clone` | [TABLE_CLONE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.table-clone/Tests/TABLE_CLONE_CONTRACT_TEST_MATRIX.md) | `partially validated`; historische V1 und W1 auf 2019 Linux/latest CL150 sowie 2025 Windows/CU8 CL150/160/170 lokal/zentral erfolgreich; korrigierte Prefixfixture nativ nachqualifiziert; PR-Head 76888216 mit allen sieben CI-Checks SUCCESS einschließlich Linux2019/2022/2025. Weitere physische Ziele und tatsächliche Lowpriv-Kontexte offen | Ziele und Lowpriv: weitere zugesagte physische Ziele und tatsächliche Lowpriv-Kontexte nachweisen. |
| `toolbelt.pseudonymization.deterministic` | [CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.pseudonymization.deterministic/Tests/CONTRACT_TEST_MATRIX.md) | `partially validated`; identischer finaler Safetyfix-Adapter auf 2019 Linux/latest und 2025 Windows/CU8 am 2026-10-02 erfolgreich; weitere Targets/CrossDB-Minimalrechte/Kapazität offen | Ziele, CrossDB-Rechte und Kapazität: weitere zugesagte Ziele sowie CrossDB-Minimalrechte und Kapazitätsfälle konkretisieren. |
| `toolbelt.core.console-message` | [CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.console-message/Tests/CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md) | `partially validated`; automatisierte Windows-/Linux-Matrix 2019/2022/2025 erfolgreich; zusätzliche Client-/Treiber-, Buffering- und Framing-Evidenz offen | Clientpfad: Client-/Treiberverhalten, Buffering und Framing mit den benannten Client-/Treiberkontexten belegen. |
| `toolbelt.metadata.capability-catalog` | [CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.capability-catalog/Tests/CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich eingeschränkter Metadatensichtbarkeit ohne Rechteausweitung | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.tsql.script-parser` | [TSQL_SCRIPT_PARSER_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.tsql.script-parser/Tests/TSQL_SCRIPT_PARSER_CONTRACT_TEST_MATRIX.md) | `validated`; physische Windows-SQL-Server-Matrix 2019/2022/2025 für Build, Deployment, Feature, Central und Uninstall erfolgreich | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.tsql.ssis-debug` | [SSIS-Debug-Prüfmatrix](../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) | `partially validated`; aktueller Current-Binaryvertrag: sechs Windows-Kontexte; aktuelles Current-ZIP: zwölf Windows-/CL-/Moduskontexte; aktueller Standalone-T-SQL-Installer: zwölf Windows-/CL-/Moduskontexte; die jeweiligen Originalberichte und Matrizen grenzen diese Nachweise auf feste synthetische Verträge ein. Nächster Schritt: tatsächliche SSIS-Ausführung, Windows-Anmeldung/SSMS-GUI, authentifiziertes TLS, administrativer Trust-Opt-in und Recovery bleiben getrennte, nicht qualifizierte Voraussetzungen; aktuelle Head-/Main-CI und Integration am PR-/Merge-Head nachweisen; unveröffentlicht | Getrennte Voraussetzungen: tatsächliche SSIS-Ausführung, Windows-Anmeldung/SSMS-GUI, authentifiziertes TLS, administrativen Trust-Opt-in und Recovery separat qualifizieren; aktuelle Head-/Main-CI und Integration am PR-/Merge-Head nachweisen. |

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
