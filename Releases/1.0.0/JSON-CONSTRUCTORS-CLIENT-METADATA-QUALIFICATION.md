# JSON Constructors: direkte Clientmetadaten

Am 2026-11-07 (Europe/Vienna) bestanden die vorhandenen Constructor-1.3-USPs
und die beiden bestehenden AGF-Rückgabetypen eine aktuelle direkte ADO.NET-
Readerprüfung auf Windows- und Linux-SQL-Zielen. **24 Installationskontexte,
480 Profile, zwölf Gesamtläufe und zwölf frische unabhängige Audits** sind
erfolgreich: **PASS_FOR_DECLARED_CLIENT_METADATA_SCOPE**.

| Ausgewähltes SQL-Labziel | CLs | Installation je CL | Kontexte | Profile | Audits |
|---|---|---|---:|---:|---:|
| Windows2019/CU32 | 150 | lokal/direkt zentral | 2 | 40 | 1 |
| Windows2022/CU26 | 150,160 | lokal/direkt zentral | 4 | 80 | 2 |
| Windows2025/CU8 | 150,160,170 | lokal/direkt zentral | 6 | 120 | 3 |
| Linux2019/latest | 150 | lokal/direkt zentral | 2 | 40 | 1 |
| Linux2022/latest | 150,160 | lokal/direkt zentral | 4 | 80 | 2 |
| Linux2025/latest | 150,160,170 | lokal/direkt zentral | 6 | 120 | 3 |

Der Clienthost war Windows. Linux bezeichnet die SQL-Ziele. Direkt zentral ist
SameDB-Nutzung, keine neue CrossDB-Anmeldung. Die vorhandene administrative
Lab-Anmeldung wurde verwendet; **keine Rechtevergabe und keine neue Identität**.
Dies ist insbesondere kein neuer Lowpriv-Nachweis der direkten Aggregate.

## Geprüfte Readerprofile

Je Kontext bestehen genau20 Profile:

- Die vier USPs `USP_JsonArray`, `USP_JsonObject`, `USP_JsonArraysByGroup` und
  `USP_JsonObjectsByGroup`: jeweils leer/befüllt, zusammen acht SELECT-Profile.
  Geprüft sind Namen, Reihenfolge, `int`-/`nvarchar(max)`-TDS-Typen, Nicht-NULL-
  Schema, MAX-Spaltenlänge, feste Werte sowie keine zusätzlichen Resultsets.
  Leere gruppierte Ausgabe hat ihr Schema und keine Datenrow; ungruppierte
  leere Ausgabe liefert `[]` beziehungsweise `{}`.
- Vier Help-Profile prüfen die zwölf Metadatenspalten, Typen, acht Parameter-
  Defaults und Hilfepriorität trotz sonst ungültiger Eingaben ohne weitere
  Resultsets oder Meldungen.
- Vier ResultTable-Profile prüfen den leeren öffentlichen Tabellenweg ohne
  SELECT-Resultset. Das ist keine allgemeine Zusage über Debug-Meldungen.
- `AGF_JsonArray` und `AGF_JsonObject`: jeweils leer/befüllt, vier direkte
  Rückgabetyp-/Wertprofile. `nvarchar(max)`, vollständiger Wert und genau eine
  Row ohne Zusatzresultset müssen stimmen. Alias `JsonValue` ist probeeigen.
  Das AGF-Nullable-Metadatenbit wird privat beobachtet; dafür wird kein neuer
  öffentlicher Vertrag erfunden.

Damit sind192 USP-SELECT-,96 Help-,96 ResultTable- und96 AGF-Profile belegt.
Profile zählen komplette Orakelgruppen, keine hochgerechneten Einzelassertions.

## Quelle und Ausführung

Ausgeführter Snapshot:
[`8fa4a51d`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/8fa4a51d938c0074e2b86b792173969cd8d9ceaa).
Der [Labtreiber](../../Tests/Release/Invoke-JsonConstructorsClientMetadataLab.ps1)
verwendet den [Readeradapter](../../Tests/Release/JsonConstructors.ClientMetadata.ps1).
Dieser übernimmt den exakt ausgewählten Vier-USP-Loop des vorhandenen
[kanonischen Readers](../../Modules/toolbelt.json.constructors/Tests/Runtime/SelectMetadata.Contract.ps1)
per AST. Seine Orakel bleiben unverändert; nur die drei Befehls-Timeoutorte
verwenden den gemeinsamen Restzeitvertrag. Die umgebende alte Anmeldehülle wird
nicht ausgeführt. Der Adapter verlangt eine bereits offene geliehene Verbindung,
entfernt seinen eigenen InfoMessage-Handler und schließt nicht selbst die
Verbindung. Der Labtreiber besitzt und entsorgt sie.

