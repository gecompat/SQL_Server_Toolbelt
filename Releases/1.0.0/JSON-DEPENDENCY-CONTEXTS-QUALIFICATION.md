# JSON Schema: zehn weitere Dependency-Zustände

Stand2026-11-13: **PASS_FOR_DECLARED_TEN_POINT_MATRIX**. Alle zehn ausgewählten
Restmatrizen bestehen mit960 eindeutigen öffentlichen Schema-Deploy-Profilen auf24
lokalen/direkt zentralen Windows-/Linux-Kontexten. Zwölf Erstläufe und zwölf
frische unabhängige Abschlussaudits PASS, kein nativer Fehlversuch oder Retry.
Keine Produkt-/Binäränderung und keine vollständige Modulqualifikation.

## Auftrag und echte Lücken

Der Benutzer beauftragte ausdrücklich die nächsten zehn bereits freigegebenen
Qualifikationspunkte autonom abzuarbeiten, gültige Nachweise wiederzuverwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Die bestehende [Constructor-Dependencymatrix](JSON-CONSTRUCTOR-DEPENDENCY-QUALIFICATION.md)
belegt den Deploywiederholungspfad bei installiertem Schema. Ihre624 gültigen
Profile bleiben unverändert; sie werden hier nicht wiederholt. Die ersten fünf
neuen Matrizen prüfen dieselben Dependencybedingungen vor der Erstinstallation,
wenn Schemaassembly, beide Schema-SQL-Slots und beide DB-Registrierungen fehlen.

Die bisherigen ResultTable-Tests prüften zu alte/nichtkanonische/NULL-DB-Version
und falsche objektbezogene Modul-/Versionswerte. Die folgenden fünf neuen
Matrizen betreffen andere konkrete Eingaben: vollständige Abwesenheit, NULL an
Objektmarkern, andere Formatgrenzen und bytegenaue Objektregistrierungstexte.
Kein alter grüner Profilaufruf wurde wiederholt.

| Punkt | Tatsächlicher Zustand vor öffentlichem Schema-Deploy | Profile bestanden/geplant |
|---|---|---|
| 1 | Schema fehlt; jeder der sechs Constructor-Assemblymarker mit abweichenden Typ-/Längenfacetten | 144/144 |
| 2 | Schema fehlt; jeder der sechs Constructor-Assemblymarker vollständig gelöscht | 144/144 |
| 3 | Schema fehlt; jeder der sechs Constructor-Assemblymarker SQL NULL | 144/144 |
| 4 | Schema fehlt; Constructor-DB-Version fehlt/NULL/alt1.2.0/nichtkanonisch1.3.00 | 96/96 |
| 5 | Schema fehlt; Constructor-DB-Modus fehlt/NULL/großgeschrieben/Gegenmodus | 96/96 |
| 6 | Schema installiert; ResultTable-DB-Versionsproperty vollständig gelöscht | 24/24 |
| 7 | Schema installiert; ResultTable-Helper-ModuleId fehlt beziehungsweise NULL | 48/48 |
| 8 | Schema installiert; ResultTable-Helper-ModuleVersion fehlt beziehungsweise NULL | 48/48 |
| 9 | Schema installiert; ResultTable-DB-Version1.0,1.0.0.0,1.0.-1,2147483648.0.0 beziehungsweise01.0.0 | 120/120 |
| 10 | Schema installiert; Helper-ModuleId großgeschrieben/mit Leerraum sowie Helper-ModuleVersion mit Leerraum/führender Null | 96/96 |

26 Profile im fehlenden Elternzustand und14 im installierten Zustand ergeben
40 Profile pro Einzelkontext. Die optionale Constructor-/ResultTable-
Installationsdependency wird vom Schema-Uninstall nicht entsprechend geprüft;
es werden keine fiktiven gespiegelten Uninstall-Abweisungen gezählt.

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | 80 Profile, frischer Audit PASS |
| Windows | SQL2022/CU26 | 150,160 | je80 Profile, je frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160,170 | je80 Profile, je frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 80 Profile, frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je80 Profile, je frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je80 Profile, je frischer Audit PASS |

