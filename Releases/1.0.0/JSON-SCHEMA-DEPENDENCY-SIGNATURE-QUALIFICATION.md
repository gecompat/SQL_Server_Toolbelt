# JSON Schema: Dependency- und Signaturguards

Stand2026-11-11: **PASS_FOR_DECLARED_FIVE_POINT_MATRIX**.
Alle fünf ausgewählten Restmatrizen sind auf24 lokalen/direkt zentralen
Windows-/Linux-Kontexten mit **1104 eindeutigen Profilen** belegt. Gültige
Teilprofile werden wiederverwendet; drei ursprüngliche Koordinatoren bleiben
FAILED_CLEANED. Alle15 frischen unabhängigen Abschlussaudits bestehen.
Keine Produkt-/Binäränderung oder vollständige Modulqualifikation.

## Auftrag und geschlossene Punkte

Der Benutzer beauftragte am2026-11-11 die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuschließen, gültige Evidenz zu verwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Der später ausdrücklich freigegebene einzelne zentrale Restlauf bleibt ein
eigener endlicher Rahmen; die ursprünglichen Grenzen wurden nicht erneuert.

| Punkt | Tatsächliches Profil | Belegt / geplant |
|---|---|---|
| 1 | Jeden der zwölf öffentlichen Parameter einzeln mit abweichendem kompatiblem Typ/Länge/Alias deklarieren; Deploy/Uninstall müssen abweisen | 576 / 576 |
| 2 | Sechs typisierte Core-Markertupel einzeln beschädigen; tatsächliche Schema-Deploy-/Uninstall-Einstiege müssen den kanonischen Corefehler liefern | 288 / 288 |
| 3 | ResultTable-Version unter Mindestversion, nichtkanonisch oder NULL sowie falsche objektbezogene ModuleId/ModuleVersion; Deploy muss abweisen | 120 / 120 |
| 4 | Constructor-Versionsregistrierung NULL, aktuell oder nichtkanonisch ohne Constructorassembly; Deploy muss abweisen | 72 / 72 |
| 5 | Eigene fremde View referenziert die interne Bridge tatsächlich; Deploy/Uninstall müssen den Verbraucher unverändert erhalten und abweisen | 48 / 48 |

Die [Caller-/Sperr-/Fremdslotmatrix](JSON-SCHEMA-SESSION-LOCK-SLOTS-QUALIFICATION.md)
und die [vorherigen Metadaten-/Eingabegrenzen](JSON-SCHEMA-FIVE-BOUNDARIES-QUALIFICATION.md)
bleiben getrennt gültig. Direkte Core-Markertests ersetzen den neuen Schema-
Aufrufpfad nicht. Der bereits geprüfte öffentliche Prozedurconsumer und die
genuine Constructor-Vorgängerabweisung wurden nicht wiederholt. Die neuen
Constructorfälle belegen ausschließlich verwaiste Registrierung ohne Assembly,
keine vollständige Constructor-Dependency- oder Migrationsmatrix.

## Physische Abdeckung

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | lokal46 gültige zusammengesetzte Profile; zentral46 Profile im gesondert genehmigten Erstlauf; zugehörige Audits PASS |
| Windows | SQL2022/CU26 | 150,160 | je92 vollständige Profile und frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160,170 | je92 vollständige Profile und frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 92 vollständige Profile und frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je92 vollständige Profile und frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je92 vollständige Profile und frischer Audit PASS |

Der [Matrixadapter](../../Tests/Release/Invoke-JsonSchemaDependencySignatureLab.ps1)
verwendet ausschließlich schema-validierte explizite READY-Ziele, tatsächliche
Engine-/Plattform-/CL-Prüfung und den unveränderten Functional-Transportvertrag.
Verschlüsselung bleibt erforderlich; kein daraus abgeleiteter authentifizierter
TLS-, Windows-Anmelde-, GUI- oder SQLCMD-CLI-Nachweis. Vollständige öffentliche
Scripts und notwendige ResultTable-/Core-Baselines werden kanonisch expandiert
und über ADO.NET-Batches ausgeführt. Bekannte unveränderte Release-DLLs sind
gegen qualifiziertes Paket, Registry, Projekte und Compilerquellen gebunden.
Keine neue Assembly, kein Neubuild, keine fremden Daten oder neuen Rechte.

