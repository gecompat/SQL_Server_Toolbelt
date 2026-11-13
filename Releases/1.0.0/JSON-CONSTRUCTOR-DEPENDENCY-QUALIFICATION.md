# JSON Schema: tatsächlich installierte Constructor-Dependency

Stand2026-11-13: **PASS_FOR_DECLARED_FIVE_POINT_MATRIX**. Alle fünf ausgewählten
Restmatrizen bestehen mit624 eindeutigen öffentlichen Schema-Deploy-Profilen auf24
lokalen/direkt zentralen Windows-/Linux-Kontexten. Zwölf Erstläufe und zwölf
frische unabhängige Abschlussaudits PASS, kein nativer Fehlversuch oder Retry.
Keine Produkt-/Binäränderung und keine vollständige Modulqualifikation.

## Auftrag und Abgleich

Der Benutzer beauftragte die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuarbeiten, gültige Nachweise wiederzuverwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Die bisherigen Constructor-Orphanregistrierungen ohne Assembly, direkten
Constructor-Lifecycle-, Core-/Schema-Marker-, Signatur-, Caller-, Lock- und
Dependencybelege bleiben unverändert. Sie ersetzen keine tatsächlichen Schema-
Deploy-Aufrufe bei vorliegender bekannter Constructor1.3-Assembly.

| Punkt | Tatsächliche Fixture an vollständig installiertem Constructor1.3 | Schema-Deploy-Profile bestanden/geplant |
|---|---|---|
| 1 | Jeden der sechs Assemblymarker in varchar(128) überführen; abweichende SQL-variant-Typ-/Längenfacetten | 144/144 |
| 2 | Jeden der sechs Assemblymarker vollständig löschen | 144/144 |
| 3 | Jeden der sechs Assemblymarker auf SQL NULL setzen | 144/144 |
| 4 | DB-Versionsregistrierung fehlt, ist NULL, alt1.2.0 oder nichtkanonisch1.3.00 | 96/96 |
| 5 | DB-Modusregistrierung fehlt, ist NULL, großgeschrieben oder der Gegenmodus | 96/96 |

Die sechs Assemblymarker sind Managed, ModuleId, ModuleVersion, DeploymentMode,
AssemblySha512 und ArtifactId mit Toolbelt-Präfix. Punkt1 behauptet nicht bei
jedem Marker einen anderen Basistyp: Beim bestehenden varchar-ArtifactId ist
bereits die abweichende MaxLength eine gezielte Typfacettendrift. Hashbytes
werden für die negative Typfixture als Hextext dargestellt; keine Assembly-
oder Artifactbytes werden ersetzt. DB-Registrierungsfälle sind Text-/Präsenzfälle,
kein Nachweis unveränderter Typfacetten während der negativen Fixture.

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | 52 Profile, frischer Audit PASS |
| Windows | SQL2022/CU26 | 150,160 | je52 Profile, je frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160,170 | je52 Profile, je frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 52 Profile, frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je52 Profile, je frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je52 Profile, je frischer Audit PASS |

## Tatsächlicher Aufrufpfad und Fehlerorakel

Die [Fixture](../../Tests/Release/Runtime/JsonLifecycle.ConstructorDependency.Contract.ps1)
installiert die kanonischen ResultTable-/Core-Baselines, den unveränderten bekannten
Constructor1.3 und anschließend Schema. Damit ist der Ausgangszustand vor jeder
einzelnen Drift vollständig kohärent; keine Orphan- oder Ersatzassemblyfixture.
Das Schema-Modul ist bereits installiert: Die624 negativen Aufrufe prüfen seinen
Deploywiederholungspfad, keine eigenständige Matrix bei fehlendem Schema-Modul.
Die originalen öffentlichen Schema-Deploy-Scripts müssen abweisen, ohne eine
Dependency zu installieren, zu migrieren oder zu reparieren.

Jeder Profilaufruf verlangt genau einen55633/State1/Severity16-Fehler mit
unverändertem Text: Die18 Assemblymarkerfälle liefern den Constructor-
Dependencytuplefehler, die acht DB-Registrierungsfälle die Abweisung zur zuerst
explizit erforderlichen kohärenten1.3-Migration. Der vollständige beschädigte
Snapshot bleibt erhalten. Lokale Transaktionsneutralität und unabhängige
Sitzungs-/AppLock-Orakel bestehen.

Es werden ausschließlich diese26 Deploy-Profile pro Kontext gezählt. Der
Schema-Uninstall prüft diese optionale Installationsdependency nicht; es werden
keine fiktiven gespiegelten Uninstall-Abweisungen oder52 Profile pro Einzelmodus
behauptet. Nach exakter Rückstellung entfernen die originalen Schema-, Constructor-
und Core-Uninstaller die eigenen Module in dieser Reihenfolge. Diese Teardowns
sind Cleanup und keine neue vollständige Lifecycle-/API-/Migrationsqualifikation.

## Typisierte Originale, Snapshot und Restore