Dies schließt eine echte Lücke: Der vorhandene Shelltreiber ruft den direkten
Reader nur im Labpfad vor seiner CL-Schleife lokal auf. Reguläre grüne
Containerjobs ersetzen daher keine vollständige aktuelle direkte Clientmatrix.
Bestehende Funktions-/Paket-/Callerbelege wurden nicht pauschal wiederholt.

Core- und Constructor-DLL bleiben exakt die bekannten SAFE-Bytes aus dem
aktuellen CLR-Installationsarchiv und der
[Artefaktregistry](../../Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json).
Der alte Paketbericht dient nur als Archivpfadquelle; sein historischer
Gesamt-ZIP-Hash wird nicht als frische Gesamtpaketattestation ausgegeben.
Kanonische aktuelle Deploymentexports, Quellen, Reader, Registry, Binärdateien,
Labvertrag/-schema/-prompt und Host sind privat gepinnt. Native Zielprüfung
erfasst Major/Plattform/Version und vorhandene administrative Berechtigung.
Installierte Marker/Assemblies, Produktdefinitionen und neutraler Sessionzustand
werden geprüft; keine Produkt-, Binär-, Manifest- oder Paketänderung.

Sechs Offlinegegenproben bestehen beide Plattformzulassungen ohne Lab/SQL,
Freigabetyp/Ziel-/Pin-/Fristabweichungen, fremde selbst gehashte DLLs, eine
bytegleiche fremde Orakeldatei, exakte Timeoutadaption/Frameablehnung und eine
geschlossene Verbindung ohne implizite Anmeldung. Die vier tatsächlich
expandierten AGF-Batches wurden zusätzlich mit Parser150 verbindungslos geprüft.

Nach der Ausführung wurde ausschließlich der missverständliche `RIGHTS`-Logtag
des Testtreibers an drei Ausgabestellen berichtigt. Ein deterministischer
Vergleich bindet diese reine Beschriftungskorrektur an die unveränderten
Reader-/SQL-/Cleanupabläufe des ausgeführten Snapshots. Originalmethode und
Journale bleiben erhalten; keine native Wiederholung.

## Cleanup und Grenzen

Vor Start wurden24 Ziel-/Auditdispatches,24 eigene DBs und45 Minuten für beide
Plattformen gemeinsam ohne Wiederholung festgelegt. Konfiguration/Trust werden
innerhalb jedes Laufs vorbereitet und wiederhergestellt, nicht in ungezählten
Zusatzdispatches. Alle24 Aufrufe und24 DBs sind geschlossen; kein nativer
Fehlversuch. Alte Wellen und ihre Fehler/Zähler bleiben unverändert.

Die eigenen DBs werden nur nach voller ID-/Erstellungszeit-/Ownerprüfung
entfernt. Eigener Hashtrust benötigt unveränderte Fingerprints und globale
Verbraucherfreiheit. Fremde Konfiguration/Trustdrift blockiert Cleanup statt
Überschreiben. Zwölf frische separate Audits binden unveränderte finale
Originaljournale, DB-Abwesenheit und vollständigen Konfigurations-/Trustvergleich.
Ein privater Nachprüfer erwartete zunächst den Statustoken eines anderen
Treibers. Die Zuordnung wurde exakt auf den bereits ausgeführten Constructor-
Cleanup `REMOVED` korrigiert; Originale/Audits unverändert, kein SQL erneut.

Functional-Verschlüsselung mit explizitem Labtrust ist keine authentifizierte
TLS-Abnahme. Netzwerk-/CrossDB-Identitäten, Linux-Clienthost, direkte AGF-
Minimalrechte, weitere Owner-/Lifecycle-/Ressourcenverträge und gesamte Modul-
oder Releaseabnahme bleiben separat. Historische Records werden nicht geändert.
Modulstatus weiterhin teilweise validiert, unveröffentlicht; keine Tags.
