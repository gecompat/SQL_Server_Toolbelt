# BACKLOG.md – Priorisierte Arbeitspakete

Nur priorisierte Kandidaten werden hier als konkrete Arbeitspakete geführt. Ein Eintrag ist keine automatische Implementierungszusage; er wird durch ausdrückliche Benutzerfreigabe aktiv.

## Aktive Arbeitspakete

### AP-2026-002: ResultTable-Infrastruktur implementierungsreif spezifizieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-002` |
| Ziel | Den Kandidaten `TC-2026-003` als erstes `toolbelt_core`-Modul so spezifizieren, dass anschließend eine getrennte Implementierungswelle ohne offene Vertragsfragen beginnen kann. |
| Scope | Modulgrenze, Objektinventar, öffentliche und interne Schnittstellen, Schemaquellen, Transaktions- und Fehlergrenzen, Dependency- und Lifecycle-Vertrag, Contract-Testmatrix. Noch keine Runtime-Implementierung. |
| Dependencies | `TC-2026-003`, `Documentation/Standards/USP_CONTRACT.md`, Modul- und Deployment-Modell. |
| Priorität | `P0` |
| Status | `planned` |
| Akzeptanzkriterien | Modul-ID und Scope festgelegt; öffentliche und interne Objekte klassifiziert; `@ResultTable`-/`@KeepData`-Routing vollständig abgebildet; zulässige Schemaquellen und Vertrauensgrenzen definiert; Fehler-, Transaktions-, Collation- und Datentypverträge dokumentiert; Install-/Upgrade-/Uninstall-Auswirkungen beschrieben; vollständige statische und Runtime-Testmatrix vorbereitet; erstmals benötigte ungeregelte Objekttypen vor Verwendung zur Entscheidung vorgelegt. |
| Tests | Statische Konsistenzprüfung gegen USP-Vertrag, Architekturentscheidungen, Templates, Datenschutz und Plattformmatrix. Runtime-Tests sind in dieser Designwelle `not applicable`. |
| Blocker | Kein aktueller Blocker. Falls eine persistente Tabelle, ein Synonym, eine Assembly oder ein anderer bisher ungeregelter Objekttyp benötigt wird, ist vor Benennung die Benutzerentscheidung einzuholen. |
| Evidenz | Kandidat `TC-2026-003`; bestehender USP-Vertrag und Foundation-Entscheidungen. |
| Nächster Schritt | Objekt- und Datenflussmodell für das ResultTable-Routing entwerfen und daraus die notwendigen Architekturentscheidungen sowie Modulartefakte ableiten. |

## Abgeschlossene Arbeitspakete

### AP-2026-001: Backlog Research Wave 1

| Feld | Wert |
|---|---|
| ID | `AP-2026-001` |
| Ziel | Eine erste belastbare, versionsbezogene Kandidatenwelle für SQL Server 2019, 2022 und 2025 erstellen. |
| Scope | `Backlog/TOOLBELT_CANDIDATES.md`; vorhandene Kandidaten präzisieren und neue Compatibility-, Core-, String-, Datetime-, JSON- und Binary-Kandidaten erfassen. |
| Dependencies | Repository-Grundaufbau und Backlog-Curator-Regeln. |
| Priorität | `P1` |
| Status | `validated` |
| Akzeptanzkriterien | Kandidaten besitzen stabile IDs, Ziel-Repository, Versionsbezug, spätere native Funktion, Nutzen, Technologieoptionen, Performance-/Security-Aspekte, Plattformgrenzen, Duplikatprüfung, Primärquellen, Prüfdatum und nächsten Schritt. |
| Tests | Primärquellenprüfung gegen Microsoft Learn; Duplikatprüfung innerhalb der Toolbelt-Listen; Abgrenzung zu `SQL_Server_Analyze`; Fakten und offene Punkte getrennt formuliert. |
| Blocker | Keine |
| Evidenz | `TC-2026-001` bis `TC-2026-013`, geprüft am 2026-07-29. Keine Runtime- oder Implementierungsvalidierung behauptet. |
| Nächster Schritt | `AP-2026-002` ausführen; weitere Kandidatenwellen erst danach oder parallel durch den Backlog Curator ergänzen. |

## Vorlage

```markdown
### AP-YYYY-NNN: <Titel>

| Feld | Wert |
|---|---|
| ID | AP-YYYY-NNN |
| Ziel | <Messbares Ziel> |
| Scope | <Betroffene Module, Schemas und Objekte> |
| Dependencies | <Arbeitspakete, Module oder externe Voraussetzungen> |
| Priorität | <P0 / P1 / P2 / P3> |
| Status | <proposed / researched / planned / implemented / validated / blocked / rejected> |
| Akzeptanzkriterien | <Überprüfbare Done-Bedingungen> |
| Tests | <Statische, Contract-, Runtime- und Plattformtests> |
| Blocker | <Bekannte Blocker> |
| Evidenz | <Commits, Pull Requests, Befehle, Workflows oder Testergebnisse> |
| Nächster Schritt | <Konkret ausführbare nächste Aktion> |
```

## Wiederaufnahme

Ein Chat allein ist keine dauerhafte Source of Truth. Entscheidungen, Prioritäten, Fortschritt und Blocker müssen in dieser Datei oder in `Documentation/Architecture/DECISIONS.md` nachvollziehbar festgehalten werden.
