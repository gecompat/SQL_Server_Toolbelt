# XLSX SAFE-/Memory-only-Qualifizierung

Aktuelle öffentliche Adapterevidenz: `local: Tests/Runtime/Invoke-LabContract.ps1`, 2026-10-02, Linux 2019/latest und Windows 2025/CU8 erfolgreich. Begrenzte Framework-/NoIO-/IL-Prüfungen bleiben von tatsächlicher SQL-SAFE-Evidenz getrennt.

## Scope und Freigabe

Die bedingte Benutzerfreigabe vom 2026-10-01 für
`USP_ListXlsxWorksheets` und `USP_ReadXlsxWorksheetCells` steht im ersten
aktiven Abschnitt von [BACKLOG.md](../../.ai/BACKLOG.md). Dieser Spike
qualifizierte zunächst nur einen eigenen begrenzten ZIP-/XML-Kern. Nach den
erfolgreichen begrenzten NoIO- und tatsächlichen SAFE-Host-Gates entstanden die
beiden freigegebenen öffentlichen Reader-USPs im Modul
`toolbelt.file.xlsx-memory`. Kein SDK, Download, Worker, Datei- oder
Netzwerkprovider entsteht. Der Spike ist ein Qualifizierungsharness, keine
zusätzliche öffentliche SQL-API.

## Kanonischer ZIP-Kern

`ZipEntryProvider.ArchiveSession` wird in der bestehenden ZIP-Assembly gebaut.
Sie verwendet einmalig den vorhandenen EOCD-/Central-Directory-Parser,
Local-Header-Prüfung, bounded Dekompression und CRC32. Der XLSX-Kern referenziert
diese Assembly, nicht eine Sourcekopie. Die technischen CLR-Methoden erhalten
kein neues öffentliches ZIP-SQL-Binding. Die Release-/Upgrade-/Trust-Kopplung
ist in Release 1.4.0 gekoppelt; die echte 1.3-Upgradefixture prüft installierte
Assemblybytes gegen die jeweiligen Manifesthashes.
Die bestehenden Reader- und Writer-Verträge bleiben unverändert.

Ein Aufruf hält sein unverändertes Input-Bytearray, den ZIP-Index und gelesene
Parts. Parts werden materialisiert; `MemoryStream.ToArray` kopiert Payload.
Die interne SQL-Probe verwendet `SqlBytes.Value`, also eine mögliche zusätzliche
Archivmaterialisierung. Keine copy-free-, Streaming-, totale Peak-Memory- oder
SQL-Memory-Grant-Zusage. Das zusätzliche 128-MiB-Budget zählt konservative
implementierte Charges, nicht sämtliche tatsächlichen CLR-/Framework-Allokationen.

## Parsergrenze

Der Kern verwendet ausschließlich `System.Xml.XmlReader` mit Stream-Eingabe,
`DtdProcessing.Prohibit`, `XmlResolver = null` und begrenzter XML-Dokumentgröße.
Er überprüft alle vorhandenen Relationships; externe Targets werden abgelehnt.
Bekannte Macro-/ActiveX-/External-Link-/Connection-Typen sind ausgeschlossen.
Es gibt keine Formelberechnung, Styles-, Culture-, Datums- oder Anzeigeformatierung.
Shared Strings, Inline-/Rich-Text, Rohwert und gespeicherte Formel/Cache bleiben
getrennt. Nur vorhandene Zellen werden nach Zeile/Spalte ausgegeben; der
ausgewählte Resultatkern materialisiert vollständig vor seiner Rückgabe.

Die Qualifizierung akzeptiert aktuell Transitional-SpreadsheetML-Namespaces,
kanonische Partnamen und explizite Content-Type-Overrides für Workbook,
Worksheet und Shared Strings. Prozentkodierte Part-/Targetnamen, Strict-Open-XML,
verschlüsselte Archive, ZIP64 und unbekannte Cell-Inhalte sind nicht qualifiziert;
es gibt keinen impliziten Ersatzprovider. Explizite Zeilen- und Zellkoordinaten
sind erforderlich; fehlende Koordinaten werden nicht inferiert. Der Parser
qualifiziert einen begrenzten Inhaltsscope, keine vollständige XSD-Validierung.

