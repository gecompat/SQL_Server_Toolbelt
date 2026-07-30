# URI Component Percent-Encoding

Das Modul implementiert `TC-2026-024` als RFC-3986-URI-Komponentenvertrag. Es verwendet UTF-8-Octets, Großbuchstaben in `%HH`, `%20` für Leerzeichen und niemals `+`.

```sql
SELECT encoded.EncodedValue
FROM toolbelt_conversion.TVF_UriComponentEncode(N'Kaffee & Tee') AS encoded;
-- Kaffee%20%26%20Tee
```

`Decode` decodiert exakt einmal. Es akzeptiert nur ASCII-URI-Komponententext, prüft Prozent-Triplets und UTF-8 und liefert in der TVF `IsValid` sowie `ValidationCode`; die Scalar-API gibt bei ungültiger Eingabe `NULL` zurück. `application/x-www-form-urlencoded`, vollständige URLs, IRI und Punycode liegen außerhalb des Scopes.

Details: [Encode](./Documentation/TVF_UriComponentEncode.md), [Decode](./Documentation/TVF_UriComponentDecode.md), [Moduldesign](../../Documentation/Architecture/URI_COMPONENT_MODULE_DESIGN.md).

Aktuelle Evidenz: [W1 Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml) – `not executed`.
