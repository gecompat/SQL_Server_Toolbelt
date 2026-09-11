# Vorschlag: Fuzzy String Matching (`TC-2026-011`)

## Status

`TC-2026-011` bleibt Research. Dieses Dokument bereitet die spätere
funktionsbezogene Besprechung vor und autorisiert kein Modul, keine SQL-CLR-
Assembly und kein öffentliches SQL-Objekt.

## Aktueller Native-Stand

Microsoft führt `EDIT_DISTANCE`, die Similarity-Varianten und
`JARO_WINKLER_DISTANCE` für SQL Server 2025 weiterhin als Preview. SQL Server
2019 und 2022 haben keine entsprechenden nativen Funktionen. Die aktuelle
`EDIT_DISTANCE`-Dokumentation bezeichnet den Algorithmus als
Damerau-Levenshtein, weist aber zugleich darauf hin, dass Transpositionen
derzeit nicht unterstützt werden. Daher ist der Preview-Name keine belastbare
Referenz für eine portable, versionsstabile Toolbelt-Semantik.

Die nativen Funktionen akzeptieren keine `varchar(max)`- oder
`nvarchar(max)`-Werte. Eine spätere Toolbelt-Grenze muss unabhängig davon
festgelegt und auf Ressourcenverbrauch geprüft werden.

## Empfohlene erste Funktion

Der erste Slice sollte nur eine explizite, symmetrische
**Levenshtein-Distanz ohne Transpositionen** bereitstellen. Das begrenzt die
Semantik auf Einfügen, Löschen und Ersetzen und vermeidet, dass ein möglicher
späterer Native-Preview-Wechsel eine stille Verhaltensänderung erzeugt.

Jaro-Winkler, Similarity-Skalierungen und transpositionsfähige Varianten
bleiben separate Funktionen. Sie unterscheiden sich bei Rundung,
Prefix-Gewichtung, Rückgabetyp und Grenzwerten und sollten nicht als
Optionsparameter in eine erste Distanzfunktion gedrängt werden.

## Vorgeschlagener V1-Vertrag

| Aspekt | Vorschlag |
|---|---|
| Einheit | UTF-16-Codeeinheiten; keine automatische Unicode-Normalisierung, Case-Faltung oder Collation-abhängige Gleichsetzung. |
| SQL `NULL` | Ein SQL-`NULL`-Argument ergibt SQL-`NULL`. |
| Leere Werte | Distanz zur leeren Zeichenfolge ist die Länge der anderen Eingabe. |
| Ergebnis | Nichtnegativer `int`; 0 genau für binär gleiche Eingaben. |
| Obergrenze | Optionaler nichtnegativer `maximum_distance`; wenn überschritten, liefert die Funktion eindeutig `maximum_distance + 1`, nicht einen geschätzten Wert. |
| Eingabelimit | Beide Eingaben werden vor Berechnung gegen einen explizit festgelegten, gleichen Codeeinheiten-Grenzwert geprüft. |
| Fehler | Negativer Grenzwert oder zu lange Eingabe erzeugen stabile Toolbelt-Fehler; es gibt kein stilles Kürzen. |

Die ``maximum_distance + 1``-Regel ermöglicht einen zeilenweisen, begrenzten
Algorithmus, ohne eine unpräzise Distanz als exaktes Ergebnis auszugeben.
Die konkrete Längengrenze gehört zur Freigabebesprechung, weil CPU und Speicher
bei edit-distance-artigen Verfahren von beiden Eingabelängen abhängen.

## Technologie und Grenzen

Für die beschriebene skalare Funktion ist ein `SAFE` SQL-CLR-Provider der
präferierte Kandidat: Eine Zeilenpuffer-Implementierung kann Speicher auf die
kürzere Eingabe begrenzen und ist auf Windows und Linux einheitlich prüfbar.
Eine T-SQL-Referenz eignet sich nur für kleine feste Testvektoren; sie ist
keine Ersatzimplementierung für den Mengenbetrieb.

Der CLR-Weg verlangt vor dem ersten Objekt die bereits etablierten
Assembly-/Hash-/Trust-/Uninstall-Regeln. Er darf weder `TRUSTWORTHY` noch
Datei-, Netzwerk-, Prozess- oder Registryzugriff benötigen. Ein rein nativer
SQL-Server-2025-Adapter ist kein Ersatz, weil er die 2019-/2022-Abdeckung
verliert und auf Preview-Verhalten aufbaut.

Die Funktion ist nicht SARGable. Große Kreuzprodukte oder Volltext-Suchen
gehören nicht zum ersten Scope; Aufrufer müssen Kandidaten vorfiltern. Tests
müssen feste Distanzvektoren, Symmetrie, Null/Leer, Grenzwert-Überschreitung,
Supplementary-Unicode, deterministische Ressourcenfehler, Mengenaufrufe,
Wiederholungsdeployment, Lifecycle und die SQL_Server_Lab-Matrix für 2019,
2022 und 2025 unter Windows und Linux umfassen. CUs sind nur bei
patchgebundenen Tests auszuwählen.

## Entscheidungspunkt

Vor einer Implementierungsfreigabe wird nur der vorgeschlagene V1-Schnitt
bestätigt oder geändert: Levenshtein ohne Transpositionen, binäre
UTF-16-Semantik, SQL-`NULL`-Propagation und optionaler Grenzwert mit dem
eindeutigen Überschreitungswert. Danach werden konkrete Signatur,
Eingabelimit, Fehlerbereich, Provider und Testvektoren als eigener
Funktionsvertrag festgelegt.

## Quellen

- [Microsoft: EDIT_DISTANCE](https://learn.microsoft.com/en-us/sql/t-sql/functions/edit-distance-transact-sql?view=sql-server-ver17)
- [Microsoft: JARO_WINKLER_DISTANCE](https://learn.microsoft.com/en-us/sql/t-sql/functions/jaro-winkler-distance-transact-sql?view=sql-server-ver17)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-011-fuzzy-string-matching-fur-sql-server-20192022)
