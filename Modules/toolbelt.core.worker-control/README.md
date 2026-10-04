# Managed Worker Control

SQL2.1-Integration und eigener Worker-Control1.0-Lifecycle. [Vertrag](../../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md).

Source implementiert; SQL-Vertrag auf SQL Server 2019 Linux und 2025 Windows/CU8 teilweise validiert, unreleased. Vollständiger paralleler Providerlauf, exakte Head-CI bleiben offen. Keine globale Kapazitäts-, Exactly-once-, Installation- oder Rechtezusage. Vorhandene Module separat installieren.

Globale Admission zählt IsOccupied unabhängig vom Proofstatus. Generationen haben feste registrierte Intervalle; administrative Pause überlebt Close/Expiry/Neuregistrierung. Stop/Hold und private Witness-/Sessionlockproofs schützen gegen Replay. UNKNOWN bleibt belegt.

[Testmatrix](Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md), [Evidenz](Tests/README.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -ManagedOnly`
- Scope: Derselbe fokussierte Managedvertrag mit Windows-Workerhost gegen SQL Server 2019 Linux; zwei Supervisoren, Betriebsmodi, Stop/Rollback/Hold/anderer Worker, Dispositionrennen und Controltimeout/UNKNOWN/keine Übernahme.
- Ergebnis: `success including own cleanup; Linux-Workerhost durch aktuelle CI gesondert zu prüfen; Committransportverlust, minimale Rechte und weitere Ziele nicht ausgeführt`
<!-- END GENERATED:MODULE_EVIDENCE -->
