# Work-Queue-Contract-Testmatrix

| Bereich | Pflichtnachweis |
|---|---|
| Objektvertrag | Tabellen, Views, elf USPs, benannte Constraints/Indizes und Extended Properties |
| Hilfe | alle sieben USPs; reine Hilfe ohne Pflichtparameter oder Seiteneffekt |
| Enqueue | aktive registrierte Work Types, NONE/JSON_PAYLOAD, 64-KiB-Grenze, fehlender/deaktivierter Handler |
| Claim | null oder eine Zeile, bestmögliches FIFO, neuer Token und Generation, Leasegrenzen, keine Caller-Transaktion |
| Heartbeat | nur aktiver eigener Claim, Verlängerung ab Engine-Zeit, keine Wiederbelebung, keine Caller-Transaktion |
| Retry und Dead Letter | persistierte Policy, exponentieller Backoff ohne Jitter, Worker-Retry, Orphan-Recovery, Dead Letter und Requeue-Zyklus |
| Idempotenz | binär identischer WorkType-/Key-/Payload-/Policy-Aufruf liefert das vorhandene Item; Abweichungen werden abgewiesen |
| Gruppen-Barrier | Snapshot laufender Claims, gruppenlokale Sperre, Priorität, Retry-Rearming, unterschiedliche Barrier-Prioritäten und parallele gleichpriorige Barriers |
| Ownership | fremder, veralteter oder recoverter Token ändert keinen Zustand; Generation steigt monoton |
| Complete/Fail | nur während aktiver Lease, terminale Übergänge, FailureCode/-Message, keine erneute Beanspruchung |
| Transaktion | Caller-Commit/-Rollback, Savepoints und keine Mutation bei `XACT_STATE()=-1` |
| Status | GetWorkStatus und View mit Lease-/Recovery-Metadaten, ohne Payload und ClaimToken |
| ResultTable | direkte Ausgabe, Dummyspalte, Replace/Append und Help-Ignorieren |
| Parallelität | vier echte Sessions, genau ein erfolgreicher Claim desselben einzigen Items |
| Upgrade | `1.0.0` und `1.1.0` auf `2.0.0` mit Default-Policy; aktive Claims blockieren vor Mutation |
| Lifecycle | Dependency-/Versions-/Kollisionsschutz, Erst-/Wiederholungsdeployment, Datenverlustgate, Central und Uninstall |
| Matrix | SQL Server 2019/2022/2025 auf Windows und Linux, nur tatsächlich ausgeführte Ziele |

Cancellation, Worker-Orchestrierung und automatische Systemzustandserkennung
sind keine Work-Queue-v2-Tests.

Die v2-Linux-Matrix wurde am 2026-09-10 über GitHub Actions und die
v2-Windows-Matrix am 2026-09-11 über den lokalen Lab-Adapter auf SQL Server
2019, 2022 und 2025 erfolgreich ausgeführt. Alle synthetischen Testdatenbanken
wurden entfernt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `local: Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -QueueUpgradeOnly`
- Scope: Echte ursprüngliche Queue-2.0-Installation auf SQL Server 2019 Linux; Upgrade auf 2.1, Erhalt bestehender Queuezeilen und aktiver Claims sowie unveränderter achtspaltiger Legacyclaim.
- Ergebnis: `success; weitere Plattformkombinationen dieses Upgrades nicht ausgeführt`
<!-- END GENERATED:MODULE_EVIDENCE -->


## Neue Welle 2.1 – noch nicht native qualifiziert

| Bereich | Gezielter Nachweis | Status |
|---|---|---|
| Genuine Upgrade 2.0→2.1 | Original-Deployment mit 15 SQL-Dateien/14 Includes aus Commit62e7b06588b28c45c58f7ec335e4e5c45f120e3e, UpgradeFrom2_0.Setup/Verify auf gleicher Connection | 2019 Linux am 2026-10-04 bestanden |
| Daten-/Identityerhaltung | Expliziter43Spalten-Snapshot einschließlich RowVersion, Unicodepayload, Token/Generation/Lease und History; symmetrischer Wertvergleich und Identitymetadaten | 2019 Linux am 2026-10-04 bestanden |
| Neutrale Legacyadmission | Manageddefaults NULL/0/NULL und Gate disabled; bestehender aktiver2.0Claim abschließbar, neuer Claim exakte8Spalten einschließlich datetime2(7) | 2019 Linux am 2026-10-04 bestanden |
| Managedgrenze | ClaimCore gesunde AdmissionTX/oneuseNonce; Holdbypässe verweigert; fehlender Singleton failclosed vor und unterLifecyclelock | SQL-Vertrag 2019 Linux und 2025 Windows/CU8 bestanden; vollständiger Providerlauf offen |

Die historischen2.0Nachweise bleiben historische Evidenz und qualifizieren diese neuen2.1Grenzen nicht.
