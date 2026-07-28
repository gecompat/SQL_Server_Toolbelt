# Test- und Validierungsrichtlinie

## Grundsatz

Plan, Dokumentation, Manifest und Testcode sind **kein Runtime-Nachweis**. Nur tatsächlich ausgeführte erfolgreiche Prüfungen sind als `validated` zu kennzeichnen.

Nicht ausgeführte Tests sind explizit als `not executed` zu kennzeichnen.

## Statuswerte für Tests

| Status | Bedeutung |
|---|---|
| `validated` | Tatsächlich ausgeführt, erfolgreich abgeschlossen |
| `not executed` | Geplant, aber noch nicht ausgeführt |
| `not applicable` | Nicht anwendbar für diese Konfiguration |
| `failed` | Ausgeführt, fehlgeschlagen; Blocker dokumentiert |

## Pflichtprüfungen je Modul

Für jedes implementierte Modul sind folgende Tests durchzuführen:

### API-Contract-Tests
- Parameternamen und -typen gemäß Vertrag
- Resultset-Spalten und -typen gemäß Vertrag
- `@Hilfe = 1`-Verhalten
- `@Debug`-Verhalten

### Lifecycle-Tests
- Install: Erstinstallation auf sauberem Zustand
- Install: Idempotenz (Wiederholung ohne Fehler)
- Upgrade: Von bekannter Vorgängerversion
- Uninstall: Vollständige Entfernung

### Plattformtests (separat)
- SQL Server 2019 Windows
- SQL Server 2022 Windows
- SQL Server 2019 Linux
- SQL Server 2022 Linux

### Deployment-Tests (separat)
- Lokale Installation (Zieldatenbank)
- Zentrale Installation (Toolbelt-Datenbank)
- Cross-database-Aufruf (wenn unterstützt)

### Collation-Tests
- Verhalten bei unterschiedlichen Collations
- Collation-Vertrag des Moduls validiert

### Datentests
- Deterministische synthetische Daten
- Keine Produktionsdaten
- Randwerte und Fehlerwerte testen

## Performance-Messungen

- Ehrliche Messungen; keine spekulativen oder erfundenen Werte.
- Messumgebung dokumentieren (SQL-Server-Version, Hardware-Klasse, Datenmenge).
- Messungen sind als empirisch oder als Planung zu kennzeichnen.

## CI-Anforderungen (geplant)

- Schlanke, pfadbezogene CI für implementierte Module.
- Keine große Actions-Matrix ohne konkreten Bedarf.
- Noch keine Runtime-CI in diesem PR.

## Aktuelle Teststatus

Dieser Initial-PR enthält keine implementierten Module. Alle Module haben Status `not executed` oder `not applicable`.
