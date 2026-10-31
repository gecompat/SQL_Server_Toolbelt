# Releasevorbereitung prüfen

## Aktuelle 19 stabile Kandidaten abnehmen

Die [Abnahmeübersicht](../../Releases/1.0.0/STABLE19-ACCEPTANCE.md) trennt
aktuelle Integrationsfälle, anwendbare historische Fachnachweise und offene
Identitäts-/Client-/Freigabegrenzen. `prepare_stable19_acceptance.py` verwendet
den bestehenden `Deployment/Deploy-All.ps1`-Exporter für genau die 19 stabilen
Kandidaten und bindet alle versionierten Moduldateien an den Quellcommit.
Die Vorbereitung benötigt ein neues privates Verzeichnis unter `.runtime`
mit zuvor schema-validierter, ausdrücklich ausgewählter Zwölfermatrix in
`private-selection.json`; Vertrag und Zugangsdaten werden nicht kopiert.
Benötigt werden Python 3.10+, PowerShell 7 und Git; Produkt- und Methodeninputs
müssen committed sein. Die private Auswahl enthält `cases` mit jeweils
`Platform`, `Version`, `Patch`, `CL` sowie `contract_path`, `schema_path` und
`prompt_path` aus der kanonischen Labdiscovery. Danach
`python -B Tests/Release/prepare_stable19_acceptance.py <privates-verzeichnis>`
aufrufen. Vorhandene Exporte werden nicht überschrieben.

`Invoke-Stable19AcceptanceLab.ps1 -RunsetPath <privates-runset> -CaseIndex <0..11>`
installiert diese aktuellen Exporte lokal und zentral, wiederholt sie, prüft
öffentliche Objektpräsenz und vollständige installierte Parameterhilfe,
führt die fünf vorhandenen Paketorakel auch im zentralen Consumer aus und
deinstalliert zweimal in umgekehrter Dependencyreihenfolge. Ein anschließender
eigener Prozess mit `-AuditOnly` prüft Abwesenheit und sämtliche Inputpins.
Die SQL-/Ownership-/Deadlinehelfer stammen unverändert aus dem historischen
Pakettreiber. Dessen Produktcommit-Gate wird weder umgangen noch verändert.
Der neue Lauf ist keine vollständige neue API-, Minimalrechte-, CrossDB-
Identitäts-, GUI- oder TLS-Qualifikation. Runsets und Journale bleiben privat.

Vier negative Vor-SQL-Prüfungen für private Pfade, Engine-/CL-Auswahl,
fehlende Pins und geänderte Inputs laufen im bestehenden Release-Validierungszweig;
gezielt: `python -B Tests/Release/test_stable19_acceptance.py`. Keine neue CI
oder automatische native SQL-Ausführung.
Zwei weitere Offlineprüfungen binden den Abschlussrecord an die vollständige
Zwölfermatrix und die Originalbytes des tatsächlichen Ausführungscommits;
eine fehlende Zeile oder erfundene Veröffentlichungsfreigabe wird abgewiesen.
Der historische `test_prepare_release.py`-Loader ist bytegleich zu seinem
exakt qualifizierten Stand wiederhergestellt. Der Dokumentationsvalidator ruft
die elf RC-Tests und sechs neuen Abnahmetests im selben `release_preparation`-
Zweig als gemeinsamen begrenzten Offlineprozess auf. Die ursprüngliche Suite
behält 280 Tests; insgesamt bleiben alle 297 Assertionsfälle erhalten. Für den
gesamten Releasecheck gibt es weiterhin genau einen CI-Job; native Labtests
werden dadurch nicht gestartet.

## Aktueller Quellkandidat

Die [Kandidatenanleitung](../../Releases/1.0.0/CURRENT-CANDIDATE.md) führt zum
aktuellen Quellpaket mit dem gebundenen Parameter-Help-Installer. Die Tests in
test_current_release_candidate.py laufen über die vorhandene Release-Suite.
Sie bauen und prüfen den exakten HEAD ohne SQL und verwerfen unter anderem
abweichende Quellen, selbst konsistent neu gehashte Nutzdaten, unzulässige
Archivpfade, falsche Nachweisbehauptungen und das Überschreiben bestehender
Ausgaben. Der historische Builder und seine strengeren Produktbindungen bleiben
unverändert. Die Prüfung benötigt committed Quellen samt Kandidatenanleitung.

## Historische Dokumentationsquellen nach PR #482

Der [Dokumentationsübergang](../../Releases/1.0.0/documentation-followup-transition.json)
bindet zehn nachträglich ergänzte Modul-Lesepfade: acht frühere Help-Quellen
und die beiden CSV-USP-Dokumente. Ein kleines Archiv bewahrt ihre Bytes vor der
Integration; exakte Vorher- und Nachher-SHAs begrenzen die aktuelle Änderung.
Historische Qualifikationsprüfungen lesen weiterhin nur die archivierten
Ausgangsbytes. Die heutigen Dokumente müssen separat exakt dem gebundenen
Folgestand entsprechen. Das ist eine Quellen-/Dokumentationsbrücke und keine
neue native Qualifikation; alte Berichte und Methodenpins bleiben unverändert.

Die gezielten Prüfungen laufen in der bestehenden Release-Suite:
`test_current_documentation_transition.py`, `test_csv_metadata.py` und
`test_clr_maintenance.py`. Sie verwerfen unter anderem abweichende aktuelle
Dateien, falsche Vorgängerpins, Archiv-/Recorddrift und geänderte gepinnte
Maintenance-Methoden.

Die [XLSX-Grenzprüfung](../../Releases/1.0.0/XLSX-BOUNDARY-QUALIFICATION.md)
trennt die bestandene 32/33-Blattgrenze vom nicht qualifizierten
50.000-Shared-String-Scope. Fünf neue Evidenzprüfungen kontrollieren Zähler,
Grenzstatus und aktuelle öffentliche Quellpins; sie laufen in
`CallerMetadataTests` über die bestehende Release-Suite.

Der [XLSX-/ZIP-Writer-Paketnachweis](../../Releases/1.0.0/XLSX-ZIP-PACKAGE-FRAMEWORK-QUALIFICATION.md)
hat drei gezielte Report-/Guardprüfungen in `test_caller_metadata.py`.
Sie prüfen Quellenpins, Paket-DLLs, Scope und die Fail-closed-Pfade des
Paketpreparers ohne Compiler oder Frameworklauf. Der lokale Lauf erfolgt über
den versteckten Python-Launcher; die Pflichtsuite läuft unverändert über CI.

Die [ZIP-Callerprüfung](../../Releases/1.0.0/ZIP-CALLER-PROFILE.md) bindet drei
bestehende ZIP-Memory-USPs an feste synthetische Orakel, sechs Rechtezustände
je API und direkte sowie caller-lokale ResultTable-Ausgabe. Vier Berichtstests
sind in `test_caller_metadata.py` integriert; gezielt lokal:
`python -B -m unittest Tests.Release.test_caller_metadata.CallerMetadataTests.test_matrix_and_probe_totals_are_arithmetically_bound Tests.Release.test_caller_metadata.CallerMetadataTests.test_public_source_pins_match_current_synthetic_inputs Tests.Release.test_caller_metadata.CallerMetadataTests.test_fixed_reader_and_writer_goldens_are_independent Tests.Release.test_caller_metadata.CallerMetadataTests.test_expected_controls_and_retained_v1_failure_are_distinct -v`.

Die [ZIP-Entryanzahl-Grenzprüfung](../../Releases/1.0.0/ZIP-ENTRY-COUNT-QUALIFICATION.md) ergänzt die bestehende Listing-API um feste 10.000-/10.001-Entry-Orakel, einen direkten Reader-Fehlerpfad ohne erste Zeile und eine Prüfung der gefundenen Deploy-All-Modulmenge. Sechs Offlineprüfungen laufen über `CallerMetadataTests`; gezielt im Verzeichnis `Tests/Release`: `python -B -m unittest test_caller_metadata.CallerMetadataTests -k zip_entry_count -v`. Der negative Discoverytest startet PowerShell 7 mit `CREATE_NO_WINDOW`; es wird kein SQL ausgeführt.

Die [XLSX-Rohleser-Callerprüfung](../../Releases/1.0.0/XLSX-RAW-CALLER-PROFILE.md) bindet `Invoke-XlsxRawCallerLab.ps1`, die SQL-Rechtefixture und den deterministischen Workbookcomposer. Die neue Profilprüfung ist als Mixin in `XlsxCellCallerTests` eingebunden; sie läuft damit über die bestehende Release-Suite, ohne neuen CI-Job. Gezielt lokal: `python -m unittest Tests.Release.test_xlsx_raw_caller_evidence Tests.Release.test_xlsx_raw_caller_composer -v`.

Die [XLSX-Zell-Callerprüfung](../../Releases/1.0.0/XLSX-CELL-CALLER-QUALIFICATION.md) ergänzt zwei öffentliche SELECT-Profile mit eigener kanonischer Case-Datei und Zwei-DLL-Labtreiber. Vier Berichtsprüfungen laufen in der vorhandenen Suite; zusätzlich `python -B Tests/Release/test_xlsx_cell_caller_qualification.py`.

Die [XLSX-Manifest- und Paketpflege](../../Releases/1.0.0/XLSX-METADATA-UPDATE.md) erhält beide ursprünglichen Berichtepins und prüft das additive Overlay auf dem bestehenden CLR-Paket. Sechs fokussierte Regressionen sind in `test_caller_metadata.py` integriert; gezielt lokal: `python -B -m unittest Tests.Release.test_xlsx_metadata -v`.

Die [aktuelle SSIS-Lookup-Paketbindung](../../Releases/1.0.0/SSIS-LOOKUP-QUALIFICATION.md)
verknüpft die zwölf Build-, zwei Standalone- und je sechs CLR-/Gesamtpaketfälle.
Historische Pipeline-Nachweise behalten ihre ursprünglichen Artefakte.

