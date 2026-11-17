# XLSX: Typ-Zukunftsslots auf genuine 1.0 und aktueller 1.2-Lifecycle

Ausführung am 2026-11-17 (UTC): `PASS_FOR_DECLARED_SCOPE`. Vier unveränderte
vorhandene Typ-Kollisionsfixtures bestehen auf zwölf Windows-/Linux-Engine-/CL-
Paaren jeweils lokal und direkt zentral. [Exakte Originalbindungen und
Resultate](XLSX-TYPE-FUTURE-REST-QUALIFICATION.json).

| Plattform / Patchselektor | SQL 2019 | SQL 2022 | SQL 2025 | Modi |
|---|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |

## Vorgänger und vier konkrete Fremdslots

Die bereits [qualifizierten genuine1.0-Artefakte](XLSX-GENUINE10-REST-QUALIFICATION.md)
und zwei unabhängigen bytegleichen Originalbuilds werden wiederverwendet.
Originalquellen, Provenance und DLLs werden erneut gegen ihre bisherigen Pins
geprüft und bytegleich in den eigenen privaten Laufbereich übernommen. Kein
Neubuild und kein nachträglich gefälschter Versionsmarker. Die reine vorhandene
Katalogprüfung wurde unverändert als wiederverwendbarer Helper herausgezogen.

| Vorhandene Fixture | Synthetischer Slot auf dem echten 1.0-Vorgänger |
|---|---|
| FuturePublic | fremde `TVF_InterpretXlsxCell` ohne Modulmarker |
| ImitatedFuturePublic | gleiche fremde öffentliche Funktion mit imitierten Markern |
| FutureInternal | fremde `TVF_InternalInterpretXlsxCell` ohne Modulmarker |
| ImitatedFutureInternal | gleiche fremde interne Funktion mit imitierten Markern |

Der originale Vierfall-Helper und `Types.CollisionFixture.sql` bleiben
unverändert. Ein aktueller Deployversuch muss jeweils51534 zurückweisen und
den vollständigen Vorgängersnapshot erhalten. Der heutige release-aware
Uninstaller muss anschließend die fremde Funktion einschließlich ID, Definition
und Properties exakt erhalten; die alte eigene Assembly muss verschwinden.
Danach wird ausschließlich die synthetische Funktion entfernt und der echte
1.0-Installer stellt die Basis wieder her. Jede frische Verbindung bestätigt
exakten alten DLL-Hash, SAFE, Version1.0, Modus, fünf Slots und zwei Bindings.

24 Routen bestehen somit96 Deploy-Ablehnungen und96 Fremderhaltprüfungen.
Die initiale und vier wiederhergestellte Baselines ergeben120 native
Katalogzeugen. Nach den vier Kollisionen wird der öffentliche aktuelle
Paketinstaller erneut erfolgreich angewendet: 24 konkrete Recovery-Upgrades
nach dieser Fehler-/Restorehistorie, Repeat, beide aktuellen SAFE-Binaryhashes,
Modulversionen/CL und die vollständige originale Display-Lifecyclefixture mit
neun Slots/Release-Markern und exaktem internem Display-Binding. Danach folgen
aktueller Uninstall/Absent und eigene Bereinigung. Diese Recoveryfolge wird
nicht als erneute isolierte Clean-Upgradequalifikation gezählt.

## Unveränderte gemeinsame Grenzen und Quellen

Der vorab gemeinsame Rahmen von 28 Lauf-/Auditaufrufen, 28 DB-Reservierungen,
60 Minuten ab erstem nativem Start und höchstens zwei gezielt geänderten
Adapterfällen blieb erhalten. Zwölf COMPLETE-Fälle und zwölf getrennte frische
PASS-Audits verbrauchen 24 Aufrufe/Reservierungen. Keine nativen Fehlfälle,
Adapterkorrekturen oder grüne Wiederholung. Alle 24 eigenen Datenbanken sind
entfernt. Jeder Audit bindet exakt sein finales Journal und bestätigt eigenen
Trust/Konfiguration im Vorzustand; fremde Zustände bleiben erhalten.
Die Welle ist geschlossen; freie Plätze eröffnen keine weitere Wiederholung.

Original- und Reproartefakte liegen nach bytegleicher, gegen den erhaltenen
Archivindex geprüfter Übernahme vor dem nativen Start im eigenen Laufbereich.
Kein Neubuild oder Abschalten des privaten Pfadguards. Die ursprüngliche reine
1.0-Katalogprüfung wurde unverändert als wiederverwendbarer Helper extrahiert.
Die tatsächliche Methodenversion `1c7febe562e6d5a763870f25f2b8a01b75847aae` und sämtliche
öffentlichen Runtimeeingaben stimmen exakt mit ihren Original-Git-Bytes überein.

SQL-freie Gegenproben prüfen drei unzulässige Eingangsfälle, sechs falsche
Vorgänger-Katalogzustände, den originalen Vierfallablauf mit acht Fremdreads und
vier Wiederherstellungen gegen Testdoubles, Fremdslotverlust/fremde Datenbank,
den tatsächlichen allgemeinen Scopeguard und drei echte Modus-/Fixtureselektionen.
Die bestehenden Reader-/Sitzungs-/Dispose-/Deadline-/Cancel-Orakel bleiben
bestanden. Testdoubles werden nicht als native SQL-Ausführung ausgegeben.

Andere Slotkollisionen, reale andere Owner/Minimalrechte/CrossDB-Identitäten,
ursprüngliche Vorgänger-Uninstaller oder API-/Workbookdomänen, Heap/Kapazität,
authentifiziertes TLS und der vollständige Modulumfang werden nicht zusätzlich
qualifiziert. Keine neue Produktfunktion, Rechte, Identitäten, OS-/Labänderung,
Veröffentlichung oder Tags. Modul weiterhin teilweise validiert/unveröffentlicht.
Private Journale, Quellenkopien, Toolpins und Rohkanäle bleiben privat.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_type_future_rest.py
```
