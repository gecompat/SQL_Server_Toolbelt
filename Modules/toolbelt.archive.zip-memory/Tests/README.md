# Tests – ZIP Memory CLR Inspection

Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` war auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich; reale Archive, echte Extremgrößen, historische Upgrades und Interoperabilität bleiben offen. Der Modulstatus bleibt `partially validated`. Dieser Nachweis ersetzt frühere offene Windows-Aussagen; datierte ältere Einträge bleiben historische Evidenz.

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Alle Testarchive und Payloads sind synthetisch.

## Prüfartefakte

- `Static/validate_contract.py`: Build-, Referenz-, Objekt-, Lifecycle- und Dokumentationsvertrag.
- `Runtime/ZipMemory.Contract.sql`: Stored, Deflate, Data Descriptor, UTF-8, ResultTable und Negativfälle.
- `Runtime/Encoding.Contract.sql`: CP437-Entry-Name.
- `Runtime/Metadata.Contract.sql`: leeres Archiv, Metadaten, Methoden- und
  Verschlüsselungsstatus, Duplikate, Directory/Pfadsicherheit, Limits, Help und
  ResultTable.
- `Runtime/Lifecycle.Contract.sql`: Modulmarker, CLR-TVF und Assemblykopplung.
- `Runtime/Central.Contract.sql`: Aufruf aus einer Consumer-Datenbank.

## Erfolgreiche Evidenz

GitHub-Actions-Lauf `32701896453`:

| Umgebung | Compatibility Level | Ergebnis |
|---|---:|---|
| SQL Server 2019 Linux | 150 | erfolgreich |
| SQL Server 2022 Linux | 160 | erfolgreich |
| SQL Server 2025 Linux | 150 | erfolgreich |
| SQL Server 2025 Linux | 160 | erfolgreich |
| SQL Server 2025 Linux | 170 | erfolgreich |
| Windows-.NET-Framework-4.8-Build | n/a | erfolgreich |

Der Lauf belegt für `1.2.0` lokale und zentrale Installation, Upgrade-Marker,
Wiederholungsdeploy, Extraktions- und Listingverträge sowie Uninstall.

## Offen

- SQL-Server-Runtime unter Windows;
- echte Läufe an den maximalen Archiv-, Entry- und Entry-Count-Grenzen;
- zusätzliche Interoperabilitätsläufe vor Release.

Der Modulstatus ist `partially validated`.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; reproduzierbar gebautes und per exaktem SHA2-512 autorisiertes Releaseartefakt; reale Archive, Extremgrößen, historische Upgrades und Interoperabilität bleiben offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
