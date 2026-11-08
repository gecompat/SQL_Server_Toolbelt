# File Content: Linux-Bindung und gestoppte Repeat-Restmatrix

Stand 2026-11-08, Modul **1.0.0**, weiterhin `partially validated` und
`unreleased`. Die Windows-/zusätzliche-CL-Gesamtmatrix ist **offen**.
Der erste Restfall ist **FAILED_CLEANED**, sein frischer unabhängiger Audit
**PASS**. Die Adapterkorrektur ist **SOURCE_ONLY**, nativ nicht ausgeführt.

## Gültige vorhandene Linux-Ausführung

Der tatsächliche [Main-Push-Lauf 41110007002](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/41110007002)
am Quellstand [6cb36bdd](https://github.com/gecompat/SQL_Server_Toolbelt/commit/6cb36bdd83462380db0a65ba1cf7709852d6944b)
hat drei erfolgreiche Linux-Jobs für SQL2019/2022/2025. Vor Wiederverwendung
wurden **23 ausgewählte Dateien** mit dem aktuellen Stand verglichen: sämtliche
File-Content-SQL-Quellen und Manifest, ResultTable-Source/Deployment/Manifest,
File-Content-CI-Adapter, Transport-/Routinghelfer und Workflow. Die normalisierten
Quellbytes stimmen vollständig überein. Der aktuelle Dependency-Preflight ist
enthalten; der ältere Nachweis `8effcee9` bleibt unverändert.

Der dort tatsächlich ausgeführte befüllte Repeat verwendet SQL2019/CL150,
SQL2022/CL160 und SQL2025/CL170, jeweils lokal und zentral. Zwei echte Deploys
prüfen vier synthetische Allowlist-Zeilen, verbrauchte Identity, Folgeinsert,
Objekt-/Schema-/Index-/Constraint-/Trigger-/Permissionsmetadaten und zusätzliche
Annotationen. Nur die kanonische Tabellenbeschreibung wird gezielt erneuert.
Die anschließende bestehende Dateisuite gehört zum Umfang des CI-Adapters.
Vorhandene Permissions werden beobachtet, keine Benutzergrants angelegt.
Dies sind frühere CI-Ausführungen, keine neuen Lab-Läufe oder frischen
unabhängigen Lab-Cleanupaudits.

## Fehlgeschlagener nativer Restfall

Geplant waren neun fehlende Engine-/CL-Paare jeweils lokal/direkt zentral:
Windows2019/CU32 CL150, Windows2022/CU26 CL150/160,
Windows2025/CU8 CL150/160/170 sowie Linux2022/latest CL150 und
Linux2025/latest CL150/160. Die drei belegten Linux-Default-Fälle wurden
ausdrücklich nicht wiederholt.

Der [Adapter](../../Tests/Release/Invoke-FileContentRepeatLab.ps1) installiert
nur ResultTable 1.0.0 und File Content 1.0.0 in eigenen markierten Datenbanken.
Die erste Ausführung auf Windows SQL2019/CU32 CL150 endete nach den beiden
lokalen Originalfixtures `RepeatCurrent.Contract.sql` und `Lifecycle.Contract.sql`
am zusätzlichen Adaptervergleich `FILE_REPEAT_PRODUCT_DEFINITION_DRIFT`.
Die inneren Tabellen-/Katalogorakel kehrten vorher zurück; dies ist kein
bestandener Gesamtfall. Kein lokaler oder zentraler Abschlusszeuge entstand.

Ausgeführter Methodensnapshot:
[1cd866d9](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1cd866d9c11f5876668dd8b6fc207b231914c451).
Windows-Client, vorhandene administrative Lab-Anmeldung, explizite schema-validierte
Zielwahl und Functional-Transport mit Verschlüsselung und explizitem Trustwert.
Keine authentifizierte TLS- oder Linux-Clienthostqualifikation.

Der vorab gewählte No-Retry-Rahmen hatte höchstens 18 Ziel-/Auditaufrufe,
18 DB-Reservierungen und 45 Minuten. Verbraucht: **zwei Aufrufe, zwei
Reservierungen, eine eigene Datenbank**, null bestandene Gesamtfälle.
Die eigene DB wurde entfernt. Der reservierte frische unabhängige Windows-Audit
bestätigt den finalen Journalhash, DB-Abwesenheit, unveränderte ganze
Serverkonfiguration und Assemblytrust sowie Eingabepins. Der ursprüngliche
Lauf bleibt ausdrücklich nicht bestanden. Die Welle und alle unbenutzten
Restplätze sind geschlossen; Zähler, Fehler, Originaljournale und Quellkapseln
bleiben erhalten.

## Offline reproduzierte Rendererabweichung und Korrektur

Der kanonische Erstexport liest Include-Dateien zeilenweise und fügt ihr
Dateiende nicht zusätzlich ein. Der Repeat-Adapter las vollständige Dateitexte;
dadurch erschien ein zusätzliches LF im eingebetteten gemeinsamen Root-Prädikat.
Die verbindungslose Gegenprobe reproduziert für beide Prozeduren in beiden
Repeats jeweils genau eine zusätzliche Codeeinheit gegenüber den tatsächlichen
kanonischen Erstexport-Batches.

Die Korrektur verwendet dieselbe Zeilen-/LF-Behandlung wie der Erstexport.
Alle **vier vollständigen CREATE-OR-ALTER-Batches** stimmen nun bytegenau
überein. Der strikte Definitionenvergleich bleibt erhalten; kein Trim,
Überspringen des Vergleichs oder Ändern eines SQL-Produktobjekts.
Die Native-Ausführung speicherte keine einzelnen Vor-/Nachdefinitionszeilen;
die konkret beobachtete Driftzeile ist daher nicht separat nativ belegt.
Künftig werden private Definitionen-Hashzeilen und beendete Fixtures vor dem
abschließenden Vergleich journalisiert.

**13 Offlineprüfungen** schützen tatsächliche Admission ohne Lab/SQL,
boolesche Freigabe, Frist-/Ziel-/Modus-/Pinabweichungen, verbotene Rechte- und
Serveroperationen, SQLCMD-Arbeitsverzeichnis, LF/CRLF und Include-Ausbruch,
Zyklen sowie dynamische Includes. Die neue Gegenprobe vergleicht die vollständigen
echten Produktbatches mit dem kanonischen Erstexport bei gemocktem SQL-Executor.
Die Tests sind im zentralen Release-Testregister enthalten. Sie ersetzen keine
native Bestätigung.

Keine Produkt-SQL-, Manifest-, Rechte-, Benutzer-, CLR-, Server- oder
Lab-Infrastrukturänderung; keine Datei-I/O-Probe in dieser Restwelle.
Rohdaten und reale Umgebungswerte bleiben privat. Die [Originalmatrix](../../Modules/toolbelt.file.content/Tests/FILE_CONTENT_CONTRACT_TEST_MATRIX.md)
behält ihre anderen Grenzen. Wegen des geschlossenen No-Retry-Plans benötigt
die korrigierte native Restmatrix eine neue konkrete endliche Freigabe.
Keine Veröffentlichung oder Tags.
