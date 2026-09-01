# Calendar Difference

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

`toolbelt.datetime.calendar-difference` liefert eine portable inline TVF für vollständige Kalenderjahre, -monate und Resttage zwischen zwei `date`-Werten. Sie ist nach `TC-2026-002` am 2026-07-30 besprochen und freigegeben.

Die Anniversary-Regel ist fest: Nicht vorhandene Monatstage werden an das Ende des Zielmonats geklammert. Daher entspricht 2020-02-29 bis 2021-02-28 genau einem Jahr und 2024-01-31 bis 2024-02-29 genau einem Monat.

```sql
SELECT difference.Sign, difference.Years, difference.Months, difference.Days
FROM (VALUES (CONVERT(date, '2020-02-29'), CONVERT(date, '2021-03-01'))) AS source(StartDate, EndDate)
CROSS APPLY toolbelt_datetime.TVF_CalendarDifference(source.StartDate, source.EndDate) AS difference;
```

Weitere Details: [Objektvertrag](./Documentation/TVF_CalendarDifference.md), [Moduldesign](../../Documentation/Architecture/CALENDAR_DIFFERENCE_MODULE_DESIGN.md) und [Testmatrix](./Tests/CALENDAR_DIFFERENCE_CONTRACT_TEST_MATRIX.md).

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) sowie der lokale Lauf vom 2026-08-29 – vollständiger Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Modulstatus `partially validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
