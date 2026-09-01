# Work-Queue-Contract-Testmatrix

| Bereich | Pflichtnachweis |
|---|---|
| Objektvertrag | Tabelle, View, sieben USPs, benannte Constraints/Indizes und Extended Properties |
| Hilfe | alle sieben USPs; reine Hilfe ohne Pflichtparameter oder Seiteneffekt |
| Enqueue | aktive registrierte Work Types, NONE/JSON_PAYLOAD, 64-KiB-Grenze, fehlender/deaktivierter Handler |
| Claim | null oder eine Zeile, bestmögliches FIFO, neuer Token und Generation, Leasegrenzen, keine Caller-Transaktion |
| Heartbeat | nur aktiver eigener Claim, Verlängerung ab Engine-Zeit, keine Wiederbelebung, keine Caller-Transaktion |
| Recovery | ausschließlich abgelaufene Claims, Batchgrenzen, kein implizites Claim-Recovery, Token-Invaliderung |
| Ownership | fremder, veralteter oder recoverter Token ändert keinen Zustand; Generation steigt monoton |
| Complete/Fail | nur während aktiver Lease, terminale Übergänge, FailureCode/-Message, keine erneute Beanspruchung |
| Transaktion | Caller-Commit/-Rollback, Savepoints und keine Mutation bei `XACT_STATE()=-1` |
| Status | GetWorkStatus und View mit Lease-/Recovery-Metadaten, ohne Payload und ClaimToken |
| ResultTable | direkte Ausgabe, Dummyspalte, Replace/Append und Help-Ignorieren |
| Parallelität | vier echte Sessions, genau ein erfolgreicher Claim desselben einzigen Items |
| Upgrade | `1.0.0 → 1.1.0` mit QUEUED/terminalen Daten; aktiver E1a-Claim blockiert vor Mutation |
| Lifecycle | Dependency-/Versions-/Kollisionsschutz, Erst-/Wiederholungsdeployment, Datenverlustgate, Central und Uninstall |
| Matrix | SQL Server 2019/2022/2025 auf Windows und Linux, nur tatsächlich ausgeführte Ziele |

Retry, Dead Letter, Idempotency, Cancellation, vollständige Attempt-Historie,
Worker und automatische Recovery sind keine E1b-Tests.

Die vollständige Pflichtmatrix wurde am 2026-08-30 über
`local: Tests/CI/run-lab-local.ps1` auf SQL Server 2019, 2022 und 2025 unter Windows
base und Linux latest erfolgreich ausgeführt. Alle synthetischen Datenbanken
wurden entfernt; die Lab-Umgebungen wurden nicht beendet.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-30`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: E1b auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest; Lease, Heartbeat, explizite Recovery, abgelaufene Ownership, Upgrade 1.0.0 auf 1.1.0, blockierter Upgrade-Preflight bei aktivem Claim, Transaktionen, vier Sessions, ResultTable, Dependency, Kollision, Redeployment, Central, Datenverlustschutz, Uninstall und Cleanup
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
