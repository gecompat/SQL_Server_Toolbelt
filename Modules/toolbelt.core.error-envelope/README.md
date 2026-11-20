# Error Envelope


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


## Security-Korrektur 2026-10-14

SC-039: Direkte Ausgabe bleibt auch bei XACT_STATE()=-1 lesend möglich. ResultTable wird dann vor jeder Mutation mit 51406 abgewiesen; Rollback und Original-Rethrow bleiben beim Caller.
[Nachweise und Grenzen](../../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md).

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

## Status

`toolbelt.core.error-envelope` Version `1.0.0` ist implementiert und auf SQL Server 2019/2022/2025 unter Windows base und Linux latest `validated`.

## Zweck

`toolbelt_core.USP_CaptureErrorEnvelope` erzeugt aus den im aufrufenden `CATCH` gelesenen `ERROR_*`-Werten eine standardisierte Zeile. Die Procedure klassifiziert Fehler als `ENGINE`, `TOOLBELT` oder `USER`, ergänzt Transaktions- und Sessiondaten und kann in eine lokale ResultTable schreiben.

Die Procedure führt bewusst keinen Rethrow aus. Nur `THROW;` im ursprünglichen `CATCH` erhält Enginefehler unverändert. Zusatzkontext muss synthetisch oder bereits bereinigt sein.

Mit `@Hilfe=1` werden die bisherige Standardhilfe und anschließend genau eine
zusätzliche Skillzeile ausgegeben. Der vollständige
[kanonische Skill](../../Metadata/UsageSkills/toolbelt_core/USP_CaptureErrorEnvelope.md)
ist identisch in der DDL enthalten. Hilfe kehrt vor Fachvalidierung, Kontextlesen
und ResultTable-Verarbeitung zurück. Die neue Hilfeausgabe ist offline geprüft;
ihre native Abnahme steht separat aus.

## Artefakte

- [SQL-Definition](Source/USP_CaptureErrorEnvelope.sql)
- [Objektvertrag](Documentation/USP_CaptureErrorEnvelope.md)
- [Beispiele](Examples/ErrorEnvelope.sql)
- [Testmatrix](Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md)
- [Aktueller Buildplan](Deployment/README.md)

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948
sowie der erfolgreiche physische Linux-Lauf 2019/2022/2025 vom 2026-08-29.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger W4-Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
