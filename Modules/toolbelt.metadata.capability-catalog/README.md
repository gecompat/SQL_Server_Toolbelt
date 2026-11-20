# Module Capability Catalog


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


Das Modul zeigt sichtbare bekannte Schnittstellenkandidaten ohne Installationsmarker oder Verwaltungstabelle. Version und Deploymentmodus bleiben NULL; `MetadataStatus=incomplete` kennzeichnet die fehlende beweisbare Zuordnung. Namensgleichheit wird nicht als Herkunft oder vollständige Installation ausgegeben.

Die [Objektreferenz](Documentation/VW_ModuleCapabilities.md) erklärt die vier Spalten und Metadata Visibility. Der [gemeinsame SQL-Installer](../../Scripts/Install/README.md) ist der neue Standard ohne SQLCMD. Er benötigt keine Marker für diese View. Die Kandidatenliste wird mit `python Scripts/Install/New-MarkerlessCapabilities.py` aus den Modulmanifesten erzeugt und mit `--check` geprüft.

Die Quellumstellung ist implementiert; aktuelle native Gesamtqualifikation steht aus. Die folgenden datierten Nachweise und Lifecycle-Beschreibungen gehören zum ursprünglichen Marker-Vertrag.

## Historische Modulbeschreibung und Nachweise

# Module Capability Catalog

Aktuelle [Callerrechte](../../Releases/1.0.0/CATALOG-CALLER-QUALIFICATION.md): getrennte Objektrechte auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral. Weitere Funktions-, Client-, Lifecycle- und Ressourcengates sowie Modulstatus bleiben separat.

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
