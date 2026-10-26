# XLSX-Callerrechte im Manifest und CLR-Paket

Diese Pflege übernimmt die bereits getrennt qualifizierten XLSX-Raw- und
Zell-Callerrechte in das Modulmanifest und den bestehenden CLR-Installationssatz.
Sie erteilt keine Rechte und ändert weder Modulstatus noch Veröffentlichung.

## Nachgewiesene Aufrufprofile

| Öffentlicher Aufruf | Direkte Ausgabe | Zusätzlich für `@ResultTable` |
|---|---|---|
| `toolbelt_file.USP_ListXlsxWorksheets` | `EXECUTE` auf der USP und `SELECT` auf `toolbelt_file.TVF_InternalXlsxSheets` | `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable` |
| `toolbelt_file.USP_ReadXlsxWorksheetCells` | `EXECUTE` auf der USP und `SELECT` auf `toolbelt_file.TVF_InternalXlsxCells` | `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable` |
| `toolbelt_file.TVF_InterpretXlsxCell` und `TVF_FormatXlsxCell` | jeweils `SELECT` auf der öffentlichen TVF | nicht als Raw-Reader-ResultTable-Profil qualifiziert |

Das ist das in den gebundenen Callerberichten geprüfte schmale Objektprofil,
keine Behauptung mathematischer Minimalität. Öffentliches `EXECUTE` ohne
passende interne FT-Sichtbarkeit ergab in diesen Profilen 51529. Die interne
FT wird dadurch keine öffentliche API. Installation und Deployment vergeben
keine Callerrechte.

## Gebundene Berichte und Quellkommentargrenze

Die unveränderten [Raw-Callerberichte](XLSX-RAW-CALLER-PROFILE.md) und
[Zell-Callerberichte](XLSX-CELL-CALLER-QUALIFICATION.md) behalten ihre
ursprünglichen Ausführungspins. [xlsx-metadata-update.json](xlsx-metadata-update.json)
bindet beide Berichte, den ursprünglichen Manifestpin, die neue exakte
`permissions_required`-Fassung und die bestehende Paketbasis. Die bereits
korrekten API-Dokumentationen bleiben maßgeblich; der begleitende Releasepfad
und die im Paket enthaltenen XLSX-Leseseiten werden mit SHA-256 gebunden.

Historische Rechtekommentare in SQL-Quellheadern bleiben bytegleich, damit kein
ausführbarer SQL-Quellpayload geändert wird. Maßgeblich für den aktuellen
Callerwortlaut sind das Manifest, diese Übersicht und die beiden unveränderten
Callerberichte; die alten Headerkommentare sind kein alternatives aktuelles
Rechteprofil.

## CLR-Paket ohne Runtime-Neuqualifikation

Das Paket baut auf dem exakt gebundenen vorherigen CLR-Installationssatz auf.
Es erhält ausschließlich die aktuelle XLSX-Modulmanifestkopie und sieben
registrierte XLSX-Lesepfade sowie den additiven
`XLSX-METADATA-UPDATE.json`-Beleg und die aktualisierte `CLR-PACKAGE.json`-
Dateiliste samt Evidenzverweis. Der bestehende CSV-Metadatenbeleg bleibt
unverändert enthalten. Alle SQL- und DLL-Dateien, die native
`QUALIFICATION.json`, Installer, Lizenz und Drittanbietertexte bleiben
bytegleich. Es wurde kein Build und kein nativer SQL-Versuch für diese
Metadatenpflege ausgeführt.

Das Modul bleibt `partially validated` und `unreleased`. Die bestehende
Qualification-CI wird am integrierenden PR-Head und anschließend auf Main
nachgewiesen. Veröffentlichung, Tags und GitHub-Release sind nicht
autorisiert.
