# JSON Core und Schema: fehlende Marker und Assembly-Sichtbarkeit

Stand2026-11-12: **PASS_FOR_DECLARED_FIVE_POINT_MATRIX**. 1848 eindeutige
Profile auf24 lokalen/direkt zentralen Windows-/Linux-Kontexten, davon76
quellgebunden wiederverwendet und1772 neu ausgeführt. Zwölf korrigierte
Koordinatoren und alle13 frischen unabhängigen Abschlussaudits bestehen.
Der erste Koordinator bleibt FAILED_CLEANED. Die fünfte Prüfung belegt die
tatsächliche SQL-Engine-Sperre, keinen ausgeführten öffentlichen Guard gegen
eine unsichtbare vollständig installierte Schema-Assembly.

## Auftrag, Abgleich und fünf begrenzte Punkte

Der Benutzer beauftragte die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuschließen, gültige Nachweise wiederzuverwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Die bestehenden Typdrift-, Registrierungs-, Caller-, Lock-, Dependency-,
Signatur- und CL-Belege bleiben unverändert. Fehlende Eigenschaften und
vorhandene Eigenschaften mit SQL NULL sind eigenständige bisher ungeprüfte
Eingaben; die früheren Typ-/Wertdriftfälle wurden nicht wiederholt.

| Punkt | Tatsächlicher Nachweis | Profile bestanden/geplant |
|---|---|---|
| 1 | Jeden der sechs Core-Assemblymarker löschen oder auf SQL NULL setzen; öffentliche Core-Deploy-/Uninstall-Abweisung | 576/576 |
| 2 | Dieselben sechs Variantenpaare an Schema-Assemblymarkern; öffentliche Schema-Deploy-/Uninstall-Abweisung | 576/576 |
| 3 | Je drei Ownershipmarker an öffentlicher Schema-USP und interner CLR-Funktion löschen/NULL setzen; Deploy und Uninstall | 576/576 |
| 4 | Core-Sichtbarkeit ON: direkte Core- und delegierte Schema-Deploy-/Uninstall-Abweisung; exakte Rückstellung OFF | 96/96 |
| 5 | Schema-Sichtbarkeit OFF bei bestehender CLR-Funktion: exakte Engine-Abweisung6284/Severity16, unveränderter installierter Zustand | 24/24 |

Die sechs Assemblymarker sind Managed, ModuleId, ModuleVersion, DeploymentMode,
AssemblySha512 und ArtifactId mit jeweiligem Toolbelt-Präfix. Ownershipmarker
sind ModuleId, ModuleVersion und DeploymentMode an USP_ValidateJsonSchema und
FT_ValidateJsonSchemaInternal. Die Assemblybytes bleiben in allen Fällen gleich.

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | 154 zusammengesetzte Profile:76 erhaltene Originalprofile und78 neue Profile; beide Audits PASS |
| Windows | SQL2022/CU26 | 150,160 | je154 Profile und frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160,170 | je154 Profile und frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 154 Profile und frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je154 Profile und frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je154 Profile und frischer Audit PASS |

## Reale Enginegrenze statt fiktiver Guardabdeckung

Die erste Fixture versuchte nach76 bestandenen lokalen Profilen, die weiterhin
von ihrer CLR-Funktion verwendete Schema-Assembly unsichtbar zu machen. SQL
Server lehnte bereits diese Fixtureänderung ab. Der Fehler stammt aus meiner
unzutreffenden Annahme über einen herstellbaren Testzustand; er bleibt im
Originaljournal erhalten. Microsoft dokumentiert [Fehler6284, Severity16](https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-events-and-errors-6000-to-6999?view=sql-server-ver17):
SQL-Objektreferenzen verhindern das Unsichtbarmachen einer Assembly.

Die korrigierte fünfte Prüfung verlangt deshalb genau diese Engine-Abweisung
mit dem erwarteten öffentlichen Objektbezug und unverändertem vollständigem
Snapshot. Der tatsächliche Engine-State wird privat protokolliert; es wird
kein fester State für den nicht vom Toolbelt-Vertrag definierten Enginefehler
behauptet. Es werden keine Objekte gelöscht oder fremde Binarys geladen, um
die Enginebedingung zu umgehen. Die zwei ursprünglich geplanten öffentlichen
Schema-Aufrufe bei unsichtbarer vollständiger Installation sind **not executed**.
Die24 Engineprofile sind ein separater Invariantennachweis und werden nicht
als48 öffentliche Lifecycle-Abweisungen ausgegeben.

## Methode, Orakel und Wiederherstellung

