# Vorgeschlagener Cancellation-Vertrag – TC-2026-018 / W6d

## Status

W6d ist am 2026-09-11 ausdrücklich freigegeben. Dieser Vertrag ist für den
ersten implementierten Slice verbindlich: `toolbelt.core.execution-cancel`
1.0.0 mit `USP_RequestExecutionCancellation`,
`TVF_ExecutionCancellationStatus` und `SVF_IsCancellationRequested`.

## Ziel

Ein Aufrufer soll eine zusammengehörige Ausführung anfordern können, dass sie
nicht weiterarbeitet. Bereits laufende Worker beenden sich an definierten,
kooperativen Prüfpunkten. Die Queue verhindert danach keine unabhängige Arbeit
und beendet niemals unbeteiligte Sessions.

## Empfohlener erster Slice

Der erste Slice beschränkt sich auf persistierte, kooperative Cancellation:

- Eine ExecutionId erhält einen monotonen Cancellation-Status mit Grund,
  anfordernder Identität und UTC-Zeit.
- Worker prüfen diesen Status vor dem Start, zwischen begrenzten Arbeitsschritten
  und vor dem Commit ihres eigenen fachlichen Seiteneffekts.
- Ein bereits angeforderter Abbruch ist idempotent und kann nicht aufgehoben
  werden.
- Ein Worker meldet seine Beobachtung als kontrollierten terminalen oder
  retryfähigen Ausgang über den bestehenden Work-Queue-Vertrag.
- Die Statusabfrage zeigt nur sichere Auditdaten; sie zeigt keine Claim-Tokens,
  Payloads, Session-IDs oder Fehlerdaten anderer Gruppen.

Dieser Slice führt weder KILL aus noch ordnet er eine automatische
Work-Queue-Recovery an. Er ist für SQL Server 2019, 2022 und 2025 sowie Windows
und Linux vorgesehen.

## Entschiedene Abgrenzung

1. Cancellation signalisiert ausschließlich den Worker-Prüfstatus. Sie
   terminalisiert und requeued keine noch nicht beanspruchten Queue-Items.
2. Der Kern erzwingt keine Zeitgrenze zwischen Prüfpunkten. Jeder Work-Type-
   Vertrag definiert seine begrenzten Arbeitsschritte und Checkpoints.
3. Eine ExecutionId mit persistierter Anforderung bleibt dauerhaft cancelled;
   eine neue Ausführung verwendet eine neue ExecutionId.
4. Ein `KILL`-Fallback bleibt ein separater, nicht freigegebener
   Administrationsslice mit eigener Berechtigung und Attestierung.

Die Anforderung wird nur außerhalb einer aktiven Caller-Transaktion angenommen.
Dadurch ist der kurze eigene Commit nicht von einem späteren Caller-Rollback
abhängig. Grund und anfordernde Identität werden intern gespeichert; die
öffentliche Statusabfrage beschränkt sich auf ID, Flag und UTC-Zeit.

## Alternativen

- **Nur Queue-Sperre:** verhindert keine bereits laufende Arbeit und genügt dem
  Abbruchziel nicht.
- **Sofortiges KILL:** benötigt hohe Rechte, kann lange Rollbacks auslösen
  und ist wegen wiederverwendeter Session-IDs kein sicherer Default.
- **Provider-spezifische Abbrüche:** bleiben Ergänzungen für Agent, Broker oder
  externe Worker; sie sind nicht Teil des portablen T-SQL-Kerns.

## Risiken und Grenzen

Kooperative Cancellation ist keine Transaktionsrücknahme und garantiert keinen
Abbruch eines nicht kooperierenden Providers. Ein schon ausgeführter externer
Seiteneffekt wird nicht zurückgenommen. Die Cancellation-Anforderung selbst
darf keine Berechtigung zur Ausführung von Raw SQL oder zur Beendigung fremder
Sessions verleihen.

## Geplanter Nachweis

Der spätere freigegebene Slice prüft mindestens wiederholte Anforderung,
Parallelität von Anforderung und Worker-Prüfung, Caller-Transaktionen,
uncommittable Transaktionen, Sichtschutz, Work-Queue-Übergänge, Lifecycle,
Upgrade, Central-Installation und Uninstall. Runtime-Ziele folgen der
betroffenen SQL_Server_Lab-Matrix; ein CU ist nur bei einem patchgebundenen
Testfall auszuwählen.
