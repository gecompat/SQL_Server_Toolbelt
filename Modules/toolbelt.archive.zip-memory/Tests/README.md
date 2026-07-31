# Tests – ZIP Memory CLR Extraction

Alle Testarchive und Payloads sind synthetisch.

## Prüfartefakte

- `Static/validate_contract.py`: Build-, Referenz-, Objekt-, Lifecycle- und Dokumentationsvertrag.
- `Runtime/ZipMemory.Contract.sql`: Stored, Deflate, Data Descriptor, UTF-8, ResultTable und Negativfälle.
- `Runtime/Encoding.Contract.sql`: CP437-Entry-Name.
- `Runtime/Lifecycle.Contract.sql`: Modulmarker, CLR-TVF und Assemblykopplung.
- `Runtime/Central.Contract.sql`: Aufruf aus einer Consumer-Datenbank.

## Erfolgreiche Evidenz

GitHub-Actions-Lauf `30615544206`:

| Umgebung | Compatibility Level | Ergebnis |
|---|---:|---|
| SQL Server 2019 Linux | 150 | erfolgreich |
| SQL Server 2022 Linux | 160 | erfolgreich |
| SQL Server 2025 Linux | 150 | erfolgreich |
| SQL Server 2025 Linux | 160 | erfolgreich |
| SQL Server 2025 Linux | 170 | erfolgreich |
| Windows-.NET-Framework-4.8-Build | n/a | erfolgreich |

Geprüft wurden lokale und zentrale Installation, Wiederholungsdeployment, fachliche Contracts und Uninstall.

## Offen

- SQL-Server-Runtime unter Windows;
- echte Läufe an den maximalen Archiv-, Entry- und Entry-Count-Grenzen;
- zusätzliche Interoperabilitätsläufe vor Release.

Der Modulstatus ist `partially validated`.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206
