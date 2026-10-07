# Repository-weites Deployment

`Deploy-All.ps1` führt alle aktuellen `Modules/*/Deployment/Deploy.sql`-Skripte aus. Die Reihenfolge wird deterministisch aus den `module.yaml`-Dependencies berechnet. Module außerhalb von `Modules/` (zum Beispiel Spikes) sind nicht enthalten.

Mit `-ModuleId` lassen sich ein oder mehrere Module auswählen. Ihre transitiven
Manifest-Abhängigkeiten werden automatisch ergänzt und in derselben
deterministischen Reihenfolge ausgeführt. Ohne `-ModuleId` bleibt der
Gesamtdeployment-Modus unverändert.

```powershell
pwsh -File .\Deployment\Deploy-All.ps1 `
  -DeploymentMode local `
  -ModuleId toolbelt.metadata.table-clone `
  -PlanOnly
```

Der Plan zeigt auch automatisch ergänzte Abhängigkeiten und deren fehlende
SQLCMD-Eingaben. Eine Modulauswahl ersetzt nicht die modulbezogenen
Server-, Plattform-, Versions-, Rechte- oder CLR-Preflights.

Vor einer Verbindung kann der Plan einschließlich der pro Modul erforderlichen SQLCMD-Eingaben angezeigt werden:

```powershell
pwsh -File .\Deployment\Deploy-All.ps1 -DeploymentMode local -PlanOnly
```

Ein Deployment benötigt PowerShell 7, `sqlcmd` im `PATH`, eine Zielinstanz und eine Ziel-Datenbank. `DeploymentMode` muss ausdrücklich `local` oder `central` sein.

Mit `-CreateDatabaseIfMissing` prüft der Runner die Datenbank in `master` und
legt sie nur an, wenn sie fehlt. `-PlanOnly` bleibt rein lesend und führt diese
Prüfung nicht aus.

Windows Authentication verwendet das Konto des aktuellen Benutzers:

```powershell
pwsh -File .\Deployment\Deploy-All.ps1 `
  -ServerInstance . `
  -Database Toolbelt `
  -DeploymentMode local `
  -Authentication Windows
```

SQL Authentication verwendet standardmäßig `sa`. Das Passwort wird einmal verdeckt abgefragt und nur über die `SQLCMDPASSWORD`-Umgebungsvariable des gestarteten `sqlcmd`-Prozesses übergeben; es erscheint weder in der Kommandozeile noch in der Ausgabe:

```powershell
pwsh -File .\Deployment\Deploy-All.ps1 `
  -ServerInstance . `
  -Database Toolbelt `
  -DeploymentMode local `
  -Authentication Sql `
  -SqlUsername sa `
  -CreateDatabaseIfMissing
```

CLR-Module benötigen ihre aktuellen, separat erzeugten Binary-Eingaben. Mit `-PlanOnly` werden die pro Modul benötigten Variablennamen aufgelistet. Übergib sie als Hashtabelle über `-ModuleVariables`; beispielsweise enthält `toolbelt.tsql.script-parser` `AssemblyBits` und `ScriptDomAssemblyBits`. Die Großschreibung der Variablennamen ist bei Prüfung und Ersetzung gleichermaßen unerheblich. Binary-Werte müssen vollständige `0x`-präfixierte Hex-Literale sein; SHA2-512-Erwartungswerte müssen `0x` und genau 128 Hex-Zeichen enthalten. Fehlende oder falsch formatierte Eingaben brechen vor der ersten Serververbindung ab.

Der Runner erzeugt keine CLR-Binaries und ändert keine Serverkonfiguration, Trust-Einträge oder Berechtigungen. Solche Voraussetzungen müssen gemäß den jeweiligen Modulregeln separat vorbereitet sein. Jedes Modul führt weiterhin sein eigenes Deployment-Preflight aus. Ein Fehler stoppt die Sequenz; zuvor erfolgreich installierte Module werden nicht zurückgerollt. Die Modul-Deployments sind für Wiederholung ausgelegt und können nach Behebung der Ursache erneut gestartet werden.
