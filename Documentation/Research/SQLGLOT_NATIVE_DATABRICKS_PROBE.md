# Nativer Databricks-Vergleich des SQLGlot-Regelspikes

Stand: 2026-10-17 · Autor: Codex · Status: **`not executed`**.
Der Benutzer hat die native Databricks-Prüfung ausdrücklich beauftragt.
Der Vergleich ist vorbereitet; keine Databricks-Testabfrage wurde ausgeführt.
Die gesamte V1 bleibt `researched`.

## Ergänzender nativer Spark-Nachweis

Auf den anschließenden Benutzerauftrag, selbst einen Testweg zu finden,
wurde der Korpus [lokal auf Apache Spark 4.0.2 ausgeführt](SQLGLOT_NATIVE_SPARK_PROBE.md):
57 positive Fälle und neun native Negativfälle bestanden am 2026-10-17.
Ergebnisse und NULL-Verhalten stimmen mit den gebundenen SQL-Server-
Ergebnissen überein; SQL-Typen und abweichende Clientmetadaten sind getrennt
dokumentiert. Dieser Spark-Nachweis benötigt keinen Databricks-Zugang.
Die native Databricks-Abnahme dieses Berichts bleibt weiterhin `not executed`.
Die anschließende [SQL-Server-/Spark-Performancewelle](SQL_DIALECT_PERFORMANCE_PROBE.md)
mit größeren synthetischen Daten ist teilweise qualifiziert; auch daraus
entsteht kein nativer Databricks- oder Photon-Nachweis.

## Offener Nachweis und Benutzerklarstellung

Der Benutzer hat am 2026-10-17 bestätigt, dass der Spike zu
SQL_Server_Toolbelt gehört und aktuell kein Databricks-Zugang vorhanden ist.
Auf seinen ausdrücklichen Auftrag bleiben die nativen Databricks-Tests
**offen (`not executed`)**, ohne zusätzliche Infrastruktur einzurichten.
Es werden dafür keine Cloud-Accounts, Workspaces, Warehouses oder Cluster
bereitgestellt und keine zusätzlichen Connectoren installiert. Die spätere
lokale Spark-Testlaufzeit ist eine isolierte Researchdependency unter `.runtime/`.
Eine spätere Fortsetzung setzt einen dann verfügbaren, ausdrücklich
ausgewählten Databricks-Zugang und ein festgelegtes Ausführungsprofil voraus.
Bis dahin erfolgen keine weiteren nativen Databricks-Ausführungsversuche.

Der vorbereitete Runner endete am 2026-10-17 vor dem ersten HTTP-/SQL-Aufruf
mit dem eigenen Code `DATABRICKS_CONFIG_MISSING`, Exit 2 und null ausgeführten
Databricks-Fällen. Es gab keinen beobachteten Databricks-Parser-, LATERAL-
oder Ergebnisfehler. Die Benutzerklarstellung bestätigt die fehlende
Voraussetzung; sie ist kein fehlgeschlagener fachlicher Test.

Native Prüfung bedeutet, die Abfragen auf einer tatsächlichen Databricks-
Engine auszuführen. Dafür braucht der gewählte Weg eine Workspace-Anmeldung
und die Nutzung einer Rechenumgebung. Beim hier vorbereiteten REST-Weg ist
das ein bestehendes SQL-Warehouse; kein zweiter separater Login. Ein
vorhandener Databricks-Cluster mit Notebook wäre ein anderer Ausführungsweg,
benötigt jedoch einen entsprechenden Harness und eine eigene Profilbindung.
Ein lokaler Spark-Lauf wäre kein Databricks-Nachweis.

Beim ursprünglichen Databricks-Startversuch wurden keine Ressourcen
eingerichtet, gestartet oder umkonfiguriert und keine neue Dependency
installiert. Die bestehenden SQLGlot-Regeln und der SQL-Server-Runner
bleiben auch nach dem ergänzenden lokalen Spark-Lauf unverändert.

## Vorbereiteter Vergleich

[`run_native_databricks.py`](../../Tests/Research/SqlDialect/run_native_databricks.py)
erzeugt **57 feste Databricks-SELECTs** aus demselben aktuellen Researchkorpus:
33 Databricks-Quellen zu den bereits geprüften T-SQL-Rückübersetzungen sowie
24 Databricks-Zwischenabfragen zu den T-SQL-Original-/Roundtrip-Paaren.
Jede Zwischenabfrage wird einmal ausgeführt und beiden T-SQL-Enden zugeordnet.
Das deckt die 81 T-SQL-Fälle ab; 57 ist keine Verringerung des Vergleichsumfangs.

Parent-/Event-Zeilen, NULLs, Duplikate, Cutoffs, Gleichstände, Leerprofile und
INT-Parameterwerte stammen unverändert aus
[`build_native_cases.py`](../../Tests/Research/SqlDialect/build_native_cases.py).
Nur die Fixture-Typdeklaration wird nativ: INT und TIMESTAMP_NTZ statt
INT und DATETIME2(6). CTEs und VALUES legen keine Tabellen an. Ergebnisorakel
bleiben die handgeschriebenen Python-Relationen; sie werden nicht aus dem
erzeugten SQL abgeleitet.

