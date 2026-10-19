# Workflowübergreifende Impact- und Cleanup-Prüfung

Datum: 2026-10-19. Ausgangsbasis: `cc6d095` auf `origin/main`, nach Integration
von PR #331 und #332; keine offenen PRs oder konkurrierenden Arbeitsbranches.
Auftrag: sinnvolle Änderungen aus dem bereitgestellten Entwicklungsvorschlag
integrieren. Ein Arbeitspaket, ein PR, ein Implementierungsverantwortlicher,
keine weiteren Agenten oder automatischen Anschlusswellen. Öffentliche SQL-APIs,
Produktversionen, Releasefreigabe und Lab-Infrastruktur bleiben unverändert.

## Befund und Korrektur

Alle 40 vorhandenen Workflowdefinitionen wurden gegen die tatsächlich
aufgerufenen Shelladapter und deren explizite Modulpfade geprüft. Der bestehende
[Change-Impact-Validator](../Documentation/validate_documentation.py) und die
Registry in [repo_map.yaml](../../.ai/repo_map.yaml) bleiben die Auswahlbasis;
es entsteht kein zweiter Orchestrator und keine Evidence-Registry.

| Befund | Korrektur |
|---|---|
| Nur zwei von 27 direkten CI-Consumern erfassen `run-lab-target.sh` in ihren Pfadfiltern. | 25 fehlende Consumerfilter ergänzt; bestehende Jobs und Matrizen erhalten. |
| Zehn Workflows erfassen nicht alle Source-/Deployment-/Manifestinputs ihrer tatsächlich verwendeten Shell-Consumer. | Fehlende positive Inputs für ResultTable, Generate Series, Date Truncate, Execution Context und Work Type ergänzt. |
| Der pauschale Ausschluss von `Documentation/**` überstimmt sogar den expliziten JSON-Constructor-Binarypin. | Ausschluss auf Markdown begrenzt; JSON, SQL und unbekannte Binärinputs im bereits positiv erfassten Bereich bleiben prüfpflichtig. |
| SSIS erfasst nur eine Parserdatei, obwohl sein Installationsvertrag exakte Parser-/Dependencypins prüft. | Parserbereich im bestehenden Offlineworkflow erfasst; kein behaupteter nativer SSIS-Nachweis. |
| Work-Queue-Push fehlt die gemeinsame Authorizationfixture; Filesystem-Push fehlt die eigene Workflowdefinition. | Beide Filter symmetrisch ergänzt. Ereignisarten und Checknamen erhalten. |
| Der äußere Lab-Cleanup verwirft SQL-/Dateifehler und kann Exit0 oder Exit75 zurückgeben. | Fehler werden gesammelt, weitere Cleanupschritte dennoch versucht, eigene DB-/Linked-Server-Abwesenheit frisch geprüft. Fehler beenden Erfolg/optionale Messung mit Exit1; ursprüngliche Testfehler bleiben erhalten. |
| Die Trustentfernung übergibt einen in EXEC syntaktisch unzulässigen direkten `CONVERT`-Ausdruck. | Konvertierten Hash in lokaler SQL-Variable übergeben; eigene Restores zusätzlich prüfen. |

Es werden keine neuen Rechte erteilt und keine zusätzlichen SQL-Konfigurationen,
Trustobjekte oder Hosts verändert. Die vorhandenen Ownership-/Hash-/Restoregrenzen
werden nicht erweitert. Der Handler deaktiviert seine Traps vor dem eigenen Exit;
dies ersetzt keine Qualifikation harter Prozess-/Hostunterbrechungen.

## Tatsächliche Testgrenzen und Aufwand

Eine ResultTable-Sourceänderung trifft vorher fünf, danach zwölf vorhandene
Workflowfilter; ihr README trifft weiterhin keinen Runtime-/Buildfilter.
Ein Wrapperdelta trifft vorher zwei, danach alle 27 direkten Consumer.
Der Constructor-Binarypin trifft vorher keinen, danach seinen Workflow.
Dies sind deterministisch geprüfte Filterzahlen, keine ausgeführten SQL-Tests.
Der immer laufende Dokumentationsjob wird separat betrachtet.

Die drei ausdrücklich untersuchten Runtimeadapter sind keine identischen Suiten:

