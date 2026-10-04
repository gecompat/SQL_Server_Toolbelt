# Paarvergleich – Nachweisstand

Modul 1.0.0 bleibt `partially validated` und `unreleased`. Der private,
begrenzte Labadapter bestand folgende ausgewählte Nachweisscopes; tatsächliche
Receipt-, Journal-, Capture- und Pinprüfungen wurden unabhängig geschlossen:

- 2026-10-03: SQL Server 2019 Linux/latest CL150, `local`, SC-UTF8:
  fünf öffentliche SQL-Fixtures sowie clean/repeat/uninstall/repeat.
- 2026-10-04: SQL Server 2025 Windows/CU8 CL170, `local`, SC-UTF8:
  dieselben fünf Fixtures sowie Wiederholung und uninstall/repeat.
- 2026-10-04, separat `central`: InstalledMetadata, drei direkte
  Algorithmusconsumer mit genau fünf typgenauen Feldern und EOF/noNext sowie
  drei ResultTable-Aufrufe ohne Resultset. `ConfirmNoExternalConsumers=0`
  wurde strikt mit 55128/1, unverändertem vollständigem Katalogsnapshot und
  gesunder Session abgelehnt; mit1 bestanden Uninstall und Wiederholung.

Jeder erfolgreiche Scope schloss die eigene Bereinigung und einen separaten
frischen Audit ein. Zentral wurden beide eigenen Datenbanken entfernt und
der eine eigene Trusteintrag wiederhergestellt. Konfiguration, SQL-Rechte
und Owner wurden nicht verändert. Keine vorhandenen Provider-/Helpernachweise
werden als Wrappernachweis übernommen.

Der erste zentrale Adapterlauf war wegen eines NULL-Secondarycount-Fehlers
fehlgeschlagen und wurde bereinigt. Vier erfolgreiche Teilabschnitte dieses
Laufs waren kein Gesamt-PASS; die spätere erfolgreiche zentrale Qualifikation
ersetzt diese historische Fehleraufzeichnung nicht.

Tatsächliche Minimalrechte, fremde CLR-PC-Kollisionen, weitere
Lifecycle-Negativfälle und Zielkombinationen sowie aktuelle exakte Head-CI
bleiben **OPEN**. Ein begrenzter Scope ist keine vollständige Produktqualifikation.


Die SQL-Fixtures verwenden ausschließlich synthetische Daten. Voraussetzung: exakt gebundene bekannte Dependencies im selben Installationsmodus und dieselbe kontrolliert eigene Testdatenbank. [Matrix](TEXT_PAIRS_TEST_MATRIX.md). Native-/Trustverbraucher werden koordiniert; dieser Modulstand startet keine Lab-Infrastruktur und gewährt keine Rechte.

Sourceprüfungen am 2026-10-03: `python Modules/toolbelt.string.text-pairs/Tests/Static/validate_contract.py` erfolgreich; Sourcekopplung/Signatur/Admissionreihenfolge/statische Providerconsumer/atomare Publishgrenze und Lifecycle-Schutzregeln, kein SQL. `python Tests/Documentation/validate_documentation.py --all --write` erfolgreich: 36 Manifest-/Status-/Link-/geschützte Lizenz- und registrierte statische Contracts; ebenfalls kein nativer Wrappernachweis. Aktuelle Head-CI separat vor Merge erforderlich.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `private bounded Windows-/Central-Labadapter; unabhängiger physischer Receipt-/Journal-/Capture-/Pin-Audit`
- Scope: SQL Server 2025 Windows/CU8 CL170 SC-UTF8 local: fünf öffentliche SQL-Fixtures und Lifecycle-Wiederholungen. Separat central: InstalledMetadata, drei direkte typgenaue Algorithmusconsumer mit EOF/noNext, drei ResultTable-Ausgaben ohne Resultset, strikte Uninstall-Bestätigung 55128/1 mit unverändertem Katalogsnapshot, Wiederholung und eigene Bereinigung. Keine Config-/Rechte-/Owneränderung. Minimalrechte, weitere Lifecycle-Negativfälle und Ziele bleiben offen; aktuelle PR-Head-CI separat.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
