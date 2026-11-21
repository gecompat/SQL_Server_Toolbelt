# Aktuelle Installation: toolbelt.conversion.integer-base

Der gemeinsame [Build-Einstieg](../../../Deployment/Build-Install.ps1) erzeugt
für dieses Modul und seine Pflichtabhängigkeiten eine normale SQL-Datei.

```powershell
& Deployment/Build-Install.ps1 -Inputs .runtime/build-inputs -OutputSqlFile .runtime/Install.sql -ModuleId toolbelt.conversion.integer-base -Platform Windows -DeploymentMode local
```

Den Befehl vom Repositoryroot ausführen. Plattform und Modus gemäß den
Modulgrenzen wählen. In der erzeugten SQL-Datei nur das anfängliche USE ändern;
SQLCMD-Modus ist nicht erforderlich. Alternativ den
[aktuellen Installationsclient](../../../Deployment/ONE-CALL-INSTALL.md) verwenden.

Der Lebenszyklus ist create-only. Bestehende Objekte werden nicht ersetzt oder
pauschal entfernt. Historische Deploy-/Upgrade-/Uninstall-Dateien gehören nicht
zu diesem Weg; ihre Originalbytes bleiben im
[vollständigen damaligen Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/tree/2fbe8e3e86f370b22ad2ce9f9716d971072a052b/Modules/toolbelt.conversion.integer-base/Deployment)
und in den unveränderten Releases erhalten.
