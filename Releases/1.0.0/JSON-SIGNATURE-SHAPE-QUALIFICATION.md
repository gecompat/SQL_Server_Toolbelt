# JSON Schema: OUTPUT, Aliastypen, Arity und Ordinals

Stand2026-11-13: **PASS_FOR_DECLARED_FIVE_POINT_MATRIX**. Alle fünf ausgewählten
Restmatrizen sind mit2304 eindeutigen Profilen auf24 lokalen/direkt zentralen
Windows-/Linux-Kontexten belegt:24 gültige Originalprofile unverändert übernommen,
2280 weitere erstmals ausgeführt. Zwölf korrigierte Koordinatoren und alle13
frischen unabhängigen Abschlussaudits PASS. Der erste Koordinator bleibt
FAILED_CLEANED. Keine Produktänderung oder Modulgesamtqualifikation.

## Auftrag, Abgleich und fünf Punkte

Der Benutzer beauftragte die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuschließen, gültige Nachweise wiederzuverwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Die bestehenden Typ-/Längen-/Namens-, Marker-, Registrierungs-, Caller-, Lock-
und Dependencynachweise bleiben unverändert; diese Profile werden nicht wiederholt.

| Punkt | Tatsächlicher negativer öffentlicher Deploy-/Uninstall-Aufruf | Profile bestanden/geplant |
|---|---|---|
| 1 | Jeden der zwölf ursprünglichen Parameter einzeln als OUTPUT deklarieren | 576/576 |
| 2 | Jeden Parameter einzeln über einen eigenen echten Alias bei gleichem Systemtyp, Länge, Präzision und Skala deklarieren | 576/576 |
| 3 | Jeden Parameter einzeln vollständig entfernen; gleichnamige lokale Variable mit ursprünglichem Typ/Default hält den Fixturebody kompilierbar | 576/576 |
| 4 | Jedes der elf benachbarten Parameterpaare vertauschen; Namen und zugehörige Typen/Defaults bleiben erhalten | 528/528 |
| 5 | Einen dreizehnten eigenen Parameter ContosoExtra int hinzufügen | 48/48 |

Das sind48 tatsächliche Fixturevektoren mit jeweils zwei öffentlichen
Lifecycleoperationen pro Kontext. Keiner der Fixturebodys wird fachlich
ausgeführt; die ursprünglichen öffentlichen Lifecycle-Einstiege müssen die
abweichende installierte Signatur vor ihrer eigenen Mutation abweisen.

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | 192 zusammengesetzte Profile:24 Originalprofile plus168 neue; beide Audits PASS |
| Windows | SQL2022/CU26 | 150,160 | je192 Profile und frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160,170 | je192 Profile und frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 192 Profile und frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je192 Profile und frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je192 Profile und frischer Audit PASS |

## Reale Katalog-, Fehler- und Restoreorakel

Die [Fixture](../../Tests/Release/Runtime/JsonLifecycle.SignatureShape.Contract.ps1)
verwendet die vorhandenen qualifizierten Snapshot-/Header-/Katalognormalisierungs-
funktionen. Ein zweiter kanonischer Setup-Deploy stabilisiert vor dem Snapshot
den bestehenden DDL-Zweig; kein neuer Repeat-Qualifikationsfall. Danach wird
die ursprüngliche Definition gespeichert und nach jedem einzelnen Vektor exakt
wiederhergestellt. Die Original-ObjectId, Ownership, Rechte, Assemblies,
typisierten Rohproperties und relevanten SET-Metadaten bleiben erhalten.
DDL-Änderungszeitstempel der eigenen Fixture sind kein behaupteter Restorevertrag.

Ein unabhängiger Vergleich der tatsächlichen sys.parameters-Zeilen verlangt
genau die geplante Veränderung. Verglichen werden parameter_id, name,
system_type_id, user_type_id, max_length, precision, scale und is_output.
OUTPUT verändert ein Flag; Alias verändert eine Typidentität; Reihenfolgetests
verschieben genau ein Nachbarpaar. Fehlende/zusätzliche Parameter müssen die
Arity auf11 beziehungsweise13 ändern; verbleibende Ordinals werden entsprechend
erwartet. Die ursprünglichen Typen bleiben jeweils dem ursprünglichen Namen
zugeordnet. Die lokale Deklaration im Missing-Fall ist die einzige zusätzliche
Bodyzeile; die anderen vier Gruppen verändern ausschließlich den Header.

Jeder öffentliche Aufruf verlangt genau einen55633/State1/Severity16-Fehler
mit unverändertem Text zur inkohärenten öffentlichen Parametersignatur.
Der vollständige beschädigte Snapshot bleibt nach Abweisung erhalten.
Lokale Transaktionsneutralität und unabhängige Sitzungs-/AppLock-Orakel bestehen.

## Eigene Alias-Fixtures und vorhandene Rechte

Die288 eigenen Alias-Fixtures entstehen ausschließlich in den eigenen temporären
Testdatenbanken über [CREATE TYPE](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-type-transact-sql?view=sql-server-ver17).
Die bekannten Basistypen umfassen auch nvarchar(max); sysname wird für den
eigenen Alias auf seinen Systemtyp nvarchar(128) abgebildet. Keine sp_addtype-
Aufrufe, GRANT-/DENY-/REVOKE-Anweisungen oder Principal-/Owneränderungen.
Es werden nur bestehende administrative Labrechte verwendet, kein neuer
Minimalrechtenachweis behauptet.

