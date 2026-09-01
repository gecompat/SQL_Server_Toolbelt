# Generate-Series-Contract-Testmatrix

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

## Status

Die Matrix ist der Pflichtscope für `toolbelt.core.generate-series` Version
`1.0.0`. Der
[Generate-Series-Runtime-Lauf 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324)
war für die SQL-Server-2025-Linux-Matrix erfolgreich. Der Modulstatus ist
`partially validated`.

## Funktionsvertrag

| Dimension | Pflichtfälle |
|---|---|
| Signatur | Schema, Name, Inline-TVF-Typ, Parameterreihenfolge, Typen, Default und `Value`-Typ |
| Richtung | aufsteigend, absteigend und widersprüchliche Schrittweite |
| Grenze | Start enthalten; erreichbarer und nicht erreichbarer Stopwert |
| NULL | `NULL` bei Start/Stop; `NULL` und `DEFAULT` bei Schritt |
| Fehler | Schritt `0`; Vorrang dieses Fehlers; Zeilenzahl außerhalb `bigint` |
| Datentypen | `int`, `bigint` und Grenzwerte beider Typen |
| Größen | eine Million synthetische Werte |
| Row Goal | äußerer `TOP (10)` gegen eine sehr große gültige Reihe |
| relationale Nutzung | typstabiler Join und korreliertes `CROSS APPLY` |
| native Parität | SQL Server 2025 bei Compatibility Levels 160 und 170 |
| Reihenfolge | keine implizite Ordnungszusage; Beispiele verwenden `ORDER BY` |

## Lifecycle

| Dimension | Pflichtfälle |
|---|---|
| Erstinstallation | leere Datenbank und vorbestehendes `toolbelt_core`-Schema |
| Wiederholung | dieselbe Version überschreibt lokale Framework-Änderungen |
| Kollision | frameworkfremdes Zielobjekt blockiert vor Mutation |
| interne Dependency | `TVF_GenerateSeriesInt` referenziert den `bigint`-Kern |
| Uninstall | Wrapper vor Kern; fremde Schemaobjekte bleiben |
| zentral | dreiteiliger Aufruf und ausdrückliche Uninstall-Bestätigung |

## Zielmatrix

| Engine/Plattform | Compatibility | Status |
|---|---:|---|
| SQL Server 2025 Linux | 150 | `validated` im genannten Run |
| SQL Server 2025 Linux | 160 | `validated` im genannten Run |
| SQL Server 2025 Linux | 170 | `validated` im genannten Run |
| SQL Server 2019 Linux | 150 | `not executed` – gezielte Releasevalidierung |
| SQL Server 2022 Linux | 160 | `not executed` – gezielte Releasevalidierung |
| Windows 2019/2022/2025 | passend | `not executed` – geeigneter Runner erforderlich |

Die Compatibility-Matrix dient als schneller Syntax-, Planungs- und
Semantiktest. Sie ersetzt die gezielten physischen Versionsläufe vor einem
Release nicht.

## Datenschutz

Alle Grenzwerte, Bereiche und relationalen Testdaten sind synthetisch.
Runtime-Ausgaben und Runner-Eigenschaften werden nicht als Repository-Evidenz
gespeichert.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