Die konfigurierbaren Grenzen dürfen nur reduziert werden: 16 MiB Archiv,
64 MiB deklarierte entpackte Summe, 16 MiB je Part, 256 Parts, 32 Sheets,
100.000 Zellen, 50.000 Shared Strings und 8 MiB dekodierter Shared-String-Text,
XML-Tiefe 64 und Ratio 200. Parserbudget: 5 Sekunden, kooperativ über
ZIP-Index-/Payload-/CRC-/XML-/Ergebnisgrenzen. Einzelne Frameworkaufrufe sind
nicht unterbrechbar; keine harte Wallclock- oder Produktionskapazitätsgarantie.

## Reproduzierbare Prüfungen

```powershell
powershell -NoProfile -File Spikes/XlsxMemory/Run-FrameworkQualification.ps1
pwsh -NoProfile -File Spikes/XlsxMemory/Invoke-LabQualification.ps1 -Platform linux -Version 2019 -Patch latest
```

Der Framework-Harness erzeugt ausschließlich synthetische ZIP-/XML-Fixtures;
`ZipArchive` gehört nur zum unabhängigen Fixture-Writer, nicht zum Provider.
Builds benötigen die vorhandene .NET-Framework-4.8-Toolchain; nichts wird installiert.

Der getrennte Non-SQL-Sandbox-EXE läuft in einer partiell vertrauten AppDomain.
Ein Execution-only-`PermitOnly`-Frame steht über einer separaten
`NoInlining`-Demand-Methode. Fünf Canaries müssen die File-, Web-,
Isolated-Storage-, Unmanaged-Code- und privilegierte Security-Permission
tatsächlich verweigern. Direkte Demands im selben Frame sind kein gültiges
Orakel. Loader-Rechte gelten nur vor diesem Prüfbereich. Danach muss das
Workbook erfolgreich gelesen und externe Relationships/DTD abgelehnt werden.
Dies ist begrenzte empirische NoIO-Evidenz, kein vollständiger OS-Syscall-Trace.

Die IL-Prüfung deckt eigene statische/Instanzmethoden, Constructors und
TypeInitializers, Calltokens und direkte Assemblyreferenzen ab. Sie prüft eine
positive API-Allowlist, Stream-only-`XmlReader.Create`, kein `P/Invoke`,
`calli` oder `InlineSig`. Transitive Frameworkimplementierungen werden nicht
vollständig per IL bewiesen; Source-Review und adversariale Sandbox bleiben
getrennte Nachweise. Das finale Gate muss an exakte SHA2-512-Binaryhashes gebunden sein.

## Tatsächlicher Stand vom 2026-10-01

- Framework-4.8-Build und synthetischer Harness: PASS.
- Stored/Deflate, sparse Zellen, Unicode/Trailing Spaces, Rich-/Shared-/Inline-Text,
  missing/empty Value und Formelcache, Shared-Formula-Metadaten, Grenzkoordinaten,
  ausgewählte Fehler-/Limitfälle, wiederholte und vier unabhängige parallele
  kleine Aufrufe: PASS.
- Tatsächliche 100.000/100.001-Zell- und 8-MiB/+1-Codeeinheit-Shared-Text-Fixtures:
  Grenze erfolgreich beziehungsweise Fehler wie erwartet.
- Sandbox inklusive DTD/External-Relationship-Adversarialfällen und IL-Allowlist:
  PASS für den beschriebenen begrenzten Scope.
- ZIP-Writer-Frameworkregression auf dem erweiterten ZIP-Binary: PASS.
- Linux 2019 und Windows 2025: tatsächliche interne SAFE-Host-Gates PASS.
- Windows 2025/CU8: aktuelles öffentliches Releasebinary PASS für
  local/central/cross-database, Clientmetadaten einschließlich NULL-SELECT,
  Help, Compilergrenze, Outputexpansion, ResultTable, Transaktionen,
  Redeploy/Uninstall und echte ZIP-1.3→1.4-Regression.
- Linux 2019/latest: finaler identischer vollständiger öffentlicher Adapter
  auf demselben Binary PASS, einschließlich local/central/cross-database,
  Outputcharge-/NULL-Metadatenfix, Transaktionen und echter ZIP-1.3-Upgradefixture.
