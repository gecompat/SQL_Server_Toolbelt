# toolbelt_json.TVF_ResolveJsonPointer

Öffentliche lesende Multi-statement T-SQL-TVF aus `toolbelt.json.pointer`1.0.0.
Der [kanonische Vertrag](../../../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
ist für Semantik und Fehlerpriorität verbindlich.

| Parameter | Typ | Default |
|---|---|---|
| Json | nvarchar(max) | keiner |
| Pointer | nvarchar(max) | keiner |
| MaxInputBytes | bigint | 16777216 |
| MaxDepth | int | 128 |

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
POINTER_SYNTAX → Pointer-UNICODE → JSON_SYNTAX → DEPTH_LIMIT →
Dokument-UNICODE → Auflösung mit DUPLICATE_KEY/ARRAY_INDEX.

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
