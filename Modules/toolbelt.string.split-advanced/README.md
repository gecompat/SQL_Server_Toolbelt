# Quote/Escape Multi-Separator Split

Modul `toolbelt.string.split-advanced`, Version 1.1.0, unreleased. S2 wurde am
2026-10-01 freigegeben. Die spätere ausdrückliche Einzel-Freigabe
„Unquoting, Split-USP und ZIP-Writer implementieren“ ergänzt
[TVF_UnquoteToken](Documentation/TVF_UnquoteToken.md) und
[USP_SplitAdvanced](Documentation/USP_SplitAdvanced.md); keine Änderung der
S2-Originaltoken-Semantik und kein automatisches Unquoting.

[Öffentlicher Vertrag](Documentation/TVF_SplitAdvanced.md) · [Design](../../Documentation/Architecture/SPLIT_ADVANCED_MODULE_DESIGN.md) · [Testmatrix](Tests/SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md) · [Evidenz](Tests/README.md).

SQLCMD-Deployment: zuerst same-database `toolbelt.core.result-table >=1.0.0`,
danach in Deployment `sqlcmd -d ToolbeltDemo -b -i Deploy.sql -v DeploymentMode=local`;
zentral mit DeploymentMode=central. Beide TVFs sind unabhängig, nur USP-
ResultTable benötigt den Helper. SQL Server 2019+ mit Compatibility>=150.
Fremdobjekte werden nicht übernommen; bekannte Releases 1.0.0/1.1.0 werden
markerbasiert ersetzt. Sourcehash ist nur diagnostisch.

Uninstall: `sqlcmd -d ToolbeltDemo -b -i Uninstall.sql -v ConfirmNoExternalConsumers=0`; zentral ausschließlich mit `-v ConfirmNoExternalConsumers=1`. Lokale referenzierende Objekte verhindern Deinstallation. Betreiber müssen externe Verbraucher vor zentraler Deinstallation prüfen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: 1.1.0: SQL Server 2019 Linux/latest und SQL Server 2025 Windows/CU8; S2-Regression, Unquoting inklusive Dense65536, USP/Help/ResultTable/OwnTransaction/Savepoint/doomed Caller, echte 1.0-Installerupgradefixture aus gepinntem Git, neue Namenskollisionen, alle API-Marker/SourceHashes, lokale/zentral-DB-Minimalrechte, administrative Cross-DB-Aufrufe. Lab-only SqlClient-Metadaten/NOT-NULL/Resultsetprobe erfolgreich. Andere neue Version-/Plattformkombinationen, GitHub-1.1-Workflow und niedrigprivilegierter mapped Caller Cross-DB nicht ausgeführt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
