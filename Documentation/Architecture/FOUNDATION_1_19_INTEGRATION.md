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
