# Managed Worker Control

**Anleitung und Beispiele:** [Worker starten und steuern](../../Workers/ExternalQueue/USAGE.md).
Der Leitfaden erklärt alle öffentlichen Steuerfunktionen, globale/lokale
Parallelität, Betriebsarten, Pause/Drain/Stop, Hold und Wiederfreigabe.

SQL2.1-Integration und eigener Worker-Control1.0-Lifecycle. [Vertrag](../../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md).

Source implementiert, teilweise validiert und unveröffentlicht. Die
[aktuellen Windows-SQL-Gates](Tests/README.md#aktuelle-windows-sql-gates-vom-2026-11-06)
belegen sechs lokale Kontexte auf SQL2019/2022/2025 über die unterstützten CLs
mit frischen Audits. Provider-, zentrale/CrossDB-, Minimalrechte- und
Recoveryumfänge bleiben gesondert abzugrenzen. Keine globale Kapazitäts-,
Exactly-once-, Installation- oder Rechtezusage. Vorhandene Module separat installieren.

Der [frische Windows-Workerprovider](Tests/README.md#aktueller-windows-workerprovider-vom-2026-11-06)
bestand zusätzlich auf WindowsSQL2025/CU8/CL170 alle elf fokussierten Fälle
einschließlich tatsächlichem Cancel/Rollback/Hold, Rennen, Controltimeout und
separatem Abschlussaudit. Weitere Providerkontexte bleiben getrennt.
Die [weitere Providerabnahme](Tests/README.md#weitere-windows-providerkontexte-vom-2026-11-06)
ergänzt grüne Gesamtfälle für WindowsSQL2019/CL150 und 2022/CL150. Der
2022/CL160-Koordinator scheiterte nach erfolgreichen Providerfällen am
Bereinigungsguard und wurde separat sicher bereinigt; weitere 2025-CLs sind offen.

Globale Admission zählt IsOccupied unabhängig vom Proofstatus. Generationen haben feste registrierte Intervalle; administrative Pause überlebt Close/Expiry/Neuregistrierung. Stop/Hold und private Witness-/Sessionlockproofs schützen gegen Replay. UNKNOWN bleibt belegt.

[Testmatrix](Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md), [Evidenz](Tests/README.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -ManagedOnly`
- Scope: Derselbe fokussierte Managedvertrag mit Windows-Workerhost gegen SQL Server 2019 Linux; zwei Supervisoren, Betriebsmodi, Stop/Rollback/Hold/anderer Worker, Dispositionrennen und Controltimeout/UNKNOWN/keine Übernahme.
- Ergebnis: `success including own cleanup; Linux-Workerhost durch aktuelle CI gesondert zu prüfen; Committransportverlust, minimale Rechte und weitere Ziele nicht ausgeführt`
<!-- END GENERATED:MODULE_EVIDENCE -->
