# Man kann es auch übertreiben

Theoretische, akademische, absurde oder bewusst unterhaltsame Ideen. Technisch korrekt beschrieben – aber ohne Implementierungszusage und ohne Relevanzanspruch.

> „Nur weil man etwas kann, muss man es nicht tun."

Vorlage: [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md)

---

## UE-2026-001: Vollständige Primzahlen-Tabelle in T-SQL (set-basiert, ohne Cursor)

| Feld | Wert |
|---|---|
| **ID** | UE-2026-001 |
| **Titel** | Primzahlen-Sieb (Sieve of Eratosthenes) als reine T-SQL-TVF |
| **Ziel-Repo** | Theoretisch (SQL Server Toolbelt, wenn jemand darauf besteht) |
| **Kategorie** | Core / Mathematisch |
| **SQL-Server-Lücke** | SQL Server hat keine eingebaute Primzahlenfunktion. (Zu Recht.) |
| **Betroffene Versionen** | SQL Server 2019, 2022 |
| **Spätere native Funktion** | Nein (und das ist gut so) |
| **Use-Case-Typ** | Theoretisch |
| **Nutzen** | Akademisches Experiment; demonstriert set-basierte Iteration in T-SQL. Kein produktiver Nutzen bekannt. |
| **Mögliche Technologie** | T-SQL (Inline TVF mit rekursivem CTE) |
| **Performance / Security** | TempDB-Belastung; bei großen Grenzen sehr langsam; kein Security-Risiko. |
| **Plattformgrenzen** | Keine; gleichmäßig nutzlos auf allen Plattformen |
| **Dependencies** | keine |
| **Status** | `curiosity` |
| **Primärquellen** | [Sieve of Eratosthenes (Wikipedia)](https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes) |
| **Prüfdatum** | 2026-07-28 |
| **Nächster Schritt** | Keiner; außer man möchte auf einer Konferenz für Heiterkeit sorgen |
