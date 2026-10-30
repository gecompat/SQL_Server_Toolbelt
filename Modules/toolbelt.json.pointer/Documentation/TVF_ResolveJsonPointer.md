# toolbelt_json.TVF_ResolveJsonPointer

Öffentliche lesende Multi-statement T-SQL-TVF aus `toolbelt.json.pointer`1.0.0.
Der [kanonische Vertrag](../../../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
ist für Semantik und Fehlerpriorität verbindlich.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, wohlgeformtes Unicode auch in decodierten Escapes. Leer ist ungültig; DATALENGTH darf MaxInputBytes nicht überschreiten. Vor nativer Prüfung gilt die absolute Containertiefengrenze 128, danach das abgesenkte MaxDepth. NULL in Json oder Pointer ergibt SQL_NULL vor Parameterprüfung. Kein partiell gültiges Dokument und keine Mutation. |
| `@Pointer` | `nvarchar(max)` | `kein Default` | Input | RFC6901-Stringpointer, keine URIfragmentform #/...: leer bezeichnet Root, sonst beginnt der Text mit /. Segmente sind exakte binäre/case-sensitive Objektkeys; ~0 decodiert einmal zu ~, ~1 zu /. Kein anderes ~-Escape oder Percentdecoding. Arrayindizes sind nullbasiert kanonische nicht negative ASCII-Dezimalzahlen ohne führende Nullen; - ist kein Appendindex, Wildcards fehlen. Maximal 4000 UTF-16-Einheiten, wohlgeformtes Unicode; / bezeichnet einen leeren Key. NULL ergibt SQL_NULL. |
| `@MaxInputBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Bytes des JSON-Dokuments, Default 16777216; keine Zeichenanzahl. NULL/außerhalb ergibt INVALID/PARAMETER, Überschreitung INVALID/INPUT_LIMIT. Nur absenkbar; früher Json-/Pointer-NULL-Pfad hat Vorrang. |
| `@MaxDepth` | `int` | `128` | Input | Ganzzahl 1..128 gleichzeitig offene JSON-Container, Default 128. Gilt für das gesamte Dokument, auch nicht traversierte Teile. NULL/außerhalb ergibt INVALID/PARAMETER; vor nativer JSON-Prüfung bleibt zusätzlich die absolute Schutzgrenze 128 wirksam. |
<!-- API_PARAMETERS:END -->

Budgets nur positiv und absenkbar; Pointer höchstens4000 UTF16-Einheiten.
Containerroot zählt Tiefe1, Scalarroot0. Bei Aufrufen alle vier Argumente
angeben; DEFAULT verwendet den jeweiligen Budgetdefault.

| Spalte | Typ | Nullable |
|---|---|---|
| Status | varchar(16) | nein |
| JsonType | varchar(8) | ja |
| Value | nvarchar(max) | ja |
| ErrorCode | varchar(32) | ja |

Alle Textspalten Latin1_General_100_BIN2. Genau eine Zeile, auch für
SQL_NULL/MISSING/INVALID. FOUND besitzt Typ/Wert, einschließlich leerer
Strings. JSON_NULL besitzt JsonType='NULL' und Value=SQL-NULL.
MISSING/SQL_NULL/INVALID besitzen keinen Typ/Wert. ErrorCode nur bei INVALID.

Priorität: SQL_NULL → PARAMETER → INPUT_LIMIT → POINTER_LIMIT →
POINTER_SYNTAX → Pointer-UNICODE → fester Strukturguard128/DEPTH_LIMIT →
JSON_SYNTAX → caller-seitig abgesenktes DEPTH_LIMIT →
Dokument-UNICODE → Auflösung mit DUPLICATE_KEY/ARRAY_INDEX und dem vor jedem
OPENJSON-Aufruf geprüften kumulativen Parserbudget.

Die ausdrücklich freigegebene Härtung SC-006 begrenzt die Summe aller
OPENJSON-Operandbytes auf 67108864 (64 MiB), einschließlich Scalarwrapper
und wiederholter Fragmente. Vor einer Überschreitung folgt genau eine Zeile
INVALID/WORK_LIMIT mit JsonType/Value=SQL-NULL. Kein neuer Parameter, kein
Teilwert und keine Laufzeit-/Heapzusage; bereits früher festgestellte
Ergebnisse behalten ihre Priorität.

Der feste Guard beobachtet Klammern außerhalb von Strings escape-aware mit
nicht negativem Zähler. Über128 hat DEPTH_LIMIT auch bei fehlerhafter Syntax
Vorrang; bis128 bleibt vollständige Syntax vor dem abgesenkten MaxDepth.

Leerer Pointer adressiert Root; ~0 und ~1 decodieren einmal. Exakte Keys
einschließlich trailing spaces/NUL; nur passende Duplikate sind ungültig.
Arrayindices sind0 oder positive ASCII-Ziffern ohne führende Null;
`-` und gültige zu große Indices ergeben MISSING. Weiterlaufen durch
Scalar/null ergibt MISSING. Vollständige Unicode-/Tiefenprüfung erfasst
auch unselektierte Dokumentteile; gültige gemischte raw/escaped Paare erlaubt.

```sql
SELECT input.Pointer,resolved.Status,resolved.JsonType,resolved.Value,resolved.ErrorCode
FROM (VALUES(N''),(N'/items/0'),(N'/items/1'),(N'/absent')) input(Pointer)
CROSS APPLY toolbelt_json.TVF_ResolveJsonPointer(N'{"items":[null,"example"]}',input.Pointer,DEFAULT,DEFAULT) resolved;
```

Keine Seiteneffekte oder eigenen Transaktionen. Vorhandenes SELECT erforderlich;
CrossDB benötigt passende Rechte und Caller-CL150+. Zielmatrix SQL2019/2022/2025
Windows/Linux, CL150+ innerhalb der Enginegrenze. Repeated Fragmentparsing und
MSTVF-Kardinalität begründen keine Inline-/Performancezusage. Ausgeführte
Kontexte und verbleibende Grenzen stehen in [Tests/README.md](../Tests/README.md).

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#json-pointer).
