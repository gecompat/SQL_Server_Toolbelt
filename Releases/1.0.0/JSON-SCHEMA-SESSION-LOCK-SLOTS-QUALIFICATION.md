# JSON Schema: Caller-, Sperr- und Fremdslotmatrizen

Stand 2026-11-11: **PASS_FOR_DECLARED_FIVE_POINT_MATRIX**.
Die fünf ausgewählten Restmatrizen sind auf zwölf unterstützten Engine-/CL-
Paaren lokal und direkt zentral geschlossen: **672 eindeutige Profile**,
davon **652 neu nativ geprüft und20 gültig wiederverwendet**. Alle zwölf
Gesamtläufe und zwölf frischen unabhängigen Audits bestanden beim ersten
Versuch. Keine neue Produktfunktion oder Modulgesamtaufwertung.

## Auftrag und fünf konkrete Punkte

Der Benutzer beauftragte am 2026-11-11 die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuschließen, gültige Nachweise wiederzuverwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Dies ist ein neues fachlich abgegrenztes Paket, kein Neustart einer geschlossenen
Welle. Rechte, Identitäten, Owner, Infrastruktur und Veröffentlichung bleiben
außerhalb dieses Testauftrags.

| Punkt | Vertrag je Modus | Belegt / geplant |
|---|---|---|
| 1 | Deploy/Uninstall unter gesunder Callertransaktion bei fehlenden Toolbelt-Modulen; alle vier XACT_ABORT-/NOCOUNT-Kombinationen | 192 / 192 |
| 2 | Deploy/Uninstall unter denselben vier Callerprofilen bei installiertem aktuellem Schema/Core | 192 / 192 |
| 3 | Deploy unter jeweils exklusiv gehaltener gemeinsamer Core- beziehungsweise Schema-Modulsperre ablehnen; nach verifizierter Freigabe erfolgreich installieren | 96 / 96 |
| 4 | Dieselben beiden Sperrkonflikte beim installierten Uninstall; nach Freigabe erfolgreich entfernen | 96 / 96 |
| 5 | Fremde Tabellen im öffentlichen beziehungsweise internen reservierten Objektslot vor Mutation ablehnen, jeweils Deploy/Uninstall | 96 / 96 |

Die [vorherige Fünfpunktmatrix](JSON-SCHEMA-FIVE-BOUNDARIES-QUALIFICATION.md)
für Modul-/Assembly-/Objektmarker, reservierte Caller-Temp-Tabelle und exakte
Eingabegrenzen bleibt unverändert gültig und wurde nicht wiederholt.

## Physische Zielmatrix

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | 56 neue Profile und frischer Audit PASS |
| Windows | SQL2022/CU26 | 150,160 | je 56 neue Profile und frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160 | je 56 neue Profile und frischer Audit PASS |
| Windows | SQL2025/CU8 | 170 | 36 neue plus20 gebunden wiederverwendete Profile; frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 56 neue Profile und frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je 56 neue Profile und frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je 56 neue Profile und frischer Audit PASS |

Der [Adapter](../../Tests/Release/Invoke-JsonSchemaLifecycleRestLab.ps1) bindet
schema-validierte explizite READY-Ziele und prüft tatsächlich Engine, Plattform
und CL. Functional verwendet Verschlüsselung und den unveränderten expliziten
Lab-Trustwert; keine daraus abgeleitete TLS-Serveridentitätsabnahme. Kanonische
vollständige öffentliche Scripts werden über die bestehenden Include-/Variablen-
Funktionen expandiert und per ADO.NET-Batching ausgeführt. Kein zusätzlicher
SQLCMD-CLI-, SSMS-GUI-, Windows-Anmelde- oder CrossDB-Netzwerkidentitätsnachweis.

