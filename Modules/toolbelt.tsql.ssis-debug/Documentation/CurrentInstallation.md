# Aktuellen SSIS-Debug-Stand installieren und verwenden

Das SSIS-Modul ist nicht als unterstützte Modulversion veröffentlicht. Es verwendet den aktuellen
Komponentenumfang ohne Versionsschalter. Historische V1-/V2-Dateien sind keine
Lieferung dieses API-Standards. Der fachliche Vertrag steht in
[SSIS_CURRENT_API_CONTRACT.md](../../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md).

## Prozedurdefinition V1 installieren

Für den neuen 40-Parameter-Stand mit `procedure-definition` verwende das
[qualifizierte Installations-ZIP](../InstallPackages/SSIS-Debug-Qualified-Install-Windows.zip).
Entpacke es, prüfe die [ZIP-Prüfsumme](../InstallPackages/SSIS-Debug-Qualified-Install-Windows.zip.sha256)
und folge für lokale Installation der [Installationsanleitung](../Examples/Installation/README.md)
für die drei enthaltenen Module. Die [aktuelle Gesamtabnahme](../Tests/Qualification/Current.Build.20261104.json)
trennt neue Prüfungen und die Anwendbarkeit früherer Windows-/CL-Kontexte.
Das Paket korrigiert den Abbruch bei Materialisierungsfehlern der erzeugten
Prozedur. Bereits installierte Definitionen müssen aus diesem Build neu
erzeugt und nach ihrem eigenen Ownership-/Versionsnachweis ersetzt werden.
Die [Objektreferenz](USP_ExplainSsisDataFlow.md#geprüften-zielpfad-als-prozedur-wiederverwenden)
zeigt den anschließenden Generator- und Prozeduraufruf.

## Qualifizierter Installationsumfang

| Windows SQL Server | Geprüfter Patch | Compatibility Levels | Installationsmodi |
|---|---|---|---|
| 2019 | CU32 | 150 | lokal und zentral |
| 2022 | CU26 | 150, 160 | lokal und zentral |
| 2025 | CU8 | 150, 160, 170 | lokal und zentral |

Die Abdeckung setzt die ursprüngliche zwölfteilige Paketmatrix, deren
unveränderte normalen Zweige und aktuelle native Brücken auf allen drei
Engines zusammen. Der korrigierte Fehlerpfad und die Typgrenzen sind auf
SQL2019/CL150 lokal, SQL2022/CL160 zentral und SQL2025/CL170 lokal geprüft.
Eine neue zwölfteilige Ausführung des korrigierten ZIPs wird nicht behauptet.
Neue native Fälle prüfen eigene Ressourcen und erhalten einen frischen
Windows-Abschlussaudit. Details und die Trennung der Originalausführungen
stehen in der [Prüfmatrix](../Tests/README.md#gesamtabnahme-des-korrigierten-builds).

## Zentrale Installation und Consumer-Datenbank

Installiere ResultTable, Parser und SSIS-Debug aus dem geprüften Paket in
derselben zentralen Moduldatenbank. Verwende dafür die vorhandenen
Deployment-Dateien mit `DeploymentMode=central`. Die
[ResultTable-Datei](../../toolbelt.core.result-table/Deployment/Deploy.sql)
benötigt SQLCMD und das eigene Deployment-Verzeichnis als Arbeitsverzeichnis.
Für Parser und SSIS-Debug enthält das ZIP bereits die vollständigen Dateien
`Artifacts/Deploy.WithAssembly.sql`. Die vorher geprüften Trustfreigaben und
Administrationsrechte gelten wie in der lokalen Installationsanleitung.
`Install-Local.ps1` führt die lokale Variante aus.

In der Consumer-Datenbank liegen die Quelldaten und die erzeugte
Debugprozedur. Installiere dort den ResultTable-Helper im lokalen Modus.
Rufe den Generator aus dieser Datenbank über den dreiteiligen Namen auf,
beispielsweise `ContosoToolbelt.toolbelt_tsql.USP_ExplainSsisDataFlow`.
`CatalogBindings.defaultDatabase`, die freigegebenen Datenbanken und die
Connection-Zuordnung verweisen auf die Consumer-Datenbank. Prüfe die
erzeugte Definition und führe ihre DDL ebenfalls dort aus. Die anschließenden
Prozeduraufrufe und Quellrechte gelten in dieser Datenbank.

## Installation der bisherigen Paketstände

Der vorherige Source-Build mit vollständiger Parameterhilfe liegt im
[Parameter-Help-Paket](../../../Releases/1.0.0/PARAMETER-HELP.md). Dessen Anleitung
erklärt Neuinstallation, die getrennte administrative Trustfreigabe und die
Kontrolle der installierten Hilfe. Die zugehörigen Funktionsnachweise bleiben
an diesen Build und seine Modulartefakte gebunden.

Der eigenständige SSIS-Installer enthält denselben fachlichen Kern mit älteren
Hilfetexten. Seine bisherigen Nachweise bleiben an genau diese Dateien gebunden;
er wird durch neue Tests nicht rückwirkend zu einem anderen Build.
Die reine T-SQL-Datei heißt
[`SSIS-INSTALL-TSQL-CURRENT.sql`](../../../Releases/1.0.0/SSIS-INSTALL-TSQL-CURRENT.sql).
Er enthält die drei benötigten DLLs und die abhängigen SQL-Objekte; zur
Ausführung sind weder SQLCMD noch weitere Dateien erforderlich. Die Datei in
einer frischen Sitzung in der gewünschten Datenbank vollständig ausführen.
Vorausgesetzt werden Windows SQL Server 2019/2022/2025 mit CL150/160/170,
aktivierte CLR und weiterhin eingeschaltetes `clr strict security` sowie
vorhandene Installations- und vollständige Metadatenrechte.
Die Einstellungen nach dem Lizenzblock wählen `@DeploymentMode = N'local'`
oder `N'central'`. `@RegisterAssemblyTrust = 0` erwartet bereits administrativ
freigegebene **exakte** DLL-Hashes. Bei `TBX_SSIS_INSTALL_TRUST_MISSING` muss
die Administration den enthaltenen Build freigeben. Wer mit vorhandenen
`sysadmin`-Rechten diese exakten Assemblies bewusst registrieren möchte,
kann dazu den vorhandenen Opt-in `@RegisterAssemblyTrust = 1` verwenden.
Dieser administrative Opt-in ist vom funktionalen Installationsnachweis
getrennt und wurde darin nicht ausgeübt.
Die enthaltenen Trust-, Eigentums-, Transaktions- und Sitzungsprüfungen gelten
auch hier. Zusätzliche Serverrechte werden nicht automatisch vergeben.

Alternativ enthält das
[aktuelle ZIP](../InstallPackages/SSIS-Debug-Current-Install-Windows.zip)
Artefakte, Quellen, Lizenztexte und gebundene Qualifikationsnachweise.
Neuinstallation und Wiederholung desselben aktuellen Stands werden getrennt
geprüft. Eine ältere inkompatible Entwicklungsinstallation muss vor der
Neuinstallation kontrolliert entfernt werden; der Installer darf keine fremden
Objekte übernehmen. Die historischen Installer bleiben unverändert erhalten.
Die Installation hat getrennte Modulstufen. Scheitert eine spätere Stufe,
bleiben bereits erfolgreich installierte frühere Module erhalten; die Datei
behauptet keine gemeinsame Transaktion über alle Module.

## Parameter ermitteln, bearbeiten und zurückgeben

`@PackageBytes` ist der Binärinhalt genau eines unterstützten DTSX-Pakets.
Die Prozedur liest selbst keine Datei. Auch ein bereits vorhandener
`nvarchar(max)`-XML-Wert kann mit `CONVERT(varbinary(max), @PackageXml)`
übergeben werden.

```sql
-- @PackageBytes enthält das zu untersuchende Paket.
CREATE TABLE #Bindings(Placeholder int);
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Operation = 'bindings-template',
    @ResultTable = '#Bindings';

DECLARE @Bindings nvarchar(max) =
    (SELECT Content FROM #Bindings WHERE ArtifactKind = 'BindingsTemplate');
SELECT @Bindings AS EditierbareVorlage;

SELECT [key], [name], sqlType, defaultAvailable, defaultValue,
       valueOrigin, assignmentState
FROM OPENJSON(@Bindings, '$.availableInputs') WITH (
    [key] nvarchar(128), [name] nvarchar(512), sqlType nvarchar(128),
    defaultAvailable bit, defaultValue nvarchar(max),
    valueOrigin nvarchar(128), assignmentState nvarchar(128)
);
```

Die vollständige JSON-Vorlage enthält `availableInputs` und editierbare
`values`. Vorhandene nicht sensitive Entwurfswerte werden mit Herkunft
ausgewiesen. Sie sind keine Messung tatsächlicher Laufzeitwerte. Ausdrücke,
bekannte Zuweisungen und unbekannte Schreibeffekte bleiben erkennbar. Fehlende
Werte werden nicht erfunden; sensitive Werte werden nicht vorbelegt.

Nur `values` bearbeiten und anschließend die **vollständige Vorlage** als
`@Bindings` übergeben. Ein numerischer Wert muss auch im JSON numerisch bleiben;
Boolean, Zeichenfolge und `null` entsprechend ihrem ausgewiesenen Typ setzen.
Paket-/Kontextbindung und Eingabemetadaten unverändert lassen. Wird ein anderer
`@ProjectContext` verwendet, dafür eine neue Vorlage erzeugen.

```sql
-- Beispiel nach Auswahl eines tatsächlichen Schlüssels aus availableInputs:
-- SET @Bindings = JSON_MODIFY(@Bindings, '$.values."<ausgegebener Schlüssel>"', 123);
CREATE TABLE #Explain(Placeholder int);
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Bindings = @Bindings,
    @CatalogBindings = @CatalogBindings,
    @ResultTable = '#Explain';

SELECT TargetFlowId, IsComplete, IsExecutable, Content, DetailsJson
FROM #Explain
WHERE ArtifactKind = 'DebugScript'
ORDER BY Ordinal;
```

`@CatalogBindings` ist die ausdrücklich erlaubte Zuordnung der Paketverbindungen
zu Datenbanken derselben Instanz. Sie enthält keine Zugangsdaten und wird nicht
aus einer fremden Umgebung übernommen. Die Felder und Flatfile-Zuordnungen sind
in der [Prozedurbeschreibung](USP_ExplainSsisDataFlow.md) erklärt. Ohne benötigte
Zuordnung bleibt der betroffene Pfad als unvollständig gekennzeichnet.

## Debug-SQL und fehlende Werte

`DebugScript.Content` enthält für ein vollständig auflösbares Ziel die geordnete
Vorbereitung, Planeinheiten, Ziel-/Row-Count-Projektion und Bereinigung. Das
Script verwendet `GO` zwischen den Batches und läuft in einer frischen Sitzung
auf der ausdrücklich zugeordneten Instanz. Bei einem Vorbereitungsfehler keine
Ergebnisbatches ausführen; die zugehörigen `CleanupSql`-Batches in derselben
Sitzung verwenden. Es gibt keine globale Atomaritätszusage.

`Workflow`, `StageIndex` und `ColumnLineage` zeigen Ablauf, Vorgänger und
Spaltenherkunft; `PreparationSql`, `PlanUnitSql`, `TargetSql`, `RowCountSql` und
`CleanupSql` bleiben einzeln verfügbar. Die Analyse führt dieses SQL nicht aus.
Das erzeugte Debug-SQL liest ausschließlich die explizit zugeordneten Quellen;
Flatfile-Ziele werden als lesende Projektion dargestellt, keine Datei wird
geschrieben und kein SSIS-Task gestartet.

Die zusätzliche [Snapshot-Kohärenzqualifikation](../Tests/Qualification/Current.SnapshotCoherence.20261030.json)
prüft Windows SQL Server 2025/CU8/CL170 lokal und zentral. Eine Quellzeile wird
erst nach Materialisierung aller Planeinheiten und vor den ersten Lese-Batches
eingefügt: Der ausgegebene Ziel-/Row-Count-Snapshot bleibt bei zwei Zeilen,
ein neu ausgeführter Plan sieht drei. Das ist kein Transaktions-Snapshotversprechen
für voneinander unabhängige Quellen oder ungeplante parallele Änderungen,
insbesondere während der Planeinheiten.

Bei einem unvollständigen Ziel enthält `DebugScript.DetailsJson` den gesamten
Strukturpfad, die Erstursache, fehlende Eingabeschlüssel und verfügbare Teilpläne.
`IsExecutable = 0` ist verbindlich. Ein fehlender Command-Text muss als
Debugwert bereitgestellt werden; die Analyse kann unbekannten Laufzeitcode
nicht zuverlässig erfinden.

## Grenzen direkt als SQL-Parameter

Für Limits gibt es **keine JSON-Konfiguration**. `@MaxPackageBytes`,
`@MaxComponents` und die weiteren in `@Hilfe = 1` aufgeführten `@Max`-Parameter
sind benannte `bigint`-Parameter. Positiv setzt die jeweilige Obergrenze,
`0` öffnet diesen konfigurierbaren Zähler nach oben; `NULL` und negative Werte
werden abgewiesen. Die Analysezeit ist standardmäßig offen. Caller-Timeouts und
feste Parser-, Tiefen-, Sicherheits- und Ownershipgrenzen bleiben wirksam.

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Bindings = @Bindings,
    @CatalogBindings = @CatalogBindings,
    @MaxComponents = 0,
    @MaxPackageBytes = 0;

EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe = 1;
```

## Qualifizierter Installationsumfang

Der aktuelle Repository-Stand des getrennten
[SSIS-Trustskripts](../Tests/InstallerTrust/README.md) ist mit dem unveränderten
heutigen Binary auf Windows SQL2019/2022/2025 qualifiziert: 54 Assertions und
drei unabhängige Audits. NULL sowie leere und überlange Literale werden vor
einem Eintrag abgewiesen. Das ersetzt keine vollständige Windows-Anmeldung
des Installationsbeispiels. Das öffentliche `PrepareServer.sql` ist inzwischen
[separat auf allen drei Windows-Versionen geprüft](../Tests/WindowsClientRecovery/README.md):
54 Assertions und drei frische Audits. Sein Pending-Guard berücksichtigt die
dokumentierten impliziten Speicherdefaults und verweigert echte ausstehende
Änderungen weiterhin. `Install-Local.ps1` liest Release-SQL ausdrücklich als UTF8.
Der [Windows-Installer-/CLI-Nachweis](../Tests/Qualification/InstallerClient.Windows.20261101.json)
belegt auf SQL2025/CU8, CL150 auch öffentliche Vorbereitung und Erst-/
Wiederholungsinstallation unter NTLM, aktuelle API sowie vollständige
DebugScript-Ausführung mit zehn Assertions und frischem Windows-Abschlussaudit.
Sein späterer SSMS-Handshake scheiterte vor der ersten GUI-Abfrage; der
Gesamtkoordinator bleibt `FAILED_CLEANED`. Der vollständige Windows-/SSMS-
Scripttransport bleibt ein eigenes Abnahmekriterium. Ältere
ZIP-/Standalone-Nachweise bleiben an ihre unveränderten Lieferbytes gebunden.

Die [Current-ZIP-Matrix](../Tests/Qualification/Current.InstallPackage.Matrix.20261029.json)
und die separate [Standalone-T-SQL-Installer-Matrix](../../../Releases/1.0.0/ssis-current-standalone-installer-matrix.json)
belegen den festen aktuellen Lieferstand auf Windows SQL2019/CL150,
SQL2022/CL150 und CL160 sowie SQL2025/CL150, CL160 und CL170, jeweils local
und central. Die ZIP-Matrix besteht aus zwei unverändert übernommenen und zehn
zusätzlichen Installationsfällen; die Standalone-Matrix aus vier unverändert
übernommenen und acht zusätzlichen Fällen. Beide Nachweise sind auf ihren
beschriebenen synthetischen Vertragsumfang begrenzt und behaupten keine
allgemeine Vollständigkeit aller SSIS-Komponenten oder APIs. Die separate
[aktuelle Funktionsabnahme](../Tests/Qualification/Current.Functional.20261031.json)
qualifiziert den freigegebenen Debugvertrag mit 12.396 Assertions. Die
[Anmeldeabnahme](../Tests/Qualification/Current.Access.Windows.CL.20261031.json)
ergänzt 1.596 Assertions für Lowpriv-Cross-DB-Identitäten und Windows-Ausführung
sowie eine sichtbar geprüfte SSMS-SQL-Anmeldung. Sie behauptet keine
Windows-Anmeldung in SSMS und keinen erfolgreichen GUI-Gesamtkoordinator.
Der aktuelle Debugvertrag ist auf Windows funktionsqualifiziert; das Modul
bleibt unveröffentlicht. Head-/Main-CI und Integration werden getrennt am
jeweiligen PR-/Merge-Head nachgewiesen. Die separate
[authentifizierte TLS-Abnahme](../Tests/Qualification/Current.AuthenticatedTls.Windows.20261031.json)
bestand auf Windows/Hyper-V SQL2025 RTM, CL170, local/central mit 412 Assertions,
signiertem V2-Snapshot und unabhängigem Cleanup-Audit. Tatsächliche
SSIS-Paketausführung bleibt eine separate Grenze.

Die konkrete qualifizierte Plattform-/CL-/Modusauswahl sowie verbleibende
Analysegrenzen stehen in der [Prüfmatrix](../Tests/README.md). Funktionale
Labprüfungen belegen keine authentifizierte TLS-Verbindung, tatsächliche
SSIS-Paketausführung oder Veröffentlichungsfreigabe.
