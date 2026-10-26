# XLSX-Rohleser: Callerrechte für Blattliste und Zellen

Dieser Bericht dokumentiert den Rechte- und Ausgabewegumfang der bereits
bestehenden `toolbelt_file.USP_ListXlsxWorksheets` und
`toolbelt_file.USP_ReadXlsxWorksheetCells` in `toolbelt.file.xlsx-memory`
1.2.0. Die Tests verwenden ausschließlich das mitgelieferte synthetische
Workbook. Sie belegen ein enges Objektprofil in der ausgewählten
Ownershipkonfiguration; sie bestimmen keine mathematisch minimalen Rechte und
schließen andere mögliche Profile nicht aus.

## Nachgewiesenes Objektprofil

| Öffentlicher Aufruf | Direkte Ausgabe | Zusätzlich für `@ResultTable` |
|---|---|---|
| `USP_ListXlsxWorksheets` | `EXECUTE` auf der öffentlichen USP und `SELECT` auf `TVF_InternalXlsxSheets` | `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable` |
| `USP_ReadXlsxWorksheetCells` | `EXECUTE` auf der öffentlichen USP und `SELECT` auf `TVF_InternalXlsxCells` | `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable` |

Öffentliches `EXECUTE` allein ergab bei diesen Aufrufen 51529, weil das passende
interne table-valued CLR-Objekt für den Caller nicht sichtbar war. Der
`ResultTable`-Pfad prüft den Helpervertrag; ohne Helper-`EXECUTE` wird ebenfalls
51529 erwartet. Ohne öffentliches `EXECUTE` wurde 229 verlangt. Das sind
beobachtete Profile und Fehlerverträge dieser Prüfung, keine allgemeine
Zusage für andere Ownershiplayouts. Die öffentliche USP vergibt selbst keine
Rechte.

## Zielmatrix und Umfang

Die zwölf ausgewählten Kombinationen umfassen SQL Server 2019 mit CL150,
2022 mit CL150/160 und 2025 mit CL150/160/170, jeweils auf Windows und Linux.
Jede Kombination wurde lokal und direkt zentral ausgeführt: 24 Kontexte.

Je Kontext durchliefen die zwei öffentlichen APIs zusammen 14 getrennte
Objektrechtemasken: ohne Rechte, öffentliches `EXECUTE` allein, passende
interne `SELECT`-Rechte mit und ohne Helper, Helper ohne interne Sichtbarkeit,
interne Rechte ohne öffentliche Freigabe und erneuter Entzug. Jede Maske
prüfte direkte Ausgabe und `ResultTable`, also 336 Maskenzustände und 672
API-Routen.

| Ergebnis | Je Kontext | Insgesamt |
|---|---:|---:|
| Erfolgreiche Routen | 6 | 144 |
| Erwartete 51529-Denials | 10 | 240 |
| Strikte 229-Denials auf API-Routen | 12 | 288 |
| Zusätzliche strikte 229-Denials für Gegen-API und interne Objekte | 70 | 1.680 |
| Strikte 229-Denials insgesamt | 82 | 1.968 |
| Feste Ergebniszeilenorakel | 30 | 720 |

Die zusätzlichen 70 Denials je Kontext decken ausschließlich die jeweils andere
öffentliche Raw-API, `USP_InternalXlsxRead`,
`TVF_InternalListZipEntriesClr`, `TVF_InternalInterpretXlsxCell` und
`TVF_InternalFormatXlsxCell` ab. Daraus folgt keine Abweisungsaussage über jede
öffentliche ZIP-API oder jede öffentliche XLSX-Typ-/Format-API.

## Feste synthetische Ausgabeorakel

Die Blattliste prüft alle vier Felder bytegenau. Die Raw-Zellliste vergleicht
alle neun erwarteten Koordinaten und zwölf Spalten in beide Richtungen; NULL
und leere Strings bleiben unterscheidbar. Die Orakelwerte stammen aus der
festen Workbook-XML und dem bestehenden Raw-Vertrag, nicht aus einem zweiten
Produktaufruf. Beide Ausgabewege verwenden dasselbe Sollwertorakel.

Pro Kontext stehen drei ausgegebene Blattzeilen und 27 Zellzeilen (neun je
erfolgreicher Zellroute) den 720 Gesamtzeilen gegenüber. Die synthetischen
Zellen umfassen Shared-/Inline-Text, vorhandene leere und fehlende `v`-Werte,
Shared-Formeln samt Index, leeren Formelcache, Boolean, Fehlerwert und die
äußerste Zeile/Spalte. Vorheriger und nachheriger Callertransaktionszustand
wurde separat geprüft.

