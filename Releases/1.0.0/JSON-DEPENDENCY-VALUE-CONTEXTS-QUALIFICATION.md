# JSON Schema: zehn weitere Dependency-Wert- und Kontextmatrizen

Stand 2026-11-13: **PASS_FOR_DECLARED_TEN_POINT_MATRIX**. Der abgegrenzte
Nachweis umfasst 1.008 eindeutige öffentliche Schema-Deploy-Profile in 24
lokalen beziehungsweise direkt zentralen Windows-/Linux-Kontexten.
Zwölf erfolgreiche Koordinatoren und 13 frische unabhängige Abschlussaudits
stehen einem erhaltenen Transportfehllauf mit zunächst blockiertem Cleanup
gegenüber. Zwei gültige Profile dieses Fehllaufs sind wiederverwendet,
1.006 weitere Profile durch die erfolgreichen Koordinatoren ausgeführt.
Keine Produkt-/Binäränderung, vollständige Modulqualifikation oder Veröffentlichung.

## Auswahl und Abgrenzung

Der Benutzer beauftragte die nächsten zehn freigegebenen Qualifikationspunkte,
Wiederverwendung gültiger Nachweise und Tests ausschließlich echter Lücken.
Die [vorherigen Dependency-Kontexte](JSON-DEPENDENCY-CONTEXTS-QUALIFICATION.md)
belegen Constructor-Typ-/Präsenz-/NULL-Drift sowie alte/nichtkanonische
Registrierung und neue ResultTable-Fehler bei installiertem Schema.
Die [ältere Constructor-Matrix](JSON-CONSTRUCTOR-DEPENDENCY-QUALIFICATION.md)
bleibt ebenfalls in ihrem ursprünglichen Scope gültig.

Hier werden andere Constructor-Werte und weitere konkrete Formate jeweils
vor und nach der Schema-Installation geprüft. Vier bisher ausschließlich im
installierten Schema-Zustand geprüfte ResultTable-Gruppen werden erstmals bei
tatsächlich fehlendem Schema geprüft. Bestehende grüne Kontextprofile werden
nicht wiederholt. Die zehn ausgewählten Matrizen sind:

| Punkt | Dependency-Eingabe | Schema-Zustand | Profile bestanden/geplant |
|---|---|---|---|
| 1 | Sechs falsche Constructor-Assemblymarkerwerte bei unverändertem Typ und Länge | fehlt | 144/144 |
| 2 | Dieselben sechs Assemblymarker-Wertabweichungen | installiert | 144/144 |
| 3 | Sechs weitere Constructor-DB-Versionsformate | fehlt | 144/144 |
| 4 | Dieselben sechs Versionsformate | installiert | 144/144 |
| 5 | Vier weitere Constructor-DB-Moduswerte | fehlt | 96/96 |
| 6 | Dieselben vier Moduswerte | installiert | 96/96 |
| 7 | ResultTable-DB-Version vollständig gelöscht | fehlt | 24/24 |
| 8 | ResultTable-Helper-ModuleId fehlt beziehungsweise SQL NULL | fehlt | 48/48 |
| 9 | ResultTable-Helper-ModuleVersion fehlt beziehungsweise SQL NULL | fehlt | 48/48 |
| 10 | Fünf ResultTable-DB-Versionsformate | fehlt | 120/120 |

Die sechs Constructor-Marker heißen `Toolbelt.Managed`, `Toolbelt.ModuleId`,
`Toolbelt.ModuleVersion`, `Toolbelt.DeploymentMode`, `Toolbelt.AssemblySha512`
und `Toolbelt.ArtifactId`. Jeder Wert wird einzeln verändert. Die Fixture
verlangt unveränderten `BaseType`, `MaxLength` und `DATALENGTH` bei tatsächlich
anderen Rohbytes. Insbesondere wird keine Typdrift als Wertprüfung gezählt.

Die neuen Constructor-Versionseingaben sind `1.3`, `1.3.0.0`, `1.3.-1`,
`2147483648.0.0`, `01.3.0` und `1.3.0 ` mit nachgestelltem Leerzeichen.
Die vier Moduswerte sind die leere Zeichenfolge, der gültige Modus mit
nachgestelltem beziehungsweise vorangestelltem Leerzeichen und `contoso`.
Für ResultTable werden `1.0`, `1.0.0.0`, `1.0.-1`, `2147483648.0.0` und
`01.0.0` vor der Schema-Erstinstallation verwendet.

