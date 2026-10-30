# toolbelt_json.TVF_JsonPathExistsStatus

**Status:** implemented; teilweise validiert, unveröffentlicht.

## Zweck und Vertrag

Genau eine Zeile: FOUND/1, MISSING/0, INVALID/0, SQL_NULL/NULL oder LIMIT/NULL. Höchstens 10000 Frontierwerte; maximal 10001 werden zur Überschreitungsfeststellung aufgenommen. Vor jedem OPENJSON werden die vorgesehenen Inputbytes gegen das kumulative 64-MiB-Budget gebucht. Containerroots werden ohne zusätzliche Wrapper-Ebene validiert. Die bisherige TVF liefert bei LIMIT NULL; kein falsches MISSING.

## Parameter

- `@Json`: nvarchar(max); höchstens 16 MiB UTF-16, vor nativer Validierung lexikalische Containertiefe höchstens 128.
- `@Path`: nvarchar(max); bestehender 4000-Codeeinheitenvertrag und höchstens 128 Segmente.

## Ergebnis

PathExists int, Status varchar(16).

## Beispiel

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a":null}',N'$.a');
```

## Freigabe und Nachweise

Ausdrücklich am 2026-10-15 mit Zweck, Vertrag, Alternativen, Risiken und Grenzverhalten freigegeben. Siehe [Security-Härtung](../../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md). Neue Runtime-/CI-Nachweise werden dort getrennt vom Implementierungsstand geführt. Keine Parallelitäts-, Heap- oder harte Echtzeitzusage.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | nvarchar(max); höchstens 16 MiB UTF-16, vor nativer Validierung lexikalische Containertiefe höchstens 128. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | nvarchar(max); bestehender 4000-Codeeinheitenvertrag und höchstens 128 Segmente. |

## Voraussetzungen für den Aufruf

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#json-pfade).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_JsonPathExists.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
