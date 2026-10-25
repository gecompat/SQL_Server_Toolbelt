# SQL Server Toolbelt installieren und ausprobieren

Diese Anleitung führt dich vom ZIP-Download zum ersten erfolgreichen Aufruf
in SQL Server Management Studio (SSMS). Du brauchst dafür keine eigenen
Builds und keine Programmierwerkzeuge.

Wenn du das Paket bereits entpackt hast, kontrolliere in Schritt 1 nur noch
Prüfsumme und Ordnerinhalt und fahre dann mit Schritt 2 fort.

**Aktueller Stand:** v1.0.0 wird vorbereitet und ist noch nicht veröffentlicht.
Für den ersten Test verwenden wir die **19 stabilen T-SQL-Kandidaten** in
einer neuen Demodatenbank. Die weiteren Preview-/CLR-Module haben zusätzliche
Voraussetzungen; den passenden Weg findest du [weiter unten](#weitere-module-und-installationswege).
Die Kennzeichnung ist noch keine Produktionsfreigabe.

## Was du vorher brauchst

| Voraussetzung | Was damit gemeint ist |
|---|---|
| SQL Server 2019, 2022 oder 2025 | Eine laufende Datenbankinstanz unter Windows oder Linux, mit der du dich verbinden darfst. SSMS allein installiert keinen Datenbankserver. |
| SSMS auf deinem Windows-Rechner | Das Programm zum Verbinden und Ausführen der SQL-Datei. Falls es fehlt: [offizielle SSMS-Installationsanleitung](https://learn.microsoft.com/en-us/ssms/install/install). |
| Servername und Anmeldung | Verwende die Angaben deiner Administration. `localhost` passt nur, wenn die Standardinstanz auf deinem Rechner läuft. |
| Vorhandene Installationsrechte | Der nachfolgende Testweg setzt ein bereits bereitgestelltes administratives SQL-Konto voraus, das eine Demodatenbank und deren Objekte anlegen darf. Windows-Administratorrechte allein sind keine SQL-Server-Rechte. |

Für diesen Einstieg sind weder Visual Studio noch SQL CLR, Assembly-Trust,
Python, Git oder das separate `sqlcmd`-Programm erforderlich. Der SQLCMD-Modus
ist bereits Bestandteil von SSMS. Die kurze Prüfsummenabfrage
verwendet PowerShell. [Microsoft beschreibt den integrierten SQLCMD-Modus hier.](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-download-install?view=sql-server-ver17)

Wenn dir Serverzugang oder Rechte fehlen, bitte deine Administration um eine
eigene Testdatenbank beziehungsweise die Installation. Der Toolbelt-Installer
erteilt keine Rechte und konfiguriert keinen SQL Server.

## 1. Das vorbereitete Paket herunterladen

1. Öffne die [ZIP-Dateiseite im Repository](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip).
   Lade die Datei über **Download raw file** beziehungsweise das Downloadsymbol
   herunter. Ihr Name ist `SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip`.
2. Lade daneben die [SHA-256-Prüfsumme](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip.sha256)
   aus demselben Repositorystand herunter. Die erste Zeichenfolge in dieser
   Textdatei ist der erwartete Hash.
3. Prüfe vor dem Auspacken in PowerShell, ob der Download vollständig
   ist. Ersetze den Beispielpfad durch den Speicherort deiner ZIP:

   ```powershell
   Get-FileHash -LiteralPath 'C:\Temp\SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip' -Algorithm SHA256
   ```

   Vergleiche die 64 Zeichen unter `Hash` mit der Prüfsummendatei. Groß- und
   Kleinschreibung spielen dabei keine Rolle. Bei Abweichung beide Dateien
   erneut aus demselben Stand herunterladen und erst danach fortfahren.
   Dieser Vergleich prüft Dateiintegrität; eine digitale Signatur ersetzt er nicht.
4. Klicke die ZIP im Windows-Explorer mit der rechten Maustaste an und wähle
   **Alle extrahieren**. Öffne anschließend den entpackten Ordner
   `SQL-Server-Toolbelt-1.0.0-Stable-SQL`.

Du bist im richtigen Ordner, wenn du dort `START-HERE.md`, `Install-Stable-local.sql` und
`Install-Stable-central.sql` siehst. Die SQL-Datei muss vollständig entpackt
vorliegen. Für diesen Weg ist sie bereits fertig erzeugt.

Die [kurze Paketanleitung](Releases/1.0.0/STABLE-SQL-INSTALL.md) liegt als
`START-HERE.md` bei. Das kleine ZIP enthält genau die stabilen SQL-Installer;
für Quellen und modulweise Deinstallation gibt es weiterhin das
[vollständige Quellpaket](Releases/1.0.0/README.md#was-enthalten-ist).
Die SQL-Payloads bleiben bytegleich zum qualifizierten Kandidaten.

## 2. Mit SQL Server verbinden

1. Starte SSMS. Wähle beim Verbinden **Datenbank-Engine / Database Engine**.
2. Trage den bereitgestellten Servernamen und die vereinbarte Anmeldeart ein.
   Verwende deine vorhandene Anmeldung; Passwörter gehören nicht in SQL-Dateien.
3. Klicke auf **Verbinden / Connect**.

**Erwartetes Ergebnis:** Links erscheint im Objekt-Explorer der Server mit dem
Eintrag **Datenbanken / Databases**. Die
[Microsoft-Anleitung zum Verbinden](https://learn.microsoft.com/en-us/ssms/quickstarts/ssms-connect-query-sql-server)
zeigt die Dialoge verschiedener SSMS-Versionen.

Toolbelt selbst benötigt kein eigenes TLS-Zertifikat. Verwende für die
Verbindung die Verschlüsselungs- und Zertifikatseinstellungen deiner Umgebung.
Ein für eine Testverbindung ausdrücklich erlaubtes `TrustServerCertificate=True`
hindert die hier gezeigten Funktionen nicht an der Ausführung. Es bestätigt
aber keine geprüfte Serveridentität. Falls die Anmeldung scheitert, hilft die
[Fehlertabelle](#wenn-etwas-nicht-funktioniert) bei der Einordnung.

## 3. Eine eigene Demodatenbank anlegen

1. Rechtsklick auf **Datenbanken / Databases**, dann **Neue Datenbank / New Database**.
2. Gib `ToolbeltDemo` als Namen ein und bestätige mit **OK**.
   Falls dieser Name schon existiert, verwende für diesen Test einen neuen
   Namen und ersetze `ToolbeltDemo` in den folgenden Schritten entsprechend.
3. Für einen einheitlichen Einstieg auf allen drei SQL-Versionen: Rechtsklick
   auf **deine neue Demodatenbank**, **Eigenschaften / Properties**, **Optionen / Options**,
   dann **Kompatibilitätsgrad / Compatibility level: SQL Server 2019 (150)**.
   Bestätige mit **OK**. Diese Wahl betrifft nur die neue Demodatenbank.

Eine lokale Installation bedeutet hier: Die Toolbelt-Objekte werden direkt
in dieser Datenbank angelegt. Dein Windows-Rechner kann sich dabei auch mit
einem SQL Server auf Linux verbinden.

## 4. Zieldatenbank kontrollieren

Öffne mit **Neue Abfrage / New Query** ein Abfragefenster. Wähle oben im
Datenbankfeld `ToolbeltDemo` aus, füge die folgende Abfrage ein und drücke **F5**:

```sql
SELECT DB_NAME() AS DatabaseName, compatibility_level AS CompatibilityLevel
FROM sys.databases WITH (NOLOCK)
WHERE database_id = DB_ID();
```

**Erwartet:** eine Zeile mit `ToolbeltDemo` und `150`. Damit ist die
beabsichtigte Zieldatenbank bestätigt. Fahre erst mit diesem Ergebnis fort.

## 5. Die 19 stabilen Kandidaten installieren

1. Öffne über **Datei → Öffnen → Datei / File → Open → File** die entpackte
   `Install-Stable-local.sql`. Die Datei ist als UTF-8 gespeichert; behalte
   diese Codierung bei, falls SSMS danach fragt.
2. Prüfe in **diesem neuen Skriptfenster** erneut den verbundenen Server und
   wähle im Datenbankfeld `ToolbeltDemo` aus. Die Auswahl eines anderen
   Abfragefensters wird nicht automatisch übernommen.
3. Aktiviere für dieses Fenster **Abfrage → SQLCMD-Modus / Query → SQLCMD Mode**.
   Dadurch versteht SSMS die Zeile `:ON ERROR EXIT`; sie beendet das Skript
   bei einem Fehler. [Microsoft erläutert diesen Modus hier.](https://learn.microsoft.com/en-us/ssms/scripting/sqlcmd-scripts-query-editor)
4. Hebe eine mögliche Textmarkierung auf und drücke **F5**. Ohne Markierung
   führt SSMS die gesamte geöffnete Datei aus.
5. Öffne unten **Meldungen / Messages**. Fahre mit der Kontrolle im nächsten
   Schritt fort, sobald die Ausführung beendet ist und keine Fehlermeldung vorliegt.

Die Datei installiert die 19 stabilen Kandidaten samt ihren Abhängigkeiten.
Sie verändert keine Serveroptionen und erteilt keinen Assembly-Trust.
Die Module werden nacheinander installiert: Bei einem Fehler bleiben davor
erfolgreich installierte Module erhalten. Die [Fehlertabelle](#wenn-etwas-nicht-funktioniert)
erklärt das weitere Vorgehen.

## 6. Installation und erste Funktionen testen

Öffne ein **neues** Abfragefenster und wähle wieder `ToolbeltDemo` aus.
Führe zunächst diese Installationskontrolle aus:

```sql
SELECT
    REPLACE(REPLACE(ep.name, N'Toolbelt.Module.', N''), N'.Version', N'') AS Module,
    CONVERT(nvarchar(64), ep.value) AS Version
FROM sys.extended_properties AS ep WITH (NOLOCK)
WHERE ep.class = 0
  AND ep.name LIKE N'Toolbelt.Module.%.Version'
ORDER BY Module;
```

**Erwartet:** 19 Zeilen mit Modulnamen und ihren jeweiligen Versionen.
Die Projektversion `1.0.0` ist nicht automatisch die Versionsnummer jedes Moduls.

Teste anschließend eine kleine Zahlenreihe:

```sql
SELECT Value
FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, 1)
ORDER BY Value;
```

**Erwartet:** die fünf Werte `1`, `2`, `3`, `4`, `5` in der Spalte `Value`.
Das folgende Beispiel codiert die drei synthetischen Bytes für `foo` als Base64:

```sql
SELECT EncodedValue
FROM toolbelt_conversion.TVF_Base64Encode(0x666F6F, 0);
```

**Erwartet:** eine Zeile mit `Zm9v`. Damit hast du Installation und erste
Aufrufe geprüft. Weitere einzelne Beispiele findest du im
[API-Katalog](Documentation/Reference/README.md); jede Funktion verlinkt ihre
Parameter, Ergebnisse und Einschränkungen.

## Wenn etwas nicht funktioniert

| Beobachtung | Nächster konkreter Schritt |
|---|---|
| SSMS kann den Server nicht erreichen | Server-/Instanzname und Anmeldung mit der Administration prüfen; zuerst die Verbindung herstellen, dann Toolbelt installieren. |
| Zertifikats- oder TLS-Fehler beim Verbinden | Die vereinbarten Verbindungswerte verwenden. Für eine ausdrücklich freigegebene Testumgebung kann die Administration eine Verbindung mit **Serverzertifikat vertrauen / Trust server certificate** vorgeben. Die Toolbelt-Funktionen benötigen keine globale Zertifikats-/Truststoreänderung. |
| Zugriff verweigert oder Datenbankanlage nicht erlaubt | Installation durch ein bereits berechtigtes SQL-Konto durchführen lassen; die Anleitung vergibt selbst keine Rechte. |
| Syntaxfehler an `:` oder `:ON ERROR EXIT` | SQLCMD-Modus im tatsächlich ausgeführten Skriptfenster einschalten und die vollständige Datei in einer frischen Verbindung erneut öffnen. |
| Weniger als 19 Versionszeilen | Im Installationsfenster die erste Fehlermeldung suchen und deren Voraussetzung beheben. Bereits installierte Module bleiben bestehen. Danach in einer frischen Verbindung dieselbe Datei für dieselbe Demodatenbank wiederholen. |
| Funktion nicht gefunden | Mit `SELECT DB_NAME();` die aktive Datenbank prüfen; die lokale Installation muss in dieser Datenbank vorhanden sein. Danach die Installationskontrolle wiederholen. |
| Abhängigkeits-, Versions- oder fremder Objektname wird gemeldet | In einer neuen leeren Demodatenbank beginnen oder den [modulspezifischen Deploymentvertrag](Deployment/README.md) prüfen. Vorhandene Objekte nicht zur Umgehung des Fehlers löschen. |
| Fehler mit Transaktionszustand | Das Installationsfenster schließen, eine frische Verbindung zur Demodatenbank öffnen, SQLCMD-Modus einschalten und ohne zusätzliche Transaktionsbefehle wiederholen. |
| Geplanter Neustart oder Abbruch während der Installation | Den Zustand mit der Versionsabfrage prüfen und die konkrete Ursache beheben; anschließend den unterstützten Repeat in einer frischen Sitzung verwenden. Ein vollständiges automatisches Rollback wird nicht zugesagt. |

Notiere bei einer Rückfrage Paketname, verwendete Modulversion und den
abstrahierten Fehler. Zugangsdaten, Servernamen und reale Ausgaben bleiben privat.

## Weitere Module und Installationswege

| Dein Ziel | Passende Anleitung |
|---|---|
| Nur ausgewählte T-SQL-Module installieren | [Repository-Deployment mit Modulauswahl und PlanOnly](Deployment/README.md). Dieser zusätzliche Weg benötigt PowerShell 7 und für die Ausführung `sqlcmd`. |
| Zentrale gemeinsame Installation | [Lokales und zentrales Deployment](Documentation/Architecture/DEPLOYMENT_MODEL.md). Der Paketroot enthält zusätzlich `Install-Stable-central.sql`; verwende den Ablauf oben mit einer zusätzlichen neuen Datenbank `ToolbeltCentralDemo` und dieser Datei. Das Beispiel unter der Tabelle zeigt den anschließenden Aufruf aus einer anderen Testdatenbank. |
| DTSX-/SSIS-Pakete debuggen | [Fertiges SSIS-Windows-Installationspaket](Modules/toolbelt.tsql.ssis-debug/InstallPackages/README.md), einschließlich Parser, ScriptDom, ResultTable, exaktem Assembly-Trust und vollständigem SSMS-Beispiel. |
| Weitere Preview-/CLR-Module ausprobieren | [Fertige CLR-DLLs ohne eigenen Build installieren](Releases/1.0.0/CLR-INSTALL.md). Das zusätzliche ZIP enthält zwölf Toolbelt-DLLs, ScriptDom, Quellcode und SQL-Dateien mit eingebetteten Assemblybytes. Windows-/Portable- sowie lokale/zentrale Profile beachten; Preview- und Supportgrenzen bleiben in der [Freigabematrix](Releases/1.0.0/FREIGABEMATRIX.md) sichtbar. |
| In einer bestehenden oder produktiven Datenbank installieren oder aktualisieren | [Deployment- und Migrationsgrenzen](Deployment/README.md) mit der Administration prüfen. Der Demoweg ersetzt weder Backup-/Upgradeplanung noch modulbezogene Rechte- und Supportabnahme. |
| Den Paketstand als Maintainer prüfen oder neu bauen | [Releasevorbereitung und Gatebericht](Releases/1.0.0/README.md). Dort stehen Quellbindung, vollständige Integritätsprüfung und noch offene Freigaben. |

Für den zentralen Demoweg installierst du ausschließlich in die neue
`ToolbeltCentralDemo`. Ein lokaler Installationsmodus wird nicht durch
Ausführen der anderen Datei automatisch umgestellt. Nach erfolgreicher
zentraler Installation kannst du in deiner anderen Testdatenbank aufrufen:

```sql
SELECT Value
FROM [ToolbeltCentralDemo].toolbelt_core.TVF_GenerateSeriesInt(1, 5, 1)
ORDER BY Value;
```

Erwartet sind wieder die Werte `1` bis `5`. Berechtigungen und unterstützte
Consumerpfade gelten weiterhin je Modul.

## Den eigenen Demotest aufräumen

Wenn `ToolbeltDemo` ausschließlich für diese Anleitung neu angelegt wurde
und du keine ihrer Inhalte mehr brauchst, kannst du **genau diese eigene
Demodatenbank** entfernen. Schließe zuerst die Abfragefenster, die mit ihr
verbunden sind. Klicke dann im Objekt-Explorer mit der rechten Maustaste auf
`ToolbeltDemo` und wähle **Löschen / Delete**. Kontrolliere vor der Bestätigung
Namen und Inhalt; das entfernt
auch alle später dort angelegten Daten. Eine Datenbank mit anderen Inhalten
bleibt bestehen.

Für die Entfernung einzelner Module gelten stattdessen deren
`Deployment/Uninstall.sql` und Dependency-/Consumerregeln. Der Toolbelt
entfernt keine andere Datenbank automatisch.

Die [Lizenz](LICENSE.md), [Freigabematrix](Releases/1.0.0/FREIGABEMATRIX.md)
und [offenen Releasegates](Releases/1.0.0/RELEASE-GATES.md) gelten unverändert.
