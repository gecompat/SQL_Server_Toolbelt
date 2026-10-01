# Vorschlag: Erweiterter String-Split (`TC-2026-032`)

## Status

Nachtrag 2026-10-01: Der nachfolgend besprochene S2-Vertrag wurde ausdrücklich freigegeben und als [TVF_SplitAdvanced](../../Modules/toolbelt.string.split-advanced/Documentation/TVF_SplitAdvanced.md) implementiert. Die folgenden Vorschlagsformulierungen dokumentieren den historischen Entscheidungsstand vor PR #114/#115; aktueller Vertrag und Evidenz liegen im Modul. Optionale USP und Unquoting bleiben getrennt und unfreigegeben.

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
und ist durch diese Präzisierung ersetzt. Weitere Innen-/Escape-Regeln waren
zu diesem Besprechungsstand noch offen; die nachfolgende Präzisierung
ersetzt offene Randregeln, ohne S2 zu ändern.
Die optionale `toolbelt_string.USP_SplitAdvanced` soll vorgesehen
werden und führt kein automatisches Unquoting aus. Diese Auswahl ist keine
Implementierungsfreigabe dieser Folgeslices; S2 bleibt separat freigegeben.

### Unquoting: Vorschlag zur weiteren Vertragsbesprechung

Arbeitsname `toolbelt_string.TVF_UnquoteToken`: portabler relationaler
T-SQL-Kern. Inputtyp, öffentliche Qualifier-/Modusparameter und Resultset sind
noch kein fertiger öffentlicher Vertrag. Ein optionaler Scalar-Wrapper ist
nicht automatisch Teil des Slices.

Präzisierung des Benutzers vom 2026-10-01, ersetzt die zuvor offene
Randprüfung: Im expliziten Qualifier-Modus sind passende äußere Delimiter
vorne und hinten Pflicht; fehlen sie oder passen sie nicht, ist das ein
Fehler. Öffnender und schließender Delimiter dürfen verschieden sein.
Ein explizites `[` oder `]` wählt dasselbe Paar `[]`.
Automatische Erkennung dagegen lässt unvollständig apparent gequoteten Text
wie `“Hallo` unverändert. Nur ein vollständig außen gequoteter Token wird
entquotet; im Inneren werden verdoppelte schließende Qualifier einmal
dekodiert. Beim Paar `[]` wird also ein inneres `]]` zu `]`.
Dies ist keine rekursive Paarentfernung, globale Quoteentfernung oder
Whitespace-/Textnormalisierung.

Historischer Besprechungsstand vom 2026-10-01 vor der nachfolgenden
Bestätigung: Auto-Kandidatenliste, malformed Innenbehandlung und konkrete
Backslash-Dekodierung waren noch offen. Dieser Stand wird durch die unten
datierte Nutzerbestätigung ersetzt, nicht als Implementierungsfreigabe
umgedeutet.

Weitere Nutzerpräzisierung vom 2026-10-01: Ein zusätzlicher Backslash-Escape-
Modus benötigt einen expliziten Opt-in-Parameter; er darf nicht automatisch
aktiv sein. Ohne dieses Opt-in bleibt Backslash literal. Die Auflösung
verdoppelter schließender Qualifier ist davon getrennte Quoting-Semantik
und aktiviert keinen globalen Escape-Modus. Der damals offene
Dekodierungsumfang wird nachfolgend konkretisiert; Parametername bleibt offen.
Daraus entsteht keine
Implementierungsfreigabe oder Änderung des bestehenden S2-Escape-Vertrags.

Weitere Semantikbestätigung vom 2026-10-01: Auf die drei konkreten
Empfehlungen zu Auto-Paaren, Innenbehandlung und Opt-in-Backslash antwortete
der Benutzer „so wie du vorschlägst!“. Damit sind folgende Regeln bestätigt,
jedoch keine konkrete öffentliche Funktionsimplementierung freigegeben:

