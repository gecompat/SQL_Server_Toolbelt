# XLSX-Zellfunktionen mit einzelnem SELECT

Stand 2026-10-26: Die bereits einzeln freigegebenen Funktionen
`toolbelt_file.TVF_InterpretXlsxCell` und `toolbelt_file.TVF_FormatXlsxCell`
1.2.0 bestehen ihre isolierten SELECT-Profile auf zwölf Ziel-/CL-Fällen.
SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170 liefen auf Windows
und Linux, jeweils lokal und direkt in der zentralen Installationsdatenbank.
Dies ergänzt ausschließlich Zellinterpretation/-anzeige im bestehenden
Ownershipstand. Modulstatus bleibt `partially validated`, `unreleased`.

## Rechte und feste Werte

Ein eigener Benutzer ohne Login erhält jeweils nur SELECT auf eine öffentliche
Zell-TVF. Vor Grant und nach Revoke wird genau SQL229 verlangt. Beim erlaubten
Profil bleiben die andere öffentliche Zell-TVF sowie elf gesonderte Objekte
mit SQL229 gesperrt: vier interne XLSX-TVFs, interne Reader-USP, beide Raw-USPs,
drei ZIP-USPs und ResultTable-Helper. Breite Rollen-, Schema- und Datenbankrechte
führen zum Abbruch. Technische ZIP-Assemblyreferenzen benötigen damit für
diese Zellproben keine weiteren SQL-Objektgrants. Interne CLR-Transporte
werden dadurch keine öffentlichen APIs; Deployment vergibt keine Rechte.

Pro Kontext werden drei typisierte Interpretationszeilen geprüft: Zahl42.5,
Datum1900-03-01 aus Serial61 sowie Boolean1. Alle14 Ausgabeplätze einschließlich
vollständiger Echos und NULLs sind erfasst. Die Zahlenprobe vergleicht
DECIMAL(38,10), numerischen sql_variant-Basistyp und Precision<=38; dies ist
keine vollständige38-Ziffern-Abnahme. Drei Anzeigezeilen prüfen1.24/en-US,
-1,24/de-DE und den unveränderten Serial60-Status7 mit NULL-Anzeige.
Sollwerte sind feste Literale und werden nicht durch einen zweiten Provideraufruf
erzeugt. Transaktionszustände werden getrennt vor/nach dem Erfolgsaufruf erfasst.

Insgesamt48 positive Einzelgrantprofile,672 strikte SQL229-Abweisungen und144
feste Ergebniszeilenorakel. Beide Ausgabeformen werden über typisierte direkte
SELECT-Captures geprüft; Workbooklesen und ResultTable-Routing sind keine
zusätzlichen Aufrufwege dieser beiden TVFs.

## Entwickelte Prüfung und Bereinigung

Neu sind der begrenzte Zwei-DLL-[Labtreiber](../../Tests/Release/Invoke-XlsxCellCallerLab.ps1),
die [Case-Datei](../../Tests/Release/Runtime/XlsxCell.FunctionCases.sql) und vier
[Offline-Berichtsprüfungen](../../Tests/Release/test_xlsx_cell_caller_qualification.py)
in der vorhandenen Release-Suite. Gemeinsamer Callercontroller, Composer,
Trust-/Konfigurations-/Ownershiphelfer und frühere qualifizierte Treiber bleiben
unverändert. Produkt-SQL, C#, Manifest und Paketpayloads bleiben unverändert.
Es entstehen keine neuen CI-Jobs oder Trigger.

Ein erster eigener Fixtureversuch verwendete versehentlich das C#-Formatliteral
`yyyy-MM-dd` statt des exakt genehmigten Excel-Literals `yyyy-mm-dd` und scheiterte
am festen Anzeigeoracle. Nur der Input wurde korrigiert; der erwartete Status7
und alle Produktbytes blieben gleich. Originalfall, Runset, Journal, Komposition
und ausgeführte Casebytes bleiben privat erhalten. Der abschließende Leseaudit
löst nur den alten optionalen Casepfad gegen identische gespeicherte Bytes mit
dem ursprünglichen Digest auf; kein Originalpin und kein Journal wird geändert.

Die korrigierte Matrix und zwei frische Kontrollen bestanden: falscher
Zahlensollwert und Schema-SELECT wurden an den vorgesehenen Prüfstellen
abgewiesen und bereinigt. Insgesamt15 Versuche inklusive Erstfehler und beider
Kontrollen; nach allen Verbrauchern15 weitere separate rein lesende Audits PASS.
Alle27 eigenen Datenbanknamen sind abwesend, davon26 zur akzeptierten Matrix
und ihren Kontrollen. Eigener Trust und Konfiguration sind restauriert;
vorbestehende Werte und Trust-Fingerprints bleiben erhalten. Reale Werte,
Trusthashes, Endpoints, Zugangsdaten und Runtimeausgaben bleiben privat.

```powershell
python -B Tests/Release/test_xlsx_cell_caller_qualification.py
python -B Tests/Release/prepare_function_rights.py --cases Tests/Release/Runtime/XlsxCell.FunctionCases.sql --output $FreshPrivateDirectory
pwsh -NoProfile -NonInteractive -File Tests/Release/Invoke-XlsxCellCallerLab.ps1 -RunsetPath $RunsetPath -CaseIndex $CaseIndex
pwsh -NoProfile -NonInteractive -File Tests/Release/Invoke-XlsxCellCallerLab.ps1 -RunsetPath $RunsetPath -CaseIndex $CaseIndex -AuditOnly
```

Ein neuer privater Runset benötigt `xlsx-cell-caller-contract/v1`, zwölf explizite
schema-validierte Labauswahlen, beide Deploymentexports, kanonische Komposition
und alle Pflichtpins. Genau die reproduzierbaren Paket-DLLs für ZIP1.4.0 und
XLSX1.2.0 werden verwendet. Beide stimmen mit zwei früheren isolierten Builds
überein; vollständige aktuelle Compile-Inputs einschließlich ZIP-Referenz sind
unverändert. Es wurde kein neuer oder unbekannter Binary verwendet.

Der [maschinenlesbare Bericht](xlsx-cell-caller-qualification.json) bindet
Quellen, abstrakte Ergebnisse und Grenzen. Functional-Verbindungen waren
verschlüsselt und übernahmen den expliziten booleschen Trustwert des validierten
Vertrags; authentifiziertes TLS ist nicht ausgeführt. Direkte Clientmetadaten,
die ganze Typ-/Format-/Grenzdomäne, Raw-Workbook-USPs, Lifecycle/Upgrade,
andere Owner, echte CrossDB-Identitäten und Heap-/Parallelgates bleiben separat.
Keine Veröffentlichung oder Tags.
