# URI Component Percent-Encoding

Aktuelle [Callerrechte-Qualifikation](../../Releases/1.0.0/CONVERSION-CALLER-QUALIFICATION.md): einzelne SELECT-Grants für TVFs und EXECUTE-Grants für Scalarwrapper, lokal/direkt zentral auf zwölf Ziel-/CL-Kombinationen. Das [korrigierte Manifest samt Paketbindung](../../Releases/1.0.0/CALLER-METADATA-UPDATE.md) nennt die Rechte je Funktion. Frühere Scalarheader sind historische Kommentare; maßgeblich sind diese Einzelrechte. Andere Fach-/Lifecycle-/CrossDB-Gates und Modulstatus werden dadurch nicht erweitert.

Nachqualifikation 2026-10-19: Der vollständige aktuelle Moduladapter bestand auf SQL Server 2019/2022/2025 unter Windows und Linux. Runtime: `validated`; Release: `unreleased`. Die folgenden datierten älteren Abschnitte beschreiben ihren damaligen Stand. Details: [V0c-Gatebericht](../../Tests/V0C_RELEASE_GATE_STATUS.md).

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Das Modul implementiert `TC-2026-024` als RFC-3986-URI-Komponentenvertrag. Es verwendet UTF-8-Octets, Großbuchstaben in `%HH`, `%20` für Leerzeichen und niemals `+`.

```sql
SELECT encoded.EncodedValue
FROM toolbelt_conversion.TVF_UriComponentEncode(N'Kaffee & Tee') AS encoded;
-- Kaffee%20%26%20Tee
```

`Decode` decodiert exakt einmal. Es akzeptiert nur ASCII-URI-Komponententext, prüft Prozent-Triplets und UTF-8 und liefert in der TVF `IsValid` sowie `ValidationCode`; die Scalar-API gibt bei ungültiger Eingabe `NULL` zurück. `application/x-www-form-urlencoded`, vollständige URLs, IRI und Punycode liegen außerhalb des Scopes.

Details: [Encode](./Documentation/TVF_UriComponentEncode.md), [Decode](./Documentation/TVF_UriComponentDecode.md), [Moduldesign](../../Documentation/Architecture/URI_COMPONENT_MODULE_DESIGN.md).

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) sowie der lokale Lauf vom 2026-08-29 – vollständiger Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Modulstatus nach Nachqualifikation 2026-10-19: `validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019/2022/2025 unter Windows mit freigegebenen CU-Äquivalenten zu base und Linux latest; vollständiger lokaler/zentraler Moduladapter, versionsabhängige CL150/160/170, Lifecycle und Uninstall; Security-Grenzen, Unicode/UTF-8, Minimalrechte und zentrale Status-APIs
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

SC-021: Neue EncodeStatus-/DecodeStatus-TVFs prüfen64 KiB UTF-16-Input vor Series und Aggregation. Die mathematische maximale Ergebnisgröße unter dieser Inputgrenze liegt bereits unter1 MiB; zusätzlicher Ergebnischeck. Alte Wertfassaden liefern bei Limit NULL; DecodeStatus nennt LIMIT (IsValid=0/ValidationCode14).

Details und abgegrenzte Nachweise: [Security-Härtung](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).

Aktueller Securitystand nach der Nachqualifikation vom 2026-10-19: `validated`,
`unreleased`. Die neuen Verträge, die vollständige Fachmatrix, lokale
Minimalrechte und zentrale Statusaufrufe sind auf allen sechs Zielen geprüft.
