# Regex-Captures und gruppenbezogenes Replace

## Freigabe, Scope und Vor-Source-Gate

Die Einzelfreigabe vom 2026-10-01 in `.ai/BACKLOG.md` umfasst sämtliche
Capture-Wiederholungen und eine getrennte gruppenbezogene Replace-Funktion.
Dieser Vertrag konkretisiert genau diese zwei APIs im bestehenden Modul
`toolbelt.string.regex`. Die sieben bisherigen öffentlichen APIs behalten
ihre Signaturen, Defaults, Grammatikmodi und Semantik. Keine Rückreferenzen
im Suchpattern, zusätzliche Typfamilie, Providerinstallation oder Veröffentlichung.

Stand 2026-10-02: Vor-Source-Gate erfolgreich. Der private Strukturkandidat
bestand neun begrenzte isolierte Framework-Kindprozesse mit 7608 Assertions,
unabhängig wiederholt. Unabhängiger Semantikreview des präzisierten Vertrags
erfolgreich. Dies qualifiziert das hier begrenzte Profil vor Source, keine
SQL-SAFE-Runtime oder vollständige API. Die integrierte Implementierung muss
dieselben Regeln erneut gegen ihren tatsächlichen Code qualifizieren.

Kandidat-SHA256 `60C2C88946BBBC367545C634D6E4E4EB80B2235406014B40166C1FA90EC68BEA`,
Harness-SHA256 `47EEE746D1F743C544995D330578EB707A2475DE33F34A180536ECF5DC408413`.
Methode: privater C#-Strukturprototyp, ursprünglicher kanonischer Parser zur
zusätzlichen Grammatikprüfung, echte .NET-Framework-Regexengine,
konfigurierte 256-KiB-Testthreadstacks, zehn Sekunden Prozessdeadline,
separate core/replacement/groups/history/large/depth/precise/rows/exhaustive
Kinder. Umfasst 5456 kleine synthetische Enginekonstruktionen, tatsächliche
100000 Captures, finite-nullable-/Null-/Verschachtelungs-/Alternationsfälle,
striktes Replacement und atomare Zeilen-/GroupName-plus-Value-Textgrenzen.
Der erste unabhängige Runner meldete einen falschen Fehler trotz Kind-PASS
wegen fehlendem belastbarem Process-Exitcode; der erneute .NET-Process-Lauf
prüfte alle neun Exitcodes erfolgreich. Kein universeller Grammatik-,
Backtracking-, Heap- oder Durchsatznachweis.

## Öffentliche Signaturen

Laufende Validierung 2026-10-02: Integrierte Framework-Suite und begrenzte
API-/SQLClient-Proben lokal/zentral auf Windows2025 und Linux2019 erfolgreich.
Der Lifecycle bleibt blockiert: die tatsächliche Releaseversion ist aus der
unsigned SQL-Katalogidentität nicht belastbar zu gewinnen. Der unten geplante
historische CLR-Versionsnachweis ist damit noch nicht erfüllt. Eine zusätzliche
exakte erwartete Assemblyhashgrenze benötigt Benutzerentscheidung; weder
Marker allein noch fehlende Evidenz werden als PASS behandelt.

| Objekt | Parameter in Reihenfolge | Ergebnis |
|---|---|---|
| `toolbelt_string.TVF_RegexCaptures` | `@Input nvarchar(max)`, `@Pattern nvarchar(max)`, `@Start int = 1`, `@Flags nvarchar(max) = N'c'`, `@Profile nvarchar(max) = N'standard'`, `@MaxRows int = 10000` | normalisierte Capture-Zeilen |
| `toolbelt_string.SVF_RegexReplaceGroups` | `@Input nvarchar(max)`, `@Pattern nvarchar(max)`, `@Replacement nvarchar(max)`, `@Start int = 1`, `@Occurrence int = 0`, `@Flags nvarchar(max) = N'c'`, `@Profile nvarchar(max) = N'standard'` | `nvarchar(max)` |

Die bestehenden T-SQL-Fassaden vor intern markierten CLR-Kernen werden
wiederverwendet: max-Defaults sind direkt an CLR-Bindings nicht zulässig.
Ein relationaler Ausdruck für allgemeines Regex-Replace ist nicht belegt;
ein inline-TVF-Aufrufwrapper der SVF wäre keine Performancealternative.
Der kanonische SAFE-CLR-Kern bleibt ohne Datenbank-, Datei- oder Netzwerkzugriff.

## Gruppen und Positionen

