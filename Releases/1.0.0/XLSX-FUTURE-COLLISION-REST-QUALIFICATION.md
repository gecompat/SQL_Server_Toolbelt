# XLSX: Zukunftsslots auf genuine 1.1 und aktueller 1.2-Lifecycle

Ausführung am 2026-11-17 (UTC): `PASS_FOR_DECLARED_SCOPE`. Vier unveränderte
vorhandene Kollisionsfixtures bestehen auf zwölf Windows-/Linux-Engine-/CL-
Paaren jeweils lokal und direkt zentral. [Exakte Originalbindungen und
Resultate](XLSX-FUTURE-COLLISION-REST-QUALIFICATION.json).

| Plattform / Patchselektor | SQL 2019 | SQL 2022 | SQL 2025 | Modi |
|---|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |

## Vorgänger und vier konkrete Fremdslots

Die bereits [qualifizierten genuine1.1-Artefakte](XLSX-GENUINE11-REST-QUALIFICATION.md)
und zwei unabhängigen bytegleichen Originalbuilds werden wiederverwendet.
Originalquellen, Provenance und DLLs werden erneut gegen ihre bisherigen Pins
geprüft und bytegleich in den eigenen privaten Laufbereich übernommen. Kein
Neubuild und kein nachträglich gefälschter Versionsmarker. Die reine vorhandene
Katalogprüfung wurde unverändert als wiederverwendbarer Helper herausgezogen.

| Vorhandene Fixture | Synthetischer Slot auf dem echten 1.1-Vorgänger |
|---|---|
| FuturePublic | fremde `TVF_FormatXlsxCell` ohne Modulmarker |
| ImitatedFuturePublic | gleiche fremde öffentliche Funktion mit imitierten Markern |
| FutureInternal | fremde `TVF_InternalFormatXlsxCell` ohne Modulmarker |
| ImitatedFutureInternal | gleiche fremde interne Funktion mit imitierten Markern |

Der originale Vierfall-Helper und `Display.CollisionFixture.sql` bleiben
unverändert. Ein aktueller Deployversuch muss jeweils51534 zurückweisen und
den vollständigen Vorgängersnapshot erhalten. Der heutige release-aware
Uninstaller muss anschließend die fremde Funktion einschließlich ID, Definition
und Properties exakt erhalten; die alte eigene Assembly muss verschwinden.
Danach wird ausschließlich die synthetische Funktion entfernt und der echte
1.1-Installer stellt die Basis wieder her. Jede frische Verbindung bestätigt
exakten alten DLL-Hash, SAFE, Version1.1, Modus, sieben Slots und drei Bindings.

24 Routen bestehen somit96 Deploy-Ablehnungen und96 Fremderhaltprüfungen.
Die initiale und vier wiederhergestellte Baselines ergeben120 native
Katalogzeugen. Nach den vier Kollisionen wird der öffentliche aktuelle
Paketinstaller erneut erfolgreich angewendet: 24 konkrete Recovery-Upgrades
nach dieser Fehler-/Restorehistorie, Repeat, beide aktuellen SAFE-Binaryhashes,
Modulversionen/CL und die vollständige originale Display-Lifecyclefixture mit
neun Slots/Release-Markern und exaktem internem Display-Binding. Danach folgen
aktueller Uninstall/Absent und eigene Bereinigung. Diese Recoveryfolge wird
nicht als erneute isolierte Clean-Upgradequalifikation gezählt.

## Eigener Fehler und unveränderte gemeinsame Grenzen

Der erste Lauf endete in PREPARE mit `RELEASE_PRIVATE_PATH_REQUIRED`, ohne
eigene Datenbank oder bestandenen Modus. Die gültigen archivierten Artefakte
lagen außerhalb des eigenen Worktree-Laufbereichs. Dieser Schutz wurde nicht
abgeschaltet. Der Lauf bleibt `FAILED_CLEANED`; sein reservierter unabhängiger
Audit ist PASS. Die Korrektur kopiert ausschließlich die bereits verifizierten
Original-/Reprobytes in den eigenen Laufbereich und verwendet einen neuen
Runset. Keine grüne Route wurde wiederholt.

Der vorab gemeinsame Rahmen von28 Lauf-/Auditaufrufen,28 DB-Reservierungen,
60 Minuten ab dem ursprünglichen ersten Start und höchstens zwei geänderten
Adapterfällen bei Befund/Cleanup blieb erhalten. Verbraucht sind26 Aufrufe/
Reservierungen und ein geänderter Adapterfall: ein Fehlversuch samt Audit und
zwölf vollständige korrigierte Fälle samt zwölf frischen Audits. Alle24
angelegten Datenbanken sind entfernt. Alle13 Audits binden ihre exakten finalen
Journale; eigener Trust und Konfiguration sind im Vorzustand, fremde Zustände
erhalten. Die Welle ist geschlossen; freie Plätze eröffnen keinen weiteren Lauf.

Die SQL-freie Vorbereitung fand und korrigierte zusätzlich eine fehlende
Helperübernahme zwischen Skriptscopes sowie die anfängliche Ablehnung des
neuen Profils im allgemeinen Scope-Enum. Keine nativen Dispatches daraus.
Gegenproben prüfen echte Pins, sechs falsche Vorgängerzustände, den originalen
Vierfallablauf mit Testdoubles, acht Fremdsnapshotreads, vier Wiederherstellungen,
Fremdslotverlust, fremde DB-Ablehnung und den tatsächlichen Scopeguard sowie
drei echte Modus-/Fixtureselektionen. Testdoubles gelten nicht als SQL-Nachweis.
Die tatsächliche Methodenversion `8bf8bd68ef6d04c822b49e20548db744aa3c5864` und alle
öffentlichen Runtimeeingaben bleiben bytegenau an ihre Original-Git-Bytes gebunden.

Andere Slotkollisionen, reale andere Owner/Minimalrechte/CrossDB-Identitäten,
ursprüngliche Vorgänger-Uninstaller oder API-/Workbookdomänen, Heap/Kapazität,
authentifiziertes TLS und der vollständige Modulumfang werden nicht zusätzlich
qualifiziert. Keine neue Produktfunktion, Rechte, Identitäten, OS-/Labänderung,
Veröffentlichung oder Tags. Modul weiterhin teilweise validiert/unveröffentlicht.
Private Journale, Quellenkopien, Toolpins und Rohkanäle bleiben privat.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_future_collision_rest.py
```
