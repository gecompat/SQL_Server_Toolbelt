# Edit Distance 1.1: fehlende physische API-Kontexte

Am 2026-11-09 bestand der erklärte Restumfang mit der vorhandenen qualifizierten
Paket-DLL: **acht vollständige Läufe, 16 lokale/direkt zentrale Kontexte,
96 unveränderte SQL-Fixtures und acht frische unabhängige Windows-Clientaudits**.
Alle 16 eigenen Testdatenbanken sind entfernt. Ergebnis:
**PASS_FOR_DECLARED_EDIT_DISTANCE_MISSING_TARGET_SCOPE**.
Modulstatus bleibt `partially validated`, `unreleased`.

## Ziele, Paket und Originalfixtures

| SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Der [Adapter](../../Tests/Release/Invoke-EditDistanceTargetsLab.ps1) lief aus
[a77971c9](https://github.com/gecompat/SQL_Server_Toolbelt/commit/a77971c93903b1aed16ee86fc7fd9e39fda73781).
Er verwendet ausschließlich die Edit-Distance-DLL aus dem vorhandenen
CLR-Installations-ZIP. Exakte ZIP-/DLL-Digests und alle 13 originalen Modulquellen
stimmen mit der [Paketqualifikation](EDIT-DISTANCE-PACKAGE-QUALIFICATION.json)
überein. Kein neuer Build oder Austausch des ursprünglichen ZIPs/Nachweises.
Bestehende Framework-/Referenz-/IL- und
[Callerrechtebelege](CLR-STRING-CALLER-CURRENT-BINDING.md) werden wiederverwendet;
diese Suites werden nicht erneut ausgeführt.

Kanonischer Export nur von Edit Distance 1.1.0 ohne Modulabhängigkeit;
AssemblyBits aus der geprüften DLL, ExpectedInstalledAssemblyHash=0x für die
erwartete Abwesenheit vor der Erstinstallation. Native Zielplattform/-version
und CL, Modulversion und DeploymentMode sowie genau eine SAFE_ACCESS-Assembly
mit erwarteten Bytes sind geprüft. Assemblybytes und ausgewählte SQL-/CLR-
Objektdefinitionen bleiben nach den Fixtures unverändert.

Je Kontext liefen die vollständigen unveränderten Originaldateien aus
[Tests/Runtime](../../Modules/toolbelt.string.edit-distance/Tests/Runtime/):

| Fixture | Geprüfter Umfang |
|---|---|
| Distance.Contract.sql | Feste Distanz-/OSA-Werte, Defaults, Prioritäten, Unicode/NUL und Mengenorakel |
| Distance.Boundaries.sql | Originale Raw-/Scalar-/Work-/Threshold-Grenzen und Fehlerprioritäten |
| Jaro.Contract.sql | Originale Score-, Profil-, Unicode- und Fehlerorakel |
| Jaro.Boundaries.sql | Originale Ressourcen- und Fehlerprioritätsfälle |
| InstalledMetadata.Contract.sql | Sechs Slots, Parameter-/Spaltentypen und Ordinals, SAFE und CLR-EntryPoints |
| Lifecycle.Contract.sql | Read-only Versions-/Managedmarker-/Slot-/SAFE-/Assemblyhash-Baseline |

Das sind sechs Dateien in 16 Kontexten, keine Behauptung von 96 Einzelassertions.
Die einzige Fixtureersetzung setzt ExpectedInstalledAssemblyHash auf den exakten
DLL-Hash. Fehlende SQLCMD-Werte werden zurückgewiesen. Nach jeder Fixture sind
`@@TRANCOUNT=0` und `XACT_STATE()=0` bestätigt. Die Baselinefixture ist kein
Upgrade-, Uninstall-, Rollback- oder vollständiger Lifecyclelauf.

## Grenzen, Cleanup und aktuelle Zuordnung

Der ausdrückliche autonome Qualifikationsauftrag umfasst diesen getrennten
Restpunkt. Vor Admission: ein Verantwortlicher ohne Agents,
**acht Producer-/Auditpaare, höchstens 16 Ziel-/Auditaufrufe, 16 eigene
DB-Reservierungen und 45 Minuten, keine Wiederholung**. Alle acht Fälle und
reservierten Audits bestanden beim ersten Versuch innerhalb dieser Frist.
16/16 Aufrufe und Reservierungen sind verbraucht; der Rahmen ist geschlossen.
Frühere Fehler, Grenzen und Originalnachweise bleiben unverändert.

Schema-validierter Functional-Labvertrag, genaue READY-Ziele, Verschlüsselung
und unveränderter expliziter Trustwert. Vorhandene administrative SQL-Anmeldung
über Windows-Client; kein Windows-Login-, Linux-Clienthost- oder authentifizierter
TLS-Nachweis. Keine neuen Benutzer oder Rechte.

Die vorhandenen [CLR-Umgebungshelfer](../../Tests/Release/ClrCaller.Environment.ps1)
schützen notwendige hashgebundene Trust-/Konfigurationsschritte: strict security
bleibt aktiv; unbekannte Verbraucher, ausstehende Änderungen oder Ownershipdrift
blockieren. Vorbestehende Einträge bleiben erhalten; nur eindeutig eigene
unveränderte Einträge werden nach Entfernung aller eigenen DBs entfernt.
Nur sicher eigene Konfigurationsänderungen werden zurückgestellt. Kein
TRUSTWORTHY ON, Neustart oder Lab-/Zertifikats-/Truststoreeingriff.

Jeder separate frische Audit bindet finales Journal, tatsächliches Ziel, eigene
DB-Abwesenheit, gesamte unveränderte finale Serverkonfiguration und Assemblytrust
sowie Eingabepins. Ein separater privater Nachprüfer bestätigt Originaljournale,
16 vollständige Modusreceipts, 96 Fixtures, alle Audits und Quellenbindungen.
Private Originale und Quellkapseln bleiben außerhalb Git.

Zehn [verbindungslose Gegenproben](../../Tests/Release/test_edit_distance_targets_lab_contract.py)
prüfen Ziele, Frist, boolesche Freigabe, Pins, Modulversion, Originalquellen,
Fixtureumfang und Paket-/DLL-Herkunft. Eine umgehashte fremde DLL oder kopierte
Ersatz-Provenienzdatei reicht nicht. Kanonischer Exportpreflight bestanden;
Tests zentral registriert.

Die bereits geprüften Windows-2025-/Linux-2019-Kontexte werden nicht erneut
ausgeführt. Ihre ursprünglichen Artefakt-/Methodenbindungen bleiben erhalten;
kein neuer gemeinsamer Zwölf-Paare-Paketlauf wird behauptet. Pauschale fehlende
physische Vollfixture-Kontexte sind für die acht oben ausgewählten Paare erledigt.
Weitere Lifecycle-/DDL-/Owner-/CrossDB-Rechte, Heap-/Parallelitäts-/Betriebs-/
Recoveryprofile und Modulgesamtabnahme bleiben separat. Keine Produkt-, Manifest-,
Status- oder Versionsänderung und keine Veröffentlichung oder Tags.
