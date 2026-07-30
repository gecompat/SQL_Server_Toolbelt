# Moduldesign Directional TRIM Compatibility

| Feld | Wert |
|---|---|
| Kandidat | `TC-2026-008` |
| Modul | `toolbelt.string.directional-trim` |
| Vertrag besprochen | 2026-07-30 |
| Implementierung freigegeben | 2026-07-30 |

Die Capability ist eine Kompatibilitätsschicht zur positionsabhängigen `TRIM`-Syntax von SQL Server 2022 bei Compatibility Level 160. Die getrennten TVFs erhalten `varchar` und `nvarchar`; die inline TVFs sind zugleich der kanonische mengenorientierte Kern. Scalar-Wrapper werden nicht bereitgestellt, weil sie für diese kleine Anwendung keinen zusätzlichen Vertrag schaffen.

Die Richtung ist absichtlich explizit. Ein ungültiger Wert ist ein Programmierfehler und führt nicht zu einem stillen Fallback. Pattern-Escaping wird nicht benötigt, weil die Zeichensatzprüfung über `CHARINDEX` erfolgt.

Aktuelle Evidenz: [W1 Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml) – `not executed`.
