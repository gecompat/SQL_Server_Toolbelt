# Vorschlag: Erweiterter String-Split (`TC-2026-032`)

## Status

`TC-2026-032` bleibt Research. Dieses Dokument bereitet die spätere
funktionsbezogene Besprechung vor; es autorisiert weder ein Modul noch eine
öffentliche SQL-Schnittstelle.

## Nutzeranforderung vom 2026-10-01

Der Benutzer verlangt eine öffentlich relationale Split-TVF als Pflicht.
Eine USP darf ergänzend angeboten werden, ersetzt die TVF aber niemals.
Unquoting wird als eigener späterer Funktionsslice unter diesem Kandidaten
geführt; dafür liegt noch keine Implementierungsfreigabe vor. Originaltoken
und spätere Transformation bleiben getrennte Verträge.

Diese Anforderung legt noch keine konkrete Signatur, Fehlersemantik oder
Implementierung fest. Die folgenden Konkretisierungen vom 2026-10-01 sind
Entscheidungsvorschläge für Fehlerausgabe, Zustandsregeln und Zielgrenzen;
sie sind weder implementiert noch runtime-validiert oder freigegeben.

## Beschlossene Folgescope-Grenzen vom 2026-10-01

Der Benutzer hat zunächst das Entfernen eines äußeren Quote-Paars gewählt
und danach die Innenbehandlung präzisiert: Verdoppelte Quotes werden im
gequoteten Token dekodiert; `"hallo""du"""` wird `hallo"du"`.
Die zuerst angenommene unveränderte Innenbehandlung war ein Missverständnis
und ist durch diese Präzisierung ersetzt. Andere Escapeformen, ungequotete
Tokens und Fehlerfälle sind noch offen. Die optionale `toolbelt_string.USP_SplitAdvanced` soll vorgesehen
werden und führt kein automatisches Unquoting aus. Diese Auswahl ist keine
Implementierungsfreigabe dieser Folgeslices; S2 bleibt separat freigegeben.

### Unquoting: Vorschlag zur weiteren Vertragsbesprechung

Arbeitsname `toolbelt_string.TVF_UnquoteToken`: portabler relationaler
T-SQL-Kern mit `@Input nvarchar(max)` und `@Quote nvarchar(max)`. Ein optionaler
Scalar-Wrapper ist nicht automatisch Teil des Slices. Vorschlag: Nur wenn
die erste und letzte UTF-16-Codeeinheit dem aktiven Quote-Zeichen entsprechen
und mindestens zwei Codeeinheiten vorhanden sind, wird genau dieses Paar
entfernt und jedes verdoppelte Quote im Inneren einmal dekodiert. Keine
rekursive Paarentfernung und kein Entfernen von Quotes mitten in einem
ungequoteten Token. Ob ungequotete Tokens unverändert bleiben, einzelne
innere Quotes in gequoteten Tokens Fehler sind und Backslash-Escapes einen
eigenen Modus erhalten, bleibt ausdrücklich zu bestätigen. Die Randprüfung
und das Verhalten bei unvollständigem äußerem Paar sind noch offen.

Vorgeschlagen: derselbe deaktivierbare Ein-Codeunit-Quote-Vertrag,
BIN2-Vergleich, NULL-No-op, 65.536-Codeunit-Inputgrenze und atomare
Errorrow-Form wie S2. Whitespace wird nicht getrimmt; ein reines Paar ergibt
leeren Text. Das Verhalten bei einem einzelnen Quote bleibt offen. Signatur,
Resultset, Fehler und Randfälle brauchen noch eine ausdrückliche
funktionsbezogene Vertrags- und Implementierungsfreigabe.

Alternative ausschließlich wörtliche Randentfernung reicht nach dem
Nutzerbeispiel nicht aus. Globales Entfernen innerer Steuerquotes ist ebenfalls
nicht der gewünschte Vertrag. Die Funktion dekodiert einen einzelnen Token,
nicht eine vollständige CSV-Zeile. Tests sollen äußere/verdoppelte/ungepaarte
Quotes, abgegrenzte Escapeformen, Leer-/NULL-Werte, Whitespace, mehrere Paare,
Unicode, BIN2 und Grenzen abdecken.

