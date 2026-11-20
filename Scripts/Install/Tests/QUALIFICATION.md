# Gemeinsamer create-only-Installer: begrenzte Abnahme

## Native Ausführung vom 2026-11-20

Der ausdrücklich freigegebene private Adapter `Invoke-CommonConsumer.private.ps1`
wurde mit `-Mode Run -SqlVersion 2025 -Patch CU8 -TrustMethod hash -WithoutForeign`
auf dem schema-validierten Windows-Labziel ausgeführt. Geprüft wurde das
lokale Windows-Profil aus dem grünen Integrationsstand `21ef0ef1`:
45 ausgewählte Module, 13 Assemblies, eine eigene temporäre Datenbank, CL170.
Provider: `System.Data.SqlClient`; funktionale verschlüsselte Verbindung gemäß
Labvertrag, kein Nachweis authentifizierten TLS.

Der Gesamtlauf endete mit `FAILED_CLEANED`, Prozess-Exit 1. Acht Prüfungen
bestanden: Engineversion, Strict Security, kein Lightweight Pooling, CL170,
Installationswiederholung, keine zusätzlichen Extended Properties,
13 mit `tlblt` beginnende Assemblies und 16 fachliche Tabellen. Die danach
geprüfte Capability-Projektion erfüllte die Erwartung nicht. API-Erzeugung,
Startwerte und tatsächliche DebugScript-Ausführung wurden daher in diesem
Gesamtlauf **nicht ausgeführt**. Teilprüfungen sind kein Gesamt-PASS.

Der separat gestartete `-Mode Audit` bestand mit Prozess-Exit 0 und zwei
Prüfungen. Er bindet den exakten finalen Journalhash und bestätigt die
Abwesenheit der eigenen Datenbank sowie unveränderte finale Konfigurations-
und Trustzustände. Beide genehmigten Aufrufe und die eine DB-Reservierung sind
verbraucht; keine Wiederholung gehört zu dieser geschlossenen Welle.
Originaljournale, Methode, Logs und Artefakte bleiben ausschließlich privat.

## Korrektur und Offlineabnahme

Die klassische Deployment-Includekette von `toolbelt.conversion.safe-cast`
und `toolbelt.json.pointer` führt zu generierten eingebetteten CREATE-Payloads,
nicht zu `Source`-Includes. Der bisherige gemeinsame Builder nahm dadurch die
sechs Safe-Cast-TVFs und `TVF_ResolveJsonPointer` nicht auf, obwohl beide Module
im Profilinventar standen. Die kanonischen Source-Dateien werden jetzt anhand
der Objektdeklarationen gezielt geladen. Ausgewählte Module ohne ausführbare
Source und ohne CLR führen zum Buildabbruch. Klassische Lifecycle-/Marker-
Skripte werden weiterhin nicht als Funktionalität übernommen.

Am 2026-11-20 bestanden:

- `python Scripts/Install/Tests/test_markerless_install.py`: elf Prüfungen,
  einschließlich aller sieben tatsächlich aufgenommenen kanonischen TVFs
  und der Ablehnung eines Moduls ohne Source/CLR.
- `New-SimpleCommonInstall.py` für Windows lokal/zentral und Portable
  lokal/zentral mit `--trust-mode hash`: vier Builds aus unveränderten,
  gebundenen Binaryinputs; neue Quellinventare enthalten die sieben TVFs.
- `Get-SimpleSqlBatches` mit dem hashgebundenen privaten ScriptDom-Parser:
  alle vier vollständigen korrigierten SQL-Dateien sind syntaktisch gültig
  und bestehen aus jeweils einem normalen T-SQL-Batch.

Diese Offlineergebnisse belegen keine native Ausführung der Korrektur.
Der noch offene gemeinsame Consumer-Gesamtfall benötigt einen separat
autorisierten endlichen Lauf mit frischem Abschlussaudit. Historische
Modul-/SSIS-Nachweise bleiben unverändert auf ihren ursprünglichen Scope
beschränkt. Keine vollständige Produkt-, Rechte- oder Plattformqualifikation,
keine Veröffentlichung und keine Installation auf einem Produktivziel.
