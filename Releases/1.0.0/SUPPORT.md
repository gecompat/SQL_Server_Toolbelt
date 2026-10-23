# Supportumfang von v1.0.0

Der Benutzer hat am 2026-10-23 den zuvor vorgeschlagenen Supportumfang
übernommen und die ausführbaren Releaseprüfungen in genau einem PR beauftragt.
Dies ist der freigegebene **Zielumfang**. Eine öffentliche Supportzusage entsteht
erst durch die vollständige Abnahme der jeweiligen Kombination und die separat
autorisierte Veröffentlichung. Alle Modulmanifeste bleiben `unreleased`.

## Freigabe

Unmittelbarer Benutzerauftrag: „Gut, dann übernimm den vorgeschlagenen
Supportumfang und arbeite die ausführbaren Releaseprüfungen in einem PR ab.
Dokumentiere verbleibende Blocker. Noch nicht veröffentlichen; die autonome
Weiterentwicklung bleibt pausiert.“

- Alle 45 implementierten Module und ihre bestehenden Versionen bleiben im
  Gesamtpaket, davon 19 im stabilen und 26 im Preview-Kanal. Die Zuordnung steht
  in der generierten [Freigabematrix](FREIGABEMATRIX.md).
- Zielsysteme sind Windows und Linux mit SQL Server 2019 CL150, 2022
  CL150/160 und 2025 CL150/160/170. Plattform-, Provider-, Deployment- und
  Dependencygrenzen des jeweiligen Moduls bleiben verbindlich.
- Lokales und zentrales Deployment sowie zentrale Consumerpfade gehören zum
  Zielumfang, soweit sie im Modulvertrag vorgesehen sind. Windows-Filesystem
  und ZIP-Dateifassaden bleiben lokal; Parser und davon abhängige Funktionen
  werden nicht durch einen Linux-Pakettest freigegeben.
- Neuinstallation, explizit gebundener Repeat und Deinstallation werden
  abgenommen. Historische Upgrades werden nur für tatsächlich geprüfte
  Ausgangsversionen zugesagt. Es gibt keinen universellen Upgradepfad.
- Fertige CLR-DLLs, ScriptDom, Quellen und SQL-/PowerShell-Anleitungen gehören
  zur Lieferung. Für die schnelle Installation ist kein eigener Build nötig.

## Bedeutung der Nachweise

Die Paketprüfung untersucht den gemeinsamen Objektbestand und ausgewählte
feste Ergebnisorakel. Sie ersetzt keine vollständige API-, Security-,
Minimalrechte-, Dateiidentitäts-, Parallelitäts- oder Recoveryabnahme eines
Moduls. Auch Preview erfordert alle Pflichtnachweise im zugesagten Scope.
Fehlende Nachweise begrenzen die veröffentlichbare Kombination; sie werden
nicht durch die Freigabe des Zielumfangs erlassen.

Der maschinenlesbare [Releaseplan](release-plan.json) projiziert diese
Entscheidung. Die [offenen Gates](RELEASE-GATES.md) nennen Ergebnisse,
verbleibende Blocker und benötigte externe Voraussetzungen. Die
Installationsanleitungen [für T-SQL](../../INSTALL.md) und
[für CLR](CLR-INSTALL.md) bleiben die Einstiege für Anwender.

Authentifizierte TLS-Abnahme und die vereinbarten optionalen Laufzeitmessungen
bleiben getrennt. Dieser Auftrag aktiviert keine allgemeine autonome
Weiterentwicklung, Automation, Veröffentlichung oder neue fachliche Funktion.
