# Moduldesign JSON Path Exists

| Feld | Wert |
|---|---|
| Kandidat | `TC-2026-009`, ausschließlich Pfadprüfungs-Slice |
| Modul | `toolbelt.json.path-exists` |
| Öffentliche API | `toolbelt_json.TVF_JsonPathExists` |
| Vertrag besprochen | 2026-07-30 |
| Implementierung freigegeben | 2026-07-30 |

## Zweck und Scope

Version 1 backportiert den fehlerfreien Existenzvertrag von
`JSON_PATH_EXISTS` auf SQL Server 2019 und stellt auf 2022/2025 eine
versionsstabile Toolbelt-API bereit.

Enthalten sind:

- genau eine öffentliche Table-valued Function;
- Root-, Property-, Array-Index- und Array-Wildcard-Schritte;
- JSON-String-Escapes für quotierte Property-Namen;
- `1`/`0`/SQL-`NULL` als `int`;
- lokale und zentrale Installation.

Nicht enthalten sind:

- `JSON_OBJECT`- oder `JSON_ARRAY`-Konstruktoren;
- `JSON_ARRAYAGG`, `JSON_OBJECTAGG` oder ein SQL-CLR-Aggregat;
- SQL-Server-2025-Preview-Ranges, Indexlisten und `last`;
- der native SQL-Server-2025-`json`-Datentyp;
- ein Scalar-Wrapper.

`TC-2026-013` bleibt zurückgestellt, solange native Aggregate Preview sind
und kein freigegebener CLR-/Providervertrag besteht.

## Ergebnis- und Fehlervertrag

Die Function liefert immer genau eine Zeile:

| Zustand | `PathExists` |
|---|---:|
| mindestens ein Pfadtreffer | `1` |
| kein Treffer | `0` |
| ungültiges JSON | `0` |
| ungültiger oder nicht unterstützter Pfad | `0` |
| mindestens ein SQL-NULL-Argument | SQL `NULL` |

JSON `null` zählt als vorhandener Wert. Die Modi `lax` und `strict` sind
syntaktisch zulässig, führen aber wegen des fehlerfreien Existenzvertrags
nicht zu unterschiedlichen Fehlern.

## Provider- und Objektentscheidung

Ein beliebig tiefer Pfad mit Wildcard kann mehrere aktuelle JSON-Knoten
besitzen. Parser und Traversierung benötigen deshalb einen veränderlichen
Frontier. T-SQL erlaubt diesen Zustand nicht in einer echten Inline TVF.

Die V1-API ist daher eine Multi-statement TVF. Diese Entscheidung hat folgende
Folgen:

- der Optimizer besitzt keine vollständige Sicht auf die interne
  Kardinalität;
- Pfadschritte materialisieren Treffer in Table Variables;
- Wildcard-Kosten wachsen mit der Zahl der Treffer;
- ein zusätzlicher SVF-Wrapper wird nicht angeboten, weil er keine
  semantisch äquivalente Inline-TVF-Alternative hätte und eine weitere
  Parallelitätssperre einführen könnte.

Geprüfte Alternativen:

- `JSON_VALUE`/`JSON_QUERY` unterscheiden fehlende Werte nicht zuverlässig
  von JSON `null` und können bei ungültigen Pfaden Fehler auslösen;
- dynamisches SQL ist in UDFs nicht zulässig und wäre für untrusted Pfade ein
  unnötiges Security-Risiko;
- eine Inline-TVF mit fester maximaler Pfadtiefe würde den öffentlichen
  Vertrag künstlich an eine unübersichtliche Anzahl kopierter Joins binden;
- SQL CLR ist für den kleinen portablen V1-Scope nicht gerechtfertigt.

## Parser- und Traversierungsmodell

Der Parser erzeugt geordnete Segmente:

- `P`: Property;
- `I`: Array Index;
- `W`: Array Wildcard.

Quotierte Schlüssel werden erst nach erfolgreicher `ISJSON`-Prüfung eines
synthetischen Ein-Element-Arrays mit `OPENJSON` decodiert. Dadurch führen
ungültige Escapes nicht zu Providerfehlern.

Die Root-Eingabe wird ebenfalls in ein synthetisches Array eingebettet.
Dadurch können SQL Server 2019 und neuer auch skalare JSON-Roots validieren.
Genau ein Arrayelement verhindert, dass mehrere kommaseparierte Werte als ein
Dokument akzeptiert werden.

Jeder Segment-Schritt expandiert ausschließlich Objekt- oder Array-Knoten mit
`OPENJSON`. Property-Namen und Array-Indizes werden mit
`Latin1_General_100_BIN2` verglichen. Das entspricht der dokumentierten
case-sensitiven, collation-unabhängigen Key-Semantik von `OPENJSON`.

## Grenzen und Teststrategie

Pfade sind auf 4.000 UTF-16-Codeunits begrenzt. Nicht quotierte
Property-Namen verwenden im V1-Scope ASCII-Alphanumerik und `_`; weitere und
Unicode-Namen bleiben über die quotierte Form vollständig erreichbar.

Die CI prüft SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170,
native Parität im gemeinsamen Pfadsubset, synthetische Fehler- und
Collation-Fälle, Wiederholungsdeployment, Central-Aufruf und Uninstall.
Physische SQL-Server-2019-/2022- sowie Windows-Läufe bleiben gezielte
Releasevalidierung.

Aktuelle Evidenz:
[Run 30568128943](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128943)
– der beschriebene SQL-Server-2025-Linux-Scope ist erfolgreich;
Modulstatus `partially validated`.

## Primärquellen

- [Microsoft: JSON_PATH_EXISTS](https://learn.microsoft.com/en-us/sql/t-sql/functions/json-path-exists-transact-sql?view=sql-server-ver17)
- [Microsoft: JSON path expressions](https://learn.microsoft.com/en-us/sql/relational-databases/json/json-path-expressions-sql-server?view=sql-server-ver17)
- [Microsoft: OPENJSON](https://learn.microsoft.com/en-us/sql/t-sql/functions/openjson-transact-sql?view=sql-server-ver17)
