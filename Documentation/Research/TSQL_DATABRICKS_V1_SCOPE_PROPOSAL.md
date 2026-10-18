# Erster Funktionsumfang: T-SQL ↔ Databricks SQL

Stand: 2026-10-16 · Autor: Codex · Status: konkretisierter Vertragsvorschlag,
`researched`, keine Implementierungsfreigabe. Dieser Vorschlag präzisiert die
[Machbarkeitsanalyse](SQL_DIALECT_TRANSFORMATION_FEASIBILITY.md) nach dem
Benutzerauftrag desselben Tages. „Automatisch“ bezeichnet geplantes Verhalten
nach Implementierung und Qualifikation; derzeit ist kein Toolbelt-Transpiler implementiert
oder als V1 empirisch qualifiziert. Der anschließend ausdrücklich beauftragte
[SQLGlot-Spike](SQLGLOT_TSQL_DATABRICKS_SPIKE.md) wurde am 2026-10-16 mit
32 synthetischen Eingaben ausgeführt. Native Engine-/Ergebnis-/Performance-
prüfungen waren dabei `not executed`; die beobachteten Providergrenzen schränken
die hier geplante Automatik ein.

Die anschließend beauftragte [eigene Regelspike-Erweiterung](SQLGLOT_TSQL_DATABRICKS_RULE_SPIKE.md)
ist inzwischen mit 140 Eingaben, 42 Roundtrips und 852 Assertions lokal geprüft.
Sie konkretisiert begrenzte AST-Regeln für LATERAL/APPLY, Parameter, Casts,
Zähl-/Rankingtypen und Limit-Gates; kein allgemeiner Binder oder fertiges V1-Modul.

**Nachgeführter Prüfstand, 2026-10-18:** Die [native SQL-Server-Prüfung](SQLGLOT_NATIVE_TSQL_LAB_PROBE.md)
bestand am 2026-10-17 mit 81 Fällen auf sechs Labzielen; die [lokale Spark-Prüfung](SQLGLOT_NATIVE_SPARK_PROBE.md)
mit 57 positiven und neun negativen Fällen. Die [Performance-/Planprüfung](SQL_DIALECT_PERFORMANCE_PROBE.md)
ist teilweise qualifiziert. Native Databricks-Tests bleiben ausdrücklich offen;
der begrenzte Researchkern ist kein freigegebenes Produkt-V1.

## Vorgeschlagene erste Funktion

**Eine einzelne lesende Abfrage einschließlich nichtrekursiver CTEs und eines
definierten APPLY-Teilumfangs in die Gegenrichtung übersetzen.** Ausgabe sind
lesbares SQL und ein strukturierter Transformationsbericht. Keine automatische
Ausführung, Migration, Installation, View-/Prozedurerzeugung oder Optimierung
von Server-/Warehouseeinstellungen.

T-SQL-Ziel ist zunächst der gemeinsame Sprachumfang von SQL Server 2019/CL150;
auf 2022/CL160 und 2025/CL170 wird derselbe Umfang geprüft, soweit kein anderer
Zweig betroffen ist. Neuere T-SQL-Funktionen gehören nicht automatisch dazu.
Databricks SQL erhält ein eigenes Capabilityprofil für das ausgewählte SQL
Warehouse beziehungsweise die ausgewählte Runtime. Verfügbare Warehouseversion
beziehungsweise Kanal und tatsächlich qualifizierte Fähigkeiten werden im Testprofil gebunden;
offene Zielbindung verhindert eine Supportzusage. Apache Spark und Python
bleiben Folgeumfänge.

Vorgeschlagener Host ist ein lokales externes Werkzeug. Damit ist für die
Konvertierung keine SQL-CLR-Installation erforderlich. Dependencyversion und
Packaging bleiben vor einem Implementierungsbeginn zu entscheiden; eine
zusätzliche SQL-USP-Fassade wird hier nicht als freigegeben behandelt.