Der Capture-Modus akzeptiert gewöhnliche `(…)` und benannte
`(?<Name>…)` Gruppen zusätzlich zum bisherigen begrenzten Grunddialekt.
Gruppen erhalten anhand ihrer öffnenden Klammer links nach rechts Ordinals
ab 1, einschließlich benannter Gruppen. Die technische Enginezuordnung ist
explizit und unabhängig von der .NET-Nummerierung benannter Gruppen.
GroupName ist der explizite Name oder die invariante Dezimaldarstellung
der Ordinal einer unbenannten Gruppe. Group 0 wird nicht ausgegeben;
für Gesamttreffer existiert bereits `TVF_RegexMatches`.

Namen bestehen aus ASCII-Buchstaben oder `_` als erstem Zeichen, danach
ASCII-Buchstaben, Ziffern oder `_`, höchstens 128 Codeeinheiten.
Namen sind exakt und case-sensitive referenziert; doppelte Namen oder Namen,
die sich nur in der Groß-/Kleinschreibung unterscheiden, werden abgelehnt.
Der Duplikatvergleich ist ordinal ASCII-case-insensitive, Referenzen werden
ordinal case-sensitive aufgelöst; Culture und Datenbank-Collation wirken nicht.
Andere Special Groups, Balancing Groups, Lookarounds aus Benutzereingaben,
Inline-Flags, Backreferences und lazy Quantifier bleiben ausgeschlossen.
Technische Gruppen der kanonischen ASCII-Klassenübersetzung sind unsichtbar.

Capture-Reihenfolge je Gruppe entspricht der erfolgreichen Capture-Historie
der links nach rechts suchenden Engine. Zurückgenommene Backtracking-Captures
gehören nicht zum Ergebnis. Positionen und Längen zählen UTF-16-Codeeinheiten,
nicht Grapheme oder Unicode-Skalarwerte; Positionen sind 1-basiert.
Treffer überlappen nicht. Leere Treffer verschieben nur den Suchcursor um
eine Codeeinheit; am Inputende ist ein terminaler leerer Treffer möglich.

| Spalte | SQL-Typ | Erfolgssemantik |
|---|---|---|
| MatchOrdinal | `bigint` | Treffer ab 1, unabhängig von der Anzahl ausgegebener Capture-Zeilen |
| GroupOrdinal | `int` | deklarierte Gruppe ab 1 |
| CaptureOrdinal | `bigint` | Wiederholung ab 1; 0 für die Sentinelzeile einer unbeteiligten Gruppe |
| GroupName | `nvarchar(128)` | expliziter Name oder Ordinaltext |
| Matched | `bit` | 1 für tatsächliche Captures, auch leere; 0 für unbeteiligte Gruppe |
| StartPosition | `bigint` | bei Matched=0 SQL-NULL |
| Length | `bigint` | bei Matched=0 SQL-NULL, bei leerem Capture 0 |
| Value | `nvarchar(max)` | bei Matched=0 SQL-NULL, bei leerem Capture leerer Text |

Ausgabe ist nach MatchOrdinal, GroupOrdinal und CaptureOrdinal zu ordnen;
SQL ohne ORDER BY garantiert keine Reihenfolge. Je erfolgreichem Treffer
erhält jede unbeteiligte deklarierte Gruppe genau eine Sentinelzeile.
Kein Treffer oder ein Pattern ohne deklarierte Gruppen liefert keine Zeilen.
Alle Zeilen und Textkopien werden vor Enumeratorrückgabe geprüft und
materialisiert; Fehler liefern keine verwertbare Teilmenge.

## Replacement

`$1` und weitere positive Dezimalordinals referenzieren deklarierte Gruppen;
die gesamte folgende Ziffernfolge gehört zur Referenz. `${Name}` referenziert
einen exakt passenden expliziten Namen, `$$` ein Dollarzeichen. Group 0,
führende Nullen, unbekannte Gruppen sowie andere oder unvollständige
Dollarformen sind Fehler. Für einen literal Dollar ist `$$` erforderlich.
Die Ziffernfolge besteht ausschließlich aus ASCII `0` bis `9`; ein
arithmetischer Overflow ist ebenfalls ein Replacement-Vertragsfehler.
Backslash hat im Replacement keine Escape- oder Rückreferenzsemantik.

Eine wiederholt erfasste Gruppe verwendet ihre letzte erfolgreiche Capture.
Eine deklarierte, im jeweiligen Treffer unbeteiligte Gruppe ersetzt durch
Leertext. Alle Referenzen werden vor der ersten Suche aufgelöst, auch wenn
kein Treffer existiert oder Start hinter dem Input liegt. Occurrence=0
ersetzt alle Treffer; ein positiver Wert genau den n-ten Treffer. Kein
entsprechender Treffer liefert den unveränderten Input. Bestehendes
`SVF_RegexReplace` behandelt seinen Ersatztext weiterhin vollständig literal.

## Parameter, Fehlerpriorität und Ressourcenprofil

