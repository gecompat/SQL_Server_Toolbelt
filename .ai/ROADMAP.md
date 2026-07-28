# ROADMAP.md – SQL Server Toolbelt

## Status

Repository-Grundaufbau und Foundation-Korrektur sind abgeschlossen. Es sind noch keine fachlichen Module implementiert.

## Phase 0 – Repository-Grundaufbau

**Status:** `completed`  
**Abschluss:** 2026-07-28

Enthält Root-Dateien, AI-Steuerung, Architektur- und Standardsdokumentation, Modul-Templates, Backlog-Struktur und den USP-Vertrag.

## Phase 0.1 – Foundation-Korrektur

**Status:** `completed`  
**Abschluss:** 2026-07-29

Enthält:

- korrigiertes GitHub-Copilot-Custom-Agent-Profil;
- objekttypspezifische SQL- und Dokumentations-Templates;
- vollständige USP-Contract-Testanforderungen;
- SQL Server 2025 in Support- und Testmatrizen;
- präzisierte CLR-, Linux- und `TRUSTWORTHY`-Regeln;
- vervollständigtes Entscheidungsprotokoll;
- konsolidierte Status-, Sprach- und Contribution-Regeln.

## Phase 1 – Erstes Kernmodul

**Status:** `proposed`

**Ziel:** Ein priorisiertes `toolbelt_core`-Modul als Referenzimplementierung für Modulabhängigkeiten, Lifecycle, Dokumentation und Tests.

**Voraussetzungen:**

- mindestens ein priorisierter Kandidat in `.ai/BACKLOG.md`;
- abgestimmter öffentlicher Vertrag;
- freigegebenes Arbeitspaket;
- geklärte Namenskonventionen für erstmals benötigte weitere Objekttypen.

## Phase 2 – Weitere Module

**Status:** `proposed`  
**Abhängigkeit:** mindestens ein validiertes Referenzmodul.

Schrittweise Umsetzung priorisierter Toolbelt-Kandidaten nach fachlicher Kategorie und Dependency-Reihenfolge.

## Phase 3 – Schlanke Test-Infrastruktur und CI

**Status:** `proposed`  
**Abhängigkeit:** mindestens ein implementiertes Modul mit konkreten Testpfaden.

Pfadbezogene statische Prüfungen und capability-spezifische Runtime-Tests; keine pauschale Vollmatrix für reine Dokumentationsänderungen.

## Repository-Grenze

Analyse-, Diagnose-, Performance-, Konfigurations- und Security-Assessment-Ideen für `gecompat/SQL_Server_Analyze` werden nur in `Backlog/SQL_SERVER_ANALYZE_CANDIDATES.md` gesammelt und nicht hier implementiert.
