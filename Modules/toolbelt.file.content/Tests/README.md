# Tests für toolbelt.file.content

## Übersicht

| Test | Zweck | Ort |
|---|---|---|
| Statische Vertragsprüfung | Artefakte, Vertragsmarker und Signatur | `Tests/Static/validate_contract.py` |
| Lifecycle-Contract | Objekte existieren im Ziel-Compatibility-Level | `Tests/Runtime/Lifecycle.Contract.sql` |
| Befüllter Repeat | Zwei echte versionsgleiche Deploys; exakte Zeilen, Identity und Katalog | [RepeatCurrent.Contract.sql](Runtime/RepeatCurrent.Contract.sql) mit gemeinsamem [Snapshot](Runtime/RepeatCurrent.Capture.sql) und [Orakel](Runtime/RepeatCurrent.Assert.sql) |
| File-Content-Contract | Hilfe-Contract, Pfadvalidierung, Allowlist, Traversal | `Tests/Runtime/FileContent.Contract.sql` |
| Root-Grenzvertrag | Literale Verzeichnisgrenzen, Unicode, Leerzeichen und beide Fassaden | [RootBoundary.Contract.sql](Runtime/RootBoundary.Contract.sql), vom File-Content-Contract eingebunden |

## Ausführung

Lokales Deployment:

```bash
cd Modules/toolbelt.file.content/Deployment
sqlcmd -S localhost -d ToolbeltFileContentTest -i Deploy.sql \
  -v DeploymentMode=local
```

Statische Prüfung:

```bash
python3 Modules/toolbelt.file.content/Tests/Static/validate_contract.py
```

Runtime-Test für ein Compatibility Level:

```bash
cd Modules/toolbelt.file.content/Tests/Runtime
sqlcmd -S localhost -d ToolbeltFileContentTest -i FileContent.Contract.sql \
  -v CompatibilityLevel=170 FixtureRoot=/synthetic/file-content-fixtures
```

## Hinweise

- Der befüllte Repeat läuft ausschließlich auf einer eigenen leeren,
  installierten Test-Allowlist. Aus `Modules/toolbelt.file.content/Deployment`
  mit `sqlcmd -i ../Tests/Runtime/RepeatCurrent.Contract.sql -v DeploymentMode=local`
  beziehungsweise `central` aufrufen. Die Session hält ihre Snapshots über
  beide echten Deploys. Kein Datei-I/O, CLR, Konfigurationsänderung oder Grant.
- Vier synthetische Zeilen enthalten aktive/inaktive Roots, NULL/leere und
  Unicode-/Trailing-Space-Texte sowie feste Auditzeiten. Eine zusätzlich
  gelöschte höchste Identity und der nächste reguläre Insert prüfen den
  Zähler unabhängig von `MAX(RootPathId)`. Die Daten werden bytegenau verglichen.
- Der Katalogsnapshot vergleicht Objekt-/Schemaidentität, Spalten, Identity,
  Indizes samt Schlüsselspalten, Constraints, Trigger, vorhandene
  Berechtigungsmetadaten und Extended Properties. Die Tabellenbeschreibung
  wird absichtlich veraltet; ausschließlich diese `MS_Description` muss der
  Deploy kanonisch erneuern. Eigene zusätzliche Tabellen-/Spaltenannotation
  muss erhalten bleiben. Es werden keine nichtleeren Benutzergrants erzeugt;
  deren Erhalt und echte Minimalrechte bleiben offen.
- Der bestehende Linuxadapter führt den Repeat vor der I/O-Konfiguration in
  lokalem und zentralem Modus auf dem jeweiligen nativen Default-CL aus:
  2019/150, 2022/160, 2025/170. Die anschließende bestehende Datei-Suite
  qualifiziert davon getrennt ihre bisherige CL-Matrix. Fehler enden über
  SQLCMD; die eigene disposable CI-Umgebung wird im vorhandenen EXIT-Trap
  entfernt. Ein Hard-Interrupt-Cleanup wird daraus nicht abgeleitet.

- Nur eine vorbereitete eigene Testdatenbank verwenden. Die Grenzmatrix
  verwendet eine vorhandene Allowlist-Zeile ohne Identity-Insert und
  restauriert Allowlist-Zeilen per Rollback.
- Der File-Content-Contract enthält kleine Datei-Fixtures und erfordert eine
  vorbereitete Allowlist sowie serverseitige Dateien unter `FixtureRoot`.
  Der eingebundene Root-Grenzvertrag prüft das gemeinsame Prädikat und beide
  Fassaden mit synthetischen Pfaden; Denial-Fälle dürfen keinen Providerfehler
  als erfolgreiche Ablehnung ausgeben. Allowlist-Änderungen werden zurückgerollt.
- SQLCMD-Includes werden relativ zum angegebenen Arbeitsverzeichnis aufgelöst.
  Die beiden Beispiele beginnen jeweils am Repository-Root.
- `OPENROWSET(BULK...)` erfordert `ad hoc distributed queries` oder
  `ADMINISTER BULK OPERATIONS`.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356

Die binären Runtime-Fixtures werden durch `Tests/CI/run-file-content-linux.sh` deterministisch und bytegenau unter `.runtime/file-content-fixtures` erzeugt. Sie werden nicht in Git gespeichert.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-07`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37687448814`
- Scope: Commit 8effcee91106cb4b8924c7a839928d550c0653b6: befüllter 1.0.0-Repeat zweimal lokal und zentral, SQL Server 2019/150, 2022/160 und 2025/170 Linux; exakte Zeilen/Identity/Katalog/Annotationen und Uninstall; vorhandene Permissions nur beobachtet, keine Benutzergrants erzeugt; bestehende Datei-I/O-Suite anschließend erfolgreich; Windows/weitere Repeat-CLs/Minimalrechte/historische Migrationen offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Historische Bindung und gestoppte erste Restmatrix — 2026-11-08