Die [SSIS-Snapshot-Kohärenzqualifikation](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.SnapshotCoherence.20261030.json)
bindet zwei native Windows-2025/CU8/CL170-Kontexte an das unveränderte Current-
Paket. Der Offlinevalidator prüft die exakte Berichtszusammensetzung, 53
öffentliche Eingabepins, Paket-/Binaryprovenienz und JSON-Typen; die fokussierten
Negativkontrollen laufen über `test_ssis_current_snapshot.py`. Er startet keine
SQL-Verbindung. Ein abweichender Checkout-Line-Ending-Pin wird nur für das
gebundene RowCount-DTSX per exakter umkehrbarer LF/CRLF-Abbildung überbrückt;
der native Execution-Pin bleibt unverändert, alle anderen Pins bleiben strikt.
Dies ist keine allgemeine SSIS-Modul- oder Matrixqualifikation.

Die [Caller-Metadatenprüfung](../../Releases/1.0.0/CALLER-METADATA-UPDATE.md)
läuft in der bestehenden Release-Regressionssuite. Einzelprüfung:
`python -B Tests/Release/test_caller_metadata.py`; ursprüngliche Caller-Pins
bleiben erhalten, Runtime-/Vertragsänderungen werden abgewiesen.

Die [JSON-Constructor-Paketqualifikation](../../Releases/1.0.0/JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.md)
bindet den vorhandenen Framework- und Closure-IL-Lauf an die Constructor-/Core-
DLLs des CLR-Pakets. Sieben Offlineprüfungen zu Paketbindung, Evidenz und
Pfadgrenzen sind in
`test_caller_metadata.py` eingebunden. Der private qualifizierende Lauf ist:

```powershell
pwsh -NoProfile -NonInteractive -File Tests/Release/Invoke-JsonConstructorsPackageQualification.ps1 `
  -CompilerPath <vorhandener Roslyn-csc> `
  -ReferenceDirectory <vorhandene .NET-Framework-Referenzen> `
  -FrameworkPowerShell <Windows-PowerShell-5.1> `
  -OutputDirectory .runtime/<neues-Ausgabeverzeichnis>
```

Er läuft ohne SQL oder Labverbindung und bindet die beiden extrahierten DLLs
bytegenau an die Frameworkausgaben; ein vorhandenes Ziel oder abweichende
Paket-/DLL-Bytes werden abgewiesen.

Die getrennte [JSON-Schema-Paket-IL-Prüfung](../../Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.md)
verwendet den unveränderten privaten Framework-Receipt und bindet alle Phasen,
Eingaben und Outputs erneut. Der vorhandene IL-Guard läuft direkt auf der
Schema-DLL aus dem geprüften Paket; neun Offlineprüfungen sind in
`test_caller_metadata.py` integriert. Ein neuer kompletter Frameworklauf ist
nicht erforderlich, solange der gebundene Receipt und seine Quellpins bestehen.
Gezielt lokal: `python -B -m unittest Tests.Release.test_caller_metadata.CallerMetadataTests.test_public_predecessor_and_framework_inputs_are_exactly_bound Tests.Release.test_caller_metadata.CallerMetadataTests.test_schema_public_evidence_binds_the_package_and_reused_receipt Tests.Release.test_caller_metadata.CallerMetadataTests.test_framework_receipt_requires_complete_phases_and_fresh_sources Tests.Release.test_caller_metadata.CallerMetadataTests.test_schema_manifest_hash_is_checked_even_with_matching_outer_hash Tests.Release.test_caller_metadata.CallerMetadataTests.test_package_archive_hash_and_fixed_oracle_pins_reject_drift Tests.Release.test_caller_metadata.CallerMetadataTests.test_schema_framework_output_must_equal_the_package_binary Tests.Release.test_caller_metadata.CallerMetadataTests.test_output_scope_rejects_external_path_before_creating_it`.

Der separate [Deploy-AppLock-Nachweis](../../Releases/1.0.0/json-schema-deploy-lock-qualification.json)
qualifiziert ausschließlich Windows SQL Server 2025/CU8/CL170 lokal: zwei
fehlgeschlagene Deploys unter jeweils gehaltener externer AppLock und den
erfolgreichen Deploy nach Lockfreigabe.
Der Bericht bindet das unveränderte Paket, die ausgeführten öffentlichen
Quellen, fünf aufgeräumte Fehlversuche und sechs unabhängige Audits; er enthält
keine privaten Runsets oder Runtimewerte. Vier Offlineprüfungen kontrollieren
Scope, Quellenpins, positive Kontrollen, Audit und Fehlerhistorie in der
bestehenden Release-Suite. Gezielt lokal:
`python -B -m unittest Tests.Release.test_json_schema_deploy_applock_qualification -v`.
Weitere Versionen, Plattformen, Deploymentmodi, Rechte- und Lifecycleprofile
werden dadurch nicht qualifiziert.

Der ergänzende [Uninstall-AppLock-Nachweis](../../Releases/1.0.0/json-schema-uninstall-lock-qualification.json)
qualifiziert ebenfalls ausschließlich Windows SQL Server 2025/CU8/CL170 lokal.
Zwei unabhängige Holder-Konflikte weisen nach, dass Uninstall vor der Mutation
mit dem jeweiligen Lifecyclefehler abbricht. Nach Freigabe gelingt derselbe
Uninstall; das Schema-Namespace bleibt leer erhalten und Core/ResultTable
bleiben unverändert. Ein Zielaufruf und ein unabhängiges Bereinigungsaudit
bestanden. Vier gezielte Offlineprüfungen binden Paket, öffentliche Quellen,
Sperrorakel und Audit in die bestehende Release-Suite ein. Lokal:
`python -B -m unittest Tests.Release.test_json_schema_uninstall_applock_qualification -v`.
Der Bericht qualifiziert keine weiteren Versionen, Kompatibilitätsstufen,
Plattformen, Deploymentmodi oder vollständigen API-/Rechte-/Lifecycleprofile.

Der [Caller-Transaktionsnachweis](../../Releases/1.0.0/json-schema-caller-transaction-qualification.json)
prüft zusätzlich Deploy bei fehlendem Schema und Uninstall bei installiertem
Schema auf Windows SQL Server 2025/CU8/CL170 lokal. Der Caller erhält
Transaktion, Savepoint, Modulzustand und Sessionoptionen; nach vollständigem
Rollback bestehen beide Lifecycleaufrufe ohne Callertransaktion. Das geprüfte
Startprofil lautet `QUOTED_IDENTIFIER ON`, `XACT_ABORT OFF`, `NOCOUNT OFF`.
Ein erfolgreicher Zielaufruf und beide unabhängigen Cleanup-Audits bestanden; ein früherer
Vorversuch wurde bereinigt und wird nicht als Fachfall gezählt. Vier gezielte
Offlineprüfungen binden Ergebnis, Ziel, Paket und öffentliche Quellpins in die
bestehende Suite ein. Lokal:
`python -B -m unittest Tests.Release.test_json_schema_caller_transaction_qualification -v`.
Andere Sessionprofile, Ziele und vollständige API-/Rechte-/Lifecyclematrizen
bleiben offen.

Der [Deploy-Kollisionsnachweis](../../Releases/1.0.0/json-schema-deploy-collision-qualification.json)
prüft vier feste Fehlerpfade für reservierten Callerzustand, öffentliche und
interne Fremdslots sowie einen verwaisten DeploymentMode-Marker. Ein gemeinsamer
positiver Deploy folgt erst nach Entfernung aller eigenen Fixtures. Ein
Zielaufruf und ein unabhängiges Cleanup-/Pin-Audit bestanden; neun Offline-
Report-/Adapterprüfungen laufen in der bestehenden Release-Suite. Lokal:
`python -B -m unittest Tests.Release.test_json_schema_deploy_collision_qualification Tests.Release.test_json_schema_deploy_collision_adapter -v`.
Der Nachweis beschränkt sich auf Windows SQL Server 2025/CU8/CL170 lokal und
schließt keine vollständige Lifecycle- oder Ownershipmatrix.

Der [zentrale Uninstall-Bestätigungsnachweis](../../Releases/1.0.0/json-schema-uninstall-confirmation-qualification.json)
prüft die festen Ablehnungen für `01` und `0` (55635/State 1), danach einen
erfolgreichen Uninstall mit `1`. Sessionprofil, Modul-/Corezustand und das
erhaltene `toolbelt_json`-Namespace sind Teil des Orakels. Qualifiziert ist
ausschließlich Windows SQL Server 2025/CU8/CL170, zentral, mit
`QUOTED_IDENTIFIER ON`, `NOCOUNT ON`, `XACT_ABORT ON` und
`IMPLICIT_TRANSACTIONS OFF`. Drei frühere bereinigte Harnessfehler und vier
unabhängige Audits sind im Bericht getrennt ausgewiesen. Fünf fokussierte
Reportprüfungen und vier Adapterprüfungen laufen in der bestehenden Release-Suite; lokal:
`python -B -m unittest Tests.Release.test_json_schema_uninstall_confirmation_qualification Tests.Release.test_json_schema_uninstall_confirmation_adapter -v`.
Andere Sessionprofile, Modi, Zielkombinationen und vollständige Lifecycle- oder
Rechtematrizen bleiben offen.

## Edit-Distance-Paketqualifikation

Der [Edit-Distance-Bericht](../../Releases/1.0.0/EDIT-DISTANCE-PACKAGE-QUALIFICATION.md)
bindet die DLL aus dem Installationspaket an feste Distance- und Jaro-Orakel.
Vier Berichtstests prüfen aktuelle Quellpins, Paket-/Oraclewerte und
Scopegrenzen; sie laufen über `test_caller_metadata.py`. Der separate
Qualifikationsrunner verwendet die geprüfte versteckte Prozesskette; SQL und
Lab werden nicht gestartet.

## T-SQL-Scriptparser-Paketbindung

Der [Scriptparser-Bericht](../../Releases/1.0.0/SCRIPT-PARSER-PACKAGE-QUALIFICATION.md)
bindet 63 feste Provideraufrufe an die Paket-DLL. Ein separat aus Quellen
gebauter Guard prüft 60 Assertions und ist kein Paketnachweis. Vier gezielte
Offlinekontrollen (Paket, Sidecar, Qualifikationshash, ZIP-Traversal) sowie
Report- und Korpusdriftprüfungen sind in `test_caller_metadata.py` integriert.
Es gibt keinen SQL- oder Labstart.

## CSV-/Phonetic-Framework-Paketprofile

