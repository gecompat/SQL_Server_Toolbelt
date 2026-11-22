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
Casts und die Erweiterung von `INT` auf `BIGINT`. Ein gesuchter
`CASE`-Ausdruck akzeptiert typgleiche Zweige einschließlich expliziter
NULL-Casts und verlangt einen ELSE-Zweig. Die Abfrage kann
gleich typisierte Operanden in COALESCE, NULLIF und dem zweistelligen
T-SQL-ISNULL verwenden. Sie kann
vollständig qualifizierte Relationen mit Alias enthalten. Mehrere Relationen
werden als Liste `relations` übergeben. Nichtrekursive CTEs können auf früher
definierte CTEs derselben Abfrage verweisen. Explizite INNER-, LEFT-, RIGHT-,
FULL- und CROSS-Joins werden übersetzt. Das logische Schema berücksichtigt
zusätzliche NULLs aus Outer Joins. Abgeleitete Tabellen, DISTINCT und
UNION mit oder ohne ALL unterstützen den gemeinsamen skalaren
Vergleichsvertrag. UNION erfordert positionsweise identische Spaltentypen.
Für Sternprojektionen über Basistabellen muss `column_order` sämtliche
Spalten in der ursprünglichen Reihenfolge aufführen. Verdeckte oder
doppelte Ausgabespalten werden abgelehnt.
EXISTS-Unterabfragen erlauben eine Ebene der Gleichheitskorrelation.
IN akzeptiert gleich typisierte Literallisten. Dezimalprojektionen
erhalten explizite Precision und Scale. Ein Cast, der ein Literal
runden oder abschneiden müsste, wird abgelehnt.
Textwerte aus explizit gebundenen Spalten oder Parametern können projiziert
werden. `NVARCHAR(n)` bezeichnet dabei den gemeinsamen logischen Vertrag
mit höchstens `text_max_utf16_units` UTF-16-Einheiten und der Zusicherung
`text_unicode_scalars: true`. Die Databricks-Parameterprojektion verwendet
STRING. Vergleiche, Gruppierung sowie Sortierung von Text erfordern
einen eigenen Collationvertrag und werden in diesem Profil abgelehnt.
Gruppierung über benannte Spalten, HAVING, MIN/MAX und COUNT/COUNT_BIG
sind für die gebundenen Ganzzahlabfragen abgedeckt. Erforderliche
INT-Zählungen setzen die Zusicherung `max_group_rows` voraus.
Addition, Subtraktion, Multiplikation und SUM verwenden deklarierte
`integer_domains` für Spalten und Parameter. Jede Zwischengröße wird
gegen den gemeinsamen Typbereich geprüft. SUM erfordert zusätzlich
`max_group_rows` und prüft die Grenze vor dem Ergebniscast.
TOP und LIMIT erfordern einen positiven Literalwert und ORDER BY über
nicht nullbare Ausgabealiase. Für die begrenzte Auswahl muss `unique_order`
genau die als eindeutig zugesicherte Reihenfolge der Schlüssel enthalten.
ROW_NUMBER wird mit dem logischen Rückgabetyp der Quelle ausgegeben. Es
erfordert nicht nullbare gebundene Schlüssel, deren eindeutige Reihenfolge
in `ranking_order` (Partition, dann Sortierung) und das Limit
`max_partition_rows`. Die Databricks-Formen QUALIFY ROW_NUMBER() = 1 und
ROW_NUMBER() <= n werden als gefilterte abgeleitete Tabelle ausgegeben.
Die Rangspalte bleibt intern.

DATE unterstützt explizite Kalenderliterale, typisierte Eingaben,
YEAR/MONTH/DAY und Tagesarithmetik. Für DATE-Eingaben aus Tabellen oder
Parametern ist der gemeinsame inklusive Wertebereich `date_domain` nötig.
DATEADD akzeptiert ganzzahlige Literale als Verschiebung und prüft beide
Bereichsgrenzen. DATEDIFF erhält die Reihenfolge von Start und Ende.
Zeitstempel und andere Zeiteinheiten liegen außerhalb dieses Teilumfangs.
Spaltennamen müssen auf beiden Seiten identisch sein. Parameterwerte
werden erst durch den jeweiligen SQL-Client gebunden.

Der Teilumfang für APPLY und LATERAL akzeptiert eine einzelne laterale
Unterabfrage mit einer benannten Relation. Eine Korrelation darf aus
gleich typisierten Spaltenpaaren bestehen, die per AND verbunden sind.
Filter auf der rechten Relation bleiben in der Unterabfrage.
Der Aufrufer muss mit `"lateral_select": true` die
entsprechende Databricks-Fähigkeit ausdrücklich zusichern. Der Bericht führt
diese Voraussetzung unter `required_capabilities` auf.
Für direkt laterales TOP/LIMIT sind zusätzlich
`lateral_ordered_limit: true` und `lateral_unique_order` nötig.
Ein zusätzliches linkes Cutoff-Prädikat erfordert bei TOP/LIMIT
`lateral_cutoff: true`. In diesem Profil bleibt die direkte laterale
Ausführung erhalten.
Korrelierte Skalaraggregate ohne GROUP BY benötigen
`lateral_scalar_aggregate: true`. Diese Schalter sind Zusicherungen des
Aufrufers zur gewählten Zielengine. Der Offline-Check ermittelt sie nicht.

Die JSON-Ausgabe enthält bei `converted` SQL, ein logisches Ergebnisschema
und den Parametervertrag. Bei fehlendem Kontext, einem nicht abgedeckten
Konstrukt, ungültiger Eingabe oder einem Limitüberschritt enthält sie einen
festen Fehlercode und `sql: null`. Die SQL-Datei ist auf 16 KiB, die
Kontextdatei auf 64 KiB, der Tokeneingang auf 512 Tokens und die
Klammerungstiefe auf 16 begrenzt. Die SQL-Ausgabe ist auf 1 MiB
begrenzt. Eingaben werden als UTF-8 gelesen.

## Native Abnahme

Die CI führt den [synthetischen Korpus](native_cases.py) auf SQL Server 2025
aus. Sie prüft Werte, NULL, Multiplizität, definierte Reihenfolge und die
per SqlClient beobachteten Spaltennamen und Typen. Der SQL-Lauf verwendet
einen isolierten Container, dessen Abwesenheit nach dem Test verifiziert wird.

Die Databricks-Prüfung nutzt dieselben festen Fälle. Für ein bestehendes
ausdrücklich ausgewähltes laufendes SQL-Warehouse müssen
`DATABRICKS_HOST`, `DATABRICKS_SQL_WAREHOUSE_ID` und
`DATABRICKS_TOKEN` lokal gesetzt sein. Der Befehl
`python Scripts/SqlDialect/native_cases.py --databricks` gibt nur
Fallnamen und Status aus und legt keine Cloud-Ressourcen an.
Fehlt die Konfiguration, endet die Prüfung vor dem ersten Request
mit `DATABRICKS_CONFIG_MISSING`. Der historische Spark-Nachweis
beschreibt den früheren Researchkorpus. Die native Databricks-Abnahme
des aktuellen Konverters bleibt davon getrennt.

Die [lokalen Tests](test_convert_query.py) prüfen die Umkehrkonvertierung,
Schema- und Parametererhalt und explizite Ablehnungen. Komplexere APPLY-Fälle,
zusätzliche Typen und die native Databricks-Abnahme bleiben weitere Arbeit
der freigegebenen V1.
