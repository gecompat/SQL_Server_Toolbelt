# Freigegebene Security-Korrekturen vom 2026-10-14

Benutzerfreigabe: alle 13 technisch vorbereiteten Korrekturen einschließlich
des besprochenen Verhaltens von SC-039 und SC-042. Quellen und deduplizierte
Cloudreferenzen stehen im [Backlog](../../.ai/BACKLOG.md). Die Umsetzung begann
mit SC-034, SC-042 und SC-043. Der folgende Stand bezeichnet den geprüften
Arbeitsbaum dieser Korrekturwelle; historische Modulnachweise bleiben historisch.

| Gruppe | Prio | Umgesetzte Korrektur | Gezielter Nachweis vom 2026-10-14 |
|---|---|---|---|
| SC-034 | P1 | Beide HTTP-Provider verlangen bei LOCAL_NETWORK, REMOTE und UNKNOWN exakt den booleschen Wert `remote_authorized=true`, bevor Handles gelesen oder Transporte aufgerufen werden. | Offline: fehlend/false/1/String abgewiesen, true positiv; 10 Methoden/111 Szenarien einschließlich bestehender Responsefälle. |
| SC-042 | P1 | Automatisches catch-all Mapping sofort entfernen; nur ORIGINAL_LOGIN mit denselben vorhandenen Testloginrechten mappen. Katalogassertion verlangt exakt dieses eine Mapping. | W5a/W5b-Labadapter auf Linux SQL2019/latest bestanden, einschließlich Second-Session- und EventLog-Verträge. |
| SC-043 | P1 | Alle registrierten Evidence-Ziele aller Module vor dem ersten Write prüfen: vorhandenes Markdown im Repository, kein Gitmetadatenpfad oder Windows-ADS/Alias. | Synthetische Mehrmodulprobe: ungültiges späteres Ziel verhindert auch das erste gültige Write; externe und Gitdateien bleiben unverändert. |
| SC-012 | P1 | Exakte Escapingkosten aller Einträge und Syntax vor vollständigen expandierten Stringfragmenten prüfen. Begrenzte UTF-16-Spans verwenden denselben bekannten CLR-Escapekern; Fehlerreihenfolge bleibt erhalten. | Constructor-Suite auf Linux SQL2019/latest CL150 local/central bestanden: vier Fixtures, 16-MiB-/100000-Grenzen, exakte Escapegrenze, Surrogatpaar an Spangrenze, Repeat/Uninstall und Cleanup. |
| SC-014 | P1 | Alle neun SQL-CLR-Einstiege verwenden SqlChars-Length-Prüfung vor begrenztem Read/managed String. Gemeinsame Fachkerne; R2 teilt eine Deadline über Intake und Auswertung. | Releasebuild; acht Frameworkfälle einschließlich Intake; native bestehende Regex-/Transformations-/Relations-/Capture-Suites und neuer Neun-Einstiegs-Test local/central auf Linux SQL2019/latest bestanden; Capture-Metadaten und Centralprobe bestanden. |
| SC-028 | P1 | Laufwerksrelative Namen, alleinstehendes `..` und nicht kanonische Dotsegmente nicht als sicher klassifizieren. | 14 Listingvektoren über kompilierten Provider sowie bestehende Writer-Frameworksuite bestanden. Frisches natives ZIP-Deployment, Reader-/Writer-Contracts auf Linux SQL2019/latest CL150 bestanden. |
| SC-029 | P1 | Legacyclaims innerhalb der Lifecycle-Transaktion unter TABLOCKX/HOLDLOCK erneut prüfen und Sperre bis zum Abschluss halten. | Bestehender Queueadapter plus zwei synchronisierte native Sessions: nach Preflight hinzugekommener Claim führt zu 51948/State4 ohne Migration; nach gesperrter Prüfung blockiert ein neuer Claim bis zum Abschluss. |
| SC-039 | P1 | Direkte Envelope-Ausgabe ohne Temp-DDL/INSERT, auch bei doomed Caller. ResultTable dann vor Mutation mit 51406 abweisen; Caller führt Rollback/Rethrow selbst aus. | W4a-Contract mit natürlichem Constraintfehler und Original-Rethrow; SqlClient prüft alle 14 Spalten, Typen/Nullability, genau eine Zeile und direkte Debugmeldung. |
| SC-030 | P2 | Summen und Budgetvergleiche rational aus den validierten dezimalen Zahlenwerten berechnen. JSON-Ausgaben bleiben Zahlen. | Synthetische exakte 0.01-/0.1-Grenzfälle in TOKENS/CREDITS/USD und Dedup; bestehende Processingtests bestanden. |
| SC-032 | P2 | Vor Blockerabschluss ausdrücklich BARRIER_WAIT und kein Barrierclaim im Resultset verlangen. | Vollständiger Queue-Contract sowie zwei negative Injektionen des tatsächlichen Assertblocks bestanden. |
| SC-035 | P2 | Logziel nur innerhalb des Repositorys, außerhalb `.git`, ohne ADS/Windows-Alias und existierende Reparsekomponenten; direkt vor Write erneut prüfen und LiteralPath verwenden. | Synthetische PowerShellprobe für Traversal, absolute Pfade, Gitmetadaten, ADS, Dot-/Spacealias, Junction und gültigen relativen Pfad bestanden. |
| SC-037 | P3 | Identifierparser im Inline-Audit ausdrücklich als MSTVF mit offener Alternative/Ausnahme ausweisen. | Dokumentationsabgleich; keine Behauptung einer neuen Inline-Implementierung. |
| SC-044 | P3 | Überschreibende SQLCMD-setvar-Defaults entfernen; Betreiber muss RootAlias/RelativePath bereitstellen. Leerer/Platzhalteralias wird abgewiesen. | Source-/Aufrufabgleich; echter Windows-Caller-Smoke mit Betreiberalias nicht ausgeführt. |

