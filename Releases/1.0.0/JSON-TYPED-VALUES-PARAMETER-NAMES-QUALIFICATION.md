# JSON Core und Schema: Markerwerte, fehlende Registrierung und Parameternamen

Stand2026-11-13: **PASS_FOR_DECLARED_FIVE_POINT_MATRIX**. Alle fünf ausgewählten
Restmatrizen bestehen mit1344 eindeutigen Profilen auf24 lokalen/direkt
zentralen Windows-/Linux-Kontexten. Zwölf Erstläufe und zwölf frische
unabhängige Abschlussaudits PASS, kein nativer Fehlversuch oder Retry.
Keine Produkt-/Binäränderung und keine vollständige Modulqualifikation.

## Auftrag und Abgleich

Der Benutzer beauftragte die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuschließen, gültige Nachweise wiederzuverwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Die bestehenden Typdrift-, NULL-/Fehlmarker-, Registrierungswert-, Caller-,
Lock-, Dependency-, Sichtbarkeits- und Signaturtypbelege bleiben unverändert.
Neue Eingaben sind gleich typisierte falsche Markerwerte, vollständig fehlende
DB-Registrierungsproperties bei vorhandener Assembly und reine Namensdrift
der öffentlichen Parameter. Keine bereits grünen Profile wurden wiederholt.

| Punkt | Tatsächliche öffentliche Deploy-/Uninstall-Prüfung | Profile bestanden/geplant |
|---|---|---|
| 1 | Sechs Core-Assemblymarker mit anderem Rohwert bei gleichem Typ, MaxLength und DATALENGTH | 288/288 |
| 2 | Sechs gleich typisierte/gleich lange falsche Rohwerte an Schema-Assemblymarkern | 288/288 |
| 3 | Installierte Core-DB-Registrierung: Version beziehungsweise DeploymentMode vollständig löschen | 96/96 |
| 4 | Installierte Schema-DB-Registrierung: Version beziehungsweise DeploymentMode vollständig löschen | 96/96 |
| 5 | Jeden der zwölf öffentlichen Schema-Parameternamen einzeln vollständig großschreiben; Typ/Länge/Ordinal und Body unverändert | 576/576 |

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | 112 Profile, frischer Audit PASS |
| Windows | SQL2022/CU26 | 150,160 | je112 Profile, je frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160,170 | je112 Profile, je frischer Audit PASS |
| Linux | SQL2019/latest | 150 | 112 Profile, frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je112 Profile, je frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je112 Profile, je frischer Audit PASS |

## Eingaben und reale Orakel

Die sechs Marker sind Managed, ModuleId, ModuleVersion, DeploymentMode,
AssemblySha512 und ArtifactId mit Toolbelt-Präfix. Die Fixture verändert nur
den Rohwert: Managed0, eine letzte Modul-ID-Stelle, Version1.0.9, Großschreibung
des Modus, synthetische Nullbytes beim Hash und synthetische Ziffern0 beim
Artifacttext. Vor der Mutation müssen SQL_VARIANT_PROPERTY für BaseType und
MaxLength sowie DATALENGTH gleich und die Rohbytes unterschiedlich sein.
Es handelt sich um Metadaten, nicht um geänderte oder unbekannte Assemblybytes.

16 Originalproperties werden als ursprüngliche sql_variant-Werte in einer
Caller-Temp-Tabelle aufbewahrt. DB-Registrierungsmarker werden vollständig
entfernt und mit ihrem ursprünglichen Wert und Typ neu angelegt. Vor jeder
Rückstellung muss der beschädigte Zustand unverändert sein; danach wird der
vollständige ursprüngliche Snapshot exakt verglichen.

Die Parametersignaturprüfung nutzt den bereits qualifizierten Headertransformer
und CREATE-OR-ALTER-Katalognormalisierer. Ein zweiter kanonischer Setup-Deploy
stabilisiert vor dem Snapshot den bestehenden DDL-Zweig; er ist kein neuer
Repeat-Qualifikationsfall. Je Profil ändern sich ausschließlich die Buchstaben
eines Parameternamens im Header. Ein unabhängiger Vergleich der tatsächlichen
zwölf sys.parameters-Zeilen verlangt genau diese eine Namensänderung und
unveränderte parameter_id, System-/Aliastypen, Länge, Präzision, Skala und
Outputflag. Die Testdatenbanken verwenden die bestehende CI-Collation; der
unveränderte Body bleibt ausführbar. Anschließend muss die ursprüngliche
Katalogdefinition einschließlich Snapshot wiederhergestellt sein.

