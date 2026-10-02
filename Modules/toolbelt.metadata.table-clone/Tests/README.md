# Testausführung

Static: `python Modules/toolbelt.metadata.table-clone/Tests/Static/validate_contract.py`.
Labadapter: `pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -RunScripts run-table-clone-linux.sh -Versions 2019 -Platforms linux -LinuxPatches latest -StopOnFailure`.
Windows-Labadapter: `pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -RunScripts run-table-clone-linux.sh -Versions 2025 -Platforms windows -WindowsPatches CU8 -StopOnFailure`.
Runner validiert exportierten Schema-Vertrag; keine Infrastrukturänderung.
CI-Workflow registriert2019/2022/2025Linux, vorhandener Workflow ist keine Evidenz.

Historische Version1.0.0: Am2026-10-01 vollständige finale2019Linux/latest- und2025Windows/CU8-Adapter erfolgreich; Source,
Statementstruktur, Help-/Resultmetadaten, Indexshape und eigener/caller/doomed
Transaktionsscope geprüft. Weitere Zielversionen/GitHub/LowprivCrossDB offen.
Siehe [Testmatrix](TABLE_CLONE_CONTRACT_TEST_MATRIX.md).
Lifecycle-Caller-Tx: SQLCMD-Includes prüfen tatsächlichen Nonzeroexit; der
SqlClient-Metadatentest prüft die frühesten kanonischen Guard-Batches auf
derselben offenen Caller-Session bei XACT_ABORT ON/OFF mit Count/State,
synthetischen Daten und Modulmarker. Keine serverweite sys.messages-Änderung.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-03`
- Nachweis: `local: Tests/CI/run-table-clone-wave1-lab.ps1; begrenzter Root-Caller und unabhängiger Cleanup-Audit`
- Scope: Finaler öffentlicher W1-Labadapter am 2026-10-03 (lokales Datum; UTC 2026-10-02): SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures TableClone.Contract.sql, Wave1.Contract.sql, Wave1.DateTimeOffset.sql und Lifecycle.Contract.sql, Clientmetadata/Help/ResultTable, 27 Propertytypen samt Ownern und 18 datetimeoffset-Produktpfadroundtrips, Computed/PERSISTED/Filter, 2MiB-Atomik, Predicate-Injektionen, genuine 1.0-Upgrade, clean/repeat, Caller-TX/SET, AppLock, Rollback, Kollisions-/Dependency-Erhalt, Uninstall und eigene Bereinigung bestanden. Source-/Helper-/Genuine-Inputs hashgebunden, begrenzter Caller mit tatsächlichem Exit und vollständigen Kanälen, exakt gebundenem Journal und frischem unabhängigen Cleanup-Audit. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 bezeichnet ausschließlich den Visibility-Teilbereich. CI am geprüften PR-Head 76888216 bestanden: alle sieben Checks SUCCESS einschließlich SQL Server 2019/2022/2025 Linux. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben NOT_EXECUTED.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Welle1 / 2.0.0

[Freigegebener Vertrag](../../../Documentation/Architecture/TABLE_CLONE_WAVE1_CONTRACT.md):
Computed/PERSISTED, Filter, optional typisierte Extended Properties, zehn Parameter,
sieben SET-Zeilen und TABLE8. Neue Source und Oracles sind kein Runtime-Nachweis.
Neue Runtimefixture: Wave1.Contract.sql (synthetische externe DDL/Typen/Owner/Atomik).
Genuine1.0 aus publicPinfdafa8038e4d5240dd727096f144c8d5fd884117, unveränderte Bytes;
kein zurückversionierter neuer Installer. W1 Runtime: ausgewählter öffentlicher Scope bestanden; CI am geprüften Head 76888216 bestanden; tatsächliche Minimalrechte: NOT_EXECUTED.
Das am2026-10-02 zusätzlich freigegebene Lifecycle-Sichtbarkeitsgate53926/2 wird vor Änderungen und unter AppLock geprüft. Statische sechzehn 0-/NULL-Predicate-Injektionsformen bezeugen die Kopplung am echten Installertext; kein tatsächlicher Lowpriv-Kontext. Die finalen öffentlichen Nativeadapter prüfen beide Lifecycle-Passes mit 0-/NULL-Injektionen und unverändertem Modulbestand. W1-Runtime im ausgewählten öffentlichen Scope und CI am geprüften Head 76888216 bestanden; tatsächliche Lowpriv-Kontexte bleiben offen.

## Finaler öffentlicher W1-Nachweis 2026-10-03

Am 2026-10-03 bestanden die finalen öffentlichen Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures einschließlich 27 Propertytypen und separater 18-datetimeoffset-Produktpfadregression, Client-/Lifecycle-/Caller-TX-/SET-/AppLock-/Rollback-/Kollisions-/Dependency-/Atomikorakel sowie genuine 1.0-Upgrades und eigene Bereinigung sind qualifiziert. Inputs und Genuine-Blobs sind hashgebunden; tatsächlicher Exit, vollständige Kanäle, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 ist nur der Visibility-Teilbereich. CI am geprüften PR-Head 76888216 bestanden: alle sieben Checks SUCCESS einschließlich SQL Server 2019/2022/2025 Linux. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben NOT_EXECUTED. Teilweise validiert und unveröffentlicht.

Der dedizierte öffentliche Adapter ist Tests/CI/run-table-clone-wave1-lab.ps1; genuine Artefakte erzeugt Deployment/New-LegacyTestArtifacts.ps1. Für einen reproduzierbaren Lauf sind LegacyDirectory, der erwartete externe Prompt-SHA256 und die exakte Plattform-/Versions-/Patchauswahl anzugeben. Optionale gepaarte ExpectedRunId/JournalPath ermöglichen die Bindung eines unabhängigen Callers; kein latest-Journal wird adoptiert. Der Linux-CI-Shelladapter ist eine getrennte disposable CI-Prüfung.


### Gezielte CI-Prefixkorrektur

Die CI-Diagnose bestätigte auf Linux 2019/2022/2025 jeweils genau eine vollständige Form: ein führendes LF, die drei exakten öffentlichen Kommentarzeilen und der vollständige CREATE-Header mit drei Leerzeichen. Die Predicate-Testfixture akzeptiert zusätzlich ausschließlich diese byteexakte Form; Diagnoseausgabe und zusätzliches Resultset sind wieder entfernt. Bestehende Headerersetzung, Ablehnungs-, Transaktions- und Restoreorakel bleiben unverändert. Die korrigierte Fixture bestand anschließend in erneuten vollständigen öffentlichen Native-Läufen auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL150/160/170 jeweils lokal und zentral, einschließlich eigener Bereinigung und ohne Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. CI am geprüften Head 76888216: alle sieben Checks SUCCESS einschließlich CloneLinux2019/2022/2025. Der Zähler32 bleibt nur der Visibility-Teilbereich; tatsächliche Lowpriv-Kontexte und weitere physische Ziele bleiben offen.
