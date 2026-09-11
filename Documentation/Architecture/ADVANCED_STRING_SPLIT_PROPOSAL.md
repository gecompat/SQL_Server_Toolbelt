# Vorschlag: Erweiterter String-Split (`TC-2026-032`)

## Status

`TC-2026-032` bleibt Research. Dieses Dokument bereitet die spätere
funktionsbezogene Besprechung vor; es autorisiert weder ein Modul noch eine
öffentliche SQL-Schnittstelle.

## Problem

`toolbelt.string.split-characters` verarbeitet bewusst einzelne, literal
verglichene UTF-16-Codeeinheiten. Strukturierte Eingaben benötigen darüber
hinaus Separatorstrings beliebiger Länge sowie Bereiche, in denen Separatoren
als Daten gelten. Dieser Bedarf ist weder ein CSV-Standard noch ein
Regex-Vertrag.

## Empfohlener V1-Schnitt

Der erste Erweiterungsslice sollte ein neues, portables T-SQL-Modul sein und
genau eine relationale TVF bereitstellen. Der Arbeitstitel
`toolbelt.string.split-advanced` und mögliche Objektnamen sind ausdrücklich
nicht festgelegt.

Der vorgeschlagene Vertrag begrenzt V1 auf:

- einen oder mehrere nichtleere Separatorstrings;
- längsten Treffer bei Präfixüberschneidungen; bei gleicher Länge entscheidet
  die binäre Reihenfolge der Separatoren;
- ein einzelnes Quote-Zeichen, das innerhalb eines Tokens Separatoren schützt;
- ein einzelnes Escape-Zeichen, das Quote, Escape und den Beginn eines
  Separators als literale Daten schützt;
- nicht verschachtelte Quotes;
- Originaltoken einschließlich Quote und Escape; ein späteres Unquoting ist
  ein eigener Transformationsvertrag;
- stabile `bigint`-Ordinals und einen definierten leeren-Token-Schalter.

Damit bleibt die Funktion ein Tokenizer. CSV-Dialekte, mehrzeichenlange Quote-
oder Escape-Strings, Kommentarregeln, Backslash-spezifische Interpretation,
unquoting, Typkonvertierung und reguläre Ausdrücke gehören nicht zu V1.

## Eingabe- und Fehlerregeln

Die spätere Besprechung sollte diese Regeln übernehmen oder bewusst ändern:

| Situation | Vorgeschlagene Wirkung |
|---|---|
| SQL `NULL` im Text | Leeres Resultset |
| SQL `NULL` in Separator-, Quote- oder Escape-Konfiguration | Fehler |
| Leere Separatorliste, leerer Separator oder Duplikat | Fehler vor Tokenisierung |
| Unbeendete Quote | Fehler mit stabiler Toolbelt-Fehlernummer |
| Escape am Ende | Fehler mit stabiler Toolbelt-Fehlernummer |
| NUL im Text oder Konfigurationswert | Fehler vor Tokenisierung |
| Quote innerhalb eines ungeschützten Tokens | Literal; nur das Quote-Zeichen wechselt den Zustand |
| Mehrere übereinstimmende Separatoren | längster Treffer, danach binäre Reihenfolge |

Der Vergleich muss `Latin1_General_100_BIN2` verwenden, damit die Wirkung
nicht von der Datenbankcollation abhängt. Das Atom bleibt eine UTF-16-
Codeeinheit; Graphemcluster sind kein V1-Ziel.

## Technologieentscheidung

Eine iterative T-SQL-Implementierung ist für den vorgeschlagenen endlichen
Zustandsautomaten portabel auf SQL Server 2019, 2022 und 2025. Sie vermeidet
eine zusätzliche CLR-, Trust- oder Plattformabhängigkeit. Der Preis ist eine
materialisierte Zustandsfolge; V1 benötigt daher eine explizite Eingabegrenze
und darf keine Parallelplan- oder allgemeine LOB-Performancezusage geben.

SQL CLR wäre erst sinnvoll, wenn ein nachfolgender Vertrag verschachtelte
Strukturen, volle CSV-Semantik oder deutlich größere Eingaben verlangt. Regex
ist kein Ersatz, weil Quote- und Escape-Zustände eine zustandsbehaftete
Tokenisierung benötigen und der vorhandene Regex-Dialekt diesen Vertrag nicht
abdeckt.

## Grenzen und Testmatrix

Vor Implementierung werden konkrete Eingabe- und Separatorlimits festgelegt.
Die Testmatrix muss mindestens enthalten:

- überlappende und gleichlange Separatoren;
- Separatoren innerhalb und außerhalb von Quotes;
- Escape vor Quote, Escape und Separatorbeginn;
- leere Tokens, Randseparatoren und leere Eingabe;
- unvollständige Quote und Escape am Ende;
- BIN2-Verhalten unter case-insensitiver und case-sensitiver Datenbankcollation;
- BMP- und Supplementary-Unicode an Token- und Separatorgrenzen;
- lokale, zentrale, Wiederholungs-, Kollisions- und Uninstall-Pfade;
- physische Windows-/Linux-Matrix für SQL Server 2019, 2022 und 2025.

## Alternativen

| Alternative | Bewertung |
|---|---|
| Erweiterung des bestehenden Character-Split-Moduls | Verworfen: Der V1-Vertrag bliebe unklar und würde eine validierte API nachträglich verbreitern. |
| SQL Server 2025 `REGEXP_SPLIT_TO_TABLE` | Verworfen: keine portable 2019-/2022-Abdeckung und keine Quote-/Escape-Semantik. |
| SQL CLR | Zurückgestellt: erhöht Deployment-, Trust- und Plattformaufwand ohne Nutzen für den begrenzten Automaten. |
| Vollständiger CSV-Parser | Zurückgestellt: Dialekt- und Transformationsentscheidungen sind über den Bedarf hinausgehend. |

## Entscheidungspunkt

Vor dem ersten öffentlichen Objekt muss der Benutzer nur noch bestätigen,
ob der empfohlene V1-Schnitt inklusive Originaltoken-Ausgabe, Einzelzeichen
für Quote/Escape und Fehler bei unvollständiger Quote/Escape gilt. Danach
folgen Modulname, konkrete Signatur, Fehlerbereich und Implementierung als
eigene Welle.

## Quellen

- [Microsoft: STRING_SPLIT](https://learn.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql?view=sql-server-ver17)
- [Microsoft: REGEXP_SPLIT_TO_TABLE](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-split-to-table-transact-sql?view=sql-server-ver17)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-032-erweiterter-string-split-mit-mehrzeichigen-separatoren-escape-und-quote)