## Reproduzierbare Prüfpfade

- `python -X utf8 -B Tests/Documentation/test_security_maintenance.py`:
  drei Testmethoden; darin PowerShell-Logpfadprobe, Mehrmodul-Writepreflight und
  Dezimalbudgets. Keine Produktdaten oder Netzwerkaufrufe.
- `python -X utf8 -B Tests/Documentation/test_foundation_http_response.py`,
  `test_foundation_processing.py`, `test_foundation_redirects.py` und
  `test_foundation_discovery.py`: synthetische gezielte Foundationregressionen.
  Die Redirectprobe bindet alle 105 installierten Dateien samt begründeten Overrides.
- `Tests/CI/run-lab-local.ps1 -Versions 2019 -Platforms linux -RunScripts ...`:
  zuerst W5a/W5b, Queue, W4a; nach Debug-/Metadatenkorrektur W5a/W5b/W4a erneut.
  Die Adapterdateinamen und Parameter stehen in [CI](../../Tests/CI/README.md).
- `Tests/CI/run-security-contracts-lab.ps1`: schema-valides explizites Einzelziel,
  zwei Queue-Races, zwei Barrier-Negativfälle und Envelope-Clientprobe. Nur die
  eigenen GUID-Datenbanken werden erstellt und nachher mit Existenzprüfung entfernt.
- `Tests/CI/run-regex-captures-lab.ps1 -Version 2019 -Platform linux -Patch latest
  -ReleaseDirectory <frischer Releaseoutput> -ApiQualificationOnly
  -ApiDeploymentMode local|central -OptInExactTrust
  -PrivateJournalDirectory <privat außerhalb Git>`: jeweils separater Lauf.
  Der Build und der Runner prüfen die vollständige aktuelle Sourcefingerprintliste.
- `Modules/toolbelt.archive.zip-memory/Tests/Runtime/Writer.Framework.ps1`:
  Windows PowerShell 5.1 mit exaktem Hash/Länge des frisch gebauten Releaseoutputs
  und neuem privatem EvidenceDirectory; unveränderte Binaryaufnahme und Read-Lease.
