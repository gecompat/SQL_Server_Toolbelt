# SQLGlot-Spike für T-SQL ↔ Databricks SQL

Dieser Research-Harness verwendet feste synthetische Eingaben. Provider- und
Regelläufe arbeiten ohne SQL-Engine; der zusätzlich beauftragte Lab-Runner
führt native T-SQL-Vergleiche aus. Er implementiert keinen Toolbelt-Transpiler
und nimmt keinen fremden SQL-Text an.
Der [Ergebnisbericht](../../../Documentation/Research/SQLGLOT_TSQL_DATABRICKS_SPIKE.md)
ordnet die Beobachtungen und verbleibenden eigenen Regeln ein.

## Reproduktion

Python ab 3.10 verwenden; tatsächlich geprüft wurde Python 3.14.7 unter Windows.
Aus dem Repositoryroot in PowerShell:

```powershell
python -m venv .runtime/sqlglot-spike-30.23.0/venv
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe -m pip install --disable-pip-version-check --no-deps --require-hashes --only-binary=:all: --index-url https://pypi.org/simple -r Tests/Research/SqlDialect/requirements.txt
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/run_spike.py --output .runtime/sqlglot-spike-30.23.0/report.json
```

Unter Linux wäre der Interpreterpfad `venv/bin/python`; diese Ausführung wurde
nicht geprüft. Keine systemweite Paketinstallation. Der Harness prüft den
exakten SQLGlot-Pin vor den Versuchen und erlaubt Berichtspfade nur unter dem
ignorierten `.runtime/`-Verzeichnis. JSON und Rohdiagnostik werden nicht
versioniert. Keine SQLGlot-Extras, Compiler, DB-Treiber oder Cloudzugänge nötig.

## Umfang und Interpretation

- 32 unabhängige Eingaben: 18 T-SQL→Databricks und 14 Databricks→T-SQL.
- Source-Parsing und Zielgenerierung mit `ErrorLevel.RAISE`; anschließend
  erneutes Parsen mit demselben SQLGlot, aber explizitem Zieldialekt.
- 34 Beobachtungsassertions prüfen sowohl nützliche Umsetzungen als auch
  bekannte problematische Ergebnisse. Ihr PASS ist kein semantischer PASS
  der 32 SQL-Abfragen.
- Zwei ausdrücklich auf feste Fixtures begrenzte AST-Versuche markieren
  LATERAL wieder als OUTER/CROSS APPLY. Eine negative Kontrolle verhindert
  das Entfernen einer zusätzlichen ON-Bedingung. Keine allgemeine Rewrite-API.
- Roundtrip-Text wird nur diagnostisch erfasst. Insbesondere scheitert die
  direkte APPLY-Rückrichtung auch nach einer erfolgreichen Hinübersetzung.

Im finalen Lauf vom 2026-10-16 wurden 26 Eingaben generiert und wieder geparst;
fünf weitere scheiterten in der Zielgenerierung an LATERAL, eine nach
Command-Fallback erst beim Zielparser. Unter den 26 stehen bewusst auch
V1-widrige oder laut Zieldokumentation problematische Ausgaben. Native
Engineausführung, Werte-/Metadatenparität und Performance sind `not executed`.

## Eigene Regeln

Die anschließend beauftragte Erweiterung ist im
[Regelspike-Bericht](../../../Documentation/Research/SQLGLOT_TSQL_DATABRICKS_RULE_SPIKE.md)
beschrieben. Der erste Lauf bleibt die unveränderte Providerbaseline.
Mit demselben gepinnten Interpreter:

```powershell
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/run_rule_spike.py --output .runtime/sqlglot-spike-30.23.0/rules-report.json
```

`rules_probe.py` enthält einen begrenzten internen AST-Regelkern;
`run_rule_spike.py` prüft aktuell 140 feste Eingaben und 42 vollständige
AST-Roundtrips mit 852 Assertions: 42 positive Umschreibungen und 98 negative
Fälle ohne Teil-SQL, davon 27 mit fehlendem Kontext. Die ursprünglichen
100 Fälle/476 Assertions vom 2026-10-16 bleiben als Eingangskorpus erhalten.
Geprüft sind LATERAL/APPLY, native benannte Parameter, eine kleine
Typmenge samt COUNT/ROW_NUMBER und die Ablehnung unzulässiger Limitoptionen.
Wertliterale und Relationsreferenzen bleiben bei allen positiven Fällen
erhalten. Begrenzte INT-/BIGINT-Ergebniscaste über COUNT/ROW_NUMBER schließen
die drei bisherigen Roundtrip-Lücken. Gruppengrenze, eindeutige Ordnung und
Partitionsgrenze bleiben erforderlich; allgemeine Ausdruckscasts bleiben gesperrt.
Der lokale Bericht bindet die Pythonquellen und den Pin über SHA256.

