# JSON Core: direkte Deploy-/Uninstall-Sperrmatrix

Stand 2026-11-09: **PASS_FOR_DECLARED_DIRECT_CORE_MUTEX_MATRIX** auf zwölf
Windows-/Linux-Engine-/CL-Paaren lokal und direkt zentral. 24 eigene Kontexte,
96 vollständige Profile und zwölf erfolgreiche Gesamtfälle mit je einem
frischen unabhängigen Abschlussaudit. Frühere Schema-Tests unter derselben
gemeinsamen Sperre bleiben gültig; sie ersetzen diesen direkten Coreaufruf nicht.

| Plattform | Engine/Patch | Compatibility Levels | Modus je CL |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | local, central |
| Windows | SQL2022/CU26 | 150,160 | local, central |
| Windows | SQL2025/CU8 | 150,160,170 | local, central |
| Linux | SQL2019/latest | 150 | local, central |
| Linux | SQL2022/latest | 150,160 | local, central |
| Linux | SQL2025/latest | 150,160,170 | local, central |

## Was tatsächlich geprüft wurde

Pro Modus wird das unveränderte aktuelle Core-Deploy einmal als Voraussetzung
ausgeführt. Die einzige Benutzerassembly muss den bekannten qualifizierten
Corebytes entsprechen, SAFE und unsichtbar sein; der Modusmarker muss stimmen.
Anschließend laufen für Deploy und Uninstall jeweils zwei Schritte:

1. Eine getrennte eigene Sitzung hält `toolbelt.deploy.json.shared-core`
   exklusiv mit Session-Ownership. Positive verschiedene SPIDs, eigene DB-ID,
   zufälliger Context-Tag und serverseitiger exklusiver Lockstatus sind geprüft.
   Das vollständige originale öffentliche Skript muss exakt55627/State1/Class16
   mit der vereinbarten Meldung liefern. Der Core-Projektionssnapshot bleibt
   unverändert, der Contender neutral und die Haltersperre weiterhin exklusiv.
2. Die eigene Freigabe muss erfolgreich und der Status `NoLock` sein. Erst dann
   läuft dasselbe originale Skript erfolgreich: Repeat erhält die Coreprojektion;
   Uninstall entfernt Coreassembly und DB-Marker vollständig.

Damit sind **48 echte Sperrabweisungen und 48 erfolgreiche Schritte nach
verifizierter Freigabe** belegt. Bestehende API-/Schema-/Migrations-Vollsuiten
wurden nicht wiederholt. Der [Treiber](../../Tests/Release/Invoke-JsonCoreLockLab.ps1)
bindet schema-validierten Labvertrag, exakte Zielwahl, aktuelle bekannte
Core-DLL, Projekt-/Compilerquellen, qualifizierte Paketbytes und vollständige
kanonische Deploy-/Uninstall-Skripte. Die
[Fixture](../../Tests/Release/Runtime/JsonCore.Lock.Contract.ps1) verwendet
vorhandene Coreprojektions- und externe Sitzungsorakel als Funktionen.
Isoliert vor dem SELECT erfasster Transaktionszustand und externe SPID-genaue
Prüfung bestätigen jeweils keine offene Benutzertransaktion oder Application Locks.

## Sicherheit, Fehlerhistorie und endlicher Rahmen

Die vorhandenen CLR-Konfigurations-/Verbraucher-/Ownershiphelfer und die
ständigen Root-Freigaben für ausgewählte Testziele und exakte Releasehashes
werden verwendet. Strict Security bleibt eingeschaltet. Nur notwendige,
eindeutig eigene CLR-Aktivierung und eigene unveränderte verbraucherfreie
Trusteinträge dürfen zurückgenommen werden; fremde Zustände werden nicht
überschrieben. Finaler vollständiger Konfigurations-/Trustvergleich und
frische Audits bestehen. Keine Grants, neuen Principals, Ownerwechsel,
Zertifikats-/Truststore-/Labänderungen oder serverseitige Datei-I/O.

| Methodencommit | Tatsächliches Ergebnis |
|---|---|
| `78cfa768d9176606eb8bbfd68f567ccfb5767bfa` | erster Kontext FAILED_CLEANED vor dem ersten vollständigen Profil; frischer Cleanup-Audit PASS |
| `6e79b7801916ed1de6f12d1b981d2326bb03f243` | zwölf vollständige Kontextepaare, 96 Profile und zwölf frische Audits PASS |

Im ersten Adapter fehlte beim vorhandenen externen Idle-Orakel die erwartete
SPID; es verglich dadurch gegen den Default0. Die gezielte Offlinegegenprobe
mit dem echten Orakel reproduziert diesen Fehler. Die Korrektur ergänzt die
tatsächliche Sitzungs-ID und erhält den strengen Check; lokale und externe
Beobachtungen werden zusätzlich privat festgehalten. Neun fokussierte
[Offlineprüfungen](../../Tests/Release/test_json_core_lock_lab_contract.py)
und der kanonische Preflight bestehen. Der erste Gesamtfehler bleibt erhalten.
Der geänderte Adapterfall startete erst nach bestätigtem Cleanup und innerhalb
derselben vorab reservierten gemeinsamen Grenze; kein grüner Kontext wiederholt.

Der Rahmen ist geschlossen: **26 von höchstens28 Ziel-/Auditaufrufen und
DB-Reservierungen innerhalb derselben45Minuten**, 25 tatsächlich angelegte und
entfernte eigene DBs, 13 entfernte eigene Trusteinträge und sechs eigene
Konfigurationswiederherstellungen. Darin sind der erste Fehlversuch und sein
Audit enthalten: **13 frische Audits insgesamt**. Ungenutzte Reserve geschlossen;
keine alten Grenzen oder Fehler zurückgesetzt. Private Originale und Quellkapseln
bleiben außerhalb Git erhalten. Ein deterministischer Originalprüfer bestätigt
alle Receipts, SPIDs, Orakel, Eingabepins und endgültige Journal-/Cleanupbindung.

Functional verwendet Verschlüsselung und den unveränderten expliziten Lab-
Trustwert. Weitere Owner-/ACL-/Drift-/Migrations-/SET-/Ressourcen-/Recoveryfälle,
echte Lowpriv-CrossDB-Identitäten und authentifiziertes TLS bleiben eigenständig.
Keine vollständige Modulabnahme, Produkt-/Manifest-/Statusänderung oder neue DLL.
Keine Veröffentlichung oder Tags.
