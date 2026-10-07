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

Das Startdirectory hat Tiefe0. Direkte Dateien benötigen keine zusätzliche
Directory-Ebene; ein untergeordnetes Directory benötigt Tiefe1. Daher erlaubt
`@MaxDepth = 0` direkte Dateien, verweigert jedoch schon ein leeres Childdirectory.
Ein Directory jenseits der erlaubten Tiefe wird mit `DepthLimitExceeded`
vor der ersten Löschung abgewiesen; Einträge werden vor Aufnahme in den
vollständigen Prüfplan gegen `@MaxEntries` geprüft. Beide Fehler bleiben im
bestehenden fachlichen Provider-/Facade-Fehlervertrag.
Der Prüfplan hält bis zu `@MaxEntries` Pfad-/Typrecords im Speicher;
gemessener Heap und Produktionskapazität sind damit nicht qualifiziert.

Der kanonische Löschhelper verarbeitet danach ausschließlich den geprüften Plan
von unten nach oben. Directory-Deletes sind immer nichtrekursiv; neue ungeprüfte
Kinder werden dadurch nicht mitgelöscht. Ancestry, Reparse-Status und Typ werden
vor jedem Delete erneut geprüft. Dies ersetzt keine handlegebundene Windows-
Sandbox: parallele Pfadänderungen bleiben ein TOCTOU-Rest. Ein I/O-/Racefehler
nach Beginn der Löschung kann einen Teilzustand hinterlassen; nur eine
fachliche Limitabweisung während des unveränderten Preflights ist mutationsfrei.

## Speicher und Schreibkonsistenz

Lesen liefert maximal 16 MiB pro Aufruf und gibt die nächste Byteposition zurück. LOB-Schreiben verwendet begrenzte Buffer. Schreiben und Transcoding verwenden eine zufällige `.part`-Datei im WorkPath oder Zielverzeichnis und veröffentlichen erst nach `Flush(true)` per Move/Replace. Deshalb verbleibt bei einem fehlgeschlagenen Write kein teilweise aktualisiertes Target.

## Plattform und Trust

Die Installation prüft `clr enabled` und `clr strict security`, ändert aber keine Instanzoption. Ein sysadmin muss den SHA2-512-Hash exakt per `sys.sp_add_trusted_assembly` autorisieren. `TRUSTWORTHY ON`, `UNSAFE` und `xp_cmdshell` sind ausgeschlossen. SQL Server auf Linux unterstützt den erforderlichen `EXTERNAL_ACCESS`-Pfad nicht und ist daher `not applicable`.

## NoOverwrite-Veröffentlichung

Bei `@Overwrite = 0` veröffentlicht der Provider ausschließlich per nicht überschreibendem `File.Move`. Auch ein erst während des Staging-Schreibens erzeugtes Ziel wird nicht ersetzt; der frühere Existenzcheck allein ist keine Veröffentlichungsbarriere. `@Overwrite = 1` behält den bisherigen Move-/Replace-Pfad. Fehlgeschlagenes Schreiben räumt die eigene Staging-Datei auf; ein vorhandenes Ziel bleibt bei NoOverwrite unverändert. Dies ist keine allgemeine NTFS-, Power-Loss- oder Caller-Impersonation-Garantie.

Die eng begrenzte Korrektur ändert ausschließlich die Weitergabe des bestehenden Overwrite-Flags und die Veröffentlichung im kanonischen Helper. Öffentliche SQL-Verträge, Lifecycle, Identitätsmodi und Version bleiben unverändert. Ein Offline-Helpertest beobachtet synthetische konkurrierende Zielerzeugung; die Windows-SQL-/NTFS-Matrix bleibt ein eigener Nachweis.