Pro Einzelkontext bestehen 26 Profile bei fehlendem Schema und 16 bei
installiertem Schema. Es handelt sich ausschließlich um öffentliche
Schema-Deploy-Abweisungen; keine fiktiven Uninstallspiegel und keine direkten
Constructor-/ResultTable-API-Nachweise.

## Physische Matrix

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL 2019/CU32 | 150 | 84 Profile, frischer Audit PASS |
| Windows | SQL 2022/CU26 | 150, 160 | je 84 Profile, je frischer Audit PASS |
| Windows | SQL 2025/CU8 | 150, 160, 170 | je 84 Profile, je frischer Audit PASS |
| Linux | SQL 2019/latest | 150 | 84 Profile, frischer Audit PASS |
| Linux | SQL 2022/latest | 150, 160 | je 84 Profile, je frischer Audit PASS |
| Linux | SQL 2025/latest | 150, 160, 170 | je 84 Profile; CL160 mit zwei übernommenen Profilen und zusätzlichem Recovery-Audit |

Nur explizit ausgewählte, schema-validierte READY-Ziele sind zugelassen;
tatsächliche Engine, Plattform und CL werden geprüft. Der unveränderte
Functional-Transport belegt keine authentifizierte TLS-/Windows-/GUI-Anmeldung.

## Methode und Orakel