Eindeutigkeits-, Gruppen-/Partitions- und Zeitprofile sind ausdrücklich
deklarierte synthetische Kontexte. Kein echter Schemabinder, kein Treiberbinding,
keine native SQL-/Performanceprüfung; keine freigegebene V1-API und kein CLI
für fremden SQL-Text.

## Nativer SQL-Server-Lab-Lauf

Der [native Prüfbericht](../../../Documentation/Research/SQLGLOT_NATIVE_TSQL_LAB_PROBE.md)
trennt den SQL-Server-Befund von den weiterhin fehlenden Databricks-Nachweisen.
`build_native_cases.py` erzeugt 81 feste native Fälle samt unabhängigen
Wert-/Multimengen- und Typorakeln. `run_native_lab.ps1` verwendet die kanonische
Lab-Discovery und schema-validierte Zielauswahl für 2019/2022/2025 auf
Windows/Linux. Er bindet INT-Parameter über System.Data.SqlClient und benötigt
keine zusätzliche Treiberinstallation. CTE-/VALUES-Fixtures legen keine
persistenten SQL-Objekte an.

```powershell
pwsh -NoLogo -NoProfile -File Tests/Research/SqlDialect/run_native_lab.ps1 -SelfTest
pwsh -NoLogo -NoProfile -File Tests/Research/SqlDialect/run_native_lab.ps1
```

Am 2026-10-16 bestanden die 57 nativen Fälle auf SQL Server 2019/2022/2025
jeweils Windows und Linux: insgesamt 342 Fallausführungen mit Ergebnis-, NULL-
und Clienttypprüfung. Die vom Benutzer klargestellte Trennung der Testzwecke
ermöglicht `Functional` mit dem schema-validierten Lab-Trustwert. Der frühere
TLS-Blocker ist für diese Fachtests aufgehoben. `-TestPurpose AuthenticatedTls`
verlangt weiterhin False; kein TLS-Nachweis aus dem fachlichen PASS.

Der Folgelauf vom 2026-10-17 bestand mit 81 Fällen auf denselben sechs
Versions-/Plattformkombinationen: 486 erfolgreiche Fallausführungen.
Die drei behobenen Roundtrips einschließlich NULL-/Leerfällen und ein
zusätzlicher Nullable-Spalten-COUNT sind enthalten. Alle 17 T-SQL-Quellmuster
sind rückübersetzbar; kein Roundtrip dieses nativen Korpus wird mehr abgewiesen.
COUNT kehrt als INT, ROW_NUMBER als BIGINT zurück. Der native Prüfbericht
trennt tatsächliche NULL-Werte und Reader-Nullability.

Der native Runner benötigt PowerShell ab 7.5; geprüft ist 7.6.6. Er liest
JSON mit `-DateKind String`, damit ISO-Zeitwerte keine impliziten DateTime-
Objekte werden. Unbenutzte CTE-Hüllen werden bei reinen Castabfragen vermieden.
Beide Fehler wurden in frühen nativen Läufen erkannt und vor dem grünen
Gesamtlauf behoben. Die zwei positiven und acht negativen lokalen
Vergleicherkontrollen bestehen ebenfalls.

Der Runner erzeugt seinen Korpus bei jedem Aufruf frisch. Berichte und
Quellbindungen liegen ausschließlich unter `.runtime/`; Exit 2 kennzeichnet
fehlende native Ausführung, Exit 1 einen Fallfehler oder Quelldrift.
Nicht unterstützte Profile werden weiterhin vor Zielausgabe abgewiesen.
Native Databricks-Tests bleiben unabhängig davon `not executed`; die
nachfolgend dokumentierte Performancewelle ist teilweise qualifiziert.

## Native Databricks-Prüfung: offen

