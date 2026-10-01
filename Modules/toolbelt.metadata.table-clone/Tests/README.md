# Testausführung

Static: `python Modules/toolbelt.metadata.table-clone/Tests/Static/validate_contract.py`.
Labadapter: `pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -RunScripts run-table-clone-linux.sh -Versions 2019 -Platforms linux -LinuxPatches latest -StopOnFailure`.
Windows-Labadapter: `pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -RunScripts run-table-clone-linux.sh -Versions 2025 -Platforms windows -WindowsPatches CU8 -StopOnFailure`.
Runner validiert exportierten Schema-Vertrag; keine Infrastrukturänderung.
CI-Workflow registriert2019/2022/2025Linux, vorhandener Workflow ist keine Evidenz.

Am2026-10-01 vollständige finale2019Linux/latest- und2025Windows/CU8-Adapter erfolgreich; Source,
Statementstruktur, Help-/Resultmetadaten, Indexshape und eigener/caller/doomed
Transaktionsscope geprüft. Weitere Zielversionen/GitHub/LowprivCrossDB offen.
Siehe [Testmatrix](TABLE_CLONE_CONTRACT_TEST_MATRIX.md).
Lifecycle-Caller-Tx: SQLCMD-Includes prüfen tatsächlichen Nonzeroexit; der
SqlClient-Metadatentest prüft die frühesten kanonischen Guard-Batches auf
derselben offenen Caller-Session bei XACT_ABORT ON/OFF mit Count/State,
synthetischen Daten und Modulmarker. Keine serverweite sys.messages-Änderung.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/CU8 CL150/160/170; synthetische Preview/externeTestDDL/Struktur/Identity/Indexkeys/Include/Optionen/Collations/ResultTable/own-caller-doomedTx/Clientmetadata/local-central/Minrechte/HiddenIncomingFK/Typdrift/MarkerHash/Kollision/Uninstall/LifecycleCallerTxON-OFF. Weitere Versionen/Plattformkombinationen, GitHub und LowprivCrossDB nicht ausgefuehrt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