- `Tests/CI/run-security-zip-lab.ps1 -ReleaseDirectory <frischer Releaseoutput>
  -OptInExactTrust`: fokussierte frische API-Qualifikation auf Linux SQL2019/latest;
  unverändertes CLR-strict-security, keine implizite Serverkonfiguration. Eigenes
  Trustjournal außerhalb Git; Entfernen nur bei exakter Ownership und ohne Verbraucher.

Native Läufe speicherten Originalausgaben, ausgewählte Zielangaben und Trustjournale
ausschließlich privat. Der fokussierte ZIP-Lauf ersetzt keinen historischen
1.2-Upgradefall; der allgemeine Adapter konnte ohne diese Fixture nicht abschließen.
Eine zwischen zwei parallelen SQL-Läufen beobachtete benannte Temp-Constraint-Kollision
wurde durch serielle Ausführung aufgelöst. Fehlgeschlagene Diagnoseversuche zählen
nicht als PASS. Für den neuen Regex-Negativtest wurde ein falsches FT-Präfix im
Test auf den vorhandenen TVF-Namen korrigiert.

## Reichweite und Verarbeitung

Dies sind gezielte Korrektur- und Integrationsnachweise, keine vollständige neue
SQL2019/2022/2025-Windows-/Linux-Releasequalifikation. Regex-Upgrades, vollständiger
Regex-Lifecycle, neue Minimalrechte, echter manueller Windows-Caller und harte
Prozessunterbrechung/Cleanup sind hier nicht ausgeführt. Die bisherigen Modulversionen
und der unveröffentlichte Releasezustand bleiben erhalten. Cloudmeldungen wurden
in dieser Welle nicht geschlossen; dafür ist ein erneuter Scan des integrierten
Codes gesonderte Evidenz. Die übrigen 25 Designgruppen sind nicht implementiert.

Foundation bleibt 1.21.0 mit unveränderter Quellpin-/Capabilityauswahl. Zwei bestehende
Overridebegründungen wurden für SC-034 erweitert und der Dezimalfix als gezielter
weiterer Override dokumentiert; installierte Hashes binden den aktuellen Inhalt.
Keine Runtime oder Automation wird dadurch aktiviert. Overhead: ein kohärenter
13er-Scope, ein Reviewer und ein Folgeauftrag ausschließlich zu konkreten Befunden;
keine zusätzliche Reviewkette. Die Offlineprüfung ist über die Repo-Map selektiert;
Registry-/Validatoränderungen erfordern einmal den Gesamtaudit. Neue SQL-Prüfungen
sind ausdrückliche lokale Testbefehle und erzeugen keinen periodischen Scan.

Die unabhängige Sourceprüfung fand ADS-Umgehung und verlorene Debugmeldung im
ersten Kandidaten; beide wurden korrigiert und regressionsgeprüft. Die begrenzte
Nachprüfung meldete keine weiteren Blocker in diesen geänderten Inputs. Der
Reviewer führte keine SQL-Tests aus; sein Bericht ist kein CI-Nachweis.

Der Gesamtaudit reparierte zusätzlich den bereits abweichenden generierten
Windows-Filesystem-Evidenzblock nach dem Manifest. Die ältere dort dokumentierte,
im Manifest fehlende Aussage vom 2026-10-13 bleibt als historischer Eintrag
erhalten. Diese Synchronisierung ist kein neuer Windows-Runtimenachweis.

Der vollständige Dokumentations-/Konsistenz-Audit (`python -X utf8 -B
Tests/Documentation/validate_documentation.py --all`) bestand am 2026-10-14
für alle 44 Modulmanifeste einschließlich der neuen Regressionen. Der
Foundationvalidator aus dem exakt gepinnten d720db4f-Sourcearchiv bestand mit
`--target . --profile full` und unveränderter expliziter Adapter-/Capabilityauswahl;
das Manifest wurde vor Ausführung gegen die installierte Quellpin geprüft.
Das belegt FOUNDATION_INTEGRITY, keine vollständige Releasequalifikation.
