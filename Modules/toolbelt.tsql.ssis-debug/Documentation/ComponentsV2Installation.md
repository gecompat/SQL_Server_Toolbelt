# Komponenten V2 getrennt installieren und testen

Der unveröffentlichte V2-Kandidat ergänzt SSIS-Debug um Versionsdefaults,
Row Count, Flatfile-Projektionen und parametrierbare Ressourcenbudgets.
Die Modulversion bleibt 1.0.0; exakte Artefakthashes unterscheiden V1 und V2.

## Installation

Die [ZIP-Anleitung](../InstallPackages/README.md) beschreibt das vollständig
getrennt zu entpackende Archiv
`SSIS-Debug-ComponentsV2-1.0.0-Install-Windows.zip`. Im Paket führt
`START-HERE.txt` zur Offlineprüfung und zur bestehenden
[Installationsanleitung](../Examples/Installation/README.md).

Alternativ enthält der
[reine T-SQL-Installer](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/SSIS-COMPONENTS-V2-INSTALL-TSQL.sql)
die drei benötigten DLLs und die abhängigen SQL-Objekte vollständig.
Die [Provenienz](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/ssis-components-v2-standalone-installer.json)
bindet ihn an das separat geprüfte Paket; Lizenz und Third-Party-Hinweise
stehen daneben im Releaseverzeichnis.

Es gelten die bestehenden
[Installer-Voraussetzungen](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/SSIS-INSTALL-TSQL.md#voraussetzungen-und-grenzen):
Windows SQL Server 2019 oder neuer, bereits aktivierte CLR, eingeschaltete
Strict Security, vorhandene Benutzerdatenbank und frische Sitzung ohne
Caller- oder implizite Transaktion. Der Installer ändert keine
Serverkonfiguration und vergibt keine Rechte. Exakter Assembly-Trust wird
vorausgesetzt; der optionale administrative Registrierungszweig bleibt
außerhalb der nativen Installertestabnahme.

Den gesamten Inhalt in einer frischen SSMS-Verbindung zur gewählten
Testdatenbank ausführen. `@DeploymentMode` steht auf `local` und darf für
den bestehenden zentralen Modus auf `central` geändert werden. Der einzelne
Batch benötigt weder SQLCMD-Direktiven, `GO`, PowerShell noch Dateien auf dem
Datenbankserver. Die Installation ist nicht global atomar: Bei späteren
Fehlern können bereits abgeschlossene Modulstufen bestehen bleiben.

## V2 auswählen und Ergebnisse nutzen

Ein bisheriger Aufruf bleibt im V1-Profil. Für V2 mit Standardbudget
`large10x` reicht `@ProjectContext = N'{"schemaVersion":2}'`.
Für unbegrenzte veränderbare Ressourcenbudgets:

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @b,
    @ProjectContext = N'{"schemaVersion":2,"resourceOptions":{
        "schemaVersion":1,"preset":"unlimited"}}';
```

Einzelne Grenzen sind über `limits` als positive Int64-Zahl oder als
`"unlimited"` wählbar. Feste Tiefen-, Protokoll-, Berechtigungs- und
SQL-Sicherheitsgrenzen bleiben bestehen. Die
[API-Anleitung](USP_ExplainSsisDataFlow.md) erklärt Vorlagen, Artefakte,
Planreihenfolge, Ergebnisinterpretation und Bereinigung. Alle Zähler stehen
im [V2-Vertrag](../../../Documentation/Architecture/SSIS_COMPONENTS_V2_CONTRACT.md).

Row Count liefert den getrennten Zählwert zur materialisierten Projektion.
Flatfile-Unterstützung nutzt Metadaten und ausdrücklich bereitgestellte
SQL-Zeilenbestände. Sie liest oder schreibt keine Dateien und führt kein
SSIS-Paket aus. Die [Prüfmatrix](../Tests/README.md) trennt neue Nachweise von
historischen V1-Builds und weiterhin offenen Gates.

## Begrenzte native Qualifikation

Das separate [V2-ZIP](../Tests/Qualification/ComponentsV2.InstallPackage.20261028.json)
bestand zwei native Windows-Paketfälle mit 1190 Assertions und zwei
unabhängigen Cleanup-Audits. Der getrennte [Standalone-T-SQL-Installerbericht](../../../Releases/1.0.0/ssis-components-v2-standalone-installer-runtime-qualification.json)
bindet zwei Zielkontexte auf SQL Server 2019/CL150 und 2025/CL170, jeweils
local und central, mit vier V2-Opt-in-Prüfungen und zwei unabhängigen Audits.
Die [Provenienz](../../../Releases/1.0.0/ssis-components-v2-standalone-installer.json)
bindet Installer, ZIP und ZIP-Qualifikation. Diese begrenzten Windows-Fälle
qualifizieren weder die vollständige Plattform-/Engine-Matrix noch Head-/Main-CI,
authentifiziertes TLS oder eine Veröffentlichung. Das `integration_binding`-
Objekt im Runtimebericht dokumentiert die eng begrenzte CRLF→LF-Integration der
beiden Qualifikations-JSONs; ursprüngliche native Eingabepins und Installerbytes
bleiben unverändert.
