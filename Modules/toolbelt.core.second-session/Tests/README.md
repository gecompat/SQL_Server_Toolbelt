# Second-Session-Testevidenz

Der Provider-Spike auf SQL Server 2025 Linux hat einen synchronen Loopback-RPC mit deaktivierter Transaktionspromotion bestätigt. Remote-Commits überleben sowohl einen späteren Caller-Rollback als auch einen bereits uncommittable Caller; die Remote-Ausführung verwendet eine andere `@@SPID`.

Provider-Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703841095

Die vollständige Modulmatrix für Konfiguration, Work-Type-Signaturen, Context-Propagation, ResultTable, Concurrency, Central, Lifecycle und Uninstall wird im dauerhaften W5a-Runtime-Workflow ausgeführt.

Die manuelle Windows-Validierung vom 2026-08-04 lief mit `System.Data.SqlClient` gegen SQL Server 2025 unter Windows erfolgreich. Sie umfasste lokale und zentrale Bereitstellung, einen Collation-übergreifenden Abgleich mit `master.sys.servers`, Provider-Probe, Contract-, Concurrency-, Central- und Lifecycle-Tests sowie geschützten und vollständigen Uninstall. Sie ist kein GitHub-Hosted-CI-Nachweis.

Die vollständige Plattformmatrix `local: Tests/CI/run-lab-local.ps1` war am
2026-09-01 auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter
Windows base und Linux latest erfolgreich. Sie umfasst Provider-Probe,
separate SPID, Caller-Rollback, uncommittable Caller, Fehlerrollback,
Konkurrenz, zentrales Deployment, Lifecycle und Uninstall.

Version `1.1.0` mit resultsetfreier Ausführung: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

## Befüllter versionsgleicher Repeat

[RepeatCurrent.Contract.sql](Runtime/RepeatCurrent.Contract.sql) qualifiziert
zwei echte Deploys des bereits installierten Second Session 1.1.0 jeweils im
gleichen lokalen beziehungsweise zentralen Modus. Die Tabelle erlaubt durch
PK und Provider-Checkconstraint genau einen `loopback`-Eintrag. Das Fixture
speichert daher eine deaktivierte synthetische Zeile mit `localhost` als
reinem Tabellenwert. Es konfiguriert keinen Linked Server, startet keinen RPC
und ruft weder Configure-USP noch einen Handler auf.

Feste verschiedene Created-/Modified-Zeitpunkte mit 100-ns-Anteilen,
synthetische Unicode-/Trailing-Space-Autoren und bereits veränderte Rowversion
werden vor der Baseline gesetzt. Zwischen Baseline und beiden Deploys findet
keine DML an der persistenten Tabelle statt. Das gemeinsame
[Capture](Runtime/RepeatCurrent.Capture.sql) erfasst alle acht Spalten, Text
binär und Rowversion als `binary(8)`. Der
[Assert](Runtime/RepeatCurrent.Assert.sql) vergleicht in beide Richtungen
zusätzlich ausgewählte Katalogmetadaten: sechs Modulobjekte und ihre IDs,
Schemaowner, Spalten, PK/UQ/Check/Defaults, Indizes, vorhandene FKs/Trigger,
Modulmarker, vorhandene Permissions sowie eigene Tabellen-/Spaltenannotation
und nichtleere `MS_Description`. Dieser Installer erneuert keine Beschreibung.
DDL-Zeitstempel gehören nicht zum Orakel. Vorhandene Permissions werden nur
gelesen; eine leere Grantmenge belegt weder nichtleere Benutzergrants noch
tatsächliche Minimalrechte.

Aus `Deployment/` in einer frischen Session mit `DeploymentMode=local` oder
`central` ausführen. Eingang ist eine eigene leere Installationsdatenbank mit
allen drei Dependencies; vorbestehende eigene Annotationsnamen werden
abgewiesen. Nach beiden Repeats wird die View read-only auf den erhaltenen
deaktivierten Eintrag geprüft. Das Fixture entfernt anschließend nur die
eigene Zeile und Properties und bestätigt seine leere Tabelle. Fehler beendet
SQLCMD; der Adapter muss seine eigene Testdatenbank beziehungsweise seinen
eigenen flüchtigen Testscope bereinigen. Kein Wiederaufnehmen einer teilweise
verbliebenen Fixture.

Dieser neue Tabellenrepeat ist bis zu seinem eigenen tatsächlichen Lauf
`not executed`. Historische Provider-/Windows-Evidenz ersetzt ihn nicht.
Windows, weitere Repeat-Compatibility-Levels, nichtleere Benutzergrants,
Minimalrechte und historische Versionsübergänge benötigen eigene Nachweise.
Der Tabellenrepeat beweist keine funktionierende Providerverbindung.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; Provider-Probe, separate SPID, Caller-Rollback, uncommittable Caller, Fehlerrollback, Konkurrenz, zentrales Deployment, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