### Optionale USP: Vorschlag zur weiteren Vertragsbesprechung

`toolbelt_string.USP_SplitAdvanced` soll dieselben fachlichen Eingaben und
Defaults wie S2 sowie den vollständigen Hilfe-/Debug-/ResultTable-/KeepData-
Vertrag verwenden. Sie ruft ausschließlich den kanonischen TVF-Kern auf und
gibt Originaltokens aus. Unquoting wird nur vom Caller ausdrücklich
komponiert und ist weder Default noch versteckte Nachverarbeitung.

Vorschlag: Eine TVF-Errorrow wird vor ResultTable-Mutation in einen stabilen
THROW übersetzt; vollständige Vorprüfung verhindert Teiltokens und
Teiländerungen bei Geschäftsfehlern. Konkreter Fehlerbereich und
Erfolgsschema bleiben zu bestätigen. Die TVF ist Pflicht und wird nicht
ersetzt; Alternative bleibt der alleinige TVF-Aufruf. Aufwand und Risiken
liegen in ResultTable-/Transaktions-/Fehlerkopplung, nicht in einer zweiten
Tokenizerlogik. Tests umfassen TVF-Parität, Originaltokens, Fehlerübersetzung,
unveränderte ResultTable bei Geschäftsfehlern, KeepData, Hilfe, Debug und
Lifecycle. Implementierungsfreigabe steht aus.

## Problem und bestehender V1-Schnitt

`toolbelt.string.split-characters` verarbeitet bewusst einzelne, literal
verglichene UTF-16-Codeeinheiten. Strukturierte Eingaben benötigen darüber
hinaus Separatorstrings beliebiger Länge sowie Bereiche, in denen Separatoren
als Daten gelten. Dieser Bedarf ist weder ein CSV-Standard noch ein
Regex-Vertrag.

## Empfohlener V1-Schnitt

Der erste Erweiterungsslice sollte ein neues, portables T-SQL-Modul sein und
eine kanonische relationale TVF bereitstellen; eine ergänzende USP ist
optional. Die Arbeitsnamen `toolbelt.string.split-advanced` und
`toolbelt_string.TVF_SplitAdvanced` sind Vorschläge, keine bereits
festgelegten öffentlichen Identifier.

Der vorgeschlagene Vertrag begrenzt V1 auf:

- einen oder mehrere nichtleere Separatorstrings;
- längsten Treffer bei Präfixüberschneidungen; binäre Duplikate werden vorab
  abgelehnt, sodass gleichlange Treffer keine zusätzliche Priorität benötigen;
- ein optionales Quote-Zeichen, das innerhalb eines Tokens Separatoren schützt;
- ein optionales Escape-Zeichen, das allgemein die folgende UTF-16-Codeeinheit
  vor Interpretation schützt;
- nicht verschachtelte Quotes;
- Originaltoken einschließlich Quote und Escape; ein späteres Unquoting ist
  ein eigener Transformationsvertrag;
- 1-basierte `bigint`-Ordinals, nach Leertokenfilterung lückenlos, wie beim
  bestehenden Character-Split;
- genau eine Fehlerzeile bei erwarteten Geschäftsfehlern, ohne Teiltokens.

Damit bleibt die Funktion ein Tokenizer. CSV-Dialekte, mehrzeichenlange Quote-
oder Escape-Strings, Kommentarregeln, Backslash-spezifische Interpretation,
unquoting, Typkonvertierung und reguläre Ausdrücke gehören nicht zu V1.

## Vorgeschlagene Signatur und Resultset

Die Signatur wird ausschließlich als Beschreibung vorgeschlagen:

