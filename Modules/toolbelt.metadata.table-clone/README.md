# Script-only Table Clone

`toolbelt_metadata.USP_ScriptTableClone` liefert eine geordnete DDL-Vorschau;
die öffentliche API führt niemals DDL aus und kopiert keine Daten.
Siehe [Objektvertrag](Documentation/USP_ScriptTableClone.md),
[Architektur](../../Documentation/Architecture/TABLE_CLONE_PROPOSAL.md)
und [Testmatrix](Tests/TABLE_CLONE_CONTRACT_TEST_MATRIX.md).

Installieren nach `toolbelt.core.result-table >=1.0.0`, aus `Deployment`:
`sqlcmd -b -i Deploy.sql -v DeploymentMode=local`.
Uninstall: `sqlcmd -b -i Uninstall.sql -v ConfirmNoExternalConsumers=0`;
central benötigt ausdrückliche Betreiberbestätigung1.
Deploy und Uninstall lehnen aktive Caller-Transaktionen vor SET-/Temp-DDL ab:
Enginefehler50000 mit `TBX_TABLE_CLONE_CALLER_TRANSACTION`, nichtdoomendes
RAISERROR+RETURN; SQLCMD `:On Error exit` beendet den Scriptlauf.
Lokaler und zentraler Modus verwenden denselben Kern. Quelle/Ziel gehören
immer zur Installationsdatenbank; dreiteiliger Aufruf verschiebt diese nicht
in die Caller-Datenbank. Kein Wrapper über fremde Metadaten/Permissions.

Status und Evidenz sind ausschließlich im [Manifest](module.yaml) kanonisch.
Historische V1-Nachweise bleiben getrennt; Welle1/2.0.0 ist teilweise validiert und unveröffentlicht.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-03`
- Nachweis: `local: Tests/CI/run-table-clone-wave1-lab.ps1; begrenzter Root-Caller und unabhängiger Cleanup-Audit`
- Scope: Finaler öffentlicher W1-Labadapter am 2026-10-03 (lokales Datum; UTC 2026-10-02): SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures TableClone.Contract.sql, Wave1.Contract.sql, Wave1.DateTimeOffset.sql und Lifecycle.Contract.sql, Clientmetadata/Help/ResultTable, 27 Propertytypen samt Ownern und 18 datetimeoffset-Produktpfadroundtrips, Computed/PERSISTED/Filter, 2MiB-Atomik, Predicate-Injektionen, genuine 1.0-Upgrade, clean/repeat, Caller-TX/SET, AppLock, Rollback, Kollisions-/Dependency-Erhalt, Uninstall und eigene Bereinigung bestanden. Source-/Helper-/Genuine-Inputs hashgebunden, begrenzter Caller mit tatsächlichem Exit und vollständigen Kanälen, exakt gebundenem Journal und frischem unabhängigen Cleanup-Audit. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 bezeichnet ausschließlich den Visibility-Teilbereich. Tatsächliche Minimalrechte mit eigenem Principal, andere Ziele und aktuelle CI bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Welle1 / 2.0.0

[Freigegebener Vertrag](../../Documentation/Architecture/TABLE_CLONE_WAVE1_CONTRACT.md):
Computed/PERSISTED, Filter, optional typisierte Extended Properties, zehn Parameter,
sieben SET-Zeilen und TABLE8. Neue Source und Oracles sind kein Runtime-Nachweis.
Neue Runtimefixture: Wave1.Contract.sql (synthetische externe DDL/Typen/Owner/Atomik).
Genuine1.0 aus publicPinfdafa8038e4d5240dd727096f144c8d5fd884117, unveränderte Bytes;
kein zurückversionierter neuer Installer. W1 Runtime: ausgewählter öffentlicher Scope bestanden; CI und tatsächliche Minimalrechte: NOT_EXECUTED.
## Finaler öffentlicher W1-Nachweis 2026-10-03

Am 2026-10-03 bestanden die finalen öffentlichen Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures einschließlich 27 Propertytypen und separater 18-datetimeoffset-Produktpfadregression, Client-/Lifecycle-/Caller-TX-/SET-/AppLock-/Rollback-/Kollisions-/Dependency-/Atomikorakel sowie genuine 1.0-Upgrades und eigene Bereinigung sind qualifiziert. Inputs und Genuine-Blobs sind hashgebunden; tatsächlicher Exit, vollständige Kanäle, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 ist nur der Visibility-Teilbereich. Tatsächliche Minimalrechte mit eigenem Principal, übrige physische Ziele und aktueller CI-Head bleiben NOT_EXECUTED. Teilweise validiert und unveröffentlicht.
