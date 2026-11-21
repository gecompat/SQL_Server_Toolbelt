# `toolbelt_string.SVF_RegexSubstring`

R2a, Version `1.1.0`, ausdrücklich freigegeben am 2026-10-01. Die T-SQL-SVF mit SAFE-CLR-Kern
liefert den n-ten nicht überlappenden Gesamttreffer als Unicode-Text.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Occurrence` | `int` | `1` | Input | Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
<!-- API_PARAMETERS:END -->

Ergebnis: `nvarchar(max)`, keine Capture-Gruppe. Ohne Treffer SQL-NULL;
ein leerer Treffer ergibt `N''`. NULL in Quelle oder Pattern liefert sofort
NULL vor weiterer Validierung. Andernfalls müssen Start/Occurrence positiv
und nicht NULL sein, Profil/Flags gültig und nicht NULL.

Start zählt UTF-16-Codeeinheiten ab 1. Nach vollständiger Vertragsprüfung
liefert Start größer als InputLength+1 NULL. Start am InputLength+1 kann einen
terminalen leeren Treffer liefern. Leere Treffer bewegen den Suchcursor um
eine Codeeinheit; am Ende wird genau ein leerer Treffer berücksichtigt.

Die [R2a-Grenzen und Betriebsregeln](./REGEX_FUNCTIONS.md#r2a-transformationsvertrag)
gelten. SQL-Fehler 6522 trägt `TBX_REGEX_*`; EXECUTE auf der öffentlichen
Funktion ist erforderlich. Der Fachcaller benötigt keinen direkten Grant
auf dem internen CLR-Kern.
Provider: SAFE CLR für SQL Server 2019/2022/2025 Windows/Linux.

Die CLR-Suche ist nicht als äquivalenter relationaler Ausdruck belegt. Eine
inline-TVF, die nur diese SVF aufruft, erfüllt die Engineering-Regel nicht
und wäre kein Performancebeleg. Relationale Vorfilter bleiben empfohlen.

Beispiel: `SVF_RegexSubstring(N'a12b34', N'[0-9]+', 1, 2, N'c', N'standard')`
liefert `N'34'`.

## Beispielaufruf

```sql
SELECT toolbelt_string.SVF_RegexSubstring(N'abc123 def456', N'[0-9]+', 1, 1, N'c', N'standard') AS ResultValue;
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/RegexFunctions.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)

## Vollständiger Usage-Skill

Der [quellgeprüfte Skill](../../../Metadata/UsageSkills/toolbelt_string/SVF_RegexSubstring.md) beschreibt sämtliche Argumente, Defaults, NULL-Pfade, Dialektgrenzen, Ergebnisse und Fehler. Er ist auch Bestandteil der ausgelieferten Funktions-DDL. Interne CLR-Kerne haben keine SQL-Defaults und verweisen auf die öffentlichen Fassaden; sie sind kein zusätzlicher Fachaufrufweg. Historische Nachweise und neue native Qualifikation bleiben getrennt.
