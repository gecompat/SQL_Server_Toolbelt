# Tests – SQL Server Toolbelt

Dieses Verzeichnis enthält die Test-Infrastruktur und Testdokumentation.

## Aktueller Status

Noch keine Runtime-Tests ausgeführt. Dieses Repository befindet sich in der Initialisierungsphase.

## Test-Anforderungen (geplant)

Für jedes implementierte Modul sind folgende Testtypen erforderlich:

| Testtyp | Beschreibung |
|---|---|
| API-Contract | Parameternamen/-typen, Resultset-Spalten, Help-Resultset |
| Install | Erstinstallation, Idempotenz |
| Upgrade | Von bekannter Vorgängerversion |
| Uninstall | Vollständige Entfernung |
| Collation | Verhalten bei unterschiedlichen Collations |
| Lokal/Zentral | Deployment-Modus-spezifische Tests |
| Plattform | Getrennt für Windows/Linux und SQL Server 2019/2022 |

## Testdaten

- Ausschließlich deterministische synthetische Daten.
- Keine Produktionsdaten, keine personenbezogenen Daten.
- Keine realen Infrastrukturnamen.

## CI-Anforderungen (geplant, nicht implementiert)

- Schlanke, pfadbezogene CI für implementierte Module.
- Keine große Actions-Matrix ohne konkreten Bedarf.
- Details: [TEST_AND_VALIDATION_POLICY.md](../Documentation/Standards/TEST_AND_VALIDATION_POLICY.md)

## Testvorlagen

Testvorlagen für neue Module: `Templates/Module/Tests/`
