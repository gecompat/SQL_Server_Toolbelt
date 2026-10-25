# CLR-Module ohne eigenen Build installieren

Der [aktuelle SSIS-Paketnachweis](SSIS-RELEASE-QUALIFICATION.md) bindet den neuen
SSIS-Binary an zwölf explizite Windows-Buildkontexte und die aktualisierte
CLR-Lieferung an sechs neue Windows-Paketkontexte. Die übrigen DLLs behalten
ihre qualifizierten Bytes; die unten beschriebene Installation benötigt keinen Build.
Die öffentliche Windows-Anmeldung und SSMS-GUI bleiben separat offen.

Das optionale CLR-Paket enthält alle zwölf bestehenden Toolbelt-CLR-Module
als fertige DLLs, die passende ScriptDom-Dependency, SQL-Installationsdateien,
exakte SHA2-512-Trustwerte, Quellcode und Lizenzhinweise. Es ist ein
unveröffentlichter Installationskandidat. Die Module behalten ihren jeweiligen
Preview- und Prüfstatus; die Paketierung erweitert keine Supportzusage.

## Voraussetzungen und Download

Wenn du das CLR-ZIP bereits vollständig entpackt hast, kontrolliere nur noch
Prüfsumme und Ordnerinhalt und fahre mit der Profilauswahl fort.

Du benötigst eine laufende SQL-Server-2019-/2022-/2025-Testinstanz, SSMS auf
deinem Windows-Rechner und ein vorhandenes administratives SQL-Konto.
Visual Studio, MSBuild, ein .NET-SDK, Python oder ein eigener Build sind für
die Installation nicht erforderlich. SSMS kann auch einen Linux-Server bedienen.

Lade [das CLR-ZIP](InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip)
und [seine Prüfsumme](InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip.sha256)
aus demselben Repositorystand herunter. Im Gesamt-ZIP liegen diese Dateien
unter `Releases/1.0.0/InstallPackages/`. Prüfe die heruntergeladene ZIP in
PowerShell, bevor du sie mit **Alle extrahieren** vollständig entpackst:

```powershell
Get-FileHash -LiteralPath 'C:\Temp\SQL-Server-Toolbelt-1.0.0-CLR-Install.zip' -Algorithm SHA256
```

Die 64 Zeichen müssen mit der Prüfsummendatei übereinstimmen. Bei Abweichung
beide Dateien erneut beziehen. Die Prüfsumme belegt Integrität; sie ersetzt
keine digitale Herausgebersignatur. Im entpackten Ordner liegen `Binaries`,
`SQL`, `Sources`, `ThirdParty`, `CLR-PACKAGE.json` und diese Anleitung.

## Den passenden Installationsweg auswählen

| Profil | Inhalt | Zieldatenbank |
|---|---|---|
| `Windows-local` | Alle zwölf CLR-Module, ScriptDom und ResultTable | Neue eigene Demodatenbank auf Windows |
| `Windows-central` | Elf CLR-Module, ScriptDom und ResultTable; das Windows-Dateisystemmodul ist ausschließlich lokal verwendbar | Neue zentrale Demodatenbank auf Windows |
| `Portable-local` | Neun SAFE-CLR-Module und ResultTable; keine Windows-/UNSAFE-Provider | Neue eigene Demodatenbank auf Windows oder Linux |
| `Portable-central` | Dieselben neun SAFE-CLR-Module und ResultTable | Neue zentrale Demodatenbank auf Windows oder Linux |

Für den ersten Windows-Test verwende `Windows-local` und eine neue Datenbank
`ToolbeltClrDemo`. Auf Linux verwende `Portable-local`. Der portable Name
bezeichnet den abgegrenzten Paketsatz, keine zusätzliche allgemeine Supportfreigabe.

## Schritt für Schritt in SSMS

1. Verbinde SSMS mit deiner Testinstanz. Nutze die vereinbarten verschlüsselten
   Verbindungswerte deiner Umgebung. Eine ausdrücklich erlaubte Einstellung
   **Serverzertifikat vertrauen** verhindert die Fachfunktionen nicht.
2. Prüfe die CLR-Voraussetzung in einer neuen Abfrage:

   ```sql
   SELECT name, value, value_in_use
   FROM sys.configurations WITH (NOLOCK)
   WHERE name IN (N'clr enabled', N'clr strict security');
   ```

   `clr enabled` muss wirksam `1` sein. Falls es `0` ist, lass deine
   Administration CLR bewusst aktivieren und zuvor alle vorgemerkten
   Konfigurationsänderungen prüfen. Die Installationsdateien ändern keine
   Serveroptionen. `clr strict security` bleibt eingeschaltet; `TRUSTWORTHY ON`
   wird nicht benötigt. Assembly-Trust und Verbindungs-TLS sind getrennte Themen.