## Tatsächlicher Elternzustand und gemeinsame Methode

Die [Fixture](../../Tests/Release/Runtime/JsonLifecycle.DependencyContexts.Contract.ps1)
installiert die kanonischen ResultTable-/Core-Baselines und den unveränderten
bekannten Constructor1.3. Vor und nach den ersten26 negativen Aufrufen muss
die Summe der Schemaassembly, beiden Schemaobjekte und beiden DB-Markern exakt0
sein. Der Namespace darf wegen Constructor bereits bestehen. Erst danach folgt
der kanonische gültige Schema-Deploy. Vor und nach den14 ResultTable-Fällen muss
derselbe Präsenzvergleich exakt5 liefern. Eine Teilinstallation oder ein anderer
Elternzustand führt zum Abbruch, nicht zu einer Umdeutung der Profilmenge.

Die bereits geprüfte Constructor-Mutations-/Restorelogik wurde in eine gemeinsame
Funktion der [vorhandenen Fixture](../../Tests/Release/Runtime/JsonLifecycle.ConstructorDependency.Contract.ps1)
gehoben. Ein deterministischer Textvergleich zum unveränderten Ausgangsstand
bestätigte die identische SQL-/Orakellogik; einzig die Receipt-ID kann ein
Präfix erhalten. Der bisherige Wiederholungsaufrufer verwendet den leeren
Default. Die aktuelle Erstinstallationsprüfung verwendet absent-. Das ist keine
erneute Ausführung oder Aufwertung der alten Wiederholungsprofile.

## Fehler-, Snapshot- und Restoreorakel

Die ersten18 Constructor-Assemblymarkerfälle verlangen genau den55633/State1/
Severity16-Dependencytuplefehler. Die acht Constructor-DB-Registrierungsfälle
verlangen die gleich nummerierte Abweisung zur zuerst explizit erforderlichen
kohärenten1.3-Migration. Die14 ResultTable-Fälle verlangen genau55632/State1/
Severity16 zur fehlenden registrierten ResultTable-Dependency>=1.0.0.
Alle Fehlertexte bleiben unverändert; es muss jeweils genau ein passender
öffentlicher Fehler vorliegen.

Vor jeder Fixture werden ursprüngliche sql_variant-Werte in Caller-Temp-Tabellen
aufbewahrt. Für ResultTable sind das genau die DB-Version sowie ModuleId und
ModuleVersion von USP_PrepareResultTable. Nur diese konkret ausgewählten
Properties dürfen verändert werden. Gelöschte Einträge werden neu angelegt,
übrige mit ursprünglichem Wert und Typ aktualisiert. Vor der Rückstellung muss
der beschädigte Snapshot unverändert sein; anschließend der vollständige
ursprüngliche Snapshot wieder exakt passen. Text-/Präsenzfälle behaupten keine
unveränderte Typfacette während der negativen Mutation.

Snapshots erfassen eigene Modulobjekte, Definitionen, CLR-Bindings, Objekt-/
Assemblyidentitäten, Owner, Rechte, Principals, Rollenmitgliedschaften, typisierte
Rohproperties, Schema-Parameter-/SET-Metadaten und Constructor-/Core-Referenzen.
Lokale Transaktionsneutralität und unabhängige Sitzungs-/AppLock-Orakel bestehen.
Es werden keine Constructor- oder Schemafunktionen fachlich ausgeführt. Nach
Restore folgen die originalen Schema-, Constructor- und Core-Uninstaller als
Cleanup, kein neuer vollständiger API-/Migrations-/Uninstallnachweis.

## Herkunftsbindung und Gegenproben

