# Work-Queue-Objekte

## Zustandsmodell

```text
QUEUED -> CLAIMED -> COMPLETED
                  -> FAILED
```

Terminale Zustände werden in Version 1.0 weder zurückgesetzt noch erneut
beansprucht. FIFO gilt bestmöglich nach `WorkItemId` unter den aktuell
beanspruchbaren Items; eine absolute Fairnesszusage besteht nicht.

## `USP_EnqueueWork`

Parameter: `@WorkTypeName varchar(128)`, `@PayloadJson nvarchar(max)` und die
vier Standardparameter für ResultTable, KeepData, Debug und Hilfe.

Der Work Type muss registriert, aktiv und sein Handler vorhanden sein.
`NONE` akzeptiert ausschließlich `NULL`; `JSON_PAYLOAD` verlangt ein
JSON-Objekt mit höchstens 65.536 Bytes nach `DATALENGTH`. Enqueue nimmt an
einer vorhandenen Caller-Transaktion teil und verwendet einen Savepoint.

## `USP_ClaimWork`

Claim darf nicht in einer Caller-Transaktion laufen. Die Procedure liefert
null oder eine Zeile mit `WorkItemId`, `WorkTypeName`, `PayloadJson`,
`ClaimToken` und `ClaimedAtUtc`. Ein atomarer Lock-/Update-Zyklus verhindert,
dass konkurrierende Worker dasselbe Item erhalten. Deaktivierte Work Types
und entfernte Handler werden übersprungen.

## `USP_CompleteWork` und `USP_FailWork`

Beide verlangen `WorkItemId` und das zum Claim gehörende `ClaimToken` und
können an einer Caller-Transaktion teilnehmen. Complete speichert kein
fachliches Arbeitsergebnis. Fail verlangt einen case-sensitiven stabilen
ASCII-`FailureCode` und akzeptiert optional höchstens 1.000 bereits vom
Aufrufer bereinigte Unicode-Codeeinheiten. Logs, Stack Traces und beliebige Fehler-Blobs
sind nicht Bestandteil des Vertrags.

## `USP_GetWorkStatus` und `VW_WorkQueue`

Beide liefern Status- und Auditmetadaten, aber weder Payload noch Claim-Token.
Der Viewzugriff ist read-only; direkte DML auf `toolbelt_core.WorkItem` ist
kein öffentlicher Vertrag.

## ResultTable und Transaktionen

Alle fünf USPs erfüllen Help-, Debug-, ResultTable- und KeepData-Vertrag.
Enqueue, Complete und Fail verändern bei eigenem Fehler nicht die
Caller-Transaktion außerhalb ihres Savepoints. Bei `XACT_STATE() = -1`
erfolgt keine Queue-Mutation. Claim besitzt immer eine vollständig interne
Transaktion.