| Adapter | Tatsächliche unterschiedliche Testausführung |
|---|---|
| ResultTable full | Eigene API-/Collation-/Transaktions-/Enginefehler-Fixtures, vier echte parallele Sitzungen, Lifecycle und Pflichtlast auf SQL2025/CL170. |
| W4a | Execution-Context-/Error-Envelope-Lifecycle, API je unterstützter CL, eigene MultiSession- und Centralverträge; ResultTable wird als Abhängigkeit installiert. |
| Work Queue | Genuine 1.0→1.1-Upgrade, Lifecycle, API/Authorization je unterstützter CL, Konkurrenz-/Central-/Dependency-/Uninstallverträge; ResultTable wird als Abhängigkeit installiert. |

Je Workflow bleiben drei unterschiedliche physische Engines 2019/2022/2025
und damit insgesamt neun flüchtige Runtime-Jobs/Container dieser drei Suiten
erhalten. Wiederholte Dependency-Deployments gehören zu verschiedenen
isolierten Consumerdatenbanken; kein identischer ResultTable-Test wurde aus
diesen Consumerläufen entfernt. Dies ist eine Quellenanalyse des Startumfangs,
keine Behauptung neun neuer lokaler Nativeausführungen.

Die lokale Standardroute bleibt deterministisch und führt die gewählten Adapter
bereits je zulässigem Ziel aus. SQL-/Session-/Transaktions-/Trust-/Queuezustände
werden nicht über Testgrenzen vermischt. Zusätzliche gemeinsame Container oder
nachweislich sichere globale Leases sind nicht eingeführt. Statische Preflights
auf unterschiedlichen Runnern bleiben wegen der jeweiligen Tool-/Umgebungsbindung
erhalten. Doppelte identische Ausführung im Dokumentationsjob wurde durch PR #313
bereits bereinigt und wird hier nicht neu entwickelt.

| Messgröße | Ergebnis dieser Welle |
|---|---|
| Entfernte Runtimejobs, Containerinitialisierungen oder Workflows | 0; bestehende unabhängige Oracles bleiben erhalten. |
| Neue Workflow-/Jobdefinitionen oder zusätzliche Modell-Testoracles | 0. |
| Vorher-/Nachher-Laufzeitvergleich, Queue-/Bootstrap-/Mutex-/Cleanupzeit getrennt | `NOT_EXECUTED`; keine vergleichbare kontrollierte Zeitreihe. |
| Gemessene Runner-/Token-/Kostenersparnis | `UNKNOWN`; keine Kosten-/Tokenmessung oder erfundene Quote. |
| Review-/Logverarbeitung | Lokale deterministische Fehler-/Statusauswertung; keine zusätzliche Modellbestätigung grüner Läufe oder Reviewkette. |

Die Filterkorrekturen erhöhen erforderlichen Prüfaufwand bei zuvor übersehenen
Inputs. Es wird keine Laufzeitersparnis aus dieser notwendigen Abdeckung behauptet.
Die großen fachlichen Lastfälle aus PR #330/DEC-2026-036 bleiben unverändert Pflicht;
optionale Zeitreihen werden nicht für eine reine Statusauffrischung ausgeführt.

## Regression und begrenzte Nativeprüfung

Reproduzierbare Offlinebefehle ohne Lab-/Docker-/SQL-Zugriff:

```powershell
python -B Tests/Documentation/test_change_impact.py
python -B Tests/CI/validate_lab_selector.py
# Nur bei Änderung des gemeinsamen Orchestrators/Validators vollständiger Audit:
python -B Tests/Documentation/validate_documentation.py --all
```

Der erste Befehl ist bereits im vollständigen Audit enthalten; er wird am selben
unveränderten Inputstand nicht zusätzlich als neuer Nachweis benötigt.
`validate_lab_selector.py` enthält den separat aufrufbaren
[Cleanup-Harness](test_lab_cleanup.py). Dieser extrahiert die echte Shellfunktion
und ersetzt ausschließlich SQL-/Dateieffekte durch synthetische Antworten.
Er prüft alle sechs SQL-Schritte im CLRzweig einzeln fehlerhaft, privaten
Removefehler, unveränderten vorhandenen Trust-/Konfigurationszustand, Exit7,
Exit75 und den normalen Erfolgsweg. Ein Exit75 mit Cleanupfehler ist ein Fehler,
keine nur fehlende Zeitmessung. Native Oracle- und Clearanceaussagen folgen daraus
nicht.

Am 2026-10-19 bestanden lokal:

- Vollständiger Dokumentations-/Manifest-/Statikaudit über 45 Module und alle
  registrierten Impact-Pakete erfolgreich. Grund: geänderte Kopplungsregistry
  und globale Testpolicy; keine daraus abgeleitete neue Modulqualifikation.
