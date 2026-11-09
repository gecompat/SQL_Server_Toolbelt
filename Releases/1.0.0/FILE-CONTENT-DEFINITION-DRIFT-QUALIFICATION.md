# File Content: gezielte Reparatur veränderter Prozedurdefinitionen

Am 2026-11-09 bestanden **zwölf vollständige Läufe, 24 lokale/direkt zentrale
Kontexte, 48 gezielte Definitionsreparaturen und zwölf frische unabhängige Audits**.
Alle 24 eigenen Testdatenbanken sind entfernt. Ergebnis:
**PASS_FOR_DECLARED_FILE_CONTENT_DEFINITION_DRIFT_SCOPE**.
File Content 1.0.0 mit ResultTable 1.0.0; Status bleibt teilweise validiert und
unveröffentlicht. Keine Änderung an Produkt-SQL, Version oder Manifest.

| SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

## Neuer Ausgangszustand und feste Orakel

Der [Adapter](../../Tests/Release/Invoke-FileContentDriftLab.ps1) und die
[Fixture](../../Tests/Release/Runtime/FileContent.DriftProfiles.Contract.ps1)
liefen aus [aec7fd60](https://github.com/gecompat/SQL_Server_Toolbelt/commit/aec7fd60512197e919d89e73ea15cacbdf983201).
Der kanonische Erstexport installiert ausschließlich ResultTable und File Content.
Zwei feste synthetische Allowlist-Zeilen enthalten aktive/inaktive Werte,
Unicode/NULL und feste Auditzeiten. Keine tatsächliche Datei wird angesprochen.

Je Kontext werden `USP_LoadBinaryFile` und `USP_LoadTextFile` einzeln durch
`ALTER PROCEDURE` auf einen festen synthetischen Sentinelbody geändert. Vor
jedem Reparaturlauf sind eine positive unveränderte Objekt-ID und ein wirklich
anderer Bodyhash zwingend. Gleicher Hash, fehlende Definition oder eine andere
Objekt-ID erfüllen das Driftorakel nicht. Die veränderte Prozedur wird nicht
aufgerufen; der Test untersucht das öffentliche Deployment.

Danach läuft das vollständige unveränderte öffentliche Same-Version-Deploy.
Der originale Bodyhash, die ursprüngliche Objekt-ID und der ausgewählte
Katalogzustand müssen exakt wiederhergestellt sein. Alle Allowlist-Zeilen
einschließlich UTF-16-Bytes, NULL, Aktivflag, Auditzeit und Identity sowie
sämtliche beobachteten Datenbankberechtigungen bleiben unverändert.

**48 absichtlich etablierte Driftzustände und 48 erfolgreiche Reparaturen**,
je zwei Reparaturprofile pro Kontext. Ein ursprünglicher und ein neu veränderter
Body sind verschiedene Testinputs; keine erneute Voll-Repeat-, API-, Client-,
Uninstall- oder AppLockfixture. Die bereits qualifizierte
[Katalogzustandsfunktion](../../Tests/Release/Runtime/LifecycleProfiles.Contract.ps1)
wird allein quellgebunden wiederverwendet, nicht der gesamte Lifecycleablauf.
Ausgewählt verglichen werden Objektidentitäten/-typen und Definitionen,
Extended Properties, Core-/File-Schemata und Transaktionszustand. Core-Definitionen
bleiben erhalten; sämtliche Kontexte enden transaktionsneutral.

## Endlicher Rahmen und unabhängiger Abschluss

Der ausdrückliche autonome Qualifikationsauftrag umfasst diesen echten Restfall.
Vor Admission: ein Verantwortlicher, keine Agents; höchstens **24 Ziel-/Auditaufrufe,
24 eigene DB-Reservierungen und 45 Minuten**, zwölf Producer mit jeweils
reserviertem frischem separatem Audit, keine Wiederholung. Alle zwölf Fälle
bestanden beim ersten Versuch innerhalb dieser Frist. 24/24 Aufrufe und
Reservierungen sind verbraucht und geschlossen; ältere Wellen und Fehler
bleiben unverändert geschlossen.

Schema-validierter Functional-Labvertrag, genau ausgewählte READY-Ziele,
tatsächlich geprüfte Plattform/Version/CL, Verschlüsselung und expliziter
unveränderter Trustwert. Vorhandene administrative SQL-Anmeldung über
Windows-Client; kein Windows-Login-, Linux-Clienthost- oder TLS-Identitätsnachweis.
Keine neuen Identitäten oder Grants, keine Owner-/CLR-/Trust-/Konfigurations-/
Lab-/Hoständerungen oder Datei-I/O. Eigene DB-Entfernung verlangt eindeutige
Identität, Erstellungszeit und Ownermarker.

Zwölf unabhängige frische Audits binden exakte finale Journale, tatsächliche
Ziele, Abwesenheit aller eigenen DBs, gesamte unveränderte Konfiguration und
Assemblytrust sowie alle Eingabepins. Der separate private Nachprüfer bestätigt
48 belegte Drift-/Wiederherstellungspaare,
alle Originaljournale, Audits und Pins. Private Originale und Quellkapseln bleiben
außerhalb Git erhalten.

Zehn [verbindungslose Gegenproben](../../Tests/Release/test_file_content_drift_lab_contract.py)
prüfen Admission, Ziele/Modi, Frist/Pins, verbotene Rechte-/Principal-/Server-
operationen und das tatsächliche Body-/Identitätsübergangsorakel. Das neue
Übergangsorakel weist unveränderte Driftbodies, falsche Wiederherstellung,
abweichende IDs und ungültige Hashes zurück. Tests zentral registriert;
kanonischer Quellen-/Exportpreflight bestanden.

Frühere [Repeat-](FILE-CONTENT-REPEAT-COMPLETION.md),
[Lifecycle-](FILE-CONTENT-LIFECYCLE-QUALIFICATION.md) und
[AppLocknachweise](FILE-CONTENT-APPLOCK-QUALIFICATION.md) bleiben gültig in ihrem
jeweiligen Scope und wurden nicht als vollständige Fixtures wiederholt.
Dieser Nachweis schließt nur die gezielte Bodyreparatur der zwei bestehenden
Prozeduren. Tabellen-/Schema-/Owner-/ACLdrift, historische Versionen,
Fremdownership, andere Rechte-/Session-/Rollback-/Race-/Ressourcen-/Provider-
und Recoveryprofile sind getrennt; keine Modulgesamtabnahme oder Veröffentlichung.
