# Moduldesign Calendar Difference

| Feld | Wert |
|---|---|
| Kandidat | `TC-2026-002` |
| Modul | `toolbelt.datetime.calendar-difference` |
| Vertrag besprochen | 2026-07-30 |
| Implementierung freigegeben | 2026-07-30 |

Der erste Slice akzeptiert ausschließlich `date` und liefert eine echte Kalenderzerlegung statt überquerter Boundaries. Die inline TVF ist der kanonische relationale Kern; eine Scalar API wäre für ein mehrspaltiges Ergebnis keine sinnvolle Alternative.

Die Anniversary-Regel entspricht `DATEADD`: nicht vorhandene Monatstage werden an den letzten Tag des Zielmonats geklammert. Negative Intervalle werden nicht komponentenweise negativ, sondern erhalten `Sign = -1`.

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) sowie der lokale Lauf vom 2026-08-29 – vollständiger Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Windows-Läufe bleiben `not executed`.
