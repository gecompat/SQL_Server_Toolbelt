# ZIP Memory Extraction

**Modul-ID:** `toolbelt.archive.zip-memory`
**Version:** `1.0.0`
**Status:** `implemented`; Runtime `not executed`

## Zweck

Dieses Modul extrahiert einen einzelnen ZIP-Eintrag aus einem in-memory
ZIP-Container (`varbinary(max)`) ohne Dateisystemzugriff.

Der Scope von Version 1.0.0 ist bewusst eng:

- kein Dateisystemzugriff;
- keine Archiv-Erzeugung;
- keine rekursive Entpackung;
- keine Passwortentschluesselung.

## Oeffentliches Objekt

| Objekt | Typ | Schema | Zweck |
|---|---|---|---|
| `USP_ExtractZipEntryFromBinary` | `USP` | `toolbelt_archive` | Extrahiert genau einen benannten ZIP-Eintrag aus einem `varbinary(max)`-Archiv. |

## Abhaengigkeiten

| Modul | Mindestversion | Installationsort | Begruendung |
|---|---|---|---|
| `toolbelt.core.result-table` | `1.0.0` | lokal oder zentral | `@ResultTable`-Integration gemaess USP-Vertrag. |

## Deployment

```sql
:r .\Deployment\Deploy.sql
```

Die SQLCMD-Variable `DeploymentMode` muss `local` oder `central` sein.

## Sicherheits- und Robustheitsvertrag

- Entry-Namen werden als untrusted input behandelt und nur intern verglichen.
- Es erfolgt keine Pfadauflosung und kein Dateischreiben.
- Harte Default-Limits:
  - `@MaxEntryBytes = 104857600`
  - `@MaxCompressionRatio = 200.00`
- Duplicate Entry-Namen werden als expliziter Fehler abgelehnt.
- Verschluesselte Eintraege werden bei `@FailIfEncrypted = 1` abgelehnt.
- Bei `@FailIfEncrypted = 0` wird der Eintrag als verschluesselt signalisiert,
  aber ohne Payload geliefert.

## Dokumentation

- Objekt: `Documentation/USP_ExtractZipEntryFromBinary.md`
- Architektur: `../../Documentation/Architecture/ZIP_ARCHIVE_MODULE_DESIGN.md`
- Tests: `Tests/`

## Einschraenkungen

Version 1.0.0 unterstuetzt nur ZIP-Eintraege mit Compression Method `0`
(`Stored`). Andere Methoden, insbesondere Deflate (Method `8`), werden
kontrolliert mit einem Vertragsfehler abgelehnt.

ZIP64 ist nicht Teil des Vertrags. CRC32 wird aus ZIP-Metadaten übernommen und
auf Header-Konsistenz geprüft, aber nicht für den extrahierten Payload neu
berechnet. Die Entry-Namensdekodierung hat keinen vollständigen UTF-8-/CP437-
Kompatibilitätsvertrag.

Der geplante, jedoch nicht implementierte C#-SQL-CLR-Provider ist getrennt in
[ZIP_CLR_PROVIDER_DESIGN.md](../../Documentation/Architecture/ZIP_CLR_PROVIDER_DESIGN.md)
dokumentiert.

## Teststatus

Kein Test gilt ohne Ausfuehrung als `validated`.
Aktueller Runtime-Status ist `not executed`.
