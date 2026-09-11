# Geo-Jittering: bedarfsabhängig zurückgestellt (`TC-2026-043`)

## Ergebnis

`TC-2026-043` wird zurückgestellt. Eine räumliche Verschiebung kann bekannte
Orte, wiederholte Beobachtungen, Grenzen und Kombinationen mit anderen
Attributen weiterhin offenlegen. Ohne konkreten räumlichen Zweck und eine
akzeptierte verbleibende Offenlegung ist weder ein Distanzwert noch ein
deterministischer Zufallsvertrag verantwortbar.

Die Funktion darf daher nicht als Anonymisierung oder als allgemeiner Spatial-
Utility vorbereitet werden.

## Wiederaufnahmebedingung

Eine spätere Funktionsbesprechung benötigt mindestens Geometrietyp und SRID,
planare oder geodätische Distanz, Determinismus, zulässige Gebiete und
Clipping, gewünschte Verteilung, Behandlung ungültiger Eingaben sowie eine
fachliche/privacy-seitige Bewertung der verbleibenden Re-Identifikation. Tests
dürfen nur synthetische Koordinaten verwenden.

Erst dann kann ein eng begrenzter, selbstständiger Providervertrag entstehen.
Er bleibt getrennt von räumlicher Analyse, realen Geodaten, Date Shifting und
anderen Pseudonymisierungsslices.
