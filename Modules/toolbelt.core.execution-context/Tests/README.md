# Execution-Context-Testevidenz

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Der statische Vertrag sowie Root-/Nested-Context, Ownership, Actor/Tenant-Änderung, Multi-Session-Isolation, Lifecycle, Central und Uninstall sind auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948

Windows und die physischen SQL-Server-2019-/2022-Releaseprüfungen bleiben bis zur tatsächlichen Ausführung `not executed`.