Die bekannten unveränderten Core-/Schema-DLLs stammen aus dem qualifizierten
Paket und werden gegen Registry, Projektdateien und kompilierte Quellen geprüft.
ResultTable/Core sind explizite synthetische Testvoraussetzungen; kein Neubuild,
keine automatische Dependencyinstallation durch das geprüfte Produkt.

## Tatsächliche Orakel und Wiederverwendung

Die [Fixture](../../Tests/Release/Runtime/JsonSchema.LifecycleRest.Contract.ps1)
verwendet bestehende gesunde Caller-, Savepoint-, Snapshot- und Observerfunktionen.
Jeder neue Callerfall prüft exakt SQL50000/State1/Class16 und den öffentlichen
Guardtext, dieselbe gesunde Transaktion/Sitzung, tatsächlich wirksame und
erhaltene Sessionoptionen, Zeugenwert300 vor/nach Abweisung, Savepointrollback200
und vollen Rollback100. Der unabhängige Observer bestätigt Transaktionsaktivität
und anschließend neutrale Sitzung ohne AppLocks. Alle374 neuen Callerreceipts
bestanden. QUOTED_IDENTIFIER ist ON, IMPLICIT_TRANSACTIONS OFF.

Die Sperrfälle verwenden eine getrennte eigene Holderverbindung mit gesunder
Transaktion und tatsächlich gewährter exklusiver Sperre. Die vollständigen
öffentlichen Scripts müssen mit genau55637/State1/Class16 und ressourcengenauem
Fehlertext unverändert ablehnen. Holder und Sperre bleiben erhalten; nach
bestätigtem Rollback und lokaler/externer Neutralität muss dieselbe Operation
erfolgreich sein. Core/ResultTable bleiben unverändert. Deploy bestätigt die
bekannte sichtbare SAFE-Schemaassembly; Uninstall deren vollständige Entfernung.

Die Fremdslotfälle erzeugen ausschließlich eigene synthetische Tabellen unter
`USP_ValidateJsonSchema` beziehungsweise `FT_ValidateJsonSchemaInternal` und
erhalten deren Zeugenwert701. Beide Lifecycleoperationen müssen exakt55634/1/16
vor Mutation ablehnen. Katalog-/Definition-/Owner-/Berechtigungs-/Assembly-
Snapshots einschließlich typisierter Rohproperties bleiben erhalten. Nur die
eigenen unveränderten Fixtures werden anschließend entfernt.

Zwanzig bereits bestandene Profile auf Windows2025/CU8 CL170 lokal werden
aus den unveränderten Originalen übernommen:

- Sechs Empty-Modulcaller aus [OFF/ON](JSON-SCHEMA-NOCOUNT-QUALIFICATION.md)
  und [ON/OFF, ON/ON](JSON-SCHEMA-XACT-ABORT-QUALIFICATION.md).
- Vier installierte Uninstallcaller aus dem [OFF/OFF-Original](json-schema-caller-transaction-qualification.json)
  und der [installierten Sessionergänzung](JSON-SCHEMA-INSTALLED-SESSION-QUALIFICATION.md).
- Acht Abweisungs-/Freigabeprofile aus [Deploy](json-schema-deploy-lock-qualification.json)
  und [Uninstall](json-schema-uninstall-lock-qualification.json), zwei Ressourcen.
- Zwei Deploy-Abweisungen fremder Tabellen aus dem [Kollisionsbericht](json-schema-deploy-collision-qualification.json).

Die öffentlichen Originale besitzen jeweils einen bestandenen finalen Audit;
ihre ausgeführte Schema-Deploymentclosure ist byte-identisch. Die drei privaten
Callerjournale sind zusätzlich mit Originalinputs, exaktem Kontext und frischem
Audit gebunden. Die aktuelle installierte Sessionquelle bindet auch die heutigen
öffentlichen Definitionen; Setup/Teardown mit diesen Definitionen werden im
neuen Lauf weiterhin tatsächlich ausgeführt. Später geänderte Hilfetextkörper
machen nicht pauschal alle alten Harness-/Produktbytes aktuell. Bestehende
Sperr-/Guardorakel und aktuelle Definitionsinstallation werden ausdrücklich
zusammengesetzt, keine historischen Fehler zum PASS umgedeutet.

