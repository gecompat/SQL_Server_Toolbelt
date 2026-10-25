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
den qualifizierten SSIS-Iterationsbuild einschließlich
passender DLLs, SQL-/PowerShell-Skripte und SSMS-Beispiel zum Testen ohne eigenen
Build. Der externe Exporthost gehört nicht zu diesem SQL-Installationspaket.
Build- und Paketnachweise stehen getrennt in der Prüfmatrix.

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
Buildbindungen und die zusätzlich geprüften echten Upgradepfade. Der Iterationsbuild hat einen eigenen Nachweis für alle drei Windows-Versionen
einschließlich Upgrade vom zuvor ausgelieferten #411-Build. Das Modul
bleibt unveröffentlicht. Seit der Benutzerklarstellung
vom 2026-10-16 verwendet sie `TestPurpose=Functional` mit dem ausdrücklich
gesetzten Trustwert des schema-validierten Labvertrags. Für diese Funktion
ist Serverzertifikatsprüfung keine fachliche Voraussetzung. Die getrennte
authentifizierte TLS-Abnahme bleibt `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-25`
- Nachweis: `local: reproduzierbarer Iterations-CLR-Build, Full21, gemeinsame97 Modell-/Iterationsgegenproben und Full Windows2019/2022/2025 local/central mit qualifiziertem ausgeliefertem Vorgänger`
- Scope: Neuer gemeinsamer Iterationskern mit unveränderter öffentlicher SQL-API und Dependency-Pins. Sechs neue physische Windows-Kontexte mit je181 Kern-,61 API-,15 Lifecycle- und8 echten PR411→Iterations-Buildupgradeassertionen,1590 insgesamt. Assembly-/Prozeduridentitäten und alte JSON-Vorlage erhalten. Sechs frische Abschlussaudits: zwölf eigene DB-Namen abwesend,24 Trustzustände und Konfiguration wiederhergestellt, Pins unverändert. Grenzen300/360/400 und40/45 unverändert; Functional Encrypt=True und expliziter Lab-Trust ohne Fallback. Frühere Legacy-/Dependency-Nachweise bleiben separat; Paketlieferung wird gegen den finalen ZIP-Hash gesondert geprüft. Windows-Identitäts-/SSMS-, authentifizierte TLS-, Linux-Host-, SDK-/Ressourcen-/Produktions- und Releasegates bleiben getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Der optionale externe [Begleittransport für native Objektkennungen](Exchange/README.md#native-objektkennungen-als-begleittransport)
verwendet denselben Paketkern. Er liefert GUIDs für eine separat zu belegende
Analyze-Korrelation und enthält weder einen Logdecoder noch ein Laufzeiturteil.
