# TVF_UnquoteToken

Funktionsbezogen ausdrücklich freigegeben am 2026-10-01 nach
[Vertragsbesprechung](../../../Documentation/Architecture/ADVANCED_STRING_SPLIT_PROPOSAL.md):
„Unquoting, Split-USP und ZIP-Writer implementieren“. Diese Seite beschreibt
Unquoting im Split-Modul 1.1.0, nicht den getrennten ZIP-Scope.

## API

~~~sql
SELECT * FROM toolbelt_string.TVF_UnquoteToken
    (N'[a]]b]', DEFAULT, DEFAULT, DEFAULT);
~~~

Input nvarchar(max), Qualifier nvarchar(max)=NULL,
ClosingQualifier nvarchar(max)=NULL, BackslashEscape bit=0.
NULL Input liefert früh null Zeilen, auch bei ungültiger Konfiguration.
Sonst genau eine Zeile: Value nvarchar(max) NULL, IsValid bit NOT NULL,
ErrorCode varchar(64) NULL, ErrorPosition bigint NULL.
Erfolg IsValid=1 und Fehlerfelder NULL; Fehler Value=NULL/IsValid=0.
Erst vollständiger Erfolg veröffentlicht den transformierten Text.

Qualifier NULL: Auto erkennt exakt ASCII doppelt/einfach, [], “…” und „…“,
nur anhand des ersten Zeichens. Unvollständige Ränder bleiben unverändert.
Qualifier leer: Disabled, Originaltext unverändert. In beiden Fällen muss
ClosingQualifier NULL sein. Explicit verwendet einzelne Nicht-Surrogate-BMP-
Codeeinheiten; NUL verboten. Ohne ClosingQualifier wählen [ und ] dasselbe
[]-Paar, U+201C/U+201D englisch U+201C/U+201D, U+201E deutsch U+201E/U+201C,
sonst symmetrisch. Explizites ClosingQualifier übersteuert diese Zuordnung.
Leeres ClosingQualifier ist ungültig. Backslash als Delimiter ist bei
aktivem BackslashEscape ungültig; ohne Opt-in erlaubt.

Ein Randpaar benötigt mindestens zwei Codeeinheiten. Explicit ohne passendes
äußeres Paar ist Fehler; Auto bleibt unverändert. Kein Trim/Normalisieren.
Im gültigen Body werden doubled closing einmal dekodiert. Ein einzelnes
unescaped closing im Body ist Fehler; opening im Body bleibt literal.
Der reservierte äußere closing darf keine zweite Hälfte eines Doubles sein.

BackslashEscape NULL entspricht 0. Opt-in 1 dekodiert nur Backslash plus
aktives opening/closing sowie Backslash plus Backslash; übrige Folgen bleiben
literal, insbesondere keine n/t/Unicode-Escapes. Escape hat im Body Vorrang
vor doubled closing. Ein escaped letztes closing ist kein Randdelimiter:
Explicit Fehler, Auto Originaltext. Odd/even Runs werden links nach rechts
auf Originalcodeeinheiten ausgewertet. Terminaler Body-Backslash bleibt
literal, kein Split-DANGLING_ESCAPE.

## Priorität und Grenzen

NULL Input, dann gesamte Konfiguration, Inputlimit, erstes Input-NUL,
Randprüfung, Body. Input maximal 65536 UTF-16-Codeeinheiten einschließlich
trailing Spaces, BIN2 (Latin1_General_100_BIN2), keine Kürzung.
Supplementary-Codeeinheiten bleiben erhalten; keine Graphemzusage.

| ErrorCode | ErrorPosition |
|---|---|
| INVALID_CONFIGURATION | NULL |
| INPUT_LIMIT_EXCEEDED | NULL |
| NUL_NOT_ALLOWED | erste Originalposition ab 1 |
| OUTER_PAIR_REQUIRED | Empty NULL; falsches erstes Zeichen oder Einzelquote 1; sonst letzte Originalposition |
| UNESCAPED_CLOSING_QUALIFIER | Originalposition |

Auto ohne Randpaar prüft keinen Body; Input-NUL/Limit bleiben auch in
Disabled vorgeschaltet. Engine-/Ressourcenfehler werden nicht verschluckt.
SELECT-Recht erforderlich; Cross-DB zusätzlich Caller-Mapping/Rechte.
Für Mengen CROSS APPLY oder OUTER APPLY; kein Scalar-Wrapper.
Bounded MSTVF mit Span-Kopien, keine Durchsatz-/Streaming-/Parallelitätszusage.
Neue 1.1-Runtime-Verträge am 2026-10-01 auf SQL Server 2019 Linux/latest
und SQL Server 2025 Windows/CU8 erfolgreich. Weitere neue Version-/Plattform-
kombinationen, GitHub-1.1-Lauf und niedrigprivilegierter mapped Caller Cross-DB
nicht ausgeführt; Modul bleibt partially validated. Reproduzierbare Befehle
und genauer Scope stehen in [Tests/README](../Tests/README.md).
