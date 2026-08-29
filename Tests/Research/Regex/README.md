# R1a Regex Research Tests

Dieser Ordner reproduziert ausschließlich den R1a-Semantik-/Provider-Spike.
Er installiert kein Toolbelt-Modul und definiert keine öffentliche Runtime-API.

## SQL Server 2025

```powershell
pwsh Tests/CI/run-lab-local.ps1 `
  -Platforms linux `
  -Versions 2025 `
  -LinuxPatches latest `
  -RunScripts ../Research/Regex/run-sqlserver-2025.sh
```

Der Adapter prüft die native Semantik unter Compatibility Levels 150, 160 und
170, entfernt seine synthetische Datenbank und beendet die Lab-Umgebung nicht.

## .NET Framework 4.8

```powershell
pwsh Tests/Research/Regex/run-dotnet48-semantics.ps1
```

Der Harness kompiliert in ein eindeutiges temporäres Verzeichnis, prüft die
erwarteten Abweichungen zur nativen Referenz und entfernt alle Buildartefakte.

## Statischer Vertrag

```bash
python3 Tests/Research/Regex/validate_research.py
```
