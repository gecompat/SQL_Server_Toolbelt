# Recherche: SQL-Server-Toolbelt-Landschaft

**Status:** Research abgeschlossen

**Prüfdatum:** 2026-07-29

**Scope:** Öffentliche Projekte, die SQL Server um wiederverwendbare Funktionen, Prozeduren, Frameworks oder Skriptkataloge ergänzen

**Folge:** Dokumentation und Backlog-Erweiterung; keine Implementierungsfreigabe

## Ziel und Aussagegrenzen

Diese Recherche beantwortet vier Fragen:

1. Welche öffentlich sichtbaren Projekte verfolgen ein ähnliches Ziel wie SQL Server Toolbelt?
2. Welche Architektur-, Packaging- und Wartungsmuster haben sich dort herausgebildet?
3. Welche konkreten Vorbilder existieren für zweite Sessions, rollback-unabhängiges Logging, Parallelisierung, Console-Ausgabe, Error Handling und Gruppenabbruch?
4. Welche zusätzlichen Toolbelt-Themen sind durch den Vergleich belastbar erkennbar?

Untersucht wurden primär Projektseiten, Quellrepositories, Herstellerdokumentation und veröffentlichte Lizenztexte. Ein Projektname oder Link in diesem Dokument erlaubt keine Codeübernahme. Vor jeder Übernahme bleiben die Regeln aus
[THIRD_PARTY_AND_SOURCE_POLICY.md](../Standards/THIRD_PARTY_AND_SOURCE_POLICY.md)
verbindlich. Insbesondere sind Repository-Lizenz, Herkunft einzelner Dateien, Versionsstand und Kompatibilität getrennt zu prüfen.

Die Recherche beschreibt beobachtete Muster. Sie bewertet weder alle Funktionen eines Projekts noch dessen allgemeine Qualität. Aktivitäts- und Versionsaussagen beziehen sich auf den am Prüfdatum sichtbaren Stand.

## Kurzfazit

- Ein direktes Open-Source-Gegenstück als moderne, modulare und versionsübergreifende SQL-Server-Capability-Library ist selten.
- Die nächsten fachlichen Vergleichspunkte sind **SDU Tools**, **SQL#**, das ältere **T-SQL Toolbox** und Microsofts spezialisiertes **SQLServerSpatialTools**.
- Der größere Teil des Ökosystems besteht aus Testframeworks, kuratierten Skriptsammlungen, Diagnosepaketen, Maintenance-Lösungen oder externer Automation. Diese Projekte sind wertvolle Quellen für Muster und Ideen, aber kein Grund, Diagnose- oder Betriebsfunktionen in das Toolbelt zu ziehen.
- `tSQLt.NewConnection` ist ein konkretes öffentliches Vorbild für die Idee einer synchron geöffneten zweiten Session. Das Muster bestätigt die technische Machbarkeit, löst aber Security Context, Blockierung, Fehlerisolation und Haltbarkeitsgarantie nicht automatisch.
- Für Parallelisierung existieren mindestens vier ernsthafte Providerklassen: Service-Broker-Aktivierung, SQL-Server-Agent-Jobs, tabellenbasierte Queue-/Worker-Modelle und externe Orchestrierung. Keine davon ist für alle Zielplattformen und Workloads eindeutig überlegen.
- Erfolgreiche Projekte unterscheiden sich weniger durch die Anzahl kleiner Hilfsfunktionen als durch auffindbare Funktionen, konsistente Installation, Versionsauskunft, belastbare Tests, klare Abhängigkeiten und eine disziplinierte Scope-Grenze.
- Aus dem Vergleich entstehen zwei neue konkrete Toolbelt-Kandidaten: ein abfragbarer Capability-/Versionskatalog (`TC-2026-023`) und URI-Percent-Encoding/-Decoding (`TC-2026-024`). Der bereits vorhandene Base64-Kandidat `TC-2026-012` wird durch die aktuelle native SQL-Server-2025-Semantik präzisiert.

## Projektlandschaft

### Einordnung

