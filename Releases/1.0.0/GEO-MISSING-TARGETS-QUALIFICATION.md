# Kanonische Geo-SQL-Verträge auf acht zusätzlichen Kombinationen

Stand 2026-10-25, dritte vorab geplante Welle des zweiten endlichen Rahmens.
Die unveränderten GeoJitter-1.2.0-Verträge bestehen auf acht zusätzlich geprüften
Ziel-/CL-Kombinationen jeweils lokal und direkt zentral. Produktquellen,
Modulstatus und Pakete bleiben unverändert; keine Veröffentlichung.

## Umfang und feste Orakel

Der [Testweg](../../Tests/Release/README.md#kanonische-geo-sql-verträge-auf-weiteren-zielen-prüfen)
installiert ausschließlich ResultTable 1.0.0 und Deterministic 1.2.0 in eigenen
markierten Datenbanken. Die Fixture setzt einen kleinen Scopeguard und danach
bytegetreu `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und
`InstalledMetadata.Contract.sql` zusammen: `b"\nGO\n".join(parts) + b"\n"`.
Die [JSON-Projektion](geo-missing-targets-qualification.json) enthält Reihenfolge,
Hash des Gesamtpayloads sowie die konsumierten Quellen-/Treiber-/Exporthashes.
Kein fachliches Orakel wurde kopiert, abgeändert oder partitioniert.

Der ursprüngliche Geo-Vertrag bleibt in fünf unpartitionierten Batches mit
504 Prioritätsfällen je Kontext erhalten; Safety und installierte SQL-Metadaten
werden zusätzlich ausgeführt. Die Metadatenprüfung betrifft SQL-Objekte,
Parameter und den nativen geography-Typ, keine Client-UDT-Serialisierung.

| Plattform | SQL-Version | Compatibility Level |
|---|---|---|
| Linux | 2022 | 150, 160 |
| Linux | 2025 | 150, 160, 170 |
| Windows | 2019 | 150 |
| Windows | 2022 | 150, 160 |

Acht Fälle mit zwei Kontexten ergeben 8.064 bestandene Prioritätsfälle.
Ein absichtlich falscher Festvektor und ein zusätzlich angelegtes Produktobjekt
werden aus den erwarteten Gründen verworfen; beide bleiben `FAILED_CLEANED`.

## Ausführungsprofil und erhaltene Fehlversuche

Der vorhandene kanonische Geo-/Translate-Adapter verwendet ExecuteNonQuery
mit 120 Sekunden je Batch. Der neue begrenzte Geo-Einstieg übernimmt dieses
Profil und begrenzt zusätzlich auf die verbleibende 300-Sekunden-Arbeitsfrist.
Installation, Kontrollabfragen und Cleanup behalten ihre 45-Sekunden-Grenzen;
Cleanup-/äußere Frist bleiben 360/400 Sekunden, Audit separat 90 Sekunden.
Das ist keine Laufzeitzusage für öffentliche Funktionen. Offline-Fakes prüfen
Fristgrenzen, Fehlerweitergabe und Dispose; ein mechanischer Vergleich hält
den übrigen Ablauf identisch zum bestehenden T-SQL-Ownership-/Cleanup-Treiber.

Drei Vorläufer bleiben im gemeinsamen Verbrauch: der erste Zusatzguard wies
vor dem Geo-Orakel ab; der 45-Sekunden-Treiber verwarf einen falschen Festvektor,
sein positiver Vollvertrag erreichte aber das Zeitlimit. Diese Versuche sind
keine positive Qualifikation und wurden an ihren damaligen Bindungen bereinigt
und unabhängig geprüft. Das kanonische Profil erhielt anschließend neue Kontrollen.

Ein Windows-2019-Versuch scheiterte bereits bei der ResultTable-Installation
an einem vorhandenen benannten Temp-Constraint. Nach unabhängiger eigener
Bereinigung und einer reinen Leseprüfung, die dessen Abwesenheit feststellte,
bestand ein frischer eigener Nachfolger. Fremde Objekte oder Sessions wurden
nicht verändert. Der Installationsfehler bleibt als zusätzlicher Versuch erhalten.

Nach dem letzten Verbraucher bestätigten elf frische unabhängige Input-/
Abwesenheitsaudits alle 19 Datenbanknamen der aktuellen Ausführungen als
abwesend; davon gehören 18 zu acht positiven Fällen und zwei Kontrollen.
Die drei Vorläufer behalten ihre ursprünglichen unabhängigen Audits.
Keine Serverkonfigurations-, Rechte- oder Assemblytruständerungen.
Identitäten, Verbindungsdaten und Logs bleiben ausschließlich lokal.

## Historische Nachweise und offene Grenzen

Linux2019 CL150 und Windows2025 exakt CU8 CL150/160/170 wurden nicht wiederholt.
Ihr früherer umfangreicher Geo-Adapter-Nachweis behält seine eigene Bindung
und seinen Lifecycle-/Clientscope; die neue SQL-Matrix erweitert diese
Lifecycle- und Clientabnahme nicht auf weitere Ziele. Die übrige Funktionsfamilie
wird ebenfalls nicht pauschal erneut qualifiziert.

Weitere Clientmetadaten, exakt 129-Byte-UDT, volle Lifecycle-/Upgrade- und
Minimalrechtefälle auf weiteren Zielen, echte Lowpriv-CrossDB-Mappings und
authentifiziertes TLS bleiben separat. Functional verwendet Verschlüsselung
und den ausdrücklichen Trustwert des schema-validierten Labvertrags.
Status bleibt `partially validated`, `unreleased`; die
[Releasegates](RELEASE-GATES.md) gelten weiterhin.
