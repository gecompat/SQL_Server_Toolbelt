# Man kann es auch übertreiben

Theoretische, akademische, absurde oder bewusst unterhaltsame Ideen. Technische Aussagen bleiben korrekt oder werden als Vermutung gekennzeichnet.

> Nur weil man etwas kann, muss man es nicht tun.

Vorlage: [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md)

## UE-2026-001: Primzahlen-Sieb in reinem T-SQL

| Feld | Wert |
|---|---|
| **ID** | `UE-2026-001` |
| **Titel** | Sieve of Eratosthenes als T-SQL-Capability |
| **Ziel-Repository** | Übertreibungs-Liste |
| **Kategorie** | Core / Mathematik |
| **SQL-Server-Lücke** | SQL Server besitzt keine eingebaute Primzahlenfunktion. |
| **Betroffene Versionen** | SQL Server 2019, 2022, 2025 |
| **Spätere native Funktion** | Keine bekannt. |
| **Use-Case-Typ** | Theoretisch |
| **Nutzen** | Akademisches Experiment und Demonstration set-basierter Grenzen; kein produktiver Nutzen belegt. |
| **Mögliche Technologie** | T-SQL mit Zahlenreihe, rekursivem CTE oder vorberechneter Tabelle; konkrete Form offen. |
| **Performance und Security** | Erwartet: rasch steigender CPU- und TempDB-Aufwand. Security-Auswirkungen nicht vertieft geprüft. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | keine |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `curiosity` |
| **Primärquellen** | https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Keiner, außer ein ausdrücklich freigegebenes akademisches Experiment verlangt es. |
