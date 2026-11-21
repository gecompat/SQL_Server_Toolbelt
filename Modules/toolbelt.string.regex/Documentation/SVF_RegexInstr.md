# toolbelt_string.SVF_RegexInstr

## Zweck

Liefert eine UTF-16-Position eines ausgewählten Regex-Treffers.

## Verhalten und Ergebnis

Zusätzliche Parameter sind `@Start int = 1`, `@Occurrence int = 1` und
`@ReturnOption int = 0`. Start und Occurrence beginnen bei 1.
`ReturnOption = 0` liefert den 1-basierten Start, `1` das 1-basierte
Ende-exklusiv. Positionen zählen UTF-16-Codeeinheiten. Ohne Treffer ist das
Ergebnis 0; eine Startposition nach Inputende liefert ebenfalls 0.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [REGEX_FUNCTIONS](REGEX_FUNCTIONS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. Count/Instr liefern dann0 vor Pattern-/Flagintake. |
| `@Occurrence` | `int` | `1` | Input | Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
| `@ReturnOption` | `int` | `0` | Input | Taxativ0=absolute1-basierte Startposition,1=absolute1-basierte Endposition exklusiv. NULL/andereWerte ungültig. OhneTreffer0. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT toolbelt_string.SVF_RegexInstr(N'abc123 def456', N'[0-9]+', 1, 1, 0, N'c') AS ResultValue;
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/RegexFunctions.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)

## Vollständiger Usage-Skill

Der [quellgeprüfte Skill](../../../Metadata/UsageSkills/toolbelt_string/SVF_RegexInstr.md) beschreibt sämtliche Argumente, Defaults, NULL-Pfade, Dialektgrenzen, Ergebnisse und Fehler. Er ist auch Bestandteil der ausgelieferten Funktions-DDL. Interne CLR-Kerne haben keine SQL-Defaults und verweisen auf die öffentlichen Fassaden; sie sind kein zusätzlicher Fachaufrufweg. Historische Nachweise und neue native Qualifikation bleiben getrennt.