Der [vorhandene Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
wählt die neue Fixture nur für json-lifecycle-dependency-contexts/v1. Die
quell-/paket-/SHA256-/SHA512-/Registry-/Projekt-/Compilerbindung der bekannten
dritten Constructor-DLL sowie ihre kanonischen Original-Includebäume und
Ownership-/Fingerprint-geprüfte Trustvorbereitung werden aus dem vorherigen
Scope übernommen. Der neue gemeinsame Fixturepfad ist zusätzlich gepinnt.
Keine unbekannten Binaries, neuen Rechte, Principals, Owner, Serverneustarts,
Labressourcen, Zertifikats-/Truststore- oder Datei-I/O-Änderungen. Notwendige
eigene CLR-Konfiguration und hashgebundener Releasetrust nutzen bestehende
Root-Freigaben mit Journal und Restore.

Nur schema-validierte explizite READY-Ziele, tatsächliche Engine-/Plattform-/CL-
Prüfung und unveränderter Functional-Transport. Kein daraus abgeleiteter
authentifizierter TLS-, Windows-Anmelde-, GUI- oder SQLCMD-CLI-Nachweis.

Methodenstand c91ceb49 besteht zwei neue
[Gegenproben](../../Tests/Release/test_json_dependency_contexts_lab_contract.py):
exakte Fixture-/Pin-/Binary-/Canonical-Scriptauswahl, zehn Gruppen mit40 eindeutigen
Deploy-Keys,14 geschlossene ResultTable-Vektoren, abgewiesene nicht ausgewählte
Properties, tatsächliche Elternzustände0/5 und Ablehnung falscher/teilweiser
Elternzustände sowie typed Restoregrenzen. Die beiden bisherigen Constructor-
Dispatchgegenproben und quellgebundene Preflights bestehen ebenfalls. Die Suite
ergänzt den vorhandenen Releasevalidator; keine neuen CI-Jobs oder Trigger.

Ein geerbtes reines Scope-Label in Runner und Auswertung nannte noch FIVE statt
TEN. Nach nativem Abschluss wurden ausschließlich diese Metadaten präzisiert;
SQL-, Snapshot-, Fehler-, Restore- und Abdeckungsorakel blieben unverändert.
Originaljournale samt Label und ursprüngliche Quellenkapseln bleiben erhalten.
Die vollständige Key-/Gruppenauswertung belegt zehn Matrizen; aus dem alten
Label wird keine andere Abdeckung abgeleitet. Keine SQL-Wiederholung hierfür.

## Gemeinsamer endlicher Abschluss

Der Benutzer verlangte ausdrücklich zehn Punkte; sie bilden ein zusammenhängendes
Dependencypaket mit einem Verantwortlichen, ohne Agenten. Gemeinsame Grenze:
32 Ziel-/Auditaufrufe,32 DB-Reservierungen,60Minuten ab erster nativer Aufnahme.
Der ursprüngliche Rahmen ist mit **24/32 Aufrufen und24/32 DB-Reservierungen**
innerhalb der Frist geschlossen; unbenutzte Reserve bleibt geschlossen.
Alle24 eigenen DBs und36 eigenen Releasehash-Trusteinträge sind entfernt, fünf
eigene CLR-Konfigurationsänderungen zurückgenommen. Alle zwölf frischen Audits
binden exakte finale Journale, Ressourcenabwesenheit, unveränderte fremde
Konfiguration/Trust und Inputpins. Eine getrennte private Auswertung rekonstruiert
alle960 Profilkeys ohne Lücken/Duplikate und prüft Quellenkapseln, aktuelle
Produktbindung und gemeinsame Frist. Private Originale bleiben außerhalb Git.

Andere Rechte-/Owner-/Identitäts-/Binding-/Recovery-/Ressourcenpflichten bleiben
separat. Schema bleibt **partially validated, unreleased**; kein neuer direkter
Constructor-/Core-Gesamtnachweis. Exakte Head-CI und tatsächliche Main-PUSH-CI
sind Integrationsgates; keine Veröffentlichung oder Tags.
