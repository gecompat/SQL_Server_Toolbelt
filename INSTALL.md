# Toolbelt installieren und zum ersten Mal verwenden

Diese Anleitung verwendet den **gemeinsamen aktuellen Installer mit Dokumentationsstand
vom 18. November 2026**. Er enthält fertige SQL-Skripte und eingebettete DLLs; ein eigener Build
ist nicht nötig. Er ist ein Entwicklungssnapshot für eine
**leere, ausdrücklich ausgewählte Testdatenbank**, kein allgemeines Upgrade
einer bestehenden Installation und keine Produktionsfreigabe aller Module.

## 1. Lokal oder zentral und das passende Profil wählen

**Lokal** installiert Toolbelt in der jeweiligen Anwendungs-/Testdatenbank.
**Zentral** installiert Toolbelt in einer separaten Datenbank derselben Instanz,
beispielsweise `Toolbelt`. Die Wahl bezeichnet den Installationsort der
SQL-Objekte, nicht den Rechner, auf dem SSMS läuft.

| Betriebssystem des SQL Servers | Lokal | Zentral |
|---|---|---|
| Windows | `Install-Windows-local.sql` — 45 Module | `Install-Windows-central.sql` — 43 Module |
| Linux | `Install-Portable-local.sql` — 41 Module | `Install-Portable-central.sql` — 41 Module |

Portable enthält weder Windows Filesystem noch ZIP Files, ScriptParser oder
SSIS. Bei zentraler Windows-Installation entfallen Windows Filesystem und
ZIP Files. SSIS benötigt das Windows-Profil. SSMS auf einem Windows-Client
kann auch einen Linux-SQL-Server bedienen.

Bei zentraler Nutzung müssen Anmeldezuordnung, Aufrufrechte und der jeweilige
Cross-Database-Vertrag passen. Ein zentraler Aufruf erhält nicht automatisch
Zugriff auf Tabellen oder temporäre Objekte einer anderen Datenbank.
Das [Deployment-Modell](Documentation/Architecture/DEPLOYMENT_MODEL.md)
erklärt diese Grenzen. Für eine schon belegte Anwendungsdatenbank zunächst den
[modulweisen Deploymentweg](Deployment/README.md) und deren Lifecycle prüfen.

## 2. Voraussetzungen bereitstellen

| Voraussetzung | Was vor dem Start erfüllt sein muss |
|---|---|
| SQL Server | Laufende SQL-Server-Instanz 2019, 2022 oder 2025 unter der gewählten Plattform; bekannte Anmeldedaten und eine leere Zieldatenbank. |
| SQL-Rechte | Vorhandene Installationsrechte für die gelieferten Schemas, Objekte und Assemblies. Für den administrativen Testweg ein bereits bereitgestelltes geeignetes SQL-Konto verwenden. Windows-Administratorrechte allein sind keine SQL-Server-Rechte. |
| CLR | `clr enabled` muss wirksam `1` sein. Die Administration bereitet die Konfiguration vor; der Installer aktiviert CLR nicht. |
| Sicherheitszustand | `clr strict security` bleibt `1`; `TRUSTWORTHY` der Zieldatenbank bleibt `OFF`. |
| Assembly-Trust | Die mitgelieferten exakten Assemblyhashes müssen auf der Zielinstanz bewusst administrativ autorisiert werden; siehe Schritt 4. |
| Client | SSMS mit aktiviertem SQLCMD-Modus oder ein geeignetes `sqlcmd`. Für den hier beschriebenen SSMS-Weg ist kein separates `sqlcmd` erforderlich. |

Die DLLs und ScriptDom liegen bereits eingebettet in den Installationsskripten.
Visual Studio, MSBuild, .NET-SDK, Python und Git sind für die Installation nicht
erforderlich. Das Paket legt keine Logins, Aufrufrechte, Windows-Roots oder
Dateirechte an. Funktionen mit Dateien, Workerprozessen oder registrierten
Handlern brauchen später ihre modulspezifische Vorbereitung.

## 3. ZIP prüfen und vollständig entpacken

Lade [den gemeinsamen Installer](Releases/1.0.0/Builds/2026-11-18-78fb8571/SQL-Server-Toolbelt-1.0.0-Current-Install.zip)
und [seine SHA256-Datei](Releases/1.0.0/Builds/2026-11-18-78fb8571/SQL-Server-Toolbelt-1.0.0-Current-Install.zip.sha256)
aus demselben Repositorystand. Auf GitHub jeweils **Download raw file** verwenden.
Prüfe die heruntergeladene ZIP, beispielsweise in PowerShell:

