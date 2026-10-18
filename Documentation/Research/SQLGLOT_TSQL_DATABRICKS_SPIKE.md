# SQLGlot-Spike: T-SQL ↔ Databricks SQL

Stand und tatsächliche Ausführung: 2026-10-16 · Autor: Codex.
Status: begrenzter lokaler Provider-Spike ausgeführt; V1 weiterhin `researched`.
Dies ergänzt den [V1-Vertragsvorschlag](TSQL_DATABRICKS_V1_SCOPE_PROPOSAL.md).
Keine Implementierungsfreigabe für ein Toolbelt-Modul oder einen produktiven
Transpiler; keine SQL-Server-/Databricks-Verbindung oder Infrastrukturänderung.

Anschließender Benutzerauftrag vom 2026-10-16:
Die [Erweiterung mit eigenen AST-Regeln](SQLGLOT_TSQL_DATABRICKS_RULE_SPIKE.md)
prüft inzwischen 140 Eingaben und 42 Roundtrips. Die späteren
[nativen SQL-Server-](SQLGLOT_NATIVE_TSQL_LAB_PROBE.md) und [Spark-Prüfungen](SQLGLOT_NATIVE_SPARK_PROBE.md)
sowie die [teilweise qualifizierte Performancewelle](SQL_DIALECT_PERFORMANCE_PROBE.md)
sind eigene Nachweise; die folgende Tabelle beschreibt allein die Providerbaseline. Die nachfolgenden 32
Providerbefunde bleiben historische Baseline des unveränderten SQLGlot-Aufrufs.

## Ergebnis

**SQLGlot ist ein brauchbarer Syntax-/AST-Baustein für V1, aber Version
30.23.0 erfüllt den bidirektionalen Vertrag nicht ohne zusätzliche Regeln.**
Insbesondere funktioniert die direkt getestete LATERAL→APPLY-Rückrichtung
nicht automatisch. Typen, Parameter, Limits und die Prüfung nicht unterstützter
Konstrukte brauchen eine eigene kontrollierende Schicht.

Der [reproduzierbare Harness](../../Tests/Research/SqlDialect/README.md) enthält
32 feste eigene SQL-Eingaben: 18 T-SQL→Databricks und 14 Gegenrichtungen.
Er verwendet striktes Source-Parsing und strikte Zielgenerierung, danach den
SQLGlot-Zielparser. Kein generiertes SQL wurde ausgeführt. Kein Optimizer,
Schema-Binder, `annotate_types` oder allgemeines Dekorrelationsverfahren wurde
zugeschaltet. Die Ergebnisse gelten exakt für diesen Pin und Aufrufpfad.

| Ausgeführte Prüfung | Ergebnis | Bedeutung / Grenze |
|---|---|---|
| 18 T-SQL→Databricks-Eingaben | 17 generiert und wieder geparst; 1 erst beim Zielparser abgewiesen | Darunter problematische Ausgaben; keine Erfolgsquote semantischer Konvertierung |
| 14 Databricks→T-SQL-Eingaben | 9 generiert und wieder geparst; 5 bei LATERAL-Generierung abgewiesen | Bestimmte relationale Formen funktionieren syntaktisch, direkte LATERAL-Rückrichtung fehlt |
| Beobachtungsassertions | 34 bestanden | Sichern auch bekannte Fehler-/Grenzfälle; kein pauschales PASS der Statements |
| Zwei feste AST-Normalisierungsversuche | Beide nach T-SQL generiert und wieder geparst | Begrenzter Machbarkeitsbeleg einer eigenen Rückrichtungsregel |
| Negative Kontrolle: zusätzliches ON-Prädikat | Vom festen AST-Versuch abgewiesen | ON darf nicht blind entfernt werden |
| Native SQL-Engine-/Ergebnis-/Metadatenparität | `not executed` | Auch ein erfolgreiches erneutes SQLGlot-Parsen ersetzt keinen Engineparser/Binder |
| SQL-Laufzeit, Querypläne und Performance | `not executed` | Keine Beschleunigung, Kapazitäts- oder Ressourcenbehauptung |

## Was syntaktisch funktioniert

