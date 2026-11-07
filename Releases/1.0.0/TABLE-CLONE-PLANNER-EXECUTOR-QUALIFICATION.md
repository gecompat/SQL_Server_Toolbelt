# Aktueller Table-Clone-Planner und Executor: gezielte Zielmatrix

Am 2026-11-07 bestand der unveränderte Vertrag **4.1.1** vier aktuelle
kanonische Fixtures auf zwölf Engine-/CL-Paaren jeweils lokal und direkt
zentral: **24 Kontexte, 96 Fixture-Ausführungen und zwölf frische Audits**.
Alle 24 eigenen Datenbanken sind entfernt.
Ergebnis: **PASS_FOR_DECLARED_CURRENT_PLANNER_EXECUTOR_SCOPE**.

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Clienthost Windows; vorhandene administrative Lab-Anmeldung. Direkt zentral
bezeichnet SameDB-Nutzung, keine neue Netzwerk- oder CrossDB-Identität.

## Ausgeführte Originalorakel

Der [enge Testtreiber](../../Tests/Release/Invoke-TableClonePlannerLab.ps1)
führt pro Kontext diese unveränderten Originale vollständig und in dieser
Reihenfolge auf derselben eigenen Verbindung aus:

1. [TableClone.Contract.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/TableClone.Contract.sql):
   grundlegende Planner-Ergebnisse und synthetische DDL-/Namenskollisionen.
2. [Execute.Contract.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Execute.Contract.sql):
   eigenständige Hashreferenz, Executor und seine synthetischen Sicherheitsorakel.
3. [Execute.Safety.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Execute.Safety.sql):
   Abweisungen sowie erhaltene Caller-Transaktions-/SET-Zustände gemäß Fixture.
4. [Lifecycle.Contract.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Lifecycle.Contract.sql):
   aktuelle vier Releaseobjekte, registrierte Definitionen, Parameter und Hilfe.

Ein Fixture-Abbruch verhindert den Abschluss des jeweiligen Kontexts. Nach
jeder Fixture verlangt der Adapter `@@TRANCOUNT=0` und `XACT_STATE()=0`.
Vor und nach dem gesamten Kontext werden die Produktdefinitionen exakt
verglichen. Der Abschlusszeuge hält die vier tatsächlich beendeten Dateinamen,
das verifizierte Compatibility Level und beide Erhaltungsprüfungen fest.
96 ist die Zahl vollständiger Fixture-Ausführungen, keine erfundene Zahl
einzelner Assertions.

Ausgeführter Methodensnapshot:
[`58f563c6`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/58f563c6f0b13719574c4972d5d000a616c541a6).
Der schema-validierte Functional-Labvertrag wählt jedes konkrete Ziel eindeutig
aus; tatsächliche Major-/Plattform-/Softwareversion und vorhandener Sysadmin
werden privat erfasst. Der frische Audit bindet die Softwareversion erneut.

Beide kanonischen Exporte enthalten ausschließlich ResultTable 1.0.0 und
Table Clone 4.1.1. Der Treiber prüft diese Closure vor SQL und danach die
tatsächlich installierten Version-/Modusmarker. Das tatsächliche CL wird vor
Installation gelesen; es gibt keine Benutzerassembly in den Testdatenbanken.
Die Quellen verwenden den triggerfreien Pfad ohne optionalen Parser.

## Endlicher Rahmen und Originalnachweise

Vor Zulassung galten insgesamt maximal 28 Ziel-/Auditaufrufe, 28 eigene
DB-Reservierungen und 45 Minuten ab erstem Aufruf. Darin waren zwölf Läufe
mit jeweils reserviertem frischem Audit und höchstens zwei gezielt korrigierte
Fallpaare nach geänderten Adaptereingaben vorgesehen. Unveränderte oder grüne
Tests durften nicht wiederholt werden; Produkt-/gemeinsame Helferänderungen,
unklare Bereinigung oder Drift schließen die Korrektur aus.

Tatsächlich wurden **24 Aufrufe und 24 Datenbanken** benötigt. Alle zwölf
Gesamtfälle bestanden beim ersten Versuch innerhalb der ursprünglichen Frist.
Keine native Korrektur oder fehlgeschlagene native Ausführung; die Welle und
ihre ungenutzten Restplätze sind geschlossen.

Jeder Producer/Audit verwendet den vorhandenen Owned-Process-Helfer mit
400 Sekunden, getrennten 4-MiB-Kanälen und eigener Prozessbereinigung. Vor
dem nächsten Fall bleiben mindestens 15 Minuten für das reservierte Paar.
Innere SQL-/Cleanupfristen bleiben erhalten; keine allgemeine harte
Host-/Server-Abbruchgarantie wird daraus abgeleitet.

Eigene volle Datenbankidentität, Erstellungszeit und Owner-Marker begrenzen
die Löschung. Die zwölf separaten Auditprozesse bestätigen DB-Abwesenheit,
vollständige unveränderte Konfigurations-/Trustsnapshots, Zielbindung, Pins
und den exakten finalen Originaljournalhash. Ein privater Nachprüfer hat
sämtliche Fälle, Zeugen, Originalaudits und Eingabebindungen geprüft.
Private hashadressierte Quellkapseln erhalten die tatsächlich benutzten
Adapter-/Controllerbytes unabhängig von späteren Änderungen.

Keine neuen Rechte, Benutzer, CLR-/Trusteinträge, Serveroptionen oder
Labressourcen. Eigene temporäre Datenbanken bilden den gesamten Änderungsscope.
Rohlogs, Endpoints, Identitäten und reale Laufzeitwerte bleiben außerhalb Git.

## Verbindungslose Prüfungen und abgegrenzte Restpunkte

Zehn [Gegenproben](../../Tests/Release/test_table_clone_planner_contract.py)
prüfen tatsächliche Admission ohne Labimport/SQL, boolesche Freigabe,
Frist-/Ziel-/Modusabweichungen, kanonische Fixtures/Pins, Exportdrift sowie
die Scope-Sperre gegen Rechte-, Principal-, Server-, CLR- und Trigger-Opt-in-
Operationen. Eine zunächst zu breite Textgegenprobe verwechselte die
`sp_configure`-Erwähnung in der Sperrliste mit einer Ausführung; sie wurde
gezielt korrigiert. Der ursprüngliche Offlinefehler bleibt privat erhalten.
Die vier echten SQL-Fixtures bestehen zusätzlich ScriptDom Parser150.

Frühere V1-/W1-/W2-/Executor-/Triggerberichte bleiben unverändert und an ihre
jeweiligen Artefakte gebunden. Der separate
[Copy-Zielnachweis](TABLE-CLONE-COPY-TARGET-QUALIFICATION.md) wird wiederverwendet
und nicht wiederholt. Dieser Bericht qualifiziert ausschließlich die vier
genannten aktuellen Fixtures über die ausgewählte Zielmatrix.

Weitere W1-/W2-/Quotenprofile, Trigger mit Parser, echte Minimalrechte,
Netzwerk-/CrossDB-Identitäten, zusätzliche Clienthosts, genuine Upgrades,
Uninstall und umfassende Lifecycle-/Ressourcen-/Recovery-/Modulabnahme bleiben
separate Nachweise. Functional-Verschlüsselung mit explizitem Labtrust ist
keine authentifizierte TLS-Abnahme. Produkt-SQL, Manifest, Paket und der
teilweise validierte, unveröffentlichte Modulstatus bleiben unverändert.
Keine Veröffentlichung oder Tags.
