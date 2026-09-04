# URI Component Percent-Encoding

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Das Modul implementiert `TC-2026-024` als RFC-3986-URI-Komponentenvertrag. Es verwendet UTF-8-Octets, Großbuchstaben in `%HH`, `%20` für Leerzeichen und niemals `+`.

```sql
SELECT encoded.EncodedValue
FROM toolbelt_conversion.TVF_UriComponentEncode(N'Kaffee & Tee') AS encoded;
-- Kaffee%20%26%20Tee
```

`Decode` decodiert exakt einmal. Es akzeptiert nur ASCII-URI-Komponententext, prüft Prozent-Triplets und UTF-8 und liefert in der TVF `IsValid` sowie `ValidationCode`; die Scalar-API gibt bei ungültiger Eingabe `NULL` zurück. `application/x-www-form-urlencoded`, vollständige URLs, IRI und Punycode liegen außerhalb des Scopes.

Details: [Encode](./Documentation/TVF_UriComponentEncode.md), [Decode](./Documentation/TVF_UriComponentDecode.md), [Moduldesign](../../Documentation/Architecture/URI_COMPONENT_MODULE_DESIGN.md).

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) sowie der lokale Lauf vom 2026-08-29 – vollständiger Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Modulstatus `partially validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; RFC-3986-ASCII-Raum, Unicode/UTF-8, ungültige Prozentsequenzen, synthetischer Large-Input-Roundtrip, Kollisionsschutz, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