| Auto-Paar | Öffnender Delimiter | Schließender Delimiter |
|---|---|---|
| ASCII doppelt | `"` U+0022 | `"` U+0022 |
| ASCII einfach | `'` U+0027 | `'` U+0027 |
| Eckige Klammern | `[` U+005B | `]` U+005D |
| Typografisch | `“` U+201C | `”` U+201D |
| Deutsch typografisch | `„` U+201E | `“` U+201C |

Auto entfernt genau ein vollständiges, passendes äußeres Paar aus dieser
Liste; sonst bleibt der Input unverändert. Es wird nicht getrimmt.
Die Innenbehandlung dekodiert verdoppelte schließende Delimiter;
ein einzelner unescaped schließender Delimiter im Inneren ist Fehler:
`[a]]b]` ergibt `a]b`, `[a]b]` ergibt einen Fehler.
Die Regel für expliziten Qualifier bleibt strenger: fehlende oder
unpassende äußere Delimiter sind dort Fehler, nicht unveränderte Ausgabe.

Der explizit aktivierte zusätzliche Backslash-Modus dekodiert ausschließlich
Backslash vor aktivem Quotezeichen sowie `\\` zu einem Backslash.
Keine `\n`-/`\t`-/Unicode-Escapeinterpretation; andere
Backslashfolgen bleiben unverändert. Ohne Opt-in ist Backslash literal.
Doubled closing Delimiter bleiben getrennte Quoting-Semantik, kein
impliziter globaler Escape-Modus.

Nachtrag 2026-10-01: Mit „do it“ bestätigt der Benutzer die letzten zwei
Randempfehlungen und Vertragsausarbeitung: Backslash schützt bei
asymmetrischen Paaren opening und closing; escaped letztes closing bildet
kein Randpaar, daher Explicit Fehler und Auto unverändert. Die zuvor offenen
Randpunkte sind ersetzt. Der unten konkretisierte öffentliche Vertrag
bleibt ein Vorschlag zur gebündelten Funktionsfreigabe, keine Implementierung.

Vorgeschlagen: BIN2-Vergleich, NULL-No-op, 65.536-Codeunit-Inputgrenze und atomare
Errorrow-Form wie S2. Whitespace wird nicht getrimmt; ein reines Paar ergibt
leeren Text. Parameterdarstellung für Auto-/expliziten Modus, deaktivierte
Erkennung und einzelne Delimiter brauchen noch Konkretisierung. Signatur,
Resultset, Fehler und Randfälle brauchen noch eine ausdrückliche
funktionsbezogene Vertrags- und Implementierungsfreigabe.

Alternative ausschließlich wörtliche Randentfernung reicht nach dem
Nutzerbeispiel nicht aus. Globales Entfernen innerer Steuerquotes ist ebenfalls
nicht der gewünschte Vertrag. Die Funktion dekodiert einen einzelnen Token,
nicht eine vollständige CSV-Zeile. Tests sollen äußere/verdoppelte/ungepaarte
Quotes, abgegrenzte Escapeformen, Leer-/NULL-Werte, Whitespace, mehrere Paare,
Unicode, BIN2 und Grenzen abdecken.

### Zur gebündelten Freigabe: Unquoting-TVF-Vertragsvorschlag

Alle folgenden API-/Fehler-/Grenzdetails sind Empfehlungen vom 2026-10-01,
keine Implementierungsfreigabe. Zweck: einen einzelnen Token entquoten;
keine CSV-Zeile, kein neuer Tokenizer und kein Scalar-Wrapper.

Signatur als Beschreibung, kein ausführbares SQL:

~~~text
toolbelt_string.TVF_UnquoteToken
    @Input             nvarchar(max)
    @Qualifier         nvarchar(max) = NULL
    @ClosingQualifier  nvarchar(max) = NULL
    @BackslashEscape   bit = 0
~~~

Für Auto ist nur Input fachlich zu konfigurieren; die übrigen
Argumentpositionen benötigen beim SQL-TVF-Aufruf DEFAULT-Platzhalter.
Kein zusätzlicher Modeparameter nötig. Beschreibendes Aufrufbeispiel:

~~~text
TVF_UnquoteToken(N'"Hallo"', DEFAULT, DEFAULT, DEFAULT)
~~~

max-Konfiguration verhindert stilles Abschneiden vor Validierung.

| Konfiguration | Vorschlag |
|---|---|
| Qualifier NULL | Auto mit genau den fünf bestätigten Paaren; ClosingQualifier muss NULL sein |
| Qualifier leer | Disabled: Originaltext unverändert, keine Innen-/Backslashdekodierung; ClosingQualifier muss NULL sein |
| Qualifier nicht leer, ClosingQualifier NULL | Explicit: eine Nicht-Surrogate-BMP-Codeeinheit; `[`/`]` wählen `[]`, U+201C/U+201D das englische Paar U+201C/U+201D, U+201E das deutsche Paar U+201E/U+201C; sonst symmetrisch |
| Beide nicht leer | Explicit: jeweils eine Nicht-Surrogate-BMP-Codeeinheit als ausdrückliches Öffnungs-/Schließpaar; etwa U+201C plus U+201C ohne automatische Umdeutung |
| ClosingQualifier leer, überlange/Surrogate-/NUL-Konfiguration oder ClosingQualifier ohne Explicit | INVALID_CONFIGURATION |
| BackslashEscape NULL | Entspricht 0; Opt-in nur beim Wert 1 |
| Delimiter Backslash bei BackslashEscape=1 | INVALID_CONFIGURATION, keine Delimiter-/Escape-Ambiguität |

Generische Explicit-Paare und typografische Defaults sind API-Vorschläge,
keine zusätzlichen Nutzerbeschlüsse. Keine mehrzeichenlangen Delimiter.
Auto bleibt auf die bestätigten fünf Paare beschränkt.

**Resultsetvorschlag:** nicht-NULL-Input genau eine Zeile; NULL-Input früher
No-op mit null Zeilen, selbst bei ungültiger Konfiguration.

| Feld | Typ | Bedeutung |
|---|---|---|
| Value | nvarchar(max) NULL | vollständig transformierter oder unveränderter Token; Fehler NULL |
| IsValid | bit NOT NULL | 1 Erfolg, 0 atomare Fehlerzeile |
| ErrorCode | varchar(64) NULL | symbolischer Geschäftscode; Erfolg NULL |
| ErrorPosition | bigint NULL | Originalposition ab 1; Konfiguration/Limit NULL |

Keine Ordinalspalte für einen einzelnen Token. Empty: Auto/Disabled gültiger
leerer Text, Explicit fehlendes Randpaar. Ein reines Randpaar ergibt leeren
Text. Ein äußeres Paar benötigt mindestens zwei UTF-16-Codeeinheiten.
Ein einzelnes ASCII-Quote bleibt in Auto unverändert; Explicit liefert
OUTER_PAIR_REQUIRED an Position 1, ohne eine negative Bodylänge zu bilden.
Auto ohne vollständiges Paar und Disabled geben Originaltext bytegetreu
aus, auch bei BackslashEscape=1; kein Trimmen/Normalisieren. Vorgeschlagene
Schutzregel: Input-NUL in allen Modi unzulässig. BIN2-Vergleich
Latin1_General_100_BIN2, UTF-16-Codeeinheiten mit DATALENGTH/2 inklusive
trailing Spaces; festes vorgeschlagenes Limit 65536, keine Kürzung.
Supplementary-Paare bleiben Text, keine Delimiter oder Graphemzusage.

**Prüf-/Dekodierungspriorität als vollständiger Vorschlag:**

1. NULL-Input früh beenden; dann Konfiguration, Inputlimit, erstes Input-NUL.
2. Disabled unverändert. Auto wählt nur anhand der ersten Codeeinheit,
   nicht anhand späterer Zeichen oder nach Trimmen.
3. Die äußersten Zeichen müssen das Paar bilden. Im Opt-in-Modus bestimmt
   ein lexikalischer Scan ab Position 2 bis zum Ende, ob das letzte closing
   escaped ist: Backslash plus opening/closing/Backslash konsumiert zwei
   Codeeinheiten; andere Folgen bleiben literal. Doubled closing ist kein
   Backslash-Escape. Escaped letztes closing: Explicit Fehler,
   Auto unverändert, kein früheres Zeichen als Ersatzrand.