3. Lege über **Datenbanken → Neue Datenbank** eine neue `ToolbeltClrDemo` an.
   Falls der Name existiert, wähle einen neuen Namen. Setze ausschließlich für
   diese neue Datenbank unter **Eigenschaften → Optionen** den
   Kompatibilitätsgrad auf **SQL Server 2019 (150)**.
4. Öffne `SQL/Trust-Windows-local.sql` beziehungsweise
   `SQL/Trust-Portable-local.sql`. Aktiviere im Fenster **Abfrage → SQLCMD-Modus**
   und führe die gesamte Datei mit **F5** aus. Diese Datei verwendet `master`
   und registriert nur die mitgelieferten exakten Hashes. Bestehende passende
   Trusteinträge werden erhalten. Vorhandene administrative Rechte sind nötig;
   es werden keine Rechte erteilt.
5. Öffne `SQL/Install-Windows-local.sql` beziehungsweise
   `SQL/Install-Portable-local.sql` in einem **neuen** Fenster. Wähle oben die
   eigene `ToolbeltClrDemo`, aktiviere erneut den **SQLCMD-Modus**, kontrolliere
   Server und Datenbank und führe ohne Textmarkierung mit **F5** aus.
   Die SQL-Datei enthält die DLL-Bytes bereits. Du musst keine DLL auf den
   SQL-Server-Rechner kopieren und keinen Server-Dateipfad eintragen.
   Die Datei ist UTF-8; behalte diese Codierung bei, falls SSMS danach fragt.
6. Prüfe nach Ende der Ausführung die Registerkarte **Meldungen**. Anschließend:

   ```sql
   SELECT name, CONVERT(nvarchar(64),value) AS Version
   FROM sys.extended_properties WITH (NOLOCK)
   WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version'
   ORDER BY name;

   SELECT * FROM toolbelt_string.TVF_ColognePhonetic(N'Contoso');
   ```

   Erwartet werden im leeren Windows-local-Test **13 Modulversionen**
   (zwölf CLR-Module plus ResultTable), bei Windows-central zwölf und in den
   portablen Profilen zehn. Das Phonetikbeispiel liefert eine Zeile;
   weitere feste Beispiele und Resultspalten stehen in der
   [Modulbeschreibung](../../Modules/toolbelt.string.phonetic/README.md).

Die übrigen T-SQL-Module kannst du zusätzlich über die
[allgemeine Installationsanleitung](../../INSTALL.md) installieren.
Konfigurationsabhängige Dateioperationen benötigen weiterhin eigene Root-Aliasse,
Windowsidentitäten und Dateirechte. Diese Anleitung erzeugt keine Dateifixtures.

## Wiederholung, zentrale Installation und Aufräumen

Optional kannst du statt SSMS PowerShell 7 und ein vorhandenes ODBC-`sqlcmd`
verwenden. Der optionale Helper prüft vor jedem Tool-/SQL-Zugriff alle
Paketdateien. Standard ist die Windows-Anmeldung des aufrufenden Kontos.
Die Übergabe an ODBC-`sqlcmd` verwendet ausdrücklich UTF-8. Bei mehreren
installierten Versionen wird genau das erste Tool im Suchpfad gewählt;
`-SqlcmdPath` kann stattdessen einen bestimmten vorhandenen Programmpfad
festlegen. Im entpackten Paketroot:

```powershell
pwsh -File ./Install-ClrPackage.ps1 -ValidateOnly
pwsh -File ./Install-ClrPackage.ps1 -ServerInstance localhost -Database ToolbeltClrDemo `
  -Profile Windows-local -RegisterExactTrust
```

Ersetze Server und Datenbank durch die vereinbarten eigenen Testziele.
Wenn deine Umgebung ein vorhandenes SQL-Konto verwendet, fordere dessen
Anmeldedaten interaktiv an und übergib ausdrücklich `-Credential`:

```powershell
$sqlCredential = Get-Credential -Message 'Vorhandenes SQL-Konto für die Testinstanz'
./Install-ClrPackage.ps1 -ServerInstance localhost -Database ToolbeltClrDemo `
  -Profile Windows-local -RegisterExactTrust -Credential $sqlCredential
```

Führe beide Zeilen in derselben PowerShell-7-Sitzung aus. Trage das Passwort
nur im Anmeldedialog ein, niemals im Skript, in einer Befehlszeile oder in
einer Chatnachricht. Der Helper gibt es ausschließlich über `SQLCMDPASSWORD`
an den gestarteten Kindprozess weiter; das Environment der aufrufenden
Sitzung bleibt erhalten. Es werden keine Konten oder Rechte angelegt.
Nach einem Fehler gibt es keinen automatischen Wechsel der Anmeldung,
des Clientprogramms oder der Verbindungsoptionen.