## Voraussetzungen und Ergebnisvertrag

Der Aufrufer liefert neben SQL-Text und Richtung:

- Quell-/Zielprofile einschließlich relevanter ANSI-/ARITHABORT-/ANSI_WARNINGS-,
  Quoting-, Collation- und Zeiteinstellungen; das Werkzeug ändert diese nicht.
- Ein explizites Tabellen-/Schema-/Katalogmapping. `dbo.Event` wird nicht durch
  Namensraten einem Unity-Catalog-Objekt zugeordnet.
- Spaltennamen, Typen mit Precision/Scale/Länge, Nullability, relevante
  Schlüssel und deklarierte Wert-/Kardinalitätsgrenzen. Eine Databricks-PK-
  Deklaration allein wird nicht als Beweis tatsächlich eindeutiger Daten benutzt.
- Typisierte Parameterdefinitionen. T-SQL `@Name` wird auf einen passenden
  Databricks-Parameter abgebildet; Werte werden nicht in SQL-Literale eingesetzt.
  Ein Hostadapter ist nur bei qualifiziertem Parameterbinding unterstützt.

Nicht jede Abfrage benötigt jeden Kontextwert: Ganzzahlprojektion benötigt
keine Stringcollation, eine Stringgleichheit schon. Verwendete Annahmen werden
im Bericht einzeln festgehalten. Vom Aufrufer zugesicherte Domänen sind als
solche sichtbar; das Werkzeug hat sie beim Konvertieren nicht an Daten geprüft.
Views sind nur als ausdrücklich gebundene, stabile Relationen zulässig;
unbekannte View-/Funktionslogik wird nicht als seiteneffektfrei erraten.

Vorgeschlagene Verarbeitungsergebnisse:

| Zustand | Bedeutung | SQL-Ausgabe |
|---|---|---|
| `converted` | Gesamte Abfrage liegt im Profil; statische Bindung und Regeln erfolgreich | Vollständiges Ziel-SQL, Parameterbeschreibung, logisches Ergebnisschema, Regelbericht |
| `requires_context` | Beispielsweise Typ, Mapping, Eindeutigkeits- oder Collationvertrag fehlt | Keine scheinbar ausführbare Teilübersetzung; genaue fehlende Angaben |
| `unsupported` | Konstrukt liegt außerhalb V1 oder kann im ausgewählten Zielprofil nicht erhalten werden | Quellposition und fachlicher Anpassungshinweis; kein Erfolg mit still gelöschter Klausel |
| `invalid_input` / `limit_exceeded` | Parserfehler oder überschrittene Eingabe-/Arbeitsgrenze | Strukturierter Fehler; keine Teilübersetzung |

Syntaxprüfung, native Engineprüfung und Performanceprüfung sind getrennte
Berichtsfelder. `converted` bedeutet keine bereits ausgeführte Abfrage.
Erhalten werden im vereinbarten Datendomänenvertrag Werte, NULL, Duplikate,
Spaltennamen/-reihenfolge, logische Typen und zugesicherte Ergebnisordnung.
Engineabhängige physische Typnamen, konservative Treiber-Nullability,
Fehlernummern und identische Ausführungspläne werden nicht gleichgesetzt.
Nullabilityabweichungen im Clientmetadatenvertrag müssen sichtbar bleiben.
Eine Abfrage ohne abschließendes ORDER BY garantiert keine Zeilenreihenfolge.
Gleichwertigkeit bezieht sich auf denselben stabilen Datenbestand, nicht auf
zeitgleich veränderliche unabhängige Systeme oder einen gemeinsamen Snapshot.

## Automatisierungsmatrix des ersten Umfangs

**A** = geplante automatische Regel bei erfülltem Kontext;
**K** = zusätzliche Datendomäne/Zielfähigkeit muss belegt oder ausdrücklich
vereinbart werden; **M** = manuelle Anpassung beziehungsweise späterer Vertrag.
Die Kennzeichnung ist keine Aussage über bereits vorhandene Toolunterstützung.

