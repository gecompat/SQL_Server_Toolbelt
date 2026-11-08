# File Content: getrennte AppLock-Sitzung und verifizierte Freigabe

Am 2026-11-08 bestand File Content 1.0.0 mit ResultTable 1.0.0 diesen
gezielten Sperrscope: **zwölf vollständige Läufe, 24 lokale/direkt zentrale
Kontexte, 96 Profile und zwölf frische unabhängige Windows-Clientaudits**.
Alle 24 eigenen Testdatenbanken sind entfernt. Ergebnis:
**PASS_FOR_DECLARED_FILE_CONTENT_APPLOCK_SCOPE**.
Gesamtstatus bleibt `partially validated`, `unreleased`.

## Ausgewählte Ziele und vier Profile je Kontext

| SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Der [Adapter](../../Tests/Release/Invoke-FileContentLockLab.ps1) und die
[Fixture](../../Tests/Release/Runtime/FileContent.LockProfiles.Contract.ps1)
liefen aus [dde7a905](https://github.com/gecompat/SQL_Server_Toolbelt/commit/dde7a905aaff4e19ed61adebd92f3cf80ba573bb).
Kanonischer Erstexport von genau ResultTable und File Content; weitere Schritte
verwenden die vollständigen unveränderten öffentlichen Deploy-/Uninstall-Batches.
Produkt-SQL, Version, Manifest und Rechte bleiben unverändert.

Eine zweite echte Verbindung zur eigenen Testdatenbank nimmt ausschließlich
die AppLock `toolbelt.deploy.toolbelt.file.content` mit `LockOwner=Session`,
`LockMode=Exclusive` und Timeout0. Nichtnegativer Rückgabecode, positive
verschiedene Arbeits-/Sperrsitzungs-IDs und tatsächlich gehaltenes `Exclusive`
sind Voraussetzungen. Beide Verbindungen verwenden die vorhandene Anmeldung;
das ist keine andere Identität oder niedrigprivilegierte Sitzung.

| Profil | Festes Orakel | Anzahl |
|---|---|---:|
| Deploy unter fremder Sitzungssperre | Exakt 51277/State1 und unveränderter ausgewählter DB-/Katalog-/Transaktionszustand | 24 |
| Uninstall unter derselben Sperre | Exakt 51277/State1 und unveränderter ausgewählter Zustand | 24 |
| Deploy nach verifizierter Freigabe | Erfolgreich; ausgewählte Objektdefinitionen, Identitäten und Properties unverändert | 24 |
| Uninstall nach verifizierter Freigabe | Modulobjekte, Marker und leeres Modul-Schema entfernt; Core-Definitionen erhalten | 24 |

Das ergibt **48 exakte negative und 48 positive Profile**. Die Sperrsitzung
muss nach beiden Abweisungen mit derselben Sitzungs-ID weiterhin `Exclusive`
melden. Erst nach erfolgreichem eigenem `sp_releaseapplock` und bestätigtem
`NoLock` sind die beiden Erfolgspfade zulässig. 24 gebundene Sperrreceipts
belegen Aufnahme, Beibehaltung und Freigabe. Alle Kontexte enden mit
`@@TRANCOUNT=0` und `XACT_STATE()=0`; ResultTable-Definitionen bleiben erhalten.

Die [vorhandenen Status-/Fehler-/Abwesenheitsorakel](../../Tests/Release/Runtime/LifecycleProfiles.Contract.ps1)
werden quellgebunden wiederverwendet, nicht ihr vollständiger Lifecycleablauf.
Ausgewählt verglichen werden eigene Objektidentitäten und Definitionen,
Extended Properties, Modul-Schemata und Transaktionszustand. Kein allgemeiner
Vergleich aller Session-/TempDB-Metadaten, Tabelleninhalte oder Berechtigungen.
Erfolg, andere SQL-Fehler oder ein anderer State erfüllen das Fehlerorakel nicht.

## Endlicher Rahmen, unabhängige Nachprüfung und Grenzen

Der ausdrückliche autonome Qualifikationsauftrag umfasst diesen getrennten
Restpunkt. Vor Start: ein Verantwortlicher ohne Agents, zwölf Producer-/Auditpaare,
**24 Lauf-/Auditaufrufe, 24 eigene DB-Reservierungen und 45 Minuten**, keine
native Wiederholung. Alle zwölf Fälle bestanden beim ersten Versuch und alle
reservierten Audits innerhalb der ursprünglichen Frist. 24/24 Aufrufe und
Reservierungen sind verbraucht; der Rahmen ist geschlossen.

Jeder Producer hat ein festes Arbeits-/Cleanupfenster und einen begrenzten
Kindprozess mit getrennten Ausgabekanälen. Die eigene Sperrsitzung wird auch
im Fehlerpfad freigegeben und geschlossen; dies ist keine Garantie für einen
verlorenen Host oder Koordinator. DB-Cleanup verlangt unveränderte eigene
Identität, Erstellungszeit und Ownermarker.

Schema-validierter Functional-Labvertrag, genaue Zielversion/Plattform/CL,
Verschlüsselung und expliziter unveränderter Trustwert. Vorhandene administrative
Anmeldung und Windows-Client für beide SQL-Plattformen. Jeder separate frische
Audit bindet das genaue finale Journal, die Zielversion, eigene DB-Abwesenheit,
unveränderte gesamte Serverkonfiguration und Assemblytrust sowie alle Eingabepins.
Ein separater privater Nachprüfer bestätigte sämtliche Profile, verschiedenen
Sitzungs-IDs, Sperrreceipts, Originaljournale, Audits und Quellenbindungen.
Private Originale und Quellkapseln bleiben erhalten und außerhalb Git.

Zehn verbindungslose
[Gegenproben](../../Tests/Release/test_file_content_lock_lab_contract.py)
prüfen Admission ohne SQL/Labimport, Ziele/Modi/Frist/Pins, verbotene Rechte-/
Principal-/Serveroperationen sowie die Verweigerung einer fehlenden/geteilten
Sperre oder derselben Sitzung. Modul-Static und Quellen-Preflight bestehen;
die Tests sind zentral registriert.

Frühere [Repeat-](FILE-CONTENT-REPEAT-COMPLETION.md) und
[Lifecyclebelege](FILE-CONTENT-LIFECYCLE-QUALIFICATION.md) bleiben unverändert.
Keine erneute volle Repeat-/API-/Client-/Lifecyclefixture. Der Sperrzustandswechsel
ist der neue Testinput für die Erfolgspfade. Keine Datei-I/O, Rechtevergabe,
neuen Identitäten, CLR-/Trust-/Konfigurations-/Labänderungen oder Veröffentlichung.
Keine allgemeine Race-/Caller-Transaktions-/SET-/Rollback-/Ressourcen-/TLS-/
CrossDB-Identitäts-/Host-Recovery- oder vollständige Modulqualifikation.