Jeder öffentliche negative Aufruf verlangt genau einen exakten Fehler mit
Severity16/State1 und unverändertem Text: Coretuple55623, Schematupel55633,
fehlende Core-Registrierung55623, fehlende Schema-Version55634, fehlender
Schema-Modus55633 und öffentliche Parametersignatur55633. Verglichen werden
Definitionen, Identitäten, Owner, Berechtigungen, Assemblies, typisierte
Rohproperties, Parameter und relevante SET-Metadaten. Lokale Transaktions-
neutralität und unabhängige Sitzungs-/AppLock-Orakel bestehen. DDL-Änderungs-
zeitstempel der eigenen temporären Fixture sind kein behaupteter Restorevertrag.

## Wiederverwendete Methode und Grenzen

Der [bestehende Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
wählt die neue [Fixture](../../Tests/Release/Runtime/JsonLifecycle.MarkerValuesNames.Contract.ps1)
ausschließlich über `json-lifecycle-marker-values-names/v1`. Gemeinsame
Snapshot-, Script-, Fehler- und Neutralitätsfunktionen sowie die vier benötigten
Signatur-/Katalogfunktionen bleiben unverändert und ausdrücklich gepinnt.
Andere Fixtureverträge werden nicht umgedeutet; keine zweite vollständige
Runner- oder Admission-Suite.

Vollständige öffentliche Scripts und Baselines sind kanonisch expandiert;
Paket, bekannte Release-DLLs, Registry, Projekte und Compilerquellen sind
gebunden. Nur schema-validierte explizite READY-Ziele, tatsächliche Engine-/
Plattform-/CL-Prüfung und unveränderter Functional-Transport. Verschlüsselung
bleibt erforderlich; kein authentifizierter TLS-, Windows-Anmelde-, GUI- oder
SQLCMD-CLI-Nachweis daraus. Keine neuen Rechte, Identitäten, Owner, Binaries,
Labressourcen, Zertifikate, Truststores oder serverseitige Datei-I/O.

Methodenstand `5a444432` besteht die zwei neuen
[Gegenproben](../../Tests/Release/test_json_marker_values_names_lab_contract.py):
exakte Fixtureauswahl und notwendige gemeinsame Pins, Profilclosure, reine
Headertransformation, tatsächlicher Katalogvergleich mit falschem Typ/Namen
und unverändertem Namen als Gegenfällen sowie Typ-/Längen- und Restoregrenzen.
Die beiden vorhandenen Marker-/Sichtbarkeits-Dispatchgegenproben und der
quellgebundene Preflight bestehen ebenfalls. Die neue Suite ist im bestehenden
Releasevalidator registriert; keine neuen CI-Jobs oder Trigger. Nicht betroffene
frühere Produktnachweise bleiben bei ihrer gültigen Bindung verwendbar.

## Endlicher Abschluss

Ein Verantwortlicher, keine Agenten: maximal32 Ziel-/Auditaufrufe,32 DB-
Reservierungen und60Minuten ab erster nativer Aufnahme. Der gemeinsame Rahmen
ist mit **24/32 Aufrufen und24/32 DB-Reservierungen** innerhalb der Frist
geschlossen; die unbenutzte Reserve bleibt geschlossen. Alle24 eigenen DBs und
24 eigenen Releasehash-Trusteinträge sind entfernt, fünf eigene CLR-
Konfigurationsänderungen zurückgenommen. Alle zwölf frischen Audits binden
exakte finale Journale, eigene Ressourcenabwesenheit, unveränderte fremde
Konfiguration/Trust und Inputpins. Eine getrennte private Auswertung rekonstruiert
alle Profilkeys, erkennt fehlende/doppelte Profile und prüft Quellenkapseln,
Produktbindung und gemeinsame Frist.

Private Originale bleiben außerhalb Git erhalten; öffentliche Evidenz enthält
nur synthetischen Scope, Anzahlen und öffentliche Quellreferenzen. Andere
Owner-/ACL-/Identitäts-/Binding-/Recovery-/Ressourcenpflichten bleiben separat.
Beide Module bleiben **partially validated, unreleased**. Exakte Head-CI und
tatsächliche Main-PUSH-CI sind Integrationsgates; keine Veröffentlichung oder Tags.
