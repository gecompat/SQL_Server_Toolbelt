# Event-Log-Objekte

## `USP_WriteEvent`

Schreibt genau ein Event über den konfigurierten Second-Session-Provider. Die Procedure gibt kein fachliches oder infrastrukturelles Resultset aus. ExecutionId, CorrelationId, Actor und Tenant werden aus expliziten Parametern oder dem aktiven Execution Context übernommen.

Die Procedure kann in einer regulären, zurückgerollten oder uncommittable Caller-Transaktion verwendet werden. Ein erfolgreicher Returncode bedeutet, dass der Remote-Handler synchron erfolgreich committed hat. Provider- oder Handlerfehler werden an den Caller weitergegeben.

Der interne `USP_WriteEventInternal`-Kern hat einen Help-Aufruf für seine
gebundene JSON-Payload und den fehlenden fachlichen Resultset-Vertrag. Direkte
Aufrufe bleiben auf die vorgesehene Event-Log-Fassade beschränkt; Hilfe
validiert oder speichert keine Payload.

## `VW_Events`

Read-only-Sicht auf Eventzeit, Aufzeichnungszeit, Eventklassifikation, Context, Source, Caller- und Remote-Session sowie optionale SQL-Fehlerdaten.

## `USP_DeleteEventsBefore`

Löscht Events mit älterem `OccurredAtUtc` in explizit begrenzten Batches. Es gibt keine automatische Zeitplanung und keinen stillen Volltabellen-Delete.