```powershell
Get-FileHash -LiteralPath 'C:\Temp\SQL-Server-Toolbelt-1.0.0-Current-Install.zip' -Algorithm SHA256
```

Die 64 Hashzeichen müssen mit der separaten SHA256-Datei übereinstimmen;
Groß-/Kleinschreibung ist unerheblich. Bei Abweichung nicht installieren.
Danach **Alle extrahieren** wählen. Im Paket liegen `START-HERE.md`, vier
`Install-*.sql`, zwei `Trust-*.sql`, `PACKAGE.json` und `SHA256SUMS`.

`SHA256SUMS` enthält je Zeile den Hash und den relativen Dateinamen, getrennt
durch zwei Leerzeichen. Vergleiche damit die entpackten Dateien. Das lässt
sich aus dem entpackten Paketverzeichnis in PowerShell vollständig prüfen:

```powershell
foreach ($line in Get-Content -LiteralPath '.\SHA256SUMS') {
    $parts = $line -split '  ', 2
    if ($parts.Count -ne 2) { throw 'Ungültige Prüfsummenzeile' }
    $actual = (Get-FileHash -LiteralPath $parts[1] -Algorithm SHA256).Hash
    if ($actual -ine $parts[0]) { throw ('Prüfsumme abweichend: ' + $parts[1]) }
}
'Alle Paketdateien stimmen mit SHA256SUMS überein.'
```

Die äußere ZIP-Prüfsumme muss vorher erfolgreich geprüft sein. Prüfsummen
belegen Integrität, keine digitale Herausgebersignatur. Verwende die Dateien
vollständig und unverändert; keine DLLs aus älteren Paketen dazumischen.

## 4. Verbinden und Assembly-Trust vorbereiten

Verbinde SSMS mit der vorgesehenen **Datenbank-Engine** und der vorhandenen
Anmeldung. Verwende die Verschlüsselungs- und Zertifikatseinstellungen deiner
Umgebung. Toolbelt benötigt kein eigenes TLS-Zertifikat. Ein ausdrücklich
erlaubtes `TrustServerCertificate=True` für ein Testziel ist keine Prüfung
der Serveridentität und wird bei Fehlern nicht automatisch eingeschaltet.

Die Administration führt auf **derselben SQL-Server-Instanz** die passende
Datei einmal bewusst aus:

- Windows-Profil: `Trust-Windows.sql`
- Portable-Profil: `Trust-Portable.sql`

Beide Dateien wählen `master` selbst. Sie registrieren die exakten mitgelieferten
Assemblyhashes, soweit diese noch fehlen. Dieser Schritt ist vom eigentlichen
Deployment getrennt; dafür sind vorhandenes `CONTROL SERVER` oder eine
`sysadmin`-Mitgliedschaft erforderlich. Siehe
[Microsoft: sp_add_trusted_assembly](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-add-trusted-assembly-transact-sql).
Die Installationsskripte vergeben weder diese Rechte noch Trust selbst.

## 5. Das vollständige Installationsskript ausführen

1. Öffne das in Schritt 1 gewählte `Install-*.sql` in SSMS.
2. Stelle die Verbindung zur vorgesehenen Instanz her. Verwende eine frische
   Sitzung ohne offene Transaktion; implizite Transaktionen müssen aus sein.
3. Wähle in der Datenbankliste **ausdrücklich die leere Zieldatenbank**:
   lokal beispielsweise `ContosoAppTest`, zentral beispielsweise `Toolbelt`.
   `master` ist nur das Ziel des vorausgehenden Trustschritts.
4. Aktiviere **Query/Abfrage → SQLCMD Mode/SQLCMD-Modus**.
5. Führe das vollständige Skript aus. `:ON ERROR EXIT` bleibt erhalten;
   keine einzelnen Batches überspringen und keine umschließende Transaktion
   ergänzen. Der Fehlerabbruch ist Teil des Installationsvertrags.

Die Datenbank muss vorher bereitgestellt sein; das Skript wählt oder erzeugt
sie nicht für dich. Für den Kommandozeilenweg gelten die gleichen Bedingungen:
Zieldatenbank ausdrücklich mit `-d`, UTF-8 mit `-f 65001` und Fehlerabbruch
mit `-b` angeben. Anmeldung und Verschlüsselung hängen vom eingesetzten
sqlcmd-Client ab; die [Microsoft-Referenz](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility)
unterscheidet ODBC- und Go-Variante. Passwörter nicht in Skripte schreiben.

