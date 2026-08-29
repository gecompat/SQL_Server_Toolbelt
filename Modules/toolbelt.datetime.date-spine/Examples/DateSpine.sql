-- Synthetische Beispiele für toolbelt.datetime.date-spine.

SELECT Ordinal, PeriodStart
FROM toolbelt_datetime.TVF_DateSpineDay('20260227', '20260303')
ORDER BY Ordinal;

SELECT Ordinal, PeriodStart
FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231', '20260108')
ORDER BY Ordinal;

SELECT Ordinal, PeriodStart
FROM toolbelt_datetime.TVF_DateSpineMonth('20260115', '20260402')
ORDER BY Ordinal;
