---
name: "toolbelt-archive-tvf-internalzipwritername"
description: "Interner strenger UTF16-/UTF8-Namensencoder mit einer Writer-Statuszeile."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-memory"
schema_name: "toolbelt_archive"
object_name: "TVF_InternalZipWriterName"
object_type: "CLR_TVF"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@Name", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Relativer Dateientryname,1..MaxUnits UTF16-Einheiten. Keine führenden/abschließenden Slashes,Backslash,Doppelpunkt,NUL oder leeren/./..-Segmente. Wohlgeformtes UTF16. SqlString-Marshalling kann vor dieser Längenprüfung materialisieren."}, {"name": "@MaxUnits", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "NichtNULL,1..2048. Keine SQL-Defaults. Der öffentliche Reader bleibt unabhängig bei1024Namenseinheiten."}]
source_paths: ["Modules/toolbelt.archive.zip-memory/Source/ZipWriterClr.sql", "Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs", "Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs"]
review_status: "verified"
source_module_version: "1.4.0"
public_entrypoints: ["toolbelt_archive.USP_CreateZipFromEntries"]
---

# TVF_InternalZipWriterName

## Zweck und Einsatzfälle

Interner strenger UTF16-/UTF8-Namensencoder mit einer Writer-Statuszeile.

## Voraussetzungen

ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|
| `@Name` | `nvarchar(max)` | kein Default | Input | Relativer Dateientryname,1..MaxUnits UTF16-Einheiten. Keine führenden/abschließenden Slashes,Backslash,Doppelpunkt,NUL oder leeren/./..-Segmente. Wohlgeformtes UTF16. SqlString-Marshalling kann vor dieser Längenprüfung materialisieren. |
| `@MaxUnits` | `int` | kein Default | Input | NichtNULL,1..2048. Keine SQL-Defaults. Der öffentliche Reader bleibt unabhängig bei1024Namenseinheiten. |

InternerCLR-Einstieg:alleArgumenteexplizit,keineSQL-Defaults,keinHilfe-/ResultTableparameter. ÖffentlicheFassadebevorzugen;notwendigegezielteProvider-SELECT-Rechtebleibenmodulabhängig.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `ErrorNumber` | `int` | NULL implizit; Writer0=Erfolg;ReaderNULL=Erfolg;sonst erwarteterFehlercode |
| `ErrorMessage` | `nvarchar(4000)` | NULL implizit; NULL beiErfolg,erwarteteFehlermeldungbeiFehler |
| `Payload` | `varbinary(max)` | NULL implizit; WriterArchiv beziehungsweiseUTF8Name,beiFehlerNULL |

Genau eineStatuszeile;WriterErfolg0,ReaderErfolgNULL. NiemalsbeideKonventionenvermischen.

## Aufrufbeispiele

```sql
-- InternerProvider:öffentlicheFassadeverwenden.
EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche Memory-USP und gezielte SELECT-Rechte auf benötigte interne CLR-TVFs gemäß Modulvertrag. Writer braucht die ResultTable-Schnittstelle für beide Ausgaben; Reader Helper-EXECUTE nur bei ResultTable. Leserechte auf Caller-Temps und Metadatensicht für Writer, tempdb.sys.columns und spezifische sys.parameters-Sicht. Interne Kennzeichnung ist kein Verbot notwendiger Providerberechtigungen, aber kein Freibrief für allgemeine Direktnutzung. Keine Filesystemrechte für den Memorypfad.

## Ressourcenbedarf

Name1..MaxUnits, MaxUnits1..2048UTF16-Einheiten. UTF8-Payload höchstens3*MaxUnitsBytes. Keine Archivpayload, kein Timer, keine Dateioperation. SqlString-Marshalling und UTF8-Kopie sind kein Peakheap- oder vorheriger LOB-Intakevertrag.

## Nebenwirkungen

Reine interne Name-Status-TVF: Name und Limit prüfen; relative Dateisegmente ohne Backslash, Doppelpunkt, NUL, führenden/abschließenden Slash, leere Segmente oder ./.. verlangen. UTF8Encoding(false,true) verweigert kaputtes UTF16 statt Ersatzzeichen. Erfolg: ErrorNumber0, ErrorMessageNULL und Payload mit strikten UTF8-Namensbytes. Eine erwartete Fehlerzeile enthält keine Payload. Keine SQL- oder Dateiabfrage. SqlString-Marshalling kann vor der Längenprüfung materialisieren; kein allgemeiner LOB-Intakebeweis.

## Fehlerbehandlung

Reader:51320 Argumente,51321 Struktur/Encoding/Stream,51322 Name fehlt,51323 gesuchter Name doppelt,51324 Encryption verboten,51325 Ressourcen,51326 Ratio,51327 Format/Method,51328 Integrität,51329 Wrapper/Dependency. Writer:51350 Argumente,51351 SQL-Inputshape,51352 Name,51353 Namensduplikat,51354 Ressourcen,51355 Format/Overflow,51356 Timeout,51357 Dependency,51358 Transport,51359 Providerstatus. Status-TVFs wandeln nur explizit gefangene Fehler um; unerwartete CLR-/Enginefehler bleiben Originalexceptions. Reader-ErfolgNULL, Writer-Erfolg0. Öffentliche Fassaden werfen statt einer Teilpayload.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/ZIP-/Dateipublikationsabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. CRC32, Status und PathSafe sind keine Signatur, Malwareprüfung oder Herkunftsauthentifizierung. Kein allgemeiner ZIP64-, Encryption-, Streaming- oder Mehrdatei-Unpacker. Keine Installations- oder Rechteattestation. ZIPnamen, Payloads, Dateipfade und Runtimebefunde privat halten.
