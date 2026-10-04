# VW_WorkerStatus

Öffentliche lesende Statussicht für registrierte Worker bzw. unveränderliche Ausführungsidentitäten. Vorhandenes SELECT ist erforderlich; das Modul erteilt keine Rechte. Unterstützt SQL Server 2019, 2022 und 2025 auf Windows und Linux.

| Spalte | SQL-Typ | NULL |
|---|---|---|
| WorkerId | uniqueidentifier | nein |
| WorkerGeneration | bigint | nein |
| ProviderKind | varchar(16) | nein |
| State | varchar(16) | nein |
| Capacity | int | nein |
| RunMode | varchar(16) | nein |
| LastHeartbeatAtUtc | datetime2(7) | nein |
| OccupiedSlots | bigint | nein |
| ConfigVersion | binary(8) | nein |
| HeartbeatSeconds | int | nein |
| UnreachableSeconds | int | nein |

`OccupiedSlots` zählt auch ungeklärte Reservations. HeartbeatSeconds und UnreachableSeconds sind bei Registrierung gepinnte Werte; neue Konfigurationswerte gelten erst für neue Generationen. Eine fehlende Heartbeatmeldung ist kein Rollbacknachweis.

```sql
SELECT WorkerId,WorkerGeneration,ProviderKind,State,Capacity,RunMode,LastHeartbeatAtUtc,OccupiedSlots,ConfigVersion,HeartbeatSeconds,UnreachableSeconds FROM toolbelt_core.VW_WorkerStatus;
```

Der [Architekturvertrag](../../../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md) beschreibt Stop, Admission und Proof. Laufzeitnachweise sind noch nicht ausgeführt.
