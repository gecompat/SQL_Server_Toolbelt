-- Synthetisches Beispiel für 15-Minuten-Buckets.
DECLARE @Events TABLE (EventId int, EventTime datetime2(7));
INSERT INTO @Events VALUES
    (1, '2026-07-30T12:34:56.1234567'),
    (2, '2026-07-30T12:46:00.0000000');

SELECT events.EventId, bucket.Value AS BucketStart
FROM @Events AS events
CROSS APPLY toolbelt_datetime.TVF_DateBucketDateTime2
            ('minute', 15, events.EventTime, DEFAULT) AS bucket
WHERE bucket.IsValid = 1;
