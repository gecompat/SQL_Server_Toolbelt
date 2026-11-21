# Gemeinsamer create-only-Installer: begrenzte Abnahme

## Aktuelle Skill-Erweiterung: native Abnahme offen

Die aktuelle Entwicklung erweitert Prozeduren um konstante Skillausgabe und die
Dateisystem-CLR-Einstiege um einen optionalen Hilfeschalter. Deren neu gebaute
Assembly ist nicht die Binary des folgenden nativen Consumer-Nachweises.
Der aktuelle gemeinsame Builder verlangt dafür einen frischen, vollständig
quellgebundenen lokalen Buildinput; eine frühere Assembly ohne Hilfeschalter
wird nicht als Ersatz übernommen. Der aktuelle begrenzte Modulinstaller ist
offline gebaut und syntaktisch geprüft. Neue Hilfe-/Binder-/Minimalrechte- und
Gesamtinstallationsabnahme stehen aus. Die folgenden datierten Nachweise bleiben
unverändert und gelten ausschließlich für ihre ursprünglichen Artefakte.

## Aktuelle Funktionskorrekturen: native Gegenproben offen

Der Quellabgleich vom 2026-11-21 hat fünf gezielt geänderte SQL-Dateien in
vier Modulen von 293 unveränderten Fachquellen getrennt. Dies betrifft neun
öffentliche Funktionen einschließlich ihrer delegierenden Fassaden:

- URI-Decoding weist Nicht-ASCII-Rohinput prozedural vor der Hexkonvertierung ab.
- JSON-Pfadexistenz vergleicht Schlüssel zusätzlich nach UTF16-Bytelänge;
  die rohe JSON-Quoting-/Tiefenprüfung erkennt nur literale ASCII-Strukturzeichen.
- Multipart-Identifier verwenden durchgehend physische UTF16-Einheiten und
  binäre Delimiter. Leer und Space sind verschieden; Supplementaryzeichen
  werden nicht durch einen SC-Zeichenschritt in einen Einheitenpuffer gekürzt.
- Directional-Trim verwendet für die NUL-Probe dieselben Zeichenpositionen
  wie für CHARINDEX und die Ausgabe, auch unter SC-/UTF8-Collations.

[current_source_deltas.py](../current_source_deltas.py) beschreibt ausschließlich
die exakten Änderungen am unveränderlichen Ausgangscode. Der strikte
Wiederverwendungsmodus lehnt diese Dateien weiterhin ab. Der explizite
`--check-current-deltas`-Modus prüft die Änderungen separat; er ist kein
Laufzeitnachweis und überträgt keine historischen Ergebnisse auf die Korrekturen.
Die vier aktuellen Modulmanifeste sind bis zur entsprechenden Abnahme teilweise
validiert. Ihre historischen Nachweise bleiben unverändert erhalten.

Die synthetische [native Gegenprobe](../../../Tests/Metadata/FunctionEdgeCases.sql)
enthält 19 deklarierte Assertions, ist derzeit **nicht ausgeführt** und setzt
eine bereits installierte eigene Testdatenbank voraus. Sie ändert weder
Rechte noch Konfiguration oder Daten. Für eine Ausführung unter ausgewählten
Nicht-SC-, SC- und UTF8-Datenbankcollations ist ein eigener konkreter endlicher
nativer Testscope erforderlich. Geschlossene frühere Testfenster bleiben
geschlossen. Die neue Hilfe-/Unicode-/Callerzustands-/Gesamtinstallerabnahme ist
zusätzlich erforderlich; grüne Offlineprüfungen ersetzen sie nicht.

## Bestandener begrenzter Gesamtfall vom 2026-11-20

Nach ausdrücklicher separater Freigabe bestand der abschließende Einmallauf
auf Windows SQL2025/CU8 CL170, lokales Windows-Profil, Hashweg. Der korrigierte
Produktquellstand ist `03c0d343`; die späteren Nachweis-/Dokumentationsänderungen
ändern die dabei gebundenen Produktquellen und Binärbytes nicht. Derselbe
private Adapter wie im zweiten Lauf verwendete die neu gebaute vollständige
SQL-Datei, eine eigene Datenbank und vorhandene administrative Testrechte.

Der tatsächliche Prozess-Exit ist 0, Status `PASS_CLEANED`, 13 Prüfungen:
die unten genannten ersten acht Prüfungen, 45 sichtbare Capability-Kandidaten
mit NULL-Version/Modus und `incomplete`, vollständige DebugScript-Erzeugung
allein aus DTSX-XML, unveränderte Kennzeichnung als ungeprüfter Entwurf,
zentraler Aufruf aus master mit typisiertem Startwert sowie bewusste
Ausführung des unveränderten vollständigen generierten SQL in der eigenen
synthetischen Quelldatenbank. Die Ausgabe enthielt die erwarteten zwei Zeilen.
Die Quelltabelle wurde erst nach der katalogfreien Erzeugung angelegt.

Der eigene separate Windows-Abschlussaudit ist PASS, Exit 0, zwei Prüfungen.
Sein Receipt bindet den exakten finalen Journalhash, bestätigt die Abwesenheit
der eigenen Datenbank und unveränderte finale Konfigurations-/Trustzustände.
Beide Aufrufe und die eine DB-Reservierung sind geschlossen; keine weitere
Wiederholung wurde gestartet. Methode, ursprüngliche Installerdateien,
Manifeste, Journale und Logs bleiben privat erhalten.

Dies belegt den beschriebenen gemeinsamen Consumer-Gesamtfall. Andere
Engine-/Plattformprofile, native TRUSTWORTHY-Wege dieses gemeinsamen Pakets,
Minimalrechte, GUI, produktive Installation und authentifiziertes TLS sind
damit nicht qualifiziert. Gültige frühere Modul-/SSIS-Nachweise behalten ihren
eigenen Scope; keine neue vollständige Produktqualifikation oder Veröffentlichung.

## Vorherige native Fehlläufe vom 2026-11-20

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

Die Offlineergebnisse bleiben von der oben separat ausgewiesenen nativen
Ausführung getrennt. Historische Modul-/SSIS-Nachweise bleiben unverändert
auf ihren ursprünglichen Scope beschränkt. Keine vollständige Produkt-,
Rechte- oder Plattformqualifikation, keine Veröffentlichung und keine
Installation auf einem Produktivziel.
