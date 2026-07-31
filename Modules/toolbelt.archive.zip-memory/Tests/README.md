# Tests – ZIP Memory CLR Extraction

Alle Testarchive und Payloads sind vollständig synthetisch.

## Statische Prüfung

`Static/validate_contract.py` prüft insbesondere:

- .NET Framework 4.8 und den direkten Referenzgraph `System`/`System.Data`;
- keinen direkten Verweis auf `System.IO.Compression.dll` und keinen Einsatz
  von `ZipArchive`;
- eigenen Central-/Local-Header-Parser, `DeflateStream`, CRC32 und harte Limits;
- internen CLR-TVF-, öffentlichen USP-, Help-, ResultTable- und Fehlervertrag;
- getrenntes SHA2-512-Trust-Opt-in;
- pfadunabhängiges `SAFE`-Assembly-Deployment und vollständigen Uninstall;
- synthetische EOCD-/Central-Directory-Konsistenz der Testvektoren.

## Runtime-Contracts

`Runtime/ZipMemory.Contract.sql` prüft:

- Stored und Deflate;
- Local Header mit Data Descriptor;
- UTF-8-Entry-Namen und ordinalen case-sensitiven Vergleich;
- Help sowie ResultTable Replace/Append;
- Duplicate Names und verschlüsselte Statuspfade;
- Größen- und Compression-Ratio-Limits;
- beschädigte Local-/Central-Header-Beziehungen;
- CRC-Mismatch;
- nicht unterstützte Methods und ZIP64.

`Runtime/Lifecycle.Contract.sql` prüft Modulmarker, interne CLR-Tabellefunktion,
`SAFE`-Assembly, Assemblykopplung und den fehlenden direkten
`System.IO.Compression.dll`-Verweis.

`Runtime/Central.Contract.sql` führt die öffentliche Procedure aus einer
separaten Consumer-Datenbank gegen eine zentrale Toolbelt-Datenbank aus und
prüft dabei den Deflate-/CRC32-Pfad.

## Matrix

Der GitHub-Actions-Workflow baut die Assembly auf Windows mit .NET Framework
4.8 und führt sie anschließend in disposable Linux-Instanzen aus:

| Physische Engine | Compatibility Level |
|---|---|
| SQL Server 2019 | 150 |
| SQL Server 2022 | 160 |
| SQL Server 2025 | 150, 160, 170 |

Jeder Lauf prüft Trust, lokale und zentrale Installation,
Wiederholungsdeployment, fachliche Contracts, Uninstall sowie den bewusst
verbleibenden serverweiten Trust-Eintrag.

## Aktueller Status

`not executed` bis zu einem erfolgreichen Lauf des neuen CLR-Workflows.
Der Windows-Build allein ist kein Windows-SQL-Server-Runtime-Nachweis.