```text
toolbelt_string.TVF_SplitAdvanced
    @Input           nvarchar(max)
    @SeparatorsJson  nvarchar(max)
    @Quote           nvarchar(max), Default: ein doppeltes Anführungszeichen
    @Escape          nvarchar(max), Default: ein Backslash
    @KeepEmpty       bit, Default: 1
```

Die `max`-Konfigurationsparameter erlauben die Prüfung überlanger Angaben,
bevor eine automatische Kürzung auf einen schmaleren Parametertyp stattfinden
könnte. Sie begründen keine unbeschränkte Verarbeitung.

| Spalte | Vorgeschlagener Typ | Bedeutung |
|---|---|---|
| `Value` | `nvarchar(max) NULL` | Originaltoken; bei Fehler `NULL` |
| `Ordinal` | `bigint NULL` | 1-basiert und nach Filter lückenlos; bei Fehler `NULL` |
| `IsValid` | `bit NOT NULL` | `1` für Token, `0` für einzige Fehlerzeile |
| `ErrorCode` | `varchar(64) NULL` | Symbolischer Geschäftscode; bei Erfolg `NULL` |
| `ErrorPosition` | `bigint NULL` | 1-basierte Inputposition in UTF-16-Codeeinheiten; bei Konfigurations-/Größenfehlern `NULL` |

Nur `ORDER BY Ordinal` garantiert die Tokenreihenfolge. Whitespace einschließlich
nachfolgender Leerzeichen bleibt erhalten; ausschließlich ein Token der Länge
null ist leer.

## Vorgeschlagene Eingabe- und Zustandsregeln

Die spätere Besprechung sollte diese Regeln übernehmen oder bewusst ändern:

| Situation | Vorgeschlagene Wirkung |
|---|---|
| SQL `NULL` im Text | Frühzeitiger No-op: null Zeilen, auch bei ungültiger Konfiguration |
| Leerer Text | Bei `@KeepEmpty = 1` ein gültiges leeres Token mit Ordinal 1; sonst null Zeilen |
| `@KeepEmpty IS NULL` | Entspricht `1`, wie beim bestehenden Character-Split |
| SQL `NULL` in Separator-, Quote- oder Escape-Konfiguration | Eine Fehlerzeile |
| `@Quote = N''` oder `@Escape = N''` | Jeweiliges Steuerzeichen deaktiviert |
| Aktive Quote/Escape | Je genau eine Nicht-Surrogate-UTF-16-Codeeinheit; wenn beide aktiv sind, müssen sie verschieden sein |
| Separatorliste | Nichtleeres JSON-Array ausschließlich nichtleerer Strings; keine Nullwerte, anderen JSON-Typen oder binären Duplikate |
| Separator mit aktivem Quote-/Escape-Zeichen | Konfigurationsfehler vor Tokenisierung |
| Unescaped Quote an beliebiger Tokenposition | Öffnet oder schließt den Schutzbereich; keine Verschachtelung |
| Aktives Escape | Schützt die unmittelbar folgende Codeeinheit innerhalb und außerhalb von Quotes; beide bleiben in `Value` erhalten |
| Unbeendete Quote | Eine Fehlerzeile; Position der öffnenden Quote |
| Escape am Ende | Eine Fehlerzeile; Position des terminalen Escape |
| NUL im Text oder dekodierter Konfiguration | Eine Fehlerzeile vor Tokenisierung |
| Mehrere übereinstimmende Separatoren außerhalb von Quotes | Längster Treffer |

Der Vergleich muss `Latin1_General_100_BIN2` verwenden, damit die Wirkung
nicht von der Datenbankcollation abhängt. Das Atom bleibt eine UTF-16-
Codeeinheit; Graphemcluster sind kein V1-Ziel. Ein Escape vor einem
Supplementary-Paar schützt zunächst nur dessen High-Surrogate-Codeeinheit:
der Cursor rückt über Escape und diese Codeeinheit hinweg, verarbeitet danach
die Low-Surrogate-Codeeinheit regulär weiter. Die ursprünglichen Codeeinheiten
werden unverändert ausgegeben; es gibt keine Unicode-Scalar- oder
Graphem-Atomizitätszusage für die Parsersteuerung.

