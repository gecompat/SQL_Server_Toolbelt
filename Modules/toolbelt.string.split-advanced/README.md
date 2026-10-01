# Quote/Escape Multi-Separator Split

Modul `toolbelt.string.split-advanced`, Version 1.0.0, unreleased. S2 wurde am 2026-10-01 funktionsbezogen freigegeben; keine Freigabe für optionalen USP oder Unquoting.

[Öffentlicher Vertrag](Documentation/TVF_SplitAdvanced.md) · [Design](../../Documentation/Architecture/SPLIT_ADVANCED_MODULE_DESIGN.md) · [Testmatrix](Tests/SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md) · [Evidenz](Tests/README.md).

SQLCMD-Deployment: in Deployment `sqlcmd -d ToolbeltDemo -b -i Deploy.sql -v DeploymentMode=local`; zentral mit DeploymentMode=central. Dependencyfrei; SQL Server 2019+ mit Compatibility>=150. Fremdobjekte werden nicht übernommen; bekannte Releases werden markerbasiert ersetzt. Sourcehash ist nur diagnostisch.

Uninstall: `sqlcmd -d ToolbeltDemo -b -i Uninstall.sql -v ConfirmNoExternalConsumers=0`; zentral ausschließlich mit `-v ConfirmNoExternalConsumers=1`. Lokale referenzierende Objekte verhindern Deinstallation. Betreiber müssen externe Verbraucher vor zentraler Deinstallation prüfen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: SQL Server 2025 Linux: erweiterter vollständiger Adapter nach Review mit IF/TF-Driftkorrektur und Drift-Uninstall, nichtnullable IsValid-Metadaten und explizitem NULL-Oracle sowie SELECT-Minimalrechteproben lokal und direkt im zentralen Installationskontext. Niedrigprivilegierter Cross-DB-Aufruf mit mapped Caller nicht ausgeführt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