| Synthetische Fixturefamilie | Beobachtung | Noch notwendige Grenze |
|---|---|---|
| `cte-join`, beide Richtungen | CTE und LEFT JOIN werden generiert und wieder geparst | Keine Tabellen-/Spaltenbindung oder Werteprüfung |
| `ordered-top3`, beide Richtungen | TOP (3) mit ORDER BY wird LIMIT 3; LIMIT 3 wird TOP 3 | Eindeutigkeit und Auswahlsemantik nicht durch den Parser bewiesen |
| `window-top3`, beide Richtungen | Vorgegebene ROW_NUMBER-CTE und rn<=3 im LEFT-JOIN-Prädikat bleiben erhalten | Das Ranking war bereits Eingabe, es wurde nicht automatisch aus APPLY hergeleitet |
| `qualify/databricks` | Einfaches QUALIFY wird in eine Unterabfrage mit Hilfsspalte und äußerem WHERE überführt | Nur der konkrete Fall geprüft; öffentliche Spalten und Ergebnistypen benötigen eigene Prüfung |
| `outer-simple`, `cross-simple`, `outer-top1`, `outer-cutoff`, `scalar-count` aus T-SQL | SQLGlot erzeugt jeweils eine laterale rechte Relation | Keine Zusage der nativen Databricks-Korrelation oder tatsächlicher Ergebnisse |
| INT/BIGINT/DATE-/DECIMAL-Projektionen in `casts` | Zielsyntax wird erzeugt; DECIMAL(12,2) bleibt mit Precision/Scale erhalten beziehungsweise heißt NUMERIC(12,2) | Keine allgemeine Cast-, Decimalrechen- oder Overflowparität bewiesen |
| Databricks COUNT(*)→T-SQL | SQLGlot erzeugt selbst COUNT_BIG(*) | In dieser Richtung ist der erwartete 64-Bit-Zähltyp bereits berücksichtigt |

## OUTER APPLY und Top-N im Detail

Der synthetische Input `outer-top1/tsql` hat die Struktur:

```sql
SELECT p.ParentId, r.EventId
FROM Parent p
OUTER APPLY
(
    SELECT TOP (1) e.EventId
    FROM Event e
    WHERE e.ParentId = p.ParentId
    ORDER BY e.EventId DESC
) r;
```

Die beobachtete Generatorform ist ein `LEFT JOIN LATERAL` mit derselben
Korrelation und `LIMIT 1`. Eine Window-Dekorrelation findet in diesem
Aufrufpfad nicht statt. Der Generator schreibt dabei kein ausdrückliches
`ON TRUE`; der SQLGlot-Databricks-Parser setzt beim erneuten Parsen intern
ein wahres ON-Prädikat ein. Das beweist keine native Engineakzeptanz.
Für den geplanten Toolbelt-Vertrag soll die geeignete laterale Form ausdrücklich
und nach nativer Zielqualifikation erzeugt werden.

Der unabhängig vorgegebene Databricks-Input mit `LEFT JOIN LATERAL (...) r
ON TRUE` scheitert dagegen im strikten T-SQL-Generator: LATERAL wird nicht
unterstützt. Dasselbe gilt für die fünf getesteten lateralen Rückrichtungen,
einschließlich CROSS JOIN LATERAL, Top-1, Cutoff und skalarer Zählung.

Die lokale Inspektion der gepinnten Generatorimplementierung erklärt den
Unterschied: Die T-SQL-APPLY-Eingabe setzt am Lateral-Knoten `cross_apply` auf
false beziehungsweise true; die explizite Databricks-LATERAL-Eingabe setzt
diesen Marker nicht. Der T-SQL-Generator kann den Marker ausgeben, leitet ihn
aber in diesem Pfad nicht aus dem umgebenden Join ab.

Zwei feste Researchversuche kopieren den Joinbegriff ausdrücklich auf diesen
Marker und entfernen nur die bereits geprüfte neutrale Joinhülle:

- LEFT + ON TRUE erzeugt wieder OUTER APPLY mit TOP 1.
- CROSS ohne ON erzeugt CROSS APPLY.
- Ein zusätzliches `ON r.EventId > 0` wird durch die negative Kontrolle
  abgewiesen, nicht entfernt.

Das ist ein kleiner AST-Machbarkeitsbeleg und keine allgemeine Übersetzungsregel.
Aliasscope, Bindung, TVF, andere Joinarten, Nichtdeterminismus und mehrere
Korrelationsstufen sind damit nicht qualifiziert.

