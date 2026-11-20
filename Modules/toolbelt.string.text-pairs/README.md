# Begrenzter Paarvergleich


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


`toolbelt.string.text-pairs` 1.0.0 ist implementiert, **teilweise validiert** und unveröffentlicht. Die gezielten lokalen Linux-/Windows- und zentralen Windows-Nachweise stehen im [Nachweisstand](Tests/README.md); Weitergehende Rechteprofile, Lifecycle-Negativfälle und Ziele bleiben offen. Bestehende Distanz-/Jaro-Evidenz qualifiziert diesen Wrapper nicht.

Die [aktuelle Callerqualifikation](../../Releases/1.0.0/TEXT-PAIRS-CALLER-QUALIFICATION.md) belegt im gebunden installierten Ownershipstand genau ein EXECUTE auf `toolbelt_string.USP_CompareTextPairs` für alle drei Algorithmen über direkte Ausgabe und ResultTable. Separate SELECT-Rechte auf Vergleichs-TVFs oder EXECUTE auf dem Helper werden dabei nicht erteilt; direkte Dependencyaufrufe bleiben mit SQL229 gesperrt. Andere Owner-/Client-/Grenz-/Lifecyclekontexte bleiben getrennt.

Die einzige öffentliche USP [USP_CompareTextPairs](Documentation/USP_CompareTextPairs.md) vergleicht eine caller-lokale #Temp mit drei global auswählbaren Algorithmen. Bestehende TVFs bleiben der einzige Vergleichskern. Row-, Textbyte- und konservative Workadmission gehen allen TVF-Aufrufen voraus; ResultTable-Vorbereitung und Insert werden gemeinsam atomar veröffentlicht.

Voraussetzungen: passende `toolbelt.string.edit-distance`- und
`toolbelt.core.result-table`-Objekte aus demselben aktuellen Funktionssatz in
derselben Toolbelt-Datenbank. Der gemeinsame Installer bündelt die ausgewählten
Abhängigkeiten. Der Wrapper installiert zur Laufzeit weder Assembly noch Trust.
Zentraler Aufruf dreiteilig mit sessionlokalen Temps; keine Synonyme.

Aktuelle Installation über den oben verlinkten gemeinsamen create-only-Weg
ohne SQLCMD-Modus. Frühere `DeploymentMode`-/Assemblyhash-/Uninstallparameter
gehören zum historischen markerbasierten Lifecycle und sind keine aktuellen
Kommandos. Seine Nachweise bleiben an die ursprünglichen Artefakte gebunden.

## Vollständiger Skill und Hilfe

Der [kanonische Skill](../../Metadata/UsageSkills/toolbelt_string/USP_CompareTextPairs.md)
beschreibt alle elf Parameter, globale Budgetfehler, die Paarcodes und die
OwnTX-/Savepoint-Veröffentlichung. Er steht identisch in der DDL. `@Hilfe=1`
liefert die bisherige Standardhilfe und anschließend genau eine zusätzliche
vierkolumnige Skillzeile vor fachlichen Transaktions-/Temp-/Providerprüfungen.
Die neue zusätzliche Hilfe ist offline geprüft; ihre native Abnahme ist separat.

[Freigabe und Vertrag](../../Documentation/Architecture/TEXT_PAIRS_CONTRACT.md), [Beispiel](Examples/CompareTextPairs.sql), [Testmatrix](Tests/TEXT_PAIRS_TEST_MATRIX.md), [Nachweisstand](Tests/README.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `private bounded Windows-/Central-Labadapter; unabhängiger physischer Receipt-/Journal-/Capture-/Pin-Audit`
- Scope: SQL Server 2025 Windows/CU8 CL170 SC-UTF8 local: fünf öffentliche SQL-Fixtures und Lifecycle-Wiederholungen. Separat central: InstalledMetadata, drei direkte typgenaue Algorithmusconsumer mit EOF/noNext, drei ResultTable-Ausgaben ohne Resultset, strikte Uninstall-Bestätigung 55128/1 mit unverändertem Katalogsnapshot, Wiederholung und eigene Bereinigung. Keine Config-/Rechte-/Owneränderung. Minimalrechte, weitere Lifecycle-Negativfälle und Ziele bleiben offen; aktuelle PR-Head-CI separat.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
