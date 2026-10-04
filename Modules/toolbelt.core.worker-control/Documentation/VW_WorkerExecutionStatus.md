# VW_WorkerExecutionStatus

Öffentliche lesende Statussicht für registrierte Worker bzw. unveränderliche Ausführungsidentitäten. Vorhandenes SELECT ist erforderlich; das Modul erteilt keine Rechte. Unterstützt SQL Server 2019, 2022 und 2025 auf Windows und Linux.

| Spalte | SQL-Typ | NULL |
|---|---|---|
| SlotReservationId | uniqueidentifier | nein |
| WorkItemId | bigint | nein |
| ClaimGeneration | bigint | nein |
| ExecutionId | uniqueidentifier | nein |
| WorkerId | uniqueidentifier | nein |
| WorkerGeneration | bigint | nein |
| State | varchar(24) | nein |
| IsHeld | bit | nein |
| HoldVersion | binary(8) | ja |
| StopStatus | varchar(24) | nein |

Jede Reservation bleibt über ihre eigene Claimgeneration sichtbar. Nur die exakt zugehörige aktuelle Disposition liefert eine HoldVersion; nach einem Folgeclaim ist die historische Version NULL. IsHeld ist dann false, StopStatus NONE (COMMITTED: ALREADY_COMMITTED). Historisches IsHeld=false und StopStatus=NONE bedeuten keine aktuelle Disposition; sie beweisen keinesfalls, dass der Attempt nie gestoppt oder gehalten war. Diese Zeile beschreibt keine Wiederfreigabe und autorisiert keinen Eingriff in eine spätere Generation.

```sql
SELECT SlotReservationId,WorkItemId,ClaimGeneration,ExecutionId,WorkerId,WorkerGeneration,State,IsHeld,HoldVersion,StopStatus FROM toolbelt_core.VW_WorkerExecutionStatus;
```

Der [Architekturvertrag](../../../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md) beschreibt Stop, Admission und Proof. Laufzeitnachweise sind noch nicht ausgeführt.
