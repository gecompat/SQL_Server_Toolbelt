# Tests – SQL Server Toolbelt

Dieses Verzeichnis enthält die gemeinsame Test-Infrastruktur und Testdokumentation.

## Aktueller Stand

Der Repository-Grundaufbau ist abgeschlossen. Für das implementierte erste Kernmodul existieren statische sowie synthetische Runtime- und Lifecycle-Contract-Testartefakte. Die SQL-Server-Runtime-Tests wurden mangels Runner noch nicht ausgeführt.

Die erste pfadbezogene Runtime-Action verwendet GitHub-hosted Linux für SQL Server 2019, 2022 und 2025. Ihr Vorhandensein ist noch kein Ausführungsnachweis; der Status wird erst nach einem tatsächlich grünen Workflow aktualisiert.

## Pflicht-Testarten je Modul

| Testtyp | Inhalt |
|---|---|
| statisch | Naming, Header, Datenschutz, Manifest, Links und Vertragskonsistenz |
| API-Contract | Parameter, Defaults, Resultsets, Help, Fehler und Rechte |
| USP-Contract | `@Hilfe`, `@Debug`, `@ResultTable`, `@KeepData`, verschachtelte Aufrufe |
| Deploy | Erstinstallation, kontrollierte Wiederholung und jede unterstützte Vorgängerversion |
| Uninstall | vollständige Entfernung und Dependency-Schutz |
| Collation | unterschiedliche Server-, Datenbank- und TempDB-Collations |
| Deployment | lokal, zentral und Cross-database, soweit unterstützt |
| Plattform | SQL Server 2019, 2022 und 2025; Windows und Linux getrennt |
| Provider | jeder alternative Provider als eigener Nachweis |
| Recovery | Cleanup und Zustand nach Fehlern |

## Modulspezifische Testmatrizen

| Modul | Matrix | Status |
|---|---|---|
| `toolbelt.core.result-table` | [RESULT_TABLE_CONTRACT_TEST_MATRIX.md](./RESULT_TABLE_CONTRACT_TEST_MATRIX.md) | Testartefakte implementiert; Runtime `not executed` |

Eine Testmatrix ist noch kein Nachweis einer erfolgreichen Ausführung.

## Testdaten

- ausschließlich deterministische synthetische Daten;
- keine Produktionsdaten, personenbezogenen Daten oder internen Firmendaten;
- keine realen Infrastruktur- oder Runtime-Angaben;
- Rand- und Fehlerwerte ausdrücklich abdecken.

## Evidenz

Jede ausgeführte Prüfung nennt Befehl oder Workflow, Scope, Version, Plattform, Provider, Ergebnis, Datum und Einschränkungen. Nicht ausgeführte Prüfungen bleiben als `not executed` sichtbar.

## CI

Die erste capability-bezogene CI-/Runner-Anbindung ist noch offen. Eine Dokumentationsänderung benötigt keine vollständige Runtime-Matrix.

Details: [TEST_AND_VALIDATION_POLICY.md](../Documentation/Standards/TEST_AND_VALIDATION_POLICY.md)