Acht Originalproperties werden als unveränderte sql_variant-Werte in einer
Caller-Temp-Tabelle gehalten: sechs Assemblymarker und die beiden DB-Marker.
Gelöschte Einträge werden neu angelegt, übrige mit dem ursprünglichen Variantwert
aktualisiert. Vor jeder Rückstellung muss der beschädigte Snapshot unverändert
sein, anschließend der ursprüngliche Snapshot exakt wiederhergestellt.

Geprüft werden alle eigenen Modulobjekte im Namespace, Definitionen und CLR-
Bindings, Objekt-/Assemblyidentitäten, Owner, Berechtigungen, Principals und
Rollenmitgliedschaften, typisierte Rohproperties, Schema-Parameter-/SET-Metadaten
und ausdrücklich die Constructor-Assemblyreferenzen. Keine Rechte-, Principal-,
Owner-, Assembly-, Klassen- oder Methodenänderung wird als Fixture verwendet.
Die Constructorfunktionen werden nicht fachlich ausgeführt.

## Erweiterte Herkunftsbindung vor Trust und SQL

Der [vorhandene Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
wählt die Fixture nur für `json-lifecycle-constructor-dependency/v1`. Nur in
diesem Scope wird zusätzlich die bekannte Constructor-DLL aus demselben bereits
qualifizierten Gesamtpaket verwendet. Vor SQL-/Trustvorbereitung müssen Paket-
SHA256, Constructor-Binary-SHA256/SHA512, Registryzeile, Projekt- und sämtliche
Compilerquellen passen. Die drei Modul-Deployments Schema, Core und Constructor bleiben jeweils lokal/
zentral konkret an ihre exportierte SQL-Fassung gebunden.
Die vollständigen Constructor-Deploy-/Uninstall-Scripts werden aus ihren
Original-Includebäumen kanonisch rekonstruiert und exakt verglichen, einschließlich
aller notwendigen Sourcepins. Umpinnen eines falschen DLL-Inhalts oder eines
verkürzten Deploy-Scripts reicht nicht zur Aufnahme.

Eigene hashgebundene Trusteinträge für diese dritte bekannte DLL nutzen die
bestehende Root-Freigabe; kein neuer Trustmechanismus oder unbekannter Build.
Die unveränderten Ownership-/Verbraucher-/Fingerprintprüfungen schützen sowohl
vorher bestehende Einträge als auch die Entfernung eindeutig eigener Einträge.
Notwendige eigene CLR-Konfiguration wird wie bisher journalgeführt vorbereitet
und zurückgenommen. Strict Security bleibt erhalten; keine Serverneustarts,
zusätzlichen Rechte, Labressourcen, Zertifikats-/Truststore- oder Datei-I/O-
Änderungen. Nur schema-validierte explizite READY-Ziele, tatsächliche Engine-/
Plattform-/CL-Prüfung und unveränderter Functional-Transport. Kein daraus
abgeleiteter authentifizierter TLS-, Windows-Anmelde-, GUI- oder SQLCMD-CLI-Nachweis.

## Gegenproben und endlicher Abschluss

Methodenstand `8364e6e9` besteht zwei neue
[Gegenproben](../../Tests/Release/test_json_constructor_dependency_lab_contract.py):
gültige Aufnahme ohne Lab-/SQL-Zugriff, exakte Fixture und gemeinsame Pins,
kanonischer Constructor-Includebaum, ausdrücklich zugeordnete Abweisung bei
umgepinntem falschem Binary beziehungsweise verkürztem Deploy-Script,26 eindeutige
Deploy-Keys je Kontext, quellgebundene Fehlertexte und typisierte Restoregrenzen.
Die beiden bestehenden Dispatchgegenproben und quellgebundene Preflights bestehen
ebenfalls. Die Suite ergänzt den vorhandenen Releasevalidator; keine neuen
CI-Jobs oder Trigger. Vorhandene, nicht betroffene Produktnachweise bleiben gültig.

Ein Verantwortlicher, keine Agenten: maximal32 Ziel-/Auditaufrufe,32 DB-
Reservierungen und60Minuten ab erster nativer Aufnahme. Der gemeinsame Rahmen
ist mit **24/32 Aufrufen und24/32 DB-Reservierungen** innerhalb der Frist
geschlossen; unbenutzte Reserve bleibt geschlossen. Alle24 eigenen DBs und
36 eigenen Releasehash-Trusteinträge sind entfernt, fünf eigene CLR-
Konfigurationsänderungen zurückgenommen. Alle zwölf frischen Audits binden
exakte finale Journale, eigene Ressourcenabwesenheit, unveränderte fremde
Konfiguration/Trust und Inputpins. Eine getrennte private Auswertung rekonstruiert
alle Profilkeys ohne Lücken/Duplikate und prüft Quellenkapseln, aktuelle
Produktbindung und gemeinsame Frist. Private Originale bleiben außerhalb Git.

Andere Rechte-/Owner-/Identitäts-/Binding-/Recovery-/Ressourcenpflichten bleiben
separat. Schema bleibt **partially validated, unreleased**. Constructor und Core
sind unveränderte Setupdependencies, keine neue Gesamtqualifikation dieser Module.
Exakte Head-CI und tatsächliche Main-PUSH-CI sind Integrationsgates; keine
Veröffentlichung oder Tags.