Der [Databricks-Prüfstand](../../../Documentation/Research/SQLGLOT_NATIVE_DATABRICKS_PROBE.md)
dokumentiert 57 vorbereitete SELECTs zu den 81 T-SQL-Vergleichsfällen.
Dieselben synthetischen Relationen, Parameterwerte und unabhängigen Orakel
werden verwendet. Zwölf lokale Harness-Testmethoden bestanden; die
gespeicherten 486 SQL-Server-Fallausführungen wurden lokal gegen Quellen und
Orakel geprüft. Keine Databricks-Abfrage wurde ausgeführt.

Benutzerklarstellung vom 2026-10-17: Aktuell besteht kein Databricks-Zugang.
Die nativen Databricks-Tests bleiben ausdrücklich offen (`not executed`);
es wird keine zusätzliche Infrastruktur eingerichtet. LATERAL, korreliertes
und globales Top-N, COUNT, ROW_NUMBER, Ergebnis-/NULL- und SQL-Typparität
sowie Performance bleiben ohne nativen Databricks-Nachweis. Eine spätere
Ausführung benötigt einen dann verfügbaren, ausgewählten Zugang und ein
festgelegtes Profil. Keine automatischen weiteren Ausführungsversuche.

`run_native_databricks.py` und `test_native_databricks.py` bleiben als
Research-Vorbereitung erhalten. Ihr lokales PASS qualifiziert weder die
Databricks-Engine noch den Live-Transport oder einen typisierten Client.
Die REST-API liefert keine Spalten-Nullability; dafür bleibt ein zusätzlicher
Clientnachweis offen. SQL-Server-Ergebnisse und die bisherigen Regeltests
behalten ihren getrennten Nachweisumfang.

## Native lokale Spark-SQL-Prüfung

Der [Spark-Prüfbericht](../../../Documentation/Research/SQLGLOT_NATIVE_SPARK_PROBE.md)
dokumentiert den anschließend gefundenen Testweg ohne Cloud-Zugang:
**57 positive SELECTs und neun native Negativfälle bestanden auf Apache
Spark 4.0.2**. Derselbe erzeugte Korpus und dieselben Orakel werden verwendet;
die Ergebnisse stimmen mit den gebundenen 81 T-SQL-Fällen auf sechs Zielen
überein. LATERAL mit korreliertem LIMIT/Cutoff, globales Top-N, COUNT,
ROW_NUMBER, Leer-/NULL-Fälle und die vereinbarten SQL-Typen sind damit auf
diesem Spark-Profil tatsächlich ausgeführt.

Unter Windows x64, Python ab 3.12 und der vorhandenen SQLGlot-Umgebung:

```powershell
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/prepare_local_spark.py
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/run_native_spark.py --sql-server-report .runtime/sqlglot-spike-30.23.0/native-roundtrip-report-2026-10-17.json --output .runtime/spark-sql-spike-4.0.2/native-final-report-2026-10-17.json
```

Das Setup prüft exakte SHA256-Pins vor dem Entpacken der offiziellen
PySpark-/Py4J-/Temurin-Artefakte unter `.runtime/`. Keine Systeminstallation,
Cloud-, Container- oder Labbereitstellung. PySpark wird direkt aus der
Distribution importiert; keine SQLGlot- oder Produktdependency geändert.
`run_native_spark.py` verwendet ausschließlich lokale Spark-Tasks, bindet
Parameter über `args` und prüft Ergebnisse, Spark-Schema und Nullability.
Quellen und die vorhandene SQL-Server-Baseline werden vor/nach dem Lauf gebunden.

Der erste Spark-Lauf erkannte einen Harnessfehler beim Binden von Cast-
Ausdrücken. Nach Umstellung auf unterstützte Literalargumente bestand der
vollständige Lauf. Nicht-NULL-Integer sind auf INT begrenzt; None wird als
untypisiertes NULL gebunden. Spark meldet COUNT/ROW_NUMBER als nicht nullable,
SQLClient dagegen als nullable. Diese Unterschiede und die Python-int-
Repräsentation beider Integerbreiten sind im Prüfbericht getrennt dokumentiert.
Databricks und explizit typisiertes NULL-Binding bleiben eigene offene
Abnahmen; Spark ist kein automatischer Databricks-Providerfallback.

## Performance und Ausführungspläne

