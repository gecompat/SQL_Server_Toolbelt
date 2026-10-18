# SQLGlot-Spike mit eigenen begrenzten AST-Regeln

Stand: 2026-10-17 · Autor: Codex · Status: beauftragte Research-Erweiterung
implementiert und lokal geprüft, V1 weiterhin `researched`.
Die [Providerbaseline](SQLGLOT_TSQL_DATABRICKS_SPIKE.md) bleibt unverändert
als eigener Befund erhalten. Die neuen Regeln liegen ausschließlich im
[Research-Harness](../../Tests/Research/SqlDialect/README.md); kein Modul,
keine SQL-CLR-/USP-Fassade und keine allgemeine V1-Schnittstelle.
Native Prüfungen waren beim ursprünglichen Regellauf `not executed`.
Die anschließend beauftragte [native Labprüfung](SQLGLOT_NATIVE_TSQL_LAB_PROBE.md)
hat inzwischen 81 T-SQL-Fälle auf sechs SQL-Server-Zielen erfolgreich
ausgeführt. Ergebnisse, NULL-Verhalten und deklarierte Clienttypen sind für
diesen Korpus bestätigt. Die [native Spark-Prüfung](SQLGLOT_NATIVE_SPARK_PROBE.md)
bestand zusätzlich mit 57 positiven und neun negativen Fällen. Die
[Performance-/Planprüfung](SQL_DIALECT_PERFORMANCE_PROBE.md) ist getrennt
`partially validated`; Databricks bleibt `not executed`. Die drei früheren
COUNT-/ROW_NUMBER-Roundtrip-Grenzen sind behoben.

## Folgewelle COUNT-/ROW_NUMBER-Roundtrips – 2026-10-17

Der Benutzer hat die drei offenen Rückübersetzungen ausdrücklich zur Korrektur
und erneuten nativen Prüfung beauftragt. Eigene begrenzte Ergebnistypregeln
erlauben nun INT-/BIGINT-Casts über skalares COUNT und einfaches ROW_NUMBER.
COUNT verlangt eine deklarierte Gruppengrenze 0..INT32_MAX, Ranking eine
eindeutige Spaltenordnung und eine Partitionsgrenze 1..INT32_MAX. Die
Castprüfung und die Breitennormalisierung verwenden dieselben Operand-/
Profilprüfungen. Ein geprüfter expliziter Ergebnistyp bekommt keinen weiteren
Cast untergeschoben. Allgemeine Ausdruckstypbindung bleibt ausgeschlossen.

Die beiden COUNT-Roundtrips ergeben in T-SQL CAST(COUNT_BIG(...) AS INTEGER)
und erhalten INT/System.Int32. Der Ranking-Roundtrip erhält BIGINT/System.Int64.
Die typisierten Parameter bleiben native Marker; ihre Verwendung wird auch
nach dem vollständigen Roundtrip geprüft. INT und INTEGER werden als
SQL-Typaliasse verglichen, Dimensionen und Typfamilien bleiben exakt.

| Richtung | Positive Umschreibungen | Unsupported | Requires context |
|---|---|---|---|
| T-SQL → Databricks | 22 | 35 | 15 |
| Databricks → T-SQL | 20 | 36 | 12 |
| Gesamt | 42 | 71 | 27 |

Die ursprünglichen 100 Eingaben bleiben erhalten. 40 neue feste Fälle prüfen
explizite INT-/BIGINT-Ergebniscaste in beiden Richtungen, Parameter und COUNT
über einer Nullable-Spalte sowie fehlende/boolesche/zu große Grenzen, fehlende
Eindeutigkeit, SMALLINT, Window-COUNT, direkte Castverschachtelung, geschachtelte
Aggregate, qualifizierte COUNT-Sterne und SUM. Alle 98 negativen Fälle geben
weiterhin weder Teil-SQL noch Parameter-/Typtrace aus.

