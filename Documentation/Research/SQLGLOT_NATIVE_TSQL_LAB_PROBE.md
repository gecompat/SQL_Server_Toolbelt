# Native T-SQL-Prüfung des SQLGlot-Regelspikes

Stand: 2026-10-17 · Autor: Codex · Status: **81 native T-SQL-Fälle auf sechs
Labzielen bestanden, insgesamt 486 erfolgreiche Fallausführungen**.
Databricks-Ausführung und authentifizierte TLS-Qualifikation bleiben
**`not executed`**. Die ergänzende
[Performance-/Planprüfung](SQL_DIALECT_PERFORMANCE_PROBE.md) ist getrennt
`partially validated`. Die gesamte V1 bleibt `researched`.

Der Benutzer hat die native Prüfung mit synthetischen Daten ausdrücklich
beauftragt und anschließend die Prüfung geeigneter Bereitstellungswege im
SQL_Server_Lab ergänzt. Dies erweitert den
[Regelspike](SQLGLOT_TSQL_DATABRICKS_RULE_SPIKE.md), erteilt aber keine
Implementierungsfreigabe für die gesamte V1 oder Änderungen an gemeinsam
genutzten Zertifikats-/Trustbindungen.

## Tatsächlicher Befund im SQL_Server_Lab

Die kanonische Discovery und Schema-Validierung waren erfolgreich. Die
ausdrückliche Auswahl umfasst SQL Server 2019, 2022 und 2025 jeweils unter
Linux mit `latest` und unter Windows mit `base` einschließlich der bereits
autorisierten CU-Äquivalenz. Sechs bereite Vertragsziele wurden gefunden.
Nach der unten beschriebenen Benutzerklarstellung bestanden SQL-Login,
Preflight und inzwischen alle 81 Fälle auf jedem Ziel. Die Ausführung verwendet
`TestPurpose=Functional`, Encrypt=True und den ausdrücklich schema-validierten
Trust-Override. Keine Zertifikats-/Truststore- oder Serverkonfigurationsänderung.
Wert-/Multimengen- und Metadatenvergleich gegen die Fallverträge bestanden;
die erfassten Metadaten waren auf allen sechs Zielen identisch. Alle 17
T-SQL-Quellmuster einschließlich der drei behobenen Roundtrips sowie deren
zusätzliche Datenvarianten lieferten dieselben Wertmultimengen wie die
Originale. Für COUNT-/ROW_NUMBER- und Nullable-Spalten-COUNT-Paare stimmen
auch sämtliche erfassten Clientmetadaten der beiden T-SQL-Enden überein.

## Historischer TLS-Blocker und Benutzerklarstellung

Der erste Lauf wies alle sechs Ziele vor SQL-Anmeldung mit
`TLS_CONTRACT_REJECTED` ab; damals wurde keine native Testabfrage ausgeführt.

Der Toolbelt-Helfer
[`New-LabConnectionString`](../../Tests/CI/run-lab-local.ps1)
verlangte zuvor pauschal `Encrypt=True` und `TrustServerCertificate=False`.
Der Lab-1.0-Vertrag liefert einen Trust-Override. Dieser Gatebefund war
kein beobachteter Zertifikats- oder fachlicher Abfragefehler.

