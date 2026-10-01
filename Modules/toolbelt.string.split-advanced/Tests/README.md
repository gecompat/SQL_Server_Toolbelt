# Split-Advanced Tests

[Matrix](SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md). Synthetische Tests ohne Persistenz realer Runtime-Ausgaben.

Statisch: `python Modules/toolbelt.string.split-advanced/Tests/Static/validate_contract.py`.

Runtime: `pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -Versions 2025 -Platforms linux -RunScripts run-split-advanced-linux.sh`. Weitere Zielversionen/Plattformen scopebezogen über dieselben Parameter. Lab-Adapter verwaltet keine Infrastruktur; synthetische Testdatenbanken werden vom vorhandenen Shim isoliert und entfernt.

GitHub-hosted Matrix: [Workflow](../../../.github/workflows/split-advanced-runtime.yml). Ein vorhandener Workflow ist kein Nachweis seiner Ausführung.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: SQL Server 2025 Linux: erweiterter vollständiger Adapter nach Review mit IF/TF-Driftkorrektur und Drift-Uninstall, nichtnullable IsValid-Metadaten und explizitem NULL-Oracle sowie SELECT-Minimalrechteproben lokal und direkt im zentralen Installationskontext. Niedrigprivilegierter Cross-DB-Aufruf mit mapped Caller nicht ausgeführt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
