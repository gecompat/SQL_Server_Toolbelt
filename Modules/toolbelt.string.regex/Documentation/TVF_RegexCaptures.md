# TVF_RegexCaptures

Liefert sämtliche erfolgreichen Capture-Wiederholungen des begrenzten
Capture-Dialekts. Einzelfreigabe 2026-10-01; Vertrag und Vor-Source-Qualifikation:
[Capture-/Replace-Vertrag](../../../Documentation/Architecture/REGEX_CAPTURE_REPLACE_CONTRACT.md).

`toolbelt_string.TVF_RegexCaptures(@Input nvarchar(max), @Pattern nvarchar(max), @Start int = 1, @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard', @MaxRows int = 10000)`

Die Inline-TVF verwendet den internen SAFE-CLR-Kern `TVF_RegexCapturesCore`.
Unicodeargumente erhalten vor dem Kernaufruf dieselbe Collationidentität.
varchar-Quellen sind am Caller verlustfrei nach nvarchar(max) zu dekodieren.

| Spalte | Typ | Bedeutung |
|---|---|---|
| MatchOrdinal | bigint | 1-basierter nicht überlappender Gesamttreffer |
| GroupOrdinal | int | Öffnende Capture-Klammern von links nach rechts, ab 1 |
| CaptureOrdinal | bigint | Wiederholung innerhalb der Gruppe ab 1; Sentinel 0 |
| GroupName | nvarchar(128) | Deklarierter Name oder dezimaler GroupOrdinal |
| Matched | bit | 1 für Capture, 0 für nicht beteiligte Gruppe |
| StartPosition | bigint | 1-basierte UTF-16-Position; Sentinel NULL |
| Length | bigint | UTF-16-Länge; Sentinel NULL |
| Value | nvarchar(max) | Capturewert; Sentinel NULL |

SQL-Metadaten sind nullable. Tatsächlich leere Captures haben Matched=1,
Length=0 und Value=N''; nicht beteiligte Gruppen erhalten genau eine
Sentinelzeile je Treffer. Gruppe 0 wird nicht ausgegeben. Ein Pattern ohne
Capturegruppen liefert keine Zeilen. Explizites `ORDER BY MatchOrdinal,
GroupOrdinal,CaptureOrdinal` ist für eine definierte Ergebnisreihenfolge nötig.
NULL-Input/Pattern liefert vor übriger Validierung keine Zeilen.

Normalgruppen und `(?<Name>...)` sind erlaubt. Höchstens 64 Gruppen,
ASCII-Namen mit Buchstabe/Unterstrich am Anfang; doppelte Namen auch bei
unterschiedlicher Großschreibung sind ungültig. Keine Pattern-Rückreferenzen
oder weiteren Spezialgruppen. Alte Regex-APIs behalten ihren Dialekt.

Profile standard/large begrenzen Quelle und kumulativen Ergebnistext auf
1048576/8388608 UTF-16-Einheiten. Jede Zeile belastet das Ergebnislimit mit
GroupName.Length plus Value.Length; auch wiederholte Namen und Sentinels
zählen. MaxRows 1–100000, Default 10000. Pattern höchstens 8000 Einheiten,
Tiefe64, Alternation1024, übersetzte Länge64000, Quantifier1000.
Vor Enginekonstruktion begrenzt die konservative Strukturprüfung erfolgreiche
Capture-Historien auf 100000; nullable unbeschränkte Capture-Schleifen werden
abgewiesen. Dies begrenzt weder Backtracking noch den gesamten Heap.

Fehlerpriorität: NULL, Profile, Start/MaxRows, Flags, Größen, Pattern/Komplexität/
Capture-Historie, Suche/Output/Budget. SQL6522 mit stabilem TBX_REGEX_*-Präfix;
zusätzlich zu den bestehenden Fehlern CAPTURE_HISTORY_LIMIT. Das Resultat
wird vollständig vor Enumeratorrückgabe materialisiert; keine Teilzeilen.
500/2000-ms-Budgets sind kooperativ, keine Durchsatz-/Wallclockzusage.

```sql
SELECT c.*
FROM toolbelt_string.TVF_RegexCaptures(N'abb',N'(?<First>a)(b)+',DEFAULT,DEFAULT,DEFAULT,DEFAULT) c
ORDER BY c.MatchOrdinal,c.GroupOrdinal,c.CaptureOrdinal;
```

SELECT auf der öffentlichen TVF genügt bei gleicher Ownership. Lowpriv-
CrossDB-Mappings benötigen eigenen Nachweis. Deployment 1.3.0 gehört zum
bestehenden Modul; Trust ist ein separates exaktes administratives Opt-in.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Normale und (?&lt;Name&gt;...)-Captures zulässig, maximal64 Gruppen; Name1..128 ASCII-Zeichen, BeginnA-Z/a-z/_, danach zusätzlichZiffern, keine ordinal-case-insensitiven Duplikate. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl1..100000, fachlich nichtNULL. Grenze der vollständig materialisierten Ausgabe, keine TOP-/Teilpräfixsemantik. Bei Überschreitung Fehler statt verwendbarer Teilzeilen. Zählt jede Capture und auch Kontrollzeilen nicht beteiligter Gruppen. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Vollständiger Usage-Skill

Der [quellgeprüfte Skill](../../../Metadata/UsageSkills/toolbelt_string/TVF_RegexCaptures.md) beschreibt sämtliche Argumente, Defaults, NULL-Pfade, Dialektgrenzen, Ergebnisse und Fehler. Er ist auch Bestandteil der ausgelieferten Funktions-DDL. Interne CLR-Kerne haben keine SQL-Defaults und verweisen auf die öffentlichen Fassaden; sie sind kein zusätzlicher Fachaufrufweg. Historische Nachweise und neue native Qualifikation bleiben getrennt.
