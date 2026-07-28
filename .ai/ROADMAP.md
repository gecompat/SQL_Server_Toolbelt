# ROADMAP.md – SQL Server Toolbelt

## Status: In Entwicklung – keine fachlichen Module implementiert

Diese Roadmap ordnet Arbeitsphasen nach Priorität und Abhängigkeiten. Kein Eintrag hier ist eine Implementierungszusage; konkrete Arbeitspakete werden nach Priorisierung in `BACKLOG.md` übernommen.

---

## Phase 0 – Repository-Grundaufbau (aktuell)

**Ziel:** Struktur, Regeln, Architektur, Templates, Backlogs und Dokumentation als stabile Basis.

**Status:** `planned` → Initiales Setup per PR

Enthält:
- Root-Dateien, AI-Metadaten, GitHub-Konfiguration
- Architektur- und Standardsdokumentation
- USP-Vertrag, Namenskonventionen, T-SQL-Regeln
- Templates für neue Module
- Backlog-Kandidaten

**Abhängigkeiten:** keine

---

## Phase 1 – Erstes Kernmodul (geplant)

**Ziel:** Ein validiertes `toolbelt_core`-Modul als Referenzimplementierung für das Modulprinzip.

**Status:** `proposed`

Voraussetzungen:
- Phase 0 abgeschlossen und gemergt
- Mindestens ein priorisierter Kandidat in `BACKLOG.md`
- Abgestimmtes Arbeitspaket mit stabiler ID

**Abhängigkeiten:** Phase 0

---

## Phase 2 – Weitere Module (geplant)

**Ziel:** Schrittweise Implementierung weiterer Module aus dem Backlog.

**Status:** `proposed`

**Abhängigkeiten:** Phase 1

---

## Phase 3 – Test-Infrastruktur und CI (geplant)

**Ziel:** Schlanke, pfadbezogene CI-Pipeline für implementierte Module; keine große Actions-Matrix ohne konkreten Bedarf.

**Status:** `proposed`

**Abhängigkeiten:** Phase 1 (mindestens ein validiertes Modul)

---

## Hinweis

Analyse-, Diagnose- und Security-Ideen für `gecompat/SQL_Server_Analyze` werden in `Backlog/SQL_SERVER_ANALYZE_CANDIDATES.md` gesammelt, aber nicht hier implementiert.
