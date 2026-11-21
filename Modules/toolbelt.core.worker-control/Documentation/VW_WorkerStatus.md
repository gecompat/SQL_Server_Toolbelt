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

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/VW_WorkerStatus.md)
steht auch in der DDL. `ConfigVersion` stammt aus der aktuellen globalen
Konfigurationszeile; die Intervalle stammen dagegen aus der Registration.
Die View filtert nicht auf aktive Worker oder den Caller. Eine fehlende
Konfigurationszeile blendet wegen des CROSS JOIN alle Registrierungen aus.
`State` ist gespeichert und wird beim SELECT nicht aus dem Heartbeatalter
neu berechnet. Der Zähler wertet ausschließlich `IsOccupied=1` aus.

```sql
SELECT WorkerId,WorkerGeneration,ProviderKind,State,Capacity,RunMode,LastHeartbeatAtUtc,OccupiedSlots,ConfigVersion,HeartbeatSeconds,UnreachableSeconds FROM toolbelt_core.VW_WorkerStatus;
```

Der [Architekturvertrag](../../../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md)
beschreibt Stop, Admission und Proof. [Vorhandene Nachweise](../Tests/README.md)
behalten ihre jeweilige Ziel- und Artefaktbindung; die aktuelle Skill-/DDL-/
Installerprojektion ist dadurch nicht erneut nativ abgenommen.

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 ist vorhanden; bestehendes SELECT-Recht auf die Sicht.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/VW_WorkerStatus.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