Input oder Pattern NULL ergibt unmittelbar keine Capture-Zeilen; für Replace
ergibt zusätzlich Replacement NULL unmittelbar SQL-NULL. Dieser Kurzschluss
liegt vor anderen Vertragsprüfungen. Danach: Profil → Start/Occurrence/MaxRows
→ Flags → Textgrößen → Pattern/Komplexität → Replacement-Syntax/Referenzen
→ Suche/Ausgabe/kooperatives Budget. Ein gültiger Start hinter InputLength+1
verdeckt keine zuvor zu prüfenden Vertragsfehler.

Profile, Flags und Grundlimits entsprechen dem bestehenden R2-Kontext:
exakte Profile standard/large, 2/16 MiB UTF-16 für Input, Ersatz und Ergebnis,
Pattern 8000 Codeeinheiten, übersetztes Pattern 64000 Codeeinheiten,
Gruppentiefe 64, Alternationen 1024 und endliche Quantifiergrenzen 1000.
Flags c/i/m/s sind kulturinvariant, höchstens vier, ohne Duplikate oder c+i.
Start ist positiv und nicht NULL; Occurrence mindestens 0; MaxRows 1 bis
100000, nicht NULL. Capture-Ausgabetextsumme ist profilbegrenzt;
auch Sentinelzeilen zählen gegen MaxRows. Die Capture-Textsumme addiert
je Zeile GroupName und Value (NULL-Value zählt 0), einschließlich wiederholter
GroupNames auf Sentinelzeilen. Vor Textkopien und Appends wird
die jeweilige Größe mit überlaufgeprüfter Arithmetik geprüft.

Zusätzliches vor Source qualifiziertes Profil: maximal 64 deklarierte
Capturegruppen und vor der Regexengine konservativ ermittelte höchstens
100000 Capture-Ereignisse je erfolgreichem Matchpfad. Konkatenation summiert,
Alternation verwendet das Maximum, Quantifier multiplizieren konservative
Teilgrenzen; Inputlänge und minimale konsumierte Länge können unbeschränkte
Quantifier begrenzen. Nicht sicher begrenzbare nullable Wiederholungen mit
Capture-Historie werden vor Konstruktor/Suche abgewiesen. Überläufe werden
als Überschreitung behandelt. Ein kleiner tatsächlicher Treffer hebt eine
überschrittene konservative Vorprüfung nicht auf.

Berechnungsdefinition des Profils: L ist die tatsächliche dekodierte
InputLength, nicht die Profilobergrenze; L=0 ist zulässig. Literale/Klassen
haben Mindestverbrauch 1 und Historie 0, Anker 0/0. Eine Capturegruppe erhöht
die Historie ihres Inhalts um 1. Konkatenation addiert Mindestverbrauch und
Historie; Alternation verwendet den kleinsten Mindestverbrauch und die
größte Historie. Bei Quantifiern mit endlicher Obergrenze U gilt N=U;
ist der Mindestverbrauch des Kindes m>0, gilt konservativ zusätzlich
N=min(U,floor(L/m)). Bei unbeschränkter Wiederholung und m>0 gilt
N=floor(L/m). Bei m=0 und positiver Kindhistorie wird eine unbeschränkte
Wiederholung abgewiesen; bei Kindhistorie 0 bleibt die Historie 0.
Die Quantifierhistorie ist N mal Kindhistorie; der Mindestverbrauch ist
Untergrenze mal Kindmindestverbrauch. Arithmetik saturiert die Historie
bei 100001 und den Mindestverbrauch bei L+1. Das Verwerfen eines nullable
Captureloops erfolgt unabhängig davon, ob dessen Zweig tatsächlich trifft.

Die neuen Replacement-Syntax-/Referenzfehler verwenden
`TBX_REGEX_INVALID_REPLACEMENT`, ungültige Gruppen-/Namensdeklarationen
`TBX_REGEX_INVALID_PATTERN`, die deklarierte Gruppenanzahl und übrige
Komplexitätsgrenzen `TBX_REGEX_PATTERN_TOO_COMPLEX`, Historienüberschreitung
oder nicht sicher begrenzbare nullable Captureloops
`TBX_REGEX_CAPTURE_HISTORY_LIMIT`. Bestehende Präfixe für Argumente,
Flags, Input/Pattern/Replacement/Output-Größe, Zeilenzahl und Timeout bleiben
`TBX_REGEX_INVALID_ARGUMENT`, `TBX_REGEX_INVALID_FLAGS`,
`TBX_REGEX_INPUT_TOO_LARGE`, `TBX_REGEX_PATTERN_TOO_LARGE`,
`TBX_REGEX_REPLACEMENT_TOO_LARGE`, `TBX_REGEX_OUTPUT_TOO_LARGE`,
`TBX_REGEX_TOO_MANY_ROWS` und `TBX_REGEX_TIMEOUT`.

