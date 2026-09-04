# Console Message

Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` war auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich; zusätzliche Client-/Treiber-, Buffering- und Framing-Evidenz bleibt offen. Der Modulstatus bleibt `partially validated`. Dieser Nachweis ersetzt frühere offene Windows-Aussagen; datierte ältere Einträge bleiben historische Evidenz.

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

**Modul-ID:** `toolbelt.core.console-message`
**Version:** `1.0.0`
**Implementierungsstatus:** `implemented`
**Validierungsstatus:** `partially validated`
**Release-Status:** `unreleased`

## Zweck

Das Modul gibt lange Unicode-Texte vollständig und geordnet im
SQL-Server-Messages-Kanal aus. Der Aufrufer wählt gepuffertes `PRINT` oder
unmittelbares `RAISERROR ... WITH NOWAIT`.

## Öffentliches Objekt

| Objekt | Typ | Zweck |
|---|---|---|
| `toolbelt_core.USP_WriteConsoleMessage` | USP | Unicode-sichere, gechunkte Console-Ausgabe ohne fachliches Resultset. |

## Abhängigkeiten

Keine Runtime-Modulabhängigkeit.

## Deployment

`Deployment/Deploy.sql` benötigt die SQLCMD-Variable
`DeploymentMode=local|central`. Lokales und zentrales Deployment verwenden
dieselbe Implementierung. Zentral installierte Procedures werden mit
dreiteiligem Namen ausgeführt.

## Vertrag

- `nvarchar(max)`-Payload;
- `PRINT` mit höchstens 4.000 UTF-16-Codeunits je Chunk;
- `RAISERROR(N'%s', 0, 1, ...) WITH NOWAIT` mit höchstens 2.000
  UTF-16-Codeunits;
- Supplementary Characters werden nicht zwischen Chunks getrennt;
- `NULL` und Leertext erzeugen keine Ausgabe;
- keine Präfixe, Zeitstempel, Severity-Optionen oder Resultsets.

Der Client kann Message-Frame-Grenzen optisch als zusätzliche Zeilen
darstellen. Die Procedure ist nicht für zeilenweise Hot-Path-Ausgabe gedacht.

## Dokumentation

- [Objektseite](Documentation/USP_WriteConsoleMessage.md)
- [Architekturvertrag](../../Documentation/Architecture/CONSOLE_MESSAGE_MODULE_DESIGN.md)
- [Beispiele](Examples/ConsoleMessage.sql)
- [Testmatrix](Tests/CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md)

Die GitHub-hosted
[W2c-Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
einschließlich Langtext-, Unicode-, Provider-, Wiederholungs-, Lifecycle-,
Central- und Uninstall-Contracts erfolgreich.

Der vollständige Adapter ist seit 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Windows-Läufe sowie
weitere Clients und Treiber bleiben Releasevalidierung.

## SQL Server Lab Project Adapter

Der [Project Adapter](TestLab/ProjectAdapter/README.md) implementiert den
ADP-008-Piloten für den Vertragsstand 0.1. Seine ausführbaren SQL-Dateien
werden deterministisch aus dem kanonischen Moduldeployment erzeugt. Der
identische Lifecycle aus Installation, versionsgleichem Update, Validierung
und markergebundenem Cleanup war am 2026-08-30 auf SQL Server 2025 Linux
getrennt unter Docker und Podman erfolgreich
(`local: SQL_Server_Lab Project Adapter 0.1`). Das Toolbelt-Repository verwaltet dabei keine
Lab-Infrastruktur; sein Runner bindet ausschließlich einen bereits
bereitgestellten Lab-Run.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger automatisierter Moduladapter; zusätzliche Client-/Treiber-, Buffering- und Framing-Evidenz bleibt offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
