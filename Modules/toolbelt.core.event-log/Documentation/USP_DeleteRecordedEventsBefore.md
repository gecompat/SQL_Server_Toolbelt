# toolbelt_core.USP_DeleteRecordedEventsBefore

**Status:** implemented; teilweise validiert, unveröffentlicht.

## Zweck und Vertrag

Nur ausdrücklich aufgerufene Retention nach RecordedAtUtc mit Index
(RecordedAtUtc,EventId), deterministischen begrenzten Batches und bestehender
Caller-Transaktions-/Savepointsemantik. Kein Job, keine Deploymentlöschung.
Die OccurredAtUtc-Retention bleibt unverändert. Erfordert vorhandenes EXECUTE;
erteilt keine Berechtigungen. Eigene Fehler 51710–51713; kein eigener THROW 51714.

Alle Batches eines Aufrufs laufen in einer gemeinsamen Transaktion. Es gibt
keinen separaten Commit pro Batch. Der OUTPUT-Zähler nach Fehler ist kein Beleg
committeter Löschungen. Der vollständige
[Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_DeleteRecordedEventsBefore.md)
steht in der DDL und folgt bei `@Hilfe=1` als zusätzliche vier-spaltige Skillzeile
auf die bisherige Standardhilfe. `@DeletedRows` bleibt bei Hilfe initial 0.

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

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@BeforeRecordedAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich RecordedAtUtc &lt; Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung. |
| `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/&gt;10000 wird abgewiesen. |
| `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/&gt;100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable mit OUTPUT übergeben; kein Löschlimit. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Vorhandenes EXECUTE auf diese Retention-USP und gültige bestehende
  Abhängigkeitsrechte auf EventLog. Kein Second-Session-Provider nötig;
  uncommittable Callertransaktionen werden abgewiesen. Keine Rechtevergabe.

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
