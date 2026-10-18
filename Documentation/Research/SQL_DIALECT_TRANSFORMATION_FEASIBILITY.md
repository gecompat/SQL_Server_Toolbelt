# SQL-Dialekte und DataFrame-Sprachen kontrolliert transformieren

Stand: 2026-10-16 · Autor: Codex · Status: `researched`.
Benutzerauftrag: Machbarkeit, Erweiterungen, Quellen-Ziel-Matrix und Vorgehen
für mindestens T-SQL ↔ Databricks SQL untersuchen und im Backlog erfassen.
Keine Implementierungsfreigabe. Ein anschließend beauftragter
[lokaler SQLGlot-Spike](SQLGLOT_TSQL_DATABRICKS_SPIKE.md) wurde am 2026-10-16
mit 32 synthetischen Eingaben ausgeführt; native Engine- und Performance-
versuche waren zu diesem Zeitpunkt `not executed`. Die Beispiele in diesem ursprünglichen
Planungsdokument bleiben eigene synthetische Entwürfe, keine getesteten
Übersetzungsergebnisse.

Die spätere [Erweiterung um eigene Researchregeln](SQLGLOT_TSQL_DATABRICKS_RULE_SPIKE.md)
prüft LATERAL/APPLY, Parameter, begrenzte Typabbildungen und Limit-Gates in
inzwischen 140 synthetischen Fällen und 42 Roundtrips. Auch dieser AST-Nachweis ersetzt keine native
Engine-/Ergebnis-/Performancequalifikation.

Konkretisierung vom 2026-10-16:
[Erster Funktionsumfang T-SQL ↔ Databricks SQL](TSQL_DATABRICKS_V1_SCOPE_PROPOSAL.md)
legt die vorgeschlagene Positivliste, benötigte Kontextangaben, manuellen
Grenzen, APPLY-/Top-N-Regeln und Performanceabnahme fest. Dieser engere
Vertragsvorschlag konkretisiert den ersten SQL-Kern der breiteren Planung;
er ist weiterhin keine Implementierungsfreigabe.

**Nachgeführter Prüfstand, 2026-10-18:** Die [native SQL-Server-Prüfung](SQLGLOT_NATIVE_TSQL_LAB_PROBE.md)
bestand am 2026-10-17 mit 81 Fällen auf sechs Labzielen; die [lokale Spark-Prüfung](SQLGLOT_NATIVE_SPARK_PROBE.md)
mit 57 positiven und neun negativen Fällen. Die [Performance-/Planprüfung](SQL_DIALECT_PERFORMANCE_PROBE.md)
ist teilweise qualifiziert. Native Databricks-Tests bleiben ausdrücklich offen;
der begrenzte Researchkern ist kein freigegebenes Produkt-V1.

## Machbarkeit und Empfehlung

**Ja, für definierte Sprach- und Funktionsprofile ist das Vorhaben machbar.**
T-SQL ↔ Databricks SQL sollte der erste, in beiden Richtungen eigenständig
geprüfte Vertrag sein. SELECT, CTEs, Joins, Aggregationen und Window Functions
sind ein sinnvoller Ausgangspunkt. Ein Parser mit Generator ist verfügbar;
Schema-, Typ- und Semantikregeln sowie Differentialtests bleiben eigene Arbeit.
Eine allgemeine verlustfreie Konvertierung beliebiger Skripte oder Routinen
ist daraus nicht ableitbar. Erfolgreiches Parsen oder eine Rückübersetzung
beweist keine Gleichwertigkeit.

Databricks SQL und Apache Spark SQL erhalten getrennte Profile. Databricks
ergänzt Spark um eigene Sprachelemente und Plattformdienste. Python wird als
konkrete API wie PySpark DataFrame, Ibis, Polars oder pandas betrachtet;
beliebiger Python-Code ist kein SQL-Dialekt. Scala/Java DataFrame sind weitere
plausible Ausgabeziele für denselben begrenzten relationalen Kern.

Empfehlung: lokaler externer Übersetzungskern, AST-basierte SQL-Adapter und ein
kleines typisiertes Zwischenmodell für tatsächlich unterstützte Operationen.
Keine vollständige eigene SQL-Grammatik bauen. Zuerst SQLGlot evaluieren und
mit Lakebridge/Morpheus vergleichen; Python-Ausgabe erst nach Qualifikation
des SQL-Kerns. Das ist eine Planungsschlussfolgerung aus den folgenden Quellen,
keine bereits ausgewählte Dependency oder Architekturentscheidung.

## Repositorybezug und Abgrenzung

Der persönliche [Brainstorm](../../Backlog/personal_Backlog_Bainstorm.md), die
[Research-Inbox](../../Backlog/TOOLBELT_RESEARCH_INBOX.md), alle drei
Kandidatenlisten und `.ai/BACKLOG.md` wurden auf Überschneidungen geprüft.
Die gezielte Suche nach Transpiler, Databricks, Spark und Dialektübersetzung
ergab keine bereits vorhandene entsprechende Capability.

- `RI-2026-140` / `TC-2026-047` liefern Parserinfrastruktur, keinen universellen
  Transpiler. Das aktuelle [Parsermanifest](../../Modules/toolbelt.tsql.script-parser/module.yaml)
  nennt 2.0.0, `implemented`, `partially validated`, `unreleased` und einen
  Windows-only-UNSAFE-CLR-Provider. AST und Tokens enthalten keine vollständige
  semantische Bindung. Diese Plattformgrenze wird nicht auf einen externen
  Python-Host übertragen; dessen Portabilität ist gesondert nachzuweisen.
