# Base64-Contract-Testmatrix

## Status

Die Matrix ist der Pflichtscope für `toolbelt.conversion.base64` Version
`1.1.0`. Der
[SQL-Server-2025-Linux-Lauf 30535377837](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377837)
war für die Compatibility Levels 150, 160 und 170 erfolgreich.

## Funktionsvertrag

| Dimension | Pflichtfälle |
|---|---|
| Signatur | Schema, Name, Typ, Parameterreihenfolge, Typen und Encode-Default |
| Null/leer | `NULL`, leere Binärfolge und leerer Text |
| RFC-4648-Vektoren | `f`, `fo`, `foo`, `foob`, `fooba`, `foobar` |
| Alphabet | Standard und Base64URL; kanonische Encode-Ausgabe |
| Padding | vollständig, ausgelassen, zu viel, Daten nach Padding |
| Whitespace | Space, Tab, CR und LF; nicht freigegebener Whitespace als Fehler |
| Fehler | ungültiges Zeichen, Länge Rest eins und ungültiges Padding |
| Roundtrip | Encode → Decode für Standard und URL-safe |
| Größen | inline-TVF-Roundtrip mit 6.000, 6.001, 65.536 und 1.048.576 synthetischen Bytes; SVF-Parität bis 6.001 Bytes |
| Native Parität | SQL Server 2025 als semantische Referenz |
| API-Parität | SVF und inline TVF für Normal-, Grenz-, `NULL`- und Fehlerfälle |
| Mengenverwendung | `OUTER APPLY`, exakt eine Ergebniszeile, Resultspalten |
| Sitzungsoption | direkter inline-TVF-Aufruf mit `QUOTED_IDENTIFIER ON` |

## Lifecycle

| Dimension | Pflichtfälle |
|---|---|
| Erstinstallation | leere Datenbank |
| Wiederholung | dieselbe Version überschreibt lokale Framework-Änderungen |
| Kollision | frameworkfremdes Zielobjekt blockiert vor Mutation |
| Upgrade | bekanntes Release `1.0.0` auf `1.1.0` |
| Uninstall | exakt vier Release-Funktionen; fremde Schemaobjekte bleiben |
| zentral | dreiteiliger Aufruf und ausdrückliche Uninstall-Bestätigung |

## Zielmatrix

| Engine/Plattform | Compatibility | Status |
|---|---:|---|
| SQL Server 2025 Linux | 150 | Version `1.1.0` erfolgreich |
| SQL Server 2025 Linux | 160 | Version `1.1.0` erfolgreich |
| SQL Server 2025 Linux | 170 | Version `1.1.0` erfolgreich |
| SQL Server 2019 Linux | 150 | `not executed` – gezielte Releasevalidierung |
| SQL Server 2022 Linux | 160 | `not executed` – gezielte Releasevalidierung |
| Windows 2019/2022/2025 | passend | `not executed` – geeigneter Runner erforderlich |

Die Compatibility-Matrix dient als schneller Syntax-, Planungs- und
Semantiktest. Sie ersetzt die gezielten physischen Versionsläufe vor einem
Release nicht.

## Datenschutz

Alle Werte sind synthetisch. Decodierte Inhalte, Fehlerinputs und Runtime-
Ausgaben werden nicht als Repository-Evidenz gespeichert.