## Tatsächliche Orakel und Wiederherstellung

Die [Fixture](../../Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1)
verändert bei jedem Signaturfall genau einen Headerparameter. Der Body bleibt
identisch; der tatsächliche Katalogvergleich bestätigt zwölf Parameter und
genau eine geänderte Parameterzeile. Geprüft werden System-/Aliastyp, Länge,
Präzision, Skala und Outputflag. Eine Setup-Wiederholung etabliert vor dem
Snapshot den stabilen bestehenden DDL-Zweig; sie ist kein neu beanspruchter
Repeat-Qualifikationsfall. Vor dem nächsten Profil wird die vollständige
ursprüngliche Katalogdefinition wiederhergestellt und exakt verglichen.

Core-/ResultTable-Properties werden vor Mutation als ursprüngliche
`sql_variant`-Werte gehalten und anschließend mit originalem Typ, Länge und
Rohwert wiederhergestellt. Constructorregistrierungen werden nur bei zuvor
nachgewiesener vollständiger Abwesenheit als eigene Fixtures angelegt. Die
Consumer-View muss eine tatsächlich sichtbare Dependency auf die interne
Bridge besitzen. Nur eindeutig eigene unveränderte Fixtures werden entfernt.

Jeder negative Profilaufruf verlangt genau einen passenden Fehler mit
Severity16/State1 und unverändertem öffentlichen Text: Signatur-/Constructor-
55633, delegiertes Coretuple55623, ResultTable55632 beziehungsweise Consumer55636.
Der vollständige beschädigte Zustand bleibt nach Abweisung erhalten.
Beobachtet werden Definitionen/Identitäten/Owner/Berechtigungen/Assemblies,
typisierte Rohproperties, Parameterkatalog, relevante SET-Metadaten sowie
Consumerdefinition und Dependencies. Lokale Transaktionsneutralität und ein
unabhängiger Sitzungs-/AppLock-Observer bestätigen den neutralen Abschluss.
Änderungszeitstempel eigener DDL-Fixtures sind kein behaupteter Restorevertrag.

## Erhaltene Fehler und ausschließlich ungeprüfte Fortsetzung

| Methodenstand | Tatsächliches Ergebnis |
|---|---|
| `bfb0f11a` | Vor dem ersten Profil FAILED_CLEANED: Katalogdefinition als CREATE statt Änderung ausgeführt; frischer Audit PASS |
| `8f800248` | Zwei gültige lokale Json-Parameterguards; anschließend FAILED_CLEANED beim exakten Katalog-Rückvergleich; frischer Audit PASS |
| `1ef7ab13` | Alle44 übrigen lokalen Guards bestehen einschließlich Wiederherstellung; FAILED_CLEANED nur beim noch nicht um wiederverwendete Profile bereinigten Modusabgleich; frischer Audit PASS |
| `08b9025b` / `267d7fca` | Ausschließlich elf bislang ungeprüfte Zielpaare vollständig bestanden; elf frische Audits PASS |
| Zentraler Restadapter aus `267d7fca` | Nach neuer ausdrücklicher Einzelfreigabe46 zentrale SQL2019-Profile im ersten Versuch bestanden; frischer Audit PASS |

Der Katalog kann den ursprünglichen CREATE-OR-ALTER-Text mit verbliebenem
Leerraum des DDL-Verbs darstellen. Der erste Adapter führte diese vorhandene
Definition als CREATE aus; die erste Korrektur übernahm Katalogpadding erneut
in den Änderungsbefehl. Die endgültige Kanonisierung verändert nur den DDL-
Einstieg und bewahrt Body/Parametertext. Eine Offlinegegenprobe prüft die
CREATE-/ALTER-/CREATE-OR-ALTER-Formen einschließlich Padding. Die aktuelle
native Matrix bestätigt den exakten Roundtrip.

