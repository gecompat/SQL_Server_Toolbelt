# Testausführung

Static: `python Modules/toolbelt.json.constructors/Tests/Static/validate_contract.py`.
Lab: `pwsh -File Tests/CI/run-lab-local.ps1 -RunScripts run-json-constructors-linux.sh -Versions 2019 -Platforms linux -StopOnFailure`.
Zweiter Scope separat2025Windows, CU/base-Override nach Rootregeln.
Der bestehende Runner validiert den portablen Exportvertrag/schema; keine Lab-Infrastrukturänderungen.
Am 2026-10-01 ausgeführt: beide obigen Zielscopes erfolgreich mit dem vollständigen
finalen Adapter. `local: Tests/CI/run-lab-local.ps1` ist der Nachweis, keine
persistierten Rohlogs/Verbindungswerte. Windowsbefehl:
`pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -RunScripts run-json-constructors-linux.sh -Versions 2025 -Platforms windows -WindowsPatches CU8 -StopOnFailure`.
Static, PowerShell-Syntax und scopebezogene Manifest-/Dokumentationslinksprüfung
erfolgreich. Weitere Ziele/GitHub-hosted/CrossDB-Minimalrechte nicht ausgeführt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019 Linux/latest und 2025 Windows/CU8; local/central, Typ-/Literal-/Unicode-/Grenz-/Help-/ResultTable-/Transaktions-/Clientmetadaten-, CS/CI-Namespace-, lokale Minimalrechte-, Repeat-/Marker-/Hash-/TF-Drift-/Kollisions-/Uninstall-Contracts; 16 MiB Ergebnis und 100000 Entries. Weitere Ziele, GitHub und CrossDB-Minimalrechte nicht ausgefuehrt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