Der [gebundene Bericht](../../Releases/1.0.0/CLR-FRAMEWORK-PACKAGE-QUALIFICATION.md)
verknüpft die unveränderten Frameworkharnesses mit den CSV- und Phonetic-DLLs
aus dem Installationspaket. Zwei Berichtstests prüfen den exakten Scope,
aktuelle zehn Quellpins, Paketbytes und Negativkontrollen; beide sind in
`test_caller_metadata.py` integriert. Gezielter Lauf:

```powershell
python -B Tests/Release/test_caller_metadata.py CallerMetadataTests.test_candidate_framework_public_evidence_is_exactly_package_bound CallerMetadataTests.test_candidate_framework_report_scope_and_pin_drift_are_rejected -v
```

Die Prüfungen führen kein SQL aus und wiederholen die Frameworkharnesses nicht.

## CSV-Caller mit kombinierten Objektrechten

Die anschließende [CSV-Metadaten-/Paketprüfung](../../Releases/1.0.0/CSV-METADATA-UPDATE.md) erhält den alten Bericht und prüft Manifestfeld, Produktdelta, CLR-Payload und Recoverygrenzen separat. Einzelprüfung: `python -B Tests/Release/test_csv_metadata.py`; sechs Prüfungen laufen in der vorhandenen Release-Suite.

Die [CSV-Rechteprüfung](../../Releases/1.0.0/CSV-CALLER-PROFILE.md) beschreibt `Invoke-CsvCallerLab.ps1` und `Runtime/Csv.CallerRights.sql`; `python -B Tests/Release/test_csv_caller_profile.py` prüft den Bericht offline. Vier Prüfungen laufen zusätzlich in der bestehenden Release-Regressionssuite, ohne neue CI-Jobs.

## Textpaar-Caller mit einzelnem EXECUTE

Der [Textpaarbericht](../../Releases/1.0.0/TEXT-PAIRS-CALLER-QUALIFICATION.md) beschreibt `Invoke-TextPairsCallerLab.ps1`, `Runtime/TextPairs.FunctionCases.sql`, die kanonische Komposition und private Runset-/Pin-/Labfensteranforderungen. Drei Algorithmen werden gegen feste Werte geprüft. Die bestehende Release-Regressionssuite bindet den Bericht; zusätzlich `python -B Tests/Release/test_text_pairs_caller_qualification.py`.

## JSON-Schema-Caller mit drei Objektrechten

Der [JSON-Schema-Bericht](../../Releases/1.0.0/JSON-SCHEMA-CALLER-PROFILE.md) beschreibt `Invoke-JsonSchemaCallerLab.ps1`, `Runtime/JsonSchema.CallerRights.sql`, das genaue Rechteprofil, private Runset-/Pin-Anforderungen und die separate Offlineprüfung `python -B Tests/Release/test_json_schema_caller_profile.py`. Die vorhandenen gemeinsamen Konfigurations-/Trusthelfer bleiben unverändert. Neue Tests ändern keine Produktfunktion; alle ursprünglichen Nachweise bleiben gebunden.

## CLR-String-Caller mit eigenem Trust-/Konfigurationsjournal

Der [CLR-Callerbericht](../../Releases/1.0.0/CLR-STRING-CALLER-QUALIFICATION.md)
verwendet `Runtime/ClrString.FunctionCases.sql` und den unveränderten
`prepare_function_rights.py`-Composer. `Invoke-ClrCallerLab.ps1` ist der neue
begrenzte Labtreiber; `ClrCaller.Environment.ps1` kapselt ausschließlich seine
Konfigurations- und Verbraucherprüfungen. Die bisherigen T-SQL-/CLR-Treiber
werden nicht geändert. Produktfunktionen sind durch diese Welle nicht erweitert.

```powershell
pwsh -NoProfile -NonInteractive -File Tests/Release/Test-ClrCallerSafety.ps1
python -B Tests/Release/test_clr_caller_qualification.py
python -B Tests/Release/test_prepare_release.py FunctionCallerQualificationTests
```

Erwartet werden zehn isolierte Sicherheitsfälle ohne SQL-Verbindung sowie
Offlineprüfungen der aktuellen CLR-Berichts-/Kompositions-/Quellbindungen.
Die bestehende Release-Regressionssuite prüft auch diese Callerprojektion;
neue CI-Jobs oder Trigger entstehen nicht.

Ein neuer privater Runset unter `.runtime` benötigt `schema_version` gleich
`clr-caller-contract/v1`, die unveränderte zwölfteilige T-SQL-Zielmatrix,
`contract_sha256`, `module_versions`, die komponierte `fixture`, `exports`
für local/central, genau zwei `artifacts` und alle tatsächlichen `pins`.
Die Closure besteht aus ResultTable1.0.0, Phonetic1.0.0 und EditDistance1.1.0.
Jedes private Artifact bindet `module_id`, privaten `path`, `sql_name`,
SHA256 und SHA512. Vor Verwendung Herkunft, zwei reproduzierbare Builds,
aktuelle Compile-Inputs und gepackte Bytes abgleichen. Keine unbekannten DLLs
vertrauen. Artefakte und ursprüngliche Nachweise privat unverändert einfrieren.

Die SQL-Exports entstehen verbindungsfrei über `Deployment/Deploy-All.ps1`
mit `ModuleVariables`: je CLR-Modul exakte `AssemblyBits` und
`ExpectedInstalledAssemblyHash` gleich `0x` für die neue eigene Datenbank.
Auf öffentliche Sourcepfade, beide Exports, Fixture, beide tatsächlichen DLLs,
Labvertrag/-schema/-Reader, Treiber, Umgebungsdatei und importierte CSV-/Release-
Helfer sind eindeutige Pins erforderlich. Der Treiber prüft Modulclosure,
installierte SAFE-Assemblybytes, Methodenbindungen und Objektdefinitionen.

Ausführung erfolgt mit `-RunsetPath` und `-CaseIndex`; anschließend separat
mit `-AuditOnly`. Der private unveränderliche Casejournalname bleibt erhalten.
Nie einen bereits versuchten Case erneut verwenden. Bei geänderten Inputs
neue Journale anlegen oder eine ausdrücklich begründete Wiederverwendungs-
bindung separat nachweisen. Auditprojektionen sind keine neuen Qualifikationen.

Notwendige CLR-Aktivierung erfordert unveränderte Strict Security, keine echten
Pending-Änderungen und vollständige Sicht auf fehlende Benutzerassemblies.
Dokumentierte Engine-Normalisierungen werden eng erkannt; Speicheroptionen
werden nicht gesetzt. Bereinigung entfernt nur eigene DBs/Trusteinträge,
verifiziert vorbestehende Fingerprints und stellt eigenen Konfigurationsscope
nur bei passendem Journalzustand wieder her. Drift oder neue Verbraucher
blockieren statt fremden Zustand zu überschreiben. Parameterstände, Hashes,
private Ziele und Rohlogs bleiben ausschließlich in privaten Journalen.


## Event-Log-Caller mit exakter Rollback-Abschlussprüfung

`prepare_event_log_rights.py` verwendet unverändert den bisherigen Composer
und ergänzt ausschließlich `Runtime/EventLog.PostAssertions.sql` hinter dessen
gemeinsamer Abschlussprüfung. Reihenfolge: gemeinsamer Prelude,
`EventLog.FunctionCases.sql`, gemeinsame Assertions, eigener Postlude. Diese
vierte Datei prüft nach REVERT/Principal-Cleanup den Transaktions- und
Identitätszustand sowie die vollständige ursprüngliche synthetische Zeilenmenge.
Transaktions- und Metadatenprüfungen laufen in getrennten Statements.

```powershell
python -B Tests/Release/test_event_log_composition.py
python -B Tests/Release/prepare_event_log_rights.py --output .runtime/contoso-event-log-inputs
```

Erwartet werden drei Offlineprüfungen und zwei Dateien in einem neuen privaten
Ausgabeordner: `FunctionRights.sql` und `composition.json`. Der Compiler führt
kein SQL aus und verweigert vorhandene oder öffentliche Ausgabeziele. Bestehende
Evidenz wird nicht überschrieben. Der unveränderte native T-SQL-Runsetvertrag
bindet danach alle vier SQL-Teile, beide Composer und die tatsächlichen
Installations-/Treiberbytes. Die bestehende Release-Regressionsprüfung bindet
auch die vierteilige Komposition und den [Callerbericht](../../Releases/1.0.0/EVENT-LOG-CALLER-QUALIFICATION.md).
Es entstehen keine neuen CI-Jobs oder Trigger und keine Wiederholung älterer
unveränderter grüner Matrixfälle. Bei Kompositions-/Pinfehlern zuerst die festen
Quellteile und den neuen privaten Zielordner prüfen; den nativen Lauf nicht mit
veränderten Altjournalen wiederholen. Frühere bereinigte Versuche bleiben im
Bericht getrennt erhalten.


[Event Log: Lesen und lokale Retention mit Einzelrechten](../../Releases/1.0.0/EVENT-LOG-CALLER-QUALIFICATION.md): 3 APIs, zwölf Fälle lokal/direkt zentral, 72 Einzelgrantprofile und 648 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[Providerview mit einzelnem SELECT-Recht](../../Releases/1.0.0/PROVIDER-CALLER-QUALIFICATION.md): 1 APIs, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 144 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[JSON Pointer mit einzelnem SELECT-Recht](../../Releases/1.0.0/POINTER-CALLER-QUALIFICATION.md): 1 APIs, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

Die feste `Catalog.FunctionCases.sql` verwendet denselben historischen Composer für die bestehende View: feste Ownerprojektion von fünf Markergruppen, darunter drei synthetische Testgruppen. Das reine SELECT-Callerprofil erlaubt die vertragliche kleinere/leere Metadatensicht und verwirft zusätzliche oder abweichende sichtbare Zeilen. Kein VIEW DEFINITION, keine neue Registry und keine Produktobjektänderung. Die Marker liegen ausschließlich in den eindeutig eigenen, anschließend entfernten Testdatenbanken.

[Capability-Katalog mit einzelnem SELECT-Recht](../../Releases/1.0.0/CATALOG-CALLER-QUALIFICATION.md): 1 APIs, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

