# Module Capability Catalog

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

**Modul-ID:** `toolbelt.metadata.capability-catalog`
**Version:** `1.0.0`
**Implementierungsstatus:** `implemented`
**Validierungsstatus:** `validated`
**Release-Status:** `unreleased`

## Zweck

Das Modul macht die tatsächlich in einer Datenbank vorhandenen
Toolbelt-Modulmarker read-only abfragbar. Unvollständige und ungültige Marker
werden nicht ausgeblendet oder als gesund interpretiert.

## Öffentliches Objekt

| Objekt | Typ | Zweck |
|---|---|---|
| `toolbelt_metadata.VW_ModuleCapabilities` | View | Modul-ID, Version, Deployment-Modus und Metadatenstatus aus Database-level Extended Properties. |

## Abhängigkeiten

Keine Runtime-Modulabhängigkeit. Insbesondere liest die View weder
`module.yaml` noch eine persistente Registry.

## Deployment

`Deployment/Deploy.sql` benötigt `DeploymentMode=local|central`. Bei zentralem
Deployment beschreibt die View ausschließlich die Marker der zentralen
Toolbelt-Datenbank; konsumierende Datenbanken werden nicht automatisch
inventarisiert.

## Statuswerte

| Wert | Bedeutung |
|---|---|
| `valid` | Beide kanonischen Marker besitzen zulässige Werte. |
| `incomplete` | Version oder Deployment-Modus fehlt. |
| `invalid` | Name, ID, Datentyp, Version oder Modus verletzt V1. |

## Dokumentation

- [Objektseite](Documentation/VW_ModuleCapabilities.md)
- [Architekturvertrag](../../Documentation/Architecture/CAPABILITY_CATALOG_MODULE_DESIGN.md)
- [Beispiele](Examples/ModuleCapabilities.sql)
- [Testmatrix](Tests/CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md)

Die GitHub-hosted
[W2c-Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
einschließlich Marker-, Drift-, Collation-, Wiederholungs-, Lifecycle-,
Central- und Uninstall-Contracts erfolgreich.

Der vollständige Adapter ist seit 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Windows-Läufe und
eingeschränkte Metadata-Visibility bleiben Releasevalidierung.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; lokales und zentrales Deployment, eingeschränkte Metadatensichtbarkeit ohne Rechteausweitung, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