Für `outer-cutoff` bleibt `e.EventTime <= p.CutoffTime` in der Hinrichtung
textlich erhalten. Das ist **kein Nachweis**, dass Databricks die konkrete
korrelierte ORDER-BY-/LIMIT-Form akzeptiert oder effizient plant. Eine automatische
Ersetzung durch globales Ranking je ParentId wäre weiterhin unzulässig.
Die [Databricks-Korrelationsgrenzen](https://docs.databricks.com/aws/en/error-messages/unsupported-subquery-expression-category-error-class)
sind erst an einem ausgewählten nativen Ziel zu prüfen.

## Datentypen: brauchbare Abbildung und konkrete Lücken

| Probe | Beobachtung des gepinnten Generators | Eigene Regel / native Gegenprobe |
|---|---|---|
| T-SQL COUNT(*) und COUNT_BIG(*) | Beide werden zu Databricks COUNT(*), ohne Ergebniscaste | 32-Bit-COUNT von 64-Bit-COUNT_BIG unterscheiden; Kontext, Ergebnistyp und Overflowvertrag erhalten |
| Databricks COUNT(*) | Wird T-SQL COUNT_BIG(*) | Diese vorhandene Regel erhalten; nicht nochmals pauschal zu COUNT umschreiben |
| SUM(INT), AVG(INT), ROW_NUMBER | Im Test keine explizite Kompensation der unterschiedlichen nativen Rückgabetypen | Eigene Typ-/Wertebereichsregeln; AVG und allgemeine Decimalarithmetik bleiben außerhalb des ersten automatischen Profils |
| T-SQL TINYINT mit 255 | Wird SMALLINT | Sinnvolle Verbreiterung des unsigned T-SQL-Wertebereichs; Ausgabeform beobachtet, nicht nativ ausgeführt |
| Databricks TINYINT mit -1 | Bleibt T-SQL CAST(-1 AS TINYINT) | Signed/unsigned-Domäne nicht erhalten; nach SMALLINT abbilden oder blockieren. [T-SQL integer types](https://learn.microsoft.com/en-us/sql/t-sql/data-types/int-bigint-smallint-and-tinyint-transact-sql?view=sql-server-ver17) erlauben für TINYINT keine negativen Werte. |
| DATETIME2(7) | Wird TIMESTAMP ohne explizite Präzision oder NTZ-Profil | Keine Präzisions-/Zeitzonenäquivalenz zusagen; eigenes geprüftes Zeitprofil erforderlich |
| TIMESTAMP_NTZ | Wird DATETIME2 ohne explizite Präzision | Gemeinsamen Wertebereich und Präzision festlegen; kein Beweis aus den Typnamen |
| NVARCHAR(3), VARCHAR(3) | Beide werden VARCHAR(3) | Unicode-, Längen-, Trunkierungs- und Collationvertrag prüfen; Parserausgabe beweist keine identischen Castregeln |
| Databricks STRING | Wird VARCHAR(MAX) | Zeichenvorrat/Codepage und Längenvertrag für SQL Server ausdrücklich bestimmen |
| BIT/BOOLEAN | Werden syntaktisch auf BOOLEAN beziehungsweise BIT abgebildet | Unterschied zwischen Prädikat und Wert, NULL und Zahlenkonvertierungen weiterhin prüfen |
| DATEADD(day,2,DATE) aus T-SQL | Bleibt in Databricks die dreistellige DATEADD-Form | [Databricks DATEADD](https://docs.databricks.com/aws/en/sql/language-manual/functions/dateadd) liefert TIMESTAMP; für den V1-DATE-Vertrag gezielte date_add-Tagesregel statt bloßer Defaultgenerierung |
| DATEDIFF(day,DATE,DATE) aus T-SQL | Dreistellige DATEDIFF-Form mit zusätzlichen TIMESTAMP-Casts | Ergebnisbreite, Grenzzählung und Zeitprofil prüfen; für reines DATE die gewünschte zweistellige Tagesform gezielt erzeugen |

Die Typdifferenzen sind teilweise durch die vorangegangene
[V1-Primärquellenprüfung](TSQL_DATABRICKS_V1_SCOPE_PROPOSAL.md#automatisierungsmatrix-des-ersten-umfangs)
belegt; der Spike zeigt, welche Syntax SQLGlot tatsächlich erzeugt. Er hat
keine nativen Werte, Clientmetadaten oder Overflowfälle ausgeführt. Insbesondere
ist die Aussage „keine Defaultkompensation gesehen“ kein Beweis, dass zusätzliche
SQLGlot-Analyse-/Optimizer-APIs solche Fälle grundsätzlich nicht unterstützen.

## Fälle, die strikte Fehleroptionen allein nicht absichern

| Probe | Beobachtung | Konsequenz für V1 |
|---|---|---|
| TOP WITH TIES / TOP PERCENT | Werden LIMIT 2 WITH TIES / LIMIT 10 PERCENT; derselbe SQLGlot-Zielparser akzeptiert beide | Die [dokumentierte Databricks-LIMIT-Grammatik](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-qry-select-limit) enthält diese Zusätze nicht. Eigene Ablehnung vor dem Generator; kein syntaktischer PASS allein aus SQLGlot |
| TOP ohne ORDER BY | Wird problemlos LIMIT 1 | Eindeutige Auswahl bleibt eine eigene V1-Anforderung; fehlende Ordnung wird nicht automatisch als Kontextlücke erkannt |
| NOLOCK | Wird ohne Warnung entfernt | Eigener Input-Gate; Isolation/Hint nicht still verlieren. RAISE ist keine Garantie gegen jede gelöschte Klausel. |
| Unbekannte Funktion ContosoScore | Wird in beiden Richtungen mit Funktionsnamen ausgegeben | Eigene Funktions-Positivliste und gegebenenfalls expliziter Adapter nötig |
| PRINT als Command-Fallback | Source-Parser liefert trotz RAISE einen Command-Knoten; Generator reicht den Text durch; erst Ziel-Reparse scheitert | Command-Knoten schon beim Source-Gate ablehnen; Beispiel ist kein SELECT und kein unterstützter V1-Pfad |
| Parameter @ParentId | Wird `${ParentId}` statt geplantem `:ParentId` | Typisierter Parameteradapter nötig; [Databricks named markers](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-parameter-marker) verwenden Doppelpunkt |
| Parameter :ParentId in Databricks | Bleibt :ParentId im T-SQL-Text; SQLGlot-Zielparser akzeptiert ihn | T-SQL-Variablen-/Hostbinding explizit erzeugen; Parser ist kein Treibervertrag |
| Katalog-/Schemanamen | dbo beziehungsweise main.default bleiben erhalten | Explizites Quell-/Zielmapping; keine automatische fachliche Namenszuordnung |

Ein geglückter Roundtrip wäre keine Ergebnisprüfung. Hier scheitern zudem die
fünf APPLY-Hinübersetzungen bereits bei der strikten Generierung ihrer
Rückübersetzung; diese Fehler stehen separat im lokalen Bericht.

## Folgerung für V1 und Performance

Empfohlen bleibt SQLGlot als austauschbarer Parser-/Generatorprovider.
Zusätzlich erforderlich sind zunächst:

1. Vollständiger Source-Gate für genau eine lesende Abfrage, erlaubte Nodes,
   Funktionen, Limitoptionen und Hints; Command-/unveränderten Fremdtext ablehnen.
2. Namens-/Aliasbindung und typisierter Kontext inklusive Parameter-,
   Namespace-, Vergleichs- und Zeitprofilen.
3. Begrenzte LATERAL→APPLY-Normalisierung und ausdrückliche Behandlung neutraler
   Joinbedingungen; keine allgemeine Beseitigung von ON-Prädikaten.
4. Eigene Ergebnis-/Castregeln besonders für TINYINT, COUNT, Ranking, SUM/AVG,
   Text und DATE-/Timestampoperationen.
5. Separat besprochene Top-N-/Voraggregationsregeln mit festen semantischen
   Orakeln, einschließlich NULL, Duplikaten, Ties und leerer skalarer Aggregation.
6. Native Parser-/Binder-/Differentialtests auf beiden ausgewählten Engines,
   anschließend Performancequalifikation der tatsächlichen Varianten.

Der Spike belegt keine automatische leistungsorientierte Dekorrelation.
Die Window-CTE wird nur übertragen, wenn sie bereits in der Eingabe steht;
APPLY bleibt lateral. Das ist kein Mangelbeweis für alle SQLGlot-Optimizer,
sondern die Grenze des getesteten Defaultpfads. Ob native LATERAL-Optimierung
oder eigener mengenorientierter Rewrite günstiger ist, bleibt ohne native
Läufe unbekannt. Kein künstlicher Mikrobenchmark dieser kleinen Parserfälle
wird als Queryperformance ausgegeben.

## Dependencyprüfung und Reproduzierbarkeit

| Feld | Geprüfter Stand |
|---|---|
| Bibliothek / exakte Version | SQLGlot 30.23.0; [versionierte PyPI-Seite](https://pypi.org/project/sqlglot/30.23.0/) |
| Variante | Pure Python, `sqlglot-30.23.0-py3-none-any.whl`; keine Extras oder weiteren Runtimepakete |
| Öffentlicher Wheel-SHA256 | `b5a645722cb4c6b649e9131b94830d9df9a557e87be63713179d848320f2baa1`; Download dagegen geprüft, zusätzlich in requirements gebunden |
| Lizenz | MIT laut Paketmetadaten und [Upstream-Lizenz](https://github.com/tobymao/sqlglot/blob/main/LICENSE); kein Upstreamcode/Binary in das Repository aufgenommen |
| Securityprüfung | [OSV-API](https://osv.dev/docs/) am 2026-10-16 nach Paket und exakter Version abgefragt: keine Vulnerability-IDs zurückgegeben. Kein allgemeiner Sicherheitsnachweis; synthetische kontrollierte Eingaben. |
| Wartung / Verfügbarkeit | PyPI-Metadaten und Upstream am Prüfdatum erreichbar; exaktes Releaseartefakt lokal bezogen. Langfristige Verfügbarkeit nicht garantiert. |
| Verwendung | Ausdrücklich beauftragter isolierter lokaler Test; kein neues Runtime-Modul, keine DB-Engine oder SQLGlot-Extras installiert |
| Python / Plattform | Python 3.14.7, Windows; Linux nicht ausgeführt |
| Exit | Harness und synthetische Fixtures bleiben providerbezogen und getrennt von Modulen. Ein späterer Providerwechsel erfordert neue Charakterisierung; kein Runtime-Lock-in durch diesen Spike. |

Ausgeführt wurde der in der [Harness-Anleitung](../../Tests/Research/SqlDialect/README.md#reproduktion)
genannte `run_spike.py --output ...` mit dem gepinnten Interpreter.
Der erste explorative Durchlauf und die anschließenden Korrekturen an den
Beobachtungserwartungen sind keine zusätzlichen Enginequalifikationen.
Maßgeblich ist der finale Lauf mit 32 Fällen und 34 bestandenen Assertions.
Rohberichte, Parserdiagnostik, installierte Pakete und öffentliche Artefakte
bleiben im ignorierten lokalen `.runtime/`-Bereich. Versioniert werden nur
eigene synthetische Fixtures, Harness, Pin und diese fachliche Zusammenfassung.

Die Prüfung verändert keine Governance oder CI-Workflowdatei und führt keine
neuen Dienste/Modellaufrufe ein. Der Spike läuft ausdrücklich manuell; keine
Paketinstallation in jeder bestehenden Modulprüfung. Neue nicht registrierte
Research-Codepfade lösen im vorhandenen Dokumentationsvalidator dessen
konservativen Vollaudit aus; eine spätere schlanke Impactregistrierung wäre
ein eigener Integrationsschritt, keine Voraussetzung für diesen manuellen
Providerbefund. Es wird keine Token-/Kostenmessung behauptet.

## Lokale Repositoryprüfung

Am 2026-10-16 wurde zusätzlich
`python Tests/Documentation/validate_documentation.py --all` auf dem aktuellen
Arbeitsbaum erfolgreich ausgeführt, einschließlich Markdown-Links und
statischer Konsistenzprüfungen. Der konservative Vollscope berücksichtigt die
neuen Research-Code-/Pinpfade. Zwei POSIX-spezifische Foundation-Handle-Tests
werden unter Windows gemäß ihrem bestehenden Skipvertrag ausgelassen; dies
ist kein PASS dieser Plattformfälle und keine SQL-Enginequalifikation.
Der Harness wurde zusätzlich auf Python-Syntax und die Ablehnung eines
Berichtsziels außerhalb `.runtime/` geprüft; beide Prüfungen bestanden.
`git diff --check` war erfolgreich. Änderungen an dieser abschließenden
Evidenzprosa benötigen keine erneute Ausführung der unveränderten Providerfälle.
