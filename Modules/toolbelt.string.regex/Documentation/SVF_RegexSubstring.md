# `toolbelt_string.SVF_RegexSubstring`

R2a, Version `1.1.0`, ausdrücklich freigegeben am 2026-10-01. Die T-SQL-SVF mit SAFE-CLR-Kern
liefert den n-ten nicht überlappenden Gesamttreffer als Unicode-Text.

| Parameter | Typ | Default |
|---|---|---|
| `@Input`, `@Pattern` | `nvarchar(max)` | erforderlich |
| `@Start`, `@Occurrence` | `int` | jeweils `1` |
| `@Flags` | `nvarchar(max)` | `N'c'` |
| `@Profile` | `nvarchar(max)` | `N'standard'` |

Ergebnis: `nvarchar(max)`, keine Capture-Gruppe. Ohne Treffer SQL-NULL;
ein leerer Treffer ergibt `N''`. NULL in Quelle oder Pattern liefert sofort
NULL vor weiterer Validierung. Andernfalls müssen Start/Occurrence positiv
und nicht NULL sein, Profil/Flags gültig und nicht NULL.

Start zählt UTF-16-Codeeinheiten ab 1. Nach vollständiger Vertragsprüfung
liefert Start größer als InputLength+1 NULL. Start am InputLength+1 kann einen
terminalen leeren Treffer liefern. Leere Treffer bewegen den Suchcursor um
eine Codeeinheit; am Ende wird genau ein leerer Treffer berücksichtigt.

Die [R2a-Grenzen und Betriebsregeln](./REGEX_FUNCTIONS.md#r2a-transformationsvertrag)
gelten. SQL-Fehler 6522 trägt `TBX_REGEX_*`; SELECT/REFERENCES ist erforderlich.
Provider: SAFE CLR für SQL Server 2019/2022/2025 Windows/Linux.

Die CLR-Suche ist nicht als äquivalenter relationaler Ausdruck belegt. Eine
inline-TVF, die nur diese SVF aufruft, erfüllt die Engineering-Regel nicht
und wäre kein Performancebeleg. Relationale Vorfilter bleiben empfohlen.

Beispiel: `SVF_RegexSubstring(N'a12b34', N'[0-9]+', 1, 2, N'c', N'standard')`
liefert `N'34'`.