## Vorgeschlagene Geschäftsfehler

Ein erwarteter Geschäftsfehler liefert genau eine Zeile mit `IsValid = 0`,
`Value = NULL`, `Ordinal = NULL` und einem symbolischen `ErrorCode`.
Es werden auch bei einem Fehler am Inputende keine zuvor gefundenen Tokens
zurückgegeben. Tokenzeilen besitzen `IsValid = 1` und zwei `NULL`-Fehlerfelder.

Die vorgeschlagene Prüfpriorität lautet:

1. `@Input IS NULL` beendet den Aufruf als No-op.
2. Fehlende Konfiguration, in Reihenfolge Separator-JSON, Quote, Escape.
3. Zielgrenzen, in Reihenfolge Input, JSON-Rohtext, Quote-/Escape-Länge.
4. JSON-Syntax und Arrayform; dann Separatoranzahl.
5. Separatoren in JSON-Arrayreihenfolge: Typ, Leerwert, Länge, NUL und binäres
   Duplikat; danach NUL/Surrogates in Steuerzeichen, identische aktive Zeichen
   und Separator-Steuerzeichenkonflikte in Arrayreihenfolge.
6. Input-NUL an der ersten betroffenen Inputposition.
7. Tokenisierung von links nach rechts; terminales Escape wird beim Erreichen
   seiner Position gemeldet. Erst nach vollständigem Scan wird eine noch
   offene Quote gemeldet. Bei beiden Endproblemen hat terminales Escape
   deshalb Vorrang; die Quote meldet sonst ihre Öffnungsposition.

Die folgende Codezuordnung ist ebenfalls ein Vorschlag zur Freigabe,
keine neue Artefakt-ID oder bereits vergebene SQL-Fehlernummer:

| Erwarteter Fehler | Vorgeschlagener `ErrorCode` |
|---|---|
| Konfigurations-NULL, Quote-/Escape-Länge oder -Surrogate, identische aktive Steuerzeichen, Separator-Steuerzeichenkonflikt, Nicht-String-Separator oder leeres Array | `INVALID_CONFIGURATION` |
| Input über Zielgrenze | `INPUT_LIMIT_EXCEEDED` |
| JSON-Rohtext über Zielgrenze | `JSON_LIMIT_EXCEEDED` |
| Ungültige JSON-Syntax oder Root ist kein Array | `INVALID_SEPARATOR_JSON` |
| Mehr als 16 Separatoren oder Separator über Zielgrenze | `SEPARATOR_LIMIT_EXCEEDED` |
| Leerer Separatorstring | `EMPTY_SEPARATOR` |
| Binär doppelter Separator | `DUPLICATE_SEPARATOR` |
| NUL im Input oder dekodierter Konfiguration | `NUL_NOT_ALLOWED` |
| Am Scanende noch offene Quote | `UNTERMINATED_QUOTE` |
| Terminales Escape | `DANGLING_ESCAPE` |

`ErrorPosition` bezieht sich ausschließlich auf den ursprünglichen Input.
Konfigurations- und Größenfehler erhalten `NULL`; Input-NUL, terminales Escape
und unterminierte Quote erhalten die oben definierten Positionen. Erwartete
JSON-Syntaxfehler werden vor dem Aufruf des JSON-Parsers abgeprüft.
Unerwartete Ressourcen- oder Serverfehler bleiben Enginefehler und werden
nicht verschluckt oder als Geschäftsfehler umetikettiert.

## Technologieentscheidung

