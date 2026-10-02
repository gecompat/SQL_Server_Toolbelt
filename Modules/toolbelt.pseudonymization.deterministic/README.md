# Deterministische synthetische Zuordnung

Modul `toolbelt.pseudonymization.deterministic`, erster Release `1.0.0`,
additiver Translate-Slice `1.1.0` implementiert.
Die additive GeoJitter-Welle `1.2.0` ergänzt genau eine Inline-TVF.
Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`.
Schema `toolbelt_pseudonymization`. Individuelle Benutzerfreigabe für
Range/DateShift/Lookup vom 2026-10-01 in der Reservewelle `.ai/BACKLOG.md`.
Source-/Lifecycle-/Testartefakte implementiert; `partially validated`,
`unreleased`. Der historische 1.0-Safetyfix-Adapter besteht auf SQL Server
2019 Linux und 2025 Windows/CU8. Translate 1.1 besteht vollständig auf Linux
2019/latest CL150 local/central und Windows 2025/CU8 central CL150/160/170.
Windows local: API-/Safetyfälle im früheren Gesamtfehllauf bestanden;
separate korrigierte Lifecycle-/Metadatenprüfung erfolgreich. Der ursprüngliche
Gesamtfehllauf bleibt ein Fehllauf. Neue Minimalrechte bleiben offen;
aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen.
Zusätzliche physische Targets bleiben getrennt offen. Vor-Safetyfix-Erfolge
sind ausschließlich historisch.

- [TVF_DeterministicRange](Documentation/TVF_DeterministicRange.md):
  geschlossener vollständiger bigint-Bereich, SHA256, begrenztes Rejection-
  Sampling und explizit versioniertes Byteformat.
- [TVF_DeterministicGeoJitter](Documentation/TVF_DeterministicGeoJitter.md):
  synthetische 2D-Points mit SRID 4326, binärer Entitätsschlüssel,
  MappingVersion/Seed, flächenorientierte konservative Kugelkappe und
  strikte native Radiusnachbedingung; kein Clipping oder Privacy-Versprechen.
  [Kanonischer Vertrag](../../Documentation/Architecture/DETERMINISTIC_GEO_JITTER_CONTRACT.md).
- [TVF_DeterministicTranslate](Documentation/TVF_DeterministicTranslate.md):
  einzeln freigegebene formaterhaltende ASCII-Vorwärtstransformation,
  casegekoppelte bijektive Substitution mit expliziten Separatoren und
  begrenzten Standard-/Large-Profilen. Der
  [Vor-Source-Vertrag](../../Documentation/Architecture/DETERMINISTIC_TRANSLATE_CONTRACT.md)
  ist vor Source qualifiziert; tatsächliche integrierte Nachweise und
  offene Teilscopes sind in der Testmatrix getrennt ausgewiesen.
- [TVF_DeterministicDateShift](Documentation/TVF_DeterministicDateShift.md):
  Entity-bezogener Tagesoffset, datetime2(7), strikter Overflow.
- [USP_DeterministicLookup](Documentation/USP_DeterministicLookup.md):
  caller-lokale Inputs/Pool, ausdrückliche Poolversion, Standard-ResultTable.

Zwei interne echte Inline-TVFs kodieren feste bigint-Bytes und implementieren
denselben Range-Kern. Eine interne Lookup-Core-Prozedur bildet die separate
Compilergrenze hinter der öffentlichen Help-/Tempnamen-Fassade; keine
zusätzliche öffentliche API und keine direkten internen Caller-Grants.
Keine Scalar-only-Fassade, Assembly, CLR-Fallback,
persistierte Mappingtabelle, Secrets oder File-/Netzwerkzugriffe.
Keine Anonymisierung oder Kryptografie-/Eindeutigkeitsgarantie.

## Deployment und Grenzen

SQLCMD aus Deployment: Deploy.sql mit DeploymentMode=local|central;
Uninstall.sql mit ConfirmNoExternalConsumers=0|1. DDL-Rechte separat vom
Caller. Deploy und Uninstall verweigern eine bereits offene Callertransaktion
vor SET-Optionen und Temp-DDL mit RAISERROR 50000, State 1 und dem Prefix
`DETERMINISTIC_LIFECYCLE_CALLER_TRANSACTION:`; SQLCMD muss nonzero enden.
Für Version 1.0 gab es keinen historischen Vorgänger. Der echte
1.0→1.1-Upgradebeleg besteht im ausgewählten Linux-/Windows-Scope;
vorhandene 1.0-Nachweise allein ersetzen ihn nicht.
Wiederholung repariert eigenen Source-Drift, Hashes sind nur diagnostisch.
Unbekannte Releases und fremde Namens-/Ownershipkollisionen scheitern
vor Mutation. Application Lock/Transaktion sichern konkurrierenden
Lifecycle. Zentraler Uninstall braucht Betreiberbestätigung; fremde
same-database Dependencies blockieren. Geteiltes Schema bleibt bestehen,
sofern nicht leer und nachweislich als diese Kategorie verwaltet.

Pool-/Resulttext höchstens je 16 MiB, Input-/Poolrows höchstens je 100000,
Key pro Input höchstens 8000 Byte; kein Unlimited und keine Peak-RAM-
oder Hardwall-Garantie. SQL 2019/2022/2025, Windows/Linux und lokale/
zentrale Verwendung sind Zielscope; aktueller risikobasierter Linuxscope
mit API-/Ressourcen-/Transaktions-/Rechte-/Client-/Lifecycle-Fällen erfolgreich.
Primär zuerst risikobasiert 2019 Linux und 2025 Windows, ohne Ableitung
weiterer physischer Targets oder CrossDB-Minimalrechte.

Offline: python Modules/toolbelt.pseudonymization.deterministic/Tests/Static/validate_contract.py.
Diese Referenz/Source-Prüfung bestätigt weder SQL-Syntax noch SQL-Laufzeit.
Sie ersetzt keine SELECT-Metadaten-, Lifecycle-, Resource- oder Rechteprüfung.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-deterministic-geo-lab.ps1`
- Scope: Version 1.2.0: Linux2019/latest CL150 und Windows2025/CU8 CL150/160/170 lokal/zentral PASS; ausdrücklich GeoJitter.Contract.sql (ursprüngliche fünf unpartitionierte Batches/504 Orakel), GeoJitter.Safety.sql, InstalledMetadata.Contract.sql plus Client-/SQLmetadaten, echte1.0/1.1-Upgrades, FirstInstall/Repeat/CallerTX-SET/Snapshot-Faults/FutureSlots/Uninstall/ownCleanup; alte sieben Source-Dateien bytegleich, kein erneuter finaler Vollfamilien-Runtime-Nachweis; keine Konfigurations-/Rechteänderungen, neue Minimalrechte/weitere Targets/exakt129ByteUDT offen; aktueller CI-/PR-Mergegate am exakten Head separat nachzuweisen; unreleased
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
