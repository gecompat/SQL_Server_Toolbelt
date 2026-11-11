# JSON Schema: fünf Lifecycle-Grenzen

Stand 2026-11-11: **PASS_FOR_DECLARED_FIVE_POINT_MATRIX**.
Die fünf ausgewählten Metadaten-/Eingabegrenzen sind auf zwölf Engine-/CL-Paaren
lokal und direkt zentral belegt. 828 eindeutige Profile bestehen aus 824 in
dieser Welle nativ geprüften und vier gültigen historischen Guardprofilen.
Der erste fehlgeschlagene Koordinator bleibt unverändert FAILED_CLEANED;
seine fünf bestandenen Profile sind gebunden wiederverwendet. Dies ist keine
vollständige Schema-Modulqualifikation oder Veröffentlichungsfreigabe.

## Auftrag und fünf abgeschlossene Punkte

Der Benutzer beauftragte am 2026-11-11 die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuschließen, gültige Nachweise wiederzuverwenden,
nur echte Lücken zu prüfen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Keine neue Fachfunktion, Rechtevergabe, Identität oder Ownerreparatur.

| Punkt | Geprüfter Vertrag | Belegt / geplant |
|---|---|---|
| 1 | Verwaiste DB-Versions-/Modusmarker bei fehlendem Schema ablehnen und unverändert erhalten, jeweils Deploy/Uninstall | 96 / 96 |
| 2 | Sechs Assembly-Markertupel einzeln typverfälschen; Deploy/Uninstall müssen exakt ablehnen und den beschädigten Zustand erhalten | 288 / 288 |
| 3 | ModuleId, ModuleVersion und DeploymentMode der beiden registrierten Objektslots einzeln verfälschen; beide Lifecycleoperationen müssen unverändert ablehnen | 288 / 288 |
| 4 | Reservierte Caller-Temp-Tabelle im Deploy ablehnen, einschließlich erhaltenem synthetischem Zeugenwert | 24 / 24 |
| 5 | Exakte Modusvarianten `LOCAL` / ` local ` sowie Consumerwerte `2`, ` 1`, `01` und zentral `0` ablehnen | 132 / 132 |

Jeder beschädigte eigene Marker wird vor dem nächsten Profil mit seinem
ursprünglichen `sql_variant` wiederhergestellt. Der Snapshot enthält
Objektdefinitionen/-identitäten, Assemblyidentität/-owner/-bytes, Berechtigungen,
Corezustand sowie Basistyp, deklarierte Länge, Datenlänge und Rohbytes der
relevanten Properties. Zusätzlich werden lokale Transaktionsneutralität und
externe Sitzungs-/AppLock-Neutralität tatsächlich geprüft. Erwartet werden
jeweils genau eine passende SQL-Fehlernummer, Severity16, State1 und der
unveränderte öffentliche Fehlertext. Kein Reparaturversuch des Produkts.

## Zielmatrix und gültige Wiederverwendung

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | fünf gültige Präfixprofile plus 64 Restprofile; beide frischen Audits PASS |
| Windows | SQL2022/CU26 | 150,160 | je 69 neue Profile und frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160 | je 69 neue Profile und frischer Audit PASS |
| Windows | SQL2025/CU8 | 170 | 65 neue plus vier historische Guardprofile; frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 69 neue Profile und frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je 69 neue Profile und frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je 69 neue Profile und frischer Audit PASS |

Die unveränderten Originalberichte belegen auf Windows2025/CU8 CL170:

- [Deploy-Kollisionen](json-schema-deploy-collision-qualification.json): lokal
  reservierte Temp-Tabelle und verwaister Modusmarker beim Deploy.
- [Consumer-Bestätigung](json-schema-uninstall-confirmation-qualification.json):
  zentral `01` und `0` beim Uninstall.

Beide Originale besitzen einen bestandenen finalen unabhängigen Audit. Alle
Schema-Deploymentquellen des tatsächlich ausgeführten Guardpfads stimmen mit
ihren Originalpins überein. Die später geänderte öffentliche Hilfetextdefinition
wird in diesen Abweisungspfaden nicht ausgeführt; daraus folgt ausdrücklich
keine pauschale Aktualität aller damaligen Produkt-/Harnessquellen. Die vier
identischen Guardprofile wurden nicht wiederholt. Fremde Tabellen in den
öffentlichen/internen Zielslots bleiben außerhalb dieser Fünfpunktmatrix.