Das neue Empty-Modul-OFF/OFF-Profil wird auf dem bisherigen Ziel tatsächlich
ergänzt: der frühere OFF/OFF-Deploy hatte bereits installierte Dependencies und
belegt diesen abweichenden Ausgangszustand nicht. Andere grüne Profile werden
nicht wiederholt.

## Native Quelle und Quittungspräzisierung

Nativer Methodencommit: `a0901b6a`. Alle zwölf ursprünglichen Koordinatoren sind
COMPLETE, keine fehlgeschlagenen nativen Versuche dieser Welle. Originalinputs,
Journale, Audits, Quellenkapseln und ältere Fehler bleiben unverändert privat.

Der generische Receiptwriter versah zunächst auch erfolgreiche Schritte nach
Sperrfreigabe mit dem Feld `snapshotPreserved`. Bei diesen positiven Schritten
ändert sich der Schemazustand erwartungsgemäß; tatsächlich geprüft wurden der
bekannte Ergebniszustand und unveränderte Dependencies. Der zugehörige Digest
bindet den Zustand **nach** dem positiven Schritt. Das zu breite Metadatenlabel
wird im aktuellen Writer getrennt: negative Guards führen `snapshotPreserved`
und `before-denial`, erfolgreiche Freigabeschritte `canonicalState` und
`after-positive`. Eine Gegenprobe reproduziert das ursprüngliche Label und
prüft die Korrektur ohne SQL.

Ein vollständiger Textvergleich nach ausschließlich diesem Formatteraustausch
bestätigt: sämtliche nativ ausgeführten Assertions, Admission-/Cleanup-Pfade,
Treiber und Produktquellen sind identisch. Die Korrektur betrifft nur Receipt-
Metadaten, wurde offline geprüft und führt zu keiner erneuten nativen Ausführung.
Die historischen Rawreceipts werden weder geändert noch als Nachweis unveränderter
Schemazustände bei positiven Schritten verwendet.

## Endlicher Rahmen, Sicherheit und verbleibende Pflichten

Die Welle schloss mit **24 von höchstens28 Ziel-/Auditaufrufen und24 von
höchstens28 DB-Reservierungen innerhalb45Minuten**. Alle24 eigenen DBs und
24 eigenen Releasehash-Trusteinträge sind entfernt; fünf eigene Konfigurations-
änderungen sind wiederhergestellt. Alle zwölf frischen Audits binden exakte
finale Journale, entfernte eigene Ressourcen, unveränderten fremden
Konfigurations-/Trustbestand und gültige Inputpins. Ungenutzte Reserve geschlossen;
keine alten Fristen, Verbräuche oder Sperren erneuert.

Elf [Offlinegegenproben](../../Tests/Release/test_json_schema_lifecycle_rest_lab_contract.py),
kanonischer Preflight und statische Closure-Prüfung bestehen; die Suite ist im
vorhandenen Releasevalidator registriert. Öffentliche Evidenz enthält ausschließlich
synthetischen Scope, Anzahlen und Quellreferenzen. Keine privaten Endpoints,
Zugangsdaten, Runtimeausgaben oder konkreten Trustwerte werden übernommen.

Damit sind die genannten fünf physischen Profilmatrizen geschlossen. Andere
Callerzustände, Lock-/Recovery-Arten, fremde Owner/Assemblies, zusätzliche
Metadaten-/Rechte-/Identitäts-/Consumer-/Ressourcenpflichten bleiben separat.
Das Modul bleibt **partially validated, unreleased**. Exakte Head-CI und die
tatsächliche Main-PUSH-CI werden im integrierten PR geprüft. Keine Veröffentlichung
oder Tags.