- `TC-2026-026` betrifft kontrollierte Python-Ausführung, nicht Codeerzeugung.
  `TC-2026-028` ist keine Freigabe, SQL an einen KI-Dienst zu übertragen.
- Die [SSIS-/DTSX-Vormerkung](SSIS_DTSX_DEBUG_SELECT_FEASIBILITY.md) erzeugt
  schrittweise prüfbares T-SQL. Ein späterer Dialektadapter könnte daran
  anschließen; er erweitert deren Eingabe-, Schreib- oder Runtimevertrag nicht.
- Gemäß [Repository-Grenzen](../Architecture/REPOSITORY_BOUNDARIES.md) passt
  definierte Code-Transformation in Toolbelt. Eine allgemeine Lint-,
  Plananalyse-, Diagnose- oder Tuningfunktion gehört nach SQL_Server_Analyze.
  Hier geht es um geeigneten erzeugten Code und dessen eigene Qualifikation.
- Ein externer Kern ist technisch plausibel. Ob er als Toolbelt-Komponente,
  optionaler Host oder gesondertes Werkzeug verteilt wird, ist noch zu
  entscheiden. Eine spätere SQL-Fassade ist ein eigener Funktionsvertrag;
  kein Python-Runtime-Nachbau innerhalb der bestehenden Parserassembly.

## Quellen-Ziel-Matrix für SQL

