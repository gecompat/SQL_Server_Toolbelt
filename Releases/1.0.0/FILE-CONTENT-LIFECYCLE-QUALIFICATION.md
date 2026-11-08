# File Content: unbekannte Versionen, Kollisionen und Uninstall

Am 2026-11-08 bestand File Content 1.0.0 mit ResultTable 1.0.0 die hier
erklärte Lifecycle-Matrix: **zwölf vollständige Läufe, 24 lokale/direkt zentrale
Kontexte, 288 Profile und zwölf frische unabhängige Windows-Clientaudits**.
Alle 24 eigenen Testdatenbanken sind entfernt. Ergebnis:
**PASS_FOR_DECLARED_FILE_CONTENT_LIFECYCLE_SCOPE**. Das Gesamtmodul bleibt
`partially validated`, `unreleased`.

## Ziele und unveränderte öffentliche Skripte

| SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Der [Adapter](../../Tests/Release/Invoke-FileContentLifecycleLab.ps1) und die
[Fixture](../../Tests/Release/Runtime/LifecycleProfiles.Contract.ps1) liefen aus
[d44e8b04](https://github.com/gecompat/SQL_Server_Toolbelt/commit/d44e8b0460d0d7f9db922431e1c3b41395f79dee).
Initial installiert der kanonische Export exakt ResultTable und File Content.
Weitere Aktionen verwenden die vollständigen aktuellen öffentlichen
File-Content-Deploy-/Uninstall-Batches. SQLCMD-Includes werden relativ zum
originalen Deploymentverzeichnis aufgelöst; Zeilenenden entsprechen dem
kanonischen Erstexport. Kein Produkt-SQL, Modulmanifest oder Versionswert
wurde für diese Nachqualifikation geändert.

## Zwölf Profile je Kontext

| Profil | Festes Orakel | Anzahl über alle Kontexte |
|---|---|---:|
| Unbekannter Versionsmarker, Deploy und Uninstall | Exakt 51273/State 1, keine nachfolgende Batchausführung oder Zustandsänderung | 48 |
| Je eine fremde Tabelle unter jedem der drei reservierten Objektnamen, Deploy und Uninstall | Exakt 51274/State 1; fremde Identität, Zeile und ausgewählte Katalogmetadaten erhalten | 144 |
| Uninstall mit zusätzlicher synthetischer Tabelle im Modul-Schema | Modulobjekte und Marker entfernt; fremde Zeile 2718, Schema- und Objektidentität erhalten | 24 |
| Neuinstallation im erhaltenen Schema | Alle drei Modulobjekte und korrekte Version-/Modusmarker vorhanden; fremde Zeile erhalten | 24 |
| Uninstall nach eigener Entfernung der Zusatztabelle | Modulobjekte, Marker und nun leeres Schema entfernt | 24 |
| Uninstall bei bereits fehlendem Modul | Unveränderter Zustand und weiter fehlendes Modul-Schema | 24 |

Somit sind **192 exakte negative und 96 positive Lifecycleprofile** bestanden.
Der unbekannte Marker ist ausschließlich eine synthetische Negativfixture,
kein behaupteter historischer Upgradepfad. Die drei Kollisionsobjekte sind
einzeln angelegte synthetische Tabellen, keine fremden realen Verbraucher.

Vor und nach jeder erwarteten Ablehnung werden eigene Objektidentitäten und
Definitionen, Extended Properties, die beiden Modul-Schemata und der neutrale
Transaktionszustand verglichen. Eine erfolgreiche Operation, ein anderer Fehler
oder ein abweichender State erfüllen das Fehlerorakel nicht. Die festen
Tabellenzeilen werden zusätzlich gelesen. Nach jedem vollständigen Kontext
sind `@@TRANCOUNT=0` und `XACT_STATE()=0`; die ResultTable-Objektdefinitionen
stimmen mit dem Zustand vor den Lifecycleprofilen exakt überein. File Content
wird dabei absichtlich entfernt und neu installiert: diese Prüfung behauptet
keinen Erhalt seiner ursprünglichen Objektidentitäten über Uninstall hinweg.

## Grenzen, Wiederverwendung und Nachprüfung

Der fortbestehende ausdrückliche Auftrag zur autonomen Qualifikation erlaubt
diesen separat abgegrenzten Restpunkt. Vor dem Start festgelegt: ein
Verantwortlicher ohne Agents, zwölf Producer-/Auditpaare, **24 Aufrufe,
24 DB-Reservierungen und 45 Minuten**, keine native Wiederholung. Tatsächlich
bestanden alle zwölf Fälle beim ersten Versuch innerhalb der ursprünglichen
Frist. Der Rahmen ist mit 24/24 Aufrufen und Reservierungen geschlossen.
Die vorherige [Repeat-Welle](FILE-CONTENT-REPEAT-COMPLETION.md) bleibt
abgeschlossen und wurde weder wiederholt noch umgeschrieben. Ihre frühere
Fehlerhistorie bleibt unverändert.

Alle Ziele wurden explizit aus dem schema-validierten Labvertrag ausgewählt,
Version, Plattform und CL nativ bestätigt. Vorhandene administrative Anmeldung,
Windows-Client und Functional-Transport mit Verschlüsselung und explizitem
Trustwert. Linux bezeichnet das SQL-Ziel, keinen Linux-Clienthost.

Ein separater frischer Auditprozess je Paar bindet das exakte finale Journal,
die tatsächliche Zielversion, die Abwesenheit der eigenen Datenbanken,
unveränderte gesamte Serverkonfiguration und Assemblytrust sowie die
Eingabepins. Eigene DB-Identität, Erstellungszeit und Ownermarker sichern den
Cleanup. Ein unabhängiger privater Nachprüfer bestätigte alle 288 eindeutigen
Profile, Originaljournale, Audits und Quellenbindungen. Private Quellkapseln
und Rohdaten bleiben außerhalb Git erhalten.

Zehn verbindungslose [Gegenproben](../../Tests/Release/test_file_content_lifecycle_lab_contract.py)
prüfen echte Admission ohne Labimport/SQL, Frist-/Ziel-/Modus-/Quellenabweichungen,
verbotene Rechte-/Principal-/Serveroperationen und Ablehnung eines fehlenden
Sollfehlers oder eines unabhängigen Adapterfehlers. Sie stehen im zentralen
Release-Testregister. Der Modul-Static-Vertrag besteht ebenfalls.

Keine neuen Benutzer oder Rechte, Datei-I/O, CLR-/Trusteinträge, Serveroptionen
oder Labressourcen. Keine Minimalrechte-, nichtleere ACL-, unbekannte
Tabellenschemata-, vollständige Drift-/AppLock-/Migrations-, Ressourcen-,
CrossDB-Identitäts-, TLS- oder harte Host-Recoveryabnahme. Zusätzliche echte
Datei-I/O bleibt optional. Keine Veröffentlichung oder Tags.
