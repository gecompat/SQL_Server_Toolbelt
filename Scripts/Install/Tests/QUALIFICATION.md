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

Der anschließend separat freigegebene korrigierte Einmallauf mit denselben
Grenzen bestand neun Prüfungen einschließlich 45 Capability-Kandidaten und
ausschließlich NULL/incomplete für nicht ableitbare Versions-/Moduswerte.
Er scheiterte vor der API-Ausführung an der fehlenden öffentlichen
SSIS-Prozedur: Auch das klassische SSIS-Deployment ist ein Release-Template,
das die kanonischen Prozeduren nicht per Source-Include lädt. Der Gesamtlauf
bleibt `FAILED_CLEANED` mit Exit 1. Sein eigener frischer, final-journalgebundener
Audit bestand mit Exit 0 und zwei Prüfungen. Auch diese zwei Aufrufe und die
DB-Reservierung sind geschlossen; keine DebugScript-Ausführung ableiten.

## Korrektur und Offlineabnahme

Die klassische Deployment-Includekette von `toolbelt.conversion.safe-cast`
und `toolbelt.json.pointer` führt zu generierten eingebetteten CREATE-Payloads,
nicht zu `Source`-Includes. Der bisherige gemeinsame Builder nahm dadurch die
sechs Safe-Cast-TVFs und `TVF_ResolveJsonPointer` nicht auf, obwohl beide Module
im Profilinventar standen. Zusätzlich fehlten `USP_ExplainSsisDataFlow` und
`USP_ExplainSsisDataFlowInternal` aus dem SSIS-Release-Template. Deshalb werden
nun für alle ausgewählten Module die namensgleichen kanonischen Source-Dateien
anhand ihrer Objektdeklarationen ergänzt und dedupliziert. Gruppendateien
behalten ihre vorhandene Includekette. Ausgewählte Module ohne ausführbare
Source und ohne CLR führen zum Buildabbruch. Klassische Lifecycle-/Marker-
Skripte werden weiterhin nicht als Funktionalität übernommen.

Am 2026-11-20 bestanden:

- `python Scripts/Install/Tests/test_markerless_install.py`: zwölf Prüfungen,
  einschließlich aller sieben kanonischen TVFs, beider SSIS-Prozeduren,
  statischer CREATE-Textabdeckung aller deklarierten SQL-Objekte je Profil
  und Ablehnung eines Moduls ohne Source/CLR.
- `New-SimpleCommonInstall.py` für Windows lokal/zentral und Portable
  lokal/zentral mit `--trust-mode hash`: vier Builds aus unveränderten,
  gebundenen Binaryinputs; neue Quellinventare enthalten die sieben TVFs und
  beide SSIS-Prozeduren.
- `Get-SimpleSqlBatches` mit dem hashgebundenen privaten ScriptDom-Parser:
  alle vier vollständigen korrigierten SQL-Dateien sind syntaktisch gültig
  und bestehen aus jeweils einem normalen T-SQL-Batch.

Diese Offlineergebnisse belegen keine native Ausführung der Korrektur.
Der noch offene gemeinsame Consumer-Gesamtfall benötigt einen separat
autorisierten endlichen Lauf mit frischem Abschlussaudit. Historische
Modul-/SSIS-Nachweise bleiben unverändert auf ihren ursprünglichen Scope
beschränkt. Keine vollständige Produkt-, Rechte- oder Plattformqualifikation,
keine Veröffentlichung und keine Installation auf einem Produktivziel.
