# `toolbelt_string.SVF_RegexReplace`

R2a, Version `1.1.0`, ausdrücklich freigegeben am 2026-10-01. Die T-SQL-SVF mit SAFE-CLR-Kern
ersetzt nicht überlappende Gesamttreffer durch literal Unicode-Text.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Literaler Ersatztext: $1,${Name},Backslash werden nicht expandiert. Leer löscht den Treffer, NULL ergibt frühNULL. Ersatzlänge wie Profil; fertiger Output bleibt ebenfalls profilbegrenzt. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Occurrence` | `int` | `0` | Input | 0=alle Treffer abStart,positiv=nur n-ter Treffer;0..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
<!-- API_PARAMETERS:END -->

Ergebnis: `nvarchar(max)`. Occurrence 0 ersetzt alle, ein positiver Wert nur
den n-ten Treffer ab der 1-basierten Startposition. Ohne Treffer bleibt die
Quelle unverändert. `$1` und `\1` im Ersatztext sind literal. NULL in Quelle,
Pattern oder Ersatztext liefert sofort NULL vor jeder weiteren Validierung.

Bei nicht-NULL-Eingaben sind NULL/negative Positionsparameter, ungültiges
Profil und NULL/ungültige Flags Fehler. Erst nach Vertragsprüfung liefert
Start größer als InputLength+1 die Quelle unverändert. Start am InputLength+1
kann einen terminalen leeren Treffer ersetzen. Leere Treffer rücken die Suche
um eine UTF-16-Codeeinheit vor; der terminale leere Treffer wird einmal ersetzt.

Die gemeinsamen [R2a-Grenzen und Betriebsregeln](./REGEX_FUNCTIONS.md#r2a-transformationsvertrag)
gelten. SQL-Fehler 6522 trägt `TBX_REGEX_*`, kein abgeschnittenes Teilergebnis.
EXECUTE auf der öffentlichen Funktion ist erforderlich; direkte Rechte auf
dem internen CLR-Kern werden dem Fachcaller nicht erteilt. Unterstützter Provider:
dieselbe SAFE-CLR-Assembly für SQL Server 2019/2022/2025 Windows/Linux.

Allgemeines Regex-Matching und Outputbau sind nicht als äquivalenter
relationaler Ausdruck belegt. Ein inline-TVF-Wrapper um die CLR-SVF wäre
kein relationaler Kern und kein Performancebeleg; deshalb wird keine solche
Scheinalternative bereitgestellt. Relationale Vorfilter werden bevorzugt.

Beispiel: `SVF_RegexReplace(N'a12b34', N'[0-9]+', N'X', 1, 0, N'c', N'standard')`
liefert `N'aXbX'`.

## Beispielaufruf

```sql
SELECT toolbelt_string.SVF_RegexReplace(N'abc123 def456', N'[0-9]+', N'X', 1, 1, N'c', N'standard') AS ResultValue;
```

Die Beispiele verwenden synthetische Werte. Vorlagen mit registrierten
Handlern, Tabellen oder Dateien setzen deren beschriebene Vorbereitung voraus.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Vollständiger Usage-Skill

Der [quellgeprüfte Skill](../../../Metadata/UsageSkills/toolbelt_string/SVF_RegexReplace.md) beschreibt sämtliche Argumente, Defaults, NULL-Pfade, Dialektgrenzen, Ergebnisse und Fehler. Er ist auch Bestandteil der ausgelieferten Funktions-DDL. Interne CLR-Kerne haben keine SQL-Defaults und verweisen auf die öffentlichen Fassaden; sie sind kein zusätzlicher Fachaufrufweg. Historische Nachweise und neue native Qualifikation bleiben getrennt.
