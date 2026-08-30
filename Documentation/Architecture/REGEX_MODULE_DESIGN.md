# Regex-Moduldesign – R1b

## Entscheidung und Freigabe

R1a verglich native SQL-Server-2025-RE2-Semantik, .NET Framework, native
Wrapper und T-SQL. Danach wurden Zweck, öffentlicher Vertrag, Alternativen,
Risiken und Scope eines engeren Toolbelt-Dialekts am 2026-08-30 mit dem
Benutzer besprochen. Der Benutzer gab anschließend „E1b und R1b wie
besprochen implementieren“ ausdrücklich frei. E1b wurde vor Beginn von R1b
separat nach `origin/main` gemergt.

## Öffentlicher Vertrag

`toolbelt.string.regex` 1.0.0 exportiert genau
`SVF_RegexIsMatch`, `SVF_RegexInstr` und `SVF_RegexCount`. Der gemeinsame
Vertrag umfasst den begrenzten Dialekt, UTF-16-Positionen, nicht überlappende
Counts, Empty-Match-Fortschritt, kulturinvariante Flags, 2-MiB-/8.000-Byte-
Grenzen und einen unveränderlichen Timeout von 250 ms. Fehler werden als
SQL-CLR-Fehler 6522 mit stabilem `TBX_REGEX_*`-Präfix sichtbar.

## Provider- und Securityentscheidung

Alle unterstützten Versionen und Plattformen verwenden dieselbe C#-Assembly
für .NET Framework 4.8. Direkte Referenzen sind auf die SQL-CLR-
Frameworkbibliotheken System und System.Data begrenzt. Es gibt keine
Drittanbieter- oder Native-Abhängigkeit, keine Datei-, Netzwerk-, Registry-
oder Prozessoperation und keine Datenbankzugriffe aus CLR.

Die Assembly bleibt `SAFE`. Deployment aktiviert CLR nicht, setzt niemals
`TRUSTWORTHY` und schwächt `clr strict security` nicht ab. Ein separates
administratives Skript autorisiert nur den SHA2-512-Hash des exakten
Releasebinaries. Modul-Uninstall entfernt den serverweiten Trust nicht, weil
derselbe Hash außerhalb der Datenbank genutzt werden könnte; der lokale
Testadapter entfernt nur einen von ihm neu erzeugten Trust-Eintrag.

## Parser statt Blacklist

Der Provider liest das Pattern vollständig und erzeugt ausschließlich aus
erlaubten Grammatikbausteinen ein .NET-Pattern. Gruppen werden intern
nicht-capturing, ASCII-Kurzklassen explizit und der absolute `$`-Anker ohne
`m` als `\z` übersetzt. Unbekannte Escapes, Inline-Optionen, Special Groups,
Class Subtraction, lazy Quantifier und Grenzen über 1.000 werden verworfen.
Damit ist die akzeptierte Sprache kleiner als .NET; dies begründet jedoch
weder RE2-Parität noch eine lineare Laufzeitgarantie.

## Alternativen und Risiken

Ein nativer RE2-Wrapper wurde wegen `UNSAFE`, plattformspezifischen Binaries
und Linux-Grenzen verworfen. Eine reine SQL-Server-2025-Fassade hätte keinen
Backportnutzen. Reines T-SQL deckt den gewünschten Dialekt nicht belastbar ab.

Die verbleibende .NET-Backtrackinggefahr wird durch Syntaxbegrenzung,
Input-/Patternlimits und festen Timeout reduziert, aber nicht eliminiert.
Regex-Aufrufe sind nicht SARGable und es besteht keine Parallelplanzusage.
Aufrufer sollen relationale Vorfilter einsetzen und Timeoutfehler fachlich
behandeln. Replace, Substring, Captures, Split und Matches benötigen eigene
Verträge und Freigaben.
