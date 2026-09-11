# Gzip-Provider: bedarfsabhängig zurückgestellt (`TC-2026-035`)

## Ergebnis

`TC-2026-035` wird zurückgestellt. Die aktuelle Microsoft-Dokumentation
bestätigt, dass `COMPRESS` und `DECOMPRESS` seit SQL Server 2016 Gzip-Werte
als `varbinary(max)` erzeugen beziehungsweise lesen. Damit besteht für die
Zielversionen 2019, 2022 und 2025 keine belegte allgemeine In-memory-Lücke.

Ein zusätzlicher Toolbelt-Adapter würde nur dann gerechtfertigt sein, wenn ein
konkreter Stream- oder File-Use-Case nachweislich durch diese nativen
Wertfunktionen und die vorhandenen Datei-/ZIP-Slices nicht erfüllt wird. Ein
solcher Use Case liegt im Backlog derzeit nicht vor.

## Abgrenzung

Diese Entscheidung verwirft weder ZIP noch weitere Kompressionsformate:

- ZIP ist ein Container und bleibt in `TC-2026-033`/`TC-2026-034` getrennt.
- Datei-I/O braucht bei Bedarf einen eigenen, bereits abgegrenzten Provider.
- Brotli, Zstandard, bzip2, 7z und weitere Formate bleiben in `TC-2026-036`
  jeweils format- und lizenzbezogene Kandidaten.

Ein pauschaler Stream- oder File-Wrapper würde zusätzliche Grenzen für
dekomprimierte Größe, Bomb-Schutz, Checksummen, Pfadberechtigungen, Timeout
und Plattformprovider einführen, ohne einen dokumentierten Mehrwert zu
liefern. Deshalb wird keine neue öffentliche Abstraktion vorbereitet.

## Wiederaufnahmebedingung

Zur Wiederaufnahme genügt eine konkrete, nicht sensible Problembeschreibung
mit Eingabeart, Größenordnungsklasse, erforderlichem Ergebnis, benötigtem
Formatmerkmal und einer Erklärung, warum `COMPRESS`/`DECOMPRESS` sowie
bestehende Toolbelt-Slices nicht genügen. Erst dann werden Vertrag, Provider,
Limits und Tests funktionsbezogen besprochen und freigegeben.

## Quelle

- [Microsoft: COMPRESS](https://learn.microsoft.com/en-us/sql/t-sql/functions/compress-transact-sql?view=sql-server-ver17)
- [Microsoft: DECOMPRESS](https://learn.microsoft.com/en-us/sql/t-sql/functions/decompress-transact-sql?view=sql-server-ver17)
