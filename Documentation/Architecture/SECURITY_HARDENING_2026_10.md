# Freigegebene Security-Härtung vom 2026-10-15

Status: ausdrücklich zur Implementierung freigegeben; Umsetzung und Nachweise
werden getrennt geführt. Autor: Codex. Ausgangsstand: `58436b0`.

Nach Besprechung der Zwecke, Verträge, Alternativen, Risiken und Migration hat
der Benutzer alle folgenden 25 Punkte ausdrücklich freigegeben, einschließlich
UNSAFE für SC-023, Cancellationquoten sowie NULL-/Leermengenverhalten.
Der Auftrag umfasst autonome Umsetzung, Tests und gekoppelte Dokumentation
in der nachfolgenden Reihenfolge. Cloudstatus ist kein Implementierungsstatus.

## Klarstellung SC-045 vom 2026-10-16

Der [gebundene V2-Consumer](LAB_QUALIFIED_TLS_CONSUMER.md) ergänzt den
qualifizierten Cutover vom 2026-10-22. V2-Bytes werden im
gewählten Labkontext vor Clientverbindungen erneut geprüft; V1-Functional
bleibt erhalten. Die gemeinsame native Windows-Abnahme bestand alle sechs
Containerprofile mit beiden echten Stacks, Signatur-Negativfall und eigenem
Cleanup. Linuxclients und Hyper-V bleiben offen; CI wird in den zugehörigen
PRs geführt. Die Windows-Teilmatrix ist kein pauschaler SC-045-Abschluss.