Der aktuelle Lauf umfasst **140 Eingaben und 42 vollständige AST-Roundtrips
mit 852 bestandenen Assertions**. Der aktuelle native Lauf umfasst
**81 T-SQL-Fälle auf sechs Zielen, 486 bestandene Fallausführungen**. Die
[native Dokumentation](SQLGLOT_NATIVE_TSQL_LAB_PROBE.md#behobene-count-row_number-roundtrips--2026-10-17)
beschreibt NULL-/Leerfälle und Metadaten sowie die noch fehlende
Databricks-Ausführung. Das ist weiterhin ein interner Researchkern ohne
allgemeinen Schemabinder; Milliardenmengen sind nicht qualifiziert. Die separate
Performancewelle erweitert weder den Regelkern noch dessen Positivliste.

## Ursprünglicher Regellauf – 2026-10-16

SQLGlot 30.23.0, Python 3.14.7 unter Windows, dieselbe isolierte und zuvor
hashgeprüfte Testdependency. Keine weiteren Pakete, Datenbanktreiber oder
Dienste installiert. Eingaben und Kontextangaben sind eigene synthetische
Fixtures; keine fremden Skripte, realen Schemadaten oder Parameterwerte.

| Richtung | Positiv: umgeschrieben und wieder geparst | Negativ: außerhalb des Profils | Negativ: Kontext fehlt |
|---|---|---|---|
| T-SQL → Databricks SQL | 16 | 28 | 8 |
| Databricks SQL → T-SQL | 14 | 29 | 5 |
| Gesamt | **30** | **57** | **13** |

Der finale Regellauf umfasst **100 Fälle, davon 30 positive und 70 negative,
mit 476 bestandenen Assertions**. Jede Ablehnung liefert kein Teil-SQL und
keinen vorgetäuschten Parameter-/Regelvertrag. Positive Fälle prüfen den
Ziel-AST, die konkrete Umschreibung, Parameterverwendung, unveränderte
Wertliterale einschließlich NULL und erhaltene Relationsreferenzen. Der Status lautet bewusst
`rewritten_in_spike`, nicht vollständig validierte Konvertierung.

Die ursprünglichen 32 Providerfälle mit 34 Beobachtungsassertions wurden
zusätzlich unverändert erfolgreich erneut ausgeführt: weiterhin 26
Generator-/Reparse-Ergebnisse und 6 bekannte Ablehnungen. Die neuen Regeln
überschreiben keine SQLGlot-Providerimplementierung.

## LATERAL und APPLY

| Quelle | Eigene Umschreibung | Begrenzung |
|---|---|---|
| T-SQL OUTER APPLY (SELECT ...) r | LEFT JOIN LATERAL (...) r **ON TRUE** | Eine laterale Stufe, rechter SELECT, einfacher Alias |
| T-SQL CROSS APPLY (SELECT ...) r | CROSS JOIN LATERAL (...) r | Kein Outer-Verhalten hinzufügen |
| Databricks LEFT JOIN LATERAL (...) r ON TRUE | OUTER APPLY (...) r | Nur neutrale Bedingung; zusätzlicher Filter bleibt gesperrt |
| Databricks CROSS JOIN LATERAL (...) r | CROSS APPLY (...) r | Keine zusätzliche ON-Bedingung |

Die AST-Regel setzt den gepinnten `cross_apply`-Marker beziehungsweise die
passende Databricks-Joinhülle mit ausdrücklichem ON TRUE. Sie erweitert die
vorherigen zwei festen Rückrichtungsversuche. Positiv geprüft sind einfache
OUTER-/CROSS-Formen, Top-1 mit typisiertem Parameter und der Erhalt einer
Cutoff-Korrelation. Die Gegenrichtung liefert beispielsweise aus dem
synthetischen Teilstück

```sql
LEFT JOIN LATERAL
(
    SELECT e.EventId FROM Event e
    WHERE e.ParentId = p.ParentId AND e.EventId > :Floor
    ORDER BY e.EventId DESC LIMIT 1
) r ON TRUE
```

diese Form:

```sql
OUTER APPLY
(
    SELECT TOP 1 e.EventId FROM Event e
    WHERE e.ParentId = p.ParentId AND e.EventId > @Floor
    ORDER BY e.EventId DESC
) r
```

Ein vom Provider bei fehlendem ON ergänztes internes TRUE reicht nicht aus:
Auch der Tokenstrom muss unmittelbar nach dem Alias ein explizites ON TRUE
enthalten. Ein ablenkender ON-FALSE-Kommentar zählt dabei nicht als Bedingung.
Negativ geprüft sind fehlendes ON, zusätzliches `ON r.EventId > 0`, RIGHT-LATERAL,
nichtnative LATERAL-Syntax unter dem T-SQL-Profil und zwei laterale Stufen.
Keine Dekorrelation, Voraggregation oder Erfindung einer linken Zeilenidentität.
Der Cutoff-Test sichert nur den Erhalt von `e.EventTime <= p.CutoffTime`
und das Ausbleiben eines unsicheren Window-Rewrites. Die native
[Databricks-Korrelationscapability](https://docs.databricks.com/aws/en/error-messages/unsupported-subquery-expression-category-error-class)
ist damit nicht geprüft.

## Benannte Parameter

T-SQL `@Name` wird am AST zu Databricks `:Name`, rückwärts wieder zu `@Name`.
Der synthetische Kontext muss einen ausdrücklich unterstützten Quelltyp
deklarieren. Der Bericht enthält einmal je Name Quell- und Zieltyp; mehrere
Verwendungen desselben Parameters bleiben erhalten. Werte werden weder
entgegengenommen noch in Literale eingesetzt.

Geprüft sind Wiederverwendung, Parameter innerhalb von Top-1 und von einer
COUNT-Ergebnisumschreibung sowie unveränderter Literaltext wie
`'@ParentId :ParentId TOP (1) PERCENT'`. Parametertexte in Kommentaren
erzeugen ebenfalls keine Bindung. Fehlende Typen liefern `requires_context`;
Casekollisionen `p`/`P`, `@@SPID`, `?`, `${p}` und ungeprüfte Stringtypen
werden abgewiesen.

Das ist ein Parameterplan, kein ausgeführtes Treiberbinding. Quellwertebereiche
müssen bei späterer Bindung vor dem Senden eingehalten werden; ein verbreiterter
Zieltyp erzwingt die engere Quelldomäne nicht selbst. Grundlage bleibt die
[native Databricks-Markersyntax](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-parameter-marker).
Keine automatische Identifier-/Tabellennamenbindung.

## Datentypen und Ergebnistypen

Die ursprünglichen Castregeln gelten für prüfbare Literale einschließlich typisiertem NULL
oder gleich typisierte deklarierte
Parameter. Allgemeine Spaltencasts liefern `requires_context`, weil ein
Schemabinder fehlt. Ganze Tabellen-/Spaltenprojektionen werden nicht allgemein
typisiert.
Die Folgewelle vom 2026-10-17 ergänzt ausschließlich die oben beschriebenen
begrenzten COUNT-/ROW_NUMBER-Ergebnisse.

| Fall | Eigene Behandlung | Negative Gegenprobe |
|---|---|---|
| INT, BIGINT, SMALLINT | Gemeinsame Typen mit Prüfung gültiger Integerliterale | Überlauf und verlustbehaftete Eingaben abweisen |
| T-SQL TINYINT | SMALLINT; Quellwerte 0 und 255 geprüft | 256 vor der Verbreiterung abweisen |
| Databricks TINYINT | T-SQL SMALLINT; -128 und 127 geprüft | -129 vor der Verbreiterung abweisen |
| DECIMAL(p,s) | Gültige explizite Precision/Scale und exakt darstellbares Literal | 1.255→DECIMAL(12,2) wegen Rundung und 1000→DECIMAL(3,0) wegen Überlauf abweisen |
| DATE | Gültiges ISO-Literal im gemeinsamen Bereich | 2026-02-30 in beiden Richtungen abweisen |
| DATETIME2(0..6) → TIMESTAMP_NTZ | Nur mit zeitzonenlosem Sechserprofil und ohne Quellrundung | Präzision 7, Offset und fehlendes Profil abweisen |
| TIMESTAMP_NTZ(6) → DATETIME2(6) | Zielpräzision ausdrücklich erzeugen | Präzision 9 und Offset abweisen |
| T-SQL COUNT | Bei deklarierter Gruppengrenze innerhalb INT: CAST(COUNT(...) AS INT) | Fehlende oder zu große Grenze ergibt `requires_context` |
| T-SQL COUNT_BIG / Databricks COUNT | 64-Bit-Pfad erhalten; vorhandene Rückabbildung zu COUNT_BIG nutzen | COUNT_BIG nicht pauschal verengen |
| ROW_NUMBER | Hinrichtung Cast auf BIGINT, rückwärts auf INT; eindeutige Ordnung und begrenzte Partition erforderlich | Fehlende/zu große Partition und ROW_NUMBER ohne OVER abweisen |

Die Prüfung erfolgt **vor** einer Verbreiterung: Ein ungültiger Quellcast
darf nicht durch den großzügigeren Zieltyp plötzlich einen Wert liefern.
Für exakte Decimal-Literale werden deshalb Rundung und Präzisionsüberlauf
ausgeschlossen.

DATETIME2(3) mit genau drei Nachkommastellen ist positiv geprüft. Ziel ist
NTZ mit Präzision 6; die ursprüngliche Präzision steht im Typtrace. Eine
Rückübersetzung stellt deshalb nicht automatisch dieselben physischen
Quellmetadaten her. Ein sechsstelliger Wert mit nötiger Rundung auf
DATETIME2(3) wird abgewiesen.

Gruppen-/Partitionsgrenzen und Eindeutigkeit sind zugesicherte synthetische
Kontextannahmen. Sie wurden nicht aus Tabellen ermittelt und beweisen keine
beliebige spätere Datenmenge. Beim ursprünglichen AST-Lauf wurden native
Typen und Client-Nullability nicht an Engines geprüft; der nachfolgende
SQL-Server-Teilkorpus ist inzwischen separat nativ bestätigt. Databricks und
Überlaufverhalten außerhalb des begrenzten Profils bleiben ungeprüft.

## TOP/LIMIT und Eingabe-Gates

Im kleinen Regelprofil sind nur positive ganzzahlige Literale von 1 bis 1000
mit ausdrücklich deklariert eindeutiger ORDER-BY-Spaltenfolge zulässig.
Dies ist eine Researchgrenze, keine Kapazitätsaussage; größere Limits und
LIMIT 0 sind nicht grundsätzlich ungültiges SQL.

PERCENT und WITH TIES werden in beiden Richtungen vor der Ausgabe abgewiesen,
auch wenn SQLGlots Zieldialektparser sie akzeptiert. Negativ geprüft sind
außerdem parametrisierte und gebrochene Limits, fehlende Ordnung oder
Eindeutigkeit, 0, 1001 und OFFSET/FETCH. Kein Best-Effort-Ersatz durch
einfaches LIMIT; siehe die [Databricks-LIMIT-Grammatik](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-qry-select-limit).

Eine kleine AST-Positivliste sperrt unbekannte Funktionen, Hints,
Command-Fallbacks und mehrere Statements. NOLOCK und ein Databricks-
BROADCAST-Hint werden abgewiesen, statt unbemerkt zu verschwinden. SUM/AVG
bleiben gesperrt. Bei allen 70 negativen Fällen prüfen die Assertions
ausdrücklich, dass kein Teil-SQL und kein unvollständiger Parameter-/Typvertrag
ausgegeben wird.

## Verbleibende Grenzen

- Kein allgemeiner Scope-/Alias-/Schema-/Funktionsbinder oder Katalogmapping.
  Eine AST-Positivliste ersetzt diese Prüfungen nicht. Der Researchkern ist
  keine Schnittstelle für fremden SQL-Text und kein vollständiger V1-Validator.
- Keine native Zielversions-/Korrelationserkennung. Erzeugtes SQL benötigt
  weiterhin native Parser-/Binder- und Differentialtests mit Ergebnisorakeln.
- String-/Unicode-/Collation-/Trunkierungsregeln, BIT/BOOLEAN-Casts und deren
  Parametertypen bleiben gesperrt; auch National-Literale liegen außerhalb der Positivliste.
  Ebenso fehlen allgemeine Decimalarithmetik, SUM/AVG, zusätzliche Datumfunktionen,
  Floats, komplexe Typen und beliebige Castausdrücke.
- Keine allgemeine Top-N-Dekorrelation. Cutoff bleibt lateral; Performance
  und Planqualität sind unbekannt.
- Ausgeschlossen bleiben Prozeduren, DML/DDL, Temp-Tabellen, rekursive CTEs,
  mehrere LATERAL-Stufen, zusätzliche LATERAL-ON-Prädikate und allgemeine Window-Verträge.
- Nur feste kleine Fixtures: 16 KiB Eingabe, höchstens 64 benannte Parameter,
  eine laterale Stufe, Limits 1..1000. Parser-Stack-/Zeitgrenzen und fremde
  große Eingaben sind nicht qualifiziert; keine öffentliche Safety-API.

## Reproduktion und Evidenz

Die [Harness-Anleitung](../../Tests/Research/SqlDialect/README.md#eigene-regeln)
führt Providerbaseline und `run_rule_spike.py` separat aus. `rules_probe.py`
ist der kanonische Researchkern; Fixtureerwartungen und Ziel-AST-Prüfungen
liegen im separaten Runner. Der lokale JSON-Bericht bindet alle drei
Pythonquellen einschließlich des importierten Baselinehelfers und den Dependency-Pin über SHA256. Rohberichte bleiben unter
`.runtime/`; versioniert sind eigene synthetische Fixtures, Regeln und
fachliche Zusammenfassungen, keine Bibliothekskopien oder realen Runtimewerte.

Am 2026-10-16 bestanden der finale Regellauf mit 476 Assertions und der
erneute Baselinelauf mit 34 Beobachtungsassertions. Das sind Python-/AST-
Nachweise, keine 130 erfolgreich ausgeführten SQL-Statements und keine
vollständige V1-Qualifikation. Die beauftragte Regelspike-Erweiterung erteilt
keine automatische Implementierungsfreigabe für die gesamte Toolbelt-Funktion.

Zusätzliche lokale Prüfung am 2026-10-16: Python-Syntax beider neuen Dateien,
Bindung des Berichts an Quellen und Pin sowie die Ablehnung eines Berichtsziels
außerhalb `.runtime/` bestanden. `git diff --check` war erfolgreich.
`python Tests/Documentation/validate_documentation.py --all` lief erfolgreich;
zwei bestehende POSIX-Handle-Tests sind unter Windows gemäß Skipvertrag
ausgelassen. Dies ist kein PASS dieser Plattformfälle. Parallel laufende
Parser-/SSIS-Arbeiten bleiben außerhalb dieses Spike-Scopes; der Vollauditlauf
ist keine aktuelle fachliche oder Runtimequalifikation dieser fremden Änderungen.