Der anschließende [Performance-Spike](../../../Documentation/Research/SQL_DIALECT_PERFORMANCE_PROBE.md)
prüft 100.000 und 1.000.000 synthetische Events mit jeweils 2.000 linken
Zeilen. Auf SQL Server 2025/Windows bestanden 34 Varianten-/Indexfälle,
auf Spark 4.0.2 weitere 20. Vier native Kontrollen erkennen den falschen
Cutoff-Filter nach globaler Rangbildung. Echte SQL-Ausführungspläne und finale
Spark-/AQE-Pläne wurden lokal gespeichert und verglichen.

11 SQL-Server- und sieben Spark-Zeitserien bestehen die feste 20-Prozent-
Stabilitätsgrenze einschließlich Bestätigungsbatch; die übrigen 36 liefern
keinen qualifizierten Zeitvergleich. Der Performance-Nachweis ist insgesamt
`partially validated`. Keine Messwerte oder Rohpläne im Repository und kein
Geschwindigkeitssieger zwischen den Engines. Details zu Warm-up, Cache,
Clientmessung, Variantenreihenfolge und Grenzen stehen im Bericht.

```powershell
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/test_performance_cases.py
pwsh -NoLogo -NoProfile -File Tests/Research/SqlDialect/run_performance_lab.ps1 -Output .runtime/sql-dialect-performance/2026-10-17/sql-server.json
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/run_performance_spark.py --output .runtime/sql-dialect-performance/2026-10-17/spark.json
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/analyze_performance.py --directory .runtime/sql-dialect-performance/2026-10-17
```

Die Engines nacheinander ausführen. Eigene Session-Temp-Tabellen und Indizes
werden entfernt; Spark-Caches und Views gehören nur der eigenen Session.
Keine Serveroption, kein gemeinsamer Cache und keine Labressource wird
verändert. Die vorhandene portable Spark-Laufzeit wird wiederverwendet.
Die Regeln bleiben Research-Ergebnisse; kein kostenbasierter Produktrewrite.

## Integrationsprüfung vor Veröffentlichung

Am 2026-10-18 bestanden Provider- und Regellauf erneut (32/140 Eingaben,
34/852 Assertions, 42 Roundtrips), zwölf lokale Databricks-Harness- und vier
Performance-Orakeltests sowie der native Vergleicher-Selbsttest mit zwei
positiven und acht negativen Kontrollen. Der vollständige Dokumentationsaudit
wurde auf dem aktuellen main-basierten Integrationsstand ausgeführt.

Die nativen SQL-Server-/Spark- und Performanceausführungen behalten ihr
Originaldatum 2026-10-17. Ihre Researchquellen sind byteidentisch; Ergebnisse,
Orakel, Paketpins, Berichte und lokale Planbindungen wurden erneut geprüft.
Der inzwischen integrierte gemeinsame Lab-Helfer unterscheidet sich vom
lokalen Ausführungsstand ausschließlich durch CRLF/LF-Zeilenenden; sein
Funktionsinhalt ist unverändert. Strikte Berichtshashes werden deshalb am
originalen lokalen Ausführungsstand geprüft und nicht umgeschrieben. Dies
ist eine geprüfte Wiederverwendung, kein neuer nativer Lauf oder Databricks-Nachweis.

## Dependency und Rechte

SQLGlot 30.23.0, pure-Python-Wheel, MIT. Der öffentliche SHA256-Wert ist in
`requirements.txt` gebunden. Es werden ausschließlich eigene Fixtures und
API-Aufrufe gespeichert; kein Upstreamcode und kein Binary wird vendort.
Die installierte Distribution behält ihre Lizenzdateien. Vor einer späteren
Distribution beziehungsweise Runtime-Aufnahme bleiben deren Notice- und
Dependencyverträge zu erfüllen. Dies ist eine isolierte Testdependency.

Quellen und Due Diligence stehen im [Ergebnisbericht](../../../Documentation/Research/SQLGLOT_TSQL_DATABRICKS_SPIKE.md#dependencyprüfung-und-reproduzierbarkeit).
Die ergänzenden isolierten Spark-/Py4J-/Java-Dependencies und ihre Lizenz-/
Securityprüfung stehen im [Spark-Prüfbericht](../../../Documentation/Research/SQLGLOT_NATIVE_SPARK_PROBE.md#reproduktion-dependencies-und-grenzen).
