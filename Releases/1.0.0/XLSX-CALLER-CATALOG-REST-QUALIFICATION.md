# XLSX: Callertransaktionen und Katalog-/Clientnullability

Ausführung am 2026-11-17 (UTC): `PASS_FOR_DECLARED_SCOPE`. Das aktuelle
fokussierte XLSX-Paket besteht die hier benannten Prüfungen auf zwölf
Windows-/Linux-Engine-/CL-Paaren lokal und direkt zentral. Der
[maschinenlesbare Bericht](XLSX-CALLER-CATALOG-REST-QUALIFICATION.json) bindet
Paket, unveränderte Originalorakel und tatsächlich ausgeführte Methode.

| Plattform / Patchselektor | SQL 2019 | SQL 2022 | SQL 2025 | Modi |
|---|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |

## Geprüfter Vertrag

Nach öffentlicher Erst-/Repeatinstallation bestätigt die unveränderte
`Display.Lifecycle.sql` die neun Slots, Release-Marker und das genaue interne
Display-Binding. Danach werden nur die vorhandenen Definitionen
`Assert-XlsxCallerPrepared` und `Assert-XlsxNativeNullablePrepared` aus dem
historischen Testadapter importiert. Dessen Top-level-Lab-/Legacy-Lauf wird
nicht gestartet. Die aktuelle begrenzte Paket-/Ownershipschicht stellt die
Verbindung und die gemeinsame monotone Restfrist bereit.

Je Route werden Deploy und Uninstall unter XACT_ABORT OFF/ON in einer
intakten sowie einer tatsächlich durch CHECK-Fehler 547 uncommittable gemachten
Callertransaktion abgewiesen: acht Ablehnungen, insgesamt 192. Erwartet werden
Fehler 50000/State1 mit dem festen Callertransaction-Präfix, unveränderter
Transaktionscount und -zustand, Optionen, synthetische Callerarbeit und
vollständiger Katalog-/Assemblysnapshot. Intakte Aufrufe verwenden den direkten
Clientbatch; doomed Aufrufe die originale Inline-Witness-Topologie mit
unverändert eingebettetem Erstbatch. RETURN ohne erwarteten CATCH/Witness kann
nicht bestehen. Dies ist kein SQLCMD-Prozessnachweis.

Die 24 Nullabilityprüfungen vergleichen die tatsächlich deklarierten
14 öffentlichen Katalogspalten mit dem echten SqlDataReader-Schema einschließlich
Ordinalen, Namen und AllowDBNull. Zusätzlich werden die 14 internen Spalten,
genau eine erwartete NULL-Eingabezeile und das Ende aller Resultsets geprüft.
Es wird keine abweichende semantische IF-Nullability erfunden. Der Client läuft
auf dem vorhandenen Windows-Exporthost; Linux bezeichnet den SQL-Zielhost.

Nach jedem Callerprofil bleibt keine offene Transaktion. Der zusätzliche
Definitionsvergleich erhält alle Paketobjekte und Dependencies. Anschließend
bestehen öffentliche Uninstall-/UninstallAbsent-Aufrufe und eigenes Cleanup.

## Abschluss, Wiederverwendung und Grenzen

Zwölf native Fälle und zwölf getrennte frische Abschlussaudits bestanden.
Alle 24 eigenen Datenbanken sind entfernt. Jeder Audit bindet das exakte finale
Journal und prüft eigene Trustreste sowie Konfigurationswiederherstellung;
vorgefundene fremde Zustände bleiben erhalten. Verbraucht wurden 24 von maximal
28 Lauf-/Auditaufrufen und DB-Reservierungen innerhalb des ursprünglichen
60-Minutenfensters. Keine nativen Fehler oder geänderten Adapterfälle; die
Welle ist geschlossen und freie Plätze eröffnen keine Wiederholung.

Aktuelle qualifizierte DLLs, Paket und vorhandene Entwicklungs-/Trustfreigabe
werden wiederverwendet; keine neue Produktfunktion, Rechte-, Identitäts-,
Lab-, Zertifikats- oder Truststoreänderung. Frühere Größen-, Upgrade-, Caller-
Rechte- und Fehlernachweise behalten ihre eigenen Originalgrenzen.

Die SQL-freie Admission prüft fehlende Pins und falschen Scope/Fixture. Die
originale Doomed-Topologie wird mit Witness-Gegenproben, der originale
Nullabilityhelper mit echtem synthetischem DataTableReader einschließlich
Fehlkatalog und Dispose geprüft. Restfristablauf muss Cancel auslösen;
Kindfehler dürfen den neuen Journalstatus nicht zu PASS aufwerten. Die echte
Modus-/Fixtureselektion wird für erste, mittlere und letzte Route geprüft.
Diese Offlineprüfungen sind keine zusätzlichen nativen SQL-Aufrufe.

Weitere Owner-/Minimalrechte-/CrossDB-Identitäten, andere Clients, Kollisions-,
OS-/VM-Ausfall-, Heap-/Kapazitäts- und TLSprofile sowie der vollständige
Modulumfang bleiben getrennt. XLSX ist weiterhin teilweise validiert und
unveröffentlicht; keine Releases oder Tags.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_caller_catalog_rest.py
python -B Tests/Release/test_xlsx_caller_catalog_rest.py
```