Der [vorhandene Matrixrunner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
wählt die neue [Marker-/Sichtbarkeitsfixture](../../Tests/Release/Runtime/JsonLifecycle.MarkerAbsenceVisibility.Contract.ps1)
ausschließlich für `json-lifecycle-marker-absence-visibility/v1`; die bisherige
Binary-/Registrierungsfixture bleibt an ihren eigenen Vertrag gebunden.
Kanonische Script-/Includeexpansion, qualifiziertes Paket, bekannte Release-DLLs,
Projekt-/Compilerquellen, Sitzungs-/AppLock-Orakel und Owned-Cleanup werden
wiederverwendet. Keine zweite Kopie des vollständigen Runners oder seiner
bisherigen Admission-Suite. Binary-Negativvektoren werden im neuen Scope
weder erzeugt noch als native Profile ausgeführt.

Nur schema-validierte explizite READY-Ziele, feste Engine-/Plattform-/CL-Auswahl
und unveränderter Functional-Transport: Verschlüsselung erforderlich, kein
authentifizierter TLS-, Windows-Anmelde-, GUI- oder SQLCMD-CLI-Nachweis daraus.
Keine neuen Rechte, Principals, Owner, Assemblybytes, Labressourcen, Truststores
oder serverseitige Datei-I/O. Die einzige ALTER-ASSEMBLY-Fixtureoperation ist
die Sichtbarkeit der zwei exakt benannten eigenen bekannten Assemblies.

18 Originalmarker werden mit ihrem sql_variant-Typ in einer Caller-Temp-Tabelle
gehalten. Gelöschte Marker werden neu angelegt, SQL-NULL-Marker aktualisiert;
vor jeder Rückstellung muss der beschädigte Zustand unverändert sein. Danach
werden Typ, Länge, Rohwert, Identitäten, Definitionen, Owner, Berechtigungen,
Parameter, SET-Metadaten und Assemblyflags gegen den Originalsnapshot geprüft.
Die neue Snapshotergänzung erfasst ausdrücklich auch Core-is_visible.

Jede Toolbelt-Abweisung verlangt genau einen passenden Fehler mit State1 und
Severity16 sowie exaktem unverändertem Text: Coretuple55623, Schematupel/
Ownership55633, Core-Sichtbarkeit direkt und delegiert55623. Lokale
Transaktionsneutralität und unabhängige Sitzungs-/AppLock-Beobachtung bestehen.
Der Enginefehler6284 besitzt das oben getrennt erklärte Orakel.

## Erhaltener Fehlversuch und ungeprüfte Fortsetzung

Methodenstand `5836781c` blieb nach76 gültigen lokalen Profilen FAILED_CLEANED;
sein frischer Audit ist PASS. Die korrigierte Methode `659c8edb` übernimmt genau
diese76 Profile und führt dort nur den neuen Enginefall sowie den bislang
ungeprüften zentralen Kontext aus. Elf weitere Zielpaare wurden erstmals
vollständig geprüft. Kein grünes Profil wurde wiederholt, kein ursprünglicher
Koordinator zu COMPLETE oder Gesamt-PASS umgedeutet.

Die Übernahme prüft das exakte Originaljournal samt frischem Audit, dessen
SHA256, ursprünglichen Runset, Lab-/Zielbindung, aktuelle Produktpins,
Originalquellenkapsel und unveränderte Snapshot-/Marker-/Fehlerorakel. Die
erwartete lokale Präfixmenge enthält genau76 erfolgreiche Profile mit erhaltenem
Snapshot. Der neue Modus-/Gesamtabgleich schließt diese gebundenen Profile aus
seiner neuen Ausführung aus. Der aktuelle Audit bestätigt den deklarierten
Restumfang und dessen Cleanup; die getrennte Gesamtprüfung bildet die Vereinigung
der Originalmengen ohne fehlende oder doppelte Keys.

## Endlicher Rahmen und Abnahme

Ein Verantwortlicher, keine Agenten: maximal32 Ziel-/Auditaufrufe,32 DB-
Reservierungen und60Minuten ab erster nativer Aufnahme. Derselbe ursprüngliche
Rahmen ist mit **26/32 Aufrufen und26/32 DB-Reservierungen** innerhalb der Frist
geschlossen. Der Fehlversuch bleibt mitgezählt; keine Frist oder Grenze erneuert.
Die unbenutzte Reserve bleibt geschlossen. Die erste Revision war ausschließlich
Offlinevorbereitung und hatte keinen SQL-Zugriff.

Alle25 tatsächlich angelegten eigenen DBs und26 eigenen Releasehash-Trusteinträge
sind entfernt, sechs eigene CLR-Konfigurationsänderungen zurückgenommen. Alle13
frischen Audits binden das jeweilige exakte finale Journal, Ressourcenabwesenheit,
unveränderte fremde Konfiguration/Trust und Inputpins. Private Originale,
Fehlerjournale und Quellenkapseln bleiben außerhalb Git erhalten.

Zwölf bestehende Admission-Gegenproben, zwei neue [Fixture-/Profilgegenproben](../../Tests/Release/test_json_marker_absence_visibility_lab_contract.py)
und quellgebundene Preflights bestehen. Die neuen Gegenproben prüfen exakte
Fixtureauswahl, erforderliche gemeinsame Pins, missing/null- und CL-abhängige
Profilclosure, unerlaubte Properties, fehlende/doppelte/fehlerhafte Präfixe,
SQL-Engine-Fehlerorakel und auf Sichtbarkeit begrenzte Mutationen. Die neue
Suite ist im vorhandenen Releasevalidator registriert; kein neuer CI-Job.

Andere Owner-/Rechte-/Identitäts-/Binding-/Recovery-/Ressourcenpflichten bleiben
getrennt. Beide Module bleiben **partially validated, unreleased**. Exakte
Head-CI und tatsächliche Main-PUSH-CI bleiben Integrationsgates; keine
Veröffentlichung oder Tags.
