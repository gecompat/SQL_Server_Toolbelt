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
