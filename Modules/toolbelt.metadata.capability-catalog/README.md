# Module Capability Catalog

**Modul-ID:** `toolbelt.metadata.capability-catalog`
**Version:** `1.0.0`
**Implementierungsstatus:** `implemented`
**Validierungsstatus:** `not executed`
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

Kein Test gilt ohne tatsächliche Ausführung als erfolgreich.