Der historisch benannte Funktions-Composer wird auch für die vorhandene Konsolen-Prozedur verwendet: Die gemeinsame Fixture prüft deklarierte SELECT-/EXECUTE-Objektrechte ohne Annahme eines Funktionstyps. Die feste `Console.FunctionCases.sql` ergänzt nur Rückgabe-/Fehler-/Transaktionsorakel; der native Treiber bleibt unverändert. Nachrichtendarstellung und Clientreader behalten ihren eigenen Nachweis.

[Konsolenausgabe mit einzelnem EXECUTE-Recht](../../Releases/1.0.0/CONSOLE-CALLER-QUALIFICATION.md): 1 APIs, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[JSON-Pfade mit getrennten SELECT-Rechten](../../Releases/1.0.0/JSON-PATH-CALLER-QUALIFICATION.md): 2 APIs, zwölf Fälle lokal/direkt zentral, 48 Einzelgrantprofile und 192 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.


Die [additive Date-Math-Ergänzung](../../Releases/1.0.0/DATE-MATH-CL-COMPLETION.md) schließt die sechs niedrigeren CL-Callerfälle. Insgesamt zwölf Fälle mit unveränderter Fixture sind gebunden; der frühere Teilscope bleibt historisch erhalten. Offline zusätzlich prüfen: `python -B Tests/Release/test_additive_caller_qualification.py`.

## Eigenständiges Stable-SQL-Paket reproduzieren

`Scripts/Release/prepare_stable_sql_package.py` benötigt nur Python3.10+ und die
versionierten Releaseinputs. Es führt kein SQL, keinen Build und keinen
Netzwerkaufruf aus. Die bestehende 19-Modul-Kanalzuordnung bleibt maßgeblich.

```powershell
python -B Scripts/Release/prepare_stable_sql_package.py verify
# Einen neuen vorhandenen privaten Ordner verwenden; Dateien dürfen nicht existieren:
python -B Scripts/Release/prepare_stable_sql_package.py build `
  --output .runtime/stable-sql-new/SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip
python -B Scripts/Release/prepare_stable_sql_package.py verify `
  --output .runtime/stable-sql-new/SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip
```

Das Werkzeug liest nur drei feste Dateinamen aus dem prüfsummenverifizierten
Quellarchiv und extrahiert nichts. Beide SQL-Hashes müssen exakt zur kanonischen
nativen Qualifikation passen, die Lizenz zu `LICENSE.md`; hinzu kommen die
[Paketanleitung](../../Releases/1.0.0/STABLE-SQL-INSTALL.md), Manifest und
Dateiprüfsummen. Geänderte Herkunftsinputs, Dateien, ZIP-Metadaten, zusätzliche/
fehlende/doppelte/Pfad-/Symlink-Einträge, Größenüberschreitungen oder vorhandene
Ausgaben werden abgewiesen. Ein Fehler erfordert Prüfung des betroffenen Inputs;
keinen Hash anpassen, um eine Abweisung zu umgehen. Erneut in einen neuen
Ausgabeort bauen. ZIP und Prüfsumme immer gemeinsam aus demselben Stand liefern.
Die Einträge verwenden ZIP_STORED mit festem Datum und festen Dateiattributen;
dadurch hängt der exakte Containervergleich nicht von Deflate-/zlib-Versionen ab.

Die Tests in `test_prepare_release.py` prüfen Reproduktion und gezielte Drift.
Das Manifest unterscheidet heutigen Quellarchivhash und historischen nativen
Archivhash; nur die exakt gleichen SQL-Payloads übernehmen ihren bisherigen
12-Fall-Scope. Die neue Verpackung erhält keinen neuen nativen GUI-/Anmeldungs-,
TLS-, API- oder Lifecycle-Nachweis. Das Gesamtquell-/CLR-/SSIS-Paket wird dabei
nicht neu gebaut; `prepared_not_published` bleibt verbindlich.

## Native Funktions-Callerrechte prüfen

`prepare_function_rights.py` komponiert drei feste öffentliche SQL-Teile ohne
SQL-/Labzugriff: Scope-/Tabellendeklarationen aus `FunctionCaller.Prelude.sql`,
eine explizite `*.FunctionCases.sql` und `FunctionCaller.Assertions.sql`.
Die Bytekomposition ist `b'\n'.join(parts) + b'\n'`; öffentliche Teile müssen
bereits vor dem Einfrieren den kanonischen Git-Bytes entsprechen.

```powershell
python -B Tests/Release/prepare_function_rights.py `
  --cases Tests/Release/Runtime/Conversion.FunctionCases.sql `
  --output .runtime/function-conversion-new
```

Der Ausgabeordner unter `.runtime` darf nicht existieren. Die Ausgabe besteht
aus `FunctionRights.sql` und `composition.json`; Pfade/Hashes der drei Teile
machen die Komposition nachvollziehbar. Nur kanonische Falldateien aus dem
Runtime-Verzeichnis sind zugelassen. Der Stager installiert oder verbindet nichts.