4. Erst bei gültigem Paar beide Randzeichen reservieren. Body links nach
   rechts: erkannte Opt-in-Backslashfolge vor doubled closing; zwei closing
   vollständig im Body werden zu einem; einzelnes unescaped closing
   ist Fehler. Opening im Body ist literal, sofern es nicht zugleich
   closing ist. Keine Verschachtelung. Der reservierte äußere closing
   darf niemals zweite Hälfte eines Body-Doubles sein.
5. Andere Backslashfolgen und terminaler Body-Backslash bleiben literal;
   kein Split-Dangling-Escape erben. Erst nach vollständigem Erfolg Value
   publizieren; kein teilweise dekodierter Text.

| Vorgeschlagener ErrorCode | Bedeutung/Position |
|---|---|
| INVALID_CONFIGURATION | ungültige Zeichenkonfiguration; NULL |
| INPUT_LIMIT_EXCEEDED | über 65536; NULL |
| NUL_NOT_ALLOWED | erstes Input-NUL; Originalposition |
| OUTER_PAIR_REQUIRED | Explicit ohne gültigen Rand: Empty NULL, falsches erstes Zeichen 1, sonst letzte Originalposition |
| UNESCAPED_CLOSING_QUALIFIER | einzelnes closing im Body; Originalposition |

Konfiguration/Limit/NUL vor Randprüfung, Rand vor Body. Auto ohne Paar ist
bewusst kein Body-Validator. Fehlerzeile Value=NULL/IsValid=0, keine Teilausgabe;
Engine-/Ressourcenfehler bleiben Enginefehler. Codes sind Vorschläge, keine
neuen Artefakt-IDs.

Technikempfehlung: dependencyfreier T-SQL-Kern im Split-Advanced-Modul.
Inline-Alternative prüfen; MSTVF-Ausnahme nur bei technisch begründeter
bounded zustandsabhängiger Dekodierung/atomarer Ausgabe. Kein Scalar-Wrapper
in diesem Slice. Lifecycle-/Registryversion erst nach Freigabe koppeln.

Alternativen: reine Randentfernung erfüllt doubled-Semantik nicht; globale
Quoteentfernung ist falsch; generischer C-/JSON-Unescape würde unerwünschte
n/t/Unicodefolgen interpretieren; CSV/CLR erweitert Scope ohne Bedarf.
Risiken: Escape-/Double-Präzedenz, typografische Ähnlichkeit, Fehlermissachtung
und LOB-Kopierkosten; keine Streaming-/Durchsatz-/Parallelitätszusage.

Geplante Tests, nicht ausgeführt: alle Auto-/Explicit-Paare, generische
Paare, NULL/Empty/Disabled/Config, escaped letzter Rand, odd/even
Backslash-Runs, opening/closing/Backslash-Escape, andere Folgen literal,
doubled/single closing und reservierter Außenrand, unveränderte Nichttreffer,
Whitespace/Surrogates/BIN2/NUL, 65536/65537, Fehlerpriorität/Originalpositionen,
atomare Ausgabe/APPLY, Local/Central/Upgrade/Kollision/Uninstall und
SELECT-Minimalrechte. Risikobasiert zuerst 2019 Linux und 2025 Windows;
weitere Ziele nur bei Unterschieden oder Providerimpact. Niedrigprivilegiertes
Cross-DB benötigt mapped Caller und getrennte Evidenz.

### Optionale USP: konkreter Vertragsvorschlag zur Freigabe

Nur Fassade des vorhandenen TVF-Kerns, keine zweite Parserlogik und kein
Unquoting. Signatur als Beschreibung:

~~~text
toolbelt_string.USP_SplitAdvanced
    @Input           nvarchar(max) = NULL
    @SeparatorsJson  nvarchar(max) = NULL
    @Quote           nvarchar(max) = N'"'
    @Escape          nvarchar(max) = N'\'
    @KeepEmpty       bit = 1
    @ResultTable     sysname = NULL
    @KeepData        bit = 0
    @Debug           tinyint = 0
    @Hilfe           bit = 0
~~~

Fachliche S2-Semantik unverändert; technische NULL-Defaults ermöglichen
Help ohne Pflichtwerte. Erfolgsschema: Value nvarchar(max) NOT NULL,
Ordinal bigint NOT NULL; Originaltokens und lückenlose Ordinals. Keine
Errorrow-Spalten im Erfolgsschema, da Fehler als THROW. SELECT nach Ordinal,
keine physische Reihenfolge in ResultTable.

Vorschlag NULL-No-op: ResultTable=NULL leeres Erfolgsschema; gesetzte
ResultTable völlig unverändert, selbst bei KeepData=0. Ein leeres
Nicht-NULL-Splitergebnis unterliegt dagegen regulärem Replace/Append.
Der Wrapper wertet die TVF einmal in einem privaten Snapshot aus, prüft alle
Errorrows und wirft Geschäftsfehler vor Ausgabe/ResultTable-Mutation.
Stabiler technisch zuzuordnender Wrapper-THROW mit symbolischem TVF-Code
und Position, ohne Textinhalt. Keine numerische Reservierung durch dieses
Dokument; kollisionsfreie Zuordnung ist Umsetzungspflicht.
Engine-/ResultTablefehler behalten Originalnummer und Zustand.

Der gesamte [USP-Vertrag](../Standards/USP_CONTRACT.md) gilt: vier
Standardparameter zuletzt in vorgeschriebener Reihenfolge; Help ausschließlich
standardisiertes Help-Resultset/Pflichtsections, kein fachlicher Aufruf,
keine Validierung/Mutation/Debug. Debug nur Messages, keine extra Resultsets
oder Input-/Tokeninhalte. KeepData/Debug/Hilfe NULL werden zu 0 normalisiert.

ResultTable=NULL genau ein SELECT; sonst existierende caller-lokale Temp
und explizite Spaltenliste, keine permanenten/globalen/variablen Tabellen,
kein INSERT EXEC. Canonical helper USP_PrepareResultTable mindestens 1.0.0:
Replace/Append, leere Schemaanpassung, voller Preflight vor Mutation,
KeepData=1 bei befüllt-unpassendem Schema Fehler; keine Callerconstraints
entfernen. Erwartete Business-/Preflightfehler lassen das Ziel unverändert.
Insert-/Enginefehler: eigene Transaktion oder Savepoint im committable
Caller-Kontext; nur eigenen Scope soweit technisch möglich zurückrollen,
niemals Callertransaktion pauschal committen/rollbacken. Bei XACT_STATE=-1
keine Savepointgarantie, Originalfehler weitergeben, Callerrollback nötig.

Dependencies vorgeschlagen: TVF-Kern und ResultTable-Runtime für die USP;
deklarierte Modul-/Lifecyclekopplung gehört zur späteren Freigabe, heute
keine Manifeständerung. EXECUTE/SELECT/Cross-DB-Rechte minimal nachweisen,
kein automatisches Grant/TRUSTWORTHY. Local/Central separat prüfen.

Tests nach Freigabe: TVF-Parität/Originaltokens, alle Geschäftsfehler vor
Zielmutation, NULL versus leeres Nicht-NULL-Ergebnis, beide Ausgabewege,
vollständige Help-Schema-/Bypass-/Debugtests, alle KeepData-/Schemaszenarien,
Dummyspalten/Constraints/Blocker, Callertransaktion/Savepoint/Enginefehler,
Nested ResultTable, Collation/Central, Kollision/Upgrade/Uninstall. Zunächst
2019 Linux/2025 Windows, dann scopebezogen. Alternative: direkter TVF-Aufruf.
Risiken: Snapshotkopien, Mutation-/Transaktions-/Dependencykopplung;
keine neue Parserfunktion. USP-Implementierungsfreigabe steht separat aus.

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
