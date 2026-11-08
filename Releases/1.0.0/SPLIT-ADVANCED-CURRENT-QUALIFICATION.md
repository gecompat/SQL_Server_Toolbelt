# Split-Advanced: aktuelle Funktions- und Clientmatrix

Am 2026-11-08 bestand Split Advanced **1.1.0** mit ResultTable **1.0.0**
auf zwölf Engine-/CL-Paaren jeweils lokal und direkt zentral:
**24 Kontexte, 96 vollständige SQL-Fixtures, 24 originale Clientproben
und zwölf frische unabhängige Abschlussaudits**.
Ergebnis: **PASS_FOR_DECLARED_SPLIT_CURRENT_SCOPE**. Alle 24 eigenen
Testdatenbanken sind entfernt. Der Modulgesamtstatus bleibt `partially validated`.

| Ausgewähltes Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows SQL2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows SQL2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows SQL2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux SQL2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux SQL2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux SQL2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Clienthost Windows, System.Data.SqlClient und vorhandene administrative
Lab-Anmeldung. Direkt zentral bedeutet Nutzung im zentralen Installationskontext,
keine CrossDB-Authentifizierung. Functional übernimmt Encrypt=True und den
expliziten Trustwert des schema-validierten Labvertrags; dies ist kein
Nachweis authentifizierten TLS. Keine GUI-Probe wurde ausgeführt.

## Unveränderte Orakel und aktuelle Bindung

Der [Testadapter](../../Tests/Release/Invoke-SplitAdvancedLab.ps1) installiert
nur die zwei oben genannten Module über kanonische Exporte. Vor SQL werden
sämtliche Pins, die Exportclosure und die zwölf festen Ziel-/Moduspaare geprüft.
Nach Anmeldung werden tatsächliche Engine, Plattform und administrative
Berechtigung festgestellt, vor der Installation das tatsächlich wirksame CL.
Versionen und Deploymentmodi werden nach Installation aus dem Katalog gelesen.
Pro Kontext laufen auf derselben eigenen Verbindung vollständig:

1. [SplitAdvanced.Contract.sql](../../Modules/toolbelt.string.split-advanced/Tests/Runtime/SplitAdvanced.Contract.sql):
   Originaltokens, Quotes/Escapes, Separatorauswahl, Unicode, JSON und Grenzen.
2. [UnquoteToken.Contract.sql](../../Modules/toolbelt.string.split-advanced/Tests/Runtime/UnquoteToken.Contract.sql):
   Unquoting-Modi, Codeeinheiten, Fehler, Grenzen einschließlich Dense65536 und APPLY.
3. [SplitAdvancedUsp.Contract.sql](../../Modules/toolbelt.string.split-advanced/Tests/Runtime/SplitAdvancedUsp.Contract.sql):
   Parameter/Help, SELECT-/ResultTable-Ausgabe, KeepData, Blocker und Callertransaktionen.
4. [Lifecycle.Contract.sql](../../Modules/toolbelt.string.split-advanced/Tests/Runtime/Lifecycle.Contract.sql):
   read-only Prüfung aktueller Objekt-, Versions-, Modus- und Quellmarker.

Nach jeder Fixture verlangt der Adapter einen neutralen Transaktionszustand.
Die unveränderte [Clientprobe](../../Modules/toolbelt.string.split-advanced/Tests/Runtime/SelectMetadata.Contract.ps1)
läuft anschließend auf einer eigenen Verbindung: SELECT-Spaltennamen/-typen,
NOT-NULL, NULL-/Zwei-Zeilen-Ausgabe, genau ein fachlicher Resultset,
Hilfe ohne Zusatzresultset/-messages und ResultTable ohne fachliches SELECT.
Der vorhandene Erfolgmarker wird exakt verlangt und pro Kontext gebunden.
Damit ist die seit 2026-10-09 nur quellseitig geführte Command-/Readeraufnahme
jetzt im nativen Erfolgsweg ausgeführt. Dispose-Fehler wurden nicht injiziert;
der historische Hinweis zur möglichen Fehlerersetzung bleibt gültig.
Produktdefinitionen vor/nach Fixtures und Clientprobe stimmen exakt überein.
96 bezeichnet ganze Fixture-Ausführungen, keine behauptete Assertionzahl.

