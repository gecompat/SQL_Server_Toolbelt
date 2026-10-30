# `toolbelt_string.SVF_RegexSubstring`

R2a, Version `1.1.0`, ausdrücklich freigegeben am 2026-10-01. Die T-SQL-SVF mit SAFE-CLR-Kern
liefert den n-ten nicht überlappenden Gesamttreffer als Unicode-Text.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Occurrence` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: n-ter Treffer ab Start; 0/negativ/NULL ungültig. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |
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
