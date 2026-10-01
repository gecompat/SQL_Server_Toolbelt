# Tests – ZIP Memory CLR Inspection

Release 1.4, 2026-10-02: `local: Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Invoke-LabContract.ps1` auf Linux 2019/latest und Windows 2025/CU8 erfolgreich. Qualifiziert sind echte ZIP-1.3-Assemblyhash-Upgrades, bestehender Writer-SQL-Vertrag, SAFE local/central und nichtdoomende Deploy-/Uninstall-Callerablehnung OFF/ON. Unabhängige Writer-Frameworksuite erneut erfolgreich; bekannte übrige Matrix bleibt offen.

## Writer 1.3.0 (2026-10-01)

`powershell -File Modules/toolbelt.archive.zip-memory/Tests/Runtime/Writer.Framework.ps1 -AssemblyPath .runtime/zip-memory-release/Toolbelt.Archive.ZipMemory.dll` prüft das echte Framework-Binary mit unabhängigem ZipArchive-, CRC- und Header-Oracle. Enthalten sind ein leerer Method-8-Entry, Stored-Identität, ungültige Envelopes, Namen und parallele Aufrufe. Synthetisch werden tatsächlich 32 MiB je Entry, 128 MiB Gesamtpayload, 1024 Entries und 2048 UTF-16-Codeeinheiten je Name gemeinsam verarbeitet. Die eigenständigen Budgetcaps für 136 MiB Envelope und 144 MiB Output werden als Parameterceilings akzeptiert; der maximale gültige Input bleibt darunter. Exakte Auslastung dieser beiden Caps wird nicht behauptet.

`Writer.Contract.sql` deckt lokal und zentral Help, Input, NULLs, Ordinals, Namen, Limits, Fehleratomarität, Append, Schema-Blocker, XACT_ABORT OFF/ON, Ratio und Readergrenzen ab. Hinzu kommen tatsächliche 16-MiB-Standardpayloads mit Stored/Deflate und Hash-/Längenvergleich sowie 256 Entries mit Ordinals über 255. `Writer.Metadata.ps1` verwendet eine eigene SQLClient-Sitzung für tatsächliche SELECT-/Help-Typen, Nullability, Resultsets und Messages. Der Adapter baut eine echte gepinnte 1.2.0-Fixture separat, prüft Hashidentität, drei neue Namenskollisionen und deren Erhalt beim historischen Uninstall sowie Upgrade auf 1.3.0, Wiederdeploy und Uninstall. Eine Markerumschaltung gilt nicht als historischer Upgradebeweis.

Abstrakte Endstand-Evidence vom 2026-10-01: Der vollständige Moduladapter war auf SQL Server 2019 unter Linux (Compatibility 150) und SQL Server 2025 unter Windows (Compatibility 150, 160 und 170) erfolgreich. Jeder Lauf umfasst lokale und zentrale Installation, die Writer- und SQLClient-Metadatenverträge, tatsächliche 16-MiB-Standardpayloads mit beiden Methoden, leere Stored-/Deflate-Payloads über direkte CLR-Tabellefunktion, öffentliche SELECT-Ausgabe und ResultTable, bestehende encrypted-NULL-Regressionen, Transaktionen und Fehleratomarität sowie echtes 1.2.0-Binaryupgrade, Kollisionen, Wiederdeploy und Uninstall. Build, Framework-Suite und statischer Modulvalidator waren am finalen Quellstand erfolgreich. Nichtöffentliche Laufzeitdaten wurden nicht als Repository-Artefakte gespeichert.

Der Modulstatus bleibt `partially validated`: echte Produktionsarchive, globale Kapazitäts- oder Parallelitätsgrenzen und SQL-LOB-Ceilings oberhalb der Standardpayload sind nicht vollständig qualifiziert. Die größeren synthetischen Frameworkgrenzen sind ein separater Nachweis, keine allgemeine Serverkapazitätszusage.

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
- Datum: `2026-10-02`
- Nachweis: `local: Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Invoke-LabContract.ps1`
- Scope: Release 1.4.0: finaler identischer Linux-2019-/Windows-2025-CU8-Adapter nach EOF-Pflege; echte ZIP-1.3-Assemblyhash-Upgradefixture, bestehender Writer-SQL-Vertrag, SAFE local/central und nichtdoomende ZIP-Deploy/Uninstall-Callerablehnung OFF/ON. Unabhängige Framework-Writerregression erneut erfolgreich; übrige Kapazitäts-/Plattformmatrix offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
