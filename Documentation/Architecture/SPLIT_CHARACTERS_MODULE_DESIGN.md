# Design: `toolbelt.string.split-characters`

## Entscheidung

Version 1 stellt genau eine öffentliche Inline-TVF bereit:

```text
toolbelt_string.TVF_SplitByCharacters
```

Sie verarbeitet eine Menge einzelner literal interpretierter
UTF-16-Codeeinheiten. Mehrzeichige Separatorstrings, Quote und Escape werden
nicht in diesen Vertrag hineinerweitert; sie bleiben `TC-2026-032`.

## Algorithmus

1. `DATALENGTH / 2` bestimmt die Zahl der UTF-16-Codeeinheiten ohne die
   Trailing-Space-Semantik von `LEN`.
2. `toolbelt_core.TVF_GenerateSeriesBigInt` erzeugt Separator- und
   Eingabepositionen.
3. NUL in der Separatorliste wird vor der Tokenbildung erkannt.
4. Eingabepositionen werden mit `Latin1_General_100_BIN2` literal gegen die
   Separatorliste geprüft.
5. Start, Separatorpositionen und synthetisches Ende bilden Grenzen.
6. `LEAD` bestimmt das nächste Ende; `SUBSTRING` liefert Tokens.
7. Nach dem optionalen Entfernen leerer Tokens erzeugt `ROW_NUMBER` lückenlose
   `bigint`-Ordinals ab 1.

Die Funktion bleibt optimizer-sichtbar und besitzt keine persistente
Hilfstabelle, rekursive CTE, Katalogabhängigkeit, CLR- oder Regex-Abhängigkeit.

## Dependency

Das Modul benötigt `toolbelt.core.generate-series` Version `1.0.0` in derselben
Datenbank. Der Deployment-Preflight prüft den Datenbankmarker und
`TVF_GenerateSeriesBigInt`, bevor Schema oder Objekte verändert werden.
Uninstall entfernt die Dependency nicht.

## Collation und Unicode

Separatorvergleiche sind unabhängig von der Datenbank-Collation. Das
Separatoratom ist eine UTF-16-Codeeinheit, nicht ein Unicode-Codepoint oder
Graphemcluster. Dieser enge Vertrag ist auf SQL Server 2019, 2022 und 2025
identisch umsetzbar.

## Deployment

Lokales und zentrales Deployment verwenden dieselbe Source. Release-Manifest,
Application Lock, Frameworkmarker, Source-Hash, Kollisionsschutz und
kontrollierter Uninstall folgen dem allgemeinen Deploymentvertrag.

Der Fehlerbereich `51070–51079` gehört diesem Modul; `51079` bezeichnet die
fehlende oder inkompatible Generate-Series-Dependency.

## Validierungsgrenze

Der GitHub-Workflow prüft SQL Server 2025 Linux bei Compatibility Levels 150,
160 und 170. SQL Server 2019/2022 sowie Windows bleiben bis zu physischen
Läufen `not executed`.
