# Stabile T-SQL-Kandidaten ohne eigenen Build installieren

Dieses kleine Paket enthält die 19 stabilen T-SQL-Kandidaten für SQL Server
2019, 2022 und 2025 unter Windows/Linux. Es ist vorbereitet und **nicht
veröffentlicht**; die Kennzeichnung ist keine Produktionsfreigabe. Die beiden
SQL-Dateien sind bytegleich zu den bereits qualifizierten Installationspayloads.
Neue Paketverpackung und Anleitung wurden offline geprüft; eine erneute native
Installation oder SSMS-/Anmeldungsabnahme wird dadurch nicht behauptet.

## Vorbereiten und installieren

Du brauchst eine laufende SQL-Server-Instanz, SSMS und eine vorhandene Anmeldung,
die eine eigene Demodatenbank samt Objekten anlegen darf. Kein eigener Build,
CLR, Assembly-Trust oder zusätzliches sqlcmd-Programm ist erforderlich.
Die [ausführliche SSMS-Anleitung](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/INSTALL.md)
zeigt Verbindung, Datenbankanlage, Kontrollen und Fehlerbehebung.

1. Lade `SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip` und die zugehörige
   `.zip.sha256` aus demselben Repositorystand herunter. Vergleiche den Hash
   vor dem Auspacken, beispielsweise in PowerShell:

   ```powershell
   Get-FileHash -LiteralPath 'C:\Temp\SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip' -Algorithm SHA256
   ```

   Bei Abweichung beide Dateien erneut aus demselben Stand laden. Prüfsummen
   erkennen Änderungen und Übertragungsfehler; sie sind keine digitale Signatur.
2. Entpacke das ZIP vollständig. Im Ordner
   `SQL-Server-Toolbelt-1.0.0-Stable-SQL` liegen diese Anleitung als
   `START-HERE.md`, beide SQL-Dateien, Lizenz, Manifest und Dateiprüfsummen.
3. Verbinde SSMS mit deinem Testsystem und lege eine **neue eigene** Datenbank
   wie `ToolbeltDemo` mit Kompatibilitätsgrad 150 an. Verwende bei vorhandenem
   Namen einen anderen; bestehende Datenbanken nicht ersetzen.
4. Öffne `Install-Stable-local.sql` über SSMS. Prüfe im Datenbankfeld deine
   neue Demodatenbank und verwende eine frische Verbindung ohne laufende oder
   implizite Transaktion. Aktiviere **Abfrage → SQLCMD-Modus**, hebe mögliche
   Textmarkierungen auf und führe die vollständige Datei mit F5 aus.
5. Prüfe zuerst **Meldungen** auf Fehler. Die Installation erfolgt modulweise;
   bei einem Fehler bleiben vorher erfolgreich installierte Module bestehen.
   Behebe die gemeldete Voraussetzung, bevor du dieselbe Datei in einer
   frischen Verbindung zur eigenen Demodatenbank wiederholst. Keine vorhandenen
   Objekte zur Umgehung eines Versions-/Dependencyfehlers löschen.

## Ergebnis kontrollieren

Ein neues Abfragefenster in derselben Demodatenbank muss 19 Modulversionen liefern:

```sql
SELECT REPLACE(REPLACE(ep.name, N'Toolbelt.Module.', N''), N'.Version', N'') AS Module,
       CONVERT(nvarchar(64), ep.value) AS Version
FROM sys.extended_properties AS ep WITH (NOLOCK)
WHERE ep.class = 0 AND ep.name LIKE N'Toolbelt.Module.%.Version'
ORDER BY Module;

SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, 1) ORDER BY Value;
```

Die zweite Abfrage liefert die Werte 1 bis 5. Modulversionen können von der
Projektversion 1.0.0 abweichen. Weniger Versionszeilen oder fehlende Funktionen
verlangen die erste Installationsfehlermeldung beziehungsweise eine Prüfung
der aktiven Datenbank; die ausführliche Anleitung führt durch diese Fälle.

## Zentraler Weg, weitere Module und Entfernung

`Install-Stable-central.sql` installiert denselben Kandidatensatz stattdessen
in eine eigene zentrale Testdatenbank, etwa `ToolbeltCentralDemo`. Verwende den
gleichen Ablauf mit dieser Datei und der passenden Zieldatenbank. Der Aufruf
aus einer anderen Datenbank erfolgt beispielsweise über
`ToolbeltCentralDemo.toolbelt_core.TVF_GenerateSeriesInt(1, 5, 1)`.

Die Installer vergeben keine Rechte und ändern keine Serverkonfiguration.
CrossDB-Identitätsmappings und vorhandene Berechtigungen bleiben Voraussetzung.
Verschlüsselung und Zertifikatseinstellungen folgen deiner Umgebung; das Paket
qualifiziert keine Serveridentität und schaltet keine Trusteinstellung um.

Diese ZIP enthält keine CLR-/Preview-/SSIS-Module und keine Uninstallskripte.
Für Quellen und gezielte Deinstallation nutze das
[passende Quellpaket](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/README.md)
und die jeweiligen Modul-/Dependencyverträge. Entferne eine eigene Demodatenbank
nur, wenn sie ausschließlich für diesen Versuch angelegt wurde und ihre Inhalte
nicht mehr benötigt werden. Andere Datenbanken bleiben bestehen.

Die unveränderte `LICENSE.md` liegt bei. Die
[Freigabematrix](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/FREIGABEMATRIX.md)
und [offenen Releasegates](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/RELEASE-GATES.md)
gelten weiterhin. Das Manifest trennt das aktuelle Quellarchiv, den historischen
nativen Archivnachweis und die unveränderten qualifizierten SQL-Hashes.
