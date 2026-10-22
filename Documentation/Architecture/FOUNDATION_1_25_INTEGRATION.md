# Foundation 1.25: Integration und Lesewege

Stand: 2026-10-22. Der Benutzer beauftragte die autonome Übernahme der aktuellen
Foundation nach sauberem Main, Merge und Branchcleanup. Dieser Ausgangszustand
ist erreicht. Der Upgrade verändert keine öffentliche SQL-Funktion und
erweitert keine bestehenden Runtime-, Infrastruktur- oder Kampagnenfreigaben.

## Quelle und vollständige Featurebewertung

Installiert war 1.24.0 aus Commit
`96391403a1b89e19d4824838806d7190d8033389`. Die ausdrücklich frisch geprüfte
[Upstreamquelle 1.25.0](https://github.com/gecompat/AI_Repository_Foundation/tree/9e1b9974de58ea775d40c7c6045cd5057ba8b30c)
ist Commit `9e1b9974de58ea775d40c7c6045cd5057ba8b30c`.
Manifest und Featurekatalog dieses identischen Stands sind maßgeblich.

Der vollständige Katalogdelta enthält genau `human-documentation-paths`,
eingeführt in 1.25.0. Die [maschinenlesbare Bewertung](FOUNDATION_1_25_ASSESSMENT.json)
klassifiziert es einmal als `APPLY_DEFAULT`. Die erforderliche Richtlinie
gilt für neue oder materiell geänderte vollständige Lesewege einschließlich
notwendiger Folgeseiten. Es gibt keine ausgelassene Empfehlung, offene
Adoptionsentscheidung oder neue optionale Capability.

## Transfer und erhaltene Projektverträge

Die bestehenden drei Adapter und neun Capabilities bleiben ausgewählt.
Alle 112 ausgewählten Manifestdateien werden gegen portable SHA-256-Hashes
geprüft und im erneuerten [Receipt](../../.ai/foundation/installation-provenance.json)
erfasst. Zehn Ziele ändern sich: neun Baselines und die verwaltete Root-Bridge.
Außerhalb dieser Bridge bleibt AGENTS unverändert. Die neun anderen
intentionalen Projektabweichungen bleiben bytegenau erhalten; zusammen mit
AGENTS sind weiterhin zehn Overrides erklärt.

Dazu gehören exakte Budgetarithmetik, sichere gehaltene Handles, ausdrückliche
Remoteautorität, Redirect-/Response-/Discoverygrenzen und die gesperrte
Stdio-Nutzdateninvocation. Der Root-Lizenzblock, LICENSE, Attributionen,
historische Kennungen und ältere Integrationsnachweise bleiben unverändert.
Quellen-README, Projektzustand, Registry und unselektierte Dateien der
Foundation werden nicht übertragen. Keine Runtime, kein Provider und kein
Scheduler wird durch den Transfer aktiviert.

Die neue Dokumentationsregel ist `COMPLEMENTARY`; Sprache und geeignete
Ablage bleiben `PROJECT_SELECTABLE_OVERRIDE`. Datenschutz, SQL-Freigaben,
Cleanup und tatsächliche aktuelle CI bleiben `PROJECT_STRONGER`. Aktive
Regeln bleiben über AGENTS, Projektregeln, Arbeitsregeln und den kanonischen
Dokumentationsstandard erreichbar; es entsteht keine doppelte Fachautorität.

## Geprüfte menschliche und technische Pfade

Die vorhandene Struktur bleibt erhalten. Der neue frühe Root-Einstieg führt
zur [Dokumentationsübersicht](../README.md), statt Produktleser zuerst durch
die umfangreiche Testhistorie zu schicken. Geprüfte Fortsetzungen:

| Leseraufgabe | Pfad und Abnahmeumfang |
|---|---|
| Modul auswählen und vorbereiten | Root-Einstieg → Dokumentationsübersicht → Modules/README → Modulbeschreibung und Objektseite; Plattform und Manifeststatus sind vor Verwendung zu prüfen |
| Deployment verstehen | Dokumentationsübersicht → Deployment-Modell → Deployment/README; PowerShell/sqlcmd, PlanOnly, bewusste Zielwahl, CLR-Voraussetzungen, getrennte Modultransaktionen und Fehlergrenzen sind beschrieben |
| Aufruf und Ergebnis untersuchen | Dokumentationsübersicht → Reference/README → API-Katalog/Objektseite sowie CONTRIBUTING; Beispiele nicht gesammelt ausführen, Resultate und Grenzen am Objektvertrag prüfen, Herkunft und private Belege für Abweichungen erhalten |
| KI-/Maschineninformationen untersuchen | AGENTS → Foundation-Ruleset und .ai/README → Projektkopplung beziehungsweise Receipt/Schema → bestehende Generator-/Validierungsanleitung; Autorität, Ableitung, Fehleruntersuchung und fehlende Evidenz sind getrennt benannt |

Dies ist eine begrenzte semantische Pfadprüfung, kein praktischer
Neuinstallations- oder Modul-Runtimeversuch. Das Deployment- und
API-Referenzmaterial bleibt fachlich unverändert. Der neue Einstieg erklärt
seine Voraussetzungen, nächste Schritte, erwartete Planausgabe, deren
Interpretation und die Grenzen bei Abweichungen.

Die [konkret geplanten Altlasten](../../.ai/BACKLOG.md#dokumentationspflege-aus-foundation-125--2026-10-22)
betreffen die spätere Entflechtung des Root-Statusverlaufs, die vorangestellte
CSV-Testchronologie und vergleichbare jeweils betroffene Modul-/Testanleitungen.
Scope, verantwortliche Rolle und Auslöser sind dort erfasst. Die nächste
CSV-Welle muss ihren Testlesepfad vor dem Review bereinigen und die bisherigen
datierten Nachweise sowie ihre Verbraucher erhalten. Dieser Upgrade ist
mit dieser Übergangsplanung abschließbar; vollständige Dokumentationskonformität
des gesamten Repositorys wird ausdrücklich nicht behauptet.

## Erforderliche Bewertung des Verarbeitungsaufwands

| Tatsächlicher Weg | Disposition und Schutzgrund |
|---|---|
| Testauswahl | Bestehende Change-Impact-Auswahl bleibt erhalten. Die zwei aktuellen Assessmentverweise ändern die Kopplungsregistry; deshalb ist nach bestehender Projektregel ein voller Offline-Dokumentationsaudit nötig. Das Upgrade allein startet keine SQL-Matrix. |
| Doppelte Prüfungen | Foundation-Validator prüft Transfer/Provenienz, der Projektaudit prüft Projektkopplung und bestehende Securityregressionen. Ihre unterschiedlichen Orakel bleiben erhalten; grüne Suites werden ohne geänderte Bindung nicht wiederholt. Keine neue Validator-Selbsttestsuite für reine Dokumentationsänderungen. |
| Logs und Modellkontext | Lokale deterministische Prüfer liefern begrenzte Findings und Status. Rohlogs und private Wiederherstellungsjournale bleiben lokal. Geänderte Dokumente und notwendige Fortsetzungen werden gelesen; unveränderte unabhängige Korpora werden nicht erneut eingelesen. |
| Review | Ein Implementierungsverantwortlicher, ein unabhängiger Review des festen Diffs und höchstens ein gezielter Folgeauftrag nach konkretem Befund. Kein Review des Reviewberichts und kein zusätzlicher CI-Leseagent. |
| Warten und Fortsetzung | Begrenztes Backoff für exakte Head-CI und tatsächliche Main-Push-CI. Der bestehende Heartbeat beachtet jüngste menschliche Steuerung und gültige Grenzen; unveränderte Blocker bleiben still. |
| Budget | Ein kohärenter Upgrade-PR innerhalb des Projektdefaults. Token-/Kostenmessung unbekannt. Der private gemeinsame CSV-Ledger und bereits verbrauchte Versuche/Reviews bleiben erhalten; der Upgrade erzeugt keinen Budgetreset. |

## Validierung und Grenzen

Vor dem Merge ausstehend: Foundation-Integrität mit der erhaltenen Auswahl,
voller Offline-Projektaudit, fester unabhängiger Review und exakte Head-CI.
Merge, tatsächliche Main-Push-CI und eigener Branchcleanup folgen erst nach
diesen Gates. Die konkreten Resultate werden nach Ausführung im bestehenden
PR-Nachweis dokumentiert.

Native SQL-/Lab-, Live-Provider-, authentifizierte TLS- und reale
Modellabnahmen sind `not applicable` für diesen reinen Governance- und
Dokumentationsscope. Vorhandene Nachweise bleiben an ihre jeweiligen
Quellen und Grenzen gebunden. GitHub-Administrationsschutz oder serverseitige
Required Checks werden weder geändert noch allein aus grüner CI abgeleitet.
