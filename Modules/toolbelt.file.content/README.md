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

## Abhängigkeiten

Keine Runtime-Modulabhängigkeit.

## Deployment

`Deployment/Deploy.sql` benötigt die SQLCMD-Variable
`DeploymentMode=local|central`. Zusätzlich muss `OPENROWSET(BULK...)` auf
SQL Server aktiviert sein (`ad hoc distributed queries`) oder der Aufrufer
besitzt `ADMINISTER BULK OPERATIONS`.

## Vertrag

- Nur Lesen; kein Schreiben im Version-1-Slice.
- Pfad muss absolut sein; UNC-Pfade sind erlaubt.
- Pfad muss unter einem Eintrag der Root-Allowlist liegen.
- Binärer Inhalt wird 1:1 als `varbinary(max)` zurückgegeben.
- Text wird nach BOM-Heuristik decodiert; unterstützt UTF-8, UTF-16 LE/BE,
  UTF-32 LE/BE; Fallback ist `Windows-1252` als 8-Bit-Codepage.
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
