# Repository-Grenzen

## SQL Server Toolbelt

`gecompat/SQL_Server_Toolbelt` enthält:

- modulare, wiederverwendbare SQL-Server-Capabilities ab SQL Server 2019;
- Source, Deployment, Dokumentation, Beispiele und Tests dieser Module;
- Architektur-, Engineering- und AI-Steuerungsregeln;
- getrennte Kandidaten-Backlogs.

## Abgrenzung zu SQL Server Analyze

`gecompat/SQL_Server_Analyze` ist fachlich zuständig für:

- Performance- und Wait-Analysen;
- Konfigurations- und Infrastrukturbeurteilung;
- Diagnose laufender oder historischer Zustände;
- Security Assessments und Findings.

Solche Inhalte werden nicht im Toolbelt implementiert. Vor Aufnahme eines Analyze-Kandidaten wird das Ziel-Repository nach Möglichkeit lesend auf vorhandene oder gleichwertige Funktionalität geprüft. Das Toolbelt-Repository ändert das Ziel-Repository nicht ohne ausdrücklichen Auftrag.

### Fachliche Zuordnung der Grenzfälle

Die Abgrenzung konkretisiert [DEC-2026-011](./DECISIONS.md#dec-2026-011-repository-grenze-zu-sql-server-analyze). Entscheidend ist die fachliche Aufgabe: Allgemeine Daten-, Parser-, Transformations- und Ausführungshilfen gehören in Toolbelt. Die Bewertung eines betrieblichen Zustands, laufende Überwachung und daraus abgeleitete Findings gehören in Analyze. Eigene Statusanzeigen, Syntaxfehlerlisten und Funktionsprüfungen begründen für sich keine Verschiebung.

| Toolbelt-Bereich | Aufgabe im Toolbelt | Diagnoseanteil in Analyze |
|---|---|---|
| Event Log | Übergebene Ereignisse persistieren, lesen und explizit löschen. `VW_Events` projiziert die eigene Ereignistabelle. | Fehlerhäufigkeiten, Trends, Alarmregeln und Ursachen bewerten. |
| Work Queue, Heartbeat und Recovery | Eigene Arbeitspakete, Claims, Leases, Retries und Ausführungsbarrieren steuern. `VW_WorkQueueBarrierBlockers` beschreibt Arbeitspakete innerhalb einer Barriere. | Rückstau, Fehlerraten oder festhängende Worker diagnostizieren; SQL-Locks und Blocking-Ketten analysieren. |
| Capability Catalog | Toolbelt-Modulmarker der aktuellen Datenbank lesen und formal prüfen. | Instanzübergreifende Installations-, Versions-, Drift- oder Gesundheitsbewertung durchführen. |
| Execution Context, Cancellation, Error Envelope und Console Message | Korrelationskontext, kooperative Abbruchanforderungen, übergebene Fehler und Meldungen verarbeiten. | Betriebszustände über diese Hilfsfunktionen hinweg bewerten. |
| Second Session und Probe | Registrierte Arbeiten ausführen und den eigenen Provider prüfen. | Unabhängige Session- und Betriebsdiagnose durchführen. |
| T-SQL-Parser und Transformation | Syntax, Tokens, Referenzen und Syntaxfehler extrahieren sowie definierte Transformationen unterstützen. | Lint-Regeln, Bad-Practice-Bewertungen und Findings anwenden. |
| Vergleich, Fingerprints und Introspektion | Übergebene Zustände vergleichen und neutrale Metadaten für Generatoren oder Dokumentation liefern. | Schemaänderungen überwachen, betriebliche Baselines bewerten und Risiken ableiten. |

Der Migration-Idempotency-Verifier bleibt Toolbelt-Qualitätssicherung: Seine Driftprüfung untersucht das eigene Deployment und Uninstall in synthetischen Testdatenbanken. Sie ist keine installierte Überwachungsfunktion.

Die statische Gegenprobe vom 2026-09-11 umfasst Toolbelt [`f4fe237`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/f4fe23721b203a2e540a7b421024e9cbd85f5f85) und Analyze [`6e46adc`](https://github.com/gecompat/SQL_Server_Analyze/commit/6e46adc22bb5deb6f6c14cd670d8f4023db44ce6). Sie ergab keinen belegten Kandidaten für eine Codeverschiebung. Diese Zuordnung ist kein neuer SQL-Laufzeitnachweis und ändert keine öffentlichen Verträge oder Modulstatuswerte.

## Azure

Azure SQL Database, Azure SQL Managed Instance und andere Azure-Produkte sind nicht automatisch unterstützt. Jede Capability benötigt eine eigene Prüfung von verfügbaren Features, Berechtigungen, Deployment und Plattformgrenzen.

## Öffentliche Referenzen und verbotene Repository-Inhalte

Fachlich relevante, öffentlich bekannte Organisations- und externe Projektnamen sowie öffentliche Quellen-, Projekt- und Dokumentations-URLs dürfen im Repository verwendet werden. `gecompat` und `Gerhard Pisch` sind ausdrücklich freigegeben.

Verboten bleiben:

- personenbezogene oder sensible Daten;
- interne oder vertrauliche Firmen-, Kunden-, Organisations- oder Projektdaten;
- Original-Tabelleninhalte aus realen Umgebungen, Produktionsdaten, Backups oder Exporte;
- nicht öffentliche Server-, Datenbank-, Domain-, Endpoint-, URL-, Netzwerk- oder Pfadangaben;
- reale Logs, Traces, Execution Plans oder Runtime-Evidence;
- konkrete Hardware-, Kapazitäts-, Inventar- oder Umgebungswerte von Remote Runnern;
- Secrets und private Schlüssel.

## Cross-Repository-Regeln

- Kein anderes Repository ohne ausdrücklichen Auftrag ändern.
- Fehlende Capability im zuständigen Repository als Gap dokumentieren, nicht stillschweigend dort implementieren.
- Keine parallele allgemeine Implementierung derselben Capability in mehreren Repositories.
- Austausch zwischen Repositories erfolgt über dokumentierte öffentliche Verträge oder geprüfte Backlog-Übergabe.

Die Diagnoseanteile aus Toolbelt werden im [Analyze-Intake unter WI-0010](https://github.com/gecompat/SQL_Server_Analyze/blob/main/AI_Metadata/Internal_Documentation/Research/SQL_Server_Diagnostic_Coverage_Landscape.md#toolbelt-übergabe) weitergeführt. Toolbelt erhält Quell-ID, Herkunft und Verweis; die ausführliche Diagnoseplanung bleibt in Analyze. Vor einer späteren Formalisierung sind vorhandene Implementierungen und Planungen erneut abzugleichen. Die Verknüpfung erzeugt weder ein zweites Arbeitspaket noch eine Implementierungsfreigabe.

Beide Repositories bleiben eigenständig. Eine lokale Nachbar-Arbeitskopie darf im autorisierten Arbeitsumfang verwendet werden; dauerhafte Verweise verwenden öffentliche Repository-URLs. Daraus entstehen weder ein Git-Submodul noch eine Runtime-Abhängigkeit oder eine automatische Installation.