Der [aktuelle Nachweis](../../../Releases/1.0.0/FILE-CONTENT-REPEAT-QUALIFICATION.md)
bindet drei erfolgreiche Linux-Main-CI-Jobs mit 23 unveränderten relevanten
Quellen an den aktuellen Stand. Die befüllten Default-CL-Repeats lokal/zentral
bleiben gültig und wurden nicht wiederholt. Der erste Windows-Restfall ist
FAILED_CLEANED; eigene DB entfernt, frischer unabhängiger Windows-Audit PASS.
Die Rendererabweichung ist offline reproduziert und durch eine echte
Erstexport-/Repeat-Batchgegenprobe korrigiert; 13 Offlineprüfungen bestehen.
Kein bestandener Gesamtfall, keine neue Windows-/Restmatrixabnahme daraus.
Der No-Retry-Rahmen ist geschlossen; Korrektur nativ NOT_EXECUTED. Vor einer
Fortsetzung ist eine neue konkrete endliche Freigabe nötig. Andere Rechte-,
Lifecycle- und Providerfälle sowie optionale Datei-I/O bleiben getrennt.

## Korrigierte Restmatrix abgeschlossen — 2026-11-08

Die [ausdrücklich freigegebene Fortsetzung](../../../Releases/1.0.0/FILE-CONTENT-REPEAT-COMPLETION.md)
bestand neun Läufe auf Windows2019/2022/2025 und zusätzlichen Linux-CLs,
18 Kontexte, 36 Original-SQL-Fixtures und neun frische Audits. Alle 18 eigenen
DBs entfernt; 18/22 Aufrufe und Reservierungen verbraucht, keine Korrekturfälle.
Mit drei unverändert wiederverwendeten Linux-Default-Paaren ist genau die
befüllte Repeat-Matrix auf zwölf Engine-/CL-Paaren lokal/zentral geschlossen.
Alle 18 neuen Vor-/Nachdefinitionspaare stimmen exakt überein. Der frühere
FAILED_CLEANED-Fall bleibt erhalten; seine Warteangabe ist historisch erledigt.
Weitere Rechte-, Lifecycle-, Ressourcen- und Providerfälle bleiben separat.

## Gezielte weitere Lifecycleprofile — 2026-11-08

Der [aktuelle Lifecyclebericht](../../../Releases/1.0.0/FILE-CONTENT-LIFECYCLE-QUALIFICATION.md)
belegt auf zwölf Windows-/Linux-Engine-/CL-Paaren lokal/direkt zentral 288
Profile: unbekannte Versionsmarker, drei fremde Namenskollisionen jeweils
für Deploy/Uninstall, Schema-/Fremdobjekterhalt, Neuinstallation, Entfernen des
leeren Schemas und idempotentes Uninstall bei fehlendem Modul. Zwölf frische
Audits bestanden; alle 24 eigenen DBs entfernt. Der Repeat-Scope wurde nicht
wiederholt. Weitere Drift-/Lock-/Rechte-/Ressourcen-/Providerprofile bleiben
getrennt; keine allgemeine Lifecycle- oder Modulgesamtabnahme.

## AppLock zwischen zwei echten Sitzungen — 2026-11-08

Die [gezielte AppLockmatrix](../../../Releases/1.0.0/FILE-CONTENT-APPLOCK-QUALIFICATION.md)
schließt 96 Profile auf 24 lokalen/direkt zentralen Windows-/Linux-Kontexten:
je exakte Deploy-/Uninstallabweisung unter einer bestätigten exklusiven
zweiten Sitzungssperre und erfolgreicher Pfad nach verifizierter Freigabe.
Zwölf frische Audits bestanden, alle 24 eigenen DBs entfernt. Keine neue
Identität oder Rechtevergabe, kein Full-Repeat-/API-/Lifecycle-Rerun.
Die vorherige pauschale AppLock-Offenangabe gilt für diesen Scope nicht mehr;
weitere Race-/Caller-/SET-/Rollback-/Ressourcen-/Rechtefälle bleiben getrennt.

## Gezielte Definitionsreparatur — 2026-11-09

Die [neue Driftmatrix](../../../Releases/1.0.0/FILE-CONTENT-DEFINITION-DRIFT-QUALIFICATION.md)
belegt 48 gezielte Reparaturen auf 24 lokalen/direkt zentralen Windows-/Linux-
Kontexten: gleiche positive Objekt-ID, absichtlich anderer Bodyhash, danach
exakt kanonischer Body/Katalog sowie unveränderte Allowlist-Zeilen/Identity und
Berechtigungen. Zwölf frische Audits, alle 24 eigenen DBs entfernt. Alte
Vollfixtures nicht wiederholt, keine neuen Rechte oder Datei-I/O. Tabellen-/
Owner-/ACLdrift und übrige Modulpflichten bleiben getrennt.

Der [Sitzungsverlust-Nachweis](../../../Releases/1.0.0/FILE-CONTENT-LEASE-RECOVERY.md)
ergänzt vier vollständige lokale/zentrale Deploy-/Uninstallfälle nach Beenden
eigener ruhender AppLock-Haltersitzungen auf Windows2025/CU8 CL170. Verifizierte
Sperrfreigabe, neutrale Sitzung, Katalog-/ResultTable-Erhalt und frischer Audit
bestanden. Beide eigenen DBs entfernt; zwei ältere Fehlläufe und ihre Audits
bleiben erhalten. Keine Unterbrechung einer aktiven Mutation, keine allgemeine
Host-/Transport- oder Rechtequalifikation.
