# Worker-Qualifikation

## Ausgeführter deterministischer Scope

Am 2026-10-02 besteht `pwsh -NoProfile -File
Workers/ExternalQueue/Tests/Worker.Contract.ps1` auf dem Windows-Workerhost.
Fault-Orakel prüfen unbekannten Commit/Rollback ohne Replay, Ownershipverlust,
Cancellation-Bestätigung, Default-/Slot-/Claimbudgets, Heartbeat im Drain,
Watchdog und bestätigten Commit mit getrenntem Cleanupfehler.
Geschlossene synthetische SqlConnections prüfen die tatsächliche
Callback-/Parameterbindung ohne Netzwerkzugriff.

Dies belegt die geprüfte Supervisorpolitik und die lokale Bindung.
Es simuliert keinen realen Transportverlust bei einem SQL-Commit.

## Runtime-Matrix

| Workerhost | SQL-Ziel | Provider/Scope | Nachweisstand |
|---|---|---|---|
| Windows | 2019 Linux/latest | Lokaler Lab-Adapter, vollständige synthetische Fixtures | erfolgreich am 2026-10-02 |
| Windows | 2025 Windows/CU8, über allgemeinen base-Selektor mit erlaubter CU-Äquivalenz | Lokaler Lab-Adapter, vollständige synthetische Fixtures | finaler Source-Stand erfolgreich am 2026-10-02 |
| Linux | 2019 Linux | CI-Adapter mit eigener synthetischer Instanz | `not executed` bis zur erfolgreichen PR-CI |
| Windows/Linux | übrige Versionen und Zielkombinationen | Getrennte weitere Qualifikation | `not executed` |

Die [Fixtures](Runtime/Fixtures.sql) und der
[Runtime-Adapter](Runtime/Invoke-Contract.ps1) prüfen NONE/JSON, Unicode,
informative Returncodes, atomaren SQL-Effekt/Complete, Rollback, Unsupported-
und Resultsetfehler, Retry/Dead Letter, manuelle Cancellation und Watchdog,
parallele Slots, Stop/Grace sowie einen Handler über 60 Sekunden mit erneuerter
Lease. Contextdrift darf weder einen Commit noch einen Retry erzeugen.

Die Lab-Auswahl folgt dem schema-validierten Vertrag und dem READY-Gate aus
`AGENTS.md`; ein allgemeiner Windows-base-Lauf prüft deterministisch alle
bereiten base-/CU-Ziele dieser Version. Keine Lab-Infrastruktur- oder
Serverparameteränderung gehört zu diesem Test.

Die zusätzlichen fokussierten Identity-Tests mit `-IdentityGuardsOnly`
bestehen am 2026-10-02 auf beiden ausgewählten Zielen: tatsächlicher
SQL-Readonly-Fehler 15664 bleibt trotz expliziter Retry-Allowlist terminal,
der synthetische Effekt wird zurückgerollt. Mutable Contextdrift erzeugt
einen ungeklärten Claim ohne Retry oder committed Effekt.
Die vorherigen Volltests bleiben als eigener Nachweis erhalten; nach der
engen Scheduling-Härtung besteht der finale vollständige Windows-2025-Lauf.

## Offene Nachweise und Cleanup

Echte Commit-Transportfaults, Cross-Principal-Minimalrechte, Recoveryrennen
und zentraler Deploymentmodus bleiben separate offene Runtime-Orakel.
Die bestehenden SQL-Kernnachweise werden nicht als Worker-Nachweis übernommen.
Die Host-/Versionsmatrix, Produktionskapazität und permanenter Betrieb sind
keine aus diesen Tests ableitbaren Zusagen.

Der Adapter erzeugt eine eindeutige eigene synthetische Datenbank und wartet
vor Cleanup auf alle eigenen Worker. Er entfernt sie ohne SQL-KILL oder
`ROLLBACK IMMEDIATE`. Unvollständiger Cleanup scheitert sichtbar; private
Diagnostik und Verbindungskonfiguration werden nicht versioniert.

Der [Providervertrag](../../../Documentation/Architecture/EXTERNAL_QUEUE_WORKER_CONTRACT.md)
legt Akzeptanzkriterien, Autorität und Grenzen fest. Plan und Testcode sind
kein erfolgreicher Ausführungsnachweis.
