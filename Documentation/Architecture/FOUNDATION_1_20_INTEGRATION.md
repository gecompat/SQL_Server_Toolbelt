# Foundation1.20: scopebezogene Verarbeitung

Datum:2026-10-09. Autor:Codex. Status:accepted im ausdrücklich beauftragten
Upgrade-/Prozessscope. Die Entwicklungspause bleibt für andere Arbeit bestehen.

## Quelle und Auswahl

Einmalig ermittelter `origin/main` der
[AI Repository Foundation](https://github.com/gecompat/AI_Repository_Foundation):
`39ae5c534bb0cf78046485754ed1be7867bf9534`, Version1.20.0.
Ausgangsinstallation:1.19.0, Commit
`4aafd20442275d0fdedf291fc6e12e8fe1f683cc`.
Manifest, Feature-Katalog und Transferprotokoll stammen aus dem exakten neuen
Commit. Die [vollständige Bewertung](FOUNDATION_1_20_ASSESSMENT.json) enthält
alle21 Kandidaten mit Einführungs-/Materialänderungsgrund und genau einer
Klassifikation. Kein Kandidat wurde wegen bestehender Governance übersprungen.

Die drei Adapter Claude Code, Gemini und GitHub Copilot sowie die neun
bewusst ausgewählten Capabilities aus DEC-2026-030 bleiben erhalten:
`ai-client-integration`, `ai-executor`, `ai-orchestrator`, `ai-provisioning`,
`ai-runtime-adapters`, `ai-work`, `artifact-registration-clients`, `model-router`
und `rule-context-cache`. Sie werden weder konfiguriert noch aktiviert.
`artifact-registry-github` bleibt unselektiert; DEC-2026-028 erhält historische
Referenzen und die Registration-Authority-Grenze. Keine neue Sequenz wird geraten.

105 ausgewählte Manifestzeilen werden deterministisch hashgeprüft. Vier neue
Coredateien, acht geänderte Baseline-Dateien und ausschließlich der markierte
AGENTS-Block werden integriert. Keine pauschale Verzeichnisübernahme.
Die sieben begründeten Overrides bleiben in der
[Installationsprovenienz](../../.ai/foundation/installation-provenance.json)
erkennbar. Die fünf lokalen Adapter-/Provisioning-Sicherheitsdateien haben
unveränderte Quellbaselines; ihre vorhandenen Vor-Dispatch-Redirect-,
Origin- und Responsegrenzen bleiben bytegleich. Copilot behält die zusätzliche
Backlog-Curator-Discovery. Toolbelt-Lizenz, Attribution und Projektregeln
außerhalb des AGENTS-Blocks bleiben geschützt.

## Wirksame Prozessentscheidung

Der frühere Preflight verlangte vor jeder Änderung neue Lektüre. Die
[Arbeitsregeln](../../.ai/WORKING_RULES.md) unterscheiden jetzt scopebezogene
Erstlektüre und lokal geprüfte Wiederverwendung tatsächlich verfügbarer
Sessionanalysen. Arbeitsbaumbytes, Autorität, Scope und semantische Abhängigkeiten
werden aktuell gebunden. Geänderte Regeln invalidieren transitive Verbraucher;
fehlende Analysen oder unbekannte Discoverywerte werden nicht als Treffer behauptet.
Der strengere optionale persistente Cachevertrag bleibt erhalten.

Die [Kostenrichtlinie](../Standards/AI_COST_AND_QUALITY_PROCESSING_POLICY.md)
verweist auf diese kanonische Regel statt eine zweite Reviewkette zu schaffen.
Hashes, Git-/Manifest-/CI-Bindungen, Receiptfelder und PR-Textvergleiche sind
deterministische Arbeit. Zusätzliche Modellreviews brauchen eine konkrete
offene semantische Frage. Erforderliche unabhängige Reviews bleiben erhalten.
Die vorhandene PR311-Abschlusskette enthält getrennte Head-/Main-Adoptions-,
Merge-, Refcleanup-, Publikations- und Body-Peer-Belege. Die Publikation bindet
einen eigenen Peer und zusätzliche mechanische Eintragsprüfungen. Das ist keine erforderliche
Modellreviewkette für Routine-Governanceänderungen: mechanische Bindungen prüft
der Verantwortliche lokal, die unabhängige Semantikprüfung erfolgt am stabilen
Gesamtdiff. Historische Belege werden weder umgeschrieben noch neu qualifiziert.

Gemeinsamer Projektdefault ohne verlässliche Tokenmessung: ein Scope/ein PR,
ein Implementierungsverantwortlicher, ein unabhängiger Reviewagent, höchstens
ein Folgeauftrag an denselben Agenten für geänderte Inputs nach einem Befund.
Root, Agent, Koordination und Wiederholungen teilen diese Grenze. Tokenwerte
bleiben unbekannt. Pflichtprüfungen werden nicht ausgelassen. Die Grenze beendet
neue Arbeit und meldet verbleibende Gates, statt unvollständige Arbeit abzuschließen.

Pausierte Fortsetzungsautomationen bleiben pausiert. Aktive Sicherheitsnetze
dürfen nur nötige begrenzte Rechecks auslösen; kein erneutes vollständiges Lesen
eines unveränderten Wartezustands. Ein echter Inputwait wird einmal verständlich
sichtbar. Handoffs enthalten neue Fakten und aktuelle Referenzen statt langer
Historien. Dieser Auftrag autorisiert keine automatische Fortsetzungswelle.

## Kompatibilität und Alternativen

SQL-/API-Einzelfreigaben, Datenschutz vor jeder konkreten Schreiboperation,
Lizenzschutz, Lab-Ownership, vorhandene Rechte, genaue READY-Zielauswahl,
Transaktions-/Cleanup-Gates und verpflichtende PR-Prüfungen bleiben erhalten.
Diese Schutzgrenzen sind kompatibel stärker; sie begründen keine zusätzliche
Volllektüre. Konflikt war ausschließlich der unnötig wiederholte Preflight.
Abgelehnte Alternativen: reiner Versionswechsel; Konservierung von Aufwand mit
`PROJECT_STRONGER`; neue obligatorische Planner-/Receipt-Infrastruktur;
automatischer Verlust gleicher Analysen bei jedem Commit; Abschwächung von
unabhängigen Reviews oder Sicherheitsgates.

GitHub hatte bei Auswahl keine offenen PRs. SafeCast-Command-Ownership ist über
[PR310](https://github.com/gecompat/SQL_Server_Toolbelt/pull/310) bereits integriert;
keine erneute Implementierung oder neue SQL-Funktion in dieser Welle.
Serverseitige Rulesets/Bypass-Actors werden nicht verändert. Bestehende
No-bypass-Regeln und die Trennung von fehlender und fehlgeschlagener CI bleiben.

## Validierungsscope

Foundationprüfung gegen den gepinnten Manifeststand: ausschließlich
`FOUNDATION_INTEGRITY`. Der einmalige vollständige Projekt-Dokumentationsaudit
prüft Governance/Repo-Map und betroffene statische Verträge einschließlich der
vorhandenen synthetischen Sicherheitsregressionen. Fünf neue Offline-Szenarien
prüfen zweite unveränderte Welle, transitive Invalidierung, neue Instruktion,
fehlende Analyse und unvollständige Discovery. Sie sind Verbrauchertests mit
aktuellen Projektregel-Kopien, keine Attestation realer Clientdiscovery.
Exakte PR-Head-/Main-Pflichtprüfungen werden im PR nachgewiesen.
Keine SQL-/Runtime-/Minimalrechte-/Releasequalifikation durch dieses Upgrade.

Der erste Projekt-Audit fand die historische1.19-Provenienzbindung der
Redirectregression. Deren aktuelle Bindung wird gezielt auf1.20/105 Manifestzeilen
aktualisiert; die fünf Sicherheitsoverride-Baselines, Gründe und tatsächlichen
Dateihashes sowie alle nicht vom Upgrade betroffenen Zeilen bleiben geprüft.
Der fehlgeschlagene erste Audit wird nicht als bestanden dargestellt.

Ausgeführt2026-10-09: Foundation-Vollprofil gegen den gepinnten Quellstand,
109 INFO/5 WARNING/0 ERROR/0 BLOCKING. Die fünf Warnungen benennen die bewusst
erhaltenen, aktuell provenancegebundenen lokalen Sicherheitsdateien; sie sind
keine unbekannte Drift und kein Foundation-Semantikbeweis. Deterministische
Prüfungen bestätigten alle105 Source-/Installed-Hashbindungen, das vollständige
21er-Assessment, die unveränderte Auswahl, die fünf exakten Overrides und
geschützte Projektdateien. Ein allgemeiner JSON-Schema-Validator war in den
vorhandenen Pythonumgebungen nicht verfügbar; das Assessment wurde lokal gegen
die konkreten Pflichtfelder, erlaubten Klassifikationen und exakten Deltaeinträge
geprüft, die Provenienz durch den Foundationvalidator und vorhandene Regression.

Der finale `python -B Tests/Documentation/validate_documentation.py --all`
bestand den vollständigen Governance-/Static-Audit einschließlich8 Redirect-,
9 Response-,12 Discovery- und5 Processing-Verbrauchertests. Die beiden früheren
Auditfehler bleiben fehlgeschlagen: zuerst veraltete1.19-Bindung, anschließend
abweichende Override-Gründe durch einen lokalen Default-Encoding-Read. Letztere
wurden exakt aus der UTF8-Git-Ausgangsprovenienz restauriert, ohne die Overrides
zu verändern. Ein unabhängiger semantischer Review und genau ein Folgeauftrag
zu korrigierter Bewertung/Provenienz-Testdelta sind abgeschlossen, ohne offene
Befunde. Kein zusätzlicher Reviewer oder wiederholter grüner Native-Lauf.
