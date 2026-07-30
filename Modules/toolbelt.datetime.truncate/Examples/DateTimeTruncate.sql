-- Synthetisches Beispiel für einen mengenorientierten Truncation-Aufruf.
DECLARE @Events TABLE (EventId int, EventTime datetime2(7));
INSERT INTO @Events VALUES
    (1, '2026-07-30T12:34:56.1234567'),
    (2, '2026-08-01T01:02:03.0000000');

SELECT events.EventId, truncated.Value AS MonthStart
FROM @Events AS events
CROSS APPLY toolbelt_datetime.TVF_TruncateDateTime2
            ('month', events.EventTime) AS truncated
WHERE truncated.IsValid = 1;
