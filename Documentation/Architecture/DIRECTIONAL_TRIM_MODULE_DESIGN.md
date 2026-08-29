# Moduldesign Directional TRIM Compatibility

| Feld | Wert |
|---|---|
| Kandidat | `TC-2026-008` |
| Modul | `toolbelt.string.directional-trim` |
| Vertrag besprochen | 2026-07-30 |
| Implementierung freigegeben | 2026-07-30 |

Die Capability ist eine Kompatibilitätsschicht zur positionsabhängigen `TRIM`-Syntax von SQL Server 2022 bei Compatibility Level 160. Die getrennten TVFs erhalten `varchar` und `nvarchar`; die inline TVFs sind zugleich der kanonische mengenorientierte Kern. Scalar-Wrapper werden nicht bereitgestellt, weil sie für diese kleine Anwendung keinen zusätzlichen Vertrag schaffen.

Die Richtung ist absichtlich explizit. Ein ungültiger Wert ist ein Programmierfehler und führt nicht zu einem stillen Fallback. Pattern-Escaping wird nicht benötigt, weil die Zeichensatzprüfung über `CHARINDEX` erfolgt.

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) sowie der lokale Lauf vom 2026-08-29 – vollständiger Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Windows-Läufe bleiben `not executed`.
