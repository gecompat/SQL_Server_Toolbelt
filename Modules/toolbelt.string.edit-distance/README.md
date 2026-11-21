# Begrenzte Editierdistanzen


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties. Der aktuelle SQL-Assemblyname ist `tlblt_String_EditDistance`.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


Aktuelle [CLR-Callerrechte](../../Releases/1.0.0/CLR-STRING-CALLER-QUALIFICATION.md): isolierte SELECT-Profile auf zwölf lokalen/direkt zentralen Ziel-/CL-Kombinationen. Neue Testtreiber/Fixtures sind entwickelt; Produktimplementierung und Modulstatus bleiben unverändert. Weitere API-/Client-/Lifecycle- und Ressourcengates sind separat.

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

Der frühere markerbasierte Lifecycle erlaubte einen exakt hashgebundenen 1.1.0-Repeat mit dem bekannten
Text-Pairs-Consumer 1.0.0, wenn Modul-/Objektmarker und Deploymentmodus
übereinstimmen. Der Consumer wird dabei nicht entfernt. Unbekannte Consumer,
abweichende Marker, ein Binarywechsel oder ein Moduswechsel bleiben gesperrt.
Die [Releaseprüfung](../../Releases/1.0.0/RELEASE-GATES.md) führt die gezielten
positiven und negativen Nachweise; weitergehende Supportgrenzen bleiben bestehen.

```sql
SELECT * FROM toolbelt_string.TVF_LevenshteinDistance(N'kitten', N'sitting', DEFAULT, DEFAULT);
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'CA', N'AC', DEFAULT, DEFAULT);
```

Genau eine Zeile: Distance int, ExceedsMaxDistance bit und ErrorCode int.
ErrorCode ist logisch nicht NULL; SQL-Metadaten dürfen nullable sein.
Oberhalb MaxDistance: NULL/1/0. NULL-Eingabetext: NULL/NULL/0.
Profile standard/large sind ordinal und vollständig zu schreiben; keine Kürzung.

## Maschinenlesbare Objektverträge

Die drei öffentlichen Funktionen und ihre internen CLR-Einstiege besitzen je
einen vollständigen kanonischen Skill, identisch in der jeweiligen DDL:

- [Levenshtein](../../Metadata/UsageSkills/toolbelt_string/TVF_LevenshteinDistance.md)
- [OSA](../../Metadata/UsageSkills/toolbelt_string/TVF_OsaDistance.md)
- [Jaro-Winkler](../../Metadata/UsageSkills/toolbelt_string/TVF_JaroWinklerSimilarity.md)

Die Skills unterscheiden NULL-Eingaben, Fachfehler und einen bewiesenen
Schwellenüberschritt. Ein fehlender Distanzwert bedeutet nicht Distanz 0.
Verglichen werden Unicode-Skalare, keine Graphemcluster; bestehende Spaces und
NUL bleiben Daten. Funktionsparameter mit SQL-Default werden beim SQL-Aufruf
ausdrücklich mit `DEFAULT` belegt. Interne Core-Skills sind als intern markiert
und verweisen auf diese öffentlichen Einstiegspunkte. Zur noch offenen
vollständigen SQL-Katalogintegration siehe [Usage-Skills](../../Metadata/UsageSkills/README.md).

## Aktueller Build und Installation

`Scripts/New-ClrReleaseArtifacts.ps1 -OutputDirectory <neues-leeres-Ziel>`
erzeugt mit vorhandenen Framework-4.8-Werkzeugen Binary- und Hashartefakte.
Keine Downloads. Die Releasequellen werden vor/nach
Build und vor Ausgabe bytegenau gebunden; alte Artefakte werden nicht übernommen.

Der [gemeinsame Installer](../../Deployment/ONE-CALL-INSTALL.md) übernimmt den
aktuellen create-only-Funktionssatz, lokal oder zentral und ohne SQLCMD-Modus.
Er bietet den Hashweg und ausdrücklich gewählte Wege mit bereits vorhandenem
Datenbank-Trust. Bestehende Objekte werden erhalten, es gibt hier keinen
automatischen Upgrade-/Uninstallpfad. Alte SQLCMD-/Marker-/AppLock-Verträge und
ihre Prüfungen bleiben ausschließlich an ihre ursprünglichen Lieferungen
gebunden; sie sind keine aktuellen Installationskommandos.

SELECT auf den öffentlichen TVFs ist das Aufrufrecht. Administrative Build-,
Installations- und Trustrechte sind davon getrennt. Die oben verlinkte aktuelle
Callerqualifikation ergänzt den datierten ursprünglichen Minimalrechte-Scope;
andere Rechte-/Ownerkontexte bleiben separat.
Siehe [Tests](Tests/README.md) und [synthetische Beispiele](Examples/EditDistance.sql).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-03`
- Nachweis: `private bounded Root qualification adapters; public Framework/runtime fixtures; independent read-only cleanup audits`
- Scope: Separate neue 1.1-/genuine 1.0-Builds, vollständige Distanz-/Jaro-Frameworkregression und Python 21185, beide Artefakt-IL-Metadatengates. Private native Gesamtadapter auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral und SC-UTF8 bestanden: genuine Upgrades, sechs Slots, API/Client/Metadata/Lifecycle/Caller/AppLock/Faults/Kollision/Dependency/Hash/Sichtbarkeit und unabhängige eigene 3DB/2Trust-Bereinigung. Healthy-Guard direkt; doomed ganzer originaler Firstbatch in eigener DB-Prozedur, kein vollständiger SQLCMD-doomed-Nachweis. Keine Konfigurations-/Rechte-/Owner-/Infrastrukturänderungen. Tatsächliche Minimalrechte, weitere physische Ziele, Heap und aktuelle PR-Head-CI bleiben getrennte offene Gates. Historische 1.0-Evidenz bleibt getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Der historische markerbasierte Deployment-/Uninstallvertrag setzte vorhandenes
VIEW DEFINITION auf der Datenbank und SELECT auf sys.sql_expression_dependencies
voraus. Seine datierten Sichtbarkeits-/AppLock-/Reparaturprüfungen qualifizieren
den damaligen Lifecycle. Der aktuelle gemeinsame create-only-Installer besitzt
einen eigenen Vertrag und erteilt ebenfalls keine Rechte.

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
