# SQL Server Toolbelt verwenden

SQL Server Toolbelt ergänzt die SQL Server Database Engine um wiederverwendbare
Funktionen, Prozeduren und Views. Die Dokumentation richtet sich an Personen,
die T-SQL schreiben, Daten verarbeiten oder eine Installation betreiben.

## Die passende Funktion finden

- [Nach Aufgabe auswählen](ChooseFunctions.md). Die Übersicht ordnet alle Module
  nach Anwendungsfällen ein und nennt ähnliche Werkzeuge und ihre Unterschiede.
- [Nach SQL-Objekt suchen](Reference/README.md). Die Referenz führt vom Namen
  zur Objektseite mit Voraussetzungen, Parametern, Ergebnissen, Fehlern und
  Beispielen. Der HTML-Katalog kann nach dem Entpacken lokal durchsucht werden.
- [Hilfe direkt in SQL lesen](../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ObjectUsageSkills.md).
  Die Skill-View bietet Kurzbeschreibungen und vollständige Markdown-Anleitungen.
  Bei Prozeduren lässt sich die Hilfe zusätzlich mit `@Hilfe=1` aufrufen.

## Installieren und betreiben

- [Toolbelt installieren](../INSTALL.md). Paket oder Quellbuild wählen,
  Voraussetzungen prüfen, lokal oder zentral installieren und die Einrichtung
  verifizieren. Dort stehen auch die Trustvarianten und der Wechsel auf eine
  neue Installation.
- [Ein-Aufruf-Installer nachschlagen](../Deployment/ONE-CALL-INSTALL.md).
  Parameter, Authentifizierung, Vorprüfung und Fehlermeldungen.
- [Datenbank und CLR vorbereiten](../Deployment/PROVISIONING.md).
  Wirkung, Rechte und Fehlerbehandlung der optionalen Vorbereitung.
- [Objekte aus einer anderen Datenbank aufrufen](../INSTALL.md#zentrale-objekte-aufrufen).
  Dreiteilige Namen, Datenbankzuordnung und Berechtigungen.

## Durchgängige Anleitungen

- [DTSX-Datenfluss als SQL nachvollziehen](../Modules/toolbelt.tsql.ssis-debug/Documentation/LocalCteDebug.md).
  DTSX-XML übergeben, Startwerte setzen, Zwischenschritte und Lookup-Fehlzeilen prüfen.
- [Aufträge mit der Queue verarbeiten](../Modules/toolbelt.core.work-queue/Documentation/USAGE.md).
  Einrichtung, Einreihung, Claims, Retry, Dead Letter und Barriers anhand eines Ablaufs.
- [Queue-Worker starten und steuern](../Workers/ExternalQueue/USAGE.md).
  Ausführung, Parallelität, Stop, Hold und Wiederfreigabe.
- [SQL zwischen T-SQL und Databricks SQL übertragen](../Scripts/SqlDialect/README.md).
  Das separate Kommandozeilenwerkzeug prüft und übersetzt die dokumentierten
  Abfrageformen. Die native Databricks-Kompatibilität ist offen.

## Bei Abweichungen

Bei Installationsfehlern mit der [Fehlerhilfe](../INSTALL.md#fehler-beheben)
beginnen. Bei einem unerwarteten Abfrageergebnis die Objektseite lesen und
`NULL`, leere Ergebnismenge, Statusspalte und SQL-Fehler unterscheiden. Bei
einem Wechsel des Servers zusätzlich Plattform, Kompatibilitätslevel, Rechte
und die Datenbank prüfen, in der die Funktion tatsächlich ausgeführt wird.

[Entwicklung und Projektpflege](Development/README.md)
