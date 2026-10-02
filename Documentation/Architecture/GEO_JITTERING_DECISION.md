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

## Wiederaufnahme 2026-10-02 – Codex

Der historische Zurückstellungsgrund bleibt erhalten. Die funktionsbezogene
Besprechung und Benutzerfreigabe vom 2026-10-01 in
[.ai/BACKLOG.md](../../.ai/BACKLOG.md) bestätigen inzwischen den eng begrenzten
Zweck: synthetische Points/SRID 4326, deterministische Entitätsparameter,
100 m Default/10 km Ceiling, flächenorientierte Verteilung und kein Clipping.
Die verbleibende Verknüpfbarkeit ist akzeptiert; keine Anonymisierungszusage.

Der [GeoJitter-Vertrag vor Source](DETERMINISTIC_GEO_JITTER_CONTRACT.md)
konkretisiert diese Wiederaufnahme additiv im vorhandenen deterministischen
Modul und begrenzt Points technisch auf 2D ohne Z/M. Er ersetzt für diesen
ausgewählten Scope die frühere Zurückstellung,
ohne deren Text umzuschreiben. Die Vor-Source-Qualifikation des akzeptierten
Punktbereichs ist abgeschlossen; unabhängiger Vertragsfreeze und sämtliche
integrierten API-/Lifecycle-/Client-/Rechte-/CI-Gates waren im damaligen
Vor-Source-Stand offen.
Reale Geodaten, räumliche Analyse und zusätzliche Spatial-APIs bleiben
außerhalb der Freigabe; keine neue Entscheidungs-ID wird hier vergeben.


### Additiver Umsetzungsnachweis vom 2026-10-02

Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`.
