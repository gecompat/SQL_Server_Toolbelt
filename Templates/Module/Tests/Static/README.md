# Statische Tests – {{ModuleName}}

Statische Tests prüfen Codequalität, Vertragseinhaltung und Dokumentation ohne SQL-Server-Laufzeit.

## Prüfliste

- [ ] Objekt-Header vorhanden und vollständig
- [ ] Parameternamen und -typen gemäß Vertrag
- [ ] Standardparameter in korrekter Reihenfolge (`@ResultTable`, `@KeepData`, `@Debug`, `@Hilfe`)
- [ ] Keine nicht erlaubten Temp-Tabellennamen (`#Temp`, `#Result`, usw.)
- [ ] Kein personenbezogenes Datum, keine Secrets
- [ ] Collation-Vertrag dokumentiert
- [ ] Namenskonventionen eingehalten

## Status

`not executed`
