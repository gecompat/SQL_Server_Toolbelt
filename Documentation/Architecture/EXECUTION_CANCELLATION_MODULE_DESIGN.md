# Vorgeschlagener Cancellation-Vertrag – TC-2026-018 / W6d

## Status

Dieser Entwurf dient ausschließlich der Vertragsbesprechung. Er ist keine
Implementierungsfreigabe und legt keine öffentlichen SQL-Objekte endgültig
fest. W6d bleibt bis zu einer ausdrücklichen Freigabe researched.

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

## Offene Entscheidungen

1. Soll eine Cancellation alle noch nicht beanspruchten Work Items derselben
   ExecutionId terminalisieren, sie auf RETRY_WAIT setzen oder nur den
   Worker-Prüfstatus signalisieren?
2. Welcher maximale Zeitraum darf zwischen zwei verpflichtenden Prüfpunkten
   liegen? Der Providervertrag muss diese Grenze je Work Type nachweisen.
3. Darf ein berechtigter Administrator eine neue Ausführung mit derselben
   ExecutionId beginnen, oder bleibt die Id dauerhaft gesperrt?
4. Soll ein technischer KILL-Fallback überhaupt bereitgestellt werden? Falls
   ja, ist er ein separater administrativer Slice mit eigener Berechtigung,
   Session-Attestierung, Rollback-Beobachtung und eigenem Testplan.

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

