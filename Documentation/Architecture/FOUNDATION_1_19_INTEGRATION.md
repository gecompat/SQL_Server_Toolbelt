# Foundation1.19 – Integrationsprüfung2026-10-05

Stand: Codex. Benutzerauftrag: neue AI Repository Foundation und ihre
Integration in dieses Projekt prüfen. Die kompatible Wartung erfolgt getrennt
von der parallel freigegebenen JSON-Schema-Produktwelle.

Quelle ist [Commit4aafd20442275d0fdedf291fc6e12e8fe1f683cc](https://github.com/gecompat/AI_Repository_Foundation/tree/4aafd20442275d0fdedf291fc6e12e8fe1f683cc),
Manifestversion1.19.0. Installierter Ausgangsstand:1.17.2 mit Provenienz zu
36d2cb20c2880b7cfaa6428db3716e6768e23964. Die vollständige Katalogdifferenz
enthält genau zwei neue Features; jedes erhält in
[FOUNDATION_1_19_ASSESSMENT.json](FOUNDATION_1_19_ASSESSMENT.json) genau eine
Klassifikation. Die Ausgangsprüfung gegen die neue Quelle meldete erwartbar
vier fehlende neue Sessionartefakte, neun Unterschiede und eine veraltete
AGENTS-Provenienz nach zwischenzeitlicher Projektregelpflege. Das ist keine
rückwirkende Behauptung,1.17.2 hätte1.19 bereits vollständig enthalten.

## Vollständige Bewertung und Empfehlungen

| Feature | Klassifikation | Ergebnis |
|---|---|---|
| ci-supersession-and-integration-queue, eingeführt1.18.0 | RECOMMENDED | Laufende mutierende Runtimeprüfungen erhalten; vorhandene Concurrency-Gruppen und exakte Headbindung verwenden.24 Runtime-/Qualification-Workflows werden von automatischem Abbruch auf Retain umgestellt. |
| session-lifecycle-management, eingeführt1.19.0 | RECOMMENDED | Günstige metadatenbasierte Sessionsteuerung und Referenz-/Deltaübergabe übernehmen; keine erfundenen Metriken, Projektthresholds oder automatische Nachfolgesitzung. |

Für mutierende Tests waren EXIT-Traps und eigene Cleanup-Pfade vorhanden,
aber kein belegter Recovery-Vertrag für harte Unterbrechung. Daher wird die
neue Sicherheitsgrenze durch Erhalt laufender Prüfungen erfüllt. Der rein
lesende Dokumentationsworkflow behält seine Abbruchstrategie. Noch nicht
gestartete, vollständig ersetzte PR-Prüfungen können durch die bestehende
Concurrency-Gruppe abgelöst werden. Cancelled ist niemals validiert.
GitHub Merge Queues, Rulesets, Bypass-Actors und Provider bleiben unverändert;
serverseitige Enforcement-Einstellungen werden hier nicht behauptet.

Konkrete Soft-/Hard-/Delta-Schwellen und eine automatische Clientrotation
sind optionale spätere Projektentscheidungen. Die Beispielwerte bleiben
synthetische Beispiele. Normale autonome Arbeit erfordert diese Auswahl
nicht. Eine tatsächliche Rotation oder neue Chat-Erstellung wurde nicht
ausgeführt. Die dauerhaften Auswahlwerte stehen in
[WORKING_RULES.md](../../.ai/WORKING_RULES.md), erreichbar über Root-AGENTS.

## Semantischer Transfer

Alle101 ausgewählten Quellzeilen wurden vor Schreiben gegen ihre portablen
Manifest-SHA256 geprüft. Die bisher ausgewählten drei Adapter und neun
Capabilities bleiben unverändert; keine neue Capability oder Runtime wird
aktiviert. Acht bestehende Foundationdateien werden vorwärts aktualisiert,
vier neue Sessionartefakte ergänzt. Die vollständige eigene Projekt-Governance
außerhalb des verwalteten AGENTS-Blocks bleibt erhalten; dessen Inhalt ist
bereits identisch zur aktuellen Quellvorlage. Die zusätzliche projektspezifische
Copilot-Backlog-Curator-Discovery bleibt als begründeter Override erhalten.

| Überlappung | Semantische Klasse | Behandlung |
|---|---|---|
| SQL-Scope, individuelle Funktionsfreigabe, Labgrenze, Datenschutz | PROJECT_STRONGER / COMPLEMENTARY | Unverändert erhalten; Foundation erweitert keine Ausführungsautorität. |
| Öffentliche USP-/Deployment-/Moduleverträge, Statusvokabular | COMPLEMENTARY | Bestehende Projektvalidatoren und Runtimeverfahren bleiben maßgeblich. |
| CI-Gruppen und exakte PR-Head-Abnahme | PROJECT_SELECTABLE_OVERRIDE | Bestehende Gruppen erhalten; nur unsicherer laufender Runtimeabbruch deaktiviert. |
| Projekt-AGENTS und Copilot-Discovery | PROJECT_SELECTABLE_OVERRIDE | Rootregeln und spezielle Capabilityreferenz erhalten; frische Provenienz mit konkreten Gründen. |
| IDs, Registration Authority, historische Referenzen | EQUIVALENT / PRESERVE | Keine Umbenennung, Registrymigration oder neue geratene Sequenz. |
| Sitzung und Content-Minimierung | COMPLEMENTARY | Metadaten-/Deltavertrag ergänzt, kein Client-/Runtimezustand committed. |

Keine Foundation-Root-README, Root-Lizenz, Projektbacklogs, Tests oder nicht
manifestgelisteten Tools werden ins Projekt übertragen. Die geschützte
Toolbelt-Lizenz und die bestehende Foundation-Attribution bleiben erhalten.
Die erneuerte Installation-Provenienz identifiziert exakte Quelle, Auswahl,
portable Hashes und ausschließlich begründete Overrides. Provenienz ist
keine fachliche Freigabe und kein Runtimeerfolg.

## Validierung und Grenzen

Ausgeführt2026-10-05: vollständige deterministische Feature-Differenz und
101 Sourcehashprüfungen; sieben Session-, elf Continuity- und16 Upgrade-
Applicability-Regressionsfälle der exakten Quelle bestanden. Diese Tests
bleiben im Quellcheckout; sie werden nicht in Toolbelt kopiert.

Die exakte Foundationprüfung bestand mit105 INFO, ohne WARNING, ERROR oder BLOCKING. Der vollständige Projekt-Dokumentationsaudit, YAML-Prüfung aller24 Retain-Workflows und Whitespaceprüfung bestanden ebenfalls. Die aktuelle Head-CI wird getrennt nachgewiesen. Foundation-green belegt ausschließlich
FOUNDATION_INTEGRITY. Keine SQL-Produktänderung, neuen Labtests, Grants,
Truständerung, Modellinvokation, Runtime-/Toolinstallation oder Produktionswirkung durch
diese Wartungswelle. Kein Hard-Interrupt-Recovery-PASS wird aus der Retain-
Konfiguration abgeleitet.

Die erste aktuelle CI deckte eine bestehende veraltete Prozesshelper-Pin im
historischen Queue-Capture auf. Diese unabhängige Testkopplung wurde separat
in [PR178](https://github.com/gecompat/SQL_Server_Toolbelt/pull/178) korrigiert
und nach vier erfolgreichen exakten Headchecks gemergt, einschließlich echter
Queue2.0→2.1-Migration. Der frühere Foundation-PR-Workerlauf bleibt fehlgeschlagen;
der darauf aktualisierte Foundationstand benötigte eigene aktuelle Headchecks.

## Abschluss der Integrationsprüfung

[PR177](https://github.com/gecompat/SQL_Server_Toolbelt/pull/177) wurde am
2026-10-05 nach 26 erfolgreichen Workflows auf dem exakten Head
`45b855a693741f26461d35d62678ea76c726f3e3` als
`2c4c5e84ce7ee1e8d2a5ae7effaec57d846cfbcd` nach `main` gemergt. Dazu
gehört der zuvor fehlende SQL-Server-2025-Linux-CL150-Lauf der Deterministic
Mapping CI. Frühere wegen Runner-Zuweisung abgebrochene Läufe und der erste
Regex-Zeitfehler bleiben getrennte Historie; sie wurden nicht als Erfolg
gewertet. Der gemergte Stand, die Foundation-Provenienz und die unveränderten
Projektregeln wurden geprüft. Diese Abnahme belegt die Foundation-Integration
und ihre betroffenen CI-Verträge, keine allgemeine SQL-Releasequalifikation
oder Wiederherstellung nach hartem Abbruch.

## Begrenzte Redirect-Wartung2026-10-07

Der autonome Security-Wartungsauftrag korrigiert im bereits ausgewählten
Host-Preparation-Referenzclient die Prüfung nach erfolgtem Redirectkontakt.
Ein gemeinsamer urllib-Handler bindet jetzt jeden Hop vor Dispatch an den
ursprünglichen HTTPS-Host und effektiven Port443. Erlaubte Same-origin-
Redirects behalten die vorhandene urllib-Methoden-/Schleifenbehandlung;
verweigerte Antworten werden ohne Bodyread geschlossen. Download und
Cost-Evidence behalten ihre bisherigen Permissioncodes und übrigen Budgets.

Sourcecommit4aafd20442275d0fdedf291fc6e12e8fe1f683cc, Manifest und Version1.19.0
bleiben Ausgangsprovenienz. Nur der korrigierte Client und seine gekoppelte
Capability-Dokumentation erhalten portable Installedhashes sowie konkrete
`INTENTIONAL_OVERRIDE`-Gründe. Dies ist eine stärkere Target-Sicherheitsgrenze,
kein Upstreamfix, Foundationupgrade oder neues Providerangebot.

Die [synthetische Regression](../../Tests/Documentation/test_foundation_redirects.py)
prüft tatsächliche urllib-Dispatchketten mit Fake-HTTP-Antworten. Netzwerk,
DNS, Runtimeinventar, Provisionierung, Installation und SQL werden dabei nicht
ausgeführt. Source-/Provenienz- und Projektaudit bleiben getrennte Ebenen;
eine erfolgreiche Offlineprobe ist kein realer Endpoint- oder Exploitnachweis.
Der andere HTTP-Bodyread- und der bedingte Pfad-TOCTOU-Befund bleiben offen.

## Begrenzte HttpAdapter-Responsewartung2026-10-07

Die anschließende autonome Securitywartung begrenzt den gemeinsamen
HttpAdapter-Readpfad für Ollama und OpenAI-compatible Probe/Catalog/Invoke
vor JSON-Parsing und Outputmutation auf16MiB Bodybytes. Auch legitime größere
Antworten werden mit nicht wiederholbarem PROTOCOL/HTTP_RESPONSE_TOO_LARGE
abgewiesen. Kurze Reads sind kein EOF; höchstens Ceiling+1 Byte wird gelesen.
Eine positive HTTPResponse-Restlänge am EOF wird separat als
HTTP_RESPONSE_INCOMPLETE abgewiesen, damit der Sized-Read die frühere
IncompleteRead-Grenze nicht schwächt. Antworten werden geschlossen;
Schließfehler verdecken eine bereits festgestellte Transportabwehr nicht.

Source und Capabilitydoc erhalten genau zwei zusätzliche begründete
Targetoverrides; Sourcecommit, Manifestversion1.19.0, Auswahl und vorherige
Redirectoverrides bleiben erhalten. Die bestehende101-Dateien-Provenienz-
Regression prüft weiterhin sämtliche Installedhashes und Originalmetadaten.
Der [neue Offline-Test](../../Tests/Documentation/test_foundation_http_response.py)
ist an den Projektvalidator gekoppelt und verwendet skalierte kleine
Bytegrenzen. Der Testcode alleine ist kein ausgeführter Nachweis.

Ausgeführt2026-10-07: `python -B Tests/Documentation/test_foundation_http_response.py`
bestand neun Methoden mit87 synthetischen Szenarien in einem begrenzten
10s-Prozess, Exit0, vollständiger Erfassung und stabilen Source-/Testpins.
Ein unabhängiger Sourceagent prüfte24 kleine AST-/HTTPResponse-Fälle;
Root las die Prüfprogramme und verifizierte die privaten Receipts und Pins.
Die Grenztests skalieren auf128/17 beziehungsweise12/5 Bytes; die echten
16MiB-/64KiB-Konstanten werden getrennt geprüft, kein Maximalworkload ausgeführt.
Projektaudit und exakte Head-/Main-CI werden als eigene Gates nachgewiesen.

Commandadapter und öffentliche SQL-Verträge werden nicht geändert. Netzwerk,
Runtimekonfiguration/-aktivierung, Provider, Provisionierung, Rechte und Lab
werden nicht erweitert. Der separate Discovery-Readpfad in
runtime_configuration.py, die bedingte Pfad-TOCTOU-Grenze, JSON-Tiefe/Heap,
Gesamtzeit und reale Endpoint-/Produktionsqualifikation bleiben offen.
Dies aktualisiert keinen historischen Cloudscan und behauptet keinen
Upstreamfix oder vollständige Foundation-/Produktvalidierung.

## Begrenzte Discoverywartung2026-10-07

Die anschließende Sourceprüfung identifizierte den getrennten Versionsprobe
mit unbegrenztem Read und automatischem Redirectfollow. Die bisherige
Loopbackselektion prüfte nur den ersten Kandidaten. Der bereits ausgewählte
Konfigurationsclient verwendet nun den gemeinsamen16MiB-/64KiB-Reader vor JSON
und den vorhandenen NoRedirect-Handler. Jeder Redirect wird ohne Folgekontakt
verweigert, auch innerhalb desselben Origins. HTTPError-Antworten werden ohne
Bodyread geschlossen. Neue Transport- und Encodingablehnungen bleiben im
bisherigen UNAVAILABLE-/versionNone-Vorschlag isoliert.

Die bestehende Kandidatenauswahl, Zeitparameter, Vorschlags-/Bestätigungsfelder
und Probe-only-Flags bleiben unverändert. Keine Runtime, Konfiguration,
Credentials, Provider oder Netzwerkautorität werden aktiviert. Source und
Capabilitydoc werden mit spezifischen Targetoverride-Gründen an die erhaltene
Original1.19-Provenienz gebunden; sämtliche101 Installedhashes bleiben gekoppelt.
Der [Discoverytest](../../Tests/Documentation/test_foundation_discovery.py)
verwendet tatsächliche AST-Funktionen und synthetischen urllib-Transport;
Testcode alleine ist kein ausgeführter Nachweis. Projektaudit und exakte
Head-/Main-CI bleiben separate Abnahmegates.

Ausgeführt2026-10-07: Das finale `python -X utf8 -B
Tests/Documentation/test_foundation_discovery.py`-Gate bestand acht Methoden
mit60 synthetischen Szenarien unter10s-Prozessbudget, Exit0, vollständige
Erfassung, leerem stderr und stabilen Source-/Testpins. Ein unabhängiger
Sourceagent bestand22 kleine AST-/stdlib-FakeHTTP-Fälle unter8s-Budget.
Root las beide finalen Berichte und Prüfprogramme und verifizierte die
privaten Receipts sowie alle betroffenen Pins ohne Casewiederholung.

Zwei frühere Testharnessgates bleiben FAILED: native TLS-Initialisierung vor
Fakekontakt sowie ein innerer8/60-PASS mit nicht leerem stderr. Der finale
Harness ersetzt beide nativen Transporthandler, schließt auch unbesuchte
eigene Route-Handles und macht Closecanaries nach erfolgtem Close idempotent.
Zwei volle instrumentierte beziehungsweise klassifizierende Diagnosesuiten
und fünf kleine Diagnosen sind separate Diagnosehistorie, keine zusätzlichen
Validierungs-PASS-Nachweise. Die ersten zwei Diagnosecodevarianten wurden
nicht getrennt bewahrt; daraus wird kein reproduzierbarer Nachweis abgeleitet.

Dies ist eine zusätzliche Prüfung des vorhandenen Sources, kein neuer Cloudscan
oder vollständiger Scanabschluss. Initiale Kandidatenvalidierung, DNS-/Proxy- und
Hostvertrauen, Heap-/JSON-Tiefen-/Gesamtzeitqualifikation sowie Pfad-TOCTOU und
reale Endpoints bleiben außerhalb dieses begrenzten Nachweises.

## Begrenzte Discovery-Originwartung2026-10-07

Die weitere Prüfung des bestehenden Konfigurationsclients bestätigte eine
separate Initialgrenze: hostnamebasierte Auswahl allein akzeptierte andere
Schemes, Userinfo und URL-Anhänge; fehlerhaftes IPv6 konnte den nachfolgenden
Standardvorschlag verhindern. Discovery validiert nun vor Transport und
Vorschlag einen credential-freien HTTP(S)-Origin. C0-/C1-Steuerzeichen,
Whitespace, Pfad-/Query-/Fragmentzusätze, Userinfo, kodierte Authorities,
ungültige Ports und fehlerhafte IPv6-Authorities werden abgewiesen.

Die Ablehnung meldet INVALID_ENDPOINT mit endpointNone und ohne Inputecho.
Der sichere Default wird unabhängig weiterbehandelt. Gültige Origins behalten
Loopbackallowlist, Zeitparameter, Nicht-Loopback-Autoritätsgrenze und sämtliche
Vorschlags-/Bestätigungsfelder. Auch der direkte private Probe validiert vor
Requesterzeugung. Die separate gespeicherte Konfigurationsvalidierung bleibt
unverändert. Bestehende Originalversion1.19.0, Quelle, Auswahl und sämtliche
101 Provenienzzeilen bleiben erhalten; nur die beiden vorhandenen
Discovery-Source-/Doc-Overrides werden aktualisiert.

Am2026-10-07 bestanden181 unabhängige aktuelle AST-/Stubfälle;32 historische
Charakterisierungen beobachteten nur gemockte Dispatchfähigkeit und
Defaultisolation, keine tatsächlichen Endpointfolgen. Der erweiterte
[Discoverytest](../../Tests/Documentation/test_foundation_discovery.py) bestand
im10s-OwnedProcess-Gate12 Methoden/266 Szenarien, einschließlich der
unveränderten8 Methoden/60 Transportfälle. Root prüfte Artefakthashes,
Executionbindung und unveränderte bestehende Methoden ohne Fallwiederholung.

Zwei frühere Harnessgates bleiben FAILED: eine Echo-Substringprüfung erfasste
auch den erlaubten Default, anschließend scheiterte eine NUL-Fixture vor dem
Consumer am echten OS-Environment. Zwei enge Diagnosen bestätigten diese
Harnessgrenzen. Die korrigierte Invalidmatrix injiziert ausschließlich den
AST-lokalen Environment-Lookup; Valid-/Barehost-/Defaultfälle behalten das
echte Prozess-Environment und sämtliche Fälle den synthetischen Transport.
Die historischen Programme und Receipts bleiben privat erhalten. Projektaudit
und exakte Head-/Main-CI bleiben eigene Abnahmegates.
Dies ist eine gezielte Sourcewartung im autonomen Securityauftrag. Keine
Runtimeaktivierung, Konfiguration, Credentials, Rechte, SQL-/Labprobe oder
Providererweiterung. DNS-/Proxy-/Hostvertrauen, Heap, Gesamtzeit und Pfad-TOCTOU
sowie vollständiger Cloudscanabschluss bleiben offen.
