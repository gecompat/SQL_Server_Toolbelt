# Windows Filesystem Module Design

Status: accepted for implementation; Windows runtime validation pending.

## Entscheidung

`toolbelt.filesystem.windows` ist eine lokale Windows-only Capability. Die Implementierung nutzt eine C#-.NET-Framework-4.8-SQL-CLR-Assembly mit `EXTERNAL_ACCESS`; eine portable Simulation oder `xp_cmdshell` ist kein Ersatz.

Die öffentliche T-SQL-Fassade bleibt der alleinige API-Einstieg. Ihre internen CLR-Procedures liefern ein enges Resultset; die Fassade stellt den Help- und ResultTable-Vertrag her.

## Identität

`Caller` ist Default. Er verwendet ausschließlich `SqlContext.WindowsIdentity` und damit das Windows-Token des aktuell authentifizierten SQL-Callers. Dieser Modus wird ohne Windows-Token kontrolliert abgelehnt. `ServiceAccount` ist eine explizite Alternative und führt den I/O-Block unter dem SQL-Server-Dienstkonto aus. Ein interaktiv an der Maschine angemeldeter Benutzer ist kein gültiger oder ermittelbarer Identitätsmodus.

## Pfade und Löschung

Eine serverseitig konfigurierte Tabelle ordnet Alias zu Root und optionalem relativem WorkPath zu. Die API nimmt keine absoluten Pfade an. Der Provider normalisiert Pfade, verweigert Ausbrüche aus dem Root und sperrt Reparse Points vor Lesen, Schreiben, Listing und Löschen.

Rekursive Löschung benötigt ausdrücklich `@Recursive = 1`; sie zählt vorab und begrenzt Traversierung durch `@MaxDepth` sowie `@MaxEntries`. Der Prüfen-/Löschen-Zeitabstand bleibt ein Windows-Dateisystemrest und wird im manuellen Windows-Test mit Junction/Symlink abgedeckt.

## Speicher und Schreibkonsistenz

Lesen liefert maximal 16 MiB pro Aufruf und gibt die nächste Byteposition zurück. LOB-Schreiben verwendet begrenzte Buffer. Schreiben und Transcoding verwenden eine zufällige `.part`-Datei im WorkPath oder Zielverzeichnis und veröffentlichen erst nach `Flush(true)` per Move/Replace. Deshalb verbleibt bei einem fehlgeschlagenen Write kein teilweise aktualisiertes Target.

## Plattform und Trust

Die Installation prüft `clr enabled` und `clr strict security`, ändert aber keine Instanzoption. Ein sysadmin muss den SHA2-512-Hash exakt per `sys.sp_add_trusted_assembly` autorisieren. `TRUSTWORTHY ON`, `UNSAFE` und `xp_cmdshell` sind ausgeschlossen. SQL Server auf Linux unterstützt den erforderlichen `EXTERNAL_ACCESS`-Pfad nicht und ist daher `not applicable`.