| Konstrukt | T-SQL → Databricks SQL | Databricks SQL → T-SQL | Konkreter V1-Umfang / Grenze |
|---|---|---|---|
| SELECT, Aliase, abgeleitete Tabellen, nichtrekursive CTEs | A | A | Vollständig gebundene Namen; explizite öffentliche Projektion. `*` nur bei vollständigem Schema kontrolliert expandieren; keine automatische Metadatenabfrage. |
| WHERE, CASE, AND/OR/NOT, IS NULL, Vergleiche | A/K | A/K | Gemeinsame Typen und dreiwertige Logik erhalten. CASE-/Vergleichsoperanden explizit typisieren; keine fehlerträchtige Ausdrucksumordnung. |
| INNER/LEFT/RIGHT/FULL JOIN ON, ausdrücklicher CROSS JOIN | A | A | Vorhandene Multiplizität erhalten; Prädikate nicht über eine Outer-Join-Grenze verschieben. NATURAL/USING zunächst M. |
| UNION ALL | A | A | Spaltenzahl/-reihenfolge und gemeinsamen Typ festlegen. SELECT DISTINCT und UNION ohne ALL nur mit gemeinsamem Vergleichsvertrag K; EXCEPT/INTERSECT zunächst M. Stringvergleich kann Datensätze zusammenführen. |
| GROUP BY/HAVING, MIN/MAX, COUNT/COUNT_BIG | A/K | A/K | Gruppierung und MIN/MAX auf gemeinsamen numerischen/DATE-Typen. Strings nur mit passendem Vergleichsvertrag; Zähltyp explizit erhalten. Keine mehrspaltigen COUNT-DISTINCT-/FILTER-Erweiterungen in V1. |
| SUM | K | K | Erstes Zahlenprofil: INT/BIGINT mit explizitem Ergebniscast und belegten Grenzen auch für Zwischensummen. DECIMAL-SUM und AVG zunächst M; eigene Regeln für Akkumulator, Rundung und Ergebnistyp notwendig. |
| ROW_NUMBER | A/K | A/K | Eindeutige Sortierung je Partition, NULL-Reihenfolge und Rückgabetyp behandeln. Databricks-Partitionsgrenze für INTEGER beachten; für größere oder unbekannt unbegrenzte Partitionen keine Gleichwertigkeitszusage. Weitere Window-Funktionen/Frames zunächst M. |
| TOP(n) mit ORDER BY ↔ LIMIT n mit ORDER BY | A/K | A/K | Positives ganzzahliges Literal und deterministische Auswahl. Kein PERCENT, WITH TIES, OFFSET oder Laufzeitausdruck für n. Ohne eindeutige Auswahl zunächst K. |
| Einfaches QUALIFY ROW_NUMBER() <= n bzw. = 1 | entfällt | A/K | Innere Projektion mit internem Ranking, äußeres WHERE; anschließend öffentliches ORDER BY/LIMIT. V1 ohne Kombination mit DISTINCT, GROUP BY/HAVING oder anderen Window-Ausdrücken. Hilfsspalten nicht ausgeben. |
| OUTER/CROSS APPLY ↔ lateraler LEFT/CROSS JOIN | A/K | A/K | Eng begrenzte Formen gemäß nächstem Abschnitt; kein blindes Ersetzen des Schlüsselworts. |
| EXISTS/NOT EXISTS | A/K | A/K | Unkorreliert oder eine Ebene mit gebundenen Gleichheitskorrelationen und erlaubtem rechten Filter; keine beliebigen skalaren Unterabfragen. IN zunächst nur typisierte Literalliste. |
| COALESCE/NULLIF, ISNULL als T-SQL-Ersatzwertfunktion | A/K | A/K | Nur gleich typisierte numerische/DATE-Operanden; erforderliche Ergebniscasts explizit. Databricks `isnull(x)` ist ein NULL-Prädikat, nicht T-SQL `ISNULL(x,y)`. Stringlängen-/Trunkierungsfälle zunächst M. |
| YEAR/MONTH/DAY und Tagesarithmetik auf DATE | A/K | A/K | Typisiertes DATE; YEAR/MONTH/DAY; DATEADD(day,n,d) ↔ date_add(d,n), DATEDIFF(day,a,b) ↔ datediff(b,a). Ergebnisse innerhalb SQL-Server-Datumsbereich; keine impliziten String-/Timestampkonvertierungen. |
| Weitere Funktionen und Operatoren | K/M | K/M | Nur explizite Positivliste. INT-/BIGINT-Addition/Subtraktion/Multiplikation mit belegtem überlauffreiem Wertebereich; Division, Modulo, Float/NaN, allgemeine Decimalarithmetik und Stringfunktionen zunächst M. |