Der Lauf lädt den bereits vorhandenen lokalen SQL-Server-Bericht und prüft
vor Netzwerkzugriff dessen Quellen-/Pin-/Lab-Helferbindung, sechs vollständige
Versions-/Plattformkombinationen, sämtliche 486 Fallstatus, Ergebniswerte und
erwartete Clienttypfelder. Diese lokale erneute Prüfung bestand am 2026-10-17;
sie ist keine neue SQL-Server-Ausführung. Die SQL-Server-Ergebnisse sind im
[nativen T-SQL-Bericht](SQLGLOT_NATIVE_TSQL_LAB_PROBE.md) dokumentiert.

| Gegenstand | Bereits nativ auf SQL Server bestätigt | Auf Databricks noch zu prüfen |
|---|---|---|
| OUTER/CROSS | 11 bzw. 9 Zeilen einschließlich Duplikaten und NULL-Korrelation | LEFT/CROSS JOIN LATERAL, fehlende rechte Treffer und leere Mengen |
| Korrelierter Top-1 | Höchste passende EventId; NULL-/hoher Floor liefert keinen Treffer | LATERAL mit LIMIT 1 und echten :Floor-Parametern |
| Cutoff und Gleichstand | Dieselbe ParentId mit zwei Cutoffs ergibt 101 bzw. 103 | Nichtgleichheitskorrelation, Erhalt des Cutoffs und EventId als Tie-Breaker |
| Globaler Top-3 | Geordnete Folge 401, 301, 202 | ORDER BY EventId DESC LIMIT 3 |
| COUNT(*) | 7, leere Eingabe eine Zeile mit 0 | Rohes Databricks-COUNT BIGINT; T-SQL-Hinübersetzung mit INT-Ergebniscaste |
| COUNT(ParentId) | 6, leere Eingabe 0 | Ausschluss des NULL-Schlüssels bei identischer Breite laut Quellvertrag |
| COUNT(Parameter) | Wert 7 ergibt 7, NULL ergibt 0; leere Eingabe 0 | Typisiertes REST-Binding statt Wertinterpolation |
| ROW_NUMBER | Drei Nicht-NULL-Ränge 1, 2, 3; leer keine Zeile | Databricks-Quelle INT, T-SQL-Hinübersetzung BIGINT, einschließlich NULL-Sortierschlüssel |
| Typen | INT/BIGINT/SMALLINT, DECIMAL(12,2), DATE, DATETIME2 | Manifesttypen und Werte für dieselben Ausdrücke einschließlich TIMESTAMP_NTZ |

