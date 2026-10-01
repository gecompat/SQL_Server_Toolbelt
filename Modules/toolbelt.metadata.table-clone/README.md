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
Risikobasierte Linux2019- und Windows2025-Nachweise erfolgreich, Rest offen; kein Release.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/CU8 CL150/160/170; synthetische Preview/externeTestDDL/Struktur/Identity/Indexkeys/Include/Optionen/Collations/ResultTable/own-caller-doomedTx/Clientmetadata/local-central/Minrechte/HiddenIncomingFK/Typdrift/MarkerHash/Kollision/Uninstall/LifecycleCallerTxON-OFF. Weitere Versionen/Plattformkombinationen, GitHub und LowprivCrossDB nicht ausgefuehrt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