Für den endlichen Zustandsautomaten wird eine reine T-SQL-Multi-statement-TVF
mit internen Tabellenvariablen vorgeschlagen. Die atomare fachliche Ausgabe
nach vollständiger Prüfung begründet die Ausnahme von der Inline-TVF-Präferenz;
eine gleichwertige relationale Alternative ist vor Implementierung zu prüfen.
Dies ist kein Build- oder Runtime-Nachweis. Materialisierung und wiederholte
mengenorientierte Aufrufe können teuer sein; es gibt keine Parallelplan-,
SARGability- oder allgemeine LOB-Performancezusage.

Microsoft dokumentiert eingeschränkte UDF-Fehlerbehandlung sowie zulässige
Tabellenvariablen. Die Errorrow vermeidet eine eigene Exception für erwartete
Geschäftsfehler. Eine spätere optionale USP verwendet denselben TVF-Kern und
darf die Errorrow in `THROW` übersetzen; sie erhält keine zweite Tokenizerlogik.

SQL CLR wäre erst sinnvoll, wenn ein nachfolgender Vertrag verschachtelte
Strukturen, volle CSV-Semantik oder deutlich größere Eingaben verlangt. Regex
ist kein Ersatz, weil Quote- und Escape-Zustände eine zustandsbehaftete
Tokenisierung benötigen und der vorhandene Regex-Dialekt diesen Vertrag nicht
abdeckt.

## Grenzen und Testmatrix

Die folgenden Zielgrenzen sind Vorschläge vom 2026-10-01, nicht validierte
Kapazitäts- oder Performancewerte:

| Dimension | Vorgeschlagene harte Grenze |
|---|---:|
| Input | 65.536 UTF-16-Codeeinheiten |
| JSON-Rohtext | 16.384 UTF-16-Codeeinheiten |
| Separatoranzahl | 16 |
| Einzelner dekodierter Separator | 64 UTF-16-Codeeinheiten |

Längen werden einschließlich nachfolgender Leerzeichen gezählt; Überschreitung
liefert eine Fehlerzeile und keine stille Kürzung. Vor Implementierung müssen
diese Zielgrenzen bestätigt werden. Die geplante Testmatrix muss enthalten:

- überlappende und gleichlange Separatoren;
- Separatoren innerhalb und außerhalb von Quotes;
- Escape vor Quote, Escape, Separatorbeginn und gewöhnlichem Zeichen;
- leere Tokens, Randseparatoren und leere Eingabe;
- unvollständige Quote und Escape am Ende;
- BIN2-Verhalten unter case-insensitiver und case-sensitiver Datenbankcollation;
- BMP- und Supplementary-Unicode an Token- und Separatorgrenzen;
- Errorrow-Schema, Fehlerpriorität/-positionen und Ausschluss von Teiltokens;
- NULL-No-op, deaktivierte Steuerzeichen und alle Zielgrenzen;
- 1-basierte lückenlose Ordinals nach Leertokenfilterung und `CROSS APPLY`;
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

Vor dem ersten öffentlichen Objekt werden Arbeitsnamen, Signatur, fünf
Resultspalten, Errorrow-Vertrag einschließlich Priorität/Positionen,
NULL-No-op, allgemeine Escape-Semantik, Quote-Zustandsregel, Separator-
Steuerzeichenkonflikte und Zielgrenzen bestätigt oder bewusst geändert.
Erst danach folgt die ausdrückliche Implementierungsfreigabe für diesen
konkreten Funktionsslice. Die optionale USP und Unquoting bleiben spätere
gesonderte Slices; es entsteht keine automatische Freigabe dafür.

## Quellen

- [Microsoft: UDF-Erstellung und Einschränkungen](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine?view=sql-server-ver17) – am 2026-10-01 für UDF-Fehlergrenzen und Tabellenvariablen geprüft; kein Nachweis einer implementierten Split-TVF.
- [Microsoft: STRING_SPLIT](https://learn.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql?view=sql-server-ver17)
- [Microsoft: REGEXP_SPLIT_TO_TABLE](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-split-to-table-transact-sql?view=sql-server-ver17)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-032-erweiterter-string-split-mit-mehrzeichigen-separatoren-escape-und-quote)