Danach gilt der [bestehende T-SQL-Runsetvertrag](#weitere-tsql-callerrechte-prüfen):
exakte Modulclosure, verbindungslos erzeugte lokale/zentrale Exports, Quellen-,
Kompositions-, Treiber- und Labpins, schema-valider expliziter Zielkontext.
`Invoke-TsqlContractLab.ps1` bleibt unverändert. Jeder native Fall hat eine
Budgetreservierung, ein einmaliges eigenes Journal, 300/360/400-Sekunden-
Arbeits-/Cleanup-/äußere Grenzen und einen separaten 90-Sekunden-Audit.
Kein Replay vorhandener Journale, kein Fallback, keine fremde Bereinigung.

Die eigene Fixture prüft fehlendes/einzelnes/entzogenes Recht, feste kardinalitäts-
und NULL-sichere Wertorakel, direkte Geschwister-/Dependency-/Helperabweisungen
mit genau SQL229 sowie fehlende breite Rechte. Ein falscher Festwert und ein
zusätzliches Objektrecht dienen als frische negative Kontrollen. Der
[Konvertierungsbericht](../../Releases/1.0.0/CONVERSION-CALLER-QUALIFICATION.md)
begrenzt die tatsächliche Matrix und bewahrt alle Vorläufer. Die Tests in
`test_prepare_release.py` prüfen Komposition, Inputs und Berichtsgrenzen ohne
Labmutation. Keine neuen Jobs und keine automatische Native-Testausführung.

Die [Series-/Datumsqualifikation](../../Releases/1.0.0/SERIES-DATE-CALLER-QUALIFICATION.md)
verwendet denselben Ablauf mit `Runtime/SeriesDate.FunctionCases.sql` und genau
ResultTable/GenerateSeries/DateSpine/Truncate1.0.0. Der Legacy-Nullschritt wird
mit SQL8134 geprüft; er wird nicht mit INVALID der begrenzten Status-TVF
vertauscht. Die drei ursprünglichen Fixtureversuche bleiben getrennt erhalten.

Die [Utilityqualifikation](../../Releases/1.0.0/UTILITY-CALLER-QUALIFICATION.md)
verwendet `Runtime/Utility.FunctionCases.sql` mit fünf Utilitymodulen und
GenerateSeries/ResultTable. Der identische Controller unterscheidet TVF-SELECT
und Scalar-EXECUTE, direkte Dependencyabweisung und intern erlaubte Ownershipkette.
Für Sort Keys gelten opake Ordnungs-/Präzedenzorakel statt eines erfundenen
versionsübergreifenden Binärformats. Keine neuen Jobs oder automatischen Labtests.

Die [ausgewählte Date-Math-Qualifikation](../../Releases/1.0.0/DATE-MATH-HIGHEST-CL-QUALIFICATION.md)
verwendet `Runtime/DateMath.FunctionCases.sql` mit ResultTable/DateBucket/
CalendarDifference. Aus dem unveränderten zwölfteiligen Runset werden vorab
nur die sechs höchsten CL je Plattform/Engine ausgewählt: Indizes0/2/5/6/8/11.
Im historischen Teilbericht wurden die übrigen sechs Einträge als not executed
projiziert. Die [additive CL-Ergänzung](../../Releases/1.0.0/DATE-MATH-CL-COMPLETION.md)
führt genau diese Indizes1/3/4/7/9/10 neu aus und bindet die bisherigen sechs Fälle
und zwei Kontrollen nach exaktem Inputvergleich und frischen Abschlussaudits. Zwei frische Gegenkontrollen und alle eigenen Abschlussaudits
bleiben Pflicht. Ein eigener Teilscope-Test ersetzt oder lockert keinen der
bestehenden zwölfteiligen Callerberichtstests.

## API- und Grenzqualifikation

`api-qualification-spec.json` benennt die 165 ausgewählten kanonischen
Fixtures, ihre Adapter und die gezielten Ergänzungen. Der
[Ergebnisbericht](../../Releases/1.0.0/API-QUALIFICATION.md) und die
[45-Modul-Zuordnung](../../Releases/1.0.0/EVIDENCE-MAP.md) begrenzen den
Nachweis. Modulmanifeste bleiben die Quelle der alten Evidenz; diese Liste
ist keine zweite allgemeine Testregistry und wertet keine Module auf.

Nach Paketprüfung und dem unten beschriebenen Erzeugen eines neuen privaten
Complete-Payloads (oder bei verifiziert bytegleichem vorhandenem Payload):

```powershell
python -B Tests/Release/prepare_api_qualification.py `
  --source-zip Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip `
  --complete-input .runtime/complete-new/complete.zip `
  --output .runtime/api-new-inputs
./Tests/Release/Invoke-ApiQualificationMatrix.ps1 `
  -InputDirectory .runtime/api-new-inputs -PlanOnly
./Tests/Release/Invoke-ApiQualificationMatrix.ps1 `
  -InputDirectory .runtime/api-new-inputs `
  -EvidenceDirectory .runtime/api-new-run -FreezeOnly
```

Diese Schritte bauen keine DLL und verbinden sich nicht mit SQL Server.
Der Stager prüft das ausgelieferte Paket, unveränderte Produktquellen und
SQL-/DLL-Payloads, übernimmt die kanonischen Fixturebytes und erzeugt zwei
synthetische XLSX-Eingaben. Relative Kompositionshelfer behalten ihre
kanonischen Hashes. Der Plan umfasst 74 Ziel-/CL-/Gruppenfälle mit eigenen
Datenbanken für local/central/Consumer. Die Auswahl ergänzt insbesondere
SQL2022/CL150, niedrigere SSIS-CLs und noch unbelegte CSV-Grenzziele.
Core, Text, Formate, CSV und strikte Cancellation-Negativfälle haben je zwölf
Fälle; Parser/TableClone/SSIS sechs Windows-Fälle; acht getrennte Translate-
Großfälle ergänzen die noch nicht belegten Ziele. Die vollen Safe-Cast- und
JSON-Pointer-Matrizen sowie bereits gültige unveränderte CSV-/Translate-
Großnachweise werden in ihrem tatsächlichen Scope wiederverwendet.

Vor nativer Ausführung Zusatzprompt lesen, Labvertrag/Schema prüfen, aktuelle
Verbraucher und vorhandene Rechte klären sowie gegebenenfalls die separat
autorisierte temporäre CLR-Konfiguration privat journalisieren. Erst danach:

```powershell
./Tests/Release/Invoke-ApiQualificationMatrix.ps1 `
  -FrozenRunset .runtime/api-new-run/runset.json
```

Jeder Fall hat einen eigenen äußeren Watchdog und einen separaten
Cleanup-/Pinaudit; auch `FAILED_CLEANED` verlangt diesen Audit. Unbekanntes
Cleanup stoppt weitere Mutationen bis zur Reconciliation. Korrekturen
brauchen neue relevante Inputs, einen neuen privaten Evidenceordner,
`-ChangedInputReason` und denselben `-SharedBudgetFile`; Start, verbrauchte
Versuche und erfolgreiche Fälle bleiben erhalten. Keine blinden Retries.
Nach allen Verbrauchern sind eigene Konfiguration und Trustzustände
wiederherzustellen und unabhängig zu prüfen.

Die gemeinsame Obergrenze ist 90 Case-/Recoveryversuche und 36000 Sekunden
ab dem ursprünglichen Start. Arbeitszeit/Cleanup-Gesamtdeadline/äußerer
Watchdog sind in Sekunden 300/360/400 für gewöhnliche Fälle,
960/1200/1240 für Core, 1800/2160/2200 für Formate und CSV sowie
1200/1440/1480 für große Translate-Fälle. Je Fall bleiben zusätzlich
90 Sekunden für den unabhängigen Audit reserviert. Das sind Harnessgrenzen;
die öffentlichen Ressourcen- und intrinsischen Regex-Zeitbudgets ändern sich
dadurch nicht.

`-CarryForwardCases <privates-case-journal>` übernimmt ausschließlich einen
vom Adapter ausdrücklich unterstützten, vollständig bestandenen Präfix nach
konkretem Befund. Das eingefrorene Runset bindet altes Journal, alten Runset
und damaligen Audit. Vor neuen Mutationen prüft ein lesender Preflight erneut
Zielidentität, bereinigten Vorzustand, bytegleiche Produkt-/Fixtureinputs und
die tatsächlichen Kontexte. Abweichungen werden abgewiesen. Ein beobachteter
intrinsischer Regex-Timeout bleibt ein blockierter Fixtureaufruf und der
gesamte Fall `PARTIAL`; er wird weder als Erfolg noch als neuer Retry gezählt.
Die gemeinsame Fortschrittsdatei trennt vollständige und partielle Fälle.

Bei einem unerwarteten Fehler der kanonischen `Captures.Contract.sql`
ergänzt der API-Adapter ausschließlich im ausgeführten Testtext Phase und
Fallnummer. Die strikten Orakel, Produktbytes und der ursprüngliche SQL-Fehler
bleiben erhalten. Erfolgreiche Aufrufe erzeugen keine zusätzlichen Meldungen.
Auch ein als `PARTIAL` erfasster Regex-Timeout hält seinen vollständigen
Fehlertext samt CLR-Stack und synthetischem Unterfall im **privaten**
Casejournal (`blockedFixtures[].privateDiagnostic` und `privateFixtureCase`).
Diese Felder dürfen nicht in öffentliche Ergebnisse oder PRs kopiert werden.
Die Diagnose erklärt einen Fehler; sie hebt ihn weder auf noch erlaubt sie
einen unveränderten Retry. Die Offline-Regressionssuite prüft die bytegenau
erhaltene Fixture, Fail-closed-Verhalten bei Quelldrift und den gebundenen
Eventcallback über `Test-ApiCaptureDiagnostic.ps1`.
Der [Capture-Untersuchungsbericht](../../Releases/1.0.0/CAPTURE-TIMEOUT-INVESTIGATION.md)
trennt absichtliche Fehlerproben, bestandene Originalfixtures und die weiterhin
offene historische Ursache.
Die spätere [Capture-Abnahme](../../Releases/1.0.0/CAPTURE-RELEASE-ACCEPTANCE.md)
dokumentiert die ausdrücklich freigegebene Abschlussregel mit Restrisiko und
die zusätzliche `Runtime/Regex.Capture.Rights.sql`. Diese Fixture benötigt
den separat freigegebenen Aufbau eines Benutzers ohne Login in einer eigenen
temporären Testdatenbank; sie ist kein Installationsskript. Der native Scope
ist lokal/direkt zentral, keine Lowpriv-CrossDB-Anmeldung.

Die Coregruppe lädt die vorhandene `WorkTypeAuthorization.Fixture.sql`
ausschließlich in eigene disposable Datenbanken: explizite dbo-Policy für
alte Fachfixtures, kein Deploymentinclude, keine echten Minimalrechte.
Die zusätzliche Cancellation-Fixture prüft die dokumentierten Fehlernummern
strikt und beweist eine doomed Callertransaktion mit einem echten FK-Zeugen.
Die zusätzliche CSV-Fixture prüft die gemeinsame Default-16-MiB-Grenze mit
vollständigen Byte- und Erhaltungsorakeln; die beiden Direct-SELECT-Suiten
verwenden ihre kanonischen Clientorakel einschließlich erwarteter Fehler.

Für SSIS erzeugt `prepare_ssis_functional_fixture.py` eine private Ableitung
der kanonischen V1-Fixture: Nur der exakt begrenzte Principal-/Rechteblock
wird ausgelassen, sonstige Assertions bleiben bytegleich. Die drei fehlenden
niedrigeren Windows-CLs prüfen die funktionalen Fälle einschließlich NOLOCK-
Zeugen. Im zentralen Modus wird die eigene Consumerdatenbank ausdrücklich
übergeben; das tatsächlich generierte SQL wird ausgeführt. Diese Ableitung
qualifiziert keine SSIS-Minimalrechte. Direkte API-Metadaten verwenden den
kanonischen Metadatenhelfer.

Serverdatei-, Provider-, Principal- und harte Recoveryvoraussetzungen werden
dadurch nicht bereitgestellt. Erfolgreiche frühere Lifecycle-/Lastnachweise
werden nicht allein zur Statusauffrischung wiederholt.

Offline-Regressionsprüfung ohne SQL: `python -B
Tests/Release/test_prepare_release.py`. Die bestehende Dokumentations-CI
führt diese Suite aus; es gibt keinen zusätzlichen Workflow.

## Gemeinsamer Gesamtpaket-Test

Der freigegebene [Support-Zielumfang](../../Releases/1.0.0/SUPPORT.md) wird durch
`prepare_complete_package.py` aus dem tatsächlichen Gesamt-ZIP in private
Testinputs übersetzt. Es verwendet dessen Modul-/Deploymentquellen, fertig
mitgelieferte DLLs und kanonischen Offline-Exporter. Kein Build oder SQL-Zugriff.
Windows-local umfasst 45 Module, Windows-central 43, Portable-local/central
jeweils 40. Fehlende Plattformfähigkeiten begrenzen transitiv ihre Consumer.

```powershell
python -B Tests/Release/prepare_complete_package.py `
  --package Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip `
  --output .runtime/complete-new/complete.zip
./Tests/Release/Invoke-CompletePackageMatrix.ps1 `
  -PackagePath .runtime/complete-new/complete.zip `
  -EvidenceDirectory "$PWD/.runtime/complete-new-run" -PlanOnly
```

Das private Ausgabe-Elternverzeichnis muss neu angelegt werden. Native
Ausführung erfolgt nur nach Lesen des Labprompts, schema-validierter Auswahl,
Preflight und eingefrorenem Runset/Restbudget wie beim CLR-Paketadapter unten.
Der Defaultscope `full` verlangt Repeat und Absent-Repeat. Der ausdrücklich
getrennte Scope `install-uninstall` prüft Erstinstallation, feste Smoke-Oracles,
den unveränderten JSON-Pointer-Securityfixture, zentrale Consumer und einmaligen
Uninstall. Er qualifiziert **keinen** Repeat oder Absent-Repeat und ersetzt
keine API-/Minimalrechte-/Recoverymatrix. Die tatsächlichen Fälle, Fehler und
Blocker stehen im [Gatebericht](../../Releases/1.0.0/RELEASE-GATES.md).

Beide Scopes teilen bei Korrekturfortsetzungen denselben expliziten
`-SharedBudgetFile`. Die erste Diagnosewelle hatte 18 Caseversuche/7200 Sekunden.
Der anschließende ausdrückliche Auftrag zur Behebung beider Lifecyclefehler
erweitert den gemeinsamen Rahmen für die korrigierte Vollmatrix auf
30 Versuche/10800 Sekunden und für die dadurch erforderliche eigenständige
CLR-Paketabnahme auf insgesamt 42 Versuche/14400 Sekunden. Ursprünglicher Start,
verbrauchte Versuche und Teilnachweise bleiben erhalten; die Scopes besitzen
getrennte Fortschrittslisten. Kein Budgetreset. Bereits
vollständig qualifizierte Fälle werden nicht erneut ausgeführt. Das Journal
führt den ausgewählten Scope; Fehler bleiben Fehler. Neue abhängige Arbeit
setzt unabhängige Cleanup-/Inputaudits voraus. Der Runner verändert weder
Labinfrastruktur noch Rechte oder Logins; eine notwendige temporäre
CLR-Konfiguration wird separat unter der bestehenden engen Autorität
journalisiert und nach allen Verbrauchern wiederhergestellt.

## Vorgebaute CLR-Lieferung

Die [CLR-Installationsanleitung](../../Releases/1.0.0/CLR-INSTALL.md) ist der
Endanwenderweg. [prepare_clr_package.py](../../Scripts/Release/prepare_clr_package.py)
packt die zwei bereits bytegleichen Builds mit eingefrorenen Produktquellen;
SSIS-/Parser-/ScriptDom-Bytes bleiben aus dem bestehenden qualifizierten ZIP
erhalten. Ein neues privates Ausgabeverzeichnis und der vorhandene
`build-check.json`-Satz werden ausdrücklich übergeben:

```powershell
python -B Scripts/Release/prepare_clr_package.py --build-directory $QualifiedDoubleBuild `
  --output .runtime/clr-package-new/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip
python -B Scripts/Release/prepare_clr_package.py `
  --verify Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip
```

Das Ausgabeziel muss neu sein und sein Elternverzeichnis bestehen. Das Tool
kompiliert und verbindet sich nicht mit SQL. Der aktuelle Paketcheck bindet
DLLs und SQL an die tatsächlich ausgeführte Welle in `clr-qualification.json`;
veränderte SQL-/DLL-/Methodenbytes erfordern eine betroffene Neuabnahme.
Reine Dokumentationsänderungen werden nur bei exakt erhaltenen funktionalen
Payloads übernommen. Dateipfade, PE-/Buildpfadguard, Trustwerte, Profile und
innere/äußere Prüfsummen werden geprüft. Die Standardregressionssuite prüft
das echte versionierte CLR-ZIP zusätzlich; keine neue CI oder Labwelle.

`Invoke-ClrPackageMatrix.ps1` nutzt den schema-validierten Labvertrag und
zwölf explizite Windows-/Linux-/SQL-/CL-Fälle, mit den jeweiligen Windows-
beziehungsweise Portable-Profilen. Jeder Case hat 300/360 Sekunden Arbeit/
Cleanup und einen äußeren 400-Sekunden-Watchdog. Sämtliche Korrekturfortsetzungen
teilen eine private ursprüngliche Budgetdatei mit höchstens 18 Caseversuchen
und 7200 Sekunden; erfolgreiche Fälle werden nicht wiederholt. Eine Fortsetzung
ab `-StartCaseIndex` setzt das vollständig geprüfte Präfix voraus. Neue Quellen
werden in einem neuen privaten `EvidenceDirectory` eingefroren und verwenden
denselben `SharedBudgetFile`; jeder Versuch bleibt getrennt. Automatische
Retries, Provider-/Trustfallbacks und Labinfrastrukturverwaltung fehlen.

Der Adapter setzt bereits aktiviertes CLR und vorhandene administrative Rechte
voraus. Die stehende enge Testkonfigurationsfreigabe kann separat mit privatem
Vor-/Wiederherstellungsjournal verwendet werden. Der Case übernimmt keine
pauschale Serverkonfiguration. Neue Trusteinträge bekommen eine eindeutige
eigene Beschreibung und vollständigen Fingerprint; Consumer-/Datenbankdrift
blockiert Cleanup. Vorbestehender Trust bleibt erhalten. Ein separater Prozess
prüft anschließend Datenbankabwesenheit, Trustfingerprints und Inputpins.
Der konkrete [Gatebericht](../../Releases/1.0.0/RELEASE-GATES.md) grenzt die
tatsächliche Installation von einer vollständigen neuen API-/Releaseabnahme ab.

Für geänderte Installations-SQL kann ein neuer privater CLR-Testkandidat mit
`prepare_clr_package.py --unqualified-candidate` gebaut werden. Er bleibt
ausschließlich unter `.runtime`, trägt `qualification_state=pending`, enthält
keinen vorgetäuschten Qualifikationsnachweis und wird vom normalen Prüfmodus
abgewiesen. Der native CLR-Matrixrunner akzeptiert ihn nur mit dem ebenfalls
ausdrücklichen Schalter `-UnqualifiedCandidate`. Erst nach realer Abnahme werden
Qualifikationsprojektion, endgültiges Paket und deren Bindungen erneuert;
der öffentliche Releaseplan akzeptiert keinen ungeprüften Kandidaten.

## Quellpaket und gemeinsame Regressionen

Die Tests prüfen den [Releasegenerator](../../Scripts/Release/prepare_release.py)
und die [v1.0.0-Freigabematrix](../../Releases/1.0.0/README.md). Es werden
keine SQL-Verbindungen, Labressourcen, Builds, Tags oder Veröffentlichungen erzeugt.

```powershell
python -B Tests/Release/test_prepare_release.py
```

Geprüft sind transitive Kanalbegrenzung und Dependencyfehler, unveränderter
Publikationsstatus, Manifest-/Matrixdrift, Ausschluss privater Pfade,
ZIP-Pfadsicherheit, Symlinks und doppelte Pfade. Der vorhandene
Dokumentationsvalidator ruft diesen Test impactbezogen auf.

Der tatsächliche Paketbau ruft zusätzlich den vorhandenen verbindungsfreien
SQL-Exporter für die stabilen Kandidaten lokal und zentral auf. Der anschließende
Prüfmodus vergleicht alle Dateien, Prüfsummen und den eingefrorenen Gitstand.
Die generierten SQL-Dateien werden erneut offline exportiert und bytegenau
verglichen; ein nachträglich passend gehashtes SQL kann diese Bindung nicht ersetzen.
Das ist eine Packagingprüfung; eine native Installation oder die fachliche
Veröffentlichungsabnahme wird daraus nicht abgeleitet.

## Natives stabiles Paket im Lab prüfen

Der [Matrixrunner](Invoke-StablePackageMatrix.ps1) prüft die tatsächlich
gepackten `Install-Stable-local.sql` und `Install-Stable-central.sql` für die
19 stabilen Kandidaten. Er verwendet ausschließlich den schema-validierten
Labvertrag, dessen Zusatzprompt vor dem Aufruf gelesen werden muss. Es gibt
keinen Provider- oder TLS-Fallback. Die jetzige endliche Auswahl umfasst
zwölf Kombinationen: Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und
SQL2025 CL150/160/170. Weitere bereite Patchziele überschreiten diese
Runsetgrenze und werden nicht stillschweigend weggelassen oder nachgetestet.

```powershell
[void][IO.Directory]::CreateDirectory("$PWD/.runtime")
./Tests/Release/Invoke-StablePackageMatrix.ps1 `
  -EvidenceDirectory "$PWD/.runtime/release-native-new" -PlanOnly
./Tests/Release/Invoke-StablePackageMatrix.ps1 `
  -EvidenceDirectory "$PWD/.runtime/release-native-new"
```

`-PlanOnly` verbindet sich nicht mit SQL und legt kein Evidenzverzeichnis an.
Der eigentliche Lauf benötigt ein neues direktes privates Arbeitsverzeichnis
unter `.runtime`, vorhandene administrative Testrechte und die vollständigen
Paketprüfwerkzeuge. Der Runner prüft das Archiv vor SQL, friert Eingaben und
Auswahl ein und startet pro Fall einen eigenen Prozess mit äußerem
400-Sekunden-Watchdog. Der Fall besitzt 300 Sekunden Arbeits- und insgesamt
360 Sekunden einschließlich Cleanupbudget; die ganze Matrix höchstens 4800
Sekunden. Kein automatischer Retry und keine neue Testwelle bei Fehlern.

Jeder Fall erzeugt drei eigene Datenbanken, prüft SQL-Version/Plattform und CL,
installiert den jeweiligen Gesamt-Export in frischer Sitzung und wiederholt ihn.
Die 19 Versions-/Modusmarker sowie Objektdefinitionen müssen erhalten bleiben.
Fünf feste Smoke-Oracles prüfen Series, Base64, Date Spine, JSON Path Exists
und ResultTable auch über den zentralen Consumerpfad. Reverse Dependencyorder
und zweimaliger Uninstall dürfen keine Modulobjekte/-marker zurücklassen.
Die Paketprüfung ersetzt keine erneute vollständige Qualifikation aller APIs.

Vor DROP werden eigener Name, Datenbank-ID, Erstellungsidentität, eigener
Marker und Bereinigungssichtbarkeit geprüft. Ein gesonderter Prozess prüft
anschließend lesend alle Namen auf Abwesenheit und die eingefrorenen Inputs.
Bei unbekannter Ownership oder Cleanup stoppt die Matrix. Journale und
Diagnosen bleiben privat; es werden keine Rechte, Logins, Serveroptionen,
Trusteinträge, Labressourcen oder fremden Datenbanken geändert.

Die rein lokalen Negativtests in `Test-StablePackageHarness.ps1` prüfen
Pfad-/Ownershipgrenzen und abgewiesene SQLCMD-Direktiven ohne SQL-Anmeldung.
Sie laufen innerhalb der bestehenden Release-Regressionssuite und des
Dokumentationsjobs; die native Matrix wird dadurch nicht gestartet.

## Skalarrechte und dokumentierte Produktrevision prüfen

Die zusätzliche [Regex-Skalarrechtequalifikation](../../Releases/1.0.0/REGEX-RIGHTS-QUALIFICATION.md)
verwendet im API-Harness einen eigenen, endlich ausgewählten SQL-Fixturescope.
Sie legt ausschließlich in eigenen temporären Datenbanken Benutzer ohne Login
an und prüft feste Werte, fehlende Rechte, REFERENCES allein, EXECUTE allein,
Rechteentzug sowie gesperrte interne Kerne. Die separate Projektion enthält
auch zwei absichtlich abgewiesene Orakelvarianten; diese sind keine funktionalen
Erfolge. Der Quellvergleich für die anschließende Rechte-Dokumentationskorrektur
erlaubt nur fünf konkrete SQL-Headerkommentare, bekannte Markdown-Seiten und
den engen Manifestnachtrag. Andere Runtime-, Versions-, Objekt- oder
Dependencyänderungen werden abgewiesen. Beide Produktstände sind aus den
gebundenen öffentlichen bzw. aktuellen Quellbundles rekonstruierbar;
unreferenzierte alte Gitobjekte sind dafür keine Voraussetzung.

## Optionalen CLR-Installer nativ prüfen

Der optionale ODBC-Clientpfad des bestehenden CLR-Paketharness wird in einem
privaten eingefrorenen Runset ausdrücklich mit `client = OdbcSqlcmd`,
`extractedPackage` und einem vorab gepinnten `sqlcmd` gewählt. Er ruft den
vollständigen Pakethelper mit dem freigegebenen vorhandenen SQL-Konto auf;
ohne Auswahl bleibt SqlClient erhalten. Paket, entpackte Metadaten, Helper,
Tool und Labvertrag müssen vor Mutationen gebunden sein. Runsets und
Zugangsdaten gehören nicht ins Repository. Umfang, unveränderte Grenzen und
Ergebnisse stehen im [Clientnachweis](../../Releases/1.0.0/CLR-CLIENT-QUALIFICATION.md).
Die vorhandenen Offline-Harnessprüfungen bleiben im selben Release-Testlauf;
es entsteht kein zusätzlicher CI-Job oder automatischer Labtest.

## CLR-Buildinputs isoliert prüfen

```powershell
python -B Scripts/Release/check_clr_builds.py `
  --msbuild $msbuild --output .runtime/release-clr-new
```

`$msbuild` benennt ein vorhandenes MSBuild mit .NET-Framework-4.8-Targeting-Pack,
zum Beispiel portabel über `vswhere` entdeckt. Das Tool installiert nichts und
verlangt einen unveränderten Produktbaum. Es baut alle zwölf CLR-Projekte in
zwei getrennten eigenen Git-Quellkopien. Die bereits enthaltene ScriptDom-DLL
wird gegen ihren kanonischen Pin geprüft; JSON und ZIP werden vor ihren
Consumers gebaut. Releaseflags schließen PDB-Daten aus, `PathMap` verwendet
einen synthetischen Pfad. Beide Builds müssen identische DLL-Bytes liefern.

Buildlogs, DLLs, SHA-256-/SHA-512-Kandidatenliste und Buildpfade bleiben im
neuen `.runtime`-Unterverzeichnis. Kein vorhandenes Buildartefakt wird ersetzt.
Ein Erfolg bestätigt Reproduzierbarkeit und die PE-/Buildpfadprüfungen,
keine vollständige IL-/Framework-/SQL-Abnahme, Trustfreigabe oder Auslieferung.
Neue Binaryhashes benötigen weiter ihren konkreten Qualifikations-/Consumer-
und Releaseumfang. Der [Gatebericht](../../Releases/1.0.0/RELEASE-GATES.md)
trennt diese Grenzen von den tatsächlich ausgeführten Pakettests.

## Execution Context mit einzelnen Objektrechten prüfen

`Runtime/ExecutionContext.Rights.sql` ist eine zusätzliche feste SQL-Fixture
für den bestehenden API-Harness. Sie legt ausschließlich in dessen eigenen
temporären Datenbanken einen Benutzer ohne Login an. Für jedes der fünf
öffentlichen APIs prüft sie fehlende Rechte, genau das eine vorgesehene
Objektrecht und dessen Entzug. Auch während der positiven Phase müssen die
vier anderen APIs mit SQL229 gesperrt bleiben. Feste Identitäts-/Contextwerte,
Nested-/Clear-Verhalten, TVF-Zeile und scalar/NULL sind unabhängig vorgegeben.
Ein vorhandener Principal oder Sessioncontext blockiert den Test.

Der [Rechtebericht](../../Releases/1.0.0/EXECUTION-CONTEXT-RIGHTS-QUALIFICATION.md)
und seine JSON-Projektion binden die tatsächlich abgeschlossene Zwölfermatrix,
zwei absichtlich verworfene Orakelvarianten und frische unabhängige Audits.
Produkt- und Paket-SQL-/DLL-Bytes blieben unverändert. Kein neuer CI-Job,
automatischer Labstart oder Replay einer bereits grünen Vollmatrix.

## Weitere T-SQL-Callerrechte prüfen

`Invoke-TsqlContractLab.ps1` verwendet die bereits geprüften begrenzten
SQL-/Pin-/Ownershiphelfer und einen expliziten Runset mit
`schema_version=tsql-release-contract/v1`. Die übrigen Pflichtfelder und
Pins entsprechen dem unten beschriebenen Work-Type-Testweg. Zusätzlich
nennt `module_versions` exakt die erwarteten Module mit Version; der
installierte Versionsmarkersatz muss vollständig passen. User-defined
Assemblies sind für diesen T-SQL-Weg ausgeschlossen.

```powershell
& Tests/Release/Invoke-TsqlContractLab.ps1 -RunsetPath $privateRunset -CaseIndex 0
# Neuer Prozess nach terminalem Fall:
& Tests/Release/Invoke-TsqlContractLab.ps1 -RunsetPath $privateRunset -CaseIndex 0 -AuditOnly
```

Die gebundene SQL-Fixture gehört jeweils zum ausdrücklich ausgewählten
Testumfang. Vorhandene Journale verhindern Replay; Fehler oder unbekannter
Cleanup verlangen Reconciliation statt neuer mutierender Fälle. Gemeinsames
Budget, 300/360/400-Sekunden-Grenzen und separaten Audit vor dem Start
reservieren. Ein Erfolg qualifiziert ausschließlich die tatsächliche Fixture.

`Runtime/SafeCast.Rights.sql` prüft sechs einzelne SELECT-Profile mit festen
Wert-/Fehlerorakeln und strikten Abweisungen der anderen APIs. Der
[Safe-Cast-Bericht](../../Releases/1.0.0/SAFE-CAST-RIGHTS-QUALIFICATION.md)
bindet die zwölf bestandenen Fälle und die verworfenen Orakelkontrollen.
Weitere Lifecycle-/CrossDB-/Recoverygates bleiben separat.

`Runtime/Cancellation.Rights.sql` verwendet denselben Treiber mit genau
Execution Context und Execution Cancellation 1.0.0. Drei isolierte Objektrechte
prüfen Request, TVF und SVF, ihre unbekannten/NULL-Zustände, Requesterbindung,
Context, Idempotenz und die gesperrte interne Tabelle. Der
[Cancellation-Bericht](../../Releases/1.0.0/CANCELLATION-RIGHTS-QUALIFICATION.md)
grenzt die zwölf Fälle von weiteren Quoten-/Lifecycle-/Recoveryverträgen ab.

`Runtime/Deterministic.Rights.sql` verwendet denselben Treiber für Deterministic
1.2.0 und ResultTable 1.0.0. Vier SELECT-TVFs und der direkte Lookup-EXECUTE-Pfad
sind isoliert; das zusätzliche Lookup-/Helperprofil bleibt getrennt. Der
[Pseudonymisierungsbericht](../../Releases/1.0.0/DETERMINISTIC-RIGHTS-QUALIFICATION.md)
bindet Festwerte, NULL-/Fehlerfälle, interne Abweisungen und Bereinigung.

`Runtime/QueueFrontend.Rights.sql` prüft Queue 2.1.0 mit ResultTable 1.0.0
und Work Type 1.2.0. Fünf Einzelgrants und der Legacyproducer mit zusätzlicher
Handler-Metadatensicht bleiben ausdrücklich getrennt. Der
[Queue-Frontend-Bericht](../../Releases/1.0.0/QUEUE-FRONTEND-RIGHTS-QUALIFICATION.md)
bindet Initialzustände, SQL229/51902, den leeren Blockerview-Scope und die
Bereinigung einschließlich des nicht akzeptierten ersten Fixtureversuchs.

`Runtime/SplitAdvanced.Rights.sql` prüft Split Advanced 1.1.0 mit ResultTable
1.0.0: zwei SELECT-TVFs, direkten USP-EXECUTE-Pfad und separaten Helperpfad.
Der [Split-Bericht](../../Releases/1.0.0/SPLIT-ADVANCED-RIGHTS-QUALIFICATION.md)
bindet Originaltokens, Unquote, NULL-/Fehlerfälle und sechs physische Ziele
bei jeweils höchstem CL. Der spätere
[CL-Abschluss](../../Releases/1.0.0/SPLIT-ADVANCED-CL-COMPLETION.md) ergänzt
die sechs niedrigeren CL-Kombinationen bei identischen Ausführungsinputs;
die bereits grünen Fälle und Orakelkontrollen werden nicht wiederholt.

`Runtime/QueueWorker.Rights.sql` prüft sieben direkte unmanaged Worker-APIs
und eine befüllte Blockerview. Claim benötigt zusätzlich Handler-EXECUTE;
die feste CLAIM-Policy bleibt separat. Der
[Worker-Bericht](../../Releases/1.0.0/QUEUE-WORKER-RIGHTS-QUALIFICATION.md)
bindet Persistenz-/Tokenorakel und Viewzustände, nicht vollständige Resultsets,
ResultTable-Workerpfade, Managed Admission oder Workerhost-/Providerverhalten.

## Kanonische Geo-SQL-Verträge auf weiteren Zielen prüfen

`Invoke-GeoContractLab.ps1` verwendet den vorhandenen T-SQL-Treiberfluss für
Pinprüfung, explizite Functional-Labauswahl, eigene Datenbanken, Objektvergleich
und unabhängige Cleanupaudits. Ein mechanischer Regressionstest hält diesen
Fluss bis auf die klar abgegrenzte Geoausführung identisch.

Nur die zusammengesetzte Geo-Fixture nutzt `GeoContract.Execution.ps1` mit
ExecuteNonQuery und höchstens 120 Sekunden je Batch wie der vorhandene
Geo-/Translate-Testweg. Restzeit begrenzt jeden Batch zusätzlich; die gesamte
Arbeitsphase bleibt auf 300 Sekunden begrenzt. Installation, Kontrollabfragen
und Cleanup behalten ihre vorhandenen 45-Sekunden-Grenzen und eigenen Fristen.
Das ist ein Funktionsprofil und keine Laufzeitzusage.

Der private Runset verwendet `schema_version = geo-functional-contract/v1`
und ausschließlich ResultTable 1.0.0 mit Deterministic 1.2.0. Die Fixture wird
bytegetreu als `b"\nGO\n".join(parts) + b"\n"` aus
`Runtime/OwnedTsqlScope.Guard.sql`, `GeoJitter.Contract.sql`,
`GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql` zusammengesetzt.
Die drei kanonischen Dateien liegen unter
`Modules/toolbelt.pseudonymization.deterministic/Tests/Runtime/`; keine Orakel
werden kopiert, umgeschrieben oder partitioniert. Der Guard normalisiert nur
die Capture-NULL-Defaults und verlangt den eigenen markierten Scope ohne
Callertransaktion. Payload, Teile, Treiber und Ausführungshilfe werden gepinnt.

`Test-GeoContractHarness.ps1` prüft offline den kanonischen Batchdeckel,
Restzeit, Ablehnung nach Fristablauf, Fehlerweitergabe und Command-Dispose.
Ungeklärte oder fremde Bereinigung verhindert weitere Mutation; ein
fehlgeschlagener Vorläufer wird nicht nachträglich als bestanden dargestellt.

Der [Geo-Ergänzungsbericht](../../Releases/1.0.0/GEO-MISSING-TARGETS-QUALIFICATION.md)
bindet acht positive Fälle, zwei verworfene Kontrollen, die erhaltenen Vorläufer
und den bereinigten Installationsfehler mit geprüftem frischem Nachfolger.

## Queue-Autorisierungsvertrag physisch prüfen

`prepare_queue_authorization.py` bindet den unveränderten kanonischen
`Authorization.Contract.sql` an den eigenen markierten Scope und schreibt
ausschließlich eine neue private SQL-Datei unter `.runtime`. Er setzt den
NULL-Default der eigenen Capture-Tabelle explizit; die ursprünglichen
fachlichen Orakel werden nicht verändert. Ein als Alias beziehungsweise
Reparse Point umgelenktes Runtimeverzeichnis wird vor der Ausgabe abgewiesen.

```powershell
python Tests/Release/prepare_queue_authorization.py --output .runtime/queue-wave/fixture.sql
& Tests/Release/Invoke-QueueAuthorizationLab.ps1 -RunsetPath $privateRunset -CaseIndex 0
# In einem neuen Prozess nach terminalem Fall:
& Tests/Release/Invoke-QueueAuthorizationLab.ps1 -RunsetPath $privateRunset -CaseIndex 0 -AuditOnly
```

Das private Runset hat dieselben Felder und Pflichtpins wie der folgende
Work-Type-Testweg, aber `schema_version=queue-authorization/v1`. Seine
verbindungslosen lokalen/zentralen Exports enthalten genau ResultTable,
Work Type und Work Queue. Generator, kanonischer Vertrag und ausgeführte
Fixturebytes sind ebenfalls gebunden. Der Caller reserviert Originalbudget,
300/360/400-Sekunden-Grenzen und separaten Audit; vorhandene Journale werden
nicht erneut ausgeführt. Ein unbekannter Cleanupzustand stoppt Folgeverbraucher.

Der [Qualifikationsbericht](../../Releases/1.0.0/QUEUE-AUTHORIZATION-QUALIFICATION.md)
und seine JSON-Projektion trennen zwölf bestandene Fälle und zwei verworfene
Orakelkontrollen. Sie belegen nur den aufgeführten Autorisierungsvertrag,
keinen vollständigen API-Mindestrechtesatz oder externen Workerbetrieb.

## Work Type mit getrennten Handler- und Policyrechten prüfen

`Invoke-WorkTypeRightsLab.ps1` prüft die feste `Runtime/WorkType.Rights.sql`
in eigenen markierten Datenbanken. Voraussetzung sind ein schema-valider,
explizit ausgewählter Labvertrag und ein privates eingefrorenes Runset unter
`.runtime`: `schema_version=work-type-rights/v1`, zwölf Ziel-/CL-Einträge in
`cases`, `contract_sha256`, `fixture`, die beiden verbindungslos erzeugten
`exports.local`/`exports.central` sowie vollständige SHA256-`pins`. Die Pins
umfassen Fixture, Exports, Harness, importierte Helfer, Labvertrag und Schema.
Die Exports enthalten nur `toolbelt.core.result-table` und
`toolbelt.core.work-type`; CLR- oder Serverkonfigurationsänderungen entfallen.

```powershell
& Tests/Release/Invoke-WorkTypeRightsLab.ps1 -RunsetPath $privateRunset -CaseIndex 0
# Erst nach terminalem Fall in einem neuen Prozess ausführen:
& Tests/Release/Invoke-WorkTypeRightsLab.ps1 -RunsetPath $privateRunset -CaseIndex 0 -AuditOnly
```

Ein erfolgreicher Fall meldet PASS für local/direct-central. Der neue Prozess
prüft anschließend erneut die Inputpins und die Abwesenheit eigener
Datenbanken. Jeder Index ist einmalig; vorhandene Journale verhindern Replay.
Ein Fehler verlangt Einsicht in das private Journal. `CLEANUP_BLOCKED` stoppt
abhängige Tests; Ownershipdrift wird niemals durch erzwungenes Löschen umgangen.
Arbeits-/Cleanup-/äußere Grenzen bleiben 300/360/400 Sekunden; der Caller
reserviert sein gemeinsames Budget und den separaten Audit vor dem Start.

Der [Rechtebericht](../../Releases/1.0.0/WORK-TYPE-RIGHTS-QUALIFICATION.md)
trennt zwölf erfolgreiche Fälle, zwei verworfene Orakelkontrollen und den
bereinigten ersten Fixturefehler. Die Prüfung ergänzt sechs isolierte APIs
einschließlich notwendiger Handler-/Policyrechte und interner DML-Abweisungen.
Sie verspricht weder echte CrossDB-Identitätsmappings noch vollständige
Work-Type- oder TLS-Qualifikation und startet keinen automatischen Labjob.

## ResultTable-/Error-Envelope-Callerprofile prüfen

`Runtime/ResultTable.ErrorEnvelope.Rights.sql` prüft die dokumentierten
Objektrechtkombinationen mit einem eigenen Benutzer ohne Login und einer
eigenen synthetischen Referenztabelle innerhalb der markierten Harness-DB.
Die fünf Profile betreffen Temp-Schema/KeepData, reine Referenz-Metadatensicht,
deren atomare Abweisung sowie direkte und ResultTable-Envelope-Ausgabe.
Rollen-, Schema-, datenbankweite und Servergrants sind ausgeschlossen.

Das Schemaorakel verwendet logische Spaltenpositionen, keine als fortlaufend
angenommenen physischen IDs. Die direkte Erfassung per INSERT EXEC erwartet
exakt den dabei sichtbaren Systemtransaktionszustand 1/1. Der
[Rechtebericht](../../Releases/1.0.0/TABLE-ENVELOPE-RIGHTS-INVESTIGATION.md)
bindet die zwölf tatsächlich bestandenen Ziel-/CL-Fälle, die anschließend
absichtlich verworfene Breitenkontrolle und die unabhängigen Abschlussaudits.
Vier frühere bereinigte Testfehler bleiben separat erhalten; der unveränderte
historische Zusatzrecht-Guard wird nicht als neuer Lauf ausgegeben. Offline-
Syntax und Strukturtests ersetzen keine native Qualifikation. Keine automatische
Labaktivierung und kein neuer CI-Job; echte CrossDB-Identitäten bleiben separat.


## Historische SSIS-Teilqualifikation aus PR #442

[SSIS-RELEASE-QUALIFICATION.md](../../Releases/1.0.0/SSIS-RELEASE-QUALIFICATION.md)
führt zu den damaligen SSIS-, ZIP-, CLR- und Gesamtpaketfällen.
Dieser Abschnitt beschreibt den früheren 36er-Rahmen; aktuelle Paketinputs
stehen im oben verlinkten Lookup-Nachweis.
`clr-ssis-qualification.json` und `complete-ssis-qualification.json` ergänzen
je sechs neue Windows-Kontexte; die alten Dateien bleiben als historische
Ausführungen erhalten. Portable SQL und die übrigen zwölf DLLs müssen exakt
unverändert sein, bevor die ursprünglichen sechs Linux-Fälle übernommen werden.

Der private Gesamtpaketexport unterstützt den gekoppelten Aufruf
`prepare_complete_package.py --package <qualifiziertes-vorgaenger-quellzip>
--product-commit <eingefrorenes-ssis-produkt> --clr-candidate <privates-pending-clr-zip>
--output <neues-privates-pruefzip>`. Alle Flags gehören zu einem Aufruf.
Er verlangt das gebundene SSIS-Produktdelta und den neuen Full12-Buildnachweis.
Das erzeugt ausschließlich einen privaten Testinput; keine neue Veröffentlichung.

Vor Mutationen wurden Runsets, Inputs, Ownership und der gemeinsame36er-Rahmen
mit unverändertem ursprünglichem Start festgelegt.34 native Treiberversuche,
alle unabhängig reconciled;300/360/400-Sekunden-Grenzen unverändert.
Keine neuen CI-Jobs oder Trigger und keine Delegation. Zusätzliche Offline-
Gegenproben schützen Projektwahl12 statt externem Host13, exakte Lieferbytes,
explizite Nachweisauswahl und beibehaltene historische Quellen. Vollständiger
Offlineaudit und echte aktuelle Head-CI ergänzen die Nativevidenz; sie ersetzen
keine noch offenen fachlichen oder externen Gates. Allgemeine Autonomie pausiert.


Die Recovery-Regressionen prüfen auch einen fehlenden lokalen synthetischen
Produktcommit. Der Baum muss aus dem bereits prüfsummen- und commitgebundenen
Bundle stammen; ein abweichender Baum oder ein beschädigtes Paket bleibt ein
Fehler. Historische CLR-Methoden werden ausschließlich bei Übereinstimmung mit
ihrem unveränderten ursprünglichen SHA-256 aus dem Quellen- oder Produktsnapshot
desselben Bundles gelesen. Änderungen ausgelieferter Installer- oder Methodenbytes
bleiben durch die bestehenden Paket-Negativtests gesperrt. Der Checkout-Objektstore
und seine Refs werden bei dieser Prüfung nicht ergänzt oder verändert.

Auch direkte Wiederherstellungen identischer Bundles teilen im Testprozess
dieselbe geprüfte Fixture. Der Schlüssel bindet zusätzlich Bundlebytes und
Quell-/Produktcommit; Scope- und Dependencywechsel sowie Fehler bleiben
Gegenproben. Keine Produktionsfunktion erhält einen Cache; die vollständige
Suite behält ihre 120-Sekunden-Grenze.
