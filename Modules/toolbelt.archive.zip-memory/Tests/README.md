# Tests – ZIP Memory CLR Inspection

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

GitHub-Actions-Lauf `30615544206`:

| Umgebung | Compatibility Level | Ergebnis |
|---|---:|---|
| SQL Server 2019 Linux | 150 | erfolgreich |
| SQL Server 2022 Linux | 160 | erfolgreich |
| SQL Server 2025 Linux | 150 | erfolgreich |
| SQL Server 2025 Linux | 160 | erfolgreich |
| SQL Server 2025 Linux | 170 | erfolgreich |
| Windows-.NET-Framework-4.8-Build | n/a | erfolgreich |

Der Lauf `30615544206` belegt den Extraktionsvertrag aus `1.1.0`. Für `1.2.0`
werden lokale und zentrale Installation, Versionsupgrade, Wiederholungsdeploy,
Extraktions- und Listingverträge sowie Uninstall erneut durch die
`zip-memory-runtime`-Matrix geprüft.

## Offen

- SQL-Server-Runtime unter Windows;
- abgeschlossene CI-Runtime-Evidenz für den Listingvertrag `1.2.0`;
- echte Läufe an den maximalen Archiv-, Entry- und Entry-Count-Grenzen;
- zusätzliche Interoperabilitätsläufe vor Release.

Der Modulstatus ist `partially validated`.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206
