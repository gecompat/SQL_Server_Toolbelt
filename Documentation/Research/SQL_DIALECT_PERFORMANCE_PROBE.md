# APPLY/LATERAL und Top-N: native Performance- und Planprüfung

Stand: 2026-10-17 · Autor: Codex · Status: **Ergebnis-/Planprüfung bestanden;
Performance `partially validated`**. Native Databricks-/Photon-Abnahme bleibt
`not executed`. Keine V1-Implementierungsfreigabe und kein produktiver Optimierer.

## Ergebnis und Nachweisumfang

Auf SQL Server 2025 unter Windows bestanden 34 feste Varianten-/Indexfälle;
auf lokalem Apache Spark 4.0.2 bestanden 20 Variantenfälle. Jeder Fall wurde
mit einem unabhängigen synthetischen Orakel einschließlich NULL-Erweiterung,
Duplikaten und Reihenfolge verglichen. Die tatsächlichen SQL-Server-Pläne
und die ausgeführten Spark-Pläne wurden lokal gespeichert und geprüft.
Vier native Negativkontrollen erkennen die fachlich falsche Anwendung des
Cutoff-Filters erst nach einer globalen Rangbildung.

| Engine | Ergebnis-/Planfälle bestanden | Zeitserien mit bestandenem Stabilitätsgate | Zeitserien ohne qualifizierten Zeitvergleich |
|---|---:|---:|---:|
| SQL Server 2025 / Windows | 34 | 11 | 23 |
| Apache Spark 4.0.2 / Windows | 20 | 7 | 13 |

Das Gate verlangt höchstens 20 Prozent Streuung der Batchmediane und einen
separaten Bestätigungsbatch innerhalb derselben Grenze. Die übrigen Serien
werden für den **Zeitvergleich** als `not executed` mit
`PERFORMANCE_STABILITY_UNAVAILABLE` geführt. Ihre Abfragen und Planprüfungen
wurden tatsächlich ausgeführt und bestanden; ihre beobachteten Zeiten tragen
keine Geschwindigkeitsbehauptung. Der Research-Nachweis ist insgesamt teilweise
qualifiziert, kein Release- oder Performance-Regressionsbaseline-Nachweis.

