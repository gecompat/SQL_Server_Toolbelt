# Result Table Infrastructure

`USP_PrepareResultTable` bereitet eine vorhandene lokale Temp-Tabelle für
Resultsets anderer Toolbelt-Procedures vor. Die Procedure prüft Referenzschema,
Collation und Datenerhalt, erzeugt selbst aber keine fachlichen Ergebniszeilen.

## Status

Aktueller Implementierungs-, Validierungs- und Releasestatus stehen im
[kanonischen Modulmanifest](module.yaml) und in der daraus abgeleiteten
[Modulübersicht](../README.md). Die [V0c-Abnahme vom 2026-10-19](../../Tests/V0C_RELEASE_GATE_STATUS.md)
belegt die vollständige Fachmatrix und den verpflichtenden Lastfall. Der
[zusätzliche Callerrechtebericht](../../Releases/1.0.0/TABLE-ENVELOPE-RIGHTS-INVESTIGATION.md)
grenzt die am 2026-10-24 geprüften Rechteprofile ab. Weitere Releasegates und
Veröffentlichung bleiben eine gesonderte Entscheidung.

Die [Objektdokumentation](Documentation/USP_PrepareResultTable.md) erklärt
Parameter, Verhalten und Fehler. [Deployment](#deployment) führt zur
Installation; die [aktuellen Nachweise](#aktuelle-validierungsevidenz) und die
[historischen Entwicklungsstände](#historische-entwicklungsnachweise) sind getrennt.

## Zweck

Eine Toolbelt-USP kann ihr bekanntes tabellarisches Resultset in eine bereits vom Aufrufer erstellte lokale Temp-Tabelle schreiben. `USP_PrepareResultTable` prüft die Zieltabelle und passt deren Spaltenschema anhand einer vorhandenen Referenztabelle an. Die Procedure schreibt selbst keine fachlichen Resultzeilen.

Die kanonische Spezifikation bleibt [RESULT_TABLE_MODULE_DESIGN.md](../../Documentation/Architecture/RESULT_TABLE_MODULE_DESIGN.md). Der allgemeine USP-Vertrag steht in [USP_CONTRACT.md](../../Documentation/Standards/USP_CONTRACT.md).

## Artefakte

| Pfad | Rolle |
|---|---|
| `Source/USP_PrepareResultTable.sql` | kanonische Procedure-Source |
| `Deployment/Deploy.sql` | parametergesteuerte Erst-, Upgrade- und Wiederholungsinstallation |
| `Deployment/Uninstall.sql` | Dependency-geschützte Entfernung |
| `Documentation/USP_PrepareResultTable.md` | öffentlicher Objektvertrag |
| `Examples/PrepareResultTable.sql` | synthetisches Verwendungsbeispiel |
| `Tests/Static/validate_contract.py` | reproduzierbare statische Vertragsprüfung |
| `Tests/Runtime/USP_PrepareResultTable.Contract.sql` | synthetische Runtime-Contract-Tests |
| `Tests/Runtime/Lifecycle.Contract.sql` | Lifecycle-Prüfungen nach Installation |
| `Tests/Runtime/Compatibility.Smoke.sql` | reduzierte Versionskompatibilitätsprüfung |
| `Tests/Runtime/Central.Contract.sql` | dreiteiliger Aufruf aus einer konsumierenden Datenbank |
| `Tests/Runtime/Collation.Contract.sql` | explizite CI-, CS-, BIN2- und UTF-8-Collation-Prüfungen |
| `Tests/Runtime/BoundaryAndTransaction.Contract.sql` | 1024-Spalten- und Transaktionsgrenzfälle |
| `Tests/Runtime/SavepointEngineError.Contract.sql` | natürlicher Enginefehler 2705 nach begonnener Mutation und vollständiger Savepoint-Rollback |
| `Tests/Runtime/MultiSession.Contract.sql` | parallele Isolation gleichnamiger lokaler Temp-Tabellen |
| `Tests/Runtime/Performance.Workload.sql` | reproduzierbarer synthetischer CI-Workload ohne allgemeine Benchmark-Zusage |
| `Tests/Manual_Windows_Runtime_Testplan.md` | manueller Windows-, Savepoint- und Performance-Nachweis mit abstrahierter Rückmeldung |
| `.github/workflows/result-table-runtime.yml` | pfadbezogene GitHub-hosted Linux-Matrix |

## Deployment

Die Lifecycle-Skripte verwenden SQLCMD-Kommandos. `Deploy.sql` bindet die kanonische Source mit `:r` ein; dadurch existiert die Procedure-Implementierung im Repository nur einmal. Das eingebettete Release-Manifest steuert Herkunft, Kollisionen und spätere Objektentfernungen. Lokale Änderungen an nachweislich aus dem installierten Release stammenden Framework-Objekten werden beim Deployment überschrieben. SQLCMD-Variablen sind beim Aufruf explizit mit `-v` anzugeben; eingebaute `:setvar`-Werte würden Kommandozeilenwerte überschreiben und sind deshalb nicht vorhanden.

Aus dem Verzeichnis `Modules/toolbelt.core.result-table/Deployment`:

```text
sqlcmd -S <server> -d <database> -E -b -i Deploy.sql -v DeploymentMode=local
```

Zentrale Installation:

```text
sqlcmd -S <server> -d <toolbelt-database> -E -b -i Deploy.sql -v DeploymentMode=central
```

Deinstallation einer zentralen Installation erfordert die ausdrückliche Betreiberbestätigung:

```text
sqlcmd -S <server> -d <toolbelt-database> -E -b -i Uninstall.sql -v ConfirmNoExternalConsumers=1
```

Die Platzhalter sind absichtlich generisch. Keine Credentials oder realen Infrastrukturwerte werden im Repository gespeichert.

## Wesentliche Grenzen

Der vollständige Moduladapter war am 2026-08-29 auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Windows- und
modulspezifische Hochrisikofälle bleiben Releasevalidierung.

- Ziel ist ausschließlich eine bereits sichtbare lokale Temp-Tabelle.
- Schemaquelle ist eine lokale Temp-Tabelle oder eine zwei-/dreiteilig benannte reguläre Tabelle.
- Ziel- und Referenztabelle dürfen nicht identisch sein.
- Views, Synonyme, Linked Server, permanente Ziele und globale Temp-Tabellen sind nicht unterstützt.
- Ein Schemaumbau entfernt keine Dependencies automatisch.
- Gleichzeitige DDL-Manipulation derselben Zieltable ist nicht unterstützt.
- Frei geliefertes `CREATE TABLE`-DDL wird nicht ausgeführt.

## Quellen

- Microsoft (2026): [CREATE TABLE](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [sys.columns](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-columns-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [sys.types](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-types-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [SAVE TRANSACTION](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/save-transaction-transact-sql?view=sql-server-ver17).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: SQL Server 2025 Linux/latest CL170; vollständiger aktueller Moduladapter einschließlich Pflicht-Lastfall: 100000 Zeilen über 50 KeepData-Aufrufe, 20 Leerungen mit Indexerhalt und zehn Schemawechsel in beide Richtungen; lokales/zentral Deploy, Lifecycle, Uninstall und frischer eigener Cleanupaudit erfolgreich; ergänzt die unveränderte Sechs-Ziel-Fachmatrix. Laufzeitmessung optional und nicht ausgeführt gemäß DEC-2026-036
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

Deployment verlangt vollständige DB-Metadatensicht und Schemaowner dbo.
Schema-/Helperkontrollrechte sowie CONTROL/ALTER ANY SCHEMA der Datenbank sind
nur für dbo und Mitglieder von db_owner beziehungsweise der vom Betreiber
ausdrücklich vertrauenswürdig eingerichteten Rolle toolbelt_core_installer
zulässig. Nicht freigegebene db_ddladmin-Mitglieder werden abgewiesen.
51032/State2 stoppt vor dauerhafter Mutation; kein Ownertransfer oder REVOKE.

Der [freigegebene Vertrag](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md)
beschreibt Scope, Migration und Grenzen. Historische Plattformnachweise gelten
weiter ausschließlich für ihre datierten Quellen.

## Historische Entwicklungsnachweise

Die folgenden unveränderten datierten Texte und die damalige Statustabelle
beschreiben frühere Arbeits- und Abnahmeverträge. Für den heutigen Status
gelten das kanonische Manifest und die oben verlinkte aktuelle Abnahme;
eine ältere Performance-Sperre wird daraus nicht erneut aktiviert.

Lastqualifikation 2026-10-19: Der vollständige Moduladapter einschließlich Pflicht-Lastfall (100000 Zeilen über 50 KeepData-Aufrufe, 20 Leerungen mit Indexerhalt und zehn Schemawechsel in beide Richtungen) bestand auf SQL Server 2025 Linux/latest CL170. Zusammen mit der unveränderten Windows-/Linux-Fachmatrix gilt `validated`; Release bleibt `unreleased`. Optionale Laufzeitmessungen: `not executed`. [Aktuelle Abnahme](../../Tests/V0C_RELEASE_GATE_STATUS.md).

Abnahmeänderung 2026-10-19: Große Lastfälle mit Ergebnisprüfung sind Pflicht; Laufzeitmessungen sind optional und kein Validierungs- oder Release-Gate. Maßgeblich ist [DEC-2026-036](../../Documentation/Architecture/DECISIONS.md#dec-2026-036-verpflichtende-lasttests-und-optionale-laufzeitmessungen). Ältere datierte Aussagen zur verpflichtenden Performance-Abnahme beschreiben den damaligen Vertrag.

Historischer Zwischenstand vor der Abnahmeänderung am 2026-10-19: Der vollständige aktuelle Moduladapter bestand auf SQL Server 2019/2022/2025 unter Windows und Linux. Die abgegrenzte Performance-Abnahme bleibt offen; Runtime: `partially validated`, Release: `unreleased`. Die folgenden datierten älteren Abschnitte beschreiben ihren damaligen Stand. Details: [V0c-Gatebericht](../../Tests/V0C_RELEASE_GATE_STATUS.md).

Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` war auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich; eine vergleichbare plattformübergreifende Performance-Baseline bleibt offen. Der Modulstatus bleibt `partially validated`. Dieser Nachweis ersetzt frühere offene Windows-Aussagen; datierte ältere Einträge bleiben historische Evidenz.

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

### Damaliger Status

| Feld | Wert |
|---|---|
| Modul-ID | `toolbelt.core.result-table` |
| Version | `1.0.0` |
| Implementierung | `implemented` |
| Runtime-Validierung | `partially validated` |
| Release | `unreleased` |
| Persistente Objekte | genau `toolbelt_core.USP_PrepareResultTable` |

Die Procedure und alle gekoppelten Source-, Lifecycle-, Dokumentations- und Testartefakte sind implementiert. Die [aktuelle GitHub-hosted Linux-Matrix](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717) war am 2026-07-29 auf SQL Server 2019, 2022 und 2025 vollständig erfolgreich. Alle drei Versionen führten dieselbe Vollsuite einschließlich lokaler und zentraler Nutzung, expliziter Collations, 1024-Spalten-Grenze, Transaktionspfade, vier paralleler Sitzungen mit identischen logischen Temp-Tabellennamen, Lifecycle und synthetischem Performance-Workload aus. Der natürliche Savepoint-Rollback nach Enginefehler 2705 ist im [GitHub-Actions-Lauf 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855) auf SQL Server 2019, 2022 und 2025 unter Linux erfolgreich. Windows und eine plattformübergreifend vergleichbare Performance-Baseline bleiben `not executed`; daher ist das Modul noch nicht vollständig `validated`.
