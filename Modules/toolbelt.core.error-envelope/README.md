# Error Envelope

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

## Status

`toolbelt.core.error-envelope` Version `1.0.0` ist implementiert und auf SQL Server 2019/2022/2025 unter Windows base und Linux latest `validated`.

## Zweck

`toolbelt_core.USP_CaptureErrorEnvelope` erzeugt aus den im aufrufenden `CATCH` gelesenen `ERROR_*`-Werten eine standardisierte Zeile. Die Procedure klassifiziert Fehler als `ENGINE`, `TOOLBELT` oder `USER`, ergänzt Transaktions- und Sessiondaten und kann in eine lokale ResultTable schreiben.

Die Procedure führt bewusst keinen Rethrow aus. Nur `THROW;` im ursprünglichen `CATCH` erhält Enginefehler unverändert. Zusatzkontext muss synthetisch oder bereits bereinigt sein.

## Artefakte

- `Source/USP_CaptureErrorEnvelope.sql`
- `Documentation/USP_CaptureErrorEnvelope.md`
- `Examples/ErrorEnvelope.sql`
- `Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md`
- `Deployment/Deploy.sql` und `Deployment/Uninstall.sql`

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948
sowie der erfolgreiche physische Linux-Lauf 2019/2022/2025 vom 2026-08-29.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger W4-Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
