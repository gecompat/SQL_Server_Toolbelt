# Freigegebene Security-Härtung vom 2026-10-15

Status: ausdrücklich zur Implementierung freigegeben; Umsetzung und Nachweise
werden getrennt geführt. Autor: Codex. Ausgangsstand: `58436b0`.

Nach Besprechung der Zwecke, Verträge, Alternativen, Risiken und Migration hat
der Benutzer alle folgenden 25 Punkte ausdrücklich freigegeben, einschließlich
UNSAFE für SC-023, Cancellationquoten sowie NULL-/Leermengenverhalten.
Der Auftrag umfasst autonome Umsetzung, Tests und gekoppelte Dokumentation
in der nachfolgenden Reihenfolge. Cloudstatus ist kein Implementierungsstatus.

| Welle | Punkte | Verbindlicher freigegebener Scope |
|---|---|---|
| 1 | SC-046/026/027/041 | Gemeinsame Work-Type-Policy: ENQUEUE, CLAIM, EXECUTE_NEW_SESSION; explizites Allow, Deny vor Allow, keine automatische Rechteübernahme. Claim zusätzlich Handler-EXECUTE; lokales Second-Session-Startrecht zusätzlich Remote-EXECUTE. Payload höchstens 1 MiB vor JSON/RPC. |
| 1 | SC-009/017/016 | ServiceAccount nur mit eigener Rolle und Rootfreigabe; Schemaowner dbo und vertrauenswürdige Kontrollprincipals; DRAIN_BARRIER ohne Callertransaktion. |
| 2 | SC-010/023/040 | Plattformgebundene Handleoperationen ohne unsicheren Pfadfallback; gesonderter nativer UNSAFE-Windowsprovider mit Root-/Zielbindung für alle neun APIs; Text/BOM/Größe aus einem Byte-Snapshot. |
| 2 | SC-045 | Lab-TLS mit CA-/Hostnameprüfung, kein TrustServerCertificate/-C. Zertifikatsbereitstellung, Hostnamevertrag und Truststorepflege sind externe Labvoraussetzungen, keine Infrastrukturänderung durch Toolbelt. |
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

Implementierung begonnen. Neue Runtime- und CI-Nachweise: noch nicht ausgeführt.
Die früheren Security-Abschlüsse bleiben historische Nachweise ihres jeweiligen
Source- und Teststands. Neue Cloudabschlüsse erfolgen nur nach bestätigtem Fix.

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
