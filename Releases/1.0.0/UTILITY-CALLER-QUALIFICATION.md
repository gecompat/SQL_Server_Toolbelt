# Native Utilityfunktionen mit getrennten Callerrechten

Die damals offene Manifest-/Paketlücke ist durch die spätere
[exakte Metadatenkorrektur](CALLER-METADATA-UPDATE.md) geschlossen.
Der folgende Ausführungsbericht behält seine ursprünglichen Quellen und Grenzen.

Stand 2026-10-25, dritte vorab geplante Welle des dritten endlichen Rahmens.
16 öffentliche Bit-, Trim-, Split-, Identifier- und SemVer-Funktionen bestehen
auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral mit einzelnen Objektgrants.
Produkt-SQL, Manifeste, Modulstatus und Pakete bleiben unverändert, unveröffentlicht.

## Profile und ausgewählte Orakel

| Familie | Profile | Feste fachliche Prüfungen |
|---|---|---|
| BitOperations1.0.0 | fünf SELECT-TVFs | Vorzeichenbit, logischer Shift, umgekehrter/weiter Shift, Bitcount, NULL sowie Offset-/Bitwertflags |
| DirectionalTrim1.0.0 | zwei SELECT-TVFs | Längen-/Binärvergleich von Unicode-/Varchar-Trim und NULL |
| SplitCharacters1.0.0 | Legacy- und Status-TVF mit SELECT | exakte Token/Ordinal-Menge mit Leerwert; Legacy-NULL ohne Zeilen; SQL_NULL/EMPTY/LIMIT ohne Tokenpräfix |
| Identifier1.0.0 | Parse-TVF mit SELECT, Quote-SVF mit EXECUTE | Multipart-Komponenten, sicher quotierter Name mit Escape, NULL/ungeschlossene Delimiter |
| SemanticVersion1.1.0 | drei SELECT-TVFs, zwei EXECUTE-SVFs | Parserfelder, Prereleasevergleich, ignorierte Buildmetadaten, NULL/ungültige Eingaben und opake Sort-Key-Reihenfolge |

Sort Keys werden anhand ihrer zugesagten SemVer-Reihenfolge und der Gleichheit
bei gleicher Präzedenz geprüft, nicht anhand eines unveränderlichen externen
Binärformats. TVF-Orakel erfassen Kardinalität und NULL ausdrücklich; die
Status-Split-Grenze wird mit einem kleinen überlangen Eingang vor Verarbeitung
abgewiesen. Die übrigen vollständigen API-/Last-/Clientverträge werden hier
nicht wiederholt oder pauschal bestätigt.

Die Closure enthält diese fünf Module sowie GenerateSeries1.0.0 und
ResultTable1.0.0. Der eigene Benutzer ohne Login erhält nacheinander ein SELECT
beziehungsweise EXECUTE. Fehlende und entzogene Rechte, alle jeweils15 anderen
öffentlichen Funktionen sowie drei direkte GenerateSeries-Aufrufe und der
ResultTable-Helper müssen mit genau SQL229 scheitern. Intern benötigte Aufrufe
laufen über die vorhandene Ownershipkette ohne direkten Zusatzgrant. Breite
Rollen-, Schema- und Datenbankrechte entfallen. Vorhandene Betreiber- und
Ressourcenpolicies bleiben verbindlich; dies sind synthetische technische
Callerprofile und keine allgemeine Produktions-Rechteempfehlung.

Die älteren generischen Rechteangaben der Identifier-/SemVer-Manifeste und
der Identifier-Scalar-Sourceheader sind für Scalar-EXECUTE ungenau. Sie bleiben
als konkrete Metadaten-/Kommentar-/Paketlücke im [Backlog](../../.ai/BACKLOG.md)
erhalten; diese Welle verändert keine eingefrorenen Produktquellen oder
Manifestbindungen. Das tatsächlich geprüfte Einzelgrantprofil ist explizit.

## Matrix, Kontrollen und Bereinigung

Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170
bestanden jeweils lokal und direkt zentral:384 Einzelgrantprofile, davon312
TVF- und72 Scalarprofile, sowie8.064 strikte SQL229-Abweisungen. Falscher
Shift-Festwert und zusätzliches direktes GenerateSeries-Recht wurden aus den
erwarteten Gründen verworfen; beide bleiben FAILED_CLEANED.

Alle14 aktuellen Versuche bestanden unabhängige Input-/Abwesenheitsaudits.
Frische Audits nach dem letzten Verbraucher bestätigen alle26 eigenen
Datenbanknamen als abwesend. Eigene Principals und Fixturezustände sind entfernt.
Keine Serverkonfigurations-, Login-, CLR-/Trust- oder fremden Änderungen.
Private Identitäten, Verbindungsdaten und Journale bleiben ausschließlich lokal.

## Bindung und offene Grenzen

Die feste `Utility.FunctionCases.sql` nutzt den unveränderten
[gemeinsamen Rechteablauf](../../Tests/Release/README.md#native-funktions-callerrechte-prüfen).
Die [JSON-Projektion](utility-caller-qualification.json) bindet alle konsumierten
Source-/Treiber-/Exportbytes, die reproduzierbare Bytekomposition und die
wirklich ausgeführten Fälle. Öffentliche Teile entsprechen den kanonischen
Git-Bytes; bestehende innere/äußere Fristen und sichere eigene Bereinigung gelten.

Keine pauschale API-/Modul-/Client-/Lifecycle-/Ressourcenabnahme und keine
REFERENCES-/DDL- oder echte CrossDB-Identitätsqualifikation. Authentifiziertes
TLS, getrennte Paket-/Metadatenpflege und weitere [Releasegates](RELEASE-GATES.md)
bleiben separat. Functional verwendet Verschlüsselung und den expliziten
schema-validen Lab-Trustwert ohne Fallback; Modul- und Release-Status unverändert.
