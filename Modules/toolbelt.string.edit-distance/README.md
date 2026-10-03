# Begrenzte Editierdistanzen

`toolbelt.string.edit-distance` Version 1.1.0 stellt genau drei öffentliche
Funktionen bereit: [Levenshtein](Documentation/TVF_LevenshteinDistance.md) und
[Optimal String Alignment](Documentation/TVF_OsaDistance.md) und
[Jaro-Winkler](Documentation/TVF_JaroWinklerSimilarity.md). Sie verwenden
den gemeinsamen portablen SAFE-CLR-Kern und Unicode Scalars ohne Normalisierung.
Der [kanonische Vor-Source-Vertrag](../../Documentation/Architecture/EDIT_DISTANCE_CONTRACT.md)
legt Profile, Ergebniszeile, Fehlerpriorität und Lifecycle fest.

Status 1.1: teilweise validiert und unveröffentlicht; neue private Gesamtadapter
auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170
lokal/zentral samt SC-UTF8-Consumer und unabhängigem Cleanup bestanden.
Jaro-Vertrag und Assemblyerweiterung sind ausdrücklich freigegeben. Die folgende
historische Evidenz betrifft ausschließlich 1.0; sie qualifiziert 1.1 nicht.
Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen.

## Aufruf

```sql
SELECT * FROM toolbelt_string.TVF_LevenshteinDistance(N'kitten', N'sitting', DEFAULT, DEFAULT);
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'CA', N'AC', DEFAULT, DEFAULT);
```

Genau eine Zeile: Distance int, ExceedsMaxDistance bit und ErrorCode int.
ErrorCode ist logisch nicht NULL; SQL-Metadaten dürfen nullable sein.
Oberhalb MaxDistance: NULL/1/0. NULL-Eingabetext: NULL/NULL/0.
Profile standard/large sind ordinal und vollständig zu schreiben; keine Kürzung.

## Build und Lifecycle

`Scripts/New-ClrReleaseArtifacts.ps1 -OutputDirectory <neues-leeres-Ziel>`
erzeugt mit vorhandenen Framework-4.8-Werkzeugen Releasebinary, SHA2-512-Manifest
und Deploy.WithAssembly.sql. Keine Downloads. Die Releasequellen werden vor/nach
Build und vor Ausgabe bytegenau gebunden; alte Artefakte werden nicht übernommen.

SQLCMD-Deploy benötigt DeploymentMode=local oder central und
ExpectedInstalledAssemblyHash=0x ausschließlich bei vollständig frischer Installation.
Reinstall benötigt den offline belegten tatsächlichen bisherigen SHA2-512-Hash.
AssemblyBits kommt ausschließlich aus dem geprüften Releasegenerator.
Das separate administrative `Deployment/Add-TrustedAssembly.sql` ist ein
expliziter exakter Hash-Opt-in. Es aktiviert keine Serveroption und erteilt keine Rechte.
Regulärer Deploy/Uninstall verändert keine Trustliste.

Uninstall benötigt denselben erwarteten installierten Hash; central zusätzlich
ConfirmNoExternalConsumers=1. Unbekannte Versionen, fremde Slots/Assembly,
Dependencies oder fehlende Rechte blockieren vor Mutation und erneut unter AppLock.
Caller-Transaktionen werden vor SET abgewiesen. Das gemeinsame Kategorie-Schema
wird nur bei vollständiger Leerheit entfernt; andere Module bleiben erhalten.

SELECT auf den öffentlichen TVFs ist das Aufrufrecht. Administrative Build-,
Deploy- und Trustrechte sind davon getrennt; Minimalrechte noch nicht nativ qualifiziert.
Siehe [Tests](Tests/README.md) und [synthetische Beispiele](Examples/EditDistance.sql).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-03`
- Nachweis: `private bounded Root qualification adapters; public Framework/runtime fixtures; independent read-only cleanup audits`
- Scope: Separate neue 1.1-/genuine 1.0-Builds, vollständige Distanz-/Jaro-Frameworkregression und Python 21185, beide Artefakt-IL-Metadatengates. Private native Gesamtadapter auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral und SC-UTF8 bestanden: genuine Upgrades, sechs Slots, API/Client/Metadata/Lifecycle/Caller/AppLock/Faults/Kollision/Dependency/Hash/Sichtbarkeit und unabhängige eigene 3DB/2Trust-Bereinigung. Healthy-Guard direkt; doomed ganzer originaler Firstbatch in eigener DB-Prozedur, kein vollständiger SQLCMD-doomed-Nachweis. Keine Konfigurations-/Rechte-/Owner-/Infrastrukturänderungen. Tatsächliche Minimalrechte, weitere physische Ziele, Heap und aktuelle PR-Head-CI bleiben getrennte offene Gates. Historische 1.0-Evidenz bleibt getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Deployment/Uninstall setzt vorhandenes VIEW DEFINITION auf der Datenbank und SELECT auf sys.sql_expression_dependencies voraus. Fehlende oder unbekannte Metadatensicht blockiert vor Mutation; der Lifecycle erteilt diese Rechte nicht. FT-Bindung und releaseabhängige Parameter-/Resultspalten werden bei vorhandenem Release erneut unter AppLock geprüft; versionsgleiche öffentliche SQL-Source bleibt reparierbar.

## Erweiterung 1.1

Jaro hat drei nvarchar(max)-Parameter und Similarity float(53)/ErrorCode int.
Der [Jaro-Vertrag](../../Documentation/Architecture/JARO_WINKLER_CONTRACT.md)
beschreibt feste Profile, reale halbe Transpositionen und rationalen Bonusvergleich.
Genuine 1.0-Quellen werden durch Scripts/New-LegacyTestArtifacts.ps1 unverändert
aus dem gepinnten öffentlichen Blob bereitgestellt; Paketierung beweist keinen Build.
Vier bekannte 1.0-Slots und sechs bekannte 1.1-Slots werden byteexakt geprüft.
Die bisherigen öffentlichen Labadapter besitzen historische Cleanupgrenzen.
Die neue 1.1-Nativeevidenz stammt aus einem separat geprüften privaten, vollständig
gepinnten Ownscopeadapter; Einzelheiten und Grenzen stehen in [Tests](Tests/README.md).
