# Relational Date Spine

`toolbelt.datetime.date-spine` erzeugt Tages-, ISO-Wochen- und Monatsperioden,
die einen halboffenen `date`-Bereich schneiden.

## Status

- Version: `1.0.0`
- Implementierung: `implemented`
- Validierung: `partially validated`
- Release: `unreleased`
- Provider: portable T-SQL Inline TVFs

## Öffentliche Objekte

- `toolbelt_datetime.TVF_DateSpineDay`
- `toolbelt_datetime.TVF_DateSpineIsoWeek`
- `toolbelt_datetime.TVF_DateSpineMonth`

Alle Funktionen liefern `Ordinal int` und `PeriodStart date`. Der Bereich ist
`[RangeStart, RangeEndExclusive)`; partielle Wochen oder Monate werden
einschließlich ihres tatsächlichen Periodenanfangs geliefert.

## Dependencies

- `toolbelt.core.generate-series` mindestens `1.0.0`;
- `toolbelt.datetime.truncate` mindestens `1.0.0`;
- beide in derselben Installationsdatenbank.

Dependencies werden nicht automatisch installiert. Deployment ist lokal und
zentral möglich; zentrale Aufrufe verwenden dreiteilige Namen.

## Grenzen

Keine Feiertage, Arbeitstage, Zeitzonen, DST, Locale-Texte, Geschäfts- oder
Fiskalkalender, Quartale, frei wählbaren Schritte oder persistente
Kalenderdimension. Ohne `ORDER BY` besteht keine Reihenfolgegarantie.

Siehe [Moduldesign](../../Documentation/Architecture/DATE_SPINE_MODULE_DESIGN.md)
und [Testmatrix](Tests/DATE_SPINE_CONTRACT_TEST_MATRIX.md).

Die vollständige Modulmatrix ist auf den physischen Linux-Zielen 2019, 2022
und 2025 erfolgreich. Die explizit ausgewählten Windows-Ziele waren beim
SQL-Anmeldungs-Preflight nicht erreichbar; Windows-Runtime bleibt deshalb
`not executed`.

Evidenz 2026-08-30: `local: Tests/CI/run-lab-local.ps1`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-30`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Explizit ausgewählte SQL-Server-2019-, 2022- und 2025-Windows-Ziele; SQL-Anmeldungs-Preflight
- Ergebnis: `not executed; Zielverbindungen waren vor der ersten Testmutation nicht erreichbar`
<!-- END GENERATED:MODULE_EVIDENCE -->
