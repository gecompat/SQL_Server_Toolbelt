# Lokale SQL-Dialektkonvertierung

Das Werkzeug übersetzt im ersten offline geprüften Teilumfang einzelne
lesende Abfragen mit Ganzzahlprojektionen zwischen T-SQL und Databricks SQL.
Es führt keine Abfrage aus und fragt keine Kataloge ab.
Die [gesamte V1-Spezifikation](../../Documentation/Research/TSQL_DATABRICKS_V1_SCOPE_PROPOSAL.md)
enthält die weiteren Sprachteile und die ausstehende native Zielabnahme.

Aus einer lokalen Python-Umgebung mit dem geprüften SQLGlot-Pin:

```powershell
python -m pip install --require-hashes -r Scripts/SqlDialect/requirements.txt
python Scripts/SqlDialect/convert_query.py --source tsql --sql query.sql --context context.json
```

Für eine Abfrage in Gegenrichtung `--source databricks` verwenden und im
Kontext Quell- und Zielrelation entsprechend zuordnen. Der SQLGlot-Pin
stammt aus dem ursprünglichen [Regelspike](../../Documentation/Research/SQLGLOT_TSQL_DATABRICKS_RULE_SPIKE.md).
Das Werkzeug installiert während der Konvertierung keine Pakete.

Beispiel für `query.sql` und `context.json`:

```sql
SELECT e.Id AS ItemId
FROM dbo.Event AS e
WHERE e.Id >= @Minimum OR e.Id IS NULL;
```

```json
{
  "relation": {
    "source": ["dbo", "Event"],
    "target": ["main", "demo", "Event"],
    "columns": {"Id": {"type": "BIGINT", "nullable": true}}
  },
  "parameters": {"Minimum": {"type": "BIGINT", "nullable": false}}
}
```

Unterstützt sind explizit aliasierte Projektionen, nullbare `INT`- und
`BIGINT`-Spalten und Parameter, kleine ganzzahlige Literale, gleiche
Vergleichstypen, `IS NULL`, logische Verknüpfungen sowie typgleiche
Casts und die Erweiterung von `INT` auf `BIGINT`. Die Abfrage kann
vollständig qualifizierte Relationen mit Alias enthalten. Mehrere Relationen
werden als Liste `relations` übergeben. Nichtrekursive CTEs können auf früher
definierte CTEs derselben Abfrage verweisen. Explizite INNER-, LEFT-, RIGHT-,
FULL- und CROSS-Joins werden übersetzt. Das logische Schema berücksichtigt
zusätzliche NULLs aus Outer Joins.
Spaltennamen müssen auf beiden Seiten identisch sein. Parameterwerte
werden erst durch den jeweiligen SQL-Client gebunden.

Der Teilumfang für APPLY und LATERAL akzeptiert eine einzelne laterale
Unterabfrage mit einer benannten Relation und optional einer gleich typisierten
Gleichheitskorrelation. Der Aufrufer muss mit `"lateral_select": true` die
entsprechende Databricks-Fähigkeit ausdrücklich zusichern. Der Bericht führt
diese Voraussetzung unter `required_capabilities` auf.

Die JSON-Ausgabe enthält bei `converted` SQL, ein logisches Ergebnisschema
und den Parametervertrag. Bei fehlendem Kontext, einem nicht abgedeckten
Konstrukt, ungültiger Eingabe oder einem Limitüberschritt enthält sie einen
festen Fehlercode und `sql: null`. Die SQL-Datei ist auf 16 KiB, die
Kontextdatei auf 64 KiB, der Tokeneingang auf 512 Tokens und die
Klammerungstiefe auf 16 begrenzt. Eingaben werden als UTF-8 gelesen.

Die [lokalen Tests](test_convert_query.py) prüfen die Umkehrkonvertierung,
Schema- und Parametererhalt und explizite Ablehnungen. Komplexere APPLY-Fälle,
zusätzliche Typen und die native Databricks-Abnahme bleiben weitere Arbeit
der freigegebenen V1.
