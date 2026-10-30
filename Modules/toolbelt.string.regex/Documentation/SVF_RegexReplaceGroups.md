# SVF_RegexReplaceGroups

Die separat freigegebene gruppenbezogene Replace-Funktion verwendet denselben
Capture-Dialekt wie [TVF_RegexCaptures](TVF_RegexCaptures.md). Der vollständige
[Vertrag](../../../Documentation/Architecture/REGEX_CAPTURE_REPLACE_CONTRACT.md)
definiert Fehlerpriorität, Capture-Historienprofil und Ressourcenbegrenzung.

`toolbelt_string.SVF_RegexReplaceGroups(@Input nvarchar(max), @Pattern nvarchar(max), @Replacement nvarchar(max), @Start int = 1, @Occurrence int = 0, @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard') -> nvarchar(max)`

Die T-SQL-Fassade ruft den internen SAFE-CLR-Kern `SVF_RegexReplaceGroupsCore`
mit einheitlicher Unicode-Collationidentität auf. Ein relationaler Ersatzkern
ohne CLR-Skalaraufruf ist für diesen materialisierten Transformationvertrag
nicht verfügbar. Die bisherigen sieben APIs, insbesondere das literale
`SVF_RegexReplace`, behalten ihre Semantik.

- `$1` referenziert eine deklarierte Gruppe; die ganze Ziffernfolge gehört
  zum Ordinal, daher ist `$10` Gruppe 10. Keine führenden Nullen oder Gruppe 0.
- `${Name}` referenziert ausschließlich einen explizit deklarierten Namen,
  ordinal und case-sensitive. Unbekannte Referenzen sind Fehler auch ohne Treffer.
- `$$` erzeugt einen Dollar. Backslash bleibt literal; andere Dollarformen
  sind ungültig.
- Wiederholte Gruppen verwenden die letzte erfolgreiche Capture. Nicht
  beteiligte Gruppen liefern Leertext.

Occurrence=0 ersetzt alle nicht überlappenden Treffer, positive Werte nur
den entsprechenden Treffer; Start ist eine positive 1-basierte UTF-16-Position.
Fehlender Treffer liefert die unveränderte Quelle. Leere Treffer rücken den
Suchcursor um eine UTF-16-Einheit weiter, am Ende höchstens einmal.
NULL-Input, Pattern oder Replacement liefert NULL vor übriger Validierung.

Fehlerpriorität: NULL, Profile, Start/Occurrence, Flags, Größen, Pattern/
Komplexität/Capture-Historie, Replacement, Suche/Output/Budget. Ungültige,
überlaufende oder unbekannte Replacementreferenzen: SQL6522 mit
`TBX_REGEX_INVALID_REPLACEMENT`. Kein Abschneiden oder stilles Aufwerten.

Quelle, Replacement und Output höchstens 1048576/8388608 UTF-16-Einheiten
für standard/large. Pattern8000, Gruppen64, erfolgreiche Capture-Historie
konservativ100000. Die kooperativen Gesamtbudgets500/2000ms und Suchschritte
bis250ms garantieren keinen Durchsatz, Heapverbrauch oder harte Wallclock.

```sql
SELECT toolbelt_string.SVF_RegexReplaceGroups(
    N'abb',N'(?<First>a)(b)+',N'${First}:$2:$$',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
-- a:b:$
```

EXECUTE auf der Fassade ist erforderlich; dem Fachcaller werden keine
direkten Rechte auf dem internen CLR-Kern erteilt. CrossDB-
Nutzermappings bleiben ein eigener Prüfkontext. Der reine Memorykern greift
nicht auf Daten, Dateien, Netzwerk oder global veränderliche Caches zu.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. Capturegruppen können unbenannt oder (?&lt;Name&gt;...) sein; Namen 1..128 ASCII-Zeichen, Beginn Buchstabe/_ danach zusätzlich Ziffern, ohne case-insensitive Namensduplikate. Maximal 64 deklarierte Gruppen und konservative Capture-History 100000. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Ersetzungstext, leer löscht den Treffer; NULL ergibt NULL vor weiterer Prüfung. Gruppenreferenzen ausschließlich $1..$64 auf vorhandene Gruppen, ${Name} auf deklarierte Namen sowie $$ für ein Dollarzeichen. $0/Gruppe 0, unbekannte Referenzen und ungültige Syntax werden auch ohne Treffer abgewiesen; höchstens 65536 Ersetzungsteile. Höchstens 1048576 UTF-16-Einheiten im Profil standard beziehungsweise 8388608 in large; auch die gesamte erzeugte Ausgabe bleibt auf dieses Profilbudget begrenzt. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Occurrence` | `int` | `0` | Input | Ganzzahl 0..2147483647, Default 0: 0 ersetzt alle Treffer ab Start, positiv nur den n-ten Treffer ab Start. Negativ/NULL ungültig; vor Start bleibt der Text erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).