Rohpläne, Messwerte, Quotienten, Baselines und konkrete Laufzeitangaben bleiben
gemäß [Test- und Validierungsrichtlinie](../Standards/TEST_AND_VALIDATION_POLICY.md#performance-messungen)
ausschließlich unter `.runtime/sql-dialect-performance/2026-10-17/`.
`measurements.md` enthält die lokale Zeitentabelle, `assessment.json` die
gebundene Auswertung. Hier stehen redigierte Planbefunde und begrenzte Regeln.

## Synthetische Daten und Varianten

[`performance_cases.py`](../../Tests/Research/SqlDialect/performance_cases.py)
definiert zwei unabhängige Größen: **100.000 und 1.000.000 Events**, jeweils
2.000 linke Zeilen mit einer eindeutigen RowId und einem Schlüsselbereich
von 1.000 ParentIds. Die Daten enthalten doppelte linke Geschäftsschlüssel
mit unterschiedlichen Cutoffs, NULL-Schlüssel, NULL-Zeitwerte, NULL-Cutoffs,
fehlende Treffer und gleiche EventTime-Werte. EventId entscheidet Zeitgleichstände.
EventTime und CutoffTime sind DATETIME2(6) beziehungsweise TIMESTAMP_NTZ.

| Szenario | Linker Scope / N | Vergleich |
|---|---|---|
| selective | Erste 32 linke Zeilen, Top-1 pro Schlüssel | Korreliert; globales Window; vor dem Window auf benötigte Schlüssel eingeschränkt |
| broad | Alle 2.000 linken Zeilen, Top-3 pro Schlüssel | Dieselben drei Varianten |
| cutoff | Alle linken Zeilen, Top-1 unter ihrem eigenen Cutoff | Korreliert; erst zulässige Kandidaten joinen, dann Window pro linker RowId |
| global | Globales Top-100 | Direktes TOP/LIMIT; ROW_NUMBER mit Rangfilter und gleicher Ergebnisordnung |

Auf SQL Server wird die Event-Tabelle zunächst als Heap geprüft, begrenzt
auf selective und global. Anschließend wird ein abdeckender Parent-/Zeitindex
für alle Szenarien geprüft; ein zusätzlicher globaler Zeitindex wird nur für
global geprüft. Der Heap-Versuch enthält absichtlich keinen unbeschränkten
breiten APPLY-Lauf. Die linke Tabelle besitzt stets ihren eigenen RowId-Schlüssel.

Die zwei getesteten Indexformen sind ausschließlich eigene Temp-Fixtures:

```sql
CREATE INDEX IX_PerfEvent_Parent_Time_Id
    ON #PerfEvent(ParentId, EventTime DESC, EventId DESC) INCLUDE(EventTick);
CREATE INDEX IX_PerfEvent_Time_Id
    ON #PerfEvent(EventTime DESC, EventId DESC) INCLUDE(ParentId, EventTick);
```

Indexaufbau und Datenbeladung liegen außerhalb der Abfragezeiten. Die
Ergebnisse sind deshalb keine Amortisations-, Schreibkosten- oder
Speicherbewertung einer produktiven Indexänderung.

## Ausführungspläne: tatsächlich beobachtete Unterschiede

Die folgenden Abläufe sind abstrahierte Beschreibungen eigener synthetischer
Pläne, keine übernommenen Rohpläne oder konkreten Umgebungsdaten.

| Profil | Nativer Planbefund | Bedeutung |
|---|---|---|
| SQL Server, selektives APPLY auf Heap | Table Scan, Sort, Index Spool und Nested Loops | TOP macht einen fehlenden Zugriffspfad nicht kostenlos; der Optimierer baut hier einen aufwendigen Zwischenzugriff auf |
| SQL Server, APPLY mit Parent-/Zeitindex | Nested Loops, Top, Index Seek | Gleichheit auf ParentId und Zeitbereich können den geordneten Zugriff begrenzen; kein zusätzlicher innerer Sort erforderlich |
| SQL Server, globales Window mit Parent-/Zeitindex | Index Scan, Window Aggregate, Filter und Hash Match | Ein mengenorientierter Rangpfad ersetzt wiederholte innere Zugriffe, verarbeitet jedoch auch die nötige rechte Eingabemenge |
| SQL Server, Cutoff-APPLY mit Index | Seek-Prädikate über ParentId und EventTime/CutoffTime | Der individuelle Cutoff bleibt im inneren Suchbereich erhalten |
| SQL Server, globales TOP mit globalem Zeitindex | Top über geordnetem Index Scan | Ein Index mit ParentId als führender Spalte erfüllt eine globale Zeitordnung nicht automatisch |
| Spark, LATERAL | InMemoryTableScan, Sort, Window, Exchange und je Profil BroadcastHashJoin oder SortMergeJoin | LATERAL wird hier mengenorientiert dekorreliert; es ist kein SQL-Server-Indexseek pro linker Zeile |
| Spark, gruppiertes explizites Top-N-Window | Zusätzlich WindowGroupLimit in den beobachteten Varianten | Die explizite Rangbegrenzung öffnet einen anderen Planpfad; zusätzliche Filter-/Joinarbeit kann bleiben |
| Spark, direktes globales LIMIT | TakeOrderedAndProject über dem Cache | Der globale Top-N-Operator bleibt direkt ausdrückbar |
| Spark, globales ROW_NUMBER | TakeOrderedAndProject vor einem zusätzlichen Window-/Filterpfad | Spark begrenzt hier schon vor der Rangbildung. Die Behauptung, dieses Window müsse stets die gesamte Million global sortieren, wäre falsch |

Einige SQL-Pläne melden `MemoryGrantWarning` mit `Excessive Grant`. Das ist
ein Hinweis, die Schätzungen und konkurrierende Speicheranforderungen zu
prüfen, keine gemessene Störung und kein Anlass für automatische Serveränderungen.
Die Warnungen und Counter stehen nur im lokalen Nachweis.

SQL-Pläne wurden mit
[SET STATISTICS XML](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-statistics-xml-transact-sql?view=sql-server-ver17)
nach einer tatsächlichen Ausführung erfasst; sie enthalten Runtime-Counter.
Die separate Planabholung gehört nicht zum Zeitfenster. Spark verwendet
den ausgeführten Plan nach `collect`; bei AdaptiveSparkPlan muss
`isFinalPlan=true` gelten. Die Auswertung trennt den finalen AQE-Plan vom
ebenfalls ausgegebenen Initialplan.

## Begrenzte Zeitbefunde und Optimierungsregeln

Nur zwei stabile Serien mit getrennten Batchmedianbereichen begründen im
lokalen Auswerter eine Richtung. Diese Bereiche sind keine statistischen
Konfidenzintervalle. Es gibt keine Engine-übergreifende Geschwindigkeitsrangliste.

| Regelkandidat | Befund / Grenze | Konsequenz für einen späteren Transpiler |
|---|---|---|
| Selektives SQL-Server-Top-N mit passendem Index | Bei 100.000 Events ist derselbe APPLY-Pfad mit abdeckendem Parent-/Zeitindex im stabilen Vergleich deutlich günstiger als auf dem Heap | APPLY nicht pauschal durch ein Window ersetzen; vorhandene Zugriffspfade und Selektivität als Kontext behandeln |
| Breiter Schlüssel-Scope | Bei 100.000 Events haben die beiden expliziten Window-Varianten im stabilen SQL-Server-Vergleich niedrigere Clientzeiten als APPLY | Window als Alternative evaluieren, wenn die Kandidatenmenge pro Geschäftsschlüssel identisch ist; kein allgemeiner Sieger und keine bestätigte Skalierungsaussage für die instabilen Million-Fälle |
| Globale Ordnung braucht das passende Indexpräfix | Das globale Top-N mit einer Million Events profitiert im stabilen SQL-Server-Vergleich vom globalen Zeitindex gegenüber dem Parent-Indexprofil | Globale und gruppierte Ordnung getrennt modellieren; keine automatische produktive Indexanlage |
| Explizites Spark-Window kann günstiger sein | Bei 100.000 Events ist im stabilen selektiven Vergleich das explizite globale Window günstiger als LATERAL; sein Plan enthält WindowGroupLimit | Eine plausible Erklärung ist der andere Begrenzungspfad. Dessen isolierter Kostenbeitrag wurde nicht bewiesen; Capability und Kosten müssen am Zielprofil geprüft werden |
| Globales TOP/LIMIT erhalten | Bei 100.000 Events ist der direkte Spark-Top-N-Pfad im stabilen Vergleich günstiger als die Rangvariante | Für globales N keine unnötige ROW_NUMBER-Umschreibung erzeugen; die getestete Spark-Optimierung des Windows trotzdem berücksichtigen |
| Schlüsselfilter vor Rangbildung | Die Semijoin-Variante ist wertgleich; ihre Pläne enthalten zusätzliche Arbeit und nicht alle Zeitvergleiche sind stabil | Optionaler Kandidat, keine universelle Beschleunigungsregel; Filter nur verschieben, wenn er den Rangraum fachlich unverändert einschränkt |
| Keine blind übernommenen Hints | SQL Server und Spark haben unterschiedliche Zugriffspfade; Spark-AQE wählt hier je Profil unterschiedliche Joinarten | Keine Index-/Loop-/Broadcast-Hints aus dem Quelldialekt ableiten oder ungeprüft erzwingen |

Die allgemeinen Empfehlungen zu Schlüsselreihenfolge, SARGability und
Abdeckung werden vom
[Microsoft-Indexleitfaden](https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide?view=sql-server-ver17)
gestützt. Für diese Fixtures wurden direkte Zeitbereichsprädikate verwendet;
eine zusätzliche Funktions-/Cast-auf-Spalte-Variante wurde nicht gemessen.
Spark dokumentiert [Caching, Joinstrategien und AQE](https://spark.apache.org/docs/4.0.2/sql-performance-tuning.html).
Diese Herstellerregeln ergänzen die Beobachtung; sie ersetzen keinen der
hier fehlenden stabilen Zielvergleiche.

## Harte Semantikgrenzen für Umschreibungen

1. **Cutoff vor Auswahl der besten Kandidaten.** Erst globale rn<=N bestimmen
   und anschließend EventTime<=Cutoff filtern verliert frühere zulässige Events.
   Die absichtlich falsche Variante scheiterte an beiden Datengrößen auf beiden Engines.
2. **Linke Zeilenidentität erhalten.** Bei unterschiedlichen Cutoffs desselben
   Schlüssels bildet die getestete Alternative zuerst die zulässigen inneren
   Kandidaten und partitioniert dann nach der eindeutigen linken RowId. Nur nach
   ParentId zu partitionieren wäre dafür keine bewiesene Ersatzregel.
3. **OUTER- und Duplikatverhalten bewahren.** Fehlende Kandidaten werden durch
   LEFT JOIN auf die ursprüngliche linke Multimenge zurückgeführt. Der Rangfilter
   gehört in diese Joinbedingung; ein unbedachtes WHERE rn<=N entfernt NULL-erweiterte Zeilen.
4. **Eindeutige Ordnung verlangen.** EventTime besitzt absichtliche Gleichstände;
   EventId ist der Tiebreaker. TOP/LIMIT ohne eindeutige Ordnung bleibt ungeeignet
   für einen deterministischen Differentialvergleich. Siehe auch
   [TOP und ORDER BY](https://learn.microsoft.com/en-us/sql/t-sql/queries/top-transact-sql?view=sql-server-ver17).
5. **Fan-out prüfen.** Joinen vor Rangbildung kann Kandidaten vervielfachen.
   Ein korrektes Window ist deshalb noch keine kostengünstige Dekorrelation.
   Ein allgemeiner Beweis aus echten Schemas und eine Ressourcenobergrenze fehlen.

Die Vergleichsabfragen sind feste Research-Alternativen. Die bestehende
SQLGlot-Positivliste, der Typbinder und der Regelkern wurden nicht erweitert;
kein automatischer kostenbasierter Dekorrelator wurde implementiert.

## Messmethode, Reproduktion und verbleibende Grenzen

SQL Server verwendet ein explizit schema-validiertes Windows-/SQL-2025-/CU8-
Labziel mit Hyper-V-Provider und `TestPurpose=Functional`. Kein Docker-
Leistungsnachweis, keine neue Labressource und keine TLS-Identitätsqualifikation.
Die Daten liegen ausschließlich in eigenen Session-Temp-Tabellen. Die
Verbindung ist nicht gepoolt; Tabellen werden explizit verworfen und die
Verbindung wird auch im Fehlerpfad geschlossen.

Spark nutzt die bereits vorhandene portable Laufzeit mit lokalem `local[2]`,
vier synthetisch festgelegten Quell-/Shufflepartitionen, AQE, ANSI, UTC und
TIMESTAMP_NTZ. Die DataFrame-Caches werden vorab materialisiert und ihre
Zeilenzahl sowie unabhängige Summen-/NULL-Orakel geprüft. Eigene Caches und
Views werden anschließend entfernt, die Spark-Session beendet. Beide Engines
laufen nacheinander; es werden keine gemeinsamen Servercaches geleert.

SQL Server erhält zwei Warm-up-Aufrufe. Danach mittelt jede Probe eine
kalibrierte Anzahl von maximal 32 identischen Ausführungen. Spark erhält vier
Warm-up-Aufrufe und misst jede Abfrage einmal pro Probe. Je Variante folgen
drei Batches mit drei Proben; Batch drei bestätigt die ersten beiden.
Ergebnis-/Hashsortierung liegen außerhalb der Uhr. SQL erfasst jedoch RPC,
Reader und Kanonisierung der Ergebniswerte; Spark erfasst Planung, Ausführung,
Transfer und Python-Materialisierung durch `collect`. Das sind Clientzeiten,
keine gleichwertigen serverseitigen CPU-Messungen.

```powershell
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/test_performance_cases.py
pwsh -NoLogo -NoProfile -File Tests/Research/SqlDialect/run_performance_lab.ps1 -Output .runtime/sql-dialect-performance/2026-10-17/sql-server.json
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/run_performance_spark.py --output .runtime/sql-dialect-performance/2026-10-17/spark.json
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/analyze_performance.py --directory .runtime/sql-dialect-performance/2026-10-17
```

Alle abschließenden Befehle bestanden am 2026-10-17. Vier lokale Testmethoden
prüfen das begrenzte Heap-Orakel zusätzlich gegen vollständige kleine
Python-Relationen sowie Duplikate/NULLs, Reihenfolge, Stabilitätsablehnung und
die linke Identität im Cutoff-Window. Native Ergebnisse, Datenorakel, Quellen,
Lab-Helfer und lokale Pläne sind im Auswerter gebunden. Ein früher SQL-Aufbau
erzeugte Temp-Tabellen versehentlich im parametrisierten sp_executesql-Scope;
die folgende Abfrage meldete 208. Das DDL liegt jetzt im Session-Batch, nur
die Befüllung ist parametrisiert. Dieser Aufbaufehler zählt nicht als Messbefund.

Offen bleiben kalte Daten-/Plancaches, echter Datenträger-I/O, Delta/Parquet,
verteilte Spark-Cluster, Skew-Workloads, breite Payloads, konkurrierende Last,
unterschiedliche N-/Parameterprofile, SQL Server 2019/2022 und Databricks/Photon.
Die Variantenreihenfolge ist fest und nicht randomisiert. Die Ursachen der
instabilen Serien wurden nicht isoliert. Ohne kontrolliertere Last und
erneute unabhängige Bestätigung dürfen sie nicht nachträglich als stabil
umgedeutet oder die Gategrenzen zur Statusaufwertung gelockert werden.
