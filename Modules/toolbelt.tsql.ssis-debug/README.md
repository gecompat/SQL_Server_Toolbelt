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
Der ausdrücklich opt-in gewählte Komponentenmodus `bindings-template-v2`
folgt dem [Komponenten-V2-Vertrag](../../Documentation/Architecture/SSIS_COMPONENTS_V2_CONTRACT.md).
Er verwendet `schemaVersion: 2` und `profile: "ssis-debug-components-v2"`;
`explain` akzeptiert dieses vollständige Profil, während V1-Aufrufe unverändert
bleiben.

Die [V2-Installation](Documentation/ComponentsV2Installation.md) beschreibt
das separate ZIP und den eigenständigen T-SQL-Installer sowie den ersten
Aufruf mit Standardbudget oder ausdrücklich unbegrenzten Ressourcenbudgets.
Die [API-Beschreibung](Documentation/USP_ExplainSsisDataFlow.md) zeigt den
SSMS-Aufruf. [Testumfang und offene Gates](Tests/README.md) sind getrennt
ausgewiesen. Das V2-ZIP und der eigenständige Installer haben begrenzte,
nativ gebundene Windows-Nachweise; Head-/Main-CI bleibt offen. Der Modulstatus
ist teilweise validiert und unveröffentlicht.

Das [vollständige SSMS-Beispiel](Examples/README.md) mit
[`SsmsDebugWalkthrough.sql`](Examples/SsmsDebugWalkthrough.sql) und synthetischer
DTSX-Fixture zeigt Import, JSON-Vorlage, Werteänderung, Stufenauswahl und direkte
DECLARE-Änderungen einschließlich erwarteter Ergebnisse und Cleanup.

Die [Installationsanleitung](Examples/Installation/README.md) enthält die
SQL-Server-Vorbereitung, einen PowerShell-Installer mit Offline-Artefaktprüfung
und die anschließende Installationskontrolle für Parser, ResultTable und
SSIS-Debug einschließlich des getrennten Assembly-Trust-Opt-ins.

Das [vollständige ZIP-Installationspaket](InstallPackages/README.md) enthält
den qualifizierten SSIS-Build mit Pipeline-Identitäten und qualifizierten Lookup-Ausgangsrollen einschließlich
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

Optionale Quellinstallation für die Entwicklung: Parser 2.0.1 und Result Table 1.0.0
separat installieren, Release
mit `Scripts/New-ClrReleaseArtifacts.ps1` reproduzierbar bauen, den exakten
Assemblyhash administrativ freigeben und `Artifacts/Deploy.WithAssembly.sql`
im SQLCMD-Modus mit `DeploymentMode=local` oder `central` ausführen. Der
UNSAFE-/Strict-Security-Vertrag wird nicht aufgeweicht. Shared Dependencies
und Trusteinträge werden beim Uninstall nicht entfernt.

Die begrenzten nativen Fachnachweise umfassen Windows SQL Server 2019/2022/2025
jeweils lokal und zentral. Die [Prüfmatrix](Tests/README.md) trennt deren
Buildbindungen und die zusätzlich geprüften echten Upgradepfade. Der aktuelle
Pipeline-Build ist auf allen unterstützten CLs geprüft, einschließlich Upgrade
vom zuvor ausgelieferten Scope-Identitätsbuild. Frühere Builds behalten ihre
eigenen datierten Nachweise. Das Modul
bleibt unveröffentlicht. Seit der Benutzerklarstellung
vom 2026-10-16 verwendet sie `TestPurpose=Functional` mit dem ausdrücklich
gesetzten Trustwert des schema-validierten Labvertrags. Für diese Funktion
ist Serverzertifikatsprüfung keine fachliche Voraussetzung. Die getrennte
authentifizierte TLS-Abnahme bleibt `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-29`
- Nachweis: `local: SSIS-Komponenten-V2 ZIP- und Standalone-T-SQL-Paketqualifikationen`
- Scope: Separates V2-ZIP mit zwei Windows-Paketfällen, 1190 Assertions und zwei unabhängigen Cleanup-Audits; Standalone-T-SQL-Installer auf Windows SQL2019/CL150 und SQL2025/CL170 in local/central, vier V2-Opt-in-Vorlagenprüfungen und zwei unabhängige Audits. Die getrennten Reports binden Binary, Paket, Installer und Ausführungseingaben. Eine separate CRLF→LF-Integrationsbindung dokumentiert genau zwei Metadatenänderungen: Normalisierung des ZIP-Qualifikations-JSONs und Anpassung seines Hashfelds in der Installerprovenienz; Ausführungspins und Installerbytes bleiben unverändert. Native Records belegen keine CI; Head-/Main-CI und Integration werden am jeweiligen PR-/Merge-Head getrennt nachgewiesen. Vollständige Plattform-/Engine-Matrix, authentifiziertes TLS und Veröffentlichung bleiben unqualifiziert beziehungsweise nicht freigegeben; der Modulstatus bleibt unverändert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Der optionale externe [Begleittransport für native Objektkennungen](Exchange/README.md#native-objektkennungen-als-begleittransport)
verwendet denselben Paketkern. Er liefert GUIDs für eine separat zu belegende
Analyze-Korrelation und enthält weder einen Logdecoder noch ein Laufzeiturteil.
