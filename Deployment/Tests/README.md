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
Snapshots und Diagnosen bleiben privat. Öffentlich erscheinen nur feste
Ergebnis-/Cleanupmarker. Die Bereinigung prüft in frischer Verbindung Namen,
DB-ID, Erzeugungszeit, Owner und typisierten Runmarker sowie fremde Sessions/
Requests. Bei unklarem Besitz wird nicht gelöscht; kein KILL, SINGLE_USER oder
Rollback fremder Verbraucher. Das private Journal bleibt bei Fehlern erhalten;
der vorhandene CI-Containercleanup bleibt separat unverändert.

Stand 2026-10-08: Offlineexport und unabhängige Reviews bestanden;
native gemeinsame Runtime ist **not executed**, bis ein exakter Head-Lauf
erfolgreich abgeschlossen ist. Die Einzelmodulnachweise stehen in
[Backlog](../../.ai/BACKLOG.md). Windows-FileSystemRoot, weitere Versionen/CLs,
historische und partielle Installationen, Minimalrechte, nichtleere Grants,
Hard-Interrupt-Recovery, native SQLCMD-Clients und vollständige 44-Modul-
Lifecycle-/Releasequalifikation bleiben offen.
