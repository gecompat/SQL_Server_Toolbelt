# File Content Contract Test Matrix

## Geltungsbereich

- Modul: `toolbelt.file.content`
- Version: `1.0.0`
- Zielversionen: SQL Server 2019, 2022, 2025
- Compatibility Levels: 150, 160, 170
- Plattformen: Windows (Releasevalidierung), Linux (partially validated)

## Statische Tests

| ID | Prüfung | Erwartung |
|---|---|---|
| ST-001 | Alle Artefakte vorhanden | Source, Deployment, Tests, Dokumentation, Beispiele, module.yaml |
| ST-002 | LoadBinaryFile-Vertragsmarker | CREATE OR ALTER, Parameter, OPENROWSET(BULK...), SINGLE_BLOB, Fehlercodes |
| ST-003 | LoadTextFile-Vertragsmarker | CREATE OR ALTER, Parameter, OPENROWSET(BULK...), CODEPAGE, EncodingDetected, BomPresent |

## Lifecycle-Tests

| ID | Prüfung | Erwartung |
|---|---|---|
| LC-001 | Schema `toolbelt_file` existiert | Deployment erfolgreich |
| LC-002 | Tabelle `FileContentRootAllowlist` existiert | Konfiguration bereit |
| LC-003 | Procedures `USP_LoadBinaryFile` und `USP_LoadTextFile` existieren | Öffentliche Verträge bereit |

## Contract-Tests (ohne echtes Dateisystem)

| ID | Prüfung | Erwartung |
|---|---|---|
| CC-001 | Hilfe-Contract LoadBinaryFile | Resultset mit DESCRIPTION-Section |
| CC-002 | Hilfe-Contract LoadTextFile | Resultset mit DESCRIPTION-Section |
| CC-003 | NULL-Pfad | `IsValid = 0`, `ValidationCode = 51320` |
| CC-004 | Relativer Pfad | `IsValid = 0`, `ValidationCode = 51320` |
| CC-005 | Traversal-Pfad | `IsValid = 0`, `ValidationCode = 51322` |
| CC-006 | Pfad außerhalb Allowlist | `IsValid = 0`, `ValidationCode = 51321` |

## Runtime-Tests mit echtem Dateisystem (optional, plattformabhängig)

| ID | Prüfung | Erwartung |
|---|---|---|
| RT-001 | Binärdatei lesen | `Content` entspricht Dateiinhalt, `IsValid = 1` |
| RT-002 | Textdatei UTF-8 mit BOM | `EncodingDetected = 'UTF-8'`, `BomPresent = 1` |
| RT-003 | Textdatei Windows-1252 ohne BOM | `EncodingDetected = 'Windows-1252'`, `BomPresent = 0` |
| RT-006 | Textdatei UTF-16-BE mit BOM | `IsValid = 0`, `ValidationCode = 51325` |
| RT-004 | @MaxBytes überschritten | `IsValid = 0`, `ValidationCode = 51323` |
| RT-005 | Nicht existierende Datei | Engine-Fehler propagiert (THROW) |

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-01`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356`
- Scope: SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170; statischer Vertrag, Text/Binary-Fixtures, Allowlist, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