Der Benutzer stellte anschließend ausdrücklich klar, dass unabhängige
Funktionalität mit dem vorhandenen Labzugang testbar bleiben muss. Die
[autoritative Testregel](../../AGENTS.md#fachliche-tests-und-transportqualifikation)
trennt deshalb `Functional` und `AuthenticatedTls`. Der erste Modus übernimmt
den validierten Labwert; der zweite verlangt weiter False. Die erfolgreiche
fachliche Ausführung belegt keine Serveridentitäts-/TLS-Qualifikation.

Die anschließende lesende Prüfung im Repository `gecompat/SQL_Server_Lab`
bestätigt eine Produktvertragslücke, keinen bloß veralteten Export:

- `Public/TestEnvironment.ps1` exportiert weiterhin beide TLS-Felder als true.
- `Schemas/test-environment.schema.json` schreibt im Vertrag
  `SqlServerLab.TestEnvironment/1.0` auch `trustServerCertificate: true` vor.
  Eine manuelle Änderung allein am JSON wäre schemawidrig.
- Eine neue Standardumgebung würde damit denselben Exportvertrag erhalten.
- Der Lab-Stream `TLS-001` und
  `Documentation/Project_Planning/TLS_001_ISOLATED_CA_DESIGN.md` beschreiben
  die isolierte Lab-CA, ausdrücklich freizugebenden Client-Trust und den
  koordinierten Nachfolgevertrag. Die vorhandenen privaten Anfrage- und
  Registryprüfer stellen noch keine Zertifikate oder authentifizierten
  Testumgebungen bereit. Die native TLS-Abnahme bleibt dort offen.

Das Lab wurde ausschließlich gelesen. Keine Umgebung, Zertifikate,
Truststoreeinträge, Serverkonfigurationen oder Exporte wurden verändert.
Die weiterhin separate TLS-Abnahme benötigt einen vom Lab bereitgestellten, schema-validen
und vom Toolbelt unterstützten authentifizierten Vertrag samt tatsächlicher
Clientqualifikation. Ein künftiger Lab-V2-Vertrag benötigt auch den passenden
Consumer-Cutover; das bloße Umbenennen einer Versionsangabe genügt nicht.

## Ausgeführter nativer Prüfumfang

[`build_native_cases.py`](../../Tests/Research/SqlDialect/build_native_cases.py)
erzeugt aus dem aktuellen Regelkern **81 feste T-SQL-Fälle**. Keine
gespeicherten alten Generatorergebnisse werden als aktuelle Eingabe verwendet.

| Gruppe | Umfang je Ziel | Native Ausführung |
|---|---|---|
| Databricks → T-SQL | 15 Quellmuster mit Varianten, insgesamt 33 | Auf sechs Zielen bestanden; Databricks-Quelle nicht nativ ausgeführt |
| T-SQL → Databricks → T-SQL | 17 Quellmuster mit Varianten: 24 Original-/Roundtrip-Paare, insgesamt 48 | Auf sechs Zielen bestanden; nur beide T-SQL-Enden ausgeführt |
| Noch am Regelgate abgewiesene T-SQL-Roundtrips dieses Korpus | 0 | Die drei bisherigen Blocker behoben |

CTEs und VALUES stellen ausschließlich eigene synthetische Relationen bereit.
Der erzeugte SELECT bleibt erhalten; seine Relationsnamen `Parent` und
`Event` binden an diese CTEs. Keine Tabellen, Datenbanken oder fachlichen
SQL-Objekte werden angelegt. Der Runner setzt nur eigene Sessionoptionen
und liest Resultsets und Metadaten. Verbindungen und Reader werden auch
im Fehlerpfad freigegeben; keine Infrastruktur wird gestartet.

| Vertrag | Im nativen Lauf bestätigtes synthetisches Orakel |
|---|---|
| OUTER APPLY / CROSS APPLY | Hauptfixture mit sechs linken Zeilen und sieben Events; 11 beziehungsweise 9 Ergebniszeilen, Duplikate zählen mit |
| Leere und fehlende Treffer | Leere Gesamtmenge sowie linke Zeilen ohne Events; OUTER erhält linke Zeilen, CROSS entfernt sie |
| NULL-Korrelation | NULL-Schlüssel treffen nicht aufeinander; NULL-Cutoff lässt keinen Zeitvergleich zu |
| Korrelierter Top-1 | Höchste EventId über Floor; Floor NULL und 999; kein Treffer erzeugt rechts NULL |
| Cutoff und gleiche Zeitstempel | Zwei linke Zeilen mit gleicher ParentId, aber verschiedenen Cutoffs, erwarten unterschiedliche Treffer 101 und 103; EventId entscheidet den Zeitgleichstand |
| Globaler Top-3 | Erwartete Folge 401, 301, 202; Reihenfolge wird ausdrücklich verglichen |
| Parameter | Echte SqlParameter mit SqlDbType.Int; Wiederverwendung, NULL und INT-Grenzwerte; keine Wertinterpolation |
| Datentypen | INT/BIGINT/SMALLINT, DECIMAL(12,2), typisiertes NULL, DATE, DATETIME2(6), COUNT_BIG und ROW_NUMBER-Ergebniscast |
| Clientmetadaten | Spaltenname, SQL-Typ, .NET-Typ, Decimal-Precision/Scale, Zeit-Scale und Literalbreite; AllowDBNull getrennt erfassen |

Alle Werte wurden mit dem handgeschriebenen relationalen Python-Orakel
verglichen. Ohne äußeres ORDER BY gilt Multimengenvergleich einschließlich
Duplikaten und NULL; nur der globale Top-3 hat ein Reihenfolgeorakel.
SQL-Typ und .NET-Typ müssen jeweils dem expliziten Fallvertrag entsprechen.
Ein tatsächlich ausgegebenes NULL darf den gemeldeten Metadaten nicht
widersprechen. Das qualifiziert noch keinen allgemeinen Nullability-Binder.

Bei zwei Roundtrips ist bereits im Vertrag eine physische Abweichung
vorgesehen und nativ bestätigt: T-SQL TINYINT wird SMALLINT, im Client
System.Byte → System.Int16; DATETIME2(3) kehrt als DATETIME2(6) mit demselben
Wert zurück. Gleiche Werte sind dafür keine identischen Quellmetadaten.

Databricks COUNT wird nativ als COUNT_BIG mit BIGINT/System.Int64 geliefert;
ROW_NUMBER nach dem Ergebniscast als INT/System.Int32. DECIMAL(12,2),
DATE und DATETIME2(6) bestätigen die deklarierten Typ-/Dimensionsverträge.
Der Reader meldet für COUNT_BIG und den gecasteten ROW_NUMBER-Ausdruck
AllowDBNull=True, obwohl die geprüften Ergebnisse keine NULLs enthielten.
Metadaten-Nullability und tatsächliche NULL-Werte bleiben getrennte Aussagen;
kein pauschaler Non-null-Vertrag wird daraus erzeugt.

## Behobene COUNT-/ROW_NUMBER-Roundtrips – 2026-10-17

Der Benutzer hat die Korrektur und erneute native Prüfung der drei zuvor mit
`integer_domain` abgewiesenen Roundtrips ausdrücklich beauftragt. Das frühere
Cast-Gate behandelte berechnete Ergebnisse ausschließlich wie ungeprüfte
Literale. Es erkennt jetzt eng begrenzt COUNT beziehungsweise ein einfaches
ROW_NUMBER-Fenster als Operanden eines INT-/BIGINT-Casts. Der explizite
Ergebniscaste bleibt erhalten; die Breitenregel fügt darunter keinen zweiten
Cast ein. Allgemeine Spalten- und Ausdruckscasts werden dadurch nicht geöffnet.

| Fall | Databricks-Zwischenausdruck | Erzeugter T-SQL-Rückausdruck | Nativ bestätigter Ergebnistyp |
|---|---|---|---|
| count-width | CAST(COUNT(*) AS INT) | CAST(COUNT_BIG(*) AS INTEGER) | INT / System.Int32 |
| count-parameter-copy | CAST(COUNT(:Value) AS INT) | CAST(COUNT_BIG(@Value) AS INTEGER) | INT / System.Int32 |
| ranking-width | CAST(ROW_NUMBER() OVER(ORDER BY ParentId) AS BIGINT) | CAST(ROW_NUMBER() OVER(ORDER BY ParentId) AS BIGINT) | BIGINT / System.Int64 |

INTEGER ist hier der SQL-Typalias für INT. Beide COUNT-Roundtrips erhalten
somit den ursprünglichen 32-Bit-Ergebnistyp; der Ranking-Roundtrip den
ursprünglichen 64-Bit-Typ. Die Primärverträge nennen
[COUNT als INT und COUNT_BIG als BIGINT](https://learn.microsoft.com/en-us/sql/t-sql/functions/count-transact-sql?view=sql-server-ver17)
und [T-SQL ROW_NUMBER als BIGINT](https://learn.microsoft.com/en-us/sql/t-sql/functions/row-number-transact-sql?view=sql-server-ver17).
Databricks dokumentiert [COUNT als BIGINT](https://docs.databricks.com/aws/en/sql/language-manual/functions/count)
und [ROW_NUMBER als INTEGER](https://docs.databricks.com/aws/en/sql/language-manual/functions/row_number).
Diese Databricks-Verträge sind weiterhin nicht durch eine eigene native
Databricks-Ausführung bestätigt.

| Synthetischer Fall | Bestätigtes Verhalten an beiden T-SQL-Enden |
|---|---|
| COUNT(*) über sieben Events, darunter NULL-Werte | 7, INT; leere Eingabe: eine Ergebniszeile mit 0 |
| COUNT(@Value), @Value=7 | 7; bei leerer Eingabe 0, jeweils INT |
| COUNT(@Value), @Value=NULL | 0 über befüllter und leerer Eingabe; kein NULL-Ergebnis |
| COUNT(ParentId) über dieselben Events | 6, weil eine ParentId NULL ist; leere Eingabe 0 |
| ROW_NUMBER über drei Zeilen | Drei Nicht-NULL-Ränge 1, 2, 3; auch mit einem NULL-Sortierschlüssel |
| ROW_NUMBER über leerer Eingabe | Keine Ergebniszeile; BIGINT-Metadaten bleiben vorhanden |

System.Data.SqlClient meldet bei diesen Original-/Roundtrip-Paaren
AllowDBNull=True, obwohl ihre geprüften COUNT-/Rankingwerte nicht NULL sind.
Die Metadaten einschließlich Nullability sind zwischen den Paaren und allen
sechs Zielen identisch. Dies ist ein Clientbefund im geprüften Sessionprofil,
kein allgemeiner Non-null-Schemavertrag.

**Weiterhin notwendige Grenzen:** COUNT-Ergebniscaste verlangen eine ausdrücklich
deklarierte ganzzahlige Gruppengrenze von 0 bis INT32_MAX. ROW_NUMBER verlangt
weiterhin eine einfache eindeutige ORDER-BY-Spaltenfolge und eine zugesicherte
Partitionsgrenze von 1 bis INT32_MAX. Damit passen die Werte in beide
Ergebnisbreiten. Fehlende, boolesche oder zu große Grenzen werden abgewiesen;
sie werden nicht aus Tabellen ermittelt. Native Fixtures erfüllen die
deklarierten Grenzen. Milliardenmengen und Überlaufverhalten außerhalb dieses
Profils sind nicht qualifiziert.

SMALLINT-Ergebniscaste, Window-COUNT, geschachtelte Aggregate/Casts, qualifizierte
COUNT-Sterne und SUM bleiben gesperrt. Es gibt keinen allgemeinen Typbinder.
Die Folgewelle ergänzt die ursprünglichen 100 AST-Fälle um 40 feste Fälle:
140 Eingaben, 42 positive Umschreibungen, 98 Ablehnungen ohne Teil-SQL sowie
42 erfolgreiche Roundtrips mit insgesamt 852 Assertions. Diese Parser-/
AST-Prüfung ist von den 81 nativen T-SQL-Fällen getrennt.

## Getrennt fehlende Databricks-Nachweise

Benutzerklarstellung vom 2026-10-17: Der Spike gehört zu SQL_Server_Toolbelt;
aktuell ist kein Databricks-Zugang vorhanden. Die folgenden Nachweise bleiben
deshalb ausdrücklich offen (`not executed`), ohne zusätzliche Infrastruktur
einzurichten. Der [Databricks-Prüfstand](SQLGLOT_NATIVE_DATABRICKS_PROBE.md)
dokumentiert den vorbereiteten Vergleich und die getrennten lokalen
Harnesskontrollen. Diese schließen keinen nativen Databricks-Nachweis.

Der anschließende [lokale Spark-Lauf](SQLGLOT_NATIVE_SPARK_PROBE.md) bestand
mit 57 positiven und neun negativen Fällen auf Apache Spark 4.0.2. Die Werte
stimmen mit den gebundenen T-SQL-Ergebnissen überein; Spark-SQL-Typen,
Python-Werttypen und abweichende Nullability-Metadaten sind dort dokumentiert.
Das ist ein zusätzlicher nativer Spark-Nachweis und schließt keine der
folgenden ausdrücklich Databricks-bezogenen Abnahmen.

| Nachweis | Status und benötigte Ergänzung |
|---|---|
| Native Annahme/Binden | `not executed`; festes SQL-Warehouse-/Runtimeprofil, Katalog und Sessionkontext erforderlich |
| LATERAL-Korrelation | `not executed`; OUTER/CROSS, korreliertes LIMIT und nichtgleichheitsbasierter Cutoff nativ prüfen |
| Ergebnis-/NULL-Parität | `not executed`; dieselben synthetischen Relationen, NULL-Parameter, leeren Eingaben und NULL-Sortierschlüssel auf Databricks ausführen und mit SQL Server vergleichen |
| Clientdatentypen | `not executed`; Integerbreiten, COUNT/ROW_NUMBER, Decimal, DATE/NTZ und tatsächlich gelieferte Nullability über einen festgelegten Client prüfen |
| Parameterbinding | `not executed`; :Name mit expliziten Typen, wiederverwendeten Markern, NULL und Randwerten über die gewählte API binden |
| Zeit-/Sessionsemantik | `not executed`; NTZ-Profil, Präzision, Zeitzonen-/ANSI-Einstellungen und Fehlerverhalten nativ belegen |
| Fehler- und Grenzfälle | `not executed`; Regeln lehnen vorab ab, liefern deshalb keinen Nachweis für Enginefehler, Rundung oder Überlauf |
| Databricks-Performance | `not executed`; die getrennte [SQL-Server-/Spark-Performancewelle](SQL_DIALECT_PERFORMANCE_PROBE.md) ist teilweise qualifiziert, ersetzt aber keine Databricks-Abnahme |

Der grüne SQL-Server-Lauf schließt keine Zeile dieser Tabelle.
Ein SQLGlot-Reparse ersetzt weder den Databricks-Parser/Binder noch einen
Ergebnisvergleich zwischen den beiden Engines. Die gesamte V1 bleibt `researched`.

## Reproduktion und bislang ausgeführte Prüfungen

Mit der bereits gepinnten SQLGlot-Testumgebung und PowerShell ab 7.5
(geprüft: Python 3.14.7, SQLGlot 30.23.0, PowerShell 7.6.6 unter Windows):

```powershell
pwsh -NoLogo -NoProfile -File Tests/Research/SqlDialect/run_native_lab.ps1 -SelfTest
pwsh -NoLogo -NoProfile -File Tests/Research/SqlDialect/run_native_lab.ps1
pwsh -NoLogo -NoProfile -File Tests/Research/SqlDialect/run_native_lab.ps1 -TestPurpose AuthenticatedTls -Output .runtime/sqlglot-spike-30.23.0/native-authenticated-tls-report.json
```

Der aktuelle Folgelauf vom 2026-10-17 wurde mit getrennten lokalen Berichten
für die AST- und native Prüfung ausgeführt:

```powershell
.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe Tests/Research/SqlDialect/run_rule_spike.py --output .runtime/sqlglot-spike-30.23.0/rules-roundtrip-2026-10-17.json
pwsh -NoLogo -NoProfile -File Tests/Research/SqlDialect/run_native_lab.ps1 -Output .runtime/sqlglot-spike-30.23.0/native-roundtrip-report-2026-10-17.json
```

140 Regelfälle/852 Assertions und 42 AST-Roundtrips bestanden; nativ bestanden
81 Fälle auf sechs Zielen. Der erste lokale AST-Entwicklungslauf verglich
Parametertypnamen lexikalisch und verwechselte INT mit INTEGER. Die Prüfung
vergleicht jetzt die geparsten Quelltypen einschließlich ihrer Dimensionen.
Parameterverwendung und Datentypen bleiben vollständig geprüft. Keine neue
Dependency und keine Änderung an Transport-, Infrastruktur- oder Trustverträgen.

Der Runner erzeugt den Korpus frisch, verwendet die kanonische Lab-Discovery,
Schema-Validierung, Zielauswahl und TLS-Regeln und schreibt ausschließlich
unter `.runtime/sqlglot-spike-30.23.0/`. Lokale Berichte binden die Quellen,
Fixtures, SQLGlot-Pin und den verwendeten Lab-Helfer über SHA256. Drift während
des Laufs invalidiert den Nachweis. Fehler enthalten nur begrenzte Codes,
keine Zugangsdaten, Connection Strings oder private Zieladressen.

Am 2026-10-16 bestanden die Korpuserzeugung einschließlich 57 T-SQL-Reparses
und der lokale Vergleicher-Selbsttest mit zwei positiven und acht negativen
Kontrollen. Letztere erkennen verlorene Duplikate, NULL→0, falsche Typen,
widersprüchliche Nullability, falsche Reihenfolge und falsche Typdimensionen.
Das sind lokale Harnessnachweise. Anschließend bestanden die 342 nativen
Fallausführungen im Fachmodus mit Exit 0. Der getrennte strenge Lauf endete
auf allen sechs Zielen vor Anmeldung mit `TLS_CONTRACT_REJECTED`, Exit 2.
Das ist eine bestandene Gatekontrolle, keine ausgeführte TLS-Liveabnahme.

Zwei vorangegangene native Läufe waren fehlerhaft: Zunächst verursachten
unbenutzte CTE-Hüllen bei reinen Cast-/Parameterabfragen SQL-Fehler 422.
Danach konvertierte der JSON-Reader ISO-Erwartungsstrings automatisch zu
DateTime und meldete fünf falsche Wertabweichungen. Der Harness ergänzt jetzt
nur benötigte Relations-CTEs und liest JSON mit `-DateKind String`. Die
SQL-Generatorregeln und Wert-/Typorakel wurden nicht gelockert. Erst der
korrigierte Gesamtlauf ist der native PASS. Rohberichte und reale Labdetails
werden nicht versioniert.

Zusätzlich bestanden die beiden negativen Berichtspfadprüfungen, die aktuelle
Quellbindung und `git diff --check`. Der vollständige lokale
`python Tests/Documentation/validate_documentation.py --all`-Audit lief
erfolgreich mit zwei bestehenden Windows-Skips. Das bestätigt keine nativen
Plattformfälle und keine parallel bearbeiteten Parser-/SSIS-/Klonfunktionen.
