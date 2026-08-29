# URI Component Percent-Encoding

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Das Modul implementiert `TC-2026-024` als RFC-3986-URI-Komponentenvertrag. Es verwendet UTF-8-Octets, Großbuchstaben in `%HH`, `%20` für Leerzeichen und niemals `+`.

```sql
SELECT encoded.EncodedValue
FROM toolbelt_conversion.TVF_UriComponentEncode(N'Kaffee & Tee') AS encoded;
-- Kaffee%20%26%20Tee
```

`Decode` decodiert exakt einmal. Es akzeptiert nur ASCII-URI-Komponententext, prüft Prozent-Triplets und UTF-8 und liefert in der TVF `IsValid` sowie `ValidationCode`; die Scalar-API gibt bei ungültiger Eingabe `NULL` zurück. `application/x-www-form-urlencoded`, vollständige URLs, IRI und Punycode liegen außerhalb des Scopes.

Details: [Encode](./Documentation/TVF_UriComponentEncode.md), [Decode](./Documentation/TVF_UriComponentDecode.md), [Moduldesign](../../Documentation/Architecture/URI_COMPONENT_MODULE_DESIGN.md).

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) sowie der lokale Lauf vom 2026-08-29 – vollständiger Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Modulstatus `partially validated`.
