# Execution Context


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

## Status

`toolbelt.core.execution-context` Version `1.0.0` ist implementiert und auf SQL Server 2019/2022/2025 unter Windows base und Linux latest `validated`.

## Vertrag

Ein Root-Aufruf von `USP_BeginExecution` setzt Execution-ID, Correlation-ID, Actor, Tenant, UTC-Startzeit und `ScopeDepth = 1`. Verschachtelte Aufrufe behalten dieselbe logische Execution-ID und erhöhen nur die Tiefe. `USP_EndExecution` verringert die Tiefe und löscht bei der letzten Ebene die sechs Ausführungskontext-Schlüssel; andere Sessionkeys bleiben erhalten.

`TVF_CurrentExecutionContext` ist die primäre, inline lesbare Schnittstelle und
liefert ohne gültige Execution-ID keine Zeile. `SVF_CurrentExecutionId` ist ein
Komfort-Wrapper mit NULL für diesen Fall. Actor und Tenant können über
`USP_SetExecutionContext` geändert oder explizit gelöscht werden. Die erwartete
ID prüft den beabsichtigten logischen Kontext; sie ist kein Sicherheitstoken.
Die sechs Keys gelten für die Verbindung über Datenbankgrenzen hinweg.
Actor/Tenant sind callerbeeinflussbare Labels, keine Authentifizierung oder
Mandantentrennung.

Connection-Pooling-Aufrufer müssen jedes erfolgreiche Begin mit End paaren. Das Modul persistiert keinen Zustand außerhalb der Session.

## Vollständige Skills und Hilfe

- [Kontext relational lesen](../../Metadata/UsageSkills/toolbelt_core/TVF_CurrentExecutionContext.md)
- [Execution-ID skalar lesen](../../Metadata/UsageSkills/toolbelt_core/SVF_CurrentExecutionId.md)
- [Scope beginnen](../../Metadata/UsageSkills/toolbelt_core/USP_BeginExecution.md)
- [Labels und Correlation aktualisieren](../../Metadata/UsageSkills/toolbelt_core/USP_SetExecutionContext.md)
- [Scope beenden](../../Metadata/UsageSkills/toolbelt_core/USP_EndExecution.md)

Diese kanonischen Texte stehen identisch in der jeweiligen DDL. Die Prozeduren
geben sie mit `@Hilfe=1` als ein zusätzliches vierkolumniges Resultset nach der
bisherigen Standardhilfe aus, vor fachlichem Kontextlesen/-schreiben. Bei Begin
bleibt ein bereits übergebener `@ExecutionId OUTPUT` im Hilfezweig erhalten.
End und Set behalten ihr Pflichtargument auch im Hilfeaufruf:

```sql
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL,@Hilfe=1;
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=NULL,@Hilfe=1;
```

Die neue zusätzliche Ausgabe ist offline geprüft; ihre native Abnahme bleibt
separat. Fachliche Schreibaufrufe setzen mehrere Sessionkeys sequentiell ohne
eigene Kompensationsklammer. Bei Enginefehlern nicht ungeprüft von einem
atomaren Mehrkey-Zustand ausgehen; keine parallele direkte Manipulation der
Toolbelt-Keys. Einzelheiten und Grenzen stehen in den Skills.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948
sowie der erfolgreiche physische Linux-Lauf 2019/2022/2025 vom 2026-08-29.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger W4-Moduladapter mit lokalem und zentralem Deployment, Transaktions-, Lifecycle- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
