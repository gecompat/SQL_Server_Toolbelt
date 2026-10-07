# Testevidenz

Die Runtime-Suite deckt den lokalen Vertrag, Idempotenz, Context-Auflösung,
Transaktionsschutz, Parallelität, Lifecycle und Central Deployment ab. Die
physische SQL_Server_Lab-Matrix ist für SQL Server 2019, 2022 und 2025 unter
Linux und Windows erfolgreich; das Modul ist `validated`.

## Befüllter versionsgleicher Repeat

[RepeatCurrent.Contract.sql](Runtime/RepeatCurrent.Contract.sql) ergänzt die
historische Lifecycle-Suite um zwei echte Deploys des installierten 1.0.0.
Vier synthetische Cancellation-Zeilen enthalten feste UTC-Auditwerte mit
100-ns-Anteilen, synthetische anfordernde Identitäten sowie NULL-, Leerstring-,
Unicode- und Trailing-Space-Gründe. Zwischen Baseline und beiden Deploys
findet keine DML an der persistenten Tabelle statt.

Das gemeinsame [Capture](Runtime/RepeatCurrent.Capture.sql) erfasst alle fünf
Spalten einschließlich der exakten Rowversionbytes. Der
[Assert](Runtime/RepeatCurrent.Assert.sql) vergleicht Zeilen und ausgewählte
Katalogmetadaten in beide Richtungen: vier Modulobjekte und ihre IDs,
Tabellenform, PK, Default, Indizes, vorhandene Constraints/FKs/Trigger,
Schemaowner, Modulmarker, vorhandene Permissions und Tabellen-/Spaltenannotation.
Nichtleere synthetische `MS_Description`-Werte an Tabelle und Reason-Spalte
müssen erhalten bleiben; dieser Installer erneuert sie nicht kanonisch.
Veränderliche DDL-Zeitstempel sind kein Orakel. Vorhandene Permissions werden
nur gelesen; die Fixture erzeugt keine Benutzergrants. Eine leere Grantmenge
ist kein Nachweis für nichtleere Benutzergrants oder tatsächliche Minimalrechte.

Der Aufruf erfolgt in einer eigenen leeren Installationsdatenbank und einer
frischen Session aus `Deployment/`, jeweils mit `DeploymentMode=local` oder
`central`. Nach beiden Repeats werden die Status-TVF und SVF read-only geprüft,
die vier eigenen Zeilen und Annotationen einschließlich eigener Beschreibungen
entfernt und der erfolgreiche
Abschluss mit einem festen Marker bestätigt. Ein Fehler bricht SQLCMD ab;
der aufrufende Adapter muss dann die eigene Testdatenbank beziehungsweise
seinen eigenen flüchtigen Testscope bereinigen. Eine Wiederaufnahme auf
teilweise verbliebener Fixture ist ausgeschlossen.

Dieser neue Repeat-Scope ist bis zu seinem eigenen tatsächlichen Lauf
`not executed`. Historische Windows-/Linux-Evidenz oben ersetzt ihn nicht.
Die CI-Matrix, konkrete erfolgreiche Revision und offene Windows-, weitere
Compatibility-Level-, Minimalrechte- und historische Migrationsprüfungen
werden im nachfolgenden Evidenzeintrag getrennt ausgewiesen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-11`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; SQL Server 2019, 2022 und 2025 unter Linux und Windows; öffentlicher Vertrag, Idempotenz, Transaktionsschutz, Parallelität, Lifecycle, Central und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
