# Split Advanced: gezielte aktuelle Lifecycleprofile

Am 2026-11-08 bestand Split Advanced 1.1.0 mit ResultTable 1.0.0 den hier
erklärten Scope: **zwölf vollständige Läufe, 24 lokale/direkt zentrale Kontexte,
240 Lifecycleprofile und zwölf frische unabhängige Windows-Clientaudits**.
Alle 24 eigenen Testdatenbanken sind entfernt. Ergebnis:
**PASS_FOR_DECLARED_SPLIT_ADVANCED_LIFECYCLE_SCOPE**.
Das Gesamtmodul bleibt `partially validated`, `unreleased`.

## Ziele, Collations und aktuelle Originalbatches

| SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Lokal wurde `Latin1_General_100_CS_AS`, direkt zentral
`Latin1_General_100_BIN2` gesetzt und anschließend zusammen mit dem tatsächlichen
CL aus `sys.databases` gelesen und exakt geprüft. Dies ist keine beliebige
Collationmatrix und keine abweichend kollatierte CrossDB-Consumerprüfung.

Der [Adapter](../../Tests/Release/Invoke-SplitAdvancedLifecycleLab.ps1) und die
[Fixture](../../Tests/Release/Runtime/SplitAdvanced.LifecycleProfiles.Contract.ps1)
liefen aus [9e7c6654](https://github.com/gecompat/SQL_Server_Toolbelt/commit/9e7c665429f4e4439c3b59e39174b289a3a26023).
Initial installiert der kanonische Export nur ResultTable und Split Advanced.
Weitere Schritte verwenden die vollständigen aktuellen öffentlichen
Deploy-/Uninstall-Batches mit festen SQLCMD-Werten. Eine Offlineprobe vergleicht
die vollständigen drei Produkt-DDL-Batches von Erstinstallation und Reparatur;
eine weitere private Probe bestätigte alle sechs lokalen/zentralen Batchpaare.
Nur SQL-Ausführung wird dabei gemockt, nicht Include-Auflösung oder Export.
Produkt-SQL, Manifest, Hilfe und Version bleiben unverändert.

## Zehn Profile je Kontext

| Profil | Festes Orakel | Anzahl |
|---|---|---:|
| Unbekannter Versionsmarker, Deploy und Uninstall | Exakt 51673/State 1 und unveränderter ausgewählter DB-/Katalog-/Transaktionszustand | 48 |
| Lokale ungültige Bestätigung beziehungsweise zentral fehlende Bestätigung | Exakt 51675/State 1, kein erfolgreicher Uninstall | 24 |
| Gleiche Version mit absichtlich veränderter TVF | Drift zuerst bestätigt; Deploy stellt sämtliche kanonischen aktuellen Moduldefinitionen wieder her | 24 |
| Registrierter Zielname absichtlich als IF statt TF | Testtyp zuerst bestätigt; Deploy repariert Typ und sämtliche kanonischen Definitionen | 24 |
| Eigene aufgelöste same-database View-Dependency | Uninstall scheitert exakt mit 51676/State 1 bei unverändertem ausgewähltem Zustand | 24 |
| Uninstall mit zusätzlicher synthetischer Tabelle | Modulobjekte und Marker entfernt; feste Fremdzeile, Schema- und Objektidentität erhalten | 24 |
| Neuinstallation im erhaltenen Schema | Kanonische vollständige Moduldefinitionen und Fremdzeile erhalten | 24 |
| Uninstall nach eigener Entfernung der Zusatztabelle | Modulobjekte, Marker und nun leeres verwaltetes Schema entfernt | 24 |
| Uninstall bei fehlendem Modul | Unveränderter ausgewählter Zustand, Modul-Schema weiterhin abwesend | 24 |

Zusammen sind **96 exakte negative und 144 positive Profile** bestanden.
Versions- und Driftzustände sind ausschließlich eigene synthetische Fixtures,
kein echter historischer Versionsübergang. Der IF-/TF-Wechsel betrifft einen
unter der bekannten Modulversion registrierten Namen; er behauptet keine
allgemeine Übernahme fremder Objekte.

Negative Orakel akzeptieren weder Erfolg noch unabhängige Adapterfehler,
andere SQL-Fehlernummern oder andere States. Verglichen werden eigene
Objektidentitäten/Definitionen, Extended Properties, Modul-Schemata und
Transaktionszustand. Nach jedem Kontext sind `@@TRANCOUNT=0` und
`XACT_STATE()=0`; ResultTable-Objektdefinitionen bleiben unverändert.
Kein Erhalt der Split-Objektidentitäten über die absichtlichen Drop-/Repair-/
Uninstall-Schritte und kein allgemeiner Vergleich sämtlicher Session-/TempDB-Zustände.

## Wiederverwendung und endlicher Rahmen

Die [aktuelle Funktions-/Clientmatrix](SPLIT-ADVANCED-CURRENT-QUALIFICATION.md)
und vorhandenen direkten Callerprofile bleiben verwendbar und wurden nicht
erneut ausgeführt. Die drei erfolgreichen Linux-Jobs aus
[Main-CI 41110006402](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/41110006402)
behalten ihren engeren ursprünglichen Lifecycle-/Funktionsscope. Alle 24
ausgewählten Produkt-, Fixture- und Methodendateien wurden erneut als
unverändert gegenüber deren Quellenstand bestätigt.

Der Quellenabgleich ersetzt keinen Orakelvergleich. Frühere Linux-Läufe
belegen nicht durchgehend die neuen exakten Fehler-/State- und vollständigen
kanonischen Definitionsvergleiche. Deshalb wurde der vorbereitete Neun-Paare-
Plan **vor jeder nativen Zulassung** auf zwölf Paare präzisiert. Alter Plan
und Runset bleiben privat erhalten; darunter wurden null native Aufrufe
verbraucht. Die neuen 240 Profile sind sämtlich neu ausgeführt, keine
nachträglich aufgewerteten historischen Fälle oder erneuten Vollfixtures.

Der fortbestehende Benutzerauftrag zur autonomen Restqualifikation gilt für
diesen konkreten Scope. Vor Zulassung: ein Verantwortlicher ohne Agents,
zwölf Producer-/Auditpaare, **24 Aufrufe, 24 DB-Reservierungen und 45 Minuten**,
keine Wiederholung. Start erst nach tatsächlicher grüner Main-CI des vorherigen
[PR #559](https://github.com/gecompat/SQL_Server_Toolbelt/pull/559).
Alle zwölf Fälle bestanden beim ersten Versuch innerhalb der ursprünglichen
Frist; der Rahmen ist mit 24/24 Aufrufen und Reservierungen geschlossen.

Schema-validierter Functional-Labvertrag, exakte Ziele/Versionen/CLs,
Verschlüsselung und unveränderter expliziter Trustwert. Vorhandene administrative
Anmeldung und Windows-Client für beide SQL-Plattformen. Kein neuer Linux-Client-
oder authentifizierter TLS-Nachweis. Jeder separate frische Auditprozess bindet
das genaue finale Journal, die tatsächliche Zielversion, eigene DB-Abwesenheit,
unveränderte gesamte Serverkonfiguration und Assemblytrust sowie die Eingabepins.
Der eigene DB-Cleanup prüft Identität, Erstellungszeit und Ownermarker.
Ein separater privater Nachprüfer bestätigte alle eindeutigen Profile,
Collations, Originaljournale, Audits, Core-Definitionen und Quellenbindungen.
Private Originale und Quellkapseln bleiben außerhalb Git erhalten.

Elf verbindungslose
[Gegenproben](../../Tests/Release/test_split_advanced_lifecycle_lab_contract.py)
einschließlich des echten kanonischen Batchvergleichs und der Modul-Static-
Vertrag bestehen; die Tests sind zentral registriert. Keine Produkt-SQL-,
Manifest-, Rechte-, Principal-, CLR-/Trust-/Server- oder Labänderung.
Weitere Genuine-Upgrades, Kollisionen, AppLock-/Rollback-/Sessionprofile,
Consumer-Collations, Lowpriv-CrossDB-Identitäten, Ressourcen- und harte
Host-Recoveryfälle bleiben separat. Keine allgemeine Lifecycle- oder
Modulgesamtabnahme, Veröffentlichung oder Tags.
