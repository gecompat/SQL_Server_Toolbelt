# SSIS Data Flow Debug SELECT

Version 1.0.0 erzeugt aus DTSX-Bytes eine bearbeitbare JSON-Vorlage und lesende
Debug-Scripts für SQL-Server-Datenflüsse. Jede ausgegebene Prüfstufe enthält
ihre `DECLARE`s, alle Vorgänger-CTEs und den abschließenden `SELECT`.

Der [neutrale Modellaustausch mit Analyze](Exchange/README.md) verwendet
denselben typisierten Kern und einen externen .NET-Host. Analyze verarbeitet
das Modell ohne CLR- oder Toolbelt-Installation. Die bestehenden
Debug-SELECT-Schnittstellen bleiben erhalten.

Die verbindliche Semantik steht im
[V1-Vertrag](../../Documentation/Architecture/SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md).
Die [API-Beschreibung](Documentation/USP_ExplainSsisDataFlow.md) zeigt den
SSMS-Aufruf. [Testumfang und offene Gates](Tests/README.md) sind getrennt
ausgewiesen. Das Modul ist teilweise validiert und unveröffentlicht.

Das [vollständige SSMS-Beispiel](Examples/README.md) mit
[`SsmsDebugWalkthrough.sql`](Examples/SsmsDebugWalkthrough.sql) und synthetischer
DTSX-Fixture zeigt Import, JSON-Vorlage, Werteänderung, Stufenauswahl und direkte
DECLARE-Änderungen einschließlich erwarteter Ergebnisse und Cleanup.

Die [Installationsanleitung](Examples/Installation/README.md) enthält die
SQL-Server-Vorbereitung, einen PowerShell-Installer mit Offline-Artefaktprüfung
und die anschließende Installationskontrolle für Parser, ResultTable und
SSIS-Debug einschließlich des getrennten Assembly-Trust-Opt-ins.

Das [vollständige ZIP-Installationspaket](InstallPackages/README.md) enthält
den bisherigen qualifizierten Artefaktsatz einschließlich DLLs, SQL-/PowerShell-
Skripten und SSMS-Beispiel zum Testen ohne eigenen Build. Der neue gemeinsame
Kern und der Exporthost sind noch nicht in diesem ZIP ausgeliefert; seine
Buildnachweise stehen getrennt in der Prüfmatrix.

Die Analyse führt keine Quellabfrage und kein SSIS-Paket aus. Für die
Dependencyprüfung werden ausschließlich Metadaten derselben SQL-Instanz
gelesen. Connections werden explizit auf Datenbanken abgebildet; Credentials
und Connection Strings gehören in keines der JSON-Dokumente.

Quell-, Referenz- und zulässige Kataloglesezugriffe erhalten `WITH (NOLOCK)`.
Damit können unbestätigte, fehlende oder doppelt gelesene Zeilen auftreten;
Schemasperren bleiben möglich. Vollständige SSIS-Laufzeitgleichheit wird nicht
behauptet. Lookup-Mehrfachtreffer werden über den vollständigen effektiven
Schlüssel reduziert und in sitzungslokalen Temp-Tabellen für weitere
Prüfstufen festgehalten. Eine eigene `CleanupSql`-Zeile räumt sie auf.

Installation: Parser 2.0.1 und Result Table 1.0.0 separat installieren, Release
mit `Scripts/New-ClrReleaseArtifacts.ps1` reproduzierbar bauen, den exakten
Assemblyhash administrativ freigeben und `Artifacts/Deploy.WithAssembly.sql`
im SQLCMD-Modus mit `DeploymentMode=local` oder `central` ausführen. Der
UNSAFE-/Strict-Security-Vertrag wird nicht aufgeweicht. Shared Dependencies
und Trusteinträge werden beim Uninstall nicht entfernt.

Die begrenzten nativen Fachnachweise umfassen Windows SQL Server 2019/2022/2025
jeweils lokal und zentral. Die [Prüfmatrix](Tests/README.md) trennt deren
Buildbindungen und die zusätzlich geprüften echten Upgradepfade. Das Modul
bleibt unveröffentlicht. Seit der Benutzerklarstellung
vom 2026-10-16 verwendet sie `TestPurpose=Functional` mit dem ausdrücklich
gesetzten Trustwert des schema-validierten Labvertrags. Für diese Funktion
ist Serverzertifikatsprüfung keine fachliche Voraussetzung. Die getrennte
authentifizierte TLS-Abnahme bleibt `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-25`
- Nachweis: `local: Invoke-LabContract.ps1 Full je Windows2019/2022 und local/central, echte SSIS-Build-/Parser-/Table-Clone-Upgrades; unabhängige Abschlussaudits`
- Scope: Vier positive native Einzelkontexte mit je181 Kern-,61 API-,15 Lifecycle- und8 SSIS-Buildupgradeassertionen,1060 insgesamt. Tatsächlich ausgelieferter SSIS1.0.0-Binary ersetzt durch den bytegleichen Kandidaten des getrennten SQL2025-Nachweises; Assembly-/Prozeduridentitäten erhalten und alte JSON-Vorlage am neuen Einstieg verwendet. Echte Parser2.0.0→2.0.1-/TableClone4.1.0→4.1.1-Upgrades mit ursprünglicher/aktueller Triggerfixture bestanden. Ein erster Adapterfehler bleibt FAILED_CLEANED; vier positive und ein historischer frischer Cleanup-/Pin-/Konfigurationsaudit PASS. Testadapter vererbt das300/360-Sekunden-Budget in Einzelmodusaufrufen; bestehende Mehrfachmodus-Kommandogrenzen erhalten, sieben Offlinegegenproben. Funktionales TLS ohne Fallback. Kein neuer SQL2025-Upgrade-, Linux-Host-, SDK-Paritäts-, Produktionslast-, Paketlieferungs- oder Veröffentlichungsnachweis.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
