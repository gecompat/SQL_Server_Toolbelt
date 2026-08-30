# Work-Queue-Contract-Testmatrix

| Bereich | Pflichtnachweis |
|---|---|
| Objektvertrag | Tabelle, View, fünf USPs, benannte Constraints/Indizes und Extended Properties |
| Hilfe | alle fünf USPs; reine Hilfe ohne fachliche Pflichtparameter und ohne Seiteneffekt |
| Enqueue | aktive registrierte Work Types, NONE/JSON_PAYLOAD, 64-KiB-Grenze, fehlender/deaktivierter Handler |
| Claim | null oder eine Zeile, bestmögliches FIFO, atomarer Token, kein Claim in Caller-Transaktion |
| Ownership | fremder oder veralteter Token ändert keinen Zustand |
| Complete/Fail | terminale Übergänge, FailureCode/-Message, keine erneute Beanspruchung |
| Transaktion | Caller-Commit/-Rollback, Savepoints und keine Mutation bei `XACT_STATE()=-1` |
| Status | GetWorkStatus und View ohne Payload und ClaimToken |
| ResultTable | direkte Ausgabe, Dummyspalte, Replace/Append und Help-Ignorieren |
| Parallelität | vier echte Sessions, genau ein erfolgreicher Claim desselben einzigen Items |
| Lifecycle | Dependency-/Versions-/Kollisionsschutz, Erst-/Wiederholungsdeployment, Datenverlustgate, Central und Uninstall |
| Matrix | SQL Server 2019/2022/2025 auf Windows und Linux, nur tatsächlich ausgeführte Ziele |

Lease, Recovery, Retry, Dead Letter, Idempotency, Cancellation und Worker sind
keine E1a-Tests und dürfen nicht aus dieser Matrix abgeleitet werden.

Ausgeführte physische Evidenz am 2026-08-30:
`local: Tests/CI/run-lab-local.ps1` für Linux 2019, 2022 und 2025; Windows-
Preflights `not executed` vor der ersten Mutation.
