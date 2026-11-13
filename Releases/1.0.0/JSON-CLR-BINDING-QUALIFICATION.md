# JSON Schema: interne CLR-Parameter und Ergebnisspalten

Stand2026-11-13: **PASS_FOR_DECLARED_FIVE_POINT_MATRIX**. Die fünf ausgewählten
Binding-Restmatrizen bestehen mit1296 eindeutigen Profilen auf24 lokalen/direkt
zentralen Windows-/Linux-Kontexten. Zwölf Erstläufe und zwölf frische unabhängige
Abschlussaudits PASS, kein nativer Fehlversuch oder Retry. Keine Produkt-/
Binäränderung und keine vollständige Modulqualifikation.

## Auftrag, Abgleich und genaue Abdeckung

Der Benutzer beauftragte die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuarbeiten, gültige Nachweise wiederzuverwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Die bestehenden öffentlichen USP-Signatur-, Marker-, Registrierungs-, Caller-,
Lock- und Dependencybelege bleiben unverändert. Sie ersetzen keine tatsächlichen
Aufrufe des CLR-Binding-Guards am internen FT_ValidateJsonSchemaInternal-Slot.

| Punkt | Tatsächliche Fixture am unveränderten bekannten CLR-Slot | Öffentliche Deploy-/Uninstall-Profile bestanden/geplant |
|---|---|---|
| 1 | Alle acht Parameternamen einzeln vollständig großschreiben | 384/384 |
| 2 | Profile-Eingabelänge von nvarchar(32) auf nvarchar(31) absenken | 48/48 |
| 3 | Alle zehn Ergebnisspaltennamen einzeln vollständig großschreiben | 480/480 |
| 4 | Fünf SqlString-Ergebnislängen absenken: RowKind8→7, Status24→23, Profile32→31, Keyword128→127, ErrorCode32→31 | 240/240 |
| 5 | Drei kompatible Nachbarpaare vertauschen: Status/Profile, DocumentPointer/SchemaPointer und Keyword/ErrorCode | 144/144 |

Das sind27 Fixturevektoren, je zwei öffentliche Lifecycleoperationen und24
Kontexte. Andere Eingabelängen, Typersetzungen, inkompatible CLR-Tausche,
Nullability-, Class-/Methoden- und übrige Bindingvarianten sind nicht aus diesem
Scope abzuleiten. Insbesondere werden keine vollständige Längenmatrix beider
SqlChars-Pointer oder sämtliche neun Nachbartausche behauptet.

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | 108 Profile, frischer Audit PASS |
| Windows | SQL2022/CU26 | 150,160 | je108 Profile, je frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160,170 | je108 Profile, je frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 108 Profile, frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je108 Profile, je frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je108 Profile, je frischer Audit PASS |

## Kanonische Deklaration und herstellbare Fixtures

Die [Fixture](../../Tests/Release/Runtime/JsonLifecycle.ClrBinding.Contract.ps1)
extrahiert genau eine SQL-Stringdeklaration aus der unveränderten
[Bridgequelle](../../Modules/toolbelt.json.schema/Source/JsonSchemaBridge.sql),
dekodiert ihre SQL-Stringescapes und verlangt den exakten bekannten Funktionsslot.
Nur das DDL-Verb wird zu ALTER geändert. Die anschließenden Transformationen
betreffen ausschließlich die ausgewählten Parameter-/Spalteneinträge; AS EXTERNAL
NAME einschließlich Assembly, Klasse und Methode bleibt unverändert. Die Bindingfixture verwendet keinen Funktions-DROP/CREATE und keinen
Assembly-/Methodenaustausch.

Alle27 Vektoren wurden auf jedem Ziel tatsächlich hergestellt und anschließend
vom öffentlichen Toolbelt-Guard abgewiesen. Es handelt sich nicht um ersatzweise
Enginefehler beim Fixtureaufbau. ALTER und CLR-Tabellenfunktionen haben eigene
[Deklarationsgrenzen](https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-function-transact-sql?view=sql-server-ver17);
unter anderem unterstützen [CLR-TVFs keine NOT-NULL-Ergebnisspalten](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions?view=sql-server-ver16).
Solche nicht ausgewählten Zustände wurden nicht zur künstlichen Guardabdeckung
erzeugt. Die drei Tausche bleiben innerhalb derselben verwalteten Datentypfamilie.

## Tatsächliche Katalog-, Fehler- und Restoreorakel