## Versuche, Kontrollen und Bereinigung

Es gab 15 native Zielversuche: zwölf Matrixfälle bestanden, zwei gezielte
Kontrollen wurden mit `FAILED_CLEANED` an ihren vorgesehenen Prüfstellen
abgewiesen, und ein älterer v1-Versuch scheiterte an einem fehlenden Argument
in einer internen Denialprobe. Für diesen Arityfehler behauptet der Bericht
keine SQL-Fehlernummer. Die Original-Fixture blieb bytegleich gespeichert; ein
separater AuditOnly-Projektionsrunset ordnete nur den alten Quellpin den
gespeicherten identischen Fixturebytes zu. Das ursprüngliche Runset und Journal
blieben unverändert.

Die falscher-Sollwert-Kontrolle wurde am Zell-Goldenvergleich abgewiesen:
`XLSX 9x12 byte-exact cell golden mismatch.` Die zusätzliche
Schema-SELECT-Kontrolle wurde vom Rechteguard abgewiesen:
`Broad caller role or schema/database permission detected.` Keine Kontrolle
änderte das Workbook oder wurde als positives Ergebnis gezählt.

Nach allen Verbrauchern bestanden 15 frische separate AuditOnly-Läufe. Die
Journale enthalten 27 eigene Datenbanknamen; alle 27 waren anschließend
entfernt und unabhängig als abwesend bestätigt. Der Trustzustand und die
Testkonfiguration wurden wiederhergestellt. Die Journale zählen 30 entfernte
Trusteintragsvorkommen über wiederholte Versuche; das ist keine Zahl
verschiedener Trusthashes. Reale Trusthashes, Endpoints, Zugangsdaten,
Parameterwerte und Runtimeausgaben bleiben privat.

Die Callerverbindungen liefen als verschlüsselte Functional-Tests mit dem
expliziten Trustwert des schema-validierten Vertrags. Das belegt keine
authentifizierte TLS-Verbindung; dieses TLS-Gate ist nicht ausgeführt.

## Bindung und reproduzierbare Offlineprüfung

Der Zwei-DLL-Treiber verwendete die paketierten ZIP-1.4.0- und XLSX-1.2.0-
Assemblies. Beide Binaries entsprachen zwei früheren reproduzierbaren Builds
mit übereinstimmenden vollständigen Compile-Inputs. Es wurde kein neuer Build
erstellt. Die öffentliche JSON-Projektion bindet die v2-Quellpins, den
deterministischen Composer, das synthetische Workbook und die zusammengesetzte
Fixture über SHA-256; sie enthält ausschließlich relative öffentliche
Quellpfade und keine privaten Pfade.

Die gezielte Offlineprüfung lautet:

```powershell
python -B Tests/Release/test_xlsx_raw_caller_evidence.py
python -B Tests/Release/test_xlsx_raw_caller_composer.py
python -B Tests/Release/compose_xlsx_raw_caller.py --output .runtime/xlsx-raw-caller-new
```

Der Composer setzt genau einmal den Binarymarker im kanonischen SQLtext ein.
Native Läufe benötigen ein frisches privates Runset mit Schema
`xlsx-raw-caller-contract/v1`, den schema-validierten Functional-Labvertrag,
zwölf expliziten Zielauswahlen, beide Deploymentexports, genau die beiden
gebundenen DLLs und vollständige Inputpins. Ein abgeschlossener Index darf
nicht wiederholt werden.

Der [maschinenlesbare Bericht](xlsx-raw-caller-profile.json) enthält die
Matrix, Profile, Zähler, Sourcepins, Kompositions-/Workbookbindung und
ausstehenden Gates. Die derzeitigen Source-Header-, Manifest- und Paketlabels
sind für das beobachtete Profil noch unvollständig; ihre gebundene Pflege ist
ein klarer Folgeschritt und ändert in diesem Caller-Nachweis keine Produktbytes.
Die Modulversion bleibt `partially validated`, `unreleased`. Head- und Main-CI werden getrennt im integrierenden PR nachgewiesen; Veröffentlichung ist nicht autorisiert. Vollständige Modul-, Client-,
Lifecycle-, Identitäts-, Heap-/Ressourcen- und sonstige Releasefreigaben sind
nicht durch diese Prüfung erteilt.
