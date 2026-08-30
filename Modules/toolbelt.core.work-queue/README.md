# Transactional Work Queue

## Status

`toolbelt.core.work-queue` Version `1.0.0` implementiert ausschließlich den
freigegebenen Slice E1a. Die physische Linux-Matrix SQL Server 2019, 2022 und
2025 ist einschließlich Parallelität und Lifecycle erfolgreich. Die drei
Windows-Ziele waren bereits im SQL-Anmeldungs-Preflight nicht erreichbar und
bleiben `not executed`. Das Modul ist `unreleased` und vor E1b Lease/Recovery
nicht als allein betriebsfertige Queue zu veröffentlichen.

Evidenz: `local: Tests/CI/run-lab-local.ps1`.

## Zweck

Das Modul reiht Aufträge für registrierte Work Types ein, beansprucht sie
atomar und schließt sie mit einem nicht erratbaren Claim-Token als
`COMPLETED` oder `FAILED` ab. Die interne Tabelle ist kein öffentlicher
DML-Vertrag.

## Öffentliche Objekte

- `toolbelt_core.USP_EnqueueWork`
- `toolbelt_core.USP_ClaimWork`
- `toolbelt_core.USP_CompleteWork`
- `toolbelt_core.USP_FailWork`
- `toolbelt_core.USP_GetWorkStatus`
- `toolbelt_core.VW_WorkQueue`

`ClaimToken` und `PayloadJson` erscheinen ausschließlich im Claim-Ergebnis,
nicht in Statusabfrage oder View. Die Queue akzeptiert niemals Raw SQL oder
einen Handlernamen aus der Payload.

## E1a-Grenze

E1a besitzt keine Lease, Recovery, Retries, Dead-Letter-Queue,
Idempotency Keys, Cancellation oder automatische Worker-Ausführung. Ein nach
dem Claim abgebrochener Worker lässt das Item dauerhaft in `CLAIMED`; diese
Lücke wird erst durch einen separat freizugebenden E1b-Vertrag geschlossen.