Vor dem negativen öffentlichen Aufruf vergleicht ein unabhängiger Katalog-
abgleich die ursprünglichen und tatsächlichen acht Parameter sowie zehn
Ergebnisspalten mit genau der erwarteten Veränderung. Er prüft Namen, Ordinals,
System-/Aliastypen, Byte-MaxLength, Präzision, Skala, Outputflag beziehungsweise
Nullability und Collation. Ein zusätzlicher Snapshot erfasst ausdrücklich alle
Ergebnisspalten am internen CLR-Slot. Die Rückgabeordinals werden nur bei den
drei gezielten Vertauschungen entsprechend neu zugeordnet.

Jeder originale öffentliche Deploy-/Uninstall-Aufruf verlangt genau einen
55633/State1/Severity16-Fehler mit unverändertem Text zum inkohärenten
CLR-Binding-/Parameter-/Spaltenvertrag. Der beschädigte vollständige Snapshot
muss nach der Abweisung unverändert sein. Anschließend wird die ursprüngliche
kanonische CLR-Deklaration wieder angewendet und der ursprüngliche Snapshot
exakt verglichen: Objektidentität, Definitionen der übrigen Objekte, effektive
Owner, Rechte, Assembly-/Methodenbindung, Parameter, Spalten und typisierte
Properties bleiben erhalten. DDL-Änderungszeitstempel der eigenen Fixture sind
kein behaupteter Restorevertrag. Die CLR-Funktion wird nicht fachlich ausgeführt.

Lokale Transaktionsneutralität und unabhängige Sitzungs-/AppLock-Orakel bestehen.
Die bestehenden Snapshot-, Script-, Fehler- und Neutralitätsfunktionen werden
unverändert wiederverwendet und ausdrücklich gepinnt. Kein eigenes DDL-/
Trust-/Ownerreparaturverfahren wird in den Produktlifecycle eingebaut.

## Quellenbindung, Gegenproben und endlicher Abschluss

Der [bestehende Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
wählt die neue Fixture ausschließlich für `json-lifecycle-clr-binding/v1`.
Öffentliche Scripts und Baselines sind kanonisch expandiert; qualifiziertes
Paket, bekannte Release-DLLs, Registry, Projekte und Compilerquellen sind
gebunden. Nur schema-validierte explizite READY-Ziele, tatsächliche Engine-/
Plattform-/CL-Prüfung und unveränderter Functional-Transport. Verschlüsselung
bleibt erforderlich; kein authentifizierter TLS-, Windows-Anmelde-, GUI- oder
SQLCMD-CLI-Nachweis daraus. Keine Rechte-/Principal-/Owner-/Lab-/Zertifikats-/Truststoreänderungen, keine
Serverneustarts oder serverseitige Datei-I/O. Notwendige eigene CLR-Konfiguration
und hashgebundener Releasetrust nutzen die bestehenden Freigaben mit Journal und
Wiederherstellung wie unten belegt.

Methodenstand `e61779d6` besteht die zwei neuen
[Gegenproben](../../Tests/Release/test_json_clr_binding_lab_contract.py): exakte
Fixtureauswahl und gemeinsame Pins, eindeutige Deklarationsextraktion, alle27
Vektoren und CL-/Modusclosure, unverändertes Managed-Bindingziel, unabhängige
Katalog-Gegenfälle ohne Änderung beziehungsweise mit fremder Spaltenänderung
sowie abgewiesene nicht ausgewählte Vektoren. Die beiden bestehenden Dispatch-
gegenproben und der quellgebundene Preflight bestehen ebenfalls. Die neue Suite
ist im bestehenden Releasevalidator registriert; keine neuen CI-Jobs oder Trigger.

Ein Verantwortlicher, keine Agenten: maximal32 Ziel-/Auditaufrufe,32 DB-
Reservierungen und60Minuten ab erster nativer Aufnahme. Der gemeinsame Rahmen
ist mit **24/32 Aufrufen und24/32 DB-Reservierungen** innerhalb der Frist
geschlossen; unbenutzte Reserve bleibt geschlossen. Alle24 eigenen DBs und
24 eigenen Releasehash-Trusteinträge sind entfernt, fünf eigene CLR-
Konfigurationsänderungen zurückgenommen. Alle zwölf frischen Audits binden
exakte finale Journale, Ressourcenabwesenheit, unveränderte fremde Konfiguration/
Trust und Inputpins. Eine getrennte private Auswertung rekonstruiert sämtliche
Profilkeys ohne Lücken/Duplikate und prüft Quellenkapseln, aktuelle Produktbindung
und gemeinsame Frist. Private Originale bleiben außerhalb Git erhalten.

Andere Owner-/ACL-/Identitäts-/Binding-/Recovery-/Ressourcenpflichten bleiben
separat. Das Schema-Modul bleibt **partially validated, unreleased**; Core ist
unveränderte Setupdependency, kein neuer direkter Core-Nachweis. Exakte Head-CI
und tatsächliche Main-PUSH-CI sind Integrationsgates; keine Veröffentlichung
oder Tags.
