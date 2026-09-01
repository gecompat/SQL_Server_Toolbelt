# Error-Envelope-Contract-Testmatrix

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

- Help ohne Pflichtparameter und ohne Seiteneffekt
- ENGINE-, TOOLBELT- und USER-Klassifikation
- Originalwerte, Transaktionszustand und Sessionmetadaten
- aktive Execution-ID aus `SESSION_CONTEXT`
- direkte Ausgabe und ResultTable mit `@KeepData`
- ungültige Nummer, Severity, State, Line und leere Meldung
- lokales und zentrales Deployment, Wiederholung und Uninstall
- Windows bleibt bis zu einer tatsächlichen Ausführung `not executed`

## Ausgeführte Evidenz

- SQL Server 2025 Linux, Compatibility Levels 150, 160 und 170: erfolgreich.
- Workflow: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948
- Windows und physische SQL-Server-2019-/2022-Läufe: `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger W4-Moduladapter
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