**Erwartet:** Das Skript endet ohne SQL-Fehler. Es gibt keine Gesamttransaktion
über alle Module. Bei einem späteren Fehler bleiben früher erfolgreich
installierte Module bestehen; dieser Zustand ist keine vollständige Installation.

## 6. Ersten Aufruf prüfen und Ergebnisse nachschlagen

Öffne eine neue Abfrage in der installierten Datenbank und führe aus:

```sql
EXEC toolbelt_core.USP_BeginExecution @Hilfe = 1;
```

Erwartet wird die API-Hilfe mit Abschnitten und Parameterbeschreibungen. Dieser
Aufruf prüft die Erreichbarkeit und Hilfe dieser API, nicht sämtliche Funktionen.
Bei zentraler Installation kann ein berechtigter Aufrufer beispielsweise verwenden:

```sql
EXEC [Toolbelt].toolbelt_core.USP_BeginExecution @Hilfe = 1;
```

Anwendungsbenutzer brauchen ihre vorhandenen bzw. administrativ bereitgestellten
einzelnen `EXECUTE`-/`SELECT`- und Datenbankzugriffsrechte. Installationsrechte
sind keine erforderlichen Dauerrechte für alle Anwender. Anforderungen und
Seiteneffekte stehen bei der jeweiligen API und ihrem Modul.

Weiter geht es über [Module und Einsatzfälle](Modules/README.md) oder die
[SQL-Objektreferenz](Documentation/Reference/README.md). Wähle dort ein einzelnes
Beispiel, erfülle seine Voraussetzungen und vergleiche das Ergebnis mit dem
Objektvertrag. Die gesamte Beispielsammlung niemals gesammelt ausführen.
Für SSIS beginne mit dem [SSIS-Leitfaden](Modules/toolbelt.tsql.ssis-debug/README.md).

## Wenn etwas nicht funktioniert

| Beobachtung | Prüfung und nächster Schritt |
|---|---|
| Anmeldung scheitert | Instanz, Port, Anmeldeart, Netzwerk und vereinbarte Verschlüsselung prüfen; keine Zertifikatsprüfung als Fehlerumgehung abschalten. |
| Syntaxfehler bei `:ON ERROR` | SQLCMD-Modus aktivieren und das unveränderte vollständige Skript verwenden. |
| CLR deaktiviert oder Assembly nicht vertrauenswürdig | Administration prüft wirksames CLR, passenden Trustschritt auf derselben Instanz und genaue Paketversion; strict security nicht abschalten. |
| Objekt, Version oder Dependency bereits vorhanden/abweichend | Installation stoppen. Bestehenden Datenbankinhalt und Modul-Lifecycle prüfen; dieser Satz ist kein allgemeiner Upgradeweg. |
| Transaktionsfehler zu Beginn | Neue Sitzung ohne offene oder implizite Transaktion verwenden. |
| Zentraler Aufruf scheitert | Datenbanknamen, gemappte Identität, einzelne Objekt-/Datenrechte und den Cross-DB-Vertrag des Moduls prüfen. |
| Erst spätere Module scheitern | Fehlerstelle und Paketversion privat sichern. Bereits installierte Module können bestehen bleiben. Nicht blind erneut starten oder fremde Objekte/Trusteinträge löschen. |
| Funktion mit Dateien oder Worker läuft nicht | Modulanleitung für RootAlias, Identität, Dateirechte oder registrierte Handler beachten; Installation allein stellt diese Ressourcen nicht bereit. |

Bei Unterstützungsbedarf die [Hinweise für Fehlermeldungen](CONTRIBUTING.md)
beachten. Zugangsdaten und reale Ausgaben bleiben privat.

## Paketstand, Nachweise und bestehende Installationen

Die [Installationsabnahme](Releases/1.0.0/CURRENT-INSTALL-QUALIFICATION.md)
belegt zwölf Profile mit sechs frischen Abschlussaudits: SQL2019/CL150,
SQL2022/CL160 und SQL2025/CL170 jeweils Windows/Linux und lokal/zentral.
Das ist keine vollständige fachliche Wiederqualifikation aller Module.

Für vorhandene Installationen gelten die jeweiligen [Modul-Lifecycle-Verträge](Modules/README.md)
und deren Versions-/Hash-/Consumer-Gates. Es gibt keinen pauschalen Repeat-,
Upgrade- oder Deinstallationsweg für diesen gesamten Fresh-Install-Satz.
Vorhandene [ältere Pakete](Releases/README.md#historische-pakete-und-nachweise)
bleiben mit ihren Originalbytes und Nachweisen erhalten. Ein Projektsnapshot
ist von einer unterstützten Modulveröffentlichung zu unterscheiden.
