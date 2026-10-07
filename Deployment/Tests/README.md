# Deploymentprüfungen

`Test-SqlExport.ps1` prüft den Exportvertrag offline mit synthetischen Dateien.
Es verbindet sich nicht mit SQL Server und ersetzt keine Runtimequalifikation.

## Befüllter gemeinsamer Exportrepeat

`Invoke-ExportPopulatedRepeat.ps1` ist ein begrenzter CI-Adapter für das bereits
eigene externe Linux-/SQL-Server-2019-Ziel mit Compatibility Level 150 und
vorhandenen Rechten. Es startet keine Infrastruktur und konfiguriert weder
CLR noch Provider, Trust oder Berechtigungen. Die Verbindung kommt ausschließlich
aus einer ausdrücklich benannten Prozessumgebungsvariable.

Die Auswahl `worker-control`, `event-log`, `file.content`, `execution-cancel`
wird durch den echten `Deploy-All.ps1 -OutputSqlFile` zu neun Modulen ergänzt:
execution-context, result-table, file.content, execution-cancel, work-type,
second-session, work-queue, event-log und worker-control. Lokal und zentral wird
je eine eigene Datenbank mit unterschiedlicher Collation angelegt. Pro Modus
werden dieselben hashgebundenen Exportbytes für die Erstinstallation und zwei
befüllte Repeats verwendet; jeder Aufruf erhält eine frische ungepoolte Sitzung.
Der geschlossene Consumer erlaubt ausschließlich `:ON ERROR EXIT` und `GO`,
führt alle nichtleeren Batches in Reihenfolge aus und stoppt beim ersten Fehler.
Das ist eine Qualifikation der exportierten Batchfolge, keine Ausführung durch
SSMS oder `sqlcmd.exe`.

Die vier Runtimefixtures erzeugen ausschließlich synthetische Daten. Alle
14 Tabellen müssen befüllt sein; jedes deklarierte Feld wird als Binary mit
expliziten NULLs privat verglichen, einschließlich Auditpräzision, Textpadding,
Rowversions, Tokens und verbrauchter Identitywerte. Der ruhende Queue2.1-/
Control1.0-Verbund hat weder Claims, Holds noch belegte/offene Reservations.
Der einzelne synthetische Loopback-Eintrag bleibt deaktiviert. Es erfolgt
kein RPC, File-Content-I/O-API-Aufruf oder Workerstart im neuen Repeat.

Im ersten Repeat sind exakt zwei kanonische Änderungen erwartet:
`FileContentRootAllowlist` erneuert seine Tabellenbeschreibung; EventLog
reaktiviert seine eigene zuvor abweichend deaktivierte WorkType-Registrierung.
Separate Assertions prüfen deren kanonische Werte, unveränderte ID/Created-Audit
und geänderte Rowversion/Modified-Audit. Der zweite Repeat vergleicht auch diese
beiden Kategorien vollständig. Andere WorkTypes und eigene typisierte Tabellen-/
Spaltenannotation bleiben erhalten. Ausgewählte Objekt-/Spalten-/Index-/
Constraint-/Moduldefinitions-/Permissionsmetadaten werden verglichen;
wiedererzeugte Checkconstraint-IDs und DDL-Zeitstempel sind keine Zusage.
Nichtleere Benutzergrants werden weder erzeugt noch qualifiziert.

Identity-Nextinsert-Zeugen laufen erst nach beiden Vergleichsfenstern.
Snapshots und freie Diagnosen bleiben privat. Öffentlich erscheinen feste
Ergebnis-/Cleanupmarker und eine geschlossene Diagnose mit vorab definierten
Phasen-/Assertioncodes sowie numerischem SQL-Fehlercode/-State, ohne SQLtext
oder Exceptionmessage. Primärfehler und Cleanupfehler bleiben getrennt.
Die Bereinigung prüft in frischer Verbindung Namen,
DB-ID, Erzeugungszeit, Owner und typisierten Runmarker sowie fremde Sessions/
Requests. Bei unklarem Besitz wird nicht gelöscht; kein KILL, SINGLE_USER oder
Rollback fremder Verbraucher. Das private Journal bleibt bei Fehlern erhalten;
der vorhandene CI-Containercleanup bleibt separat unverändert.

Stand 2026-10-08: Offlineexport und unabhängige Reviews bestanden;
der erste native Lauf am Commit `e5b51d14500203947fd45d6ad0533e40b1302c8a`
ist im neuen Test **FAILED**
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37696018416)).
Vorherige Worker-/Upgradefälle und eigene Containerbereinigung bestanden.
Der Diagnoselauf am Commit `947da95d61ae617f88e42847ae453dd27e132197`
ist ebenfalls FAILED im Verbindungs-Preflight
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37697052700)).
Ohne Verbindung reproduziert: PowerShell-Dotzuweisungen für `InitialCatalog`
und `ConnectTimeout` erzeugen ungültige Builder-Schlüssel. Explizite Indexer
`Initial Catalog` und `Connect Timeout` beheben dies; der separate abschließende
Pfadseparatorfehler im Adaptercleanup ist ebenfalls korrigiert. Beide
fehlgeschlagenen Läufe bleiben historische Evidenz. Die Qualifikation bleibt offen bis
tatsächlicher korrigierter Head-CI. Die Einzelmodulnachweise stehen in
[Backlog](../../.ai/BACKLOG.md). Windows-FileSystemRoot, weitere Versionen/CLs,
historische und partielle Installationen, Minimalrechte, nichtleere Grants,
Hard-Interrupt-Recovery, native SQLCMD-Clients und vollständige 44-Modul-
Lifecycle-/Releasequalifikation bleiben offen.

Der folgende Lauf `6989d8ac43033e8cd45c2f8fb88f59239429c64a` besteht den
Verbindungs-Preflight, ist aber im eigenen Datenbank-/Sitzungsgate FAILED
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37697908672)).
Der Diagnoselauf `e79bf5a4c1d0db3760b6fbc29a8d1714b8fc7368` ist ebenfalls
FAILED ([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37699250549)):
Alle zwölf Einzelbedingungen bestehen, das kombinierte Gate wirft State 13.
Die Korrektur trennt die neutralen Sitzungsprüfungen von den kataloglesenden
Besitzprüfungen wie im bestehenden Repeatactor. Sämtliche Besitzprädikate
bleiben gemeinsam gebunden; die Sitzung wird davor und danach geprüft.
Ein während des Katalogstatements aktiver Autocommit erklärt das Ergebnis als
Hypothese; der konkrete interne Operand wurde nicht nativ gemessen.
Containerbereinigung und vorherige Runtimefälle bestanden weiterhin.
Der folgende Head `52526f7836b0d4c113991fc972608b1eff276283` besteht Besitzgate
und Erstinstallation, bleibt aber im initialen Fixture-Sitzungsgate
FAILED/SQL54980/State1
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37700707745)).
Die kombinierten Sitzungsbedingungen der vier Fixtures werden jeweils einzeln
geprüft; Prädikate, Fehlercodes und die fachlichen Orakel bleiben erhalten.
Vorherige Workerfälle und Containerbereinigung bestehen. Die korrigierte
gemeinsame Exportqualifikation bleibt bis neuer Head-CI offen.
