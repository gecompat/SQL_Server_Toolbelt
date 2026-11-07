# JSON Constructors: direkte Aggregate-Minimalrechte

## Aktueller Stand

Der Benutzer hat am 2026-11-07 genau zwei zusätzliche Objektrechte freigegeben:
je ein `EXECUTE` auf `toolbelt_json.AGF_JsonArray` beziehungsweise `AGF_JsonObject`
für eine eigene temporäre Identität `WITHOUT LOGIN` in eigenen Testdatenbanken.
Keine Rollen-, Schema-, Datenbank- oder Servergrants, keine bestehende Identität.
Die früheren sechs USP-/ResultTable-Rechte enthalten diese Direktaufrufe nicht.

**Die native Aggregate-Minimalrechtequalifikation ist noch offen.** Der erste
Lauf blieb `FAILED_CLEANED`; sein frischer unabhängiger Abschlussaudit bestand.
Der korrigierte Gesamtlauf wurde noch nicht ausgeführt. Grüne Offline- oder
GitHub-Prüfungen werden nicht als nativer Rechte-PASS ausgegeben.

## Methode und vorbereiteter Vertrag

Der [Labtreiber](../../Tests/Release/Invoke-JsonConstructorsAggregateCallerLab.ps1)
führt die [SQL-Fixture](../../Tests/Release/JsonConstructors.AggregateCaller.sql)
auf zwölf Windows-/Linux-Engine-/CL-Paaren jeweils lokal und direkt zentral aus.
Windows:2019/CU32 CL150,2022/CU26 CL150/160,2025/CU8 CL150/160/170;
Linux:2019/2022/2025 jeweils latest mit denselben Engine-CLs. Clienthost Windows;
direkt zentral ist SameDB-Nutzung, keine CrossDB-Identität. Nur tatsächlich
ausgeführte Kontexte dürfen später als bestanden gelten.

Je Kontext sind zwei positive Profile vorgesehen: je Aggregat feste gruppierte
und leere Ausgaben mit ordinaler Sortierung und exaktem Unicodewert. Sechs
SQL229-Abweisungen prüfen vor Grant, das andere Aggregat während des Einzelgrants
und nach Revoke. `EXECUTE AS USER`/`REVERT` wechseln den tatsächlichen Caller.
Der eigene Benutzer wird anschließend entfernt. Engine-Defaultrechte wie
CONNECT werden als Ausgangszustand erfasst; genau ein zusätzlicher Objektgrant
muss vorhanden sein und nach Revoke exakt der ursprüngliche ACL-Zustand gelten.
Session-/Owner-Marker sind technische Guards, keine eigenständige Autorität.

Die unveränderten bekannten SAFE-DLLs Core1.0.0 und Constructors1.3.0 werden mit
der [Registry](../../Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json)
und kanonischen aktuellen Deploymentexports verglichen. Der alte Paketrecord
liefert nur den Archivpfad, keine aktuelle Gesamt-ZIP-Attestation. Quellen,
Methoden, DLLs, Exporte, Vertrag/Schema/Prompt und Host bleiben privat gepinnt.
Tatsächliche Engine/Plattform, installierte Marker und Bytes, Produktdefinitionen
und neutraler Sessionzustand werden geprüft. Cleanup verlangt eigene DB-ID,
Erstellungszeit/Owner und unveränderte Hashtrust-Fingerprints. Globale
Verbraucherfreiheit und vollständige Konfigurations-/Trustvergleiche schützen
andere Verbraucher. Ein frischer separater Audit bindet das finale Originaljournal.

## Erster Versuch und Adapterkorrektur

Ausführungsmethode:
[`ec40fe7e`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/ec40fe7e).
Vor Start galten höchstens36 Ziel-/Auditaufrufe,24 Datenbanken,45 Minuten und
keine Wiederholung. Integrierte Vorbereitung/Wiederherstellung pro Lauf benötigt
geplant12 Läufe plus12 Audits, also24 statt36 Dispatches. Verbraucht wurden zwei
Dispatches und zwei DB-Reservierungen; tatsächlich entstand eine lokale DB.
Der erste Windows2019-CL150-Lauf scheiterte nach Installation beim Setzen des
Owner-Sessionmarkers, vor Rechtefixture oder Benutzeranlage. **Null Rechteprofile
bestanden, null Grants und null Testidentitäten angelegt.** Die eigene DB wurde
entfernt, Konfiguration/Trust wiederhergestellt; der frische Audit bestätigte
Abwesenheit, ursprünglichen Journalhash, Inputpins und Servervorzustände.
Andere Kontexte wurden nicht begonnen. Der Fehlversuch bleibt erhalten.

Der vorhandene SQL-Helfer bindet Strings als `nvarchar(max)`. Dieser Wert kann
nicht unmittelbar an den `sql_variant`-Parameter von `sp_set_session_context`
übergeben werden. Die Korrektur deklariert lokal `@ContextOwner nvarchar(32)`
und übergibt ausschließlich diese begrenzte Variable. Eine Gegenprobe sichert
die tatsächliche Aufrufstelle. Neue native Bestätigung benötigt eine neue
endliche Freigabe; alte Zähler und Journale bleiben unverändert.

Sieben verbindungslose Offlineprüfungen bestehen beide Plattformzulassungen,
fehlende/typfalsche Rechtefreigabe, Ziel-/Pin-/Fristabweichungen, fremde selbst
gehashte DLLs, bytegleiche fremde Fixture, exakt zwei einzelne Grants/Revoke-
Orakel, typisierte Kontextübergabe und erhaltene Source-/Cleanup-Guards.
Fixture und beide expandierten dynamischen Werteorakel sind zusätzlich mit
ScriptDom Parser150 geprüft. Syntax/Quellchecks ersetzen keinen SQL-PASS.

## Grenzen

Die früheren [USP-Caller](JSON-CONSTRUCTORS-CALLER-QUALIFICATION.md),
[Linux-Caller](JSON-CONSTRUCTORS-LINUX-CALLER-QUALIFICATION.md),
[administrativen Clientmetadaten](JSON-CONSTRUCTORS-CLIENT-METADATA-QUALIFICATION.md)
und [aktuelle genuine Migration](JSON-CONSTRUCTORS-CURRENT-MIGRATION-QUALIFICATION.md)
behalten ihren jeweiligen Scope. Netzwerklogins, CrossDB-Identitäten,
Linux-Clienthost, Heap/Spill/Parallelität, zusätzliche Owner-/ACL-Upgrades und
vollständige Modul-/Releaseabnahme bleiben separat. Funktionale Verschlüsselung
mit explizitem Labtrust ist kein authentifizierter TLS-Nachweis. Produkt/API/DLL,
Manifest/Paket und teilweise validierter, unveröffentlichter Modulstatus bleiben
unverändert. Keine Veröffentlichung oder Tags.
