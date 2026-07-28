# Tests – SQL Server Toolbelt

Dieses Verzeichnis enthält die gemeinsame Test-Infrastruktur und Testdokumentation.

## Aktueller Stand

Der Repository-Grundaufbau ist abgeschlossen. Es sind noch keine fachlichen Module implementiert; deshalb wurden keine Toolbelt-Runtime-Tests ausgeführt.

## Pflicht-Testarten je Modul

| Testtyp | Inhalt |
|---|---|
| statisch | Naming, Header, Datenschutz, Manifest, Links und Vertragskonsistenz |
| API-Contract | Parameter, Defaults, Resultsets, Help, Fehler und Rechte |
| USP-Contract | `@Hilfe`, `@Debug`, `@ResultTable`, `@KeepData`, verschachtelte Aufrufe |
| Install | Erstinstallation und kontrollierte Wiederholung |
| Upgrade | jede unterstützte Vorgängerversion |
| Uninstall | vollständige Entfernung und Dependency-Schutz |
| Collation | unterschiedliche Server-, Datenbank- und TempDB-Collations |
| Deployment | lokal, zentral und Cross-database, soweit unterstützt |
| Plattform | SQL Server 2019, 2022 und 2025; Windows und Linux getrennt |
| Provider | jeder alternative Provider als eigener Nachweis |
| Recovery | Cleanup und Zustand nach Fehlern |

## Testdaten

- ausschließlich deterministische synthetische Daten;
- keine Produktionsdaten, personenbezogenen Daten oder internen Firmendaten;
- keine realen Infrastruktur- oder Runtime-Angaben;
- Rand- und Fehlerwerte ausdrücklich abdecken.

## Evidenz

Jede ausgeführte Prüfung nennt Befehl oder Workflow, Scope, Version, Plattform, Provider, Ergebnis, Datum und Einschränkungen. Nicht ausgeführte Prüfungen bleiben als `not executed` sichtbar.

## CI

CI wird erst mit konkreten Modulen aufgebaut und bleibt pfad- sowie capability-bezogen. Eine Dokumentationsänderung benötigt keine vollständige Runtime-Matrix.

Details: [TEST_AND_VALIDATION_POLICY.md](../Documentation/Standards/TEST_AND_VALIDATION_POLICY.md)
