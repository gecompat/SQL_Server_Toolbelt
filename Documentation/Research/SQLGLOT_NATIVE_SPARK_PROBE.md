# Native Spark-SQL-Prüfung ohne Databricks-Zugang

Stand: 2026-10-17 · Autor: Codex · Status: **57 positive Fälle und neun
Negativfälle auf Apache Spark 4.0.2 bestanden**. Native Databricks-Abnahme
bleibt **`not executed`**. Die ergänzende
[Performance-/Planprüfung](SQL_DIALECT_PERFORMANCE_PROBE.md) ist getrennt
`partially validated`. Die V1 bleibt `researched`.

## Lösung und Nachweisgrenze

Auf den Benutzerauftrag, selbst einen Testweg zu finden, wurde Apache Spark
lokal im Prozessmodus `local[2]` ausgeführt. Dazu sind weder Cloud-Account
noch SQL-Warehouse, Container oder Labänderungen erforderlich. Portable
Testdependencies liegen ausschließlich unter dem ignorierten `.runtime/`;
es wurden keine Systeminstallation, Dienste oder globalen Einstellungen geändert.

Die [Spark-Dokumentation](https://spark.apache.org/docs/4.0.2/index.html)
beschreibt die lokale Ausführung unter Windows und Java 17/21. Verwendet wurden
Apache Spark/PySpark 4.0.2, Py4J 0.10.9.9, portable Temurin JRE 21.0.12.1+1
und der vorhandene Python-3.14.7-/SQLGlot-30.23.0-Interpreter. Der Runner legt
ANSI-Modus, UTC, TIMESTAMP_NTZ und case-sensitive Namen ausdrücklich fest.
UI und Eventlog sind aus; der lokale Treiber bindet an Loopback. Es wird kein
Standalone-, Connect- oder entfernter Spark-Cluster gestartet.

Das ist tatsächliche Engineausführung mit Parser, Analyzer, Optimizer und
Resultsetabholung. Sie ersetzt den SQLGlot-Reparse als einzigen Nachweis für
dieses Spark-Profil. Sie qualifiziert jedoch kein Databricks-Profil:
[Databricks Runtime 17.3 LTS basiert auf Spark 4.0.0](https://docs.databricks.com/aws/en/release-notes/runtime/17.3lts),
enthält aber zusätzliche Herstelleränderungen; auch die Patchversion ist hier
abweichend. SQL-Warehouse, Runtime, Photon und Databricks-REST-/Treiberbinding
bleiben eigenständige Abnahmen.

Ein echter Databricks-Weg ist die
[Free Edition mit persönlicher Anmeldung](https://docs.databricks.com/aws/en/getting-started/free-edition).
Ihre [Nutzungs- und Funktionsgrenzen](https://docs.databricks.com/aws/en/getting-started/free-edition-limitations)
gelten zusätzlich, insbesondere die Beschränkung auf nichtkommerzielle Nutzung.
Dieser Weg wurde recherchiert, aber kein Account oder Workspace angelegt.

## Ausgeführter Korpus und SQL-Server-Vergleich

[`run_native_spark.py`](../../Tests/Research/SqlDialect/run_native_spark.py)
verwendet dieselben 57 vorbereiteten SELECTs aus
[`run_native_databricks.py`](../../Tests/Research/SqlDialect/run_native_databricks.py):
33 Quellabfragen der Rückrichtung und 24 Zwischenabfragen der Hinrichtung.
Diese sind allen 81 bereits nativ geprüften T-SQL-Fällen zugeordnet; die
Zwischenabfragen der Original-/Roundtrip-Paare werden einmal ausgeführt.
Der erzeugte SELECT-Text bleibt unverändert, einschließlich LATERAL, LIMIT,
Ergebniscasts und benannter Parameter. Es wird keine andere SQL-Übersetzung
als Ersatz für einen fehlgeschlagenen Fall verwendet.

Die sechs Parent- und sieben Event-Zeilen sowie Leer-, NULL-, Cutoff-,
Gleichstands- und Parameterprofile stammen unverändert aus dem bestehenden
synthetischen Korpus. CTEs/VALUES legen keine persistenten Objekte an.
Die Erwartungen sind weiterhin die unabhängigen handgeschriebenen
Python-Relationen. Ohne äußeres ORDER BY wird eine Multimenge einschließlich
Duplikaten und NULL verglichen; der globale Top-3 hat ein Reihenfolgeorakel.

Vor der Ausführung prüft der Runner den lokalen SQL-Server-Bericht auf
unveränderte Quellen, SQLGlot-Pin, Lab-Helfer, sechs vollständige Zielgruppen,
sämtliche 486 Fallstatus, erwartete Clienttypfelder und Ergebnisorakel.
Nach dem Lauf werden Quellen- und Berichtsbindungen erneut geprüft. Der
frühere [SQL-Server-Lauf](SQLGLOT_NATIVE_TSQL_LAB_PROBE.md) wurde nicht wiederholt;
der neue Vergleich bezieht sich auf dessen unverändert gebundene Ergebnisse.

| Gegenstand | Auf Spark 4.0.2 tatsächlich bestätigt |
|---|---|
| LEFT JOIN LATERAL / CROSS JOIN LATERAL | 11 bzw. 9 Zeilen; Duplikate bleiben erhalten; NULL-Schlüssel treffen nicht aufeinander |
| Leere und fehlende rechte Treffer | OUTER erhält linke Zeilen mit rechter NULL-Erweiterung; CROSS entfernt sie; leere Gesamtmenge bleibt leer |
| Korrelierter Top-1 | LIMIT 1, absteigende EventId, Floor 102, NULL und 999 entsprechen dem SQL-Server-Orakel |
| Cutoff und Gleichstand | Gleiche ParentId mit verschiedenen Cutoffs liefert 101 bzw. 103; NULL-Cutoff und fehlender Treffer liefern rechts NULL |
| Globaler Top-3 | Geordnete Folge 401, 301, 202 |
| COUNT(*) | Sieben Events ergeben 7; leere Eingabe ergibt eine Zeile mit 0 |
| COUNT(ParentId) | 6 wegen eines NULL-Schlüssels; leere Eingabe 0 |
| COUNT(Parameter) | Wert 7 ergibt 7; NULL ergibt 0; auch leere Eingabe ergibt 0 |
| ROW_NUMBER | Drei Nicht-NULL-Ränge 1, 2, 3; auch über dem Fixture mit NULL-Sortierschlüssel; leer keine Zeile |
| Parameter | Wiederverwendete Marker, unveränderte Markertexte im Stringliteral, NULL und INT-Randwerte stimmen überein |
| Typen | INT/BIGINT/SMALLINT/TINYINT, DECIMAL(12,2), typisiertes NULL, DATE und TIMESTAMP_NTZ entsprechen den jeweiligen Fallverträgen |

**Ergebnis:** 57/57 positive Fälle bestanden. Für jeden Fall stimmen Werte
beziehungsweise Multimenge oder Reihenfolge mit dem Orakel und allen sechs
SQL-Server-Zielen überein. Abweichende physische Typen werden nach dem
vereinbarten Mapping geprüft; eine pauschale Metadatenidentität wird nicht behauptet.

## Clienttypen und NULL-Metadaten

| Ausdruck/Vertrag | Spark-SQL-Typ | PySpark-Werttyp | SQL-Server-Gegenstück |
|---|---|---|---|
| Quell-COUNT der Rückrichtung | BIGINT | int | COUNT_BIG, BIGINT / System.Int64 |
| Aus T-SQL erzeugter COUNT-Ergebniscaste | INT | int | Original und Roundtrip INT / System.Int32 |
| Quell-ROW_NUMBER der Rückrichtung | INT | int | Ergebniscast nach INT / System.Int32 |
| Aus T-SQL erzeugter ROW_NUMBER-Ergebniscaste | BIGINT | int | Original und Roundtrip BIGINT / System.Int64 |
| DECIMAL(12,2) | DECIMAL(12,2) | Decimal | DECIMAL(12,2) / System.Decimal |
| DATE | DATE | date | DATE / System.DateTime |
| Zeitwert mit sechs Nachkommastellen | TIMESTAMP_NTZ | datetime ohne Zeitzone | DATETIME2(6) / System.DateTime |

Python-int unterscheidet keine feste 32-/64-Bit-Clientbreite; diese wird aus
dem tatsächlichen Spark-Schema geprüft. COUNT und ROW_NUMBER einschließlich
der geprüften Ergebniscasts melden in Spark `nullable=false`; SQLClient
meldet bei ihren T-SQL-Gegenstücken AllowDBNull=True. Die tatsächlichen
COUNT-/Rankingwerte sind auf beiden Engines nicht NULL. Metadaten-Nullability
ist deshalb ausdrücklich von tatsächlicher NULL-Parität getrennt.

Spark-TINYINT ist signiert: -128 und 127 bleiben auf Spark TINYINT, das
T-SQL-Ziel ist SMALLINT. T-SQL-TINYINT 0 und 255 wird auf Spark SMALLINT;
der bereits geprüfte T-SQL-Roundtrip bleibt SMALLINT. DATETIME2(3) wird als
TIMESTAMP_NTZ mit demselben Wert geprüft; sein T-SQL-Rücktyp DATETIME2(6)
ist weiterhin eine ausdrücklich dokumentierte physische Abweichung.

## Parameter-API und behobener Harnessfehler

Die [SparkSession.sql-API](https://spark.apache.org/docs/4.0.2/api/python/reference/pyspark.sql/api/pyspark.sql.SparkSession.sql.html)
bindet Parameter über `args`. Der erste native Lauf band
`lit(value).cast('int')` als Argument. Spark wies diese Castausdrücke mit
`INVALID_SQL_ARG`, SQLSTATE 42K08, ab: 37 Fälle bestanden, 20 Parameterfälle
scheiterten. Das war ein Harnessfehler, keine LATERAL-/Konvertierungsgrenze.

Der korrigierte Runner bindet Python-Literale über `args`, ohne SQL-
Interpolation oder Änderung des SELECT-Texts. Nicht-NULL-Integer werden vorab
auf die deklarierte INT-Domäne geprüft. `None` wird vom API als untypisiertes
NULL gebunden. Die NULL-/COUNT-/Castfälle bestehen damit; ein ausdrücklich
typisiertes NULL am REST-/SQLClient-Parameter ist dadurch nicht qualifiziert.
Der abschließende vollständige Lauf bestand mit 57 positiven und neun negativen
Fällen. Quellen, Regeln und Ergebnisorakel wurden nicht gelockert.

## Native Negativfälle

| Eingabe | Erwartete und tatsächlich gelieferte Spark-Kategorie |
|---|---|
| T-SQL TOP(1), LIMIT PERCENT, LIMIT WITH TIES | Je PARSE_SYNTAX_ERROR / 42601 |
| TINYINT 128 und -129, INT 2147483648 | Je CAST_OVERFLOW / 22003 |
| DECIMAL(3,0) mit 1000 | NUMERIC_VALUE_OUT_OF_RANGE.WITH_SUGGESTION / 22003 |
| Datum 2026-02-30 | CAST_INVALID_INPUT / 22018 |
| Ungebundener :Missing-Parameter | UNBOUND_SQL_PARAMETER / 42P02 |

Alle neun Ablehnungen wurden nach konkreter Fehlerkategorie geprüft. Eine
beliebige Exception zählt nicht als erfolgreicher Negativfall. Diese Kontrollen
belegen das Fehlerverhalten dieses Spark-/ANSI-Profils, keinen Databricks-
Fehlervertrag und keine Freigabe der im Regelspike ausgeschlossenen Eingaben.

## Reproduktion, Dependencies und Grenzen

Unter Windows x64, Python ab 3.12 und der vorhandenen SQLGlot-Testumgebung:

```powershell
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/prepare_local_spark.py
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/run_native_spark.py --sql-server-report .runtime/sqlglot-spike-30.23.0/native-roundtrip-report-2026-10-17.json --output .runtime/spark-sql-spike-4.0.2/native-final-report-2026-10-17.json
```

Beide Befehle wurden am 2026-10-17 erfolgreich ausgeführt; der native Runner
endete mit Exit 0. Die Quellen und Paketversionen sind im lokalen Bericht
gebunden. Setup und Runner verwenden exakte Download-URLs und SHA256-Pins
für PySpark-Sdist, Py4J-Wheel und portable Java-ZIP. Die PyPI- und offiziellen
Temurin-Release-Metadaten wurden vor Download geprüft. Distributionen werden
nur unter `.runtime/` entpackt, einschließlich ihrer Lizenz-/Notice-Dateien;
keine fremden Quellen oder Binaries werden ins Repository übernommen.

Spark steht unter [Apache-2.0](https://github.com/apache/spark/blob/v4.0.2/LICENSE),
Py4J unter [BSD](https://github.com/py4j/py4j/blob/0.10.9.9/LICENSE.txt),
Temurin unter [GPLv2 mit Classpath Exception](https://adoptium.net/docs/faq/#is-eclipse-temurin-free-to-use).
Die Installation ist eine isolierte Testdependency, keine zusätzliche
Toolbelt-Runtime- oder Distributionsabhängigkeit. Eine spätere Auslieferung
benötigt ihre eigene Lizenz-/Notice- und Dependencyprüfung. Die exakte
OSV-Abfrage für PySpark 4.0.2 und Py4J 0.10.9.9 lieferte am 2026-10-17 keine
Advisory-IDs; das ist keine vollständige Prüfung aller enthaltenen JARs oder
eine allgemeine Sicherheitsgarantie. Die
[Spark-Sicherheitsinformationen](https://spark.apache.org/security.html)
wurden zusätzlich geprüft.

Verbleibende Grenzen:

- Native Databricks-Tests bleiben offen; dieser Lauf ist ein eigener
  Spark-Nachweis. Kein versteckter Providerfallback im Databricks-Runner.
- Das Schema-/Aliasbinding bleibt der begrenzte Researchvertrag; deklarierte
  Gruppen-/Partitionsgrenzen und eindeutige Sortierung werden nicht allgemein
  aus realen Schemas bewiesen. Milliardenmengen und Rankingüberlauf sind offen.
- Die ROW_NUMBER-Fälle projizieren nur den Rang. Sie belegen die Rangwerte
  und Breiten, aber keine zusätzliche Zuordnung von Rang zu ParentId im Resultset.
- Typisiertes NULL-Parameterbinding sowie REST-/JDBC-/ODBC-Clientmetadaten
  sind eigene Nachweise; die Spark-Nullability ersetzt deren Vertrag nicht.
- Keine Delta-, Dateisystem-, HDFS-, Python-UDF-, Unicode-/Collation- oder
  Databricks-spezifischen Funktionen getestet. Native Hadoop-Bibliotheken
  beziehungsweise winutils wurden für die reinen VALUES-SELECTs nicht benötigt.
- Dieser funktionale Korpus enthält keinen Performancebenchmark. Die
  [nachfolgende Performancewelle](SQL_DIALECT_PERFORMANCE_PROBE.md) mit größeren
  synthetischen Mengen ist teilweise qualifiziert. Photon bleibt offen;
  kein allgemeines Leistungsversprechen aus den kleinen Funktionsfixtures.