Der Benutzer hat die pauschale Blockierung unabhängiger Funktionsprüfungen
durch die Lab-TLS-Qualifikation ausdrücklich aufgehoben. Aktuell gelten
[getrennte Testzwecke](../Standards/TEST_AND_VALIDATION_POLICY.md#fachtests-und-verbindungstransport):
`Functional` übernimmt den schema-validierten booleschen Trustwert bei
Encrypt=True; `AuthenticatedTls` verlangt False. Ein Fachtest mit True
belegt keine Serverzertifikatsprüfung. Die frühere pauschale Sperre in den
historischen Nachweisen unten beschreibt den damaligen Stand.

Der gemeinsame Connection-Builder, Preflight, sqlcmd-Adapter und SQLClient-
Metadatenhelper verwenden diese Trennung. Der lokale Runner reicht Testzweck
und Vertragswert weiter und stellt Prozessvariablen anschließend wieder her.
Metadatenaufrufer übernehmen den Zielwert. Kein automatisches Umschalten bei
Fehlern, keine Ziel-/Providerersetzung, keine Lab-/Zertifikats-/Truststoreänderung.
Der Aufruf `run-lab-local.ps1 -TestPurpose AuthenticatedTls` bleibt mit einem
Trust-Override-Vertrag gesperrt. Authentifizierte Lab-Livequalifikation und
Cloudabschluss bleiben offen. Für einen tatsächlich zertifikatsabhängigen
Funktionsvertrag ist der strenge Testzweck erforderlich.

**Verarbeitungsaufwand:** Die Änderung verwendet bestehende Adapter und
`validate_lab_selector.py`; keine neue periodische Prüfung, Reviewkette oder
Providerprovisionierung. 17 Selektionsfälle bleiben unverändert, 21
Builderfälle und 13 SQLClient-Policyfälle prüfen beide Testzwecke; sechs
Shelltests sichern die CLI-Grenze. Der betroffene Dokumentations-/Governance-
Audit läuft am stabilen Stand. Native SSIS-Fachnachweise stehen separat in
der [Modulprüfmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md);
andere Modul-Runtime-Matrizen werden durch diese Transportkorrektur nicht erneut qualifiziert.
Keine zusätzlichen Modellreviews oder Agenten; Kosten-/Tokenmessung unbekannt.
Der erste Gesamtaudit fand die nach der AGENTS-Änderung veraltete installierte
Root-Provenienz. Deren einzelner Installedhash und begründeter Projekt-Override
wurden an die freigegebene Klarstellung gebunden. Der Folgeaudit verlangte
zusätzlich den aktualisierten exakten Snapshot der vollständigen
Installedhash-/Grundprojektion. Dieser Prüfwert wurde für die nachgewiesene
Änderung ausschließlich der AGENTS-Zeile fortgeschrieben, ohne Felder oder
Dateien von der Prüfung auszunehmen. Foundation-Bridge, Quellpin, Version,
Auswahl und übrige 104 Transferzeilen bleiben unverändert; kein SQL-Wert-,
Typ- oder Security-Gateorakel wurde gelockert. Der erneute Audit ist ein zuvor
unerfüllter Gate.

| Welle | Punkte | Verbindlicher freigegebener Scope |
|---|---|---|
| 1 | SC-046/026/027/041 | Gemeinsame Work-Type-Policy: ENQUEUE, CLAIM, EXECUTE_NEW_SESSION; explizites Allow, Deny vor Allow, keine automatische Rechteübernahme. Claim zusätzlich Handler-EXECUTE; lokales Second-Session-Startrecht zusätzlich Remote-EXECUTE. Payload höchstens 1 MiB vor JSON/RPC. |
| 1 | SC-009/017/016 | ServiceAccount nur mit eigener Rolle und Rootfreigabe; Schemaowner dbo und vertrauenswürdige Kontrollprincipals; DRAIN_BARRIER ohne Callertransaktion. |
| 2 | SC-010/023/040 | Plattformgebundene Handleoperationen ohne unsicheren Pfadfallback; gesonderter nativer UNSAFE-Windowsprovider mit Root-/Zielbindung für alle neun APIs; Text/BOM/Größe aus einem Byte-Snapshot. |
| 2 | SC-045 | Eigene Lab-TLS-Abnahme mit CA-/Hostnameprüfung und ohne Trust-Override; unabhängige Fachtests bleiben mit dem schema-validierten Labvertrag möglich, gemäß Klarstellung vom 2026-10-16. Zertifikatsbereitstellung und Truststorepflege bleiben externe Labverantwortung. |
| 3 | SC-004 | ZIP-Entry Default 16 MiB, Hardlimit 64 MiB in Binary-/Dateifassade; deklarierte und tatsächliche Größe; keine MemoryStream-Abschlusskopie. |
| 3 | SC-005 | Listing atomar vor erster Ausgabe: höchstens 10000 Einträge, Tiefe 64, 16 MiB gespeicherte UTF-16-Pfade. |
| 3 | SC-002/011 | Count/Instr: kooperativ 500 ms insgesamt, 100000 erfolgreiche Matchschritte. Replacement: kompakte Spans, maximal 65536 Teile, bestehende R2-Deadline auch im Parser. |
| 4 | SC-006 | 64 MiB kumulative an OPENJSON übergebene Bytes vor Aufruf; INVALID/WORK_LIMIT, kein Value; bestehende 16-MiB-/128er-Grenzen bleiben. |
| 4 | SC-013 | Unquoting: validierte Spans und einmaliger Aufbau; Semantik und 65536 Codeeinheiten bleiben. |
| 4 | SC-015 | Dauerhafte irreversible Cancellation ohne Purge: atomar 100000 Zeilen je DB und 10000 je anforderndem Principal; Wiederholungen bleiben bei voller Quote idempotent. |
| 4 | SC-018 | Begrenzte Statusoberfläche für höchstens 1000000 Reihenzeilen; mathematische Alt-APIs nur für vertrauenswürdige Nutzung. Befund bleibt bei untrusted Legacydirektzugriff offen. |
| 4 | SC-019 | Base64 Encode höchstens 16 MiB Binary; Decode höchstens 24 MiB Rohtext und 16 MiB Ergebnis. Statusvarianten; bisherige Wertfassaden bei Oversize NULL. |
| 4 | SC-020 | Split höchstens 64 KiB UTF-16-Input, 64 unterschiedliche Separatorcodeeinheiten, 10000 Tokens. Statusvariante; bisherige Token-TVF bei Limit ohne Zeilen, keine Teilmenge. |
| 4 | SC-021 | URI höchstens 64 KiB UTF-16-Input und 1 MiB Ergebnis. Statusvarianten; bisherige Wertfassaden bei Limit NULL. |
| 4 | SC-022 | JSON Path: 16 MiB Input, Tiefe/Segmente 128, Frontier 10000, kumulativ 64 MiB Parserarbeit; Statusvariante, bestehende Fassade bei LIMIT NULL statt 0. |
| 4 | SC-024 | Zusätzliche ausdrücklich aufgerufene RecordedAtUtc-Retention samt Index und begrenzten Batches; bisherige OccurredAtUtc-Retention bleibt. Kein Job und keine Deploymentlöschung. |
| 4 | SC-038 | Console maximal 1 MiB UTF-16 und 512 Frames; Fehler vor erstem Frame, keine Kürzung. |

## Verarbeitung und Abnahme

Endlicher Gesamtscope: genau diese 25 Punkte in vier geordneten Teilwellen,
ein Implementierungsverantwortlicher, keine zusätzliche Funktionswelle.
Checkpoints nach jeder Teilwelle, reproduzierbare Quellen und Prüfevidenz.
Verlässliche Token-/Kostenmessung fehlt; keine monetäre Budgetbehauptung.
Zusätzlicher unabhängiger Review nur für eine konkrete offene Sicherheitsfrage.
Ein blockierter Labvertrag stoppt keine unabhängige freigegebene Teilwelle.

Abnahme: Grenzwerte darunter/exakt/darüber, kein stilles Teilresultat, wirksame
Caller-/Rollen-/Denyprüfung, direkte und Managed-/Remoteeinstiege, kontrollierte
Konkurrenz-/Austauschfälle, Help-/ResultTable-/NULL-Verträge sowie betroffene
Erst-/Upgrade-/Repeat-/Uninstallpfade. Reale Laufzeitdaten und Journale bleiben
privat. Ein Sourcefix, Plan oder Testartefakt ist kein Runtime-PASS.

## Work-Type-Autorität

Die Policy gehört zum kanonischen Work-Type-Katalog. Ein Eintrag bindet
WorkTypeId und RowVersion, Principal-ID/SID/Erstellungszeit und Aktion.
Die tatsächlichen Datenbanktoken des laufenden Callers bestimmen Rollenrechte;
Actor, Tenant und frei übergebene Identitätsstrings verleihen keine Autorität.
Jede Work-Type-Änderung invalidiert bestehende Einträge bis zur erneuten
ausdrücklichen Konfiguration. Prinzipal-Neuanlage erbt keine alten Einträge.
Eine passende gültige Sperre hat Vorrang; ohne gültiges Allow wird abgewiesen,
auch für dbo. Nur CONTROL auf der Policytabelle erlaubt deren Verwaltungs-USP.
Deployment erzeugt keine Freigaben und erteilt keine Mitgliedschaften/Grants.

Die neue Verwaltungs-USP hat keine fachliche Ergebnismenge. Die interne
inline TVF bildet die Entscheidung genau einmal ab. Enqueue prüft vor Insert
und Idempotency-Auskunft, Claim filtert vor Reservierung/Payloadausgabe.
Second Session prüft lokal vor RPC und der Dispatcher weiterhin seine eigene
Remoteautorität. Bestehende Installationen brauchen explizite Policykonfiguration.

## Nachweisstand

Alle 25 freigegebenen Korrekturen sind seit dem 2026-10-16 über
[PR #322](https://github.com/gecompat/SQL_Server_Toolbelt/pull/322) in `main`
integriert ([Merge `985b9d8`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/985b9d8a9df1dad9b1c13e868b7eac0a7758bd6f)).
Die Statusabfrage mit `gh pr view 322` am 2026-10-16 bestätigt am finalen
[PR-Head `8772e9d`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/8772e9d6a1d538e6fcb22da3f0bd03c83a28e88a)
93 erfolgreiche CI-Prüfungen, keine Fehler und keine ausstehenden Prüfungen.
Nur die ausdrücklich manuelle JSON-Pointer-Lastprüfung ist `SKIPPED`, kein PASS.
Der Merge-Dateistand ist zum geprüften Head identisch; eigene Mergecommit-CI
und vollständige Plattform-/Minimalrechte-/Heap-/Releasequalifikation werden
daraus nicht abgeleitet. Die gezielten lokalen Teilnachweise folgen unten.

**SC-045 bleibt P1 und offen bis zur erfolgreichen authentifizierten
TLS-Lab-Abnahme.** Der zuletzt für `AuthenticatedTls` geprüfte externe
Labvertrag wurde vor der Verbindung abgewiesen. Die zuvor ausgeführten Produktprüfungen nutzten den
damaligen Labtransport und qualifizieren keine authentifizierte TLS-Verbindung.
Erforderlich bleibt ein erfolgreicher Livebeleg für Zertifikatskette und
Servernamen mit SQLClient und `sqlcmd` auf ausdrücklich ausgewählten,
schema-validierten Labzielen. SC-018 verlangt weiterhin die betreiberseitige
Beschränkung der Legacydirektgrants auf vertrauenswürdige Principals.
Kein neuer Cloudabschluss oder pauschales Modulstatusupgrade durch den Merge.

## Teilnachweise Welle 1 — 2026-10-15

Die gezielten nativen Sourceverträge für Work-Type-Policy, befüllten Policyrepeat,
Removal, Schemaowner/-kontrollrechte, Producer-/Workerautorität, Barrier-TX und
Second-Session-Payload/Autorität bestanden auf einem explizit ausgewählten,
schema-validierten bereiten Linux-SQL-Server-2019-Ziel. Eigene GUID-Datenbank
anschließend entfernt und Nichtexistenz geprüft. Keine bestehenden Rechte,
Serverkonfiguration oder Labressourcen geändert. Der fokussierte Lauf ohne
konfigurierten Testprovider qualifiziert keinen RPC.

Zusätzlich bestanden die bestehenden vollständigen Adapter run-w4b-work-type-linux.sh,
run-w5a-second-session-linux.sh und run-work-queue-linux.sh über
Tests/CI/run-lab-local.ps1 -Versions 2019 -Platforms linux -LinuxPatches latest
auf eingefrorenen aktuellen Quellen. W5a enthält dabei den neuen Securityvertrag
mit echter RPC-Ausführung der exakt 1-MiB-Payload. Frühere Fehler bei Testschema,
SQLCMD-Arbeitsverzeichnis, Quoted-Identifier-Setup und gleichzeitiger Skriptpflege
sind Diagnosehistorie und werden nicht als PASS gezählt.

Der sourcegebundene Windows-Frameworklauf Invoke-NoOverwrite.ps1 bestand mit
aktuellen Runner-/Provider-/Harnesspins. Das ist ausschließlich der begrenzte
Offlinehelpernachweis; ServiceAccount-Rolle/Rootfreigabe in SQL und die neue
native Handleassembly bleiben für Welle 2 zu qualifizieren. Die drei Worker-
Contracts Worker.Contract.ps1, ManagedWorker.Contract.ps1 und
ExecutionActors.Contract.ps1 bestanden; keine neue SQL-Worker-Runtimeaussage.

Testtrigger: Die neue ausschließlich synthetische dbo-Policyfixture ist explizit
bei W4b, W5a, W5b und Queue registriert. Produktionsdeployment enthält weder
Fixture noch automatische Freigaben. Die Helper erhalten SQLCMD-Fehlercodes
auch bei negativer Lifecycleprobe. Keine zusätzliche periodische Prüfung.
Ein Gesamtaudit prüft Registry/API-Katalog; erneute breite Läufe benötigen
geänderte Inputs, einen Befund oder ein unerfülltes Gate.

Nach der Resolveranbindung bestand der externe Queueworker nativ auf Linux
SQL2019 mit -SkipLongHeartbeat: Transaktion, Unicode, Retry, Cancellation,
Identität, Slots und Drain. Handler über 60 Sekunden, ambiger Committransport,
getrennte Workerprincipals, Recoveryraces und zentrale Worker-Nutzung bleiben
NOT_EXECUTED. Der fokussierte Sourcevertrag bestand nach der letzten
Resolveränderung erneut. Ein paralleler Versuch kollidierte an einem bereits
benannten Tempconstraint; ausschließlich der anschließende serielle Lauf ist
PASS. Bestehende mutierende Läufe wurden nicht abgebrochen.

## Aktueller Nachweis Wellen 2–4 — 2026-10-15

| Prüfung | Ausführung und Ergebnis | Begrenzung |
|---|---|---|
| Foundation-Datei-I/O | `test_foundation_handles.py`: Windows 10 ausgeführt / 2 POSIX-Fälle übersprungen, erfolgreich; echte Command-stdin/stdout, Junction, Hardlink, Rootwechsel und Cleanup. HTTP-Response 10 Methoden/111 Fälle, Discovery 12/266, Redirects 8/204 und 105 Provenance-Dateien erfolgreich. | WSL-Linux: 11 von 12 Fällen ausgeführt, nur Windows-Junctionfall übersprungen; ebenfalls erfolgreich. Ubuntu-CI bestätigt separat. Kein externer HTTP-Transport. |
| Windowsprovider | Reproduzierbarer Releasebuild; `Invoke-NoOverwrite.ps1` mit aktuellen Provider-/Harnesspins erfolgreich. `run-filesystem-security-lab.ps1` auf explizit ausgewähltem schema-validem Windows-SQL-2025-Ziel: Rollen-/Root-/Rollenownerablehnung und alle neun öffentlichen APIs erfolgreich. | Kein Gesamt-PASS für Caller-Token-/NTFS-/Live-Race-Matrix. Eigene DB, Dateien und exakter eigener Trust nachweislich entfernt; keine Instanzoption geändert. |
| Textsnapshot | Sieben aus dem aktuellen Decoder extrahierte SQL-Fälle unter Linux SQL2019: UTF-8/UTF-16-LE/1252 mit Nicht-ASCII, leer sowie ungültige UTF-8-/UTF-16-Bytes erfolgreich. Öffentlicher FileContent-Contract um Dateifälle ergänzt. | Reiner Decoder-Nachweis; der komplette OPENROWSET-Dateilauf ist lokal mangels serverseitiger Fixtures NOT_EXECUTED. Container-CI prüft ihn separat. |
| ZIP | `run-security-zip-lab.ps1` am frischen gebundenen Release unter Linux SQL2019: bestehende Extraktions-/Writerverträge erfolgreich. `Writer.Framework.ps1` am selben Release einschließlich neuem `EntrySecurity.Framework.cs`: sieben Default-/Hardlimit-/Längenlügenfälle sowie bisherige unabhängige Writer-Suite erfolgreich. | Frameworkgrenzen sind kein SQL-Marshaling-/Gesamtheap-PASS. Weitere Plattformen bleiben eigene Gates. |
| Regex | `run-regex-captures-lab.ps1 -Version 2019 -Platform linux -Patch latest -ApiQualificationOnly -OptInExactTrust` am finalen Release: acht Frameworksuiten, bestehende SQL-APIs und SQLClient-Metadaten/Atomik erfolgreich; 100000/100001 Matches und 65536/65537 Replacementteile in Framework abgedeckt. | Local API; zentrale Nutzung, Upgrade/Lifecycle und tatsächliche Minimalrechte hier NOT_EXECUTED. |
| Ressourcen-/Statusverträge | `run-security-hardening-lab.ps1`: auf Linux SQL2019 neue Security-Contracts für Base64, URI, Series, Split, Unquote, Pointer, Path, Cancellation, Console und EventLog erfolgreich; echte Zweiverbindungskonkurrenz um letzten Cancellationplatz, vollständige Consoleframes, Repeat und Reverse-Uninstall erfolgreich. | Ein ausgewähltes Ziel; keine vollständige Plattform-/CL-/Minimalrechtematrix. |
| Neue Statusnamen | Fokussierter nativer Lauf unter Linux SQL2019: fremde Base64-/Series-/Split-Namen unverändert abgewiesen; Restore, Repeat, Uninstall und eigene DB-Bereinigung erfolgreich. | Gezielte Lifecycle-Guards, keine allgemeine fremde Deploymentqualifikation. |
| Lab-TLS | `validate_lab_selector.py`: 17 Selektions-, 9 TLS-Builderfälle, 6 SQLClient-Policyfälle und 4 Shelltests erfolgreich. Aktueller schema-validierter Labvertrag wird vor Verbindungsaufbau gesperrt. | Authentifizierte Liveverbindung NOT_EXECUTED; gültige CA-Kette und passender Hostname sind externe Voraussetzung. Kein Fallback, keine Truststore-/Zertifikatsänderung. |

Testdatum jeweils 2026-10-15. Eingefrorene Artefakte, private Logs und
Wiederherstellungsjournale bleiben außerhalb versionierter/public Evidence.
Historische Prüfläufe sind keine CI am finalen Commit. Die vier zuvor vollständig
validierten Module Path Exists, URI, Split Characters und Execution Cancel stehen
wegen der neuen öffentlichen Verträge jetzt bewusst auf `partially validated`.

## Migration und verbleibende Betriebsgrenzen

Work-Type-Einträge müssen nach Deploy ausdrücklich für ENQUEUE/CLAIM/
EXECUTE_NEW_SESSION konfiguriert werden; Deny gewinnt und WorkTypeänderung
invalidiert vorherige Freigaben. Kein automatischer Grant. ResultTable vertraut
nur dbo und den ausgewiesenen Rollen samt vertrauenswürdigen Rollenownern;
untrusted Schema-/DDL-/Securityadmin-/Impersonationskontrolle wird vor Mutation
abgewiesen. Es werden keine fremden Owner/Rechte korrigiert.

ServiceAccount benötigt die leere dbo-eigene Rolle und das explizite Rootflag.
Windows braucht das neue, exakt vertrauensgebundene UNSAFE-Artefakt. Die Python-
Commandadapter übernehmen Dateipfade ausschließlich als stdin/stdout-Handles;
`{input_path}`/`{output_path}` in argv sind nicht mehr zulässig. HTTP- und Command-
Adapter halten auf Windows alle Vorfahren ohne Renamefreigabe; POSIX verwendet
gehaltene dirfd-/NOFOLLOW-Bindungen und private Stagedirectories. Ein privates
Stagedirectory wird vor Nutzung auf Owner und fehlende Gruppen-/Otherrechte
geprüft. Ein gleichberechtigter Prozess desselben OS-Principals ist keine
zugesagte Isolation. Kein unsicherer Plattformfallback.

Neue Status-TVFs liefern Limits explizit. Bestehende Base64-/URI-Werte liefern
bei Limit NULL, Split keine Zeilen, JSON Path NULL. Dadurch darf ein Caller
NULL/Leermengen nicht als negatives Fachresultat behandeln. Die alten
mathematischen Series-APIs bleiben unverändert und dürfen untrusted nicht
direkt freigegeben werden; SC-018 bleibt bei solchen Grants betrieblich offen.
Kein Deployment nimmt bestehende Rechte automatisch zurück. Cancellation ist
dauerhaft: Legacyzeilen zählen global; neue Anforderungen tragen den tatsächlichen
Principal samt SID/Erstellzeit. Volle Quote erlaubt Wiederholung bestehender IDs,
kein Purge. RecordedAtUtc-Retention ist ausschließlich ein expliziter neuer
Aufruf; bestehende OccurredAtUtc-Semantik und automatische Jobs bleiben unverändert.

Die Guards begrenzen logische Arbeit und Ausgabe; sie garantieren weder
Gesamtheap noch konstante Laufzeit oder harte Echtzeit. ZIP verwendet ein exakt
begrenztes Ausgabearray; SQL-/CLR-Marshaling kann zusätzliche Kopien anlegen.
Ein Fenster für Dateiaustausch nach mehrfacher Pfadauflösung wird durch die
jeweils gehaltenen Handles geschlossen; laufende Datenänderung durch vorhandene
Schreibhandles ist keine zugesagte Dateiversionskontrolle.

## Testtrigger und Verarbeitungsaufwand

Die neuen SQL-Security-Contracts laufen einmal je ausgewähltem CI-Ziel nach
Erstdeployment, nicht in jeder bestehenden CL-/Repeat-Schleife. Console-Großausgabe
wird im Adapter verworfen und separat über Framegrößen geprüft. ZIP-Grenzfälle
verwenden denselben bereits gebundenen Framework-Releaseoutput ohne weiteren
Build. TLS-/Handleprüfungen sind kurze Offlinefälle; POSIX wurde lokal unter WSL-Linux geprüft und wird in Ubuntu-CI bestätigt. Registry-/Status-/API-Katalogänderungen erfordern einmal den Gesamtaudit.
Keine zusätzliche periodische Automation, Reviewkette oder neue Entwicklungswelle.
Notwendige stärkere Grenz-/Konkurrenzprüfungen sind auf die freigegebenen 25 Punkte
begrenzt. Verlässliche Kosten-/Tokenmessungen liegen nicht vor.

Alle SQLClient-Metadatenprüfungen mit frei konfiguriertem TBX_SQL_HOST verwenden
`Set-SqlClientTlsPolicy.ps1`. Bei Lab verlangt er die validierten True/False-
Transportflags und erzwingt Zertifikatsprüfung; außerhalb von Lab ist eine
Zertifikatsausnahme ausschließlich für Loopback-CI erlaubt. Bereits übergebene
Connections bleiben im Eigentum des kanonischen Lab-Builders. Zwei speziell
an eigene CI-Container gebundene Pointer-/SafeCast-Clients verwenden ihren
festen Loopback-Port und gehören nicht zum persistenten Labpfad.

Abschließende lokale Strukturprüfung: vollständiger
`validate_documentation.py --all --write` erfolgreich (44 Manifeste),
`Deployment/Tests/Test-SqlExport.ps1` erfolgreich (29 Fälle/153 Assertions),
Syntax aller 16 geänderten Shellskripte und 17 PowerShellskripte erfolgreich.
Diese Offlineprüfungen ersetzen keine noch offene aktuelle Head-CI.

Die erste Head-CI identifizierte veraltete gekoppelte Testanbindungen:
Second-Session-Abhängigkeitsorakel auf WorkType 1.2 aktualisiert,
Cancellation-Grenzfixture ohne fremde Testdependency und explizite dbo-Delegation
für den Managed-Control-Test ergänzt. Split normalisiert seine begrenzte
Separatormenge über den deklarierten Generate-Series-Kern; Lifecycle prüft die
Dependency am kanonischen Statuskern. Native SQLClient-Labaufrufe propagieren
explizit den TLS-Kontext; die Table-Clone-Snapshotausführung bindet den neuen
Helper transitiv. Diese Änderungen benötigen die folgende aktuelle Head-CI;
Fehlversuche sind kein PASS. Laufende mutierende CI wurde nicht abgebrochen.

Der bisherige positive Split-LOB-Vertrag wurde auf exakt 10000 Tokens gebunden;
10001 wird im Securityvertrag separat mit LIMIT und ohne Legacyteilmenge geprüft.
Die SQL-Helptexte nennen die neuen Payload-/Console-/Quotengrenzen sowie
Work-Type-/ServiceAccount-Rechte. Console-Adapterexporte wurden aus derselben
Quelle regeneriert. Zusätzliche statische Prüfungen aller sechs davon betroffenen
Module bestanden; aktuelle Runtimeabnahme folgt mit dem finalen Head.

Der genuine Worker-Upgradepfad bindet nun WorkType1.1 und Queue2.0 aus demselben
öffentlichen historischen Commit blobidentisch vor der ersten DB-Mutation.
Anschließend aktualisiert er regulär auf WorkType1.2, delegiert ausschließlich
den vorhandenen synthetischen Upgrade-Work-Type und aktualisiert Queue2.1.
Keine historischen Sourceänderungen oder fingierten Versionsmarker.
Die lokale Offlineaufnahme beider Module bestand (24 eigene gebundene Dateien);
beide geänderten PowerShellhelper sind syntaktisch geprüft. Der historische
SQL-Upgradepfad benötigt die folgende Head-CI; die vorherige fehlgeschlagene
Installation gegen den zu neuen Katalog ist kein PASS.

Der aktuelle genuine SQL-Upgradepfad bestand bereits einschließlich erhaltenem
aktiven Claim und Queue-Repeat. Die danach erreichte Control-Repeatfixture
zählte noch zehn Tabellen; sie schließt nun ausdrücklich die elfte Tabelle
WorkTypePermission und deren vorhandene Zeilen in den binären Erhaltungsnachweis
ein. Keine Prüfung entfernt; der nachfolgende Head muss den gesamten Pfad bestehen.

Auch die bestehenden vier SQL-Exportqualifikationen sind gekoppelt erweitert:
aktuell 15 Tabellen/166 Felder, vollständige Principal-/Policyzeugen und feste
Quellenbindung der aktuellen acht Legacyoberflächen. Historische Queues werden
zuerst mit echter WorkType1.1-Abhängigkeit installiert; erst danach werden
regulär die aktuellen gemeinsamen Module und die Queue exportiert migriert.
Offline bestanden die gebundene Dependency-Erzeugung local/central ohne
SQLverbindung und der unveränderte SQL-Exportselbsttest (29/153).
Die bestehenden CI-Schritte und ihre Bereinigungsgrenzen bleiben erhalten;
kein zusätzlicher Testtarget, keine neue Version- oder Parameterfiktion.

Die native befüllte Exportprüfung bestand inzwischen local/central. Der
nachfolgende Legacyexport stoppte vor SQL an einem Windows-/LF-Sourcepin.
Alle fünf Pins sind jetzt exakt an die konsumierten Gitbytes gebunden.
Der bestehende Exportselbsttest prüft diese Intakegrenze und die acht
Deklarationspins zusätzlich offline (5 Dateien/8 Deklarationen); dieser Test
und die 29/153 bisherigen Fälle bestanden. Keine Ausnahme für abweichende
Sourcebytes und keine zusätzlichen SQL-Ziele oder Prüfstufen.

Der native Provider behält zusätzlich die bisherige exklusive Stagedatei-
Freigabe bei: kein zweiter Reader vor Publikation, auch nicht bei breiterer
Parent-DACL. Der aktuelle gebundene Windows-Frameworklauf prüft diese Eigenschaft
in allen neun Writefällen zusätzlich und bestand; die zuvor qualifizierten
SQL-API-Läufe werden dadurch nicht zu einer neuen vollständigen Windowsmatrix.

Die beiden aktuellen Export-Repeats führen für die zusätzliche leere Policytabelle
nun jeweils einen expliziten Nullzeilen-Zählzeugen. Der Offline-Intake vergleicht
alle 15 Tabellenzeugen mit den 166 Feldbindungen, damit keine deklarierte Tabelle
stillschweigend aus der Aufnahme fällt. Bestehende Migrations- und Vergleichs-
prüfungen werden vollständig beibehalten.

Exportierte Queue2.0-Migration und Parameter-Metadatenrepeat bestanden local/
central. Die Queue1.1-Fixture bindet BEFORE nun ausdrücklich auch die bereits
regulär aktualisierte gemeinsame Policyabhängigkeit: sieben Tabellen/93 Felder,
AFTER unverändert 15/166. Die sechs ursprünglichen Legacytabellen bleiben separat
vollständig verglichen; zusätzlich muss die Policytabelle in beiden Phasen leer
bleiben. Keine automatische Delegation wird als Migrationsdefault zugelassen.

Das Queue1.1-Schemaorakel bestand anschließend. Seine Zeilenaufnahme bezeugt nun
auch die bereits vor der Queuemigration bestehende leere Policytabelle in beiden
Phasen ausdrücklich. Der separate unveränderte Vergleich der sechs ursprünglichen
Tabellen wird dadurch um einen Nullzeilen-Zeugen ergänzt, nicht reduziert.

Queue1.1-Erstinstallation und aktuelle Migration bestanden nun bis einschließlich
Legacyvergleich. Die nachgelagerte geschlossene Objektinventarliste umfasst
explizit die vier neuen Securityobjekte: 83 statt 79. Ihre positiven Bindungen
und der Ausschluss unbekannter Zusatzobjekte bleiben erhalten. Der Offline-
Intake prüft auch diese endliche Liste vor dem Runtimeeinsatz.

## V0c-Nachqualifikation — 2026-10-19

Die aktuelle Fachmatrix der ersten 16 Module bestand auf SQL Server
2019/2022/2025 unter Windows und Linux einschließlich der betreffenden
Security-Contracts. Sieben Statusfunktionen bestanden zusätzliche lokale
Minimalrechte- und echte zentrale Aufrufe auf allen sechs Zielen. Die
begrenzte Series-Oberfläche benötigt dabei keinen direkten SELECT-Zugriff
auf die unbegrenzten Alt-APIs. SC-018 bleibt deren ausdrückliche Betreibergrenze;
unbekannte reale Grants werden nicht als geschlossen erklärt. Nur die
betroffenen V0c-Module werden nachqualifiziert; andere Wellen und deren offene
Minimalrechte-/Plattformgates bleiben unverändert. Details und Status:
[V0c-Gatebericht](../../Tests/V0C_RELEASE_GATE_STATUS.md).
