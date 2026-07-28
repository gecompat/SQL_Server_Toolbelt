# ROADMAP.md – SQL Server Toolbelt

## Status

Repository-Grundaufbau, Foundation-Korrektur und erste Backlog-Research-Welle sind abgeschlossen. Es sind noch keine fachlichen Module implementiert.

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

## Phase 0.2 – Backlog Research Wave 1

**Status:** `completed`  
**Abschluss:** 2026-07-29

Enthält:

- Präzisierung der bestehenden Kandidaten `TC-2026-001` und `TC-2026-002`;
- neue Kandidaten `TC-2026-003` bis `TC-2026-013`;
- versionsbezogene Abgrenzung zwischen SQL Server 2019, 2022 und 2025;
- Primärquellen, Plattformgrenzen, Performance-/Security-Fragen und konkrete nächste Schritte;
- Priorisierung der ResultTable-Infrastruktur als erstes Kernarbeitspaket.

## Phase 1 – Erstes Kernmodul

**Status:** `planned`

**Ausgewählter Kandidat:** `TC-2026-003` – ResultTable-Routing und automatische Anpassung lokaler Temp-Tabellen.  
**Aktives Arbeitspaket:** `AP-2026-002` – implementierungsreife Spezifikation des ersten `toolbelt_core`-Moduls.

**Ziel:** Ein priorisiertes `toolbelt_core`-Modul als Referenzimplementierung für Modulabhängigkeiten, Lifecycle, Dokumentation, USP-Verträge und Tests.

**Reihenfolge:**

1. Modul- und Objektvertrag implementierungsreif spezifizieren;
2. erstmals benötigte ungeregelte Objekttypen vor Benennung entscheiden;
3. Implementierung als eigene Welle freigeben;
4. statische, Contract-, Runtime-, Collation-, Plattform- und Deployment-Tests ausführen;
5. erst nach tatsächlicher Evidenz den Status `implemented` beziehungsweise `validated` vergeben.

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
