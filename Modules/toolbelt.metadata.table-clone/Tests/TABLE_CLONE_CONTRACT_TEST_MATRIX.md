# Table Clone Testmatrix

| Scope | Vorhandener Oracle | Ausführung |
|---|---|---|
| Structure | synthetische externe DDL-Ausführung; Columns/Defaults/Checks/Indexkeys/INCLUDE/Richtung/Options/Identity; keine Datenkopie | PASS2019Linux/2025Windows |
| Naming | Determinismus, Kollision, Injectionidentifier,128/129Units/NUL | PASS2019Linux/2025Windows |
| Unsupported | Computed/Sparse/filteredIndex/sequentialKeyON/disabledCheck/EP/Trigger/incomingFK/Compression vor ResultTable-Mutation | PASS2019Linux/2025Windows |
| USP | Help/SELECT/Metadata, reservedOutput lower/uppercase vor Kernkompilierung, Replace/Append/SchemaBlocker/own/callerSavepoint/doomed | PASS2019Linux/2025Windows |
| Lifecycle | install/repeat/P-TFdrift/allMarkerHash/twoCI-caseCollisions/foreignConsumer/uninstall | PASS2019Linux/2025Windows |
| Caller Lifecycle | Deploy/Uninstall ON/OFF Count/State/Daten/Marker unverändert; SQLCMD Nonzeroexit | PASS2019Linux/2025Windows |
| Rights | eingeschränkter lokaler Caller mit DBweiter VIEW DEFINITION, verweigerte Sicht, hidden-incoming-FK atomar53901/vollsicht53903, adminCrossDB | PASS2019Linux/2025Windows |
| Platforms | risikobasiert2019Linux/latest CL150 und2025Windows/CU8 CL150/160/170; keine vollständige6Matrix | PASS ausgewählter Scope |

Keine realen Quell-DDL/Rohlogs als Evidence. Weitere Unsupportedfeatures benötigen
zusätzliche gezielte synthetische Oracles vor Statusaufwertung; kein vollständiges
SMO-/DacFx-Kompatibilitätsversprechen oder Produktions-/Parallelitätsnachweis.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/CU8 CL150/160/170; synthetische Preview/externeTestDDL/Struktur/Identity/Indexkeys/Include/Optionen/Collations/ResultTable/own-caller-doomedTx/Clientmetadata/local-central/Minrechte/HiddenIncomingFK/Typdrift/MarkerHash/Kollision/Uninstall/LifecycleCallerTxON-OFF. Weitere Versionen/Plattformkombinationen, GitHub und LowprivCrossDB nicht ausgefuehrt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