MaxRows und Textlimits greifen erst nach Engine-Matching; sie begrenzen
keine bereits intern aufgebaute Capture-Historie. Der zusätzliche Wächter
ist keine Heap-, Backtracking-, Wall-Clock- oder globale Speicherzusage.
Das kooperative Gesamtbudget 500/2000 ms und Suchschrittlimit höchstens
250 ms werden über den vorhandenen Restbudgetkontext wiederverwendet.
Konstruktor, Allokation, GC und SQL-Scheduling bleiben nicht unterbrechbar.
Fehler erscheinen als SQL6522 mit stabilen TBX_REGEX-Präfixen; keine
Truncation, angenäherte Captures oder Unlimited-Option.

## Lifecycle und Pflichtqualifikation

Geplante additive Modulversion 1.3.0, weiterhin unreleased. Bestehende
Objekt-/Assemblymarker, bekannte Release-Manifeste, AppLock, Preflight,
atomare Mutation und Dependency-Uninstall werden für die zwei Fassaden
und zwei internen CLR-Bindings erweitert. Historische Release-Evidenz bleibt
getrennt; neue Runtime-Evidenz entsteht ausschließlich durch tatsächliche Tests.

Deploy und Uninstall lehnen eine aktive Caller-Transaktion vor SET oder DDL
mit nichtdoomendem RAISERROR und vollständigem Batchabbruch ab. Sie rollen
niemals Caller-Arbeit zurück. Beide verwenden denselben Transaction-AppLock
und lesen Version, Objekt-/Assemblyzuordnung und Dependencies unter diesem
Lock erneut. Nur bekannte Release-Slots dürfen ersetzt oder entfernt werden:
1.0 besitzt die drei R1b-Funktionen, 1.1 zusätzlich vier R2a-Slots, 1.2
zusätzlich vier R2b-Slots und 1.3 zusätzlich vier Capture-/Replace-Slots.
Ein neuer Slot ist auch mit nachgeahmtem Marker eine Kollision, wenn er
zum installierten Release nicht gehört. Vorhandene eigene Slots benötigen
Managed/ModuleId und passende Function-ModuleVersion; fremde oder unbekannte
Zuordnung blockiert vor Mutation. Alte Assembly-Releases besitzen keinen
ModuleVersion-Marker: deren vorhandene Managed/ModuleId-Zuordnung und
bekannte CLR-Version werden geprüft, kein neuer historischer Marker erfunden.
Eine fremde Schemazuordnung wird nicht adoptiert und ein fremdes Schema
bei Uninstall nicht entfernt. Serverweiter Trust bleibt separater administrativer
Lifecycle; Tests verwenden bestehende Rechte und private Restorejournale.
Der Lab-Lauf aktiviert keine globalen Pending-Konfigurationen implizit.

Vor Source: Parser-/History-/Replacement-Kandidat in begrenzten isolierten
Framework-Prozessen und unabhängiger Vertragstest. Danach: alle alten APIs
regressieren; gemischte benannte/unbenannte und verschachtelte/wiederholte
Gruppen, fehlend versus leer, Escape/Klassen, Unicode/Start, alle Ersatzformen,
NULL-/Fehlerprioritäten, Grenzen und atomare Timeout-/Limitfehler prüfen.
Scopebezogenes schema-validiertes Lab auf Linux 2019 und Windows 2025,
local/central, Clientmetadaten/Rechte, echter 1.2-Upgrade, ältere unterstützte
Upgrades, Reinstall, Kollisionen, Caller-Transaktionen und Cleanup folgen.
Fehlende Tests bleiben not executed und blockieren eine pauschale Aufwertung.

## Primärquellen

- [Microsoft: Group.Captures](https://learn.microsoft.com/en-us/dotnet/api/system.text.regularexpressions.group.captures?view=netframework-4.8.1): Capture-Historie und Unterschied zum letzten Gruppenwert.
- [Microsoft: Grouping constructs](https://learn.microsoft.com/en-us/dotnet/standard/base-types/grouping-constructs-in-regular-expressions): Engine-Gruppen und abweichende benannte Nummerierung; Toolbelt legt seine Zuordnung ausdrücklich selbst fest.
- [Microsoft: Substitutions](https://learn.microsoft.com/en-us/dotnet/standard/base-types/substitutions-in-regular-expressions): Referenz zur Engine; die hier begrenzte Toolbelt-Replacementgrammatik wird selbst geprüft.
- [bestehender Regex-Vertrag](./REGEX_MODULE_DESIGN.md) und [R2-Erweiterung](./REGEX_EXTENSION_PROPOSAL.md).
