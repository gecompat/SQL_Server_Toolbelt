# SSIS Data Flow Debug SELECT

Version 1.0.0 erzeugt aus DTSX-Bytes eine bearbeitbare JSON-Vorlage und lesende
Debug-Scripts für SQL-Server-Datenflüsse. Jede ausgegebene Prüfstufe enthält
ihre `DECLARE`s, alle Vorgänger-CTEs und den abschließenden `SELECT`.

Die verbindliche Semantik steht im
[V1-Vertrag](../../Documentation/Architecture/SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md).
Die [API-Beschreibung](Documentation/USP_ExplainSsisDataFlow.md) zeigt den
SSMS-Aufruf. [Testumfang und offene Gates](Tests/README.md) sind getrennt
ausgewiesen. Das Modul ist teilweise validiert und unveröffentlicht.

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
- Datum: `2026-10-17`
- Nachweis: `local: Tests/Runtime/Invoke-LabContract.ps1 -Full -Version 2019/2022/2025 -Patch base -Modes local,central -PredecessorRoot (je Version); Framework/Invoke-Contract.ps1 -Profile Full; Framework/Invoke-Syntax.ps1`
- Scope: Finaler reproduzierbarer Produktbuild: Windows SQL2019/BIN2, SQL2022/CS_AS und SQL2025/CI_AS_SC_UTF8, jeweils local/central mit181 Kern-,61 API- und15 Lifecycleassertionen (1542 insgesamt). Alle Stufen frisch und einzeln ausgeführt; direkte DECLARE-/Cacheinvalidierung, Unicode-Lookup, Conversion/Overwrite/Shadowing, ResultTable/Help/Caller-TX/SET, Parallel-DML/Sch-M, Cross-DB, Analyse ohne Quell-SELECT, Katalog-/Computed-/Funktionsgrenzen und atomarer Fremdobjekt-/Consumer-/Lock-Schutz bestanden. Echte Parser2.0.0→2.0.1-/TableClone4.1.0→4.1.1-Upgrades mit ursprünglicher/aktueller Triggerfixture, Deployment/Repeat/Uninstall/Repeat und frische Cleanup-Audits bestanden. Full21 und Syntax12 bestanden; unveränderte Parser245/Guard60 wiederverwendet. Functional: Encrypt=True, explizit TrustServerCertificate=True; authentifizierte TLS-Abnahme separat not executed. Kein SDK-Paritäts-, Produktionslast-, Head-CI- oder Releasenachweis.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
