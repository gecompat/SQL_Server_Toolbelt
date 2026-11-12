# JSON Core und Schema: Binary-, Registrierungs- und CL-Guards

Stand2026-11-12: **PASS_FOR_DECLARED_FIVE_POINT_MATRIX**. Die fünf ausgewählten
Qualifikationspunkte bestehen mit816 eindeutigen Profilen auf24 lokalen/direkt
zentralen Windows-/Linux-Kontexten. Alle zwölf Erstläufe und zwölf frischen
unabhängigen Abschlussaudits bestehen. Keine Produkt-/Binäränderung oder
vollständige Modulqualifikation; die Module bleiben partially validated, unreleased.

## Auftrag und Abdeckung

Der Benutzer beauftragte die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuschließen, gültige Nachweise wiederzuverwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Die vorhandenen Argument-, Caller-, Sperr-, Assemblymarker-, Dependency- und
Signaturbelege bleiben unverändert und werden nicht erneut ausgeführt.

| Punkt | Tatsächlicher öffentlicher Einstieg | Profile bestanden/geplant |
|---|---|---|
| 1 | Core-Deploy mit NULL, leerem Binary, einem Nullbyte und qualifizierter Schema-DLL statt Core-DLL | 96/96 |
| 2 | Schema-Deploy mit denselben drei ungültigen Werten und qualifizierter Core-DLL statt Schema-DLL | 96/96 |
| 3 | Installierte Core-DB-Registrierung: Version NULL/alt/nichtkanonisch und Modus NULL/Großschreibung/Gegenmodus; jeweils Deploy und Uninstall | 288/288 |
| 4 | Dieselben sechs installierten Schema-DB-Registrierungsdrifts; jeweils Deploy und Uninstall | 288/288 |
| 5 | Tatsächliches CL140 einer eigenen Testdatenbank: öffentliche Core-/Schema-Deploy- und Uninstall-Abweisung | 48/48 |

| Plattform | Engine/Patch | Unterstützte Ausgangs-CLs | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | 72 Profile, frischer Audit PASS |
| Windows | SQL2022/CU26 | 150,160 | 72 beziehungsweise64 Profile, je frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160,170 | 72 beziehungsweise64/64 Profile, je frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 72 Profile, frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | 72 beziehungsweise64 Profile, je frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | 72 beziehungsweise64/64 Profile, je frischer Audit PASS |

Die CL140-Grenze wird pro physischer Engine und Modus einmal vom CL150-Anker
aus geprüft. Höhere Ausgangs-CLs wiederholen diesen identischen Grenzfall nicht.
Andere nicht unterstützte CLs und Engineversionen sind damit nicht nativ geprüft.

## Methode und Ergebnisdeutung

Der [Matrixadapter](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
verwendet ausschließlich schema-validierte explizite READY-Ziele, tatsächliche
Engine-/Plattform-/CL-Prüfung und den unveränderten Functional-Transportvertrag.
Verschlüsselung bleibt erforderlich; kein authentifizierter TLS-, Windows-
Anmelde-, GUI- oder SQLCMD-CLI-Nachweis daraus. Vollständige öffentliche Scripts
und ResultTable-/Core-Baselines werden kanonisch expandiert und über ADO.NET-
Batches ausgeführt. Release-DLLs sind gegen qualifiziertes Paket, Registry,
Projekte und Compilerquellen gebunden. Ungültige Zielbytes werden abgewiesen,
keine unbekannte Assembly geladen. Kein Neubuild oder neuer Rechteumfang.

Die [Fixture](../../Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1)
verlangt pro Profil genau einen Fehler mit Severity16/State1 und dem exakten
unveränderten öffentlichen Fehlertext. Binary-Guards liefern Core55623 oder
Schema55633. Registrierungsfälle unterscheiden insbesondere Schema55634 bei
fehlender Version sowie den tatsächlichen Modus-/Markertuple-Vorrang bei
Uninstall. CL140 liefert Core55620 beziehungsweise Schema55630.

Vollständige Snapshots prüfen Definitionen, Identitäten, Owner, Berechtigungen,
Assemblies, typisierte Rohproperties, Parameter und relevante SET-Metadaten.
Der beschädigte Zustand muss nach Abweisung unverändert sein. Originale
DB-Properties werden als ursprüngliche sql_variant-Werte mit Typ/Länge/Rohwert
gehalten und exakt wiederhergestellt. Keine öffentliche Prozedur wird verändert.
Vor eigener CL-Änderung und Rückstellung werden deterministischer DB-Name,
DB-ID, Erstellungsidentität und eigener Ownershiptoken geprüft; tatsächlicher
CL und vollständiger wiederhergestellter Snapshot müssen passen. Lokale
Transaktionsneutralität und unabhängige Sitzungs-/AppLock-Orakel bestehen.

## Endlicher Rahmen und unabhängige Auswertung

Ein Verantwortlicher, keine Agenten: höchstens32 Ziel-/Auditaufrufe,32 DB-
Reservierungen und60Minuten ab erster nativer Aufnahme. Die Welle ist mit
**24/32 Aufrufen und24/32 DB-Reservierungen** innerhalb der Frist geschlossen.
Alle zwölf ersten Koordinatoren COMPLETE; kein nativer Fehlversuch oder Retry.
Die unbenutzte Reserve bleibt geschlossen und eröffnet keine weitere Welle.

Alle24 eigenen DBs und24 eigenen Releasehash-Trusteinträge sind entfernt;
fünf eigene CLR-Konfigurationsänderungen wiederhergestellt. Jeder frische Audit
bindet das exakte finale Journal, eigene Ressourcenabwesenheit, unveränderte
fremde Konfiguration/Trust und gültige Inputpins. Eine getrennte private
Auswertung rekonstruiert sämtliche erwarteten Profilkeys und prüft auf fehlende,
doppelte oder fremde Profile, Quellenkapseln und die gemeinsame Frist.

Methodenstand `36c7d310` bindet Adapter, Fixture und zwölf
[Offlinegegenproben](../../Tests/Release/test_json_lifecycle_binary_registration_lab_contract.py).
Diese prüfen unter anderem kanonische Expansion, manipulierte oder umsortierte
Binaryvektoren, falsche DLL trotz neuer Pins, genaue CL-abhängige Abdeckung,
Fehlervorrang und abweichende DB-Ownership. Alle zwölf Gegenproben und der
quellgebundene Preflight bestehen. Die Suite ist im vorhandenen Releasevalidator
registriert. Unveränderte frühere Produkt-/Closurebelege bleiben bei ihrer
ursprünglichen Quellenbindung verwendbar; keine Behauptung eines neuen Volltests.

Private Originaljournale, Fehlerausgaben und Quellenkapseln bleiben außerhalb
Git erhalten. Öffentliche Evidenz enthält nur synthetischen Scope, Anzahlen
und Quellreferenzen; keine privaten Endpoints, Credentials oder Trustwerte.
Andere Owner-/Rechte-/Identitäts-/Binding-/Recovery-/Ressourcenpflichten bleiben
separat. Exakte Head-CI und tatsächliche Main-PUSH-CI sind Integrationsgates.
Keine Veröffentlichung oder Tags.