Ausgeführter Methodensnapshot:
[`379da73e`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/379da73ec0b8dba4478c7f2ca2bd1fb74aa23991).
Die aktuelle Hilfe gehört zum ausgeführten Export, nicht zu einer historischen
Paketkopie. Die seit Oktober grünen einzelnen Callerprofile werden nicht wiederholt.
Beim Bindungsvergleich waren neun Moduldateien identisch; die beiden abweichenden
USP-Quellen von Split und ResultTable enthalten eine geänderte Hilfeausgabe.
Ihre Einstiegspfade und vollständigen fachlichen Pfade nach dem Helpblock sind
unverändert. Der [Rechtebericht](SPLIT-ADVANCED-RIGHTS-QUALIFICATION.md) und sein
[CL-Abschluss](SPLIT-ADVANCED-CL-COMPLETION.md) bleiben für diese unveränderten
Rechtepfade verwendbar; sie werden nicht als frische Rechteausführung ausgegeben.
Die aktuelle Hilfe/Clientausgabe ist durch das neue Paket separat nativ belegt.
Historische Projektionen, Ausführungspins und damalige Grenzen bleiben unverändert.

## Grenzen, unabhängige Abnahme und Wiederverwendung

Vor Beginn galten gemeinsam **24 Ziel-/Auditaufrufe, 24 eigene Datenbanken
und 45 Minuten**, ein Verantwortlicher, keine Agents und keine Wiederholung.
Alle zwölf Producer bestanden beim ersten nativen Versuch; alle zwölf reservierten
separaten Auditprozesse bestanden innerhalb der ursprünglichen Frist.
Die Welle ist mit 24/24 Aufrufen und 24/24 DB-Reservierungen geschlossen.

Owned-Process begrenzt Producer/Audit jeweils auf 400 Sekunden mit getrennten
4-MiB-Kanälen. SQL-Arbeits-/Cleanupfristen bleiben erhalten; vor einem neuen Paar
sind mindestens 15 Minuten Reserve nötig. Dies qualifiziert keinen verlorenen
Koordinator oder allgemeinen harten Hostausfall.

Cleanup verlangt die exakte eigene DB-Identität einschließlich Erstellungszeit
und Ownermarker. Jeder frische Windows-Clientaudit bindet den finalen Journalhash,
die tatsächliche Zielversion, DB-Abwesenheit, unveränderte gesamte Konfiguration
und Assemblytrust sowie alle Eingabepins. Ein separater privater Nachprüfer hat
alle zwölf Fälle, 24 Abschlusszeugen, Originalaudits und Quellbindungen geprüft.
Private Quellkapseln erhalten die tatsächlich ausgeführten Adapter-/Controllerbytes.
Keine neuen Benutzer, Grants, CLR-Assemblies, Trusteinträge, Serveroptionen oder
Labressourcen. Reale Rohlogs, Endpoints und Laufzeitwerte bleiben außerhalb Git.

Zehn [Offlinegegenproben](../../Tests/Release/test_split_advanced_lab_contract.py)
prüfen tatsächliche Admission ohne SQL/Labimport, boolesche Freigabe, Frist-,
Ziel- und Modusabweichungen, kanonische Fixtures/Pins, Exportdrift und verbotene
Rechte-/Principal-/Server-/CLR-Operationen. Der Modul-Static-Vertrag besteht.
Vor der nativen Zulassung korrigierte Namens-/Controllerprobleme bleiben privat
erhalten; kein nativer Fehlversuch und keine Wiederholung werden verschwiegen.

Reproduktionsaufruf nach separat geprüfter privater Vorbereitung:
`pwsh -NoProfile -File Tests/Release/Invoke-SplitAdvancedLab.ps1 -RunsetPath .runtime/selected/runset.private.json -CaseIndex 0`;
der reservierte separate Aufruf ergänzt `-AuditOnly`. Der private Runset enthält
nur Pfade/Pins und feste Auswahl-/Budgetdaten, keine kopierten Zugangsdaten.
Nicht ohne einen neuen freigegebenen endlichen Rahmen wiederholen.

Die früher pauschal offene Funktions-/Clientzielmatrix ist für diese Originalorakel
geschlossen. Nicht enthalten sind vollständige Drift-/Upgrade-/Uninstallprofile,
zusätzliche Collations, echte Lowpriv-CrossDB-Identitäten, Linux-Clienthost,
Heap-/Parallelitäts- und harte Recoveryqualifikation. Die alte Security-Fixture
wurde hier nicht wiederholt. Das Modul bleibt unveröffentlicht; keine Tags oder Releases.