Die Matrix bewertet **Planung und technische Plausibilität für einen
relationalen Teilumfang**, nicht vollständige Produktunterstützung. SQLGlot
führt alle aufgeführten Dialekte in seiner [Dialektliste](https://github.com/tobymao/sqlglot#supported-dialects).
Das belegt verfügbare Adapter, keine garantierte Konvertierung jeder Kombination.
Jede Richtung braucht eigene Feature- und Versionsnachweise.

Legende:

- **K**: empfohlener erster Kernumfang; noch zu implementieren und zu prüfen.
- **E**: sinnvolle nachfolgende Erweiterung; eigenes Richtungsprofil notwendig.
- **O**: mit vorhandenen Adaptern grundsätzlich untersuchbar; hier weder
  priorisiert noch im Paar vertieft oder empirisch belegt.
- **=**: gleiche Dialektfamilie; Versionsmigration und Normalisierung können
  trotzdem semantische Änderungen erfordern.

| Quelle ↓ / Ziel → | T-SQL | Databricks | Spark SQL | PostgreSQL | DuckDB | Snowflake | BigQuery | Trino | MySQL | Oracle SQL |
|---|---|---|---|---|---|---|---|---|---|---|
| T-SQL | = | **K** | E | E | E | E | E | E | O | O |
| Databricks SQL | **K** | = | E | E | E | E | E | E | O | O |
| Spark SQL | E | E | = | O | O | O | O | O | O | O |
| PostgreSQL | E | E | O | = | O | O | O | O | O | O |
| DuckDB | E | E | O | O | = | O | O | O | O | O |
| Snowflake | E | E | O | O | O | = | O | O | O | O |
| BigQuery / GoogleSQL | E | E | O | O | O | O | = | O | O | O |
| Trino | E | E | O | O | O | O | O | = | O | O |
| MySQL | O | O | O | O | O | O | O | O | = | O |
| Oracle SQL | O | O | O | O | O | O | O | O | O | = |

Nicht jede E-Kante gehört in dieselbe Welle. Empfohlene Reihenfolge:
Spark SQL, PostgreSQL/DuckDB, danach bedarfsabhängig Snowflake, BigQuery und
Trino. MySQL/Oracle bleiben Optionen. Hive, Redshift und weitere Dialekte
können später ergänzt werden; die bloße Parserverfügbarkeit begründet keinen
Supportvertrag und keine vollständige Paarmatrix als Testpflicht.

| Priorisierte Richtung / Erweiterung | Nutzen und Verfahren | Wesentliche Grenze |
|---|---|---|
| T-SQL → Databricks SQL | SQL-Server-Abfragen in Lakehouse-Workloads übernehmen; AST, Typbindung und gezielte Rewrite-Regeln | APPLY/Korrelation, Datum/Zeitzone, Collation, Temp-Objekte, SQL-Server-spezifische Funktionen |
| Databricks SQL → T-SQL | Relationale Logik für SQL Server 2019/2022/2025 ausgeben | QUALIFY braucht gegebenenfalls eine Unterabfrage; ARRAY/MAP/STRUCT, Delta/Unity-Catalog-Funktionen und höhere Präzision/Typbreite nicht beliebig rückführbar |
| T-SQL ↔ Spark SQL; Databricks ↔ Spark SQL | Open-Source-Spark und Databricks getrennt adressieren | Exakte Sparkversion, ANSI-Modus und Databricks-Erweiterungen; installierte Databricks-Prozeduren sind kein allgemeiner Sparkvertrag |
| T-SQL/Databricks ↔ PostgreSQL | Verbreitete relationale Alternative und gute Referenz für LATERAL | Eigene Funktionen, Typen, Identifier, NULL-Sortierung und prozedurale Sprache |
| T-SQL/Databricks ↔ DuckDB | Lokale Entwicklung und zusätzliche synthetische Gegenprobe | DuckDB-Test ersetzt keine SQL-Server-/Databricks-Qualifikation |
| T-SQL/Databricks ↔ Snowflake | Warehouse-Migration, Window-/QUALIFY-Profile | LATERAL-/Tabellenfunktionsregeln und Prozeduren zielabhängig prüfen; nicht von PostgreSQL ableiten |
| T-SQL/Databricks ↔ BigQuery | Weitere relevante analytische SQL-Plattform | GoogleSQL kennt andere Regeln für korrelierte FROM-Ausdrücke; je Fall Join/Window oder ARRAY-/UNNEST-Strategie prüfen |
| T-SQL/Databricks ↔ Trino | Föderierte analytische Abfragen | Connector-/Typ-/Funktionsfähigkeiten und korrelierte Formen separat prüfen |

Die Erweiterungseinordnung ist eine Empfehlung. Beispiele für die tatsächlich
unterschiedlichen Zielregeln liefern [PostgreSQL LATERAL](https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-LATERAL),
[Snowflake LATERAL](https://docs.snowflake.com/en/sql-reference/constructs/join-lateral)
und [BigQuery Query syntax](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax).
Für alle Profile müssen Engineversion und Compatibility-/Sessioneinstellungen
vor einer Zusage feststehen; kein pauschales Ziel `latest`.

## Quellen-Ziel-Matrix für Python und weitere Sprachen

Die Hinrichtung ist Codegenerierung aus einem geprüften relationalen Modell.
Die Rückrichtung benötigt einen ausdrücklich erlaubten API-/Sprachumfang;
sie darf unbekannten Code nicht zur Analyse ausführen.

| Quelle | Ziel | Machbarkeit / Priorität | Rückrichtung und Grenzen |
|---|---|---|---|
| T-SQL / Databricks / Spark SQL | Python mit `spark.sql(...)` | Gut machbare spätere Hülle um bereits übersetztes Spark-/Databricks-SQL | Statisch bekannte SQL-Literale und getrennte Parameter können wieder extrahiert werden. Keine DataFrame-Übersetzung; keine freie f-String-/String-Konkatenationsauswertung. |
| Geprüfter relationaler SQL-Kern | Python / PySpark DataFrame API | Sinnvoller erster echter Python-Generator: select, filter, join, groupBy, Window | Nur deklarative, bekannte API-Ketten rückführbar; UDFs, RDDs, I/O, Actions, Python-Schleifen und dynamische Metaprogrammierung ausgeschlossen. |
| Deklarative PySpark-API-Teilmenge | SQL der ausgewählten Zielengine | Über SQLFrame oder eigenen statischen API-Importer untersuchbar | API-Abdeckung und Zieldialekt separat qualifizieren. SQLFrame ist kein allgemeiner Python-zu-SQL-Compiler. |
| Ibis-Ausdrücke | T-SQL / Databricks / weitere Backends | Bestehende Python-Abstraktion als Alternative zu eigenem Frontend prüfen | Ibis-Backendfähigkeiten unterscheiden sich pro Operation. SQL → Ibis benötigt einen eigenen begrenzten Importer; keine automatische Umkehrung des Compilers. |
| Geprüfter relationaler SQL-Kern | Python / Polars LazyFrame | Sinnvoll für lokale analytische Verarbeitung; spätere Option | Lazy-Ausführung und Typ-/NULL-/Sortierregeln eigens abbilden. Keine Zusage, verteilte Workloads in lokalen Speicher zu übernehmen. |
| Geprüfter relationaler SQL-Kern | Python / pandas | Für begrenzte lokale Datenmengen möglich; nachrangig | pandas.merge kann NULL-Schlüssel miteinander matchen; SQL-Join-Semantik muss explizit nachgebildet werden. Auch nullable dtypes, Aggregation und Reihenfolge prüfen. |
| Geprüfter relationaler Kern | Scala / Java Spark DataFrame bzw. `Dataset<Row>` | Plausible spätere Generatoren auf derselben Sparkengine | Keine Übersetzung beliebiger Scala-/Java-Programme oder typisierter Benutzerklassen zugesagt. |
| Ausgewählte SQL-Abfrage | C# / Java / JavaScript mit SQL-Aufruf | Einfache zusätzliche Hosthülle technisch möglich | Ziel bleibt SQL; Verbindungs-, Parameter- und Ergebnisbinding sind eigene Adapter, keine Übersetzung in LINQ oder allgemeine Sprachlogik. |
| Beliebiges Python / Scala / Java / C# | Semantisch gleichwertiges SQL oder andere beliebige Sprache | Kein allgemeiner automatischer Vertrag sinnvoll zusagbar | Nur klar beschränkte Teilsprachen, manuelle Portierung oder geprüfte Vorschläge; externe Seiteneffekte und frei berechnete Kontrollflüsse nicht stillschweigend umdeuten. |

Primärquellen: [Spark SQL/DataFrames](https://spark.apache.org/docs/latest/sql-programming-guide.html)
beschreibt die gemeinsame Ausführungsengine; [PySpark DataFrame](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/dataframe.html)
die API. [SQLFrame](https://github.com/eakmanrq/sqlframe) bietet SQL-Erzeugung
aus seiner PySpark-artigen API, auch mit einer Standalone-Session.
Die [Ibis-Operationsmatrix](https://ibis-project.org/backends/support/matrix)
zeigt die unterschiedlichen Backendfähigkeiten. [Polars Lazy optimizations](https://docs.pola.rs/user-guide/lazy/optimizations/)
und die dokumentierte [pandas.merge-NULL-Abweichung](https://pandas.pydata.org/docs/reference/api/pandas.merge.html)
begründen getrennte Profile. Die vorgeschlagenen Importer und Generatoren
sind daraus abgeleitete Planung, keine vorhandene Toolbelt-Funktion.

## Funktionsumfang und semantische Hürden

| Konstrukt | Erste Einschätzung | Erforderliche Behandlung |
|---|---|---|
| SELECT, CTE, Filter, Joins, GROUP BY, Window | Guter Kernumfang | Namensbindung, Bag-Semantik einschließlich Duplikaten, Typen, NULL und Window Frames erhalten; Reihenfolge nur bei zugesichertem ORDER BY vergleichen |
| Identifier, Parameter, TOP/LIMIT | Häufig automatisierbar | Katalog-/Schema-Mapping ausdrücklich liefern; Parameter typisieren; TOP PERCENT/WITH TIES und fehlendes deterministisches ORDER BY nicht auf einfaches LIMIT reduzieren |
| Datum, String, Cast, Arithmetik | Regeln je Funktion/Typ | DATEDIFF zählt je nach Dialekt andere Grenzen/Einheiten; ISNULL/COALESCE können unterschiedliche Typregeln haben; Division, Decimal-Overflow, LEN/trailing spaces und implizite Konvertierung prüfen |
| Collation und Zeit | Kontextabhängig | Case/Accent/Trailing-Space-Vergleich, Zeitzone, DST und Timestamp-Präzision erhalten oder ablehnen. Eine verlustbehaftete Typabbildung ist keine exakte Konvertierung. |
| OUTER/CROSS APPLY, TVFs, korrelierte Top-N | Zentrale eigene Rewrite-Familie | LATERAL oder belegte Dekorrelation; siehe nächster Abschnitt. Funktionskörper/-vertrag muss verfügbar oder gemappt sein. |
| JSON, ARRAY/MAP/STRUCT, Generatorfunktionen | Getrennte spätere Profile | Relationale Darstellung oder explizit vereinbarte Kodierung; keine stillschweigende Stringifizierung. LATERAL VIEW/EXPLODE ist kein allgemeiner APPLY-Ersatz. |
| INSERT/UPDATE/DELETE/MERGE und DDL | Spätere eigene Verträge | Delta-/SQL-Server-Semantik, Mehrfachtreffer, Constraints, Identity/Sequence, OUTPUT/RETURNING, Trigger, Transaktionen und Wiederholung prüfen; im ersten Kern ablehnen |
| Funktionen, Prozeduren, SQL-Scripting | Teilweise möglich; eigene spätere Welle | Body, Parameter, Resultsets, Return-/Fehlercodes, SET-Zustände, Transaktionen, Temp-Scope und Security-Kontext einzeln abbilden |
| Cursor, dynamisches SQL, CLR, Systemkataloge, Agent/Hostzugriffe | Kein pauschaler automatischer Support | Erkennen und mit konkreter Quellstelle ablehnen; statisch bekannte dynamische Teilabfrage allenfalls als eigener Vertrag |
| NOLOCK, Lock-/Optimizerhints, Isolation | Semantische oder physische Differenz | Nicht blind entfernen oder kopieren. Isolation als mögliche Bedeutungsänderung blockieren; rein physische Hints über ausdrückliche Regel dokumentiert behandeln. |

[Databricks CREATE PROCEDURE](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-ddl-create-procedure)
ist für Databricks SQL beziehungsweise Databricks Runtime ab 17.0 und nur in
Unity Catalog dokumentiert. Daher sind Routinen kein grundsätzlich unmögliches
Ziel. Das erlaubt aber keine 1:1-Übertragung von T-SQL-Prozeduren.
[SQL scripting](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-scripting)
verwendet ein eigenes prozedurales Modell. Umgekehrt sind dessen Handler und
Aufrufverträge nicht automatisch T-SQL TRY/CATCH/EXEC. SQL-Server-2019-Ziele
dürfen keine nur 2022/2025 vorhandenen Funktionen erhalten.

## OUTER APPLY korrekt während der Konvertierung behandeln

Mit „on the fly“ ist hier die automatische Umschreibung beim
Konvertierungsaufruf gemeint: SQL-Text hinein, Zieltext und Transformationsbericht
heraus. Keine Abfrageausführung, kein produktiver SQL-Proxy und keine
automatische Ersetzung laufender Statements.

### Direkte Abbildung über LATERAL

Nach [Microsofts APPLY-Vertrag](https://learn.microsoft.com/en-us/sql/t-sql/queries/from-transact-sql?view=sql-server-ver17)
ist die rechte Relation von der linken Zeile abhängig. OUTER APPLY erhält
eine linke Zeile auch bei leerem rechten Ergebnis. Folgende semantische
Abbildung ist deshalb ein sinnvoller Regelentwurf:

| T-SQL | Databricks-/Spark-Profil mit passender Capability | Rückrichtung |
|---|---|---|
| `OUTER APPLY (Q) AS r` | `LEFT JOIN LATERAL (Q') AS r ON TRUE` | Für diese Form zurück zu `OUTER APPLY (Q) AS r`; Q' rekursiv übersetzen |
| `CROSS APPLY (Q) AS r` | `CROSS JOIN LATERAL (Q') AS r` | Für diese Form zurück zu CROSS APPLY |
| LATERAL mit zusätzlicher ON-Bedingung | Zuerst Wirkung der Bedingung analysieren | In das rechte Teilresultat integrieren, sofern äquivalent, andernfalls keine direkte APPLY-Regel |

Databricks dokumentiert [LATERAL-Tabellenreferenzen](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-qry-select-table-reference)
und [laterale LEFT JOINs](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-qry-select-join).
Apache Spark dokumentiert [LATERAL SUBQUERY](https://spark.apache.org/docs/latest/sql-ref-syntax-qry-select-lateral-subquery.html).
Diese Syntaxbelege qualifizieren noch nicht jede korrelierte Top-N-, TVF-
oder Aggregatform. Insbesondere dokumentiert Databricks
[Einschränkungen für korrelierte/nichtdeterministische Unterabfragen](https://docs.databricks.com/aws/en/error-messages/unsupported-subquery-expression-category-error-class).
Je exaktem Zielprofil muss die Regel akzeptieren, anders umschreiben oder
eine begründete Ablehnung liefern.

### Synthetischer Top-1-Fall und mengenorientierte Alternative

Annahmen: `EventId` ist eindeutig; `EventTime` hat in beiden Engines dieselbe
vereinbarte Zeitsemantik. Die einzige Korrelation ist Gleichheit über
`ParentId`; weitere Filter wären ausschließlich rechte, deterministische
Filter und müssten vor dem Ranking stehen. Alle Tabellennamen sind synthetisch;
die Abbildung von `dbo` auf das Zielnamespace muss ausdrücklich vorliegen.

T-SQL-Eingabe:

```sql
-- Pro Parent die jüngste Eventzeile; der eindeutige zweite Sortierschlüssel
-- definiert bei gleicher Zeit die Auswahl. Parents ohne Treffer bleiben erhalten.
SELECT p.ParentId, e.EventId, e.EventTime
FROM dbo.Parent AS p
OUTER APPLY
(
    SELECT TOP (1) x.EventId, x.EventTime
    FROM dbo.Event AS x
    WHERE x.ParentId = p.ParentId
    ORDER BY x.EventTime DESC, x.EventId DESC
) AS e;
```

Direkter Zielentwurf, **nur bei qualifizierter korrelierter LIMIT-Capability**:

```sql
-- Die Abhängigkeit bleibt lateral. Ob genau diese ORDER-BY-/LIMIT-Form
-- unterstützt und geeignet geplant wird, ist auf dem gewählten Ziel zu prüfen.
SELECT p.ParentId, e.EventId, e.EventTime
FROM Parent AS p
LEFT JOIN LATERAL
(
    SELECT x.EventId, x.EventTime
    FROM Event AS x
    WHERE x.ParentId = p.ParentId
    ORDER BY x.EventTime DESC NULLS LAST, x.EventId DESC
    LIMIT 1
) AS e ON TRUE;
```

Alternativer Databricks-/Spark-Entwurf ohne korreliertes LIMIT:

```sql
-- Weil die rechte Auswahl ausschließlich vom Gleichheitsschlüssel abhängt,
-- kann sie einmal je ParentId bestimmt werden. rn bleibt im ON-Prädikat,
-- damit Parents ohne Treffer weiterhin eine NULL-erweiterte Zeile liefern.
WITH RankedEvent AS
(
    SELECT x.ParentId, x.EventId, x.EventTime,
           ROW_NUMBER() OVER
           (
               PARTITION BY x.ParentId
               ORDER BY x.EventTime DESC NULLS LAST, x.EventId DESC
           ) AS rn
    FROM Event AS x
)
SELECT p.ParentId, e.EventId, e.EventTime
FROM Parent AS p
LEFT JOIN RankedEvent AS e
  ON e.ParentId = p.ParentId
 AND e.rn = 1;
```

Diese Dekorrelation ist **kein allgemeiner APPLY-Algorithmus**. Hängt die
Auswahl zusätzlich etwa von `p.CutoffTime` ab, reicht Partitionierung allein
nach `ParentId` nicht. Dann braucht es das vollständige Korrelationsmodell,
gegebenenfalls eine belegte stabile linke Zeilenidentität und ein anderes
Ranking oder LATERAL. Fehlt die nötige Bindung, wird die Regel abgelehnt.
Linke Duplikate dürfen weder zusammenfallen noch zusätzliche Treffer erzeugen.

Weitere Pflichtfälle: keine/eine/viele rechte Zeilen; NULL-Schlüssel;
mehrspaltige Korrelation; TOP N/WITH TIES; vollständige Sortierbindung;
Nichtgleichheit; verkettete APPLYs; TVF-/EXPLODE-Semantik; nondeterministische
Ausdrücke; Aggregationen ohne GROUP BY. Insbesondere liefert ein skalares
`COUNT(*)` über einer leeren rechten Eingabe eine Ergebniszeile mit Zählwert 0,
nicht dasselbe wie ein LEFT JOIN auf eine leere gruppierte Relation.
Reparaturen mit COALESCE sind nur bei bewiesener Aggregate-Semantik zulässig.

Für die Rückrichtung wird auch ein generisches LATERAL-ON-Prädikat nicht
entfernt. Der Window-Entwurf kann nach T-SQL ausgegeben werden, ohne künstlich
APPLY zurückzuerzeugen. Erhalten werden Ergebnisse und vereinbarte Metadaten,
nicht zwingend die ursprüngliche Schreibweise.

## Architektur und mögliche Bausteine

| Baustein | Recherchierter Nutzen | Entscheidung / Grenze |
|---|---|---|
| [SQLGlot](https://github.com/tobymao/sqlglot) | Python-Parser, AST, Generatoren; explizite Quell-/Zieldialekte; MIT | Bevorzugter Spike-Kandidat für beide SQL-Richtungen. Unsupported Errors auf RAISE/IMMEDIATE; kein stilles Best-Effort. Schemaabhängige Regeln brauchen zusätzliche Bindung. |
| [SQLGlot Command fallback](https://github.com/tobymao/sqlglot/blob/main/posts/onboarding.md#command-fallback) | Unbekannter Text kann als Command unverändert erhalten bleiben | Solche Knoten zusätzlich erkennen und blockieren; ein erfolgreicher Generatoraufruf ist kein vollständiger Übersetzungsnachweis. |
| [Lakebridge Werkzeugvergleich](https://databrickslabs.github.io/lakebridge/docs/choosing_tools/) | Morpheus: AST/IR-basierte Migration unter anderem von MSSQL zu Databricks; weitere Provider für breitere Formate | Vergleichs-/Alternativkandidat für die Hinrichtung. Keine dokumentierte allgemeine Databricks→T-SQL-Rückrichtung daraus ableiten. Switch ist experimentell und LLM-basiert. |
| [Lakebridge Konfiguration](https://databrickslabs.github.io/lakebridge/docs/transpile/pluggable_transpilers/bladebridge/bladebridge_configuration/) | Unterscheidet SQL-, SparkSQL- und PySpark-Ausgabe je Source-Typ | Bei BladeBridge liefern SQL-Source-Dialekte Databricks SQL; PySpark ist kein pauschales MSSQL-Ausgabeziel. |
| [Lakebridge Installation](https://databrickslabs.github.io/lakebridge/docs/installation/) | Dokumentiert Workspace-/CLI-/Provider-Voraussetzungen | Kein Ersatz für einen zugesagten vollständig lokalen Offlinekern. Provider, Runtime und Nutzungsbedingungen getrennt prüfen. Keine Installation im Research-Auftrag. |
| [Microsoft ScriptDOM](https://github.com/microsoft/SqlScriptDOM) | Offizieller T-SQL-AST; MIT; vorhandene Projektintegration | Optionaler zusätzlicher T-SQL-Parser/Prüfer oder eigenes Frontend; keine Spark-/Databricks-Grammatik. Kein unnötiger Doppelparser bei jeder Anfrage. |
| [SQLFrame](https://github.com/eakmanrq/sqlframe) / [Ibis](https://ibis-project.org/backends/support/matrix) | Vorhandene Python-API→SQL-/Backend-Abstraktionen | Für Python-Teilverträge separat vergleichen; SQLFrame nennt MIT. Ibis-Lizenz und transitive Pakete vor Aufnahme prüfen. Kein allgemeiner Python-Importer. |

Lizenzangaben sind Researchbefunde, keine Freigabe zur Dependency-Aufnahme.
In der ursprünglichen Planungsrecherche wurde kein Drittanbietercode oder
Sample übernommen und kein Paket installiert; der spätere isolierte SQLGlot-Spike ist im verlinkten Bericht
eigens dokumentiert. Exakte Versionen, Artefakte, Lizenz-/NOTICE-Pflichten,
Sicherheitsadvisories und Exit-Strategie sind vor einem Spike mit Dependency
gemäß [Drittanbieterrichtlinie](../Standards/THIRD_PARTY_AND_SOURCE_POLICY.md)
zu prüfen. Bei Lakebridge zusätzlich jeden gewählten Provider beurteilen.
Die heute gelesenen beweglichen Dokumentationen werden vor Qualifikation an
ausgewählte Releaseversionen gebunden.

Geplanter Ablauf:

1. Quelle, Ziel, Engineversion, Compatibility Level/ANSI-Modus, Zeitzone,
   Collation, erlaubte Features und übergebene Schema-/Funktionsmetadaten prüfen.
2. Gesamte Eingabe parsen; Batches, Scopes und Parameter explizit modellieren.
   Unbekannte Nodes, ungelöste Namen und unsichere Typabbildungen melden.
3. Unterstützte AST-Knoten in einen kleinen relationalen Kern überführen:
   Project, Filter, Join, Aggregate, Window, Sort, Limit und laterale Abhängigkeit.
   Typen, Nullability, Duplikate, Ordnung und Quellspannen daran binden.
4. Zuerst semantisch notwendige Rewrites; danach getrennte, begründete
   Optimierungen. Jede Regel nennt Voraussetzungen und mögliche Auswirkungen.
5. SQL oder API-spezifischen Code generieren; Zielsyntax erneut prüfen und
   den vollständigen Feature-/Transformationsbericht zurückgeben.
6. Engineprüfung und Ausführung ausschließlich in einem getrennten Testpfad
   mit synthetischen Daten; nie implizit beim Konvertieren.

Ein späterer Schnittstellenentwurf könnte Text, Quell-/Zielprofile, Parameter
und optionale Schemametadaten entgegennehmen. Ergebnis: Code, Quellpositionen,
angewandte Regeln, Annahmen, blockierende Gründe und getrennte Aussagen zu
Syntax, Semantikprüfung und Performanceprüfung. Vorläufige Zustände wären
`converted`, `requires context`, `unsupported` und `validation pending`;
die endgültige API wird erst besprochen. Bei einem blockierten Statement
keine ausführbare scheinbar vollständige Teilkonvertierung ausgeben.

## Performance als Erzeugerziel und messbare Eigenschaft

Semantische Korrektheit hat Vorrang. Ein zeilenweises SQL-Server-Seek über
APPLY kann für wenige linke Zeilen gut passen; ein vollständiges Window-Ranking
kann viele Daten lesen/sortieren. Umgekehrt kann ein verteiltes mengenorientiertes
Ranking wiederholte Arbeit vermeiden. **Keine Form ist pauschal schneller.**
Das sind zu prüfende Hypothesen, keine Benchmarkergebnisse.

| Ziel | Geplante Regeln und Gegenproben |
|---|---|
| SQL Server | SARGability, keine unnötigen Spaltencasts, set-basierte Verarbeitung und echte Inline-TVF-Komposition bevorzugen; APPLY/Seek gegen Join/Window nach Selektivität und Datenverteilung vergleichen; Parametereinfluss und Compilekosten erfassen |
| Databricks / Spark | Native SQL-/DataFrame-Ausdrücke bevorzugen; Python-UDFs, collect/toPandas und Zeilenschleifen nicht automatisch einführen; Projektion/Filter möglichst früh, sofern Semantik erhalten bleibt; Shuffle, Skew und Scanvolumen untersuchen |
| Wiederverwendete Teilergebnisse | CTE ist keine zugesicherte Materialisierung. Cache/Temp-Tabelle nur mit eigenem Lebenszyklus, Größenannahmen und belegtem Nutzen; kein automatisches Cache-/Serverkonfigurations-Tuning |
| Joinstrategie | Keine ungeprüften BROADCAST-, Repartitionierungs- oder SQL-Server-Indexhints. Statistiken und Optimizer nutzen; optionale Zielhinweise nur bei explizitem Profil und Nachweis |
| Routinen | Mengenorientierter Kern vor generierten Schleifen; Ausführungshäufigkeit, Transaktionsgrenzen, Parameter, Zwischenmaterialisierung und UDF-Grenzen als eigener Routinevertrag |
| Übersetzer selbst | Parse-, Bindungs-, Rewrite- und Generierkosten separat messen; Input-/AST-/Zeit-/Outputgrenzen definieren. Cache nur an Code, Metadaten, Dialekt-/Engineprofile und Regel-/Providerversion binden; keine stille Wiederverwendung nach Kontextänderung |

[Sparks Performance-Dokumentation](https://spark.apache.org/docs/latest/sql-performance-tuning.html)
beschreibt Statistiken, Joinstrategien und AQE; Hints garantieren die gewählte
Strategie nicht. [Spark SQL/DataFrames](https://spark.apache.org/docs/latest/sql-programming-guide.html)
nutzen dieselbe Engine: Python-API-Ausgabe ist für sich kein Geschwindigkeitsgewinn.

Geplante Messung: Quellreferenz, semantisch korrekte direkte Zielübersetzung
und optionale Zielalternative auf identischen synthetischen Daten vergleichen.
Zielvarianten innerhalb derselben stabilen Engineumgebung bewerten, inklusive
Warm-up, wiederholten Messungen, Selektivität, Skew und kleinem/großem Workload.
Übersetzungszeit, Compilezeit und Ausführung getrennt ausweisen; je Engine
relevante Ressourcen wie Reads, Scan-/Shufflevolumen und Spill erfassen.
Keine plattformübergreifende Beschleunigung aus einem Einzellauf behaupten.
Reale Pläne, Runnerwerte und Runtimeausgaben bleiben lokal unversioniert;
Repository-Evidenz enthält nur zulässigen Scope, Verfahren und Ergebnisstatus.

## Geplante Wellen und Akzeptanzkriterien

Die folgenden Wellen sind ein Vorschlag ohne aktive Arbeitspakete. Kein
Zeitschätzwert oder Abdeckungsprozentsatz ist derzeit belastbar.

| Welle | Inhalt | Abnahme / Ergebnis |
|---|---|---|
| Abgrenzung und Providervergleich | Exakte Quell-/Zielprofile, synthetischer Featurekorpus, SQLGlot gegen Morpheus für die Hinrichtung, Hosting-/Lizenzentscheidung | Je Richtung explizite Positiv-/Negativliste; Dependencyprüfung; besprochener erster Funktionsvertrag. Erst danach Implementierung gesondert freigeben. |
| SQL-Kern in beiden Richtungen | Einzeln freigegebene lesende SELECT-/CTE-/Join-/Window-/Funktionsprofile, korrekte Parameter-/Namespaceabbildung | Zielparser und native Binder akzeptieren jeden Positivfall; Ergebnisse/Metadaten auf beiden Engines gleich; unbekannte Fälle sicher abgelehnt |
| APPLY und korrelierte Auswahl | Direkte laterale Formen, begrenzte Top-N-/Window-Dekorrelation, Aggregate und Ketten | Leere rechte Seite, Duplikate, NULL, Ties, Zusatzkorrelation und Nichtdeterminismus mit festen Orakeln in beiden Richtungen; Performancealternativen separat bewerten |
| Spark und erste Zusatzdialekte | Spark SQL, danach PostgreSQL/DuckDB nach Bedarf | Dieselben Regeltests je tatsächlich gewählter Kante; Databricks-Erweiterungen in Spark klar ablehnen; kein transitiver Supportbeweis |
| Python und weitere Generatoren | Zuerst SQL-Hülle/PySpark, danach bei Bedarf SQLFrame-/Ibis-Import und Polars/pandas oder Scala/Java | API-Allowlist, sichere statische Verarbeitung, Typ-/NULL-/Bag-Parität, keine unbeabsichtigten Actions oder Datentransfers |
| Routinen und schreibende Profile | Einzeln freigegebene UDF-/Prozedur-/DML-/DDL-Teilverträge | Zusätzlich Fehler-, Resultset-, Transaktions-, Rechte-, Wiederholungs- und Lifecycleparität; Persistenz/Ausführung separat autorisieren |

Pflicht für eine spätere Qualifikation:

- Beide Kernrichtungen unabhängig testen; SQL-Server-Ziele 2019/CL150,
  2022/CL160 und 2025/CL170 sowie explizite Databricks-/Spark-Profile nach
  tatsächlichen abweichenden Fähigkeiten auswählen.
- Tabellen- und Ergebnisvergleiche erhalten Zeilenmultiplizität, NULL, Typen,
  Precision/Scale, vereinbarte Collation und Fehler. Reihenfolge nur dort,
  wo der Vertrag sie definiert. Floattoleranzen ausschließlich ausdrücklich;
  keine pauschale Toleranz für Geld, Decimal oder Zeitpräzision.
- Feste Gegenbeispiele für Aliasschatten, Kommentare/Literale, tiefes/großes SQL,
  CTEs, korrelierte Subqueries, Typgrenzen, Überlauf, DST und Randwerte.
- Roundtrip-Prüfungen als Zusatz nutzen; native Differentialtests und feste
  semantische Orakel bleiben maßgeblich. Gleichlautender zurückerzeugter SQL-Text
  ist kein Ergebnisnachweis.
- Unsupported-/Command-Fallback, verlorene Klauseln und Versionsdrift negativ
  testen; keine stillen Löschungen. Ein Bericht allein macht SQL nicht sicher.
- SQL-Server-Tests über den schema-validierten ausgewählten Labvertrag;
  Databricks-Ziel und Zugang sind separat bereitzustellen. Lokales Spark oder
  DuckDB ersetzt kein Databricks SQL Warehouse. Keine Lab-/Cloudressourcen
  selbst provisionieren oder konfigurieren.

## Offene Entscheidungen vor einer Implementierung

1. Zuerst ausschließlich lesende Abfragen mit T-SQL ↔ Databricks SQL und
   welcher genaue Featureumfang einschließlich APPLY? Konkrete Engineprofile
   und synthetische Beispielsammlung auswählen.
2. Externes lokales Werkzeug als erster Host oder zusätzlich eine einzeln
   zu besprechende SQL-Fassade? Packaging und Projektgrenze verbindlich klären.
3. Welche Schema-, Funktions-, Collation-, Zeitzonen- und Parameterinformationen
   muss der Aufrufer liefern? Bei fehlender Evidenz Kontext anfordern oder
   ablehnen; kein Erraten.
4. Welche erste echte Python-API: empfohlen PySpark DataFrame; Ibis/SQLFrame
   als Alternativen vergleichen. Zusätzliche Sprachen nur nach Nutzungsbedarf.
5. Welche Transformationsregeln und Leistungsbudgets sind verbindlich?
   Optimierungsmodus getrennt von bloßer semantischer Übertragung definieren.
6. Sichere finale Referenzvergabe gemäß
   [DEC-2026-028](../Architecture/DECISIONS.md#dec-2026-028-foundation-14-und-bestandsschutz-für-projektidentitäten)
   lösen; bis dahin die [benannte Vormerkung](../../Backlog/TOOLBELT_CANDIDATES.md#sql-dialekt-transformation--vormerkung-ohne-finale-tc-referenz)
   verwenden. Keine neue TC-/AP-Sequenz erraten.

Es entstehen weder eine automatische Datenmigration noch eine Ausführungs-,
Installations- oder Infrastrukturfreigabe. Übergebener Quelltext kann vertraulich
sein: Verarbeitung standardmäßig lokal, keine Rohtextprotokollierung oder
Übermittlung an LLM-/Cloudanbieter. Die vorliegende Recherche verwendet nur
öffentliche Primärquellen und synthetische Beispiele; keine realen SQL-Skripte,
Schemaauszüge, Zugangsdaten oder Laufzeitdaten wurden aufgenommen.
