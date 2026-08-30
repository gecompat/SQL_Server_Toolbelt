# Project Adapter – Console Message

Dieser Adapter implementiert den ADP-008-Piloten des Project-Adapter-Vertrags
0.1 von `SQL_Server_Lab`. Er installiert das vorhandene, versionierte Modul
`toolbelt.core.console-message` 1.0.0 in einer markergebundenen synthetischen
Datenbank, führt ein versionsgleiches idempotentes Update aus, validiert den
Modul- und Help-Vertrag und deinstalliert den Projektzustand wieder.

Die ausführbaren SQL-Dateien `install.sql`, `update.sql` und `cleanup.sql`
werden deterministisch aus den kanonischen Deployment-, Source- und
Uninstall-Dateien des Moduls erzeugt:

```powershell
pwsh -File ./Modules/toolbelt.core.console-message/TestLab/ProjectAdapter/Build-AdapterSql.ps1
```

Das Toolbelt-Repository startet, repariert oder entfernt keine
`SQL_Server_Lab`-Infrastruktur. Der Runner benötigt deshalb einen bereits
bereitgestellten, isolierten Lab-Run und entfernt nur die markergebundene
Adapterdatenbank:

```powershell
$secret = Read-Host 'Temporäres SA-Passwort' -AsSecureString
pwsh -File ./Modules/toolbelt.core.console-message/TestLab/ProjectAdapter/Invoke-OnExistingLab.ps1 `
  -RunId '<run-id>' `
  -StateRoot '<lab-state-root>' `
  -SaPassword $secret `
  -LabRepositoryRoot '../SQL_Server_Lab'
```

Provider-Provisionierung und Infrastruktur-Cleanup bleiben vollständig beim
Lab-Projekt. Der Adapter enthält keine Providerlogik, keine Zugangsdaten und
keine realen Runtime-Ausgaben. `-KeepProjectStateOnFailure` erhält nur auf
ausdrückliche Wahl die synthetische Adapterdatenbank zur Diagnose.

Der Update-Entrypoint ist bewusst ein versionsgleiches Redeployment. Für das
Modul existiert kein historischer Upgradepfad; ein solcher wird durch diesen
Piloten weder simuliert noch behauptet.