## Testmethode und erhaltener Fehler

Der [Adapter](../../Tests/Release/Invoke-JsonSchemaBoundariesLab.ps1) expandiert
vollständige öffentliche Deploy-/Uninstallskripte und Argumentvarianten mit
den kanonischen SQLCMD-Include-/Variablenfunktionen. Ausgeführt werden deren
Batches über ADO.NET; kein neuer Nachweis eines separaten SQLCMD-CLI-Transports.
ResultTable/Core dienen als notwendige lokale beziehungsweise zentrale
Dependencies. Beide unveränderten Release-DLLs werden gegen Paketprovenienz,
Known-Artifact-Registry, Projekte und kompilierte Quellen geprüft. Kein Neubuild.

Die [Fixture](../../Tests/Release/Runtime/JsonSchema.Boundaries.Contract.ps1)
verwendet bestehende Snapshot-/Observerfunktionen. Nach gezielter Mutation muss
der vollständige öffentliche Lifecycle unverändert ablehnen. Anschließend
gelingt die reguläre eigene Schemaentfernung; die übrigen eigenen Dependencies
werden mit der Testdatenbank entfernt.

| Methodencommit | Tatsächliches Ergebnis |
|---|---|
| `e5ba6965` | Erster SQL2019-Lauf FAILED_CLEANED nach fünf gültigen Guardprofilen; frischer Audit PASS |
| `8f2c6eaa` | Ausschließlich ungeprüfter Restumfang und elf weitere Zielpaare bestanden; zwölf frische Audits PASS |

Der erste Adapter kopierte zusätzliche Objektproperties, erwartete jedoch nur
die sechs Assembly- und sechs ausgewählten Ownershipmarker. Die Korrektur
begrenzt die Objektselektion auf die drei tatsächlich geprüften Eigenschaften;
ContractVersion/SourceHash bleiben unverändert beobachtet. Eine gezielte
Offlinegegenprobe verhindert diese falsche Zählannahme. Originaljournal,
Eingaben, Quellkapseln, Fehlbefund und Audit bleiben privat unverändert erhalten.

Die Fortsetzung bindet das exakte Originaljournal und seinen frischen Audit,
unveränderte Produktpins und tatsächlich identische Snapshot-/Fehlerorakel.
Nur die 64 ungeprüften Profile des ersten Paars wurden ausgeführt. Der ursprüngliche
Koordinator bleibt fehlgeschlagen; sein Audit behauptet weiterhin keinen
bestandenen Gesamtfall. Kein grünes Präfix wurde wiederholt oder aufgewertet.

## Sicherheit, Grenzen und verbleibender Scope

Der gemeinsame Rahmen schloss mit **26 von höchstens28 Lauf-/Auditaufrufen,
26 von höchstens28 DB-Reservierungen innerhalb45Minuten**. Alle25 tatsächlich
angelegten eigenen Datenbanken und26 eigenen Hash-Trusteinträge wurden entfernt;
sechs eigene Konfigurationsänderungen wurden wiederhergestellt. Sämtliche13
frischen Audits binden das jeweilige finale Journal und bestätigen DB-Abwesenheit,
unveränderte fremde Serverkonfiguration/Trust und gültige Quellbindungen.
Ungenutzte Reserven sind geschlossen; frühere Testgrenzen bleiben unberührt.

Zwölf [Offlinegegenproben](../../Tests/Release/test_json_schema_boundaries_lab_contract.py),
der kanonische Preflight und die statische Closure-Prüfung bestehen. Die Suite
ist in der vorhandenen Releasesuite registriert. Öffentliche Dokumentation
enthält ausschließlich synthetischen Scope, Anzahlen und Quellreferenzen;
private Endpoints, Zugangsdaten, Laufzeitausgaben und Trustwerte bleiben lokal.

Andere Caller-/SET-/Zielprofile, vollständige Schema-AppLock-, Fremdslot-,
Owner-, Consumer-, Rechte-, Recovery- und Ressourcenpflichten sind durch diese
fünf Punkte nicht insgesamt geschlossen. Bestehende engere Belege gelten
weiter in ihrem jeweiligen Scope. Das Modul bleibt **partially validated,
unreleased**. Head- und tatsächliche Main-CI werden am integrierten PR geprüft;
es wird nichts veröffentlicht oder getaggt.
