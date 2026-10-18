# SSIS Data Flow Debug SELECT

Version 1.0.0 erzeugt aus DTSX-Bytes eine bearbeitbare JSON-Vorlage und lesende
Debug-Scripts für SQL-Server-Datenflüsse. Jede ausgegebene Prüfstufe enthält
ihre `DECLARE`s, alle Vorgänger-CTEs und den abschließenden `SELECT`.

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
den passenden Artefaktsatz einschließlich DLLs, SQL-/PowerShell-Skripten und
SSMS-Beispiel zum Testen ohne eigenen Build.

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

Die begrenzte native V1-Fachmatrix besteht auf Windows SQL Server 2019/2022/2025
jeweils lokal und zentral. Aktuelle Head-/Integrations-CI und Release bleiben
gesondert offen. Seit der Benutzerklarstellung
vom 2026-10-16 verwendet sie `TestPurpose=Functional` mit dem ausdrücklich
gesetzten Trustwert des schema-validierten Labvertrags. Für diese Funktion
ist Serverzertifikatsprüfung keine fachliche Voraussetzung. Die getrennte
authentifizierte TLS-Abnahme bleibt `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-18`
- Nachweis: `local: Parser-Releasebuilder in zwei Buildroots; Parser Framework Full; SSIS Releasebuilder, Framework Full, Syntax und InstallationExample; Invoke-LabContract.ps1 -Full -Version 2019/2022/2025 -Modes local,central -PredecessorRoot (je Version)`
- Scope: Neuer freigegebener Buildsatz ohne Parser-PDB-Debugdaten: Parser aus zwei verschiedenen Verzeichnissen bytegleich und alle57 Methoden-ILs unverändert;245 Parser- und21 SSIS-Frameworkfälle,21 SQL-Syntaxfälle sowie55 Installerassertionen bestanden. Windows2019/BIN2,2022/CS_AS und2025/CI_AS_SC_UTF8 jeweils local/central:181 Kern-,61 API- und15 Lifecycleassertionen je Lauf,1542 insgesamt. Echte Parser2.0.0→2.0.1-/TableClone4.1.0→4.1.1-Upgrades mit ursprünglicher/aktueller Triggerfixture und Repeat bestanden; drei eigene Journale PASS_CLEANED. Functional mit explizitem Lab-Trustwert bei erforderlicher Verschlüsselung. Authentifizierte TLS-Abnahme, aktueller Head-CI- und Releaseabschluss separat; kein Produktions- oder vollständiger SDK-Paritätsnachweis.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