`-TrustServerCertificate` wird nur bei ausdrücklicher Erlaubnis für die konkrete
Verbindung ergänzt; Verschlüsselung bleibt aktiviert. Die PowerShell-Option
`-Action Repeat` wählt die Repeatdatei; für Uninstall ist zusätzlich die
ausdrückliche Option `-ConfirmNoExternalConsumers` erforderlich.

Ein vollständig erfolgreich installiertes Profil lässt sich mit der passenden
`SQL/Repeat-<Profil>.sql` in einer frischen Sitzung wiederholen. Die Repeatdatei
erwartet exakt die bereits installierten mitgelieferten DLLs. Die Installdatei
erwartet für die Module mit Anwesenheitsvertrag eine Erstinstallation.
Für zentrale Installation wählst du das entsprechende `central`-Profil und
eine eigene neue zentrale Datenbank; ein Moduswechsel ist kein Upgradeweg.

Nach einem Teilfehler bleiben zuvor installierte Module erhalten. Suche die
erste Fehlermeldung und behebe die Ursache. Führe auf einem gemischten Teilstand
nicht blind Install oder Repeat erneut aus. Für den Demotest ist eine neue eigene
leere Datenbank der einfachste Neustart; bestehende Installationen benötigen
die modulspezifische Zustands-/Hashprüfung. Keine fremden Objekte löschen.

Für eine modulweise Entfernung enthält `SQL/Uninstall-<Profil>.sql` die
kanonischen Uninstalls in umgekehrter Dependencyreihenfolge. Verwende sie nur,
wenn alle externen Consumer zuvor geprüft und entfernt sind. Diese Dateien
bestätigen diesen Umstand ausdrücklich; sie ermitteln keine fremden Anwendungen.
Trusteinträge bleiben erhalten, da andere Datenbanken dieselben DLLs verwenden
können. Eine Wiederholung nach vollständig erfolgreicher Entfernung verwendet
`SQL/UninstallAbsent-<Profil>.sql`; sie erwartet ausdrücklich abwesende
Assemblies und bewahrt damit den Anwesenheitsvertrag. Alternativ kannst du
ausschließlich deine neu angelegte, nicht mehr
benötigte Demodatenbank nach Kontrolle ihres Inhalts über SSMS löschen.

## Wenn etwas nicht funktioniert

| Meldung oder Beobachtung | Nächster Schritt |
|---|---|
| Syntaxfehler an `:` | SQLCMD-Modus im tatsächlich ausgeführten Fenster einschalten. |
| Windows-Anmeldung oder SSPI scheitert | Das bereits freigegebene Anmeldeverfahren der Umgebung prüfen. Falls ein SQL-Konto vorgesehen ist, in SSMS ausdrücklich SQL-Server-Authentifizierung wählen beziehungsweise dem Helper `-Credential` übergeben. Keine Konten oder Rechte zur Umgehung ändern. |
| CLR ist deaktiviert | Mit der Administration die bewusste CLR-Aktivierung abstimmen; keine Sicherheitsoption zur Umgehung abschalten. |
| `TBX_REGEX_TIMEOUT` | Der Regex-Aufruf wurde am festen Sicherheitsbudget abgebrochen. Eingabe und Pattern prüfen; die [aktuelle Nachprüfung und ihre Grenzen](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/REGEX-TIMEOUT-QUALIFICATION.md) beachten. Ein solcher Fehler ist keine Aufforderung zum Erhöhen des Budgets. |
| Assembly nicht vertrauenswürdig | Den passenden Trustskript durch das bereits berechtigte administrative Konto ausführen lassen. |
| Abweichender installierter Hash oder Anwesenheitszustand | Paketprofil und Erst-/Repeatdatei prüfen; für die erste Erprobung eine neue leere Demodatenbank verwenden. |
| Windows-/UNSAFE-Fehler auf Linux | Das Portable-Profil verwenden; Windows-Provider gehören nicht zu diesem Profil. |
| Dependency-/Consumerabweisung bei Uninstall | Betroffene Consumer anhand der Modulverträge klären; den Guard nicht umgehen. |

`CLR-PACKAGE.json` bindet jede Datei, DLL, Modulzuordnung und jedes Profil an
Hashes und Quellen. Der Compilerquellcode liegt unter `Sources/Modules`,
die unveränderte Deploymentlogik unter `Sources/Deployment`. Die vollständigen
Projektquellen und weiterführenden Dokumente enthält außerdem das Gesamt-ZIP.
Lizenz und ScriptDom-/ANTLR-Attributionen bleiben im Paket enthalten.
Den begrenzten nativen Nachweis des optionalen ODBC-Helfers mit SQL-Anmeldung
beschreibt die [Clientqualifikation](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/CLR-CLIENT-QUALIFICATION.md).
SSMS-GUI und Windows-Anmeldung bleiben dort separat als ungeprüft ausgewiesen.
