# Datenschutz und Vertraulichkeit

## Stop-Gate

**Vor jeder Dateiänderung, jedem Commit und jedem PR ist diese Prüfung durchzuführen.**

Im Zweifel: **vor dem Schreiben stoppen und Benutzer fragen.**

## Verbotene Inhalte

In Repository, Dokumentation, Code, Beispielen, Tests, Commits, PRs und Issues sind verboten:

### Personenbezogene Daten
- Namen realer Personen (außer im Copyright- und Attributionsblock: `gecompat - Gerhard Pisch`)
- E-Mail-Adressen, Telefonnummern, Adressen
- Benutzernamen aus Produktivumgebungen
- Daten aus DSGVO-Art.-9-Kategorien (Gesundheit, Religion, Ethnizität, politische Überzeugungen, biometrische Daten, Gewerkschaftszugehörigkeit, sexuelle Orientierung)

### Infrastrukturdaten
- Reale Server-, Instanz- und Datenbanknamen
- Reale Domainnamen, Hostnamen
- Interne URLs, API-Endpunkte, Netzwerkpfade
- IP-Adressen (außer `localhost` / `127.0.0.1`)

### Produktionsdaten
- Datenbankbackups oder -exporte
- Tabelleninhalt aus Produktivumgebungen
- Reale Query Plans, Execution Logs, Traces

### Secrets
- Passwörter
- API-Keys, Tokens
- OAuth-Tokens, Session-Cookies
- Connection Strings mit Credentials
- Private Schlüssel, PFX/P12/PVK/SNK-Dateien

## Erlaubte Inhalte

- Synthetische Daten (fictional, klar als Beispiel erkennbar)
- `localhost`, `127.0.0.1`
- Öffentlich bekannte Beispieldatenbanken: Contoso, Fabrikam, AdventureWorks, WideWorldImporters
- Ausdrücklich freigegebene Demo-Daten
- `gecompat - Gerhard Pisch` ausschließlich für Copyright, Attribution, Lizenz

## Debug-Ausgaben

Runtime-Debug darf diagnostisch notwendige technische Werte enthalten:
- Datenbankname, Schemaname, Objektname (Systemkontext)
- Parameterwerte
- Metadaten
- Generiertes SQL
- Fehlerdetails

Runtime-Debug darf **niemals** enthalten:
- Passwörter, Tokens, API-Keys
- Private Schlüssel
- Session-/OAuth-Tokens
- Connection Strings mit Credentials
- Zugriffscookies

**Reale Debug-Ausgaben dürfen nicht als Repository-, Help-, Beispiel-, Test-, Issue- oder PR-Inhalt übernommen werden.**

## Signing-Artefakte

Private Signing Keys (`*.pfx`, `*.p12`, `*.pvk`, `*.snk`) dürfen nicht ins Repository. Details: [CLR_SECURITY_AND_PORTABILITY.md](../Architecture/CLR_SECURITY_AND_PORTABILITY.md)
