# JSON Pointer: kleine Securityfixture auf allen Moduskontexten

Am 2026-11-08 bestanden für JSON Pointer 1.0.0 **18 neue Kontextausführungen,
zwölf vollständige Läufe und zwölf frische unabhängige Windows-Clientaudits**.
Alle 18 eigenen Testdatenbanken sind entfernt. Zusammen mit sechs gültig
wiederverwendeten lokalen Linux-Kontexten ist die unveränderte kleine
`Security.Contract.sql` auf **24 erklärten lokalen/direkt zentralen Kontexten**
belegt. Ergebnis: **PASS_FOR_DECLARED_JSON_POINTER_SECURITY_SCOPE**.
Gesamtstatus bleibt `partially validated`, `unreleased`.

## Zwei unveränderte feste Sollfälle

Die [Originalfixture](../../Modules/toolbelt.json.pointer/Tests/Runtime/Security.Contract.sql)
enthält ein synthetisches Dokument mit einer Million Nutzzeichen und Tiefe40.
Der passende Pointer muss `Status='INVALID'`, `ErrorCode='WORK_LIMIT'` und
NULL-Wert liefern. Der zweite feste Aufruf für JSON-null muss `JSON_NULL`
liefern. Beide originalen THROW-Orakel werden unverändert serverseitig ausgeführt.
Dies sind keine 16-MiB-Verarbeitung, Heapmessung, Performance- oder
Parallelitätsqualifikation. Frühere getrennte Lastnachweise bleiben unverändert.

## Neue Kontexte und gültige Wiederverwendung

| SQL-Ziel | CLs | Neue Modi | Neue Kontexte | Wiederverwendete lokale Kontexte |
|---|---|---|---:|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 | 0 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 | 0 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 | 0 |
| Linux 2019/latest | 150 | direkt zentral | 1 | 1 |
| Linux 2022/latest | 150, 160 | direkt zentral | 2 | 2 |
| Linux 2025/latest | 150, 160, 170 | direkt zentral | 3 | 3 |

Die sechs lokalen Linux-Fälle stammen aus den drei erfolgreichen Runtimejobs
von [Main-CI 40171363163](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/40171363163)
am Quellenstand
[7f6dcb0d](https://github.com/gecompat/SQL_Server_Toolbelt/commit/7f6dcb0dd1e9efffabd41cfd1dc854a5485f307b).
Der gebundene Linuxadapter setzt und prüft die jeweiligen CLs und führt die
Securityfixture innerhalb jeder lokalen CL-Iteration aus. Alle elf ausgewählten
Produkt-, Fixture- und Methodendateien wurden erneut als unverändert bestätigt.
Der optionale manuelle Maximallastjob dieses CI-Laufs war `SKIPPED`, kein PASS.

Neue und wiederverwendete Kontextmengen überschneiden sich nicht. Die neue
Admission lässt Linux ausschließlich direkt zentral zu; eine lokale Linux-
Wiederholung wird abgewiesen. Modusanzahlen stammen aus Runset und gebundenen
Journalen. Alte CI-Fälle erhalten keine nachträglich erfundenen frischen
Lab-Audits, und es wird kein neuer 24-Kontexte-Gesamtlauf behauptet.

Der [neue Adapter](../../Tests/Release/Invoke-JsonPointerSecurityLab.ps1) lief aus
[b17d4926](https://github.com/gecompat/SQL_Server_Toolbelt/commit/b17d4926dc461f66884a050fb45ec058e72da929).
Der kanonische Erstexport installiert ausschließlich das unveränderte Pointer-
Modul ohne weitere Module. Tatsächliche Version, Plattform, CL und Modus werden
geprüft. Nach der vollständigen Fixture sind Transaktion und XACT_STATE neutral;
alle eigenen Moduldefinitionen sind gegenüber dem installierten Zustand gleich.
Keine Wiederholung der grünen vollständigen API-/Client-/Lifecycleadapter.

Die [vorhandenen direkten SELECT-Callerprofile](POINTER-CALLER-QUALIFICATION.md)
bleiben als eigener Nachweis erhalten: 24 positive Profile und 72 SQL229-
Abweisungen. Ihre Originalquellen wurden über den kanonischen historischen
Quellenleser geprüft; die öffentliche Pointer-TVF ist auch aktuell bytegleich.
Historische Ausführung und spätere Installer-/Help-Methoden bleiben getrennt.
Die frühere pauschale Minimalrechte-Offenangabe gilt damit nicht für diesen
bereits belegten Datenpfad. Lifecycle-DDL-Rechte und echte Lowpriv-CrossDB-
Identitäten sind weiterhin eigene Gates; die Securityfixture erteilt keine Rechte.

## Endlicher Rahmen, Cleanup und Grenzen

Ausdrücklicher Benutzerauftrag: erst PR #560 mit Head-/Main-CI abschließen,
danach die fehlenden Pointer-Security-Kontexte autonom. Der vorherige
[PR #560](https://github.com/gecompat/SQL_Server_Toolbelt/pull/560) und seine
tatsächliche Main-PUSH-CI 42517286103 waren vor Zulassung erfolgreich.
Ein Verantwortlicher, keine Agents; vor Start festgelegt: **24 Lauf-/Auditaufrufe,
18 eigene DB-Reservierungen, 45 Minuten, keine native Wiederholung**.
Alle zwölf Producer bestanden beim ersten Versuch; alle zwölf reservierten
separaten Auditprozesse bestanden innerhalb der ursprünglichen Frist.
Der Rahmen ist mit 24/24 Aufrufen und 18/18 Reservierungen geschlossen.

Nur die originale Securityfixture erhält wie im vorhandenen CI maximal 180 Sekunden
SQL-Commandtimeout, sonst 45 Sekunden. Jeder Producer behält 300 Sekunden
für die Arbeit und 60 Sekunden für Cleanup; sein Kindprozess ist auf 400 Sekunden
begrenzt. Diese Grenzen
verlängern weder die gemeinsame Frist noch begründen sie eine Hardwallgarantie.

Schema-validierter Functional-Labvertrag mit exakter Zielauswahl,
Verschlüsselung und explizitem unverändertem Trustwert. Vorhandene administrative
Anmeldung und Windows-Client für Windows- und Linux-SQL-Ziele. Jeder frische
Audit bindet das genaue finale Journal, Zielversion, eigene DB-Abwesenheit,
unveränderte gesamte Konfiguration/Assemblytrust und alle Eingabepins.
Cleanup prüft eigene DB-Identität, Erstellungszeit und Ownermarker.
Der separate private Nachprüfer bestätigte die 18 neuen sowie sechs alten
Kontexte, fehlende Überschneidung, Originaljournale, Audits und Quellenbindungen.
Private Originale und Quellkapseln bleiben außerhalb Git erhalten.

Zehn verbindungslose
[Gegenproben](../../Tests/Release/test_json_pointer_security_lab_contract.py)
prüfen echte Admission ohne SQL/Labimport, unveränderliche Ziele/Modi/Quellen,
verbotene lokale Linux-Wiederholung und die nicht verlängerbaren Timeoutfenster.
Sie sind zentral registriert; Modul-Static und Quellen-Preflight bestehen.
Keine Produkt-SQL-/Manifest-/Rechte-/Principal-/CLR-/Trust-/Server-/Labänderung.
Kein neuer Maximalworkload-, Heap-/Parallelitäts-, Lifecycle-Minimalrechte-,
Lowpriv-CrossDB-, Linux-Clienthost-, TLS- oder Host-Recoverynachweis.
Keine vollständige Modulabnahme, Veröffentlichung oder Tags.
