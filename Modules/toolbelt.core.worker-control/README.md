# Managed Worker Control


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


**Anleitung und Beispiele:** [Worker starten und steuern](../../Workers/ExternalQueue/USAGE.md).
Der Leitfaden erklärt alle öffentlichen Steuerfunktionen, globale/lokale
Parallelität, Betriebsarten, Pause/Drain/Stop, Hold und Wiederfreigabe.

## Relationen und maschinenlesbare Verträge

Die sieben Relationen besitzen vollständige quellgeprüfte Skills, auch in
ihrer kanonischen DDL:

- [WorkerControlConfiguration](../../Metadata/UsageSkills/toolbelt_core/WorkerControlConfiguration.md)
- [WorkerRegistration](../../Metadata/UsageSkills/toolbelt_core/WorkerRegistration.md)
- [WorkerSlotReservation](../../Metadata/UsageSkills/toolbelt_core/WorkerSlotReservation.md)
- [WorkerExecutionDisposition](../../Metadata/UsageSkills/toolbelt_core/WorkerExecutionDisposition.md)
- [WorkerExecutionCommitWitness](../../Metadata/UsageSkills/toolbelt_core/WorkerExecutionCommitWitness.md)
- [VW_WorkerStatus](../../Metadata/UsageSkills/toolbelt_core/VW_WorkerStatus.md)
- [VW_WorkerExecutionStatus](../../Metadata/UsageSkills/toolbelt_core/VW_WorkerExecutionStatus.md)

Die fünf Tabellen sind intern. Für Caller bleiben die öffentlichen Steuerpfade
und Statusviews vorgesehen. Tabellenconstraints, gespeicherte Statuswerte und
ein einzelner Witness ersetzen keine vollständige Provider-/Transaktionsprüfung.
Die Skill-Quellabnahme ist keine neue native Gesamtqualifikation.

Auch alle 22 Prozeduren besitzen jetzt einen vollständigen quellgeprüften Skill
unter [Metadata/UsageSkills/toolbelt_core](../../Metadata/UsageSkills/toolbelt_core).
Damit sind die Verträge aller 29 Modulobjekte beschrieben. `@Hilfe=1` liefert
bei jeder Prozedur zusätzlich zur bisherigen Standardhilfe genau eine
vier-spaltige Skillzeile mit dem vollständigen Markdown. Die ausgelieferte DDL
enthält denselben Text; notwendige native Hilfe-/Installerprüfungen bleiben
von dieser Quellenabnahme getrennt.

Die Skills unterscheiden tokengebundene Workeraufrufe von administrativer
EXECUTE-Autorität. Stop ist zunächst eine persistierte Anforderung mit Hold;
UNKNOWN beweist weder Commit noch Rollback und erlaubt keinen Replay. Vor einer
expliziten Freigabe muss die nach Stop/Reconcile aktuelle HoldVersion frisch
gelesen werden. Interne Bindungs-/Transaktionshelfer bleiben Teil des
kontrollierten Providers und sind kein manueller Ersatz für diesen Ablauf.

## Nachweisstand

SQL2.1-Integration und eigener Worker-Control1.0-Lifecycle. [Vertrag](../../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md).

Source implementiert, teilweise validiert und unveröffentlicht. Die
[aktuellen Windows-SQL-Gates](Tests/README.md#aktuelle-windows-sql-gates-vom-2026-11-06)
belegen sechs lokale Kontexte auf SQL2019/2022/2025 über die unterstützten CLs
mit frischen Audits. Zentrale/CrossDB-, Minimalrechte- und
Recoveryumfänge bleiben gesondert abzugrenzen. Keine globale Kapazitäts-,
Exactly-once-, Installation- oder Rechtezusage. Vorhandene Module separat installieren.

Die [lokale Windows-Provider-Teilmatrix](Tests/README.md#aktueller-abschluss-der-lokalen-windows-provider-teilmatrix)
ist für die sechs ausgewählten SQL2019-/2022-/2025-CL-Kontexte abgeschlossen:
je elf fokussierte Fälle einschließlich tatsächlichem Cancel/Rollback/Hold,
Rennen und Controltimeout, vollständiger Koordinator und separater Audit.
Der ursprüngliche 2022/CL160-Bereinigungsfehler bleibt neben dem erfolgreichen
korrigierten Lauf dokumentiert. `FullProduct=false` und die weiterführenden
Provider-/Rechte-/Recoverygrenzen bleiben erhalten.

Globale Admission zählt IsOccupied unabhängig vom Proofstatus. Generationen haben feste registrierte Intervalle; administrative Pause überlebt Close/Expiry/Neuregistrierung. Stop/Hold und private Witness-/Sessionlockproofs schützen gegen Replay. UNKNOWN bleibt belegt.

[Testmatrix](Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md), [Evidenz](Tests/README.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -ManagedOnly`
- Scope: Derselbe fokussierte Managedvertrag mit Windows-Workerhost gegen SQL Server 2019 Linux; zwei Supervisoren, Betriebsmodi, Stop/Rollback/Hold/anderer Worker, Dispositionrennen und Controltimeout/UNKNOWN/keine Übernahme.
- Ergebnis: `success including own cleanup; Linux-Workerhost durch aktuelle CI gesondert zu prüfen; Committransportverlust, minimale Rechte und weitere Ziele nicht ausgeführt`
<!-- END GENERATED:MODULE_EVIDENCE -->