- Outputstrings werden vor SQL-Zeilenmaterialisierung mit vier Bytes je
  UTF-16-Codeeinheit zusätzlich belastet, wiederholte SST-Referenzen erneut.
  Exakte reduzierte Chargegrenze/+1 und repeated-SST-Fehler: Framework PASS;
  atomarer SQL-Fehler mit unverändertem Ziel: Windows PASS.
- Übrige tatsächliche numerische Ceiling-Fixtures, Peak-RAM, minimale
  EXECUTE-Rollen und übrige SQL-/Plattformmatrix: not executed. Details in der
  [Modultestmatrix](../../Modules/toolbelt.file.xlsx-memory/Tests/XLSX_CONTRACT_TEST_MATRIX.md).

Historischer Preflight: Linux 2019/2022 war zunächst wegen deaktiviertem CLR
not executed. Nach ausdrücklicher erweiterter Benutzerfreigabe wurde CLR nur
am koordinierten Linux-2019-Ziel aktiviert und wirksam verifiziert. Der
vorhandene konfigurierte und wirksame Memory-Wert blieb jeweils unverändert;
daraus folgt kein Memory-Gate-PASS. Vorzustände liegen ausschließlich im
lokalen Configjournal außerhalb von Git.

Der Lab-Harness validiert das Exportschema, übernimmt kanonische Selektoren
ohne Runnerinitialisierung und verwendet eigene eindeutig benannte disposable
Datenbanken. Exakte Assemblyhashes werden nur für den Test autorisiert;
ausschließlich neu angelegte eigene Trusteinträge werden wieder entfernt.
Kein automatischer Versions-/Plattformfallback und keine Lab-Ressourcenverwaltung.
Der optionale Schalter `-AuthorizeClrEnable` ist ausschließlich für die
ausdrücklich koordinierte Benutzerfreigabe auf Linux 2019/latest bestimmt.
Er prüft vorhandene Rechte, unveränderte strict security, deaktiviertes
lightweight pooling und sämtliche fremden Pending-Changes vor `RECONFIGURE`.
Ein secretfreies vorheriges Configjournal liegt außerhalb von Git; Restoration
erfolgt erst nach Koordination aller Wellen. Keine andere Option, kein
`WITH OVERRIDE`, Restart, GRANT oder `TRUSTWORTHY` ist freigegeben.

## Primärquellen und Aussagegrenzen

- [Microsoft: AppDomain.PermissionSet und homogene Sandbox](https://learn.microsoft.com/en-us/dotnet/api/system.appdomain.permissionset?view=netframework-4.7.2)
- [Microsoft: FileIOPermission und partielle Vertrauensgrenze](https://learn.microsoft.com/en-us/dotnet/api/system.security.permissions.fileiopermission?view=netframework-4.8.1)
- [Microsoft: PermitOnly-Stackgrenze](https://learn.microsoft.com/en-us/dotnet/api/system.security.codeaccesspermission.permitonly?view=netframework-4.7.2)
- [Microsoft: SQL-CLR-HostProtection](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-security-host-protection-attributes/host-protection-attributes-and-clr-integration-programming?view=sql-server-ver17)
- [Microsoft: clr strict security](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/clr-strict-security?view=sql-server-ver17)

Am 2026-10-01 quellengeprüft. CAS ist kein allgemeiner moderner
Security-Sicherheitsmechanismus. Ein Katalogwert `SAFE` oder Hashtrust allein
beweist unter strict security keinen vollständigen NoIO-Schutz; deshalb sind
Sandbox, API-Prüfung und tatsächlicher SQL-Hostaufruf getrennt erforderlich.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-xlsx-types-lab.ps1`
- Scope: Finaler identischer öffentlicher XLSX1.1-Adapter Linux2019/latest CL150 und Windows2025/CU8 CL150/160/170 jeweils local/central: drei Types-Fixtures, SQL-/Client-/native Nullability, clean/genuine1.0/repeat, CallerOFF/ON intakt/doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, synthetische0/NULL-Sichtbarkeitsgates, Consumer/Uninstall; RawType nach API-Schleifen auf letzterCL150/170 plus zentralerCaller. Voller PASS samt frischen eigenen Cleanup-Audits. Keine Konfigurations-/Rechteänderungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Lowpriv-Rechte, übrige physische Targets und Heap/Produktionskapazität offen. Historische FAILED-Adapterstände bleiben getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
