# toolbelt_core.TVF_GenerateSeriesBigIntStatus

**Status:** implemented; teilweise validiert, unveröffentlicht.

## Zweck und Vertrag

Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen.

## Parameter

- `@Start`: bigint; inklusiver Start.
- `@Stop`: bigint; inklusives Ende bei erreichbarem Schritt.
- `@Step`: bigint=NULL; Richtung automatisch; 0 ergibt INVALID.

## Ergebnis

Value bigint, Status varchar(16), RequestedRows decimal(38,0).

## Beispiel

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,DEFAULT);
```

## Freigabe und Nachweise

Für SELECT-Aufrufe ist `SELECT` auf der Funktion erforderlich.

Ausdrücklich am 2026-10-15 mit Zweck, Vertrag, Alternativen, Risiken und Grenzverhalten freigegeben. Siehe [Security-Härtung](../../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md). Neue Runtime-/CI-Nachweise werden dort getrennt vom Implementierungsstand geführt. Keine Parallelitäts-, Heap- oder harte Echtzeitzusage.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | bigint; inklusiver Start. |
| `@Stop` | `bigint` | `kein Default` | Input | bigint; inklusives Ende bei erreichbarem Schritt. |
| `@Step` | `bigint` | `NULL` | Input | bigint=NULL; Richtung automatisch; 0 ergibt INVALID. |

## Voraussetzungen für den Aufruf

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_GenerateSeriesBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
