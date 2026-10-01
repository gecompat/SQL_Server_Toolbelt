# Deterministische synthetische Zuordnung

Modul `toolbelt.pseudonymization.deterministic`, erster Release `1.0.0`,
Schema `toolbelt_pseudonymization`. Individuelle Benutzerfreigabe für
Range/DateShift/Lookup vom 2026-10-01 in der Reservewelle `.ai/BACKLOG.md`.
Source-/Lifecycle-/Testartefakte implementiert; `partially validated`,
`unreleased`. Finaler Safetyfix-Adapter auf SQL Server 2019 Linux CL150 am
2026-10-02 erfolgreich; finaler Windowsbaum und zusätzliche physische Targets
bleiben getrennt offen. Vor-Safetyfix-Erfolge sind ausschließlich historisch.

- [TVF_DeterministicRange](Documentation/TVF_DeterministicRange.md):
  geschlossener vollständiger bigint-Bereich, SHA256, begrenztes Rejection-
  Sampling und explizit versioniertes Byteformat.
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
Erste Version, deshalb kein historischer Vorgänger/Upgradebeleg.
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
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Finaler Safetyfix-Adapter SQL Server 2019 Linux/latest CL150; API/Fehler/Grenzen/Transaktionen, vier Caller-Temp-Eclipsing/Help-Fixtures, Installer-Callertransaction ON/OFF und SQLCMD-nonzero, Local-CS/Central-BIN2, administrative CrossDB-CI, direkte Minimalrechte und Clientmetadaten lokal/zentral, Wiederholung/Drift/Kollision/Dependency/Uninstall; finaler Windowsbaum und weitere physische Targets offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
