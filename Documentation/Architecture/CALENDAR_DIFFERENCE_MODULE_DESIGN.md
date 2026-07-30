# Moduldesign Calendar Difference

| Feld | Wert |
|---|---|
| Kandidat | `TC-2026-002` |
| Modul | `toolbelt.datetime.calendar-difference` |
| Vertrag besprochen | 2026-07-30 |
| Implementierung freigegeben | 2026-07-30 |

Der erste Slice akzeptiert ausschließlich `date` und liefert eine echte Kalenderzerlegung statt überquerter Boundaries. Die inline TVF ist der kanonische relationale Kern; eine Scalar API wäre für ein mehrspaltiges Ergebnis keine sinnvolle Alternative.

Die Anniversary-Regel entspricht `DATEADD`: nicht vorhandene Monatstage werden an den letzten Tag des Zielmonats geklammert. Negative Intervalle werden nicht komponentenweise negativ, sondern erhalten `Sign = -1`.

Aktuelle Evidenz: [W1 Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml) – `not executed`.
