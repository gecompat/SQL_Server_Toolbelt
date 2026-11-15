# SSIS Copy Column V1: aktueller Modellhost auf Windows und Linux

Stand: 2026-11-15 · `PASS_FOR_DECLARED_SCOPE` · unveröffentlicht

Der [quellgebundene Record](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/ExportHost.CopyColumn.20261115.json)
belegt den externen Modell-/CLI-Host nach Copy Column V1 auf beiden Plattformen.
Derselbe portable Host aus Quellsnapshot `8a495ae4303e50bd7367aaa07e1d7adf422e5122`
besteht je 25 Fälle und 305 Assertions; insgesamt 50 Fälle/610 Assertions.
Produktquellen und synthetische Eingaben sind exakt gebunden, die relevanten
Host-/Kernquellen zum integrierten Copy-Column-Stand bytegleich. Binäridentität,
Buildrevision und kanonische Modelloutputs stimmen zwischen Windows und Linux
überein. Die SQL-Assembly wird dadurch weder verändert noch neu qualifiziert.

## Geprüfte Fälle

Die vorhandene Methode prüft 17 CLI-Fälle: beide Paketformate als Modell und
mit vier Bundleoptionen, Unicode-Pfad, nicht exportiertes synthetisches Literal,
unbekanntes Format, DTD, fehlerhaftes XML, Dateierweiterung, fehlende Datei und
Verwendungsfehler. Der neue Wrapper ergänzt acht Copy-Column-Modellfälle:
Paketformat 6/8, Integer/Unicode und Komponentenversion 1/2. Jeweils werden
Paketbytes/-länge, tatsächliches Hostbinary, Buildrevision, native ClassID,
Komponentenzahl, Ports, synchrone Bindung sowie Reihenfolge und Typen der
beiden Kopiespalten geprüft. Version 1 erhält `REGULAR`; die unbekannte Version 2
bleibt ausdrücklich diagnostiziert und erhält keine qualifizierte Portrolle.

Die [Methode und Reproduktion](../../Modules/toolbelt.tsql.ssis-debug/Exchange/README.md#aktueller-modellhost-nach-copy-column-v1)
benötigt ein explizites Hostbinary, die dazugehörige Buildrevision und eine
explizite .NET-10-Runtime. Die Linux-Runtime 10.0.14 wurde im privaten
Testverzeichnis entpackt und gegen den bereits dokumentierten offiziellen
SHA-512-Pin geprüft. Keine globale Installation, SQL-Verbindung, Rechte-,
Trust-, Zertifikats- oder Labänderung. Die eigenen Runtimeverzeichnisse sind
entfernt beziehungsweise frisch als abwesend festgestellt.

## Fehlerhistorie und endlicher Rahmen

Ein gemeinsamer Rahmen mit maximal vier Plattformdispatches und 30 Minuten
wurde vor dem ersten Hostlauf gewählt. Alle vier Dispatches sind geschlossen:
Windows bestand beim ersten Lauf. Der erste Linux-Start fand sein vorher
vorbereitetes temporäres Runtimeverzeichnis nicht mehr; kein Hostprofil startete.
Der zweite Vorbereitungsstart scheiterte an der Windows-Pfadform der Worktree-
Gitdatei, ebenfalls vor dem Qualifier. Die korrigierte Übergabe der bereits unter
Windows bestimmten Buildrevision und die zusammenhängende private Runtime-
Vorbereitung/-Ausführung bestanden anschließend. Beide Fehler und private
Originale bleiben erhalten. Der bestandene Windows-Lauf wurde nicht wiederholt.
Die frühere SQL-Deltaqualifikation bleibt mit ihren 28 Aufrufen geschlossen;
dieser Plattformvergleich enthält keinen SQL-Lauf und erneuert deren Grenzen nicht.

Neun [Offlinegegenproben](../../Tests/Release/test_ssis_copy_column_host.py)
prüfen die echte Quellenbindung und die Ablehnung alter Records, falscher
Plattform-/Binär-/Outputidentität, fehlender Fälle, falscher Zähler, abweichender
Runtimepins und Scopeaufwertungen. Sie laufen in den bestehenden Windows-/Linux-
Offlinejobs; keine zusätzliche Workflow-, Agenten- oder Reviewkette. Die
Workflowselektoren berücksichtigen die zugehörigen Validator-/Testdateien
gezielt. Es entsteht kein neuer nativer CI-Linux-Lauf.

## Verbleibende Grenzen

Dieser Nachweis ersetzt keinen vollständigen neuen ZIP-Matrixlauf, sichtbaren
SSMS-Gesamtfall, authentifizierten TLS-Consumerfall oder Modulgesamt-PASS.
SQL CLR unter Linux bleibt nicht unterstützt; native SSIS-Runtime-Parität,
unbegrenzte Produktionskapazität und OS-/VM-Verlust sind nicht qualifiziert.
Die älteren Records behalten Datum, Artefakte und ursprünglichen Scope,
insbesondere die damalige Linux-Angabe im Copy-Column-Delta-Record.
Gesamtmodul weiterhin `partially validated`, `unreleased`. Aktuelle Head-/Main-CI
sind getrennte Integrationsgates. Keine Veröffentlichung oder Tags.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-15`
- Nachweis: `local: aktueller Copy-Column-Modellhost auf Windows und Linux`
- Scope: PASS_FOR_DECLARED_SCOPE: dasselbe portable Hostbinary, je25 CLI-/Modellfaelle und305 Assertions, insgesamt50/610; acht neue Copy-Column-Format-/Typ-/Versionsfaelle jePlattform. Exakt gleiche Quellen-/Binarypins und kanonische Outputs. Windows beim ersten Lauf bestanden; zwei Linux-Vorbereitungsfehler mit null Hostprofilen erhalten, korrigierter Lauf bestanden. Vier Plattformdispatches im gemeinsamen30-Minuten-Rahmen geschlossen, private Runtime entfernt/Abwesenheit geprueft. Keine SQL-, Rechte-, Trust-, Lab- oder Produktquellaenderung; kein neuer ZIP-/SSMS-/TLS-/Modulgesamt-PASS.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