| Projekt | Klasse | Technik und Packaging | Lizenz-/Statushinweis | Bedeutung für Toolbelt |
|---|---|---|---|---|
| [SDU Tools](https://sqldownunder.com/sdutools/) | direkte Capability-Library | T-SQL-Funktionen, -Prozeduren und -Views; ein Installationsskript je Datenbank; Schema wird je Release vollständig ersetzt | kostenlos nach Registrierung; auf der geprüften Projektseite keine Code-Reuse-Lizenz ausgewiesen; Version 27.1 | Nächster funktionaler Vergleich: Kategorien, einheitliches Schema, installierte Tools und Version sind abfragbar |
| [SQL# / SQLsharp](https://sqlsharp.com/features/) | direkte Capability-Library | laut öffentlicher Produktseite umfangreiche SQL-CLR-Bibliothek; Free- und Full-Varianten; Installation über SQL-Skript | [proprietäre EULA](https://sqlsharp.com/download/SQLsharp_EULA.htm); keine Installation, Codeübernahme oder Untersuchung internen Verhaltens | Die veröffentlichte Featureliste belegt den Bedarf an Regex, Konvertierung, String-, Datei- und weiteren CLR-Capabilities; Security- und Portabilitätsmodell passt nicht ohne Weiteres zum Projekt |
| [T-SQL Toolbox](https://gitlab.com/Kittell-Projects/t-sql-toolbox) | direkte, ältere T-SQL-Library | eigene zentrale Datenbank mit nativen T-SQL-Utilities und Referenzdaten | Apache-2.0; wenige Commits, keine Releases; historischer Stand | Vorbild und Warnung für zentrale Installation sowie für wartungsbedürftige Referenzdaten |
| [SQLServerSpatialTools](https://github.com/microsoft/SQLServerSpatialTools) | spezialisierte Capability-Library | SQL-CLR-Assembly, Registrierungsskripte, räumliche Funktionen, Aggregate und Transformationen | Microsoft Public License; älteres, spezialisiertes Projekt | Zeigt den Wert eines schmalen CLR-Moduls; vorhandene Legacy-Signing-Artefakte dürfen nicht unbesehen nachgebaut werden |
| [tSQLt](https://github.com/tSQLt-org/tSQLt) | Datenbank-Testframework | T-SQL plus signiertes CLR; transaktionale Testisolation; Installationsskript und DACPAC-Option | Apache-2.0 | Kein Runtime-Toolbelt, aber wichtig für Contract Tests und als Vorbild für `tSQLt.NewConnection` |
| [SQL Server KIT](https://github.com/ktaranov/sqlserver-kit) | kuratierter Katalog | Links, Skripte, Tools und Best Practices aus vielen Quellen | Repository MIT; Herkunft einzelner Inhalte muss separat geprüft werden | Sehr guter Discovery-Index; keine pauschale Quelle für Codeübernahmen |
| [SQL Undercover Toolbox](https://github.com/SQLUndercover/UndercoverToolbox) | DBA-Skriptsammlung | lose Prozeduren, Funktionen und Skripte mit Einzeldokumentation | MIT | Ideenquelle; überwiegend Diagnose und Betrieb, daher meist `SQL_Server_Analyze` |
| [Madeira Toolbox](https://github.com/MadeiraData/MadeiraToolbox) | breite DBA-Skriptsammlung | Skripte für Administration, Troubleshooting und Performance | MIT; seit März 2024 zugunsten mehrerer spezialisierter Repositories abgelöst | Belegt das Wartungsproblem eines zu breiten „Misc“-Toolbox-Scopes und den Nutzen fachlicher Aufteilung |
| [Sparkhound SQL Server Toolbox](https://github.com/SparkhoundSQL/sql-server-toolbox) | DBA-Skriptsammlung | lose Skripte für Administration, Performance, Troubleshooting und Investigation | auf der geprüften Startseite keine belastbare Reuse-Lizenz festgestellt | Themenquelle für Analyze; kein Packaging-Vorbild |
| [Tiger Toolbox](https://github.com/microsoft/tigertoolbox) | Hersteller-Skriptsammlung | Microsoft-Team-Skripte und Lösungen für Betrieb und Performance | „as is“; Reife und Bedingungen je Inhalt prüfen | Primär für Analyze und Betrieb; verdeutlicht, dass ein gemeinsames Repository keine gemeinsame Produktreife garantiert |
| [First Responder Kit](https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit) | Diagnosepaket | versionierte T-SQL-Prozeduren; Gesamtinstaller und Deinstallation; `master` empfohlen, andere Datenbank möglich | MIT; laufend gepflegtes Community-Projekt | Starkes Packaging- und Dokumentationsvorbild; fachlich eindeutig Analyze |
| [SQL Server Maintenance Solution](https://github.com/olahallengren/sql-server-maintenance-solution) | Maintenance-Framework | Gesamtinstaller plus Einzelkomponenten; explizite Prozedur- und Tabellenabhängigkeiten; Prüfsummen | MIT | Queue-, Logging-, Abhängigkeits- und Lifecycle-Muster sind relevant; Maintenance bleibt außerhalb des Toolbelt |
| [dbatools](https://github.com/dataplat/dbatools) | externe Automation | umfangreiches PowerShell-Modul mit einheitlichen Commands und Discovery | MIT | Vorbild für konsistente Benennung, Hilfe und Command Discovery; als Out-of-process-Provider denkbar, nicht als T-SQL-Runtime-Abhängigkeit |
| [sp_WhoIsActive](https://github.com/amachanic/sp_whoisactive) | Diagnosetool | fokussierte T-SQL-Prozedur mit versionsbezogenen Artefakten | GPL-3.0 | Sehr erfolgreiches Single-Purpose-Modell; Diagnose gehört zu Analyze, GPL-Code nicht beiläufig übernehmen |
| [dbachecks](https://github.com/dataplat/dbachecks) | Validierungsframework | PowerShell/Pester, konfigurationsgetriebene Checks und maschinenlesbare Ergebnisse | MIT; Versionsübergang laut Projekt beachten | Vorbild für deklarative Tests und auswertbare Evidenz; keine Toolbelt-Runtime |
| [SQL Server Multi Thread](https://github.com/jobbish-sql/SQL-Server-Multi-Thread) | Parallelisierungsframework | Parent-, Child- und Cleanup-Prozeduren über SQL-Server-Agent-Jobs | MIT; 26 Commits, keine veröffentlichten Releases | Konkretes Vorbild für begrenzte Parallelität, Timeout, Stop und Fehlerbericht über Agent-Jobs |

### 1. Direkte Capability-Libraries

#### SDU Tools

SDU Tools kommt dem funktionalen Ziel des Toolbelt am nächsten. Die Projektseite führt allgemeine String-, Date/Time- und Konvertierungsfunktionen ebenso wie Datenbank-Hilfsprozeduren auf. Bemerkenswert sind weniger einzelne Funktionen als die gemeinsamen Produktmerkmale:

- ein einheitliches Schema für alle Objekte;
- ein einzelner Installer je Zieldatenbank;
- vollständiger Austausch des eigenen Schemas bei einem Release;
- abfragbare Liste der installierten Tools;
- abfragbare Produktversion;
- kurze Demonstrationen je Tool;
- getrennte Skripte für SQL Server, Azure SQL Database und Fabric SQL Database.

Für Toolbelt sind die Runtime-Auffindbarkeit und Versionsauskunft direkt übertragbare Anforderungen. Das vollständige Ersetzen eines Schemas ist dagegen nur dann sicher, wenn Ownership, Drift, Berechtigungen, Abhängigkeiten und benutzerseitige Erweiterungen zweifelsfrei beherrscht werden. Das vorhandene modulare Lifecycle-Modell des Toolbelt bleibt deshalb geeigneter als ein pauschaler Schema-Reset.

Die lange SDU-Liste ist außerdem kein sinnvoller Implementierungsplan. Mehrere Einträge sind landes-, sprach- oder betriebsbezogen; andere überlappen mit neueren nativen SQL-Server-Funktionen. Jeder Kandidat benötigt weiterhin eine eigene Lücken-, Versions- und Vertragsprüfung.

#### SQL# / SQLsharp

SQL# zeigt, wie groß der Funktionsraum einer SQL-CLR-Library werden kann. Die Projektseite nennt mehr als 340 Funktionen und Prozeduren sowie Aggregate und User-defined Types. Das Spektrum umfasst unter anderem Regex, Konvertierungen, Strings, Dateisystemzugriffe und Netzwerkfunktionen.

Für das Toolbelt ergeben sich drei Lehren:

1. Ein SQL-CLR-Provider kann echte Engine-Lücken schließen, sollte aber als klar begrenztes Modul mit eigener Security- und Plattformmatrix behandelt werden.
2. Datentyp-Wrapper und LOB-Verhalten sind Teil des Performancevertrags, nicht bloß Implementierungsdetails.
3. Breite Funktionsabdeckung rechtfertigt keine Abweichung vom Least-Privilege- und `TRUSTWORTHY`-Verbot.

SQL# ist proprietär. Die EULA schließt eine freie Codeübernahme aus und enthält zusätzliche Nutzungsbeschränkungen. Für diese Recherche wurde ausschließlich die öffentlich sichtbare Produkt- und Lizenzinformation ausgewertet; die Software wurde nicht installiert oder intern untersucht.

#### T-SQL Toolbox

Das ältere T-SQL Toolbox installiert Utilities in einer eigenen zentralen Datenbank. Sein bekanntester Bereich verwaltet Zeitzoneninformationen in Tabellen und stellt Konvertierungsfunktionen bereit. Das Modell zeigt:

- Eine zentrale Library kann mehrere Anwendungsdatenbanken bedienen.
- Cross-Database-Aufrufe, Berechtigungen und Deployment-Reihenfolge werden dadurch zum öffentlichen Vertrag.
- Referenzdaten sind ein eigenständiges Produktproblem. Zeitzonen, Feiertage, Währungen oder ähnliche Daten können fachlich veralten, selbst wenn sich der SQL-Code nicht ändert.
- Eine native Engine-Funktion kann Teile einer Library später überflüssig machen. `AT TIME ZONE` und `sys.time_zone_info` reduzieren heute den Bedarf an einer selbst gepflegten allgemeinen Zeitzonenbibliothek, ersetzen aber nicht automatisch jeden historischen oder plattformübergreifenden Vertrag.

Das Toolbelt sollte Referenzdaten daher erst nach einer eigenen Entscheidung zu Quelle, Lizenz, Aktualisierung, Versionierung, Offline-Betrieb und Migration aufnehmen.

#### SQLServerSpatialTools

SQLServerSpatialTools ist kein allgemeines Toolbelt, aber ein gutes Beispiel für ein fachlich enges Capability-Modul: räumliche Funktionen, Konvertierungen, Transformationen und Aggregate werden gemeinsam als SQL-CLR-Assembly ausgeliefert. Ein solches Modul kann sinnvoll sein, wenn native T-SQL-Varianten den Vertrag nicht korrekt oder performant erfüllen.

Das Repository enthält historisches Signing-/Deployment-Material. Daraus wird ausdrücklich kein modernes Sicherheitsmuster abgeleitet. Assembly-Signierung, Zertifikatskette, Secret-Behandlung, `clr strict security`, Windows/Linux und Upgradepfad müssen für jedes Toolbelt-CLR-Modul neu entworfen und validiert werden.

## Konkrete Vorbilder für die angesprochenen Execution-Themen

### Zweite Session und rollback-unabhängiges Logging

[`tSQLt.NewConnection`](https://tsqlt.org/125/tsqlt-build-9-release-notes/) führt Statements synchron in einem anderen Connection-Kontext aus. Der
[aktuelle CLR-Quellstand](https://github.com/tSQLt-org/tSQLt/blob/4a921d0dacfb1d66b3db124c58158c80e5e910e6/tSQLtCLR/tSQLtCLR/CommandExecutor.cs)
unterdrückt die umgebende .NET-Transaktion und öffnet eine reguläre SQL-Verbindung zur aktuellen Datenbank. Damit existiert konkretes Apache-2.0-Prior-Art für eine zweite Session aus einer SQL-CLR-Routine.

Das Muster beweist jedoch nur technische Machbarkeit:

- Die Ausführung ist dort synchron, nicht automatisch parallel oder gepuffert.
- Die neue Session besitzt eigenen Transaktions- und Sessionzustand.
- Lokale Temp-Tabellen und nicht committete Änderungen des Callers sind nicht sichtbar.
- Der Logger kann sich an Sperren der Caller-Transaktion selbst blockieren.
- Anmeldung, Impersonation, integrierte Sicherheit, Connection String und Zertifikats-/Assembly-Trust sind ein eigener Sicherheitsvertrag.
- Ein Fehler beim Öffnen oder Schreiben darf den ursprünglichen Fehler nicht verdecken.
- Eine zweite Session macht einen Logeintrag nur dann dauerhaft, wenn ihr eigener Commit tatsächlich erfolgreich war.

Service Broker ersetzt dieses Muster nicht innerhalb derselben noch offenen Caller-Transaktion: `SEND` ist transaktional und wird mit einem Rollback ebenfalls zurückgenommen. Broker bleibt interessant, wenn ein Ereignis bewusst erst mit dem erfolgreichen Fach-Commit sichtbar werden soll.

Folgerung für `TC-2026-014`: Nicht „zweite Session“ ist der öffentliche Vertrag, sondern die gewünschte Haltbarkeits-, Blockierungs-, Fehler- und Security-Semantik. SQL CLR, externer Prozess, Loopback-RPC und eingeschränkte Engine-Log-Provider sind mögliche Adapter hinter diesem Vertrag.

### Parallelisierung und Work Queues

| Providerklasse | Öffentliches Vorbild | Stärken | Offene Risiken und Grenzen |
|---|---|---|---|
| Service Broker mit Internal Activation | Microsoft-Dokumentation zu `MAX_QUEUE_READERS` und Aktivierung | transaktionale, dauerhafte Queue; Engine startet begrenzte Reader; kein Polling-Orchestrator erforderlich | Einrichtung komplex; `SEND` ist commit-gekoppelt; Poison Messages, Conversation Lifecycle, Security und Ergebnisaggregation benötigen eigenen Vertrag |
| SQL-Server-Agent-Jobs | [SQL Server Multi Thread](https://github.com/jobbish-sql/SQL-Server-Multi-Thread) | getrennte Sessions; maximale Child-Anzahl; Parent-/Child-/Cleanup-Modell; Timeout und Stop sind demonstriert | Agent-Abhängigkeit; Job-Metadaten und Berechtigungen; gröbere Granularität; kein universeller Cloud-/Edition-Vertrag |
| Tabellenbasierte Queue mit mehreren Aufrufern | [`Queue.sql`](https://github.com/olahallengren/sql-server-maintenance-solution/blob/main/Queue.sql) und `QueueDatabase.sql` der Maintenance Solution | transparenter Status; einfache operative Abfrage; lässt sich mit vorhandenen Sessions oder Jobs kombinieren | Claiming, Sperren, Lease, Orphan Recovery, Idempotenz und Supervisor müssen selbst korrekt entworfen werden |
| Externer Orchestrator | beispielsweise ein kontrollierter Worker-Service oder dbatools-artige Automation | Provider- und Credential-Isolation; gute Parallelitätsprimitive; SQL Server muss keine Worker erzeugen | zusätzliche Betriebsplattform; Netzwerkfehler; Deployment, Secrets und Ende-zu-Ende-Korrelation |

SQL Server Multi Thread ist besonders relevant, weil es mehrere der genannten Anforderungen gemeinsam zeigt: begrenzte Child-Prozeduren, Timeout, Stop aller Child-Prozeduren sowie Validation und Error Reporting. Das ist dennoch kein fertiger Toolbelt-Vertrag. Das Repository weist keine Releases aus, nennt einen begrenzten Versionsumfang und ist an SQL Server Agent gebunden.

Die Queue-Tabellen der SQL Server Maintenance Solution zeigen eine zweite Richtung: Eine kleine persistente Statusstruktur kann Parallelisierung koordinieren, während die eigentliche Session-Erzeugung außerhalb der Tabelle bleibt. Gerade deshalb dürfen Queue, Worker-Provider und Work-Type-Katalog nicht als ein einziges untrennbares Objekt entworfen werden.

Folgerung für `TC-2026-015`: Zuerst den providerunabhängigen Vertrag festlegen, danach Provider vergleichen. Der Kernvertrag umfasst mindestens Execution-/Work-Item-Identität, maximale Parallelität, Claiming, Ergebnis, Timeout, Cancellation, Retry, Idempotenz, Lease und erlaubte Work Types.

### Console-Ausgabe

SDU Tools enthält mit `PrintMessage` bereits eine Funktion für sofortige Ausgabe. Das bestätigt den praktischen Bedarf, ändert aber nicht die Enginegrenzen:

- `PRINT` begrenzt und puffert lange Nachrichten;
- `RAISERROR ... WITH NOWAIT` liefert unmittelbare Messages, hat aber eine kleinere Nachrichtenobergrenze;
- Client und Treiber beeinflussen Darstellung und Reihenfolge;
- Message-Ausgabe ist kein dauerhafter Logger;
- Chunking muss Unicode, Zeilenenden, Formatzeichen und leere Werte deterministisch behandeln.

`TC-2026-016` bleibt daher eine kleine, eigenständige Capability. Sie sollte nicht stillschweigend in den Error Envelope oder Logger eingebaut werden.

### Error Handling und Gruppenabbruch

Keines der untersuchten Projekte liefert einen allgemeinen, projektübergreifend passenden Error Envelope. Frameworks besitzen jeweils ihre eigene Semantik:

- tSQLt isoliert Testfälle und formatiert Testergebnisse.
- SQL Server Multi Thread nennt Validation, Error Reporting und zeitgesteuertes Stoppen der Child-Arbeit.
- Service Broker besitzt Poison-Message-Schutz, aber keinen fachlichen Retry-/Idempotenzvertrag.
- SQL Server Agent kann Jobs stoppen, aber keinen beliebigen Satz fremder Sessions sicher als zusammengehörige Ausführung erkennen.

Daraus folgt:

- Der Originalfehler muss vor Logging und Cleanup vollständig erfasst werden.
- Das Rethrow an der ursprünglichen `CATCH`-Grenze bleibt parameterloses `THROW;`.
- Logging-, Console- oder Cleanup-Fehler dürfen die Primärursache nicht überschreiben.
- Gruppenabbruch beginnt kooperativ über eine verifizierte `ExecutionId`.
- `KILL` ist nur ein privilegierter, nach erneuter Sessionzuordnung zulässiger Eskalationspfad.
- „Alle Prozesse abbrechen“ darf ausschließlich die eigene Ausführungsgruppe meinen.
- Fail-fast, Grace Period, Rollback-Wartezeit und Verhalten bereits erfolgreich abgeschlossener Work Items sind Teil des öffentlichen Vertrags.

## Zusätzliche Themen aus dem Vergleich

### Neue Research-Kandidaten

#### Abfragbarer Capability- und Versionskatalog

SDU Tools stellt sowohl die installierte Version als auch eine Liste seiner Tools zur Laufzeit bereit. dbatools zeigt denselben Nutzen auf Command-Ebene. Das Toolbelt besitzt bereits `module.yaml` und Modulversionen im Repository, aber noch keinen festgelegten Runtime-Vertrag für Fragen wie:

- Welche Module und Capabilities sind in dieser Datenbank installiert?
- Welche öffentliche Objektversion gehört zu welchem Modul?
- Welcher Provider und welche SQL-Server-Version werden unterstützt?
- Ist ein Modul vollständig, teilweise oder mit Drift installiert?
- Wo liegt die zugehörige Help-/Dokumentationsinformation?

Das wird als `TC-2026-023` erfasst. Eine Runtime-Tabelle ist nicht vorentschieden; mögliche Quellen sind deterministische Extended Properties, eine View über vorhandene Metadaten oder ein kontrollierter Katalog. Jede persistente Registry benötigt eine eigene Architektur- und Namensentscheidung.

#### URI-Percent-Encoding und -Decoding

SQL Server dokumentiert mit `STRING_ESCAPE` ausschließlich JSON-Escaping, aber keine allgemeine Funktion für URI-Percent-Encoding. Öffentliche T-SQL-Libraries führen eine solche Konvertierung deshalb als eigene Capability. Der neue Kandidat `TC-2026-024` prüft einen eng begrenzten RFC-3986-Vertrag.

Der Vertrag darf nicht ungenau „URL encode“ heißen, weil mindestens folgende Varianten auseinanderzuhalten sind:

- URI-Komponente gegenüber vollständiger URI;
- reservierte gegenüber nicht reservierten Zeichen;
- UTF-8-Bytes gegenüber UTF-16-Code-Units;
- Percent-Encoding gegenüber `application/x-www-form-urlencoded`;
- Leerzeichen als `%20` gegenüber `+`;
- Normalisierung bereits percent-kodierter Triplets;
- Verhalten bei ungültigen, unvollständigen oder nicht kanonischen Sequenzen.

Die erste Version sollte nur eine klar bezeichnete URI-Komponenten-Capability nach RFC 3986 betrachten. Form-Encoding, vollständiges URL-Parsing und IRI-/Domain-Normalisierung sind eigene Verträge und dürfen nicht als versteckte Optionen hinzukommen.

#### Vorhandener Base64-Kandidat bestätigt

SQL Server 2025 besitzt `BASE64_ENCODE` und `BASE64_DECODE`; SQL Server 2019 und 2022 nicht. Der bereits vorhandene Kandidat `TC-2026-012` war damit kein neuer Fund, wurde durch diese Recherche aber präzisiert.

Die native 2025-Semantik enthält mehr als eine einfache XML-Konvertierung: Standard- und URL-safe-Alphabet, Padding-Regeln, definierte Whitespace-Toleranz beim Decoding, typabhängige Rückgabelängen, `NULL`-Verhalten und unterscheidbare Fehlerzustände für ungültige Zeichen und Formatierung. Ein Backport sollte entweder diese Semantik messbar nachbilden oder einen ausdrücklich kleineren Vertrag erhalten.

### Weiter zu untersuchende Architekturthemen

Diese Punkte sind noch keine Funktionskandidaten:

1. **Referenzdaten-Lifecycle:** Quelle, Lizenz, Version, Updatefrequenz, Offline-Installation, Hash, Migration und Rückbau für Kalender-, Zeitzonen-, Unicode- oder andere Referenzdaten.
2. **Lizenz- und Herkunftsinventar je Modul:** Ein Repository-Level-Lizenzhinweis reicht für aggregierte Skriptsammlungen nicht zwingend aus.
3. **Providerfähige Module:** Ein öffentlicher Capability-Vertrag kann einen nativen, T-SQL-, CLR- oder externen Provider besitzen, ohne Providerdetails in jede aufrufende Procedure zu leaken.
4. **Maschinenlesbare Testevidenz:** Contract Tests sollten nicht nur Messages ausgeben, sondern später auch eindeutig auswertbare Ergebnisse für CI liefern.
5. **Obsoleszenzprozess:** Wenn eine spätere SQL-Server-Version eine Capability nativ anbietet, braucht das Modul Paritätstests, Providerwechsel und einen dokumentierten Deprecation-Pfad.

### Screening-Liste für spätere Funktionsrecherche

Die Projektkataloge zeigen weitere wiederkehrende Themen. Sie werden bewusst noch nicht als `researched` eingetragen:

- Unix-Time-Konvertierung mit Bereichs-, Rundungs- und Zeitzonenregeln;
- String-Distanz und Suchnormalisierung mit Collation- und Performancevertrag;
- Kalender- und Working-Day-Funktionen mit explizitem Kalender-/Feiertagsprovider;
- sichere, rein lesende Schema- und Dependency-Vergleiche;
- Parser für URL- und Dateipfad-Komponenten mit klarer Plattformsemantik.

Vor einer Aufnahme sind native Alternativen in SQL Server 2019, 2022 und 2025, realistische Use Cases, Mengenperformance, deterministische Semantik und Repository-Grenze einzeln zu prüfen.

### Einordnung des zusätzlichen Brainstorms

Der während dieser Recherche ergänzte
[persönliche Brainstorm](../../Backlog/personal_Backlog_Bainstorm.md)
bleibt als unveränderte Ideensammlung erhalten. Seine Themen wurden gegen Engine-Semantik und Repository-Grenzen vorgeprüft, aber noch nicht als formale Kandidaten übernommen:

| Thema | Belastbarer Ausgangspunkt | Vorläufige Einordnung | Nächste Research-Fragen |
|---|---|---|---|
| Ganzzahlen in variable Zahlensysteme konvertieren | `CAST`/`CONVERT` kennt dokumentierte Binär-/Hex-Stile, aber keinen allgemeinen Vertrag für frei wählbare Basen | plausible Toolbelt-Capability in `Conversion`; Kandidat nach Vertragsbesprechung | unterstützte Basen und Alphabet, Vorzeichen, Null, führende Nullen, `bigint`-Grenzen, Rückkonvertierung, Case-Semantik und Overflow |
| ZIP, Gzip und weitere Kompressionsverfahren | `COMPRESS` und `DECOMPRESS` existieren bereits seit SQL Server 2016 und verwenden den Gzip-Algorithmus; ein Gzip-komprimierter Wert ist kein ZIP-Archiv mit Dateiverzeichnis | reine `varbinary`-Kompression von Archivcontainer und Dateisystemzugriff trennen; nativen Gzip-Vertrag nicht nachbauen | Algorithmen, Stream-/LOB-Verhalten, maximale Größe, Kompressionsbomben, Archivpfade, Verschlüsselung, Provider und Plattform |
| Datei lesen und schreiben | `BULK INSERT` und `OPENROWSET(BULK...)` importieren Dateien; Bulk-Export erfolgt typischerweise über einen externen Prozess wie `bcp`; SQL CLR benötigt für Dateizugriff `EXTERNAL_ACCESS` | Hochrisiko-Providergrenze; eher externes Automationsmodul oder streng begrenztes CLR-Modul als allgemeine T-SQL-Funktion | Pfad-Sandbox, Read versus Write, Overwrite, Encoding/BOM, ACL/Security Context, Dateigröße, Atomicity, Windows/Linux und zentrale Installation |
| Verzeichnisinhalt auflisten | dokumentierter SQL-CLR-Dateizugriff fällt ebenfalls unter `EXTERNAL_ACCESS`; Pfad- und Berechtigungssemantik ist betriebssystemabhängig | nicht mit undokumentierten Extended Procedures aufbauen; externer oder eng signierter Provider | rekursiv oder flach, Symlinks/Reparse Points, versteckte Dateien, Race Conditions, Pfadnormalisierung, Berechtigungen und Ergebnisgrenzen |
| Anonymisierung und Pseudonymisierung | Dynamic Data Masking verändert gespeicherte Werte nicht und schützt laut Microsoft nicht vor gezieltem Ableiten durch Ad-hoc-Abfragen; `HASHBYTES` und `CRYPT_GEN_RANDOM` sind nur Primitive | separates, sicherheits- und datenschutzkritisches Framework; nicht als lose Sammlung von Random-Funktionen behandeln | irreversibel versus reversibel, deterministisch versus zufällig, referenzielle Integrität, Eindeutigkeit, Verteilungsnähe, Schlüssel-/Salt-Management, Wiederholbarkeit und Validierungsnachweis |
| Objekt klonen | `SELECT...INTO` überträgt keine Indizes, Constraints oder Trigger und besitzt Sonderregeln für `IDENTITY`; SMO `Scripter` kann Abhängigkeiten entdecken und besitzt gezielte Scripting-Optionen | wahrscheinlich externes SMO/DacFx-Modul; ein T-SQL-Modul sollte zunächst nur kontrolliert Skript erzeugen, nicht automatisch alles ausführen | unterstützte Objekttypen, Abhängigkeitsgraph, Namensbildung, Daten ja/nein, Berechtigungen, Extended Properties, Partitionierung, Temporal/Memory-optimized, Cross-Database und transaktionaler Rückbau |

Aus dieser Vorprüfung folgt eine wichtige Trennung:

- **Value Capabilities** wie Zahlensystem- oder reine In-memory-Kompression können Toolbelt-Funktionen werden.
- **External Resource Capabilities** wie Datei, Verzeichnis und Archivzugriff benötigen eine eigene Security- und Providerentscheidung.
- **Frameworks mit fachlichen Nebenwirkungen** wie Anonymisierung und Objektklonen benötigen einen deutlich größeren Vertrags-, Datenschutz- und Recovery-Entwurf als eine einzelne Helper-Funktion.

Keine dieser Einordnungen ist eine Implementierungsfreigabe. Vor der Vergabe weiterer `TC`-IDs werden Zweck, Schnittstelle, Alternativen, Risiken und Scope einzeln besprochen.

## Architekturfolgen für SQL Server Toolbelt

### Muster, die übernommen werden sollten

1. **Funktionen müssen auffindbar sein.** Kategorie, Modul, Version, Supportmatrix und Help sollten konsistent abfragbar sein.
2. **Module bleiben schmal.** Das spezialisierte SpatialTools- und das fokussierte WhoIsActive-Modell sind wartbarer als eine ungegliederte Sammlung beliebiger DBA-Skripte.
3. **Aggregate und Einzelkomponenten brauchen denselben Lifecycle.** Gesamtinstallation darf keine andere Objektsemantik erzeugen als die Einzelinstallation.
4. **Abhängigkeiten sind explizit.** Die Maintenance Solution zeigt den Wert klar benannter Hilfsobjekte; das Toolbelt-Modell ergänzt dazu Preflight und Versionsvertrag.
5. **Provider werden getrennt validiert.** T-SQL, CLR, Agent, Broker und externe Prozesse erhalten jeweils eigene Security-, Plattform- und Runtime-Evidenz.
6. **Tests liefern maschinenlesbare Ergebnisse.** Frameworks wie tSQLt und dbachecks zeigen den Wert automatisiert auswertbarer Contract-Evidenz.
7. **Spätere native Funktionen sind ein geplanter Provider, kein Überraschungsereignis.** Compatibility-Module benötigen Paritätsmatrix und Deprecation-Pfad.
8. **Quellen und Lizenz gelten pro übernommener Einheit.** Ein Linkkatalog ist eine Recherchehilfe, keine pauschale Wiederverwendungserlaubnis.

### Muster, die vermieden werden sollten

- ein unkontrollierter „Misc Scripts“-Ordner ohne Modulvertrag;
- pauschales Löschen und Neuaufbauen eines Schemas ohne Ownership- und Drift-Preflight;
- Installation in `master` oder ein `sp_`-Namenspräfix als stillschweigender Default;
- Vermischung von Capabilities, Diagnose, Security Assessment und Maintenance;
- `TRUSTWORTHY ON`, undokumentierte Privilegien oder Legacy-Signing-Artefakte als bequemer CLR-Installationspfad;
- eine allgemeine Raw-SQL-Ausführungsschnittstelle für Worker;
- Kopieren aus proprietären oder lizenzseitig uneindeutigen Projekten;
- Feature-Mengen als Roadmap, ohne Nutzen-, Versions-, Performance- und Obsoleszenzprüfung.

## Repository-Routing

| Inhalt | Ziel |
|---|---|
| wiederverwendbare String-, Date-, Conversion-, JSON-, Binary- oder Core-Capability mit stabilem Vertrag | `SQL_Server_Toolbelt` |
| Diagnose von Sessions, Indizes, Konfiguration, Performance, Security oder Serverzustand | `SQL_Server_Analyze` |
| Backups, Integrity Checks, Index-/Statistics-Maintenance und Job Scheduling | externe Maintenance-Lösung; kein Toolbelt-Nachbau |
| Migration und Flottenautomation über viele Instanzen | externer Orchestrator, beispielsweise PowerShell; Toolbelt höchstens als klarer Datenbank-Endpunkt |
| Unit-/Contract-Testframework | Test-Infrastruktur; keine Runtime-Abhängigkeit ohne eigene Entscheidung |
| Queue, Logging oder Cancellation ausschließlich für Toolbelt-eigene Ausführungen | möglicher Toolbelt-Core-Scope nach Funktionsbesprechung |
| generisches Enterprise-Messaging oder beliebige Remote-Code-Ausführung | außerhalb des Toolbelt |

## Empfohlene Besprechungsreihenfolge

Die Recherche verändert die sinnvolle Reihenfolge der Execution-Themen:

1. `toolbelt_core.USP_PrepareResultTable` separat reviewen und die tatsächlich verfügbare Runtime-Validierung festlegen.
2. `TC-2026-019` – minimale Execution-/Correlation-Identität festlegen.
3. `TC-2026-017` – Error Envelope und unverändertes Rethrow festlegen.
4. `TC-2026-016` – kleine Console-Capability unabhängig besprechen.
5. `TC-2026-014` – Haltbarkeitsgarantie und Provider für rollback-unabhängiges Logging vergleichen.
6. `TC-2026-022` – erlaubte Work Types und Security Boundary festlegen.
7. `TC-2026-015`, `TC-2026-018`, `TC-2026-020` und `TC-2026-021` gemeinsam als Queue-, Cancellation-, Retry- und Lease-Vertrag diskutieren, aber in getrennten Modulen implementierbar halten.
8. `TC-2026-023`, `TC-2026-024` und die präzisierte `TC-2026-012` nach Nutzen priorisieren.

Diese Reihenfolge ist eine Research-Empfehlung. Jeder Funktionsbeginn benötigt weiterhin eine eigene Besprechung und ausdrückliche Freigabe.

## Quellen

### Direkte Libraries und Sammlungen

- [SDU Tools](https://sqldownunder.com/sdutools/)
- [SQL# Features](https://sqlsharp.com/features/)
- [SQL# Free Edition](https://sqlsharp.com/free/)
- [SQL# EULA](https://sqlsharp.com/download/SQLsharp_EULA.htm)
- [T-SQL Toolbox](https://gitlab.com/Kittell-Projects/t-sql-toolbox)
- [SQLServerSpatialTools](https://github.com/microsoft/SQLServerSpatialTools)
- [SQL Server KIT](https://github.com/ktaranov/sqlserver-kit)
- [SQL Undercover Toolbox](https://github.com/SQLUndercover/UndercoverToolbox)
- [Madeira Toolbox](https://github.com/MadeiraData/MadeiraToolbox)
- [Sparkhound SQL Server Toolbox](https://github.com/SparkhoundSQL/sql-server-toolbox)
- [Microsoft Tiger Toolbox](https://github.com/microsoft/tigertoolbox)

### Frameworks, Diagnose und Betrieb

- [tSQLt](https://github.com/tSQLt-org/tSQLt)
- [tSQLt.NewConnection Release Note](https://tsqlt.org/125/tsqlt-build-9-release-notes/)
- [tSQLt CommandExecutor source](https://github.com/tSQLt-org/tSQLt/blob/4a921d0dacfb1d66b3db124c58158c80e5e910e6/tSQLtCLR/tSQLtCLR/CommandExecutor.cs)
- [First Responder Kit](https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit)
- [SQL Server Maintenance Solution](https://github.com/olahallengren/sql-server-maintenance-solution)
- [Maintenance Solution Queue](https://github.com/olahallengren/sql-server-maintenance-solution/blob/main/Queue.sql)
- [SQL Server Multi Thread](https://github.com/jobbish-sql/SQL-Server-Multi-Thread)
- [dbatools](https://github.com/dataplat/dbatools)
- [sp_WhoIsActive](https://github.com/amachanic/sp_whoisactive)
- [dbachecks](https://github.com/dataplat/dbachecks)

### Microsoft Engine-Dokumentation

- [Transactional Messaging](https://learn.microsoft.com/en-us/sql/database-engine/service-broker/transactional-messaging?view=sql-server-ver17)
- [ALTER QUEUE](https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-queue-transact-sql?view=sql-server-ver17)
- [Understanding When Activation Occurs](https://learn.microsoft.com/en-us/sql/database-engine/service-broker/understanding-when-activation-occurs?view=sql-server-ver17)
- [sp_start_job](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-start-job-transact-sql?view=sql-server-ver17)
- [PRINT](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/print-transact-sql?view=sql-server-ver17)
- [RAISERROR](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver17)
- [TRY...CATCH](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/try-catch-transact-sql?view=sql-server-ver17)
- [THROW](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql?view=sql-server-ver17)
- [KILL](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/kill-transact-sql?view=sql-server-ver17)
- [AT TIME ZONE](https://learn.microsoft.com/en-us/sql/t-sql/queries/at-time-zone-transact-sql?view=sql-server-ver17)
- [sys.time_zone_info](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-time-zone-info-transact-sql?view=sql-server-ver17)
- [BASE64_ENCODE](https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-encode-transact-sql?view=sql-server-ver17)
- [BASE64_DECODE](https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-decode-transact-sql?view=sql-server-ver17)
- [STRING_ESCAPE](https://learn.microsoft.com/en-us/sql/t-sql/functions/string-escape-transact-sql?view=sql-server-ver17)
- [RFC 3986: Uniform Resource Identifier – Generic Syntax](https://datatracker.ietf.org/doc/html/rfc3986)
- [COMPRESS](https://learn.microsoft.com/en-us/sql/t-sql/functions/compress-transact-sql?view=sql-server-ver17)
- [DECOMPRESS](https://learn.microsoft.com/en-us/sql/t-sql/functions/decompress-transact-sql?view=sql-server-ver17)
- [BULK INSERT und OPENROWSET(BULK...)](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-bulk-data-by-using-bulk-insert-or-openrowset-bulk-sql-server?view=sql-server-ver17)
- [CLR Integration Code Access Security](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/security/clr-integration-code-access-security?view=sql-server-ver17)
- [Dynamic Data Masking](https://learn.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking?view=sql-server-ver17)
- [HASHBYTES](https://learn.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql?view=sql-server-ver17)
- [CRYPT_GEN_RANDOM](https://learn.microsoft.com/en-us/sql/t-sql/functions/crypt-gen-random-transact-sql?view=sql-server-ver17)
- [SELECT...INTO](https://learn.microsoft.com/en-us/sql/t-sql/queries/select-into-clause-transact-sql?view=sql-server-ver17)
- [SMO Overview](https://learn.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo/overview-smo?view=sql-server-ver17)
- [SMO ScriptingOptions](https://learn.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.scriptingoptions?view=sql-smo-172)
- [CAST und CONVERT](https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?view=sql-server-ver17)
