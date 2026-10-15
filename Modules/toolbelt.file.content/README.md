# File Content

**Modul-ID:** `toolbelt.file.content`
**Version:** `1.0.0`
**Implementierungsstatus:** `implemented`
**Validierungsstatus:** `partially validated`
**Release-Status:** `unreleased`

## Zweck

Das Modul liest Text- und Binärdateien aus dem Dateisystem über einen
kontrollierten, allowlist-basierten Vertrag. Der erste Slice verwendet
`OPENROWSET(BULK...)` als Lesen-Provider und erlaubt nur Pfade, die unter
einem konfigurierten Root liegen.

## Öffentliche Objekte

| Objekt | Typ | Zweck |
|---|---|---|
| `toolbelt_file.USP_LoadBinaryFile` | USP | Liest eine Datei als `varbinary(max)`. |
| `toolbelt_file.USP_LoadTextFile` | USP | Liest eine Datei als `nvarchar(max)` mit Encoding-/BOM-Metadaten. |

## Konfiguration

`toolbelt_file.FileContentRootAllowlist` enthält die erlaubten Root-Pfade.
Nur absolute lokale Pfade und UNC-Pfade sind zulässig. Relative Pfade,
`..`-Traversierung und Pfade außerhalb der Allowlist werden abgelehnt.
Roots werden nach Slash-Normalisierung literal und case-sensitiv verglichen.
Ein abschließender Slash ist optional; `/safe` erlaubt `/safe/file.bin`,
aber nicht `/safe-old/file.bin`. `%`, `_` und Klammern sind normale Pfadzeichen.

## Abhängigkeiten

Keine Runtime-Modulabhängigkeit.

## Deployment

`Deployment/Deploy.sql` benötigt die SQLCMD-Variable
`DeploymentMode=local|central`. Zusätzlich muss `OPENROWSET(BULK...)` auf
SQL Server aktiviert sein (`ad hoc distributed queries`) oder der Aufrufer
besitzt `ADMINISTER BULK OPERATIONS`.
Die beiden Procedure-Dateien binden im SQLCMD-Modus das gemeinsame
Queryfragment `Source/FileContentRootPredicate.sql` ein.

## Vertrag

- Nur Lesen; kein Schreiben im Version-1-Slice.
- Pfad muss absolut sein; UNC-Pfade sind erlaubt.
- Pfad muss unter einem Eintrag der Root-Allowlist liegen.
- Binärer Inhalt wird 1:1 als `varbinary(max)` zurückgegeben.
- Text wird aus einem Byte-Snapshot nach BOM decodiert: UTF-8 und UTF-16 LE;
  UTF-16 BE und UTF-32 werden abgewiesen. Ohne BOM gilt `Windows-1252`.
- Fehler werden als standardisiertes Resultset mit `IsValid = 0` und
  `ValidationCode` zurückgegeben, soweit fachlich klassifizierbar.

## Dokumentation

- [USP_LoadBinaryFile](Documentation/USP_LoadBinaryFile.md)
- [USP_LoadTextFile](Documentation/USP_LoadTextFile.md)
- [Architekturvertrag](../../Documentation/Architecture/FILE_CONTENT_MODULE_DESIGN.md)
- [Beispiele](Examples/FileContent.sql)
- [Testmatrix](Tests/FILE_CONTENT_CONTRACT_TEST_MATRIX.md)

Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben Releasevalidierung.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-07`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37687448814`
- Scope: Commit 8effcee91106cb4b8924c7a839928d550c0653b6: befüllter 1.0.0-Repeat zweimal lokal und zentral, SQL Server 2019/150, 2022/160 und 2025/170 Linux; exakte Zeilen/Identity/Katalog/Annotationen und Uninstall; vorhandene Permissions nur beobachtet, keine Benutzergrants erzeugt; bestehende Datei-I/O-Suite anschließend erfolgreich; Windows/weitere Repeat-CLs/Minimalrechte/historische Migrationen offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

SC-040: USP_LoadTextFile verwendet genau einen SINGLE_BLOB-Snapshot. Bytezahl, BOM und Inhalt stammen aus derselben Aufnahme. UTF-8/UTF-16-LE-BOM wird vor Dekodierung entfernt; UTF-8 wird mit expliziter UTF8-Collation und binärem Roundtrip geprüft, UTF-16-LE verlangt gerade Bytezahl. Windows-1252 wird mit expliziter 1252-Collation auch auf Linux dekodiert. UTF-16-BE/UTF-32 bleiben ausgeschlossen. MaxBytes schützt nach der ersten Aufnahme; keine vorgezogene Heapgarantie.

Details und abgegrenzte Nachweise: [Security-Härtung](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).
