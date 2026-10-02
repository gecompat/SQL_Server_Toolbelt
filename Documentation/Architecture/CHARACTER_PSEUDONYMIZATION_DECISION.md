# Zeichentranslation: bedarfsabhängig zurückgestellt (`TC-2026-041`)

## Begrenzte Wiederaufnahme am 2026-10-02

Die Einzel-Freigabe vom 2026-10-01 in `.ai/BACKLOG.md` erfüllt die
Wiederaufnahmebedingungen für synthetische ASCII-Kennungen. Dieser enge
Vorwärtsslice wird durch den
[DeterministicTranslate-Vertrag](DETERMINISTIC_TRANSLATE_CONTRACT.md)
konkretisiert. Die folgende ursprüngliche Zurückstellung bleibt als
Historie erhalten; allgemeine Textmaskierung, weitere Alphabete und Decode
bleiben außerhalb der Freigabe. Die Risiken bleiben unverändert gültig.

## Ergebnis

`TC-2026-041` wird zurückgestellt. Eine zeichenweise deterministische
Transformation erhält Länge, Zeichensätze, häufige Muster und oft Teile des
Formats. Bei begrenzten Alphabeten kann sie zudem leicht rückführbar sein.
Ohne einen konkreten Formaterhaltungsbedarf ist sie gegenüber einem
versionierten synthetischen Lookup kein sinnvoller Standard.

Ein Salt ist kein Secret und kann die fehlende Widerstandsfähigkeit einer
kleinen, reversiblen Substitution nicht ersetzen. Die Funktion darf daher
nicht als Anonymisierung oder als allgemeine Textmaskierung vorbereitet
werden.

## Wiederaufnahmebedingung

Vor einer Funktionsbesprechung müssen folgende Entscheidungen vorliegen:

| Entscheidung | Mindestinhalt |
|---|---|
| Zweck | Konkreter, erlaubter Formaterhaltungsbedarf und Datenklasse. |
| Reversibilität | Explizit erlaubte oder verbotene Umkehrbarkeit sowie Mapping-/Key-Verwaltung. |
| Alphabet | Zulässige Zeichen, Unicode-Normalisierung, Case-/Accent-Semantik und Verhalten unbekannter Zeichen. |
| Format | Welche Teile erhalten bleiben dürfen und welche Muster nicht erhalten bleiben sollen. |
| Risiko | Akzeptierte verbleibende Verknüpfbarkeit und erforderliche fachliche/privacy-seitige Bewertung. |

Erst danach kann ein enger, alphabet- und formatgebundener Vertrag geprüft
werden. Er bleibt getrennt vom Range-, Lookup- und Date-Shifting-Slice.
