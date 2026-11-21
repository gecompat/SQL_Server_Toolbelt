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
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Normale und (?&lt;Name&gt;...)-Captures zulässig, maximal64 Gruppen; Name1..128 ASCII-Zeichen, BeginnA-Z/a-z/_, danach zusätzlichZiffern, keine ordinal-case-insensitiven Duplikate. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Strikter Ersatz: $N für eine existierende positive vollständige ASCII-Gruppennummer ohne führende0, ${Name} nur für exakt case-sensitiv passenden expliziten Namen, $$ für ein Dollarzeichen. Backslash bleibt literal. $0,unbekannte/beschädigte Referenzen und einzelneDollarzeichen sind Fehler vor erster Suche; erzeugteDollarzeichen werden nicht erneut interpretiert. Verwendet den letzten erfolgreichen Capture, unbeteiligte Gruppe wird leer. Höchstens65536 geparste Ersatzteile. Leer löscht den Treffer, NULL ergibt frühNULL. Ersatzlänge wie Profil; fertiger Output bleibt ebenfalls profilbegrenzt. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Occurrence` | `int` | `0` | Input | 0=alle Treffer abStart,positiv=nur n-ter Treffer;0..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Vollständiger Usage-Skill

Der [quellgeprüfte Skill](../../../Metadata/UsageSkills/toolbelt_string/SVF_RegexReplaceGroups.md) beschreibt sämtliche Argumente, Defaults, NULL-Pfade, Dialektgrenzen, Ergebnisse und Fehler. Er ist auch Bestandteil der ausgelieferten Funktions-DDL. Interne CLR-Kerne haben keine SQL-Defaults und verweisen auf die öffentlichen Fassaden; sie sind kein zusätzlicher Fachaufrufweg. Historische Nachweise und neue native Qualifikation bleiben getrennt.
