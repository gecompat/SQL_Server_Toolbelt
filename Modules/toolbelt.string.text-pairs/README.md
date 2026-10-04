# Begrenzter Paarvergleich

`toolbelt.string.text-pairs` 1.0.0 ist implementiert, **teilweise validiert** und unveröffentlicht. Die gezielten lokalen Linux-/Windows- und zentralen Windows-Nachweise stehen im [Nachweisstand](Tests/README.md); Minimalrechte, weitere Lifecycle-Negativfälle und Ziele bleiben offen. Bestehende Distanz-/Jaro-Evidenz qualifiziert diesen Wrapper nicht.

Die einzige öffentliche USP [USP_CompareTextPairs](Documentation/USP_CompareTextPairs.md) vergleicht eine caller-lokale #Temp mit drei global auswählbaren Algorithmen. Bestehende TVFs bleiben der einzige Vergleichskern. Row-, Textbyte- und konservative Workadmission gehen allen TVF-Aufrufen voraus; ResultTable-Vorbereitung und Insert werden gemeinsam atomar veröffentlicht.

Voraussetzungen: `toolbelt.string.edit-distance` exakt bekannter Release 1.1.0 und `toolbelt.core.result-table` 1.0.0 in derselben Datenbank und im gleichen local/central-Modus. Keine neue Assembly oder Trustinstallation. Central-Aufruf dreiteilig, keine Synonyme.

Deploy aus `Deployment/` im SQLCMD-Modus mit `DeploymentMode` und `ExpectedComparisonAssemblyHash` (0x+128 Hexzeichen des freigegebenen tatsächlichen SHA2-512-Binary). Uninstall mit `ConfirmNoExternalConsumers`; central verlangt 1. Lifecycle verlangt vorhandene vollständige Metadatensicht, gewährt keine Rechte und erhält fremde/unkannte Zustände. Das bereits von der Dependency benötigte Schema wird weder adoptiert noch entfernt.

[Freigabe und Vertrag](../../Documentation/Architecture/TEXT_PAIRS_CONTRACT.md), [Beispiel](Examples/CompareTextPairs.sql), [Testmatrix](Tests/TEXT_PAIRS_TEST_MATRIX.md), [Nachweisstand](Tests/README.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `private bounded Windows-/Central-Labadapter; unabhängiger physischer Receipt-/Journal-/Capture-/Pin-Audit`
- Scope: SQL Server 2025 Windows/CU8 CL170 SC-UTF8 local: fünf öffentliche SQL-Fixtures und Lifecycle-Wiederholungen. Separat central: InstalledMetadata, drei direkte typgenaue Algorithmusconsumer mit EOF/noNext, drei ResultTable-Ausgaben ohne Resultset, strikte Uninstall-Bestätigung 55128/1 mit unverändertem Katalogsnapshot, Wiederholung und eigene Bereinigung. Keine Config-/Rechte-/Owneränderung. Minimalrechte, weitere Lifecycle-Negativfälle und Ziele bleiben offen; aktuelle PR-Head-CI separat.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
