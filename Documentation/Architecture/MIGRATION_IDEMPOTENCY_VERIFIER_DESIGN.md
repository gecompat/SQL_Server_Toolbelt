# Migration-Idempotency-Verifier Q1 V1

## Zweck

Der Q1-Verifier prüft, dass ein Modul-Deployment auf demselben Releasezustand
keine Katalogdrift erzeugt und dass ein wiederholtes Uninstall vollständig und
fehlerfrei bleibt. Er ist repository-interne Testautomation und definiert
keine öffentliche SQL-Schnittstelle.

## V1-Scope

V1 ist absichtlich auf ein isoliertes, dependency-freies Modul mit
zustandslosen T-SQL-Funktionen, Procedures oder Views begrenzt. Als erster
Referenzvertrag dient `toolbelt.core.generate-series`:

1. leere synthetische Testdatenbank anlegen;
2. Modul erstmals lokal deployen;
3. kanonischen Katalog-Snapshot erfassen;
4. denselben Release erneut deployen;
5. Objekte, Definitionen, Spalten, Parameter, Toolbelt-Properties und
   Berechtigungen kataloggenau vergleichen;
6. nach Abschluss der Snapshot-Sitzung in zwei voneinander unabhängigen
   SQLCMD-Sitzungen deinstallieren;
7. nach beiden Aufrufen Releaseobjekte und Modulmarker als entfernt nachweisen;
8. synthetische Testdatenbank auch nach Fehlern gezielt bereinigen.

Tabellen, Assemblies, persistente Zustandsdaten, Dependency-Installation,
historische Upgradeartefakte, Central-Consumer und parallele Migrationen
bleiben getrennte spätere Slices.

## Alternativen

- Nur vorhandene Lifecycle-Tests ausführen: erkennt keine stille Definition-,
  Metadaten- oder Berechtigungsdrift.
- Ausschließlich Source-Hashes vergleichen: Source-Hashes sind bei mehreren
  Modulen diagnostisch und bilden den effektiven Katalog nicht vollständig ab.
- Ein dauerhaftes Verifier-Modul installieren: erzeugt eine unnötige Runtime-
  Capability und würde den zu prüfenden Zustand selbst verändern.

Der gewählte SQLCMD-Contract hält den Snapshot ausschließlich in lokalen
Temp-Tabellen derselben Testsitzung.

## Risiken und Grenzen

- Objekt-IDs und Änderungszeitpunkte sind absichtlich nicht Teil des
  Snapshots, weil ein korrektes Wiederholungsdeployment sie verändern darf.
- V1 vergleicht keine Tabelleninhalte und lehnt zustandsbehaftete Objekttypen
  ab.
- V1 verwendet die Standard-Collation des jeweiligen Testziels. Abweichende
  Database- und Catalog-Collations bleiben ein eigener Lifecycle-Testscope.
- Der Verifier darf nur in einer isolierten synthetischen Testdatenbank laufen.
- Fehlerausgaben enthalten keine Connection Strings, Credentials, Hosts oder
  vollständigen Objektdefinitionen.
- Die Lab-Orchestrierung verwendet ausschließlich explizit ausgewählte bereite
  Ziele. Sie beendet, startet oder repariert keine SQL_Server_Lab-Umgebung.

## Abnahme

- statischer Contract erfolgreich;
- wiederholtes Deployment ohne Katalogdrift;
- wiederholtes Uninstall ohne Restobjekte oder Modulmarker;
- tatsächliche Läufe auf SQL Server 2019, 2022 und 2025 unter Linux und
  Windows, soweit einzeln bereite Lab-Ziele vorhanden sind;
- erzeugte Testdatenbanken werden gezielt entfernt, die Lab-Systeme bleiben
  unverändert aktiv.

## Evidenz

Der statische Contract, der vollständige Dokumentationsaudit und die lokale
SQL_Server_Lab-Matrix waren am 2026-08-29 für SQL Server 2019, 2022 und 2025
jeweils unter Linux und Windows erfolgreich. Pro Ziel wurden ausschließlich
synthetische Testobjekte verwendet und nach dem zweimaligen Uninstall sowie
der Restzustandsprüfung durch Entfernen der eindeutigen Testdatenbank
bereinigt. Die Lab-Systeme wurden nicht gestartet, gestoppt oder repariert.

Die Evidenz übernimmt keine Hosts, Credentials, Connection Strings, konkreten
Datenbanknamen, Engine-Buildnummern, Laufzeiten oder vollständigen Logs.