Vor Erstellung muss der deterministische eigene Typname frei sein. Die Fixture
speichert Typidentität und vollständige Typmetadaten im Snapshot. Nach
Definitionrestore muss dieser Snapshot unverändert sein, TYPE_ID dem eigenen
Wert entsprechen und sys.parameter_type_usages darf keine Referenz mehr
enthalten. Erst dann wird der eigene Typ entfernt; anschließend muss der
ursprüngliche typfreie Baseline-Snapshot wieder exakt passen. Alle288 Alias-
Fixtures wurden so entfernt, bevor ihre eigenen Datenbanken abgebaut wurden.

## Erhaltener Adapterfehler und ausschließlich offener Rest

Methodenstand `df517551` bestand24 lokale OUTPUT-Profile und scheiterte vor der
ersten Alias-Fixture: Die vorhandene skalare Hilfsfunktion akzeptiert keine
Parameterdictionary als drittes Argument. Deshalb fehlte @Name im SQL-Batch.
Der Koordinator bleibt FAILED_CLEANED; sein frischer Abschlussaudit ist PASS.

Die Korrektur `3fa1c7bb` führt das Dictionary über eine eigene kleine
Read-ShapeScalar-Funktion ausdrücklich an den bestehenden SQL-Executor weiter.
Der ursprüngliche Helper bleibt unverändert. Genau24 vollständige lokale
OUTPUT-Profile werden über Originaljournal, frischen Audit, SHA256, ursprünglichen
Runset, Produkt-/Lab-/Zielbindung, Quellenkapsel und unveränderte Transformations-/
Katalog-/Snapshotorakel übernommen. Der ursprüngliche Fehler wird nicht zum
Gesamt-PASS aufgewertet.

Der korrigierte lokale Fall prüft nur die72 verbleibenden Profile, anschließend
den bislang ungeprüften zentralen Kontext mit96 Profilen. Elf weitere Zielpaare
wurden erstmals vollständig ausgeführt. Der Modus-/Gesamtabgleich schließt
die24 übernommenen Keys aus der neuen Ausführung aus. Keine grüne Wiederholung
und keine Erneuerung des ursprünglichen Zeit- oder Aufrufrahmens.

## Quellenbindung und endlicher Abschluss

Der [vorhandene Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
wählt die neue Fixture nur für `json-lifecycle-signature-shape/v1` und verlangt
ihre gemeinsamen Methodenpins. Vollständige öffentliche Scripts und Baselines
sind kanonisch expandiert; Paket, bekannte Release-DLLs, Registry, Projekte
und Compilerquellen sind gebunden. Nur schema-validierte explizite READY-Ziele,
tatsächliche Engine-/Plattform-/CL-Prüfung und unveränderter Functional-Transport.
Verschlüsselung bleibt erforderlich; kein authentifizierter TLS-, Windows-
Anmelde-, GUI- oder SQLCMD-CLI-Nachweis daraus. Keine neuen Binaries, Server-/
Lab-/Truststore-/Zertifikatsänderungen oder serverseitige Datei-I/O.

Zwei neue [Gegenproben](../../Tests/Release/test_json_signature_shape_lab_contract.py)
prüfen Fixtureauswahl/Pins, alle48 Headervektoren, Bodygrenzen, unabhängige
Katalog-Gegenfälle, echte Dictionaryweitergabe und fehlende/doppelte/fehlgeschlagene
Präfixprofile. Die zusätzliche reine Body-Gegenprobe entstand nach nativem
Abschluss; SQL-/Restoreorakel blieben unverändert, keine SQL-Wiederholung dafür.
Die beiden bestehenden Dispatchgegenproben und kanonische Preflights bestehen.
Die Suite ergänzt den vorhandenen Releasevalidator, keinen neuen CI-Job.

Ein Verantwortlicher, keine Agenten: maximal32 Ziel-/Auditaufrufe,32 DB-
Reservierungen und60Minuten ab erster nativer Aufnahme. Derselbe ursprüngliche
Rahmen ist mit **26/32 Aufrufen und26/32 DB-Reservierungen** innerhalb der Frist
geschlossen; unbenutzte Reserve bleibt geschlossen. Alle25 tatsächlich angelegten
eigenen DBs und26 eigenen Releasehash-Trusteinträge sind entfernt, sechs eigene
CLR-Konfigurationsänderungen zurückgenommen. Alle13 frischen Audits binden das
jeweilige exakte finale Journal, Ressourcenabwesenheit, unveränderte fremde
Konfiguration/Trust und Inputpins. Eine getrennte private Auswertung rekonstruiert
die gesamte Keyvereinigung ohne Lücken oder Duplikate und prüft Quellenkapseln,
aktuelle Produktbindung und gemeinsame Frist.

Private Originale bleiben außerhalb Git erhalten. Andere Owner-/ACL-/Identitäts-/
Binding-/Recovery-/Ressourcenpflichten bleiben separat; das Schema-Modul bleibt
**partially validated, unreleased**. Core ist unveränderte Setupdependency,
kein neuer direkter Core-Modulnachweis. Exakte Head-CI und tatsächliche Main-
PUSH-CI sind Integrationsgates; keine Veröffentlichung oder Tags.