Die Databricks-Spalte enthält Erwartungen und Prüfschritte, keine bestandenen
nativen Befunde. Besonders LATERAL plus korreliertes LIMIT/Cutoff bleibt ein
offenes Capability-Gate. Die Dokumentation erlaubt
[LATERAL-Referenzen auf vorangehende Relationen](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-qry-select-table-reference);
die dokumentierten
[Beschränkungen korrelierter Unterabfragen](https://docs.databricks.com/aws/en/error-messages/unsupported-subquery-expression-category-error-class)
ersetzen keinen Test des konkreten Warehouse-/Runtimeprofils.

## Ergebnis-, NULL- und Typvergleich

Der Runner vergleicht JSON-NULL getrennt von 0 und leeren Strings und erhält
Duplikate durch Multimengenvergleich. Nur der globale Top-3 verlangt eine
bestimmte Ergebnisreihenfolge. Integerwerte werden ohne Float-Konvertierung,
Decimalwerte exakt und NTZ-Werte ohne Zeitzonenverschiebung verglichen.
Die siebente SQLClient-Nachkommastelle darf nur entfallen, wenn sie 0 ist;
eine echte höhere Präzision wird abgewiesen.

Die [Statement Execution API](https://docs.databricks.com/api/statement-execution/v1/statement-execution)
liefert bei JSON_ARRAY Strings und JSON-null sowie SQL-Typangaben im Manifest.
Der Harness prüft die vollständigen Typangaben einschließlich
DECIMAL-Precision/Scale. Dieser API-Vertrag liefert keine Spalten-Nullability
und keine CLR-/Python-Integerbreite. SQL-Server-System.Int32/System.Int64
dürfen deshalb nicht als identische Databricks-Clienttypen gemeldet werden.
Für Nullability- und typisierte Clientobjekte bleibt ein zusätzlicher
festgelegter Treiber-/Clientnachweis erforderlich.

Physische Typunterschiede bleiben ausdrücklich sichtbar: T-SQL TINYINT
0..255 wird auf Databricks SMALLINT; Databricks TINYINT -128..127 wird in
T-SQL SMALLINT. DATETIME2(3) wird TIMESTAMP_NTZ mit Mikrosekundenauflösung;
der Rücktyp DATETIME2(6) ist bereits auf SQL Server bestätigt. Die
Primärverträge nennen [Databricks COUNT als BIGINT](https://docs.databricks.com/aws/en/sql/language-manual/functions/count)
und [ROW_NUMBER als INTEGER](https://docs.databricks.com/aws/en/sql/language-manual/functions/row_number).
Eigene Ergebniscaste sollen den jeweiligen Quellvertrag bewahren; die
erforderlichen Gruppen-/Partitionsgrenzen bleiben deklarierte Voraussetzungen.

## Reproduktion und lokal ausgeführte Kontrollen

Mit dem vorhandenen SQLGlot-Pin 30.23.0 und Python 3.14.7 unter Windows:
Die folgenden Befehle dokumentieren die bereits ausgeführten lokalen
Kontrollen und den früheren, vor Netzwerkzugriff beendeten Startversuch.
Sie sind kein Auftrag zur erneuten nativen Ausführung ohne Zugang.

```powershell
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/test_native_databricks.py
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/run_native_databricks.py --sql-server-report .runtime/sqlglot-spike-30.23.0/native-roundtrip-report-2026-10-17.json --output .runtime/sqlglot-spike-30.23.0/databricks-native-report-2026-10-17.json
```

Der erste Befehl bestand mit zwölf lokalen Testmethoden einschließlich
Negativkontrollen für verlorene Duplikate, NULL→0, Integerbreite,
Decimaldimension, Reihenfolge, leeres COUNT gegenüber leerem Ranking,
NTZ-Präzision, Fehlerstatus, Trunkierung, zusätzliche Chunks, fehlende
Konfiguration, unsichere Hostformen und HTTP-Redirects. Die Testantworten
sind handgeschriebene synthetische API-Objekte. Das qualifiziert weder den
Live-Transport noch den tatsächlichen Databricks-Antwortvertrag.

Der zweite Befehl prüfte die gespeicherte SQL-Server-Baseline und erzeugte den
57-Fall-Korpus erfolgreich, blieb jedoch mit fehlender Konfiguration bei
`not executed`. `--prepare-only` erzeugt dasselbe Paket ausdrücklich ohne
Netzwerkzugriff und endet ebenfalls mit Exit 2.

Für den aktuellen REST-Weg müssen außerhalb des Chats lokal
`DATABRICKS_HOST`, `DATABRICKS_TOKEN` und `DATABRICKS_SQL_WAREHOUSE_ID`
konfiguriert sein. Ein bereits vorhandenes gültiges Bearer-Token wird
verwendet; keine automatische Tokenbeschaffung/-erneuerung. Kein Token oder
vollständiger privater Endpoint gehört in Chat, Repository oder Bericht.
Der Runner prüft ein ausdrücklich ausgewähltes Warehouse auf RUNNING;
er besitzt keinen Start-/Create-/Update-Pfad. Ein Zustandswechsel zwischen
Prüfung und Statement ist damit nicht atomar ausgeschlossen.

Die REST-Anfragen senden ausschließlich feste synthetische SQL-Statements
und explizit typisierte Parameter. TLS-Zertifikatsprüfung bleibt aktiv,
Redirects werden abgewiesen, Ergebnisse bleiben INLINE. Jede Abfrage erhält
30 Sekunden Wartezeit mit CANCEL bei Überschreitung. Unerwartete Chunks oder
Trunkierung scheitern geschlossen. Es gibt weder SQL-Text-CLI noch einen
Fallback auf eine andere Engine. Berichte, Fixture-SQL und Laufzeitprofil
bleiben ausschließlich unter dem ignorierten `.runtime/`; öffentlich werden
nur redigierte Statusaussagen dokumentiert.

## Verbleibende Grenzen

- Native Annahme, Ergebnis-/NULL-/SQL-Typparität auf Databricks sind vollständig
  offen. Der vorbereitete Runner und seine lokalen Kontrollen sind kein Ersatz.
- Dieser Harness unterstützt aktuell nur den REST-/Bearer-Weg zu einem
  bestehenden Warehouse. CLI-/OAuth-Profilauflösung und Notebookausführung
  wurden nicht implementiert oder geprüft.
- Der spätere Lauf erfasst Version/Kanal und Zeitzone lokal. ANSI-Fehlerprofile,
  Zeitzonenwechsel, allgemeine Collations-/Unicodefälle und Treibervarianten
  sind nicht qualifiziert; die Fixtures verwenden exakte Casts und NTZ.
- COUNT-/ROW_NUMBER-Überläufe außerhalb INT32_MAX, unbewiesene eindeutige
  Ordnung, mehrere LATERAL-Stufen und allgemeine Ausdruckstypbindung bleiben
  ausgeschlossen. Ablehnungen des Regelspikes belegen keine Enginefehler.
- Kleine VALUES-Fixtures belegen keine Performance. Die getrennte
  [SQL-Server-/Spark-Performanceprüfung](SQL_DIALECT_PERFORMANCE_PROBE.md)
  enthält native Pläne und teilweise stabile Zeitvergleiche mit größeren
  synthetischen Mengen; native Databricks-Performance bleibt `not executed`.
