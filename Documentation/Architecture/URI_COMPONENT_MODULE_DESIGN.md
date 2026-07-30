# Moduldesign URI Component Percent-Encoding

| Feld | Wert |
|---|---|
| Kandidat | `TC-2026-024` |
| Modul | `toolbelt.conversion.uri-component` |
| Vertrag besprochen | 2026-07-30 |
| Implementierung freigegeben | 2026-07-30 |

V1 behandelt ausschließlich URI-Komponenten nach RFC 3986. Encode verwendet Unicode-Eingabe und UTF-8-Octets. Decode ist absichtlich strikter: Der Eingabetext einer URI ist ASCII; unescaped Unicode ist IRI und liegt nicht in diesem Vertrag. Die TVF stellt eine relationale Validierungssicht bereit, die SVF reduziert ungültige Eingaben auf `NULL`.

NUL und nicht kanonisches UTF-8 sind ungültig. Es gibt keine automatische zweite Decoding-Runde. SQL CLR wurde verworfen, weil der T-SQL-Kern portabel ist und kein gemessener Korrektheits- oder Performancevorteil vorliegt.

Quelle: [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986).

Aktuelle Evidenz: [W1 Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml) – `not executed`.