Die [neue Fixture](../../Tests/Release/Runtime/JsonLifecycle.DependencyValueContexts.Contract.ps1)
verwendet die kanonischen aktuellen Deploy-/Uninstall-Exporte und bekannten
qualifizierten Core-, Constructor- und Schema-Binaries. Der
[bestehende Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
wählt sie ausschließlich für `json-lifecycle-dependency-value-contexts/v1`.
Provenienz, Registry, Projekt-/Compilerquellen, Original-Includebäume und
SHA256-/SHA512-Bindungen aller drei Binaries werden vor SQL-Zugriff geprüft.

Schemaassembly, beide Schema-SQL-Slots und beide DB-Marker müssen vor und
nach den ersten 26 Profilen zusammen exakt die Präsenzzahl 0 ergeben.
Anschließend erfolgt der kanonische Schema-Deploy als Voraussetzung; vor und
nach den weiteren 16 Profilen muss dieselbe Prüfung exakt 5 ergeben.
Falsche oder teilweise Installationszustände werden abgewiesen.

Die Constructor-Wertfälle verlangen genau Fehler 55633, State 1, Severity 16
mit dem unveränderten Constructor-Dependencytupletext. Die Version-/Modusfälle
verlangen denselben Fehlercode mit dem Text zur zuvor erforderlichen
kohärenten expliziten 1.3-Migration. Alle ResultTable-Fälle verlangen genau
55632/State 1/Severity 16 mit dem unveränderten Dependencytext für die
registrierte ResultTable-Version ab 1.0.0. Ein anderer SQL-Fehler ist kein PASS.

Originalwerte bleiben als `sql_variant` in Caller-Temp-Tabellen erhalten.
Vor Restore muss der beschädigte Snapshot unverändert sein, nach Restore
der ursprüngliche Gesamtsnapshot exakt passen. Dieser umfasst Moduldefinitionen,
CLR-Bindings, Objekt-/Assemblyidentitäten, Owner, Principals, Rechte,
Rollenmitgliedschaften, typisierte Rohproperties und Constructor-/Core-Referenzen.
Unabhängige Sitzungs-/AppLock-Orakel prüfen Transaktionsneutralität.

Die ResultTable-Mutations-/Restorelogik der
[vorherigen Fixture](../../Tests/Release/Runtime/JsonLifecycle.DependencyContexts.Contract.ps1)
wurde als gemeinsame Funktion mit ausgewählten Specs und optionalem Receiptpräfix
extrahiert. Ein deterministischer Textvergleich bestätigte die identische
SQL-/Fehler-/Restorelogik; einzig Auswahl und Receiptpräfix sind parametrisiert.
Der bisherige Aufrufer verwendet unveränderte Defaults. Seine alten grünen
nativen Profile werden nicht erneut ausgeführt.

## Erhaltener Transportfehler und gebundene Fortsetzung

Die ersten zehn Engine-/CL-Paare waren vollständig abgeschlossen und frisch
auditiert. Auf Linux SQL 2025, CL160, brach beim dritten lokalen Profil die
Verbindung ab; die Rückverbindung zur Bereinigung wurde verweigert.
Der Originalkoordinator bleibt unverändert `CLEANUP_BLOCKED`; auch sein
fehlgeschlagener ursprünglicher Auditversuch bleibt erhalten. Die technische
Ursache des vorübergehenden Erreichbarkeitsverlusts ist damit nicht abschließend
diagnostiziert. Es gab keine Reparatur oder Änderung der Lab-Infrastruktur.

Ein gesonderter Sicherheitslauf konnte dasselbe ausgewählte Ziel wieder
erreichen. Er prüfte tatsächliche Ziel- und eigene Datenbankidentität,
entfernte ausschließlich die eigene Datenbank und eigene unveränderte
Trusteinträge und stellte den ursprünglichen Serverzustand fest.
Sein separates Recovery-Journal bindet den Hash des Originaljournals,
behält dessen Fehler und beide Profilreceipts und endet `FAILED_CLEANED`.
Ein frischer unabhängiger Audit bindet dieses finale Recovery-Journal:
Cleanup PASS, `originalRunPassed=false`. Daraus wird kein Gesamt-PASS des
ursprünglichen Fehllaufs abgeleitet.

Der geänderte Restadapter übernimmt genau die beiden bereits bestandenen
lokalen `Toolbelt.Managed`-/`Toolbelt.ModuleId`-Wertprofile. Dafür sind
Originaljournal, Recovery-Journal, frischer Audit und ursprünglicher Runset
hashgebunden; Produkt-/Orakelquellen, Labvertrag und tatsächlicher Kontext
müssen unverändert sein. Der Quellkapselvergleich erlaubt in der Mutationsfunktion
nur das Überspringen dieser belegten Keys. Wertvektoren, Parameter und
SQL-/Fehler-/Restorelogik bleiben gleich. Falsche, umsortierte, unvollständige
oder nicht bestandene Receipts werden zurückgewiesen.

Der korrigierte CL160-Koordinator führt die übrigen 82 Profile aus; CL170
führt seine erstmals geprüften 84 Profile aus. Beide Koordinatoren und
ihre frischen Audits bestehen. Die zehn zuvor grünen Kontextpaare und die
zwei übernommenen Einzelprofile werden nicht wiederholt.

## Validierung, Grenzen und Abschluss

Methodenstände `4b3d1353` und `055a5261`: drei neue
[Offlinegegenproben](../../Tests/Release/test_json_dependency_value_contexts_lab_contract.py),
vier betroffene bestehende Gegenproben und die quellgebundenen Preflights
einschließlich tatsächlicher Reuse-Zuordnung bestehen. Die neue Suite ergänzt
den vorhandenen Releasevalidator, ohne zusätzliche CI-Jobs oder Trigger.
Vollständige Head-CI und tatsächliche Main-PUSH-CI bleiben Integrationsgates.

Der ursprüngliche gemeinsame Rahmen von 32 Ziel-/Auditaufrufen,
32 DB-Reservierungen und 60 Minuten bleibt über Fehler, Recovery und
Fortsetzung erhalten. Er ist mit **28/32 Aufrufen und 26/32 DB-Reservierungen**
innerhalb dieser Frist geschlossen. Die unbenutzte Reserve bleibt geschlossen.
Alle 25 tatsächlich angelegten eigenen Datenbanken und 39 eigenen Trusteinträge
sind entfernt; fünf eigene Konfigurationsänderungen sind zurückgenommen.
Keine zusätzlichen Rechte, Principals, Owner, unbekannten Binaries,
Serverneustarts, Labressourcen oder Zertifikats-/Truststoreänderungen.

Eine getrennte private Auswertung rekonstruiert alle 1.008 Profilkeys ohne
Lücke oder Duplikat, prüft Original-/Recovery-/Auditbindungen, Quellenkapseln,
aktuelle Produktpins und die gemeinsame Frist. Alle privaten Originale bleiben
außerhalb Git erhalten. Andere Rechte-, Identitäts-, Binding-, Recovery- und
Ressourcenpflichten bleiben separat. Schema bleibt **partially validated,
unreleased**; keine Veröffentlichung oder Tags.