Gleichnamige Funktionen sind keine Gleichwertigkeitsregel:

- [T-SQL COUNT](https://learn.microsoft.com/en-us/sql/t-sql/functions/count-transact-sql?view=sql-server-ver17)
  liefert `int`, COUNT_BIG `bigint`; [Databricks count](https://docs.databricks.com/aws/en/sql/language-manual/functions/count)
  liefert BIGINT. Databricks→T-SQL benutzt im einfachen Fall COUNT_BIG;
  T-SQL COUNT→Databricks benötigt einen INT-Cast und einen passenden
  Kardinalitäts-/Fehlervertrag. Mehr Ausdrucksargumente sind kein einfaches Mapping.
- [T-SQL ROW_NUMBER](https://learn.microsoft.com/en-us/sql/t-sql/functions/row-number-transact-sql?view=sql-server-ver17)
  liefert `bigint`, [Databricks row_number](https://docs.databricks.com/aws/en/sql/language-manual/functions/row_number)
  INTEGER. Ein Zielcast allein erweitert nicht den internen Wertebereich.
- [T-SQL AVG](https://learn.microsoft.com/en-us/sql/t-sql/functions/avg-transact-sql?view=sql-server-ver17)
  über INT liefert INT; [Databricks avg](https://docs.databricks.com/aws/en/sql/language-manual/functions/avg)
  im entsprechenden Fall DOUBLE. Der Mittelwert von 1 und 2 ist daher kein
  Beleg für eine direkte AVG-Übersetzung. Ein abschließender Cast allein
  garantiert weder gleiches Rundungs- noch Überlaufverhalten.
- Auch [T-SQL SUM](https://learn.microsoft.com/en-us/sql/t-sql/functions/sum-transact-sql?view=sql-server-ver17)
  und [Databricks sum](https://docs.databricks.com/aws/en/sql/language-manual/functions/sum)
  haben unterschiedliche Typregeln. Ein Cast erst nach der Summe kann
  unterschiedliche Zwischenüberläufe nicht allgemein reparieren.
- Bei DATE ist die [Argumentreihenfolge von datediff](https://docs.databricks.com/aws/en/sql/language-manual/functions/datediff)
  ausdrücklich umzudrehen; [date_add](https://docs.databricks.com/aws/en/sql/language-manual/functions/date_add)
  wird hier nur für Tage und DATE freigeplant. Monats-/Zeitstempelarithmetik
  bleibt ein eigener Vertrag.

## Typen, Text und Zeit als harte Semantikgrenzen

Gemeinsamer erster Wertumfang: INT, BIGINT, DATE, übergebene DECIMAL-Werte
ohne allgemeine Rechen-/Aggregatzusage und explizit vereinbarte Textwerte.
Projektion ist meist einfacher als Vergleich oder Berechnung. DECIMAL-
Precision/Scale bleibt Teil jeder Projektion und jedes gemeinsamen UNION-Typs.

| Situation | Geplante Behandlung |
|---|---|
| Stringgleichheit, Join, GROUP BY, DISTINCT oder ORDER BY | Nur bei belegtem gemeinsamen Case-/Accent-/Padding-/Sortiervertrag. `LOWER` oder eine ähnlich benannte Collation ist kein allgemeiner Ersatz. Fehlt der Vertrag: K. |
| Reine Stringprojektion | Übertragen bei deklariertem Zeichenvorrat, Längen-/Encodingvertrag und unveränderten Zeichen; V1 keine pauschale varchar↔nvarchar↔STRING-Äquivalenz oder Trunkierung. |
| datetime2 bis Präzision 6 / TIMESTAMP_NTZ mit Präzision 6 | Optionales K-Profil: gleiche zeitzonenlose Bedeutung, passender Wertebereich, bewiesene Quellpräzision und expliziter Typadapter. Keine Zeitzonenumrechnung durch die Hintertür. |
| datetime2(7), höhere Databricks-Präzision, TIMESTAMP mit Zeitzonenbezug, datetimeoffset | M im ersten Profil. Kein stilles Abschneiden, Runden oder Entfernen des Offsets. Separates Zeitprofil könnte später mehr abdecken. |
| BOOLEAN/bit, BINARY, UUID/uniqueidentifier, XML, JSON/VARIANT, ARRAY/MAP/STRUCT, INTERVAL | M im ersten Profil; BIT und BOOLEAN insbesondere bei Ausdrucks-/Prädikatverwendung nicht bloß umbenennen. |
| Fehlende Schlüssel, Bereichs- oder Vergleichsnachweise | K mit konkreter fehlender Angabe; keine statistische Vermutung als Beweis. |

[datetime2](https://learn.microsoft.com/en-us/sql/t-sql/data-types/datetime2-transact-sql?view=sql-server-ver16)
unterstützt sieben Nachkommastellen. Die aktuell geprüfte
[Databricks-TIMESTAMP_NTZ-Dokumentation](https://docs.databricks.com/aws/en/sql/language-manual/data-types/timestamp-ntz-type)
nennt standardmäßig sechs und zusätzlich Präzision 7–9 als Beta mit weiteren
Grenzen. Das erste Profil bleibt bewusst beim gesondert zu qualifizierenden
Sechserumfang; höhere Präzision wird nicht als grundsätzlich unmöglich dargestellt.

## OUTER APPLY: konkrete erlaubte Regeln

V1 begrenzt sich auf **eine APPLY-/LATERAL-Stufe je SELECT-Block** und eine
Korrelationsstufe. Ein zuvor gejointes linkes Rowset ist möglich, sofern alle
verwendeten Schlüssel und Duplikate gebunden sind. Verkettete/nestende APPLYs,
unbekannte TVFs und nondeterministische Ausdrücke bleiben M.

| Form | Automatischer Weg bei erfüllten Voraussetzungen | Grenze |
|---|---|---|
| OUTER APPLY mit deterministischer rechter SELECT-Abfrage und Gleichheitskorrelation | LEFT JOIN LATERAL mit ON TRUE; alternativ nachgewiesene Dekorrelation zu LEFT JOIN | Keine Änderung des Nullerhalts, rechter Filter bleiben rechts; Zielcapability qualifizieren |
| CROSS APPLY derselben nichtaggregierten Form | CROSS JOIN LATERAL beziehungsweise bewiesener INNER JOIN | Bei leerem rechten Ergebnis entfällt die linke Zeile; nicht als LEFT JOIN ausgeben |
| TOP(n) je vollständigem Gleichheitsschlüssel, eindeutiges ORDER BY | Direkt lateral mit LIMIT, wenn unterstützt; sonst begrenzte ROW_NUMBER-CTE plus LEFT JOIN und rn <= n im ON | Alle rechten Filter vor Ranking; keine zusätzliche linke Abhängigkeit; Partitionsgrößen-/Typgrenzen einhalten |
| Zusätzliches deterministisches linkes Cutoff-Prädikat bei TOP(n) | K: ausschließlich direkte LATERAL-/APPLY-Form, wenn genau dieses Zielmuster qualifiziert ist | Keine einfache Schlüssel-Dekorrelation; ohne qualifizierte direkte Form M |
| Scalar COUNT/COUNT_BIG ohne GROUP BY/HAVING | Lateral erhalten oder rechte Voraggregation plus LEFT JOIN mit typkorrektem COALESCE auf 0 | Auch CROSS APPLY liefert in diesem Fall die linke Zeile bei null Treffern; INNER JOIN auf Voraggregation wäre falsch |
| Scalar MIN/MAX ohne GROUP BY/HAVING | Lateral erhalten oder belegte Voraggregation plus LEFT JOIN | Leere rechte Eingabe bleibt NULL; kein pauschaler Ersatz durch 0 |
| Databricks LEFT JOIN LATERAL ... ON TRUE | OUTER APPLY, rechte SELECT-Abfrage rekursiv übersetzen | Zusätzliches ON-Prädikat zunächst M; nicht vor ein rechtes LIMIT verschieben |
| Databricks CROSS JOIN LATERAL derselben Teilmenge | CROSS APPLY | Ein generischer INNER JOIN LATERAL mit zusätzlicher ON-Bedingung liegt außerhalb der direkten V1-Regel |

Die ausführlichen [synthetischen Top-1-Beispiele](SQL_DIALECT_TRANSFORMATION_FEASIBILITY.md#synthetischer-top-1-fall-und-mengenorientierte-alternative)
gelten unter diesen engeren Voraussetzungen weiter. Direkte LATERAL-Syntax
ist durch [Databricks JOIN](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-qry-select-join)
belegt; die [Korrelationsgrenzen](https://docs.databricks.com/aws/en/error-messages/unsupported-subquery-expression-category-error-class)
verhindern eine pauschale Zusage für jedes korrelierte LIMIT.

Ein konkreter Fall für zusätzliche Zielqualifikation oder manuelle Anpassung:

```sql
-- Synthetisch: Die Auswahl hängt außer vom Schlüssel von einem Wert
-- der jeweiligen linken Zeile ab. Ein globales Ranking je ParentId
-- würde möglicherweise ein zu spätes Event auswählen.
OUTER APPLY
(
    SELECT TOP (1) e.EventId
    FROM dbo.Event AS e
    WHERE e.ParentId = p.ParentId
      AND e.EventTime <= p.CutoffTime
    ORDER BY e.EventTime DESC, e.EventId DESC
) AS lastEvent
```

Hier lautet der Bericht K mit Quellstelle `p.CutoffTime`: Nur eine für diese
Form qualifizierte direkte LATERAL-Übersetzung darf automatisch greifen.
Andernfalls M; kein Ersatz durch das einfache Ranking je ParentId. Eine spätere
Regel könnte zunächst Kandidaten je belegter linker Zeilenidentität bilden
und danach ranken. Dieses Join-Ranking kann stark wachsen und gehört nicht in
den einfachen Schlüsselrewrite.
Künstliche Zeilenidentität aus einer instabilen ROW_NUMBER wird nicht erfunden.

Bei TOP ohne eindeutige Ordnung wird kein zusätzlicher fachlicher
Sortierschlüssel geraten. Der Benutzer kann die Auswahlregel ausdrücklich
ergänzen; das ist eine bewusste Präzisierung der ursprünglichen Semantik.
Linke Duplikate bleiben auch bei gleichen Korrelationswerten erhalten.

## Performance: was automatisch sinnvoll ist und was gemessen werden muss

Der Standardmodus erzeugt die möglichst direkte semantisch erhaltene Form.
Ein optionaler Modus darf eine **separate, begründete mengenorientierte
Alternative** liefern, sofern deren Voraussetzungen bewiesen sind. Ohne
Messung heißt sie nicht „schneller“. Eine notwendige Ausweichform bei fehlender
Zielcapability ist als solche sichtbar. Fehlt auch eine sichere Ausweichform,
wird die Konvertierung abgelehnt.

Automatisch vorgesehen:

- Keine neuen Python-UDFs, Cursor, Zeilenschleifen, collect/toPandas oder
  Materialisierungen einführen; native Zieloperationen verwenden.
- Öffentliche und intern benötigte Spalten gezielt projizieren. Filter nur dann
  vorziehen, wenn Outer-Join-, Top-N-, Aggregat- und NULL-Semantik erhalten bleiben.
- SARGable Bedingungen möglichst bewahren: keine zusätzliche Funktion oder
  unnötigen Cast auf eine Such-/Joinspalte legen; nötige Typanpassung am passend
  typisierten Parameter nur bei gleicher Vergleichssemantik.
- Bei der sicheren APPLY-Top-N-Alternative je vollständigem Schlüssel ranken,
  nicht wiederholt für jede identische linke Schlüsselbelegung. Kein DISTINCT
  auf dem öffentlichen linken Ergebnis zur vermeintlichen Beschleunigung.
- Keine Index-, BROADCAST-, Repartitionierungs- oder Cachehinweise ohne eigenen
  belegten Vertrag erzeugen; Quellhints nicht still entfernen.

Manuell beziehungsweise nur mit zusätzlicher Performancequalifikation:

| Szenario | Entscheidung und zu prüfende Hypothese |
|---|---|
| Wenige linke Zeilen, passender SQL-Server-Index | APPLY/TOP mit Seek kann günstiger als Ranking der ganzen rechten Tabelle sein. Bei Rückübersetzung die Window-Form nicht automatisch auflösen. |
| Viele linke Zeilen, wiederholte Schlüssel | Rechte Voraggregation/Window kann Arbeit sparen; tatsächliche Scans, Sortierung, Shuffle und Skew müssen gemessen werden. |
| Zeitliche oder andere Nichtgleichheitskorrelation | Kandidatenjoin kann sehr viele Zwischenzeilen erzeugen; keine automatische Freigabe eines potenziell teuren Ersatzplans. |
| Mehrfach verwendete CTE | Keine Zusage einmaliger Ausführung. Cache-/Temp-Materialisierung ist ein separater Lifecycle-/Ressourcenvertrag. |
| Fehlende Datenverteilung, Statistiken oder stabile Testumgebung | Semantisch mögliche Übersetzung kann ausgegeben werden; Performancefeld bleibt `not executed`/unbekannt, keine erfundene Rangfolge. |

Geplante Abnahme: direkte Zielübersetzung und erlaubte Alternative auf derselben
Zielengine bei selektiven, breiten, schief verteilten und duplikatreichen
synthetischen Daten vergleichen. Übersetzungs-, Compile- und Ausführungszeit
trennen; Reads/CPU beziehungsweise Scan-/Shuffle-/Spillvolumen und robuste
Laufzeitverteilung erfassen. Warm-up, Wiederholungen und ein szenariobezogenes
Akzeptanzbudget vor dem Messlauf festlegen. Kein pauschaler Faktor zwischen
SQL Server und einem Warehouse. Messwerte/Pläne bleiben lokal unversioniert.
[Databricks Optimierung](https://docs.databricks.com/aws/en/optimizations/)
und [Spark Performance Tuning](https://spark.apache.org/docs/latest/sql-performance-tuning.html)
liefern die Zielgrundlagen, aber keinen Benchmark für diese Vorschläge.

## Manuelle Grenzen des ersten Umfangs

Nicht automatisch: DML/DDL und SELECT INTO; CREATE/ALTER PROCEDURE/FUNCTION,
SQL-Scripting, Transaktionen und TRY/CATCH; Temp-Tabellen, Tabellenvariablen,
GO/Mehrfachbatches, DECLARE/SET-Skripte und dynamisches SQL; unbekannte
UDF/TVF/CLR- oder Systemkataloglogik; NOLOCK/Lock-/Index-/Optimizerhints;
rekursive CTE, PIVOT/UNPIVOT, TOP PERCENT/WITH TIES/OFFSET, komplexe Windows;
allgemeines JSON/XML, EXPLODE/UNNEST und komplexe Datentypen; String-
und Zeitoperationen außerhalb der Positivliste. Keine automatische
Umschreibung von CONVERT-Styles, TRY_CONVERT, LEN/CONCAT, DATEDIFF in beliebigen
Einheiten, GETDATE/NEWID/RAND oder allgemeinen Dezimal-/Floatausdrücken.

„Manuell“ heißt: Ursache und Anpassungsweg nennen, beispielsweise Parameter
aus einem DECLARE-Skript herauslösen, TVF als gesonderten relationalen Vertrag
bereitstellen oder eine fachliche Top-N-Auswahl festlegen. Nach der Anpassung
erneut vollständig prüfen. Eine Warnung erlaubt kein unvollständiges
`converted`. Prozeduren sind grundsätzlich als spätere Funktion prüfbar;
ihre automatische Übersetzung gehört nicht in die erste Funktion.

## Abnahme und verbleibende Entscheidungen

Vorläufige technische Hülle: eine Abfrage, höchstens 256 KiB UTF-8-Eingabe,
16 CTEs, 64 Parameter, eine Korrelationsstufe und 1 MiB Ausgabe. Parser-/AST-
Tiefe und Prozesszeit benötigen vor Implementierung einen überprüfbaren
Grenzvertrag; Textlänge allein verhindert keinen Parser-Stackoverflow.
Diese Werte sind vorgeschlagene Eingabegrenzen, keine gemessene Kapazität.

Pflichtfälle der späteren Testabnahme:

1. Jede A-Regel und freigegebene K-Variante in beiden Richtungen an nativen
   Engines binden; keine Zusage nur aufgrund erfolgreicher Parserausgabe.
2. APPLY mit 0/1/vielen rechten Zeilen, NULL- und mehrspaltigen Schlüsseln,
   linken Duplikaten, eindeutigem Top-1/Top-N, negativen Tiefällen und einer
   gesondert aktivierten oder sicher abgewiesenen Cutoff-Capability.
   Die Herkunft rechter Filter und rn im ON statt WHERE gezielt prüfen.
3. Scalar COUNT/COUNT_BIG/MIN/MAX über leerer Eingabe, einschließlich CROSS
   APPLY; Normalisierung von Zähl- und ROW_NUMBER-Typen, Größen-/Überlaufgrenzen.
4. Ergebniswerte, Multiplizität, logisches Schema und definierte Ordnung
   vergleichen. Alias-/CTE-Schatten, NULL, Datumsränder, Stringvergleich und
   Präzisionsverlust gezielt mit festen Gegenbeispielen prüfen.
5. M-Konstrukte, Parser-Command-Fallback, fehlenden Kontext und Ressourcenfehler
   sicher ablehnen. Kein Keyword-REPLACE, kein Erhalt unübersetzter Fragmente
   als scheinbar gültiger Zielcode, keine Rohtext-/Parameterprotokollierung.
6. Performancevarianten unabhängig von semantischer Gleichheit qualifizieren;
   fehlende Databricks-Testumgebung durch keinen DuckDB-/Spark-Lauf ersetzen.

Offen bleiben das konkrete verfügbare Databricks-Testprofil, Lizenz-/Security-
geprüfter Providerpin, endgültige Ressourcen-/Fehler-API und benötigte
K-Domänenverträge. Der Benutzer hat die Konkretisierung beauftragt; eine
anschließende ausdrückliche Implementierungsfreigabe liegt weiterhin nicht vor.
Finale TC-/AP-Referenzvergabe folgt unverändert `DEC-2026-028`.
