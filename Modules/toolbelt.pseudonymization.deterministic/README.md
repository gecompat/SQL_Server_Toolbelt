# Deterministische synthetische Zuordnung

Modul `toolbelt.pseudonymization.deterministic`, erster Release `1.0.0`,
additiver Translate-Slice `1.1.0` implementiert.
Schema `toolbelt_pseudonymization`. Individuelle Benutzerfreigabe für
Range/DateShift/Lookup vom 2026-10-01 in der Reservewelle `.ai/BACKLOG.md`.
Source-/Lifecycle-/Testartefakte implementiert; `partially validated`,
`unreleased`. Der historische 1.0-Safetyfix-Adapter besteht auf SQL Server
2019 Linux und 2025 Windows/CU8. Translate 1.1 besteht vollständig auf Linux
2019/latest CL150 local/central und Windows 2025/CU8 central CL150/160/170.
Windows local: API-/Safetyfälle im früheren Gesamtfehllauf bestanden;
separate korrigierte Lifecycle-/Metadatenprüfung erfolgreich. Der ursprüngliche
Gesamtfehllauf bleibt ein Fehllauf. Aktuelle CI und neue Minimalrechte offen.
Zusätzliche physische Targets bleiben getrennt offen. Vor-Safetyfix-Erfolge
sind ausschließlich historisch.

- [TVF_DeterministicRange](Documentation/TVF_DeterministicRange.md):
  geschlossener vollständiger bigint-Bereich, SHA256, begrenztes Rejection-
  Sampling und explizit versioniertes Byteformat.
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
- Nachweis: `local: Tests/CI/run-deterministic-translate-lab.ps1`
- Scope: Version 1.1.0: vollständiger Linux2019/latest CL150 local/central; bestehende APIregressionen, Translate/21Safetybatches/vier Caller-Collations/echte2MiB+16MiB/Metadaten, genuine1.0Upgrade/FirstInstall/Repeat/CallerTX/Snapshot-Faults/fremdeFutureSlots/historischerUninstall/CrossDB/ownCleanup; Windows2025/CU8 vollständiger central-Adapter CL150/160/170 PASS; lokale APIs/Safety im früheren insgesamt fehlgeschlagenen Lauf bestanden, separater korrigierter lokaler Metadaten-/Lifecycleadapter PASS; keine neuen Lab-Grants/Serverkonfiguration, weitere Targets/Minimalrechte/CI offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
