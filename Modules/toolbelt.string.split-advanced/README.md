# Quote/Escape Multi-Separator Split


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


Modul `toolbelt.string.split-advanced`, Version 1.1.0, unreleased. S2 wurde am
2026-10-01 freigegeben. Die spätere ausdrückliche Einzel-Freigabe
„Unquoting, Split-USP und ZIP-Writer implementieren“ ergänzt
[TVF_UnquoteToken](Documentation/TVF_UnquoteToken.md) und
[USP_SplitAdvanced](Documentation/USP_SplitAdvanced.md); keine Änderung der
S2-Originaltoken-Semantik und kein automatisches Unquoting.

[Öffentlicher Vertrag](Documentation/TVF_SplitAdvanced.md) · [Design](../../Documentation/Architecture/SPLIT_ADVANCED_MODULE_DESIGN.md) · [Testmatrix](Tests/SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md) · [Evidenz](Tests/README.md).

Der [gemeinsame Buildplan](Deployment/README.md) bündelt die ausgewählte
Modulclosure einschließlich `toolbelt.core.result-table >=1.0.0` in derselben
Datenbank. Beide TVFs sind fachlich unabhängig vom Helper; nur USP-ResultTable
benötigt ihn zur Laufzeit. SQL Server 2019+ mit Compatibility>=150.
Der aktuelle create-only-Weg ersetzt keine vorhandenen Objekte, benötigt
weder SQLCMD noch Deploymentmarker und bietet keinen impliziten Uninstall.
Die früheren markerbasierten Installations-/Upgrade-/Uninstallwege gehören
ausschließlich zu ihren historischen Quellen und Nachweisen.

Alle drei öffentlichen Objekte besitzen einen vollständigen quellgeprüften
[Usage-Skill](../../Metadata/UsageSkills/README.md) in ihrer ausgelieferten DDL.
`EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;` liefert zusätzlich zur
Standardhilfe eine vollständige Skillzeile mit vier Spalten. Die neue
Hilfeprojektion ist offline geprüft; dies ist keine neue native Abnahme.

Der [ursprüngliche Callerrechtebericht](../../Releases/1.0.0/SPLIT-ADVANCED-RIGHTS-QUALIFICATION.md)
belegt drei Einzelgrantprofile und den getrennten ResultTable-/Helperpfad auf
sechs physischen Zielen bei höchstem CL. Der
[ergänzende CL-Abschluss](../../Releases/1.0.0/SPLIT-ADVANCED-CL-COMPLETION.md)
fügt die sechs niedrigeren CL-Fälle hinzu, ohne unveränderte grüne Fälle zu
wiederholen. Lifecycle- und echte CrossDB-Kontexte bleiben separat.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: 1.1.0: SQL Server 2019 Linux/latest und SQL Server 2025 Windows/CU8; S2-Regression, Unquoting inklusive Dense65536, USP/Help/ResultTable/OwnTransaction/Savepoint/doomed Caller, echte 1.0-Installerupgradefixture aus gepinntem Git, neue Namenskollisionen, alle API-Marker/SourceHashes, lokale/zentral-DB-Minimalrechte, administrative Cross-DB-Aufrufe. Lab-only SqlClient-Metadaten/NOT-NULL/Resultsetprobe erfolgreich. Andere neue Version-/Plattformkombinationen, GitHub-1.1-Workflow und niedrigprivilegierter mapped Caller Cross-DB nicht ausgeführt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

SC-013: TVF_UnquoteToken validiert Originalpositionen und speichert Start/Länge der Ausgabespans. Erst nach vollständiger Validierung wird das Ergebnis einmal geordnet zusammengesetzt. Kein wiederholtes LOB-Anhängen; Grenze65536 Codeeinheiten, Fehlerpositionen und Escape-/Qualifierprioritäten bleiben.

Details und abgegrenzte Nachweise: [Security-Härtung](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).
