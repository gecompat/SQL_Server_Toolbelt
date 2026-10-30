# toolbelt_core.USP_DeleteRecordedEventsBefore

**Status:** implemented; teilweise validiert, unveröffentlicht.

## Zweck und Vertrag

Nur ausdrücklich aufgerufene Retention nach RecordedAtUtc mit Index (RecordedAtUtc,EventId), deterministischen begrenzten Batches und bestehender Caller-Transaktions-/Savepointsemantik. Kein Job, keine Deploymentlöschung. Die OccurredAtUtc-Retention bleibt unverändert. Erfordert vorhandenes EXECUTE; erteilt keine Berechtigungen. Fehler 51710–51714 wie im bestehenden Retentionvertrag.

## Parameter

- `@BeforeRecordedAtUtc`: datetime2(7), erforderlich; exklusiver Cutoff für serverseitiges RecordedAtUtc.
- `@BatchSize`: int=1000; 1 bis 10000.
- `@MaxBatches`: int=1; 1 bis 100.
- `@DeletedRows`: bigint OUTPUT=NULL; initial 0, Anzahl dieses Aufrufs.
- `@Debug`: tinyint=0; feste Fortschrittsmeldung ohne Eventinhalt.
- `@Hilfe`: bit=0; 1 liefert ausschließlich Hilfe.

## Ergebnis

Kein fachliches Resultset; @DeletedRows bigint OUTPUT.

## Beispiel

```sql
DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @BeforeRecordedAtUtc='2026-01-01',@BatchSize=1000,@MaxBatches=1,@DeletedRows=@n OUTPUT;
```

## Freigabe und Nachweise

Ausdrücklich am 2026-10-15 mit Zweck, Vertrag, Alternativen, Risiken und Grenzverhalten freigegeben. Siehe [Security-Härtung](../../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md). Neue Runtime-/CI-Nachweise werden dort getrennt vom Implementierungsstand geführt. Keine Parallelitäts-, Heap- oder harte Echtzeitzusage.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@BeforeRecordedAtUtc` | `datetime2(7)` | `NULL` | Input | datetime2(7), erforderlich; exklusiver Cutoff für serverseitiges RecordedAtUtc. |
| `@BatchSize` | `int` | `1000` | Input | int=1000; 1 bis 10000. |
| `@MaxBatches` | `int` | `1` | Input | int=1; 1 bis 100. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | bigint OUTPUT=NULL; initial 0, Anzahl dieses Aufrufs. |
| `@Debug` | `tinyint` | `0` | Input | tinyint=0; feste Fortschrittsmeldung ohne Eventinhalt. |
| `@Hilfe` | `bit` | `0` | Input | bit=0; 1 liefert ausschließlich Hilfe. |

## Voraussetzungen für den Aufruf

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zweite-session).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_DeleteRecordedEventsBefore.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