- 16 Change-Impact-Regressionen, einschließlich aller 27 direkten Wrapperconsumer,
  expliziter Shell-Module, gemeinsamer Authorizationfixture, Parserpins,
  JSON-Oracleinputs, reiner Markdownänderungen und eigener Workflowdefinitionen.
  Die bereits vorhandenen Unknown-/Global-Fallback- und Selbsttestfälle bleiben
  enthalten. Dies ist die verwendete eingeschränkte Globsyntax, kein Nachbau
  der vollständigen GitHub-Filterengine.
- 17 synthetische Labselektorfälle, 21 Lab-TLS-Contractfälle, 13 SqlClient-
  Policyfälle und sechs Shell-TLS-Testmethoden; keine TLS-/Targetausweichwahl.
- Sieben Cleanup-Testmethoden mit positiven und negativen Unterfällen.
- Sechs synthetisch gebundene Cleanup-SQL-Batches mit ScriptDom auf SQL150,
  SQL160 und SQL170: 18 Syntaxprüfungen. Die zunächst sechs Syntaxfehler in
  den beiden Trustbatches wurden durch die lokale Hashvariable behoben.
- Ein vollständiger ResultTable-Labadapter auf dem schema-validierten bereiten
  SQL2025-Linux/latest-Ziel mit `TestPurpose=Functional`: lokale/zentral
  Installation, bestehende fachliche Fixtures einschließlich vier Sitzungen,
  Pflichtlast/CL170, Lifecycle, Uninstall und neuer frischer OwnDB-/Linked-Server-
  Cleanupaudit erfolgreich. Keine Konfigurations-/Rechte-/Truständerung.
  Der anschließende Syntaxfix betrifft ausschließlich den in diesem Lauf
  nicht verwendeten CLRzweig; der ausgeführte Nicht-CLRpfad bleibt unverändert.

Aktuelle PR-CI wird separat am tatsächlichen Head geprüft und im PR referenziert.
Ein lokaler Erfolg wird dabei weder als Remoteausführung noch als aktuelle
Support-/Releasequalifikation aller Module dargestellt.

## Offene Grenzen und Fortsetzungsbedingungen

| Bereich | Stand und Voraussetzung |
|---|---|
| Automatisches Local-to-Remote-Reuse | `NOT_IMPLEMENTED`. Es fehlt eine unabhängige vertrauenswürdige Host-/Runnerattestierung und ein geschützter aktueller CI-Verifikator. Selbst erzeugtes JSON, Sourcehash oder Modellurteil genügt nicht. Bestehende CI bleibt `EXECUTE_REQUIRED`. |
| Spätere Reuse-Abnahme | Positive aktuelle Attestierung samt tatsächlichem Required Check sowie negative Fälle für Manipulation, untrusted Quelle, Frische/Widerruf, unvollständige Oracles/Cleanup, Inputs/Engine/CL/Rechte/Transport, externe Drift und abweichende Head-/Integration-/Merge-Groupbindung sind vor Aktivierung Pflicht. Hier wird kein erfolgreicher Reusepfad behauptet. |
| Unbekannter Impact | Bestehender konservativer vollständiger Dokumentations-/Manifest-/Statikaudit; kein erfundener Native-PASS. Neue Module, dynamisch zusammengesetzte Consumerpfade und unbekannte externe Dependencies benötigen weiterhin explizite Impact-/Workflowpflege. |
| Physische Windows-/SQL2019-/2022-/CLR-Restores | Neue native Ausführung in dieser Welle `not executed`; Shell-/Syntaxkontrollen ersetzen keinen realen Trust-/Konfigurationsrestore. Nur bei diesem zusätzlich gewählten Scope explizite bereite Labziele und qualifizierte Binaries verwenden. |
| Foreign-state-/Hard-Interrupt-Recovery | Bestehende Isolation nicht verändert; kein neuer Nachweis für konkurrierende fremde Änderungen, Hostausfälle oder abgebrochene Ressourcenverbraucher. Keine Labstopps oder Recoveryaktionen aus diesem Auftrag. |
| Authentifiziertes TLS und Release | Getrennt offen; weder aus Functional noch aus Build-Provenance abgeleitet. Andere pausierte Aufgaben bleiben pausiert. Kein eigenmächtiger Merge. |

Maßgeblich bleiben die [Testregel](../../Documentation/Standards/TEST_AND_VALIDATION_POLICY.md)
und die [Arbeitsregeln](../../.ai/WORKING_RULES.md).
GitHub beschreibt [geordnete Pfadfilter](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore),
[aktuelle Required Checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks)
und [Artifact Attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations).
Build-Provenance allein attestiert keinen erfolgreichen vollständigen SQL-Test.
