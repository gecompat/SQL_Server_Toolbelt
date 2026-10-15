# Windows Filesystem Module Design

Status: freigegebene native Härtung implementiert; begrenzte Windows-Runtimeprüfung bestanden, Gesamtmatrix offen.

## Entscheidung

`toolbelt.filesystem.windows` ist eine lokale Windows-only Capability. Die Implementierung nutzt eine C#-.NET-Framework-4.8-SQL-CLR-Assembly mit ausdrücklich freigegebenem `UNSAFE`; eine portable Simulation oder `xp_cmdshell` ist kein Ersatz.

Die öffentliche T-SQL-Fassade bleibt der alleinige API-Einstieg. Ihre internen CLR-Procedures liefern ein enges Resultset; die Fassade stellt den Help- und ResultTable-Vertrag her.

## Identität

`Caller` ist Default. Er verwendet ausschließlich `SqlContext.WindowsIdentity` und damit das Windows-Token des aktuell authentifizierten SQL-Callers. Dieser Modus wird ohne Windows-Token kontrolliert abgelehnt. `ServiceAccount` ist eine explizite Alternative und führt den I/O-Block unter dem SQL-Server-Dienstkonto aus. ServiceAccount verlangt sowohl `AllowServiceAccount = 1` am Root (Default 0)
als auch Mitgliedschaft des aktuellen SQL-Callers in `toolbelt_filesystem_service_account`.
Die Rolle muss Typ R und dbo als Owner haben; Deployment und direkter CLR-Einstieg
weisen abweichende Besitzer ab. Deployment erteilt keine Mitgliedschaften.
Ein interaktiv angemeldeter Benutzer verleiht keine Autorität.

## Pfade und Löschung

Eine serverseitig konfigurierte Tabelle ordnet Alias zu Root und optionalem relativem WorkPath zu. Die API nimmt keine absoluten Pfade an. Der Provider normalisiert Pfade, verweigert Ausbrüche aus dem Root und sperrt Reparse Points vor Lesen, Schreiben, Listing und Löschen.

Alle neun APIs halten Root, WorkPath und lokale Laufwerksvorfahren über native
Handles ohne Write-/Deletefreigabe offen. Reparse Points, ungeeignete Objekttypen
und mehrfach verlinkte Dateien werden abgewiesen. Gelesen und veröffentlicht
wird über dieselben geprüften Handles; es gibt keinen Pfadfallback.
Rekursive Löschung verlangt `@Recursive = 1` und einen vollständigen begrenzten
Preflightplan, der die tatsächlichen Löschhandles bis zur Mutation hält.

Das Startdirectory hat Tiefe0. Direkte Dateien benötigen keine zusätzliche
Directory-Ebene; ein untergeordnetes Directory benötigt Tiefe1. Daher erlaubt
`@MaxDepth = 0` direkte Dateien, verweigert jedoch schon ein leeres Childdirectory.
Ein Directory jenseits der erlaubten Tiefe wird mit `DepthLimitExceeded`
vor der ersten Löschung abgewiesen; Einträge werden vor Aufnahme in den
vollständigen Prüfplan gegen `@MaxEntries` geprüft. Beide Fehler bleiben im
bestehenden fachlichen Provider-/Facade-Fehlervertrag.
Der Prüfplan hält bis zu `@MaxEntries` Pfad-/Typrecords im Speicher;
gemessener Heap und Produktionskapazität sind damit nicht qualifiziert.

Der kanonische Löschhelper verarbeitet den gehaltenen Plan von unten nach oben.
Directory-Deletes sind nichtrekursiv; neue ungeprüfte Kinder werden nicht
mitgelöscht. Ein I/O-Fehler nach erster Löschung kann einen Teilzustand
hinterlassen. Limitabweisungen erfolgen vor der ersten Löschung.
Listing sammelt vollständig vor der Ausgabe und begrenzt Tiefe auf 64,
Einträge auf 10000 und gespeicherte UTF-16-Pfadtexte auf insgesamt 16 MiB.

## Speicher und Schreibkonsistenz

Lesen liefert maximal 16 MiB pro Aufruf und gibt die nächste Byteposition zurück.
LOB-Schreiben verwendet begrenzte Buffer. Stagehandles bleiben von `CREATE_NEW`
bis `Flush(true)` und `SetFileInformationByHandle`-Rename gebunden. Bei NoOverwrite
wird ein zwischenzeitlich vorhandenes Ziel nicht ersetzt. Overwrite übernimmt
die DACL eines vorhandenen Ziels über dessen gehaltenen Handle vor Publikation;
fehlende Rechte brechen ab. Cleanup betrifft ausschließlich die eigene Stage.
Power-Loss-Durabilität, vollständige NTFS-Sandbox und Produktionsheap sind nicht zugesagt.

## Plattform und Trust

Die Installation prüft `clr enabled` und `clr strict security`, ändert aber
keine Instanzoption. Der Operator autorisiert nur den exakten Release-SHA2-512.
`UNSAFE` ist wegen P/Invoke erforderlich und ausdrücklich für SC-023 freigegeben.
`TRUSTWORTHY ON`, ein Abschalten von strict security und `xp_cmdshell` bleiben
ausgeschlossen. Dieser Provider ist ausschließlich für Windows vorgesehen;
Linux bleibt `not applicable`.

## Abgegrenzter Nachweis

Windows-.NET-Frameworktests prüfen gehaltene Root-/Stagebindungen,
NoOverwrite-Rennen, DACL-Erhalt und begrenzte Löschpläne. Der native SQL-Test
`Tests/CI/run-filesystem-security-lab.ps1` bestand am 2026-10-15 auf ausgewähltem
SQL Server 2025 Windows: ServiceAccount-Rolle, Rootdefault, abweichender
Rollenowner und alle neun öffentlichen APIs; eigene DB/Dateien/Trust entfernt.
Caller-Token-/NTFS-Gesamtmatrix und Live-Austauschrennen bleiben offen.
Details: [Security-Härtung](SECURITY_HARDENING_2026_10.md).