Der Modusabgleich berücksichtigt jetzt die zwei gültigen wiederverwendeten
Json-Profile. Gegenproben prüfen vollständige, zusammengesetzte und fehlende
Abdeckung sowie doppelte/unbekannte Ausschlüsse. Originaljournal, frischer
Audit, Produktpins und tatsächlich identische Snapshot-/Fehlerorakel binden
die zwei frühen Profile. Weitere44 lokale Profile stammen aus dem dritten
Original; dessen reiner Abdeckungsfehler entwertet ihre zuvor bestandenen
SQL-/Restoreorakel nicht. Keiner der drei Koordinatoren wird zum Gesamt-PASS;
kein grünes Profil wird wiederholt. Die elf anderen Zielpaare laufen unter
dem korrigierten Abgleich vollständig und unabhängig.

Ein geerbter privater Controller-Abschlusstext bezeichnete den Teilabschluss
noch zu weit. Die Auswertung verwendet die tatsächlichen Journale, Kontext-
und Profilmengen sowie den expliziten Budgetstatus CLOSED_PARTIAL_SCOPE;
aus diesem Text wird kein Vollnachweis abgeleitet.

## Zwei getrennte endliche Freigaberahmen

Die ursprüngliche Welle ist mit **28/28 Ziel-/Auditaufrufen und28/28 DB-
Reservierungen innerhalb45Minuten** geschlossen. Ihr Ergebnis sind1058 gültige
Profile auf23 Kontexten,25 tatsächlich angelegte und entfernte DBs sowie14
frische Audits. Der zentrale SQL2019-Kontext blieb explizit offen.

Der Benutzer gab anschließend genau diesen Rest frei: **ein Lauf, eine eigene
DB und ein frischer Audit, höchstens zwei zusätzliche Ziel-/Auditaufrufe und
45Minuten, keine Wiederholung**. Der [zentrale Adapter](../../Tests/Release/Invoke-JsonSchemaCentralRestLab.ps1)
akzeptiert nur Windows2019/CU32 CL150, zentral, CaseIndex0 und den expliziten
2/1/45-Vertrag. Sein Audit kann ausschließlich46 zentrale Profile, einen
abgeschlossenen Modus und einen Witness bestätigen; keine Aufwertung zum
vollen lokalen/zentralen Paar. Der separate Rahmen ist mit2/2 Aufrufen und1/1DB
erfolgreich geschlossen. Die ursprünglichen Zähler/Fristen bleiben unverändert.

Insgesamt sind alle26 angelegten eigenen DBs und30 eigenen Releasehash-
Trusteinträge entfernt; acht eigene Konfigurationsänderungen wiederhergestellt.
Alle15 frischen Audits binden exakte finale Journale, eigene Ressourcenabwesenheit,
unveränderten fremden Konfigurations-/Trustbestand und gültige Inputpins.
Private Originale, Fehler und Quellenkapseln bleiben außerhalb Git erhalten.

Zwölf [Matrix-Offlinegegenproben](../../Tests/Release/test_json_schema_dependency_signature_lab_contract.py),
vier [Restadapter-Gegenproben](../../Tests/Release/test_json_schema_central_rest_lab_contract.py),
kanonische Preflights und statische Closure-Prüfung bestehen. Beide Suiten sind
im vorhandenen Releasevalidator registriert. Öffentliche Evidenz enthält
ausschließlich synthetischen Scope, Anzahlen und Quellreferenzen, keine privaten
Endpoints, Credentials, tatsächlichen Trustwerte oder Runtime-Ausgaben.

Andere Owner-/Rechte-/Identitäts-/Binding-/Consumer-/Recovery-/Ressourcenpflichten
bleiben separat. Das Modul bleibt **partially validated, unreleased**. Exakte
Head-CI und tatsächliche Main-PUSH-CI sind Integrationsgates; keine Veröffentlichung
oder Tags.
