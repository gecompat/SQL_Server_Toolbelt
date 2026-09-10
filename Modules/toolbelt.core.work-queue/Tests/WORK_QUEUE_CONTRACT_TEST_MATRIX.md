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

Die v2-Linux-Matrix wurde am 2026-09-10 über GitHub Actions auf SQL Server
2019, 2022 und 2025 erfolgreich ausgeführt. Die Windows-v2-Matrix ist
`not executed`; die Validierung bleibt daher teilweise. Alle synthetischen
Testdatenbanken wurden entfernt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-10`
- Nachweis: `GitHub Actions: Work-Queue Runtime #34533724721`
- Scope: Work Queue 2.0.0 auf synthetischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen; öffentlicher Vertrag, Retry/Dead Letter, Idempotenz, Barrier- und Parallelitätsfälle, Upgrade, Lifecycle, Central, Redeployment, Uninstall und Cleanup
- Ergebnis: `success; Windows-v2-Matrix not executed`
<!-- END GENERATED:MODULE_EVIDENCE -->
