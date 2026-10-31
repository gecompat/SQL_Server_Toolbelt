# v1.0.0: erledigte PrÃ¼fungen und offene Releasegates

[XLSX-/ZIP-Writer-Paketnachweis](XLSX-ZIP-PACKAGE-FRAMEWORK-QUALIFICATION.md):
19 bestehende XLSX-Candidate-Frameworkphasen und sieben ZIP-Entry-Security-FÃ¤lle
mit dem bestehenden Writer-Body bestanden. Paket-/Modulstatus blieb unverÃ¤ndert;
SQL, Deployment und VerÃ¶ffentlichung sind nicht freigegeben.

[ZIP-Callerrechte](ZIP-CALLER-PROFILE.md): drei bestehende ZIP-Memory-USPs,
432 MaskenzustÃ¤nde, 864 API-Routen, 192 positive Orakel, 2.808 strikte
SQL-229-Abweisungen und 15 frische Abschlussaudits. ZwÃ¶lf MatrixfÃ¤lle
bestanden; die falsche Goldenwert- und breite Schema-SELECT-Kontrolle wurden
erwartungsgemÃ¤ÃŸ bereinigt abgewiesen. Produkt-/Paketstatus und weitere
Releasegates bleiben getrennt.

[ZIP-Entryanzahl-GrenzprÃ¼fung](ZIP-ENTRY-COUNT-QUALIFICATION.md): zwÃ¶lf Ziel-/CL-FÃ¤lle prÃ¼fen das 10.000-Entry-Limit der bestehenden Listing-API lokal und direkt zentral. 24 positive Routen lieferten 240.000 feste Metadatenzeilen; 48 direkte Reader-Pfade wurden ohne erste Zeile mit den festgelegten Fehlercodes abgewiesen. ZwÃ¶lf unmittelbare und sechs zusÃ¤tzliche Abschlussaudits bestanden. Der 256-MiB-Archivgrenzwert und vollstÃ¤ndige Modulpflichten bleiben auÃŸerhalb dieses Scopes.

[XLSX-Raw-Callerrechte](XLSX-RAW-CALLER-PROFILE.md): zwÃ¶lf ausgewÃ¤hlte Ziel-/CL-FÃ¤lle mit 336 RechtezustÃ¤nden, 672 API-Routen, 144 positiven Aufrufen und 720 festen Ergebniszeilen; 12 MatrixfÃ¤lle und 15 frische Abschlussaudits bestanden. Die [Manifest- und Paketpflege](XLSX-METADATA-UPDATE.md) Ã¼bernimmt Raw- und Zellrechte; historische Source-Header bleiben unverÃ¤ndert. Weitere Releasegates bleiben offen; Head- und Main-CI werden getrennt im integrierenden PR nachgewiesen.

[XLSX-Zell-Callerrechte](XLSX-CELL-CALLER-QUALIFICATION.md): zwei Ã¶ffentliche TVFs mit einzelnem SELECT auf zwÃ¶lf lokalen/direkt zentralen Windows-/Linux-Ziel-/CL-FÃ¤llen.48 positive Profile,672 SQL229-Abweisungen und144 feste Ergebniszeilenorakel; Raw-Reader, volle Typ-/Client-/Ressourcen- und Releasegates bleiben separat.

[CSV-Manifest- und Paketpflege](CSV-METADATA-UPDATE.md): die in PR450 belegten getrennten Parser-/Writer-/ResultTable-Rechte werden exakt Ã¼bernommen. Historische AusfÃ¼hrungspins bleiben erhalten; ausfÃ¼hrbare SQL-/DLL-Payloads und weitere Releasegrenzen bleiben unverÃ¤ndert.

[CSV-Callerrechte](CSV-CALLER-PROFILE.md): getrennte Parser-/Writer-/ResultTable-Objektrechte, zwÃ¶lf lokale/direkt zentrale Ziel-/CL-FÃ¤lle, 384 RechtezustÃ¤nde, 504 feste Ergebniszeilenorakel und frische eigene BereinigungsprÃ¼fungen. Manifest-/Paketpflege und weitere Releasegates bleiben separat.

[Textpaar-Callerrechte](TEXT-PAIRS-CALLER-QUALIFICATION.md): ein EXECUTE-Grant, drei Algorithmen, zwÃ¶lf lokale/direkt zentrale Ziel-/CL-FÃ¤lle, 24 positive Profile und 216 SQL229-Abweisungen. 1008 feste Zeilenorakel und eigene Bereinigung sind belegt; weitergehende Gates bleiben separat.

[JSON-Schema-Callerrechte](JSON-SCHEMA-CALLER-PROFILE.md): drei einzelne Objektrechte, zwÃ¶lf lokale/direkt zentrale Ziel-/CL-FÃ¤lle, 168 RechtezustÃ¤nde und 240 feste FachfÃ¤lle. Neuer Labtreiber und SQL-Fixture; keine Produkt- oder PaketÃ¤nderung. Die [gebundene Metadatenkorrektur](CALLER-METADATA-UPDATE.md) Ã¼bernimmt diese Rechte jetzt in Manifest und Paket.

[JSON-Schema-Deploy-AppLock](json-schema-deploy-lock-qualification.json): genau zwei lokale Windows/SQL-Server-2025/CU8/CL170-Sperrkonflikte mit getrennten Holder-/Contender-Verbindungen, unverÃ¤ndertem Zustand nach der Abweisung und positivem Deploy nach Freigabe. FÃ¼nf frÃ¼here Fehlversuche bleiben als aufgerÃ¤umte Historie erhalten; alle sechs unabhÃ¤ngigen Audits bestanden. Diese Funktionsabnahme ergÃ¤nzt nur den angegebenen Deploy-Scope und ersetzt weder das vollstÃ¤ndige Rechte-/Lifecycleprofil noch andere Zielkombinationen.

[JSON-Schema-Uninstall-AppLock](json-schema-uninstall-lock-qualification.json): genau zwei lokale Windows/SQL-Server-2025/CU8/CL170-Sperrkonflikte bei Uninstall, jeweils mit unverÃ¤ndertem installiertem Zustand, sauberem Contender und erfolgreichem identischem Uninstall nach Freigabe. Das leere Schema-Namespace bleibt erhalten; Core und ResultTable sind einschlieÃŸlich ObjektidentitÃ¤ten und Berechtigungen unverÃ¤ndert. Ein Zielaufruf und ein unabhÃ¤ngiges Bereinigungsaudit bestanden. Dieser zusÃ¤tzliche Funktionsnachweis schlieÃŸt keine weiteren Zielkombinationen oder vollstÃ¤ndigen API-/Rechte-/Lifecycleprofile.

[JSON-Schema-Deploy-Kollisionsschutz](json-schema-deploy-collision-qualification.json): vier synthetische Abweisungen vor Mutation bei fehlendem Schema-Modul und eigenem leerem `toolbelt_json`-Namespace fÃ¼r reservierte Temp-Tabelle, fremde Ã¶ffentliche/interne Slots und verwaisten DeploymentMode-Marker auf Windows SQL Server 2025/CU8/CL170 lokal. Ein gemeinsamer positiver Deploy nach Bereinigung aller Fixtures sowie ein unabhÃ¤ngiges Cleanup-/Pin-Audit bestanden. Keine Ã¼brigen Fremdobjekt-, Marker- oder vollstÃ¤ndigen Lifecyclematrizen werden dadurch geschlossen.

[JSON-Schema-Uninstall-BestÃ¤tigung](json-schema-uninstall-confirmation-qualification.json): zwei zentrale Abweisungen (`01` ungÃ¼ltig, `0` ohne zentrale BestÃ¤tigung), jeweils 55635/State 1 mit exakter Meldung und unverÃ¤ndertem Modul-, Core- und Sessionzustand; anschlieÃŸend ein erfolgreicher Uninstall mit BestÃ¤tigung `1`. GeprÃ¼ft wurde Windows SQL Server 2025/CU8/CL170 im zentralen Funktionsmodus mit festem Startprofil `QUOTED_IDENTIFIER ON`, `NOCOUNT ON`, `XACT_ABORT ON`, `IMPLICIT_TRANSACTIONS OFF`. Ein Zielaufruf und ein unabhÃ¤ngiges Bereinigungsaudit bestanden; drei frÃ¼here bereinigte Harnessfehler bleiben getrennte Historie. Andere Sessionprofile, Modi, Ziele und vollstÃ¤ndige Lifecycle-/Rechtematrizen bleiben offen.

[JSON-Constructor-Paketqualifikation](JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.md):
27 bestehende Frameworkphasen bestanden; die gelieferten Constructor-/Core-DLLs
stimmen bytegenau mit den erzeugten Framework-DLLs Ã¼berein. Der vorhandene
JSON-Core-Closure-IL-Gate bestand direkt mit der Constructor-DLL aus dem Paket.
Keine SQL-/Labverbindung, keine Schema-Paketqualifikation und keine
Gesamtfreigabe.

[JSON-Schema-Paket-IL](JSON-SCHEMA-PACKAGE-QUALIFICATION.md) ergÃ¤nzt den
separaten direkten IL-Lauf fÃ¼r die Schema-DLL aus demselben unverÃ¤nderten
Paket. Der abgeschlossene Source-Receipt wurde mit allen 27 Phasen und frischen
Eingaben wiederverwendet; ein neuer Frameworklauf fand nicht statt. SQL-, API-,
Gesamt-CLR- und VerÃ¶ffentlichungsfreigaben bleiben getrennt.

[Edit-Distance-Paketqualifikation](EDIT-DISTANCE-PACKAGE-QUALIFICATION.md):
die DLL aus dem CLR-Paket besteht 27.104 Distance-Golden-Zeilen, 60 Jaro-Paare
in drei Kulturen und 109.333 feste Contract-Assertions. Eine begrenzte
IL-Inspektion bestand; Gesamt-CLR, SQL, API-Rechte und VerÃ¶ffentlichung sind
nicht Teil des Nachweises.

[Scriptparser-Paketbindung](SCRIPT-PARSER-PACKAGE-QUALIFICATION.md): 63
ausgewÃ¤hlte feste ProviderfÃ¤lle bestanden gegen die DLL aus dem Paket. Der
separate Source-Guard umfasst 60 Assertions; kein SQL-/Lablauf und keine
vollstÃ¤ndige Modul-, Plattform- oder transitive IL-Qualifikation. Die
[Evidenz](SCRIPT-PARSER-PACKAGE-QUALIFICATION.json) bindet 16 repo-relative
Eingabepins.

Die [SSIS-Qualifikation vom 2026-10-25](SSIS-LOOKUP-QUALIFICATION.md) ergÃ¤nzt
zwÃ¶lf explizite Windows-Engine-/CL-/ModusfÃ¤lle, den finalen Installationssatz und
je sechs neue Windows-FÃ¤lle fÃ¼r CLR- und Gesamtpaket. Historische Manifest-/API-
Snapshots werden aus ihrer gebundenen frÃ¼heren Lieferung gelesen. UnverÃ¤nderte
Linux-Payloads behalten ihre ursprÃ¼nglichen Nachweise; keine neue Linux-AusfÃ¼hrung
und keine automatische Modul- oder Gesamtfreigabe.

[CLR-String-Callerrechte](CLR-STRING-CALLER-QUALIFICATION.md): fÃ¼nf vorhandene Phonetic-/Edit-Distance-TVFs, zwÃ¶lf lokale/direkt zentrale Ziel-/CL-FÃ¤lle,120 positive Profile und1440 SQL229-Abweisungen. Entwickelt wurden Labtreiber, SicherheitsprÃ¼fungen und feste SQL-Fixtures. Eigener Trust und notwendige Testkonfiguration sind unabhÃ¤ngig als bereinigt bestÃ¤tigt; Produktquellen und Modulstatus bleiben unverÃ¤ndert.

[Event Log: Lesen und lokale Retention mit Einzelrechten](EVENT-LOG-CALLER-QUALIFICATION.md): 3 APIs, zwÃ¶lf FÃ¤lle lokal/direkt zentral, 72 Einzelgrantprofile und 648 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[Providerview mit einzelnem SELECT-Recht](PROVIDER-CALLER-QUALIFICATION.md): 1 APIs, zwÃ¶lf FÃ¤lle lokal/direkt zentral, 24 Einzelgrantprofile und 144 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[JSON Pointer mit einzelnem SELECT-Recht](POINTER-CALLER-QUALIFICATION.md): 1 APIs, zwÃ¶lf FÃ¤lle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[Capability-Katalog mit einzelnem SELECT-Recht](CATALOG-CALLER-QUALIFICATION.md): 1 APIs, zwÃ¶lf FÃ¤lle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[Konsolenausgabe mit einzelnem EXECUTE-Recht](CONSOLE-CALLER-QUALIFICATION.md): 1 APIs, zwÃ¶lf FÃ¤lle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[JSON-Pfade mit getrennten SELECT-Rechten](JSON-PATH-CALLER-QUALIFICATION.md): 2 APIs, zwÃ¶lf FÃ¤lle lokal/direkt zentral, 48 Einzelgrantprofile und 192 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.


Die [additive Date-Math-ErgÃ¤nzung](DATE-MATH-CL-COMPLETION.md) schlieÃŸt die sechs niedrigeren CL-CallerfÃ¤lle. Insgesamt zwÃ¶lf FÃ¤lle mit unverÃ¤nderter Fixture sind gebunden; der frÃ¼here Teilscope bleibt historisch erhalten. Offline zusÃ¤tzlich prÃ¼fen: `python -B Tests/Release/test_additive_caller_qualification.py`.

Basisbericht vom 2026-10-23 mit NachtrÃ¤gen vom 2026-10-24. Dies ist der PrÃ¼fbericht zur unverÃ¶ffentlichten
[Releasevorbereitung](README.md), keine Freigabe von Supportkombinationen.
Die [Freigabematrix](FREIGABEMATRIX.md) bleibt bei 19 stabilen und 26
Preview-Kandidaten; diese ZielkanÃ¤le und der [Supportumfang](SUPPORT.md) sind
ausdrÃ¼cklich freigegeben. Alle 45 Modulmanifeste bleiben `unreleased`.

## Was technisch geprÃ¼ft ist

| PrÃ¼fung | TatsÃ¤chlicher Nachweis | Grenze |
|---|---|---|
| Gepackte stabile SQL-Exports | ZwÃ¶lf erfolgreiche LabfÃ¤lle; jeweils Erstinstallation, Repeat, fÃ¼nf feste Funktionsorakel, zentraler Consumer sowie Uninstall/Repeat | Genau 19 stabile Kandidaten, keine Vollabnahme aller APIs oder Preview-Module |
| Installationsmetadaten | Alle 19 Versions-/Deploymentmarker vorhanden; Objektdefinitionen nach Repeat unverÃ¤ndert; nach Uninstall keine Modulobjekte/-marker | Eigene administrative synthetische Testdatenbanken, kein Minimalrechtenachweis |
| Bereinigung | 36 eigene Datenbanken entfernt; zwÃ¶lf separate lesende Auditprozesse bestÃ¤tigten Abwesenheit und Inputpins | Keine fremden Ressourcen, Server-, Rechte-, Login- oder TrustÃ¤nderungen |
| CLR-Buildinputs | ZwÃ¶lf vorhandene Projekte jeweils zweimal isoliert gebaut; identische DLL-Bytes, keine CodeView-EintrÃ¤ge und keine geprÃ¼ften privaten Buildpfade | Der erste Offlinebuild allein war keine vollstÃ¤ndige IL-/Framework-/SQL-Abnahme; die anschlieÃŸende Paketlieferung ist unten getrennt beschrieben |
| JSON-Binarybindung | Die drei erneut erzeugten JSON-Binaries stimmen exakt mit den kanonischen bekannten Closure-Pins Ã¼berein | Keine Erweiterung des vorhandenen nativen Supportumfangs |
| AusgewÃ¤hlte FrameworkprÃ¼fungen | Sieben frÃ¼here Suiten auf ihren Kandidaten bestanden: CSV, Phonetic, ZIP-Writer, drei Regex-Suiten und SSIS Full; zusÃ¤tzlich 27 Phasen fÃ¼r den JSON-Constructor mit exakt gebundenen Paket-DLLs | Begrenzte Frameworkprofile fÃ¼r einzelne Module; keine vollstÃ¤ndige IL-/Framework- oder SQL-Qualifikation aller zwÃ¶lf Projekte |

Am 27.10.2026 wurden die bestehenden CSV- und Phonetic-Harnesses zusÃ¤tzlich
mit den DLL-Bytes aus dem CLR-Installationspaket ausgefÃ¼hrt. Die
[Paketprofile](CLR-FRAMEWORK-PACKAGE-QUALIFICATION.md) binden drei
Kulturphasen je Modul und begrenzen den Scope auf diese CLR-VertrÃ¤ge. Die
frÃ¼heren KandidatenlÃ¤ufe bleiben als historische Evidenz erhalten; diese
neuen PaketlÃ¤ufe ersetzen weder eine vollstÃ¤ndige Modul-/Plattformmatrix noch
SQL-, Deployment-, transitive IL- oder Sicherheitsqualifikationen.

Der native Aufruf war
`Tests/Release/Invoke-StablePackageMatrix.ps1 -EvidenceDirectory <neues privates .runtime-Verzeichnis>`.
Er konsumierte den auf Commit `5b83a73aab3639b0d45b56e334fb38dc24509279`
versionierten Quellpaket-Kandidaten. Das geprÃ¼fte Produkt bleibt unverÃ¤ndert
an `756e7fb0444aedf04949409a8fab2189b9fa890f` gebunden. Die
[maschinenlesbare Projektion](qualification.json) nennt Archiv-/SQL- sowie
Adapterbindungen, konkrete abstrakte Ziel-/CL-Kombinationen und Ergebnisgrenzen.
Sie enthÃ¤lt keine LabidentitÃ¤ten, Endpoints, Connection Strings oder Rohlogs.

Die Zielmatrix ist Windows und Linux mit SQL2019 CL150, SQL2022 CL150/160
und SQL2025 CL150/160/170, jeweils lokal/zentral und mit zentralem Consumer.
Die Auswahl folgt dem vorhandenen Labvertrag einschlieÃŸlich der erlaubten
Windows-base/CU-Regel. `TestPurpose=Functional`, `Encrypt=True` und der
ausdrÃ¼cklich boolesche Trustwert des Labvertrags wurden unverÃ¤ndert verwendet.
Dies belegt keine authentifizierte TLS-Verbindung.

Die fÃ¼nf Smoke-Oracles sind Generate Series, Base64, Date Spine,
JSON Path Exists und ResultTable. Bestehende vollstÃ¤ndige Modulqualifikationen
werden nur in ihrem ursprÃ¼nglichen Scope weiterverwendet. Die PaketprÃ¼fung
erweitert weder Rechte-, Heap-/ParallelitÃ¤ts-, Host-Recovery- noch Plattformzusagen.

Ein erster Versuch scheiterte am Markerparameter des neuen Testadapters:
`nvarchar(max)` war als Wert einer SQL-Extended-Property ungeeignet.
Der Adapter verwendet jetzt einen begrenzten `nvarchar(32)`-Wert und
journaliert die DatenbankidentitÃ¤t bereits vor der Markeranlage. Die eine
zunÃ¤chst leere eigene Datenbank wurde anhand des privaten Erzeugungsintents,
der ErstellungsidentitÃ¤t und des unverÃ¤nderten leeren Scopes reconciled,
markiert, entfernt und anschlieÃŸend frisch lesend als abwesend bestÃ¤tigt.
Dieser Versuch bleibt `failed_cleaned`; die zwÃ¶lf anschlieÃŸenden finalen
GesamtlÃ¤ufe mit korrigiertem Adapter bestanden. Ein Cleanupfehler wurde nicht
als Erfolg umetikettiert und kein unverÃ¤nderter Fall blind wiederholt.

Nach diesem ersten grÃ¼nen Matrixlauf wurde im Abschlussreview die gemeinsame
Zeitreserve verschÃ¤rft: Vor einem mutierenden Fall werden jetzt Arbeit und
separater Audit reserviert. Zwei neue NegativfÃ¤lle prÃ¼fen die Abweisung vor
dem Wellenende. Alle zwÃ¶lf finalen FÃ¤lle wurden mit diesem geÃ¤nderten Wrapper
erneut erfolgreich ausgefÃ¼hrt. Ein abschlieÃŸender unabhÃ¤ngiger lesender
Audit bestÃ¤tigte alle 73 eigenen Datenbanknamen aus Erstfehler, frÃ¼herer
grÃ¼ner Matrix und finaler Matrix als abwesend. Beide erfolgreichen Matrizen
bleiben zeitlich und nach ihren jeweiligen Eingaben unterscheidbar.

Die reproduzierbare CLR-PrÃ¼fung verwendete
`Scripts/Release/check_clr_builds.py --msbuild <vorhandenes MSBuild> --output <neues direktes .runtime-Unterverzeichnis>`
auf Windows mit .NET Framework 4.8. Sie nahm nur versionierte Quellen und
die bereits gepinnte offizielle ScriptDom-DLL auf. PDB-freie Releaseflags und
synthetisches PathMap verhindern die Ãœbernahme lokaler Buildpfade. Die neuen
Kandidaten bleiben lokal: Insbesondere ersetzt ein gleicher Modulname mit
neuem Binaryhash keine bestehende native/Consumer-Qualifikation.

ErgÃ¤nzend bestanden sieben vorhandene, binarygebundene Frameworksuiten:
[CSV](../../Modules/toolbelt.file.csv-memory/Tests/README.md),
[Phonetic](../../Modules/toolbelt.string.phonetic/Tests/README.md),
[ZIP-Writer](../../Modules/toolbelt.archive.zip-memory/Tests/README.md),
[Regex Transformations/Relations/Captures](../../Modules/toolbelt.string.regex/Tests/README.md)
und [SSIS Full](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md).
Die Aufrufe konsumierten ausdrÃ¼cklich die neuen Kandidaten, verwendeten
die vorhandenen Frameworkharnesses und fÃ¼hrten kein SQL aus. Beim ersten
CSV-Setup wurde ein Evidenzpfad innerhalb des Checkouts vor TestausfÃ¼hrung
abgewiesen; nach Wahl eines neuen privaten externen Verzeichnisses bestand
die Suite. Dieser Setupfehler bleibt in der Projektion sichtbar. Es gibt
weiterhin keinen vollstÃ¤ndigen neuen Framework-/IL-/SQL-Nachweis fÃ¼r den
gesamten CLR-Satz.

Die Foundation wurde vor dem erneuten Paketbau frisch gegen Upstream geprÃ¼ft:
1.25.0 bleibt aktuell. Commit `a3567f8e5372e5f4db72dbd466323aa22c71b13a`
ergÃ¤nzt nur Foundation-eigene Release-/Navigationsdokumentation; alle 112
ausgewÃ¤hlten Transferquellen sind gegenÃ¼ber der installierten Quelle
`9e1b9974de58ea775d40c7c6045cd5057ba8b30c` bytegleich. Die bestehende
Provenienz bleibt erhalten; es gibt keinen neuen Regelpayload oder Upgrade.

Bei einem aktualisierten Quell-ZIP mÃ¼ssen beide stabilen SQL-Dateien weiterhin
exakt den hier tatsÃ¤chlich geprÃ¼ften Bytes entsprechen. Der Paketgenerator
und sein PrÃ¼fmodus kontrollieren diese Bindung zusÃ¤tzlich zum regulÃ¤ren
erneuten Export. Ein geÃ¤nderter SQL-Payload oder Adapter invalidiert den
betroffenen Nachweis. Die Paket-/Negativtests und der vollstÃ¤ndige
Dokumentationsaudit laufen im bestehenden CI; ein grÃ¼ner Strukturcheck allein
bestÃ¤tigt keine native AusfÃ¼hrung. Einzelheiten der AusfÃ¼hrung stehen im PR.

## EigenstÃ¤ndige Stable-SQL-Lieferform

Das neue [SQL-Installationspaket](STABLE-SQL-INSTALL.md) enthÃ¤lt nur die beiden
qualifizierten Stable-Payloads, unverÃ¤nderte Lizenz, Anleitung, Herkunftsmanifest
und DateiprÃ¼fsummen. Der Offlinegenerator prÃ¼ft das aktuelle Quellarchiv gegen
seine PrÃ¼fsumme und beide SQL-Dateien gegen `qualification.json`. Der heutige
Quellarchivhash unterscheidet sich vom historischen nativen Archivhash; beide
SQL-Payloads bleiben exakt gleich. Wiederverwendet wird ausschlieÃŸlich deren
bestehender nativer SQL-Scope, keine neue Gesamtarchiv- oder Modulabnahme.

Deterministische Containerbytes, exakte Dateiliste, Pfad-/Symlink-/Duplikat-
Abweisung, GrÃ¶ÃŸenlimits, unverÃ¤nderte Lizenz und SQL-Bindung sowie verweigertes
Ãœberschreiben werden offline geprÃ¼ft. ZIP_STORED mit festen Metadaten vermeidet
Kompressionsunterschiede zwischen Laufzeitumgebungen. Installation, GUI, Anmeldung und TLS
wurden fÃ¼r die neue Verpackung nicht erneut nativ ausgefÃ¼hrt. Der eigenstÃ¤ndige
Download erleichtert den vorhandenen SSMS-Weg; keine Produkt-/Manifest-/Status-
Ã¤nderung, kein SSIS-/CLR-Paketrefresh und keine VerÃ¶ffentlichung.

## Fertige CLR-DLLs und native Paketinstallation

Der anschlieÃŸende ausdrÃ¼ckliche Benutzerauftrag verlangt fertige DLLs mit
Quellcode und eine schnelle Installation ohne eigenen Build. Der zusÃ¤tzliche
[CLR-Installationssatz](CLR-INSTALL.md) enthÃ¤lt zwÃ¶lf Toolbelt-DLLs, ScriptDom,
Quellcode, Lizenzhinweise, exakte Trustwerte und fertige SQL-Dateien mit
eingebetteten Assemblybytes. Vier Profile erhalten Windows/Portable und
local/central; das Windows-Dateisystemmodul bleibt ausschlieÃŸlich lokal.
Ein optionaler PowerShell-Helper prÃ¼ft alle Paketdateien vor Tool-/SQL-Zugriff.

Zehn DLLs stammen unverÃ¤ndert aus dem bereits reproduzierbaren Doppelbuild
mit identischen Produktquellen. SSIS und Parser sowie ScriptDom werden exakt
aus dem bestehenden qualifizierten SSIS-Paket Ã¼bernommen. Die vorhandenen
Modulversionen und Dependency-/Consumerpins Ã¤ndern sich nicht. Die
[CLR-Qualifikationsprojektion](clr-qualification.json) bindet alle ausgelieferten
SQL-Payloads und DLL-Bytes an den tatsÃ¤chlich getesteten Satz sowie an die
aktuellen PrÃ¼f-/Paketierungsquellen. Die spÃ¤tere
[ODBC-Clientqualifikation](CLR-CLIENT-QUALIFICATION.md) verwendet fÃ¼r dieselben
BinÃ¤rwerte kurze SQL-Zeilenfortsetzungen und prÃ¼ft alle zwÃ¶lf Kombinationen
erneut Ã¼ber den optionalen Pakethelper. DLL-Bytes bleiben identisch; SQL- und
ZIP-Hashes Ã¤ndern sich durch die ausdrÃ¼cklich gebundene neue Lieferform.

Die endliche Welle bestand zwÃ¶lf tatsÃ¤chliche Ziel-/CL-FÃ¤lle: Windows und
Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170. Windows
prÃ¼fte die Windows-Profile, Linux die neun SAFE-Module der portablen Profile.
Jeweils Erstinstallation, explizit hashgebundener Repeat, exakte Assemblyhashes
und Modulmarkermenge, ein festes Phonetik-Wertorakel, zwei JSON-Help-Aufrufe,
zentraler Consumer, Uninstall und ausdrÃ¼cklich abwesender Uninstallrepeat
bestanden. Es gab 24 Deploymentpfade mit 36 eigenen Datenbanken und zwÃ¶lf
separate lesende Cleanup-/Pinaudits. Das ist eine PaketinstallationsprÃ¼fung,
keine vollstÃ¤ndige neue Abnahme sÃ¤mtlicher Ã¶ffentlichen APIs.

Ein erster Paketadapterlauf scheiterte am Uninstallrepeat mit noch auf
Anwesenheit gebundenem Hash. Die getrennte Datei `UninstallAbsent` erhÃ¤lt
den vorhandenen Guard; das Produkt wurde nicht geÃ¤ndert. Der Versuch bleibt
`failed_cleaned`. Ein JSON-Datumskulturfehler stoppte eine Fortsetzung vor SQL;
ein weiterer Preflight wies deaktiviertes CLR vor Mutation ab. Unter der
stehenden Testkonfigurationsfreigabe wurde erforderliches CLR vorÃ¼bergehend
aktiviert. Vorgemerkte ZustÃ¤nde und Auswirkungen wurden privat journalisiert;
die Ã¼brigen KonfigurationszustÃ¤nde blieben wirksam unverÃ¤ndert. Keine Rechte,
Sicherheitslockerung oder InfrastrukturÃ¤nderung. Nach allen Verbrauchern
bestanden Wiederherstellung und ein neuer unabhÃ¤ngiger Konfigurationsaudit.
Ein abschlieÃŸender lesender Gesamtaudit bestÃ¤tigte alle **39 eigenen
Datenbanknamen** aus Erstfehler und erfolgreicher Welle als abwesend, eigene
TrusteintrÃ¤ge entfernt und vorbestehende Trustfingerprints erhalten.

Alle Versuche teilten dasselbe ursprÃ¼ngliche Restbudget; keine grÃ¼nen FÃ¤lle
wurden zur Statusauffrischung wiederholt. Nach Abschluss wurden ausschlieÃŸlich
die PrÃ¤fix-/Gesamtabdeckungsgrenzen des Matrixwrappers verschÃ¤rft und positiv/
negativ ohne SQL geprÃ¼ft. Der exakte ausgefÃ¼hrte Wrapperhash und seine
Quellreferenz bleiben getrennt vom aktuellen Wrapper gebunden; Case-Driver,
funktionale SQL-/DLL-Inputs und tatsÃ¤chliche Ergebnisse bleiben unverÃ¤ndert.
Die Datumskulturregression prÃ¼ft den echten Budgetausdruck Ã¼ber JSON-Roundtrip
mit zwei Kulturen. Neue Laufzeit-, Minimalrechte-, Heap-/ParallelitÃ¤ts-,
Host-Recovery-, authentifizierte TLS- oder allgemeine Produktionszusagen folgen
aus der PaketprÃ¼fung nicht. GUI-Installation bleibt `not executed`.

## Gemeinsame Paketqualifikation und Lifecycle-Korrekturen am 2026-10-23

Die [maschinenlesbare Projektion](complete-qualification.json) bindet die
tatsÃ¤chliche korrigierte Vollmatrix und ihre Daten-/Methodeninputs. ZwÃ¶lf
Windows-/Linux-FÃ¤lle bestanden: SQL2019 CL150, SQL2022 CL150/160 und SQL2025
CL150/160/170, jeweils lokal/zentral und mit zentralem Consumer. Windows-local
enthielt 45 Module, Windows-central 43, Portable-local/central jeweils 40;
Plattform- und Dependencygrenzen blieben wirksam.

Je Fall bestanden Erstinstallation, explizit hashgebundener Repeat,
Assembly-/Versionsmarker- und Definitionsvergleich, feste Smoke-Oracles,
der unverÃ¤nderte Pointer-Securityfixture, zentraler Consumer, Uninstall und
Absent-Repeat. Die beiden ursprÃ¼nglich gefundenen Lifecycle-Blocker sind
damit behoben:

- Edit Distance akzeptiert ausschlieÃŸlich den bekannten Text-Pairs-Consumer
  bei gleicher Version, gleichem Hash und gleichem Modus. 24 Fremdconsumer-
  und 24 abweichende VersionsmarkerfÃ¤lle wurden weiterhin mit SQL55038
  abgewiesen; Text-Pairs-ObjektidentitÃ¤t und eigene Annotation blieben in
  allen 24 Deploymentpfaden erhalten.
- Event Log kompiliert den optionalen WorkType-Zugriff erst nach dessen
  ExistenzprÃ¼fung. Alle 24 vollstÃ¤ndigen Absent-Repeats nach Entfernung der
  Registry bestanden. 24 unvollstÃ¤ndige Event-Log-MarkerfÃ¤lle ohne Dependency
  blieben mit SQL51748 gesperrt und wurden durch die Abweisung nicht entfernt.

ZusÃ¤tzlich bestanden zwÃ¶lf **eigenstÃ¤ndige** CLR-PaketfÃ¤lle mit den geÃ¤nderten
Installations-SQL-Dateien, wiederum Erst-/Repeat-/Consumer-/Uninstall-/Absent-
Repeat und separaten Cleanup-/Pinaudits. Die [CLR-Projektion](clr-qualification.json)
unterscheidet diese tatsÃ¤chliche AusfÃ¼hrung vom frÃ¼heren Nachweis. Die privaten
Testkandidaten trugen ausdrÃ¼cklich `qualification_state=pending`; sie wurden
nicht als qualifizierte Releaseassets ausgegeben. EndgÃ¼ltige ZIPs nehmen erst
danach die tatsÃ¤chlichen Nachweise auf und mÃ¼ssen exakt dieselben SQL-/DLL-
Bytes enthalten.

Die erste Diagnose blieb `failed_cleaned` (SQL55038), die zweite ebenfalls
`failed_cleaned` (SQL208 beim Absent-Repeat). Dazwischen bestanden zwÃ¶lf
ausdrÃ¼cklich begrenzte Install-/Consumer-/Einmal-UninstallfÃ¤lle; diese wurden
nie als erfolgreiche Vollqualifikation umetikettiert. Nach dem zusÃ¤tzlichen
ausdrÃ¼cklichen Korrekturauftrag wurden zwÃ¶lf neue VollfÃ¤lle und zwÃ¶lf neue
CLR-FÃ¤lle geprÃ¼ft. Alle Phasen behielten denselben ursprÃ¼nglichen Start und
Verbrauch im erweiterten Restbudget: 38 tatsÃ¤chliche Caseversuche, Grenze
42/14400 Sekunden, keine blinden Retries oder Budgetresets.

Ein abschlieÃŸender unabhÃ¤ngiger lesender Audit bestÃ¤tigte alle **114 eigenen
Datenbanknamen** als abwesend, eigene TrusteintrÃ¤ge entfernt und vorbestehende
Trustfingerprints erhalten. Nach Abschluss aller Verbraucher wurden die
temporÃ¤ren CLR-Einstellungen wiederhergestellt; ein weiterer unabhÃ¤ngiger
Prozess bestÃ¤tigte Originalkonfiguration und Datenbank-/Assemblykataloge.
Keine Rechte-/Login-/LabinfrastrukturÃ¤nderung. Journale, tatsÃ¤chliche
Parameterwerte und Rohlogs bleiben ausschlieÃŸlich privat.

Die Produktquellen sind bytegleich als synthetischer Produkt-Snapshot
gebunden; OriginalausfÃ¼hrung und aktueller Snapshot stehen getrennt in den
Projektionen und in [product-source.json](product-source.json). Dies nimmt
keine persÃ¶nliche Commitmetadaten ins Paket auf und erweitert keine API-,
Minimalrechte-, Heap-/ParallelitÃ¤ts-, DateiidentitÃ¤ts-, Worker-Recovery- oder
authentifizierte TLS-Zusage. Alle Module bleiben `unreleased`.

## Was vor VerÃ¶ffentlichung offen bleibt

Die [Zuordnung aller 45 Module](EVIDENCE-MAP.md) und der
[API-/Grenzbericht](API-QUALIFICATION.md) konkretisieren die fachlichen
RestfÃ¤lle. Vorhandene volle Matrizen und CSV-Grenznachweise bleiben in ihrem
ursprÃ¼nglichen Scope gÃ¼ltig; die nachfolgende Tabelle ist keine Aussage,
dass sÃ¤mtliche genannten EinzelprÃ¼fungen noch fehlen.

Die zusÃ¤tzliche API-/Grenzwelle ist abgeschlossen: 74 ausgewÃ¤hlte FÃ¤lle,
73 vollstÃ¤ndig bestanden und ein Regex-Teilnachweis; zusÃ¤tzliche Fixtures
fÃ¼r 37 Module. Alle eigenen Datenbanknamen sind abwesend, Trust und
temporÃ¤re CLR-Konfiguration unabhÃ¤ngig als wiederhergestellt geprÃ¼ft.
Die [Regex-NachprÃ¼fung vom 2026-10-24](REGEX-TIMEOUT-QUALIFICATION.md)
belegt den ursprÃ¼nglichen positiven Transformationsabschluss auf einer DLL
mit weniger LOB-Kopien und unverÃ¤nderten Sicherheitsbudgets. Ein zusÃ¤tzlicher
Capture-Timeout unter Linux SQL2019/CL150 local war zunÃ¤chst offen. Die neu
geprÃ¼ften CLR-/Gesamtpaket-Lifecycles ersetzen keine Ã¼brigen PflichtfÃ¤lle.
Die anschlieÃŸende [Capture-Diagnose](CAPTURE-TIMEOUT-INVESTIGATION.md) erhÃ¤lt
jetzt den zuvor verlorenen Unterfall und CLR-Stack. Der historische Fehler
lieÃŸ sich weiterhin nicht reproduzieren. Nach ausdrÃ¼cklicher Freigabe der
Abschlussregel ist das historische Timeout-Gate fÃ¼r die exakt gebundene DLL
mit [dokumentiertem Restrisiko angenommen](CAPTURE-RELEASE-ACCEPTANCE.md).
Neue Minimalrechtetests lokal/direkt zentral bestanden in zwÃ¶lf physischen
Ziel-/CL-FÃ¤llen. Die skalare Rechte-Dokumentation ist inzwischen korrigiert
und [begrenzt qualifiziert](REGEX-RIGHTS-QUALIFICATION.md). Echte
Lowpriv-CrossDB-Mappings und Ã¼brige ModulpflichtfÃ¤lle bleiben offen.

| Gate | Konkret erforderlich | AbhÃ¤ngigkeit |
|---|---|---|
| Fachlicher Zielumfang | Erledigt: 45 bestehende Modulversionen, 19 stabil/26 Preview und SQL-/CL-/Plattform-/Deployment-Zielumfang sind ausdrÃ¼cklich Ã¼bernommen | [Benutzerfreigabe](SUPPORT.md#freigabe); konkrete Ã¶ffentliche Kombinationen brauchen weiterhin ihre vollstÃ¤ndigen Pflichtnachweise |
| Pflichtqualifikation im gewÃ¤hlten Umfang | Fehlende Minimalrechte-, API-/Lifecycle-, Datei-/IdentitÃ¤ts-/Worker-, Heap-/ParallelitÃ¤ts- oder RecoveryfÃ¤lle je Modul prÃ¼fen oder die betreffende Kombination auÃŸerhalb des verÃ¶ffentlichten Umfangs halten | Konkreter Supportumfang; gegebenenfalls bereitgestellte Principals, Fixtures oder gesonderte Recoveryumgebung |
| CLR-Lieferumfang | Erledigt: vorgebauter Installationssatz samt Quellen ist in den Zielumfang Ã¼bernommen | Keine weitere Build-/Lieferentscheidung offen; vollstÃ¤ndige fachliche Pflichtnachweise der gewÃ¤hlten Preview-Kombinationen bleiben erforderlich |
| Gemeinsamer Paket-Lifecycle | Erledigt fÃ¼r die vier abgegrenzten Profile: Erst-/Repeat-/Uninstall-/Absent-Repeat und zentrale Consumer in zwÃ¶lf physischen Ziel-/CL-FÃ¤llen; eigenstÃ¤ndige CLR-Profile nochmals separat geprÃ¼ft | Kein universeller historischer Upgradepfad und keine vollstÃ¤ndige neue APIabnahme aller 45 Module |
| Finaler Releasekandidat | PaketintegritÃ¤t, Dokumentationsaudit und echte CI am endgÃ¼ltigen Head bestÃ¤tigen; geÃ¤nderte Inputs mit betroffenem Nachweis abgleichen | Nach Abschluss der noch offenen Inhalte; heutige grÃ¼ne CI qualifiziert keine spÃ¤teren Ã„nderungen |
| Ã–ffentliche VerÃ¶ffentlichung | Separater ausdrÃ¼cklicher Auftrag; danach tatsÃ¤chlichen Tag, Release-URL, Zeitpunkt, Assethashes und `publication_record` je verÃ¶ffentlichter Modulversion pflegen | Noch nicht autorisiert; kein Tag, kein GitHub-Release und keine Statusaufwertung |

### Aktueller Restgate-Status und Voraussetzungen

Diese Ãœbersicht ordnet den verbleibenden Scope den bestehenden Nachweisen zu.
`PASS` gilt jeweils nur fÃ¼r den angegebenen Fall; es erweitert weder den
Modulstatus noch den zugesagten Produktumfang. Unkonkretisierte
manifesteigene PflichtfÃ¤lle bleiben offen, bis sie pro Modul und Kombination
benannt sind. Sie werden nicht pauschal als durch externe Voraussetzungen
blockiert behandelt.

| Gate | Status | Verbleibender Scope und Grenze | Voraussetzung | Kanonische Evidenz |
|---|---|---|---|---|
| XLSX-Listing: feste Blattanzahl | **PASS FÃœR 32/33 BLÃ„TTER** | `USP_ListXlsxWorksheets` lieferte auf 24 Routen jeweils 32 feste Zeilen; 24 33-Blatt-Aufrufe wurden mit 51520 und null gelesenen Zeilen abgewiesen. | Kein weiteres Ziel fÃ¼r diesen Grenzfall. Andere XLSX-APIs und Modulpflichten bleiben separat. | [XLSX-Grenzbericht](XLSX-BOUNDARY-QUALIFICATION.md) |
| XLSX-Rohleser: 50.000 Shared Strings | **PASS FÃœR QUELL- UND WARTUNGSPAKETDELTA** | Der korrigierte Kandidat und die ausgewÃ¤hlte Installation des aktuellen Wartungspakets bestehen 50.000/50.001 lokal/direkt zentral auf zwÃ¶lf Ziel-/CL-FÃ¤llen bei unverÃ¤ndertem 5.000-ms-Budget. ZwÃ¶lf neue unabhÃ¤ngige Audits bestanden. FÃ¼r die frÃ¼here Paket-DLL bleiben die ursprÃ¼nglichen Budgetfehler und nicht ausgefÃ¼hrten Routen historisch erhalten. | FÃ¼r diesen begrenzten Installations-/Hilfe-/SST-Delta kein weiterer Nativlauf; vollstÃ¤ndige Modul-, Lifecycle- und Ã¼brige Releasegates bleiben separat. | [Aktueller Wartungsnachweis](CLR-MAINTENANCE.md), [SST-Quellkorrektur](XLSX-SST-BUDGET-CORRECTION.md), [historischer Paketbericht](XLSX-BOUNDARY-QUALIFICATION.md) |
| Modulpflichten je zugesagter Kombination | **OFFEN; nÃ¤chste Schritte je Modul zugeordnet** | Die vorhandene 45-Modul-Ãœbersicht nennt pro teilweise qualifiziertem Modul den belegten nÃ¤chsten Schritt oder dessen Voraussetzung (zum Beispiel weitere deklarierte Ziele, Minimalrechte/IdentitÃ¤t, Lifecycle/Upgrade, Datei-/Client-/Hostverhalten oder Last/Recovery). Sie erweitert keine Supportmatrix und erzeugt keine Kombinationen allein aus Betriebssystem- oder Versionsunterschieden. Ein `validated`-Eintrag gilt fÃ¼r den dort beschriebenen Scope. Ist ein zusÃ¤tzlicher Schritt nicht benannt, ist er im Inventar nicht benannt und vor weiterer Abnahme anhand der kanonischen Matrix und des zugesagten Umfangs zu prÃ¼fen. | Nur die in Manifest und Modulmatrix tatsÃ¤chlich zugesagten, noch nicht belegten FÃ¤lle konkretisieren; pro Fall feste Eingaben und begrenztes Ziel verwenden. Externe Voraussetzungen bleiben modulbezogen. | [45-Modul-Ãœbersicht mit nÃ¤chsten Schritten](../../Tests/README.md#modulspezifische-testmatrizen), [Modulzuordnung der Evidenz](EVIDENCE-MAP.md), jeweilige kanonische Modulmatrix |
| SSIS: heutiger freigegebener Debugvertrag | **PASS IM ABGEGRENZTEN FUNKTIONSSCOPE** | Aktueller Parameter-Help-Binary und Deployment: zwölf Windows-/Engine-/CL-/Moduskontexte, 12396 Assertions, zwölf unabhängige Audits und Full26. Komponenten/Typen/Pläne, API/ResultTable, Katalog/Safety, direkte Callerrechte, Lifecycle und native 64-Gruppen-Pläne unter dem Defaultbudget sind gebunden; alte unveränderte ZIP-/Standalone-/Snapshotbelege werden quellengeprüft weiterverwendet. | Lowpriv-CrossDB-Identitäten, GUI/Windows-Anmeldung, administrativer Installer-Trust, TLS, harte Recovery, Linux-Exporthost und Produktionskapazität bleiben eigene Grenzen. Keine umfassende SSIS-Runtime-Parität, keine Veröffentlichung. Head-/Main-CI und Integration am jeweiligen Head. | [Aktueller Funktionsrecord](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.Functional.20261031.json), [Scope und Testmethode](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) |
| SSIS: aktuelles ZIP auf allen Windows-/CL-/Moduskontexten | **PASS FÃœR DEN GEBUNDENEN AKTUELLEN PAKETVERTRAG** | Zehn neue PaketfÃ¤lle mit je 206 festen Assertions und zehn unabhÃ¤ngigen Audits ergÃ¤nzen zwei unverÃ¤nderte grÃ¼ne FÃ¤lle: SQL 2019/CL150, SQL 2022/CL150/160 und SQL 2025/CL150/160/170 jeweils lokal und zentral. API-Metadaten, editierbare Defaults, SQL-Limits, ResultTable-Schutz und ausgefÃ¼hrte Row-Count-/Flatfile-Debug-Scripts sind belegt; keine vollstÃ¤ndige SSIS-Modulabnahme. | Ãœbrige Komponenten-/Ausdruckskombinationen, echte SSIS-AusfÃ¼hrung, Windowsauthentifizierung/GUI, TLS und Recovery bleiben eigene Gates. | [Aktuelle Paketmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.InstallPackage.Matrix.20261029.json), [PrÃ¼fmatrix mit Grenzen](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) |
| SSIS: aktueller Standalone-T-SQL-Installer auf allen Windows-/CL-Kontexten | **PASS FÃœR DEN GEBUNDENEN AKTUELLEN INSTALLER** | Acht neue InstallationsfÃ¤lle mit je 206 Assertions und vier unabhÃ¤ngigen Audits ergÃ¤nzen vier unverÃ¤ndert Ã¼bernommene Kontexte. FÃ¼r den festen Installer sind SQL 2019/CL150, SQL 2022/CL150/160 und SQL 2025/CL150/160/170 lokal und zentral belegt; die vier ursprÃ¼nglichen erfolgreichen Kontexte wurden nicht wiederholt. Das ist keine allgemeine SSIS-Modul- oder API-Vollabnahme. | TatsÃ¤chliche SSIS-AusfÃ¼hrung, Windowsauthentifizierung/GUI, TLS, Recovery und VerÃ¶ffentlichung bleiben eigene Gates. Head-/Main-CI und Integration werden am jeweiligen PR-/Merge-Head nachgewiesen. | [Standalone-Installer-Matrix](ssis-current-standalone-installer-matrix.json), [PrÃ¼fmatrix mit Grenzen](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) |
| SSIS: materialisierter DebugScript-Snapshot | **PASS FÃœR ZWEI FESTE KONTEXTE** | Windows SQL Server 2025/CU8/CL170 lokal und zentral: je zwei frische DebugScript-Sitzungen, 272 Assertions und ein unabhÃ¤ngiges Audit. Ein Insert aus separater Controllerverbindung nach Planmaterialisierung blieb aus den ersten Ziel-/Row-Count-Leseergebnissen ausgeschlossen; ein neu ausgefÃ¼hrter Plan sah die geÃ¤nderte Quelle. | Keine Aussage zu atomarer Sicht Ã¼ber unabhÃ¤ngige Quellen, ungeplanten parallelen Ã„nderungen wÃ¤hrend der Planeinheiten, anderen Zielkombinationen oder allgemeiner SSIS-/API-Abdeckung. Modulstatus und VerÃ¶ffentlichung bleiben unverÃ¤ndert. | [Snapshot-KohÃ¤renzbericht](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.SnapshotCoherence.20261030.json), [PrÃ¼fmatrix mit Grenzen](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) |
| ZIP-Listing: feste Entryanzahl-Grenzen | **PASS FÃœR DEN GEBUNDENEN GRENZSCOPE** | Das bestehende `USP_ListZipEntriesFromBinary` gab 10.000 synthetische EintrÃ¤ge mit festen Metadaten aus; 10.001 Archiv-Entries und `@MaxEntries = 10001` wurden vor einer direkt gelesenen Zeile abgewiesen. Dies ist keine ZIP-Modul- oder sonstige API-Vollabnahme. | Kein weiteres Ziel fÃ¼r diese beiden festen GrenzfÃ¤lle. Andere ZIP-Formate, Payload- und Modulpflichten bleiben separat. | [ZIP-Entryanzahl-Nachweis](ZIP-ENTRY-COUNT-QUALIFICATION.md), [maschinenlesbare Evidenz](zip-entry-count-qualification.json) |
| Echte Minimalrechte und CrossDB-IdentitÃ¤t | **TEILWEISE BELEGT; CROSSDB OFFEN** | AusgewÃ¤hlte Callerprofile mit engen Objektgrants sind belegt. Tests mit getrenntem Login, User-Mapping oder echten Lowpriv-CrossDB-Aufrufen bleiben eigenstÃ¤ndige FÃ¤lle; DBO- oder direkte Consumer-Profile ersetzen sie nicht. | Geeignete getrennte Principals und ausdrÃ¼cklich zugeordnete CrossDB-Mappings; kein Grant aus den vorhandenen Profilen ableiten. | [CallerrechteÃ¼bersicht](CALLER-METADATA-UPDATE.md), [API- und Grenzbericht](API-QUALIFICATION.md), jeweilige Callerprofile |
| Serverseitige Dateien und Windows-IdentitÃ¤ten | **NICHT AUSGEFÃœHRT** | ZIP-Dateien, File-Content und Windows-Filesystemzugriffe sind getrennte VertrÃ¤ge. SQL-API- und Paketprofile belegen weder Serverdateizugriff noch Caller-/ServiceAccount-, NTFS- oder Reparseverhalten. | Synthetische serverseitige Dateien und Fixture-Ownership; fÃ¼r Windows-FÃ¤lle geklÃ¤rte Caller-/ServiceAccount-IdentitÃ¤t sowie NTFS-/Reparse-Fixtures. | [API- und Grenzbericht](API-QUALIFICATION.md), [Dateimodule in der Modulzuordnung](EVIDENCE-MAP.md) |
| Zweite Session, EventLog und administrierter Provider | **NICHT AUSGEFÃœHRT** | Direkte API-, Rollback- und SessionunabhÃ¤ngigkeitsprÃ¼fungen qualifizieren keinen administrierten externen Provider. | Vorkonfigurierter administrierter Provider und eine passende bestehende Testfixture. | [API- und Grenzbericht](API-QUALIFICATION.md), [EventLog-Callerprofil](EVENT-LOG-CALLER-QUALIFICATION.md) |
| Queue 2.1 Managed-/ProviderparallelitÃ¤t | **TEILWEISE BELEGT; PROVIDERLAUF OFFEN** | Die Vier-Sessions-/Ein-Claim-Fixture und die getrennten SQL-ManagedfÃ¤lle belegen nicht den vollstÃ¤ndigen parallelen Worker-/Providerlauf. | Passende vorkonfigurierte Worker-/Providerkombinationen. | [Queue-Testmatrix](../../Modules/toolbelt.core.work-queue/Tests/WORK_QUEUE_CONTRACT_TEST_MATRIX.md), [Queue-Autorisierungsnachweis](QUEUE-AUTHORIZATION-QUALIFICATION.md), [Worker-Callerprofil](QUEUE-WORKER-RIGHTS-QUALIFICATION.md) |
| Transport-/Host-Recovery | **NICHT AUSGEFÃœHRT** | Keine harte Unterbrechung eines laufenden mutierenden Tests als Ersatz fÃ¼r einen kontrollierten Recoveryvertrag. | Gesonderte kontrollierte Recoveryumgebung und ein sicher abbrechbarer, eigener Testfall. | [API- und Grenzbericht](API-QUALIFICATION.md), [Releasegates](#was-vor-verÃ¶ffentlichung-offen-bleibt) |
| Regex-Capture-Outputgrenze | **PASS FÃœR DIE GEBUNDENE 16-MiB-GRENZE; SEPARATER CAPTURE-TEILFALL PARTIAL** | `Captures.Metadata.ps1` prÃ¼fte den Large-Output exakt bei 16 MiB (8.388.480 Capture-Codeunits plus 128 Codeunits Gruppenname) und wies anschlieÃŸend die um 2 Bytes grÃ¶ÃŸere Ausgabe mit `TBX_REGEX_OUTPUT_TOO_LARGE` ab. Das originale `Captures.Contract.sql` hatte separat unter Linux SQL Server 2019/CL150 einen Timeout; dieser Teilfall bleibt `PARTIAL` und wurde nur mit dokumentiertem Restrisiko angenommen. Das ist keine vollstÃ¤ndige Regex-Modulabnahme. | Kein erneuter Lauf dieser unverÃ¤nderten Evidenz; andere Capture-, Rechte-, Ressourcen-, Client- und Recoverypflichten bleiben separat. | [Regex-NachprÃ¼fung](REGEX-TIMEOUT-QUALIFICATION.md), [Capture-Akzeptanz](CAPTURE-RELEASE-ACCEPTANCE.md), [Capture-Diagnose](CAPTURE-TIMEOUT-INVESTIGATION.md) |
| Pflicht-LastfÃ¤lle fÃ¼r ResultTable, Base64 und Generate Series | **PASS IM ANGEGEBENEN SQL-2025-UMFANG** | ResultTable: 100.000 Zeilen Ã¼ber 50 KeepData-Aufrufe, 20 Leerungen und zehn Schemawechsel. Base64: exakter 4-MiB-Roundtrip mit NULL-, LÃ¤ngen- und Inhaltsorakeln. Generate Series: zehn Millionen eindeutige Werte mit Grenzen 1 bis 10.000.000. Diese Ergebnisse sind funktionale PflichtlastfÃ¤lle, keine Zeit- oder ProduktionskapazitÃ¤tszusage. | Die protokollierten SQL-Server-2025/Linux/CL170-FÃ¤lle ergÃ¤nzen die jeweiligen unverÃ¤nderten Plattformmatrizen; weitere Modulpflichten bleiben eigenstÃ¤ndig. | [V0c-Pflichtlaststatus](../../Tests/V0C_RELEASE_GATE_STATUS.md), [DEC-2026-036](../../Documentation/Architecture/DECISIONS.md#dec-2026-036-verpflichtende-lasttests-und-optionale-laufzeitmessungen), [ResultTable](../../Modules/toolbelt.core.result-table/README.md), [Base64](../../Modules/toolbelt.conversion.base64/README.md), [Generate Series](../../Modules/toolbelt.core.generate-series/README.md) |
| Optionale Laufzeitmessungen | **NOT EXECUTED; KEIN PFLICHTGATE** | Die drei vorstehenden funktionalen Lastorakel bleiben Pflicht. Optionale Laufzeitmessungen sind getrennt und werden nicht als fehlender Pflichtlasttest oder als PASS gewertet. | Gesonderter Auftrag fÃ¼r eine Messung; ein solcher Auftrag Ã¤ndert nicht die fachlichen Ergebnisorakel. | [DEC-2026-036](../../Documentation/Architecture/DECISIONS.md#dec-2026-036-verpflichtende-lasttests-und-optionale-laufzeitmessungen), [V0c-Pflichtlaststatus](../../Tests/V0C_RELEASE_GATE_STATUS.md) |
| Endanwender-Clients | **TEILWEISE BELEGT; GUI-/WINDOWS-LOGIN NICHT AUSGEFÃœHRT** | Der ODBC-PowerShell-Helper ist separat belegt. Dieser Nachweis deckt weder SSMS-GUI noch Windows-Authentifizierung ab. | FÃ¼r die fehlenden Clientwege jeweils konkreter Supportumfang und ein geeignetes Testziel. | [Clientqualifikation](CLR-CLIENT-QUALIFICATION.md), [API- und Grenzbericht](API-QUALIFICATION.md) |
| Authentifizierte TLS | **NOT EXECUTED; SEPARATER TRANSPORTNACHWEIS** | Funktionale LÃ¤ufe mit explizitem Lab-Trust sind kein ServeridentitÃ¤tsnachweis und blockieren keine unabhÃ¤ngigen Funktionstests. | Separater TLS-Vertrag und dafÃ¼r qualifiziertes Ziel; keine automatische Trustumschaltung. | [TLS-Consumervertrag](../../Documentation/Architecture/LAB_QUALIFIED_TLS_CONSUMER.md), [API- und Grenzbericht](API-QUALIFICATION.md) |
| Finaler Releasekandidat | **AUSSTEHEND** | PaketintegritÃ¤t, Dokumentationsaudit und erforderliche CI mÃ¼ssen am endgÃ¼ltigen integrierten Head belegt sein; danach sind alle noch anwendbaren Pflichtnachweise abzugleichen. | Abgeschlossene Pflichtnachweise und exakter finaler Head. | Dieses Dokument; [Evidenzzuordnung](EVIDENCE-MAP.md) |
| VerÃ¶ffentlichung | **NICHT AUTORISIERT** | Kein Tag, Release oder Statusupgrade aus der vorhandenen Abnahme ableiten. | Separater ausdrÃ¼cklicher VerÃ¶ffentlichungsauftrag. | [Supportumfang und Freigabe](SUPPORT.md#freigabe) |

Die Ã¤ltere Aussage in `Modules/toolbelt.string.regex/Tests/README.md`, die
16-MiB-Capturegrenze sei noch nicht in SQL ausgefÃ¼hrt, ist durch die spÃ¤tere
gebundene Regex-Evidenz Ã¼berholt. Diese ReleaseÃ¼bersicht ordnet den neueren
Nachweis ein, Ã¤ndert aber weder die alte Moduldatei noch den getrennten
`Captures.Contract.sql`-Teilbefund.

Preview ersetzt keine PflichtprÃ¼fung im zugesagten Scope. Authentifizierte
TLS-Abnahme bleibt getrennt; die optionalen Laufzeitmessungen fÃ¼r ResultTable,
Base64 und Generate Series sind kein pauschales Releasegate.

Die zusÃ¤tzliche [CallerrechteprÃ¼fung von ResultTable/Error Envelope](TABLE-ENVELOPE-RIGHTS-INVESTIGATION.md)
ist fÃ¼r fÃ¼nf enge Profile auf zwÃ¶lf Ziel-/CL-Kombinationen lokal und direkt
zentral abgeschlossen: 120 Profilszenarien und 360 strikte Rechteabweisungen.
Eine neue Breitenkontrolle wurde nach bestandener Baseline gezielt verworfen.
Vier frÃ¼here bereinigte Testfehler und ihre originalen Eingabebytes bleiben
historisch erhalten; der Produktcode und die Paket-SQL-/DLL-Bytes blieben gleich.
Der ResultTable-Lesepfad verweist seit 2026-10-25 auf den kanonischen
Manifeststatus und die aktuelle V0c-Abnahme; frÃ¼here Statustexte sind als
Historie getrennt. Dies ist eine Dokumentationskorrektur ohne Statusaufwertung.
Der unverÃ¤nderte archivierte Paketstand bleibt an seine ursprÃ¼nglichen
Dokumentationsbytes gebunden; der endgÃ¼ltige Releasekandidat muss den
korrigierten Lesepfad samt passenden Quellen-/Paketbindungen Ã¼bernehmen.
Bestehende gÃ¼ltige Nachweise werden weder umetikettiert noch pauschal verworfen.

Am 2026-10-25 sind zusÃ¤tzlich die sechs Ã¶ffentlichen
[Work-Type-Callerprofile](WORK-TYPE-RIGHTS-QUALIFICATION.md) auf zwÃ¶lf
Ziel-/CL-Kombinationen lokal und direkt zentral geprÃ¼ft: 144 positive Profile,
1.368 strikte Abweisungen und unabhÃ¤ngige Audits aller eigenen Ressourcen.
Notwendige Handler-/Policyrechte sind ausdrÃ¼cklich getrennt. Produktquellen,
Paketbytes und Modulstatus blieben unverÃ¤ndert; echte CrossDB-IdentitÃ¤ten und
weitere Policy-/Rollen-/LifecyclevertrÃ¤ge bleiben offen.

Der [Queue-Autorisierungsvertrag vom 2026-10-25](QUEUE-AUTHORIZATION-QUALIFICATION.md)
ist ebenfalls auf zwÃ¶lf Ziel-/CL-Kombinationen lokal/direkt zentral geprÃ¼ft.
Producer-Policy, ausfÃ¼hrbarer Handler, DENY vor Idempotenzauskunft und
Callertransaktionsschutz sind fÃ¼r die bestehende feste Fixture belegt;
vollstÃ¤ndige API-Minimalrechte, Managed-/ProviderparallelitÃ¤t und harte
Recovery bleiben davon unabhÃ¤ngig offen.

Die [sechs Safe-Cast-Callerprofile](SAFE-CAST-RIGHTS-QUALIFICATION.md) sind
zusÃ¤tzlich auf zwÃ¶lf Ziel-/CL-Kombinationen lokal/direkt zentral mit jeweils
einem einzelnen SELECT geprÃ¼ft. Die neue Rechtequalifikation ersetzt keine
Lifecycle-DDL-, echte CrossDB-, harte Recovery- oder ProduktionskapazitÃ¤tsabnahme.

Die [Cancellation-Callerrechte](CANCELLATION-RIGHTS-QUALIFICATION.md) sind
ebenfalls fÃ¼r drei isolierte API-Profile auf zwÃ¶lf Ziel-/CL-Kombinationen
lokal/direkt zentral geprÃ¼ft. Das schlieÃŸt keine Quoten-, Konkurrenz-,
Retention-, Lifecycle-, CrossDB- oder Recoverygates mit ein.

Die [zusÃ¤tzliche Geo-SQL-Matrix](GEO-MISSING-TARGETS-QUALIFICATION.md) ergÃ¤nzt
acht bisher fehlende Ziel-/CL-Kombinationen lokal/direkt zentral mit unverÃ¤nderten
Geo-/Safety-/SQL-MetadatenvertrÃ¤gen. Sie erweitert weder historische
Client-/Lifecycle-Abnahmen noch den Modulstatus oder die VerÃ¶ffentlichung.

Die [Konvertierungs-Callerprofile](CONVERSION-CALLER-QUALIFICATION.md) ergÃ¤nzen
16 Ã¶ffentliche Base64-/IntegerBase-/URI-Funktionen einschlieÃŸlich Status-TVFs
und Scalarwrappern: zwÃ¶lf lokale/direkt zentrale Ziel-/CL-FÃ¤lle mit einzelnen
SELECT-/EXECUTE-Grants. Die [Metadatenkorrektur](CALLER-METADATA-UPDATE.md) schlieÃŸt die pauschalen
Manifestlabels dieser drei Module; keine Statusaufwertung.

Die [Series-/Datums-Callerprofile](SERIES-DATE-CALLER-QUALIFICATION.md) ergÃ¤nzen
neun Ã¶ffentliche GenerateSeries-/DateSpine-/Truncate-TVFs einschlieÃŸlich der
begrenzten Series-Status-API. ZwÃ¶lf lokale/direkt zentrale Ziel-/CL-FÃ¤lle belegen
je ein SELECT; interne Core-/Helperrechte und andere APIs bleiben getrennt.
Keine Erweiterung alter Last-/Client-/Lifecycle- oder CrossDB-Nachweise.

Die [Utility-Callerprofile](UTILITY-CALLER-QUALIFICATION.md) ergÃ¤nzen16 Ã¶ffentliche
Bit-/Trim-/Split-/Identifier-/SemVer-Funktionen mit getrennten SELECT-/EXECUTE-
Grants auf zwÃ¶lf lokalen/direkt zentralen Ziel-/CL-Kombinationen. Opake Sort Keys
werden nach ihrem Ordnungsvertrag geprÃ¼ft; breite Rechte bleiben ausgeschlossen.
Andere API-/Ressourcen-/Lifecycle- und Paket-/Metadatengates bleiben separat.

Die [ausgewÃ¤hlten Date-Math-Callerprofile](DATE-MATH-HIGHEST-CL-QUALIFICATION.md)
belegen vier TVFs auf Windows/Linux SQL2019/CL150,SQL2022/CL160 undSQL2025/CL170
lokal/direkt zentral als damaligen Teilscope. Die [additive ErgÃ¤nzung](DATE-MATH-CL-COMPLETION.md)
schlieÃŸt inzwischen die sechs niedrigeren CL-FÃ¤lle mit identischen Inputs.
Die volle Caller-Matrix umfasst zwÃ¶lf FÃ¤lle; Modulstatus und weitere Gates bleiben separat.

Die [Pseudonymisierungs-Callerrechte](DETERMINISTIC-RIGHTS-QUALIFICATION.md)
ergÃ¤nzen vier TVFs und Lookup mit Einzelgrants sowie den getrennten
Lookup-/Helperpfad auf zwÃ¶lf lokalen/direkt zentralen Ziel-/CL-Kombinationen.
GroÃŸwert-/Konkurrenz-/Lifecycle-, echte CrossDB- und Recoverygates bleiben separat.

Die [Queue-Frontend-Callerrechte](QUEUE-FRONTEND-RIGHTS-QUALIFICATION.md)
und [Worker-Callerrechte](QUEUE-WORKER-RIGHTS-QUALIFICATION.md) belegen direkte
Callerprofile aller 13 Ã¶ffentlichen Queue-APIs auf zwÃ¶lf Ziel-/CL-Kombinationen.
Die befÃ¼llte Blockerview ist vor/nach eigenem Complete geprÃ¼ft; Snapshotanlage,
Managed-/Provider-/Workerhost-, ResultTable-Ausgabe-, volle Lifecycle-/
ParallelitÃ¤ts-/Ressourcen- und harte RecoveryvertrÃ¤ge bleiben separat.

Die [Split-Advanced-Callerrechte](SPLIT-ADVANCED-RIGHTS-QUALIFICATION.md)
sind durch den [ergÃ¤nzenden CL-Abschluss](SPLIT-ADVANCED-CL-COMPLETION.md)
auf zwÃ¶lf Ziel-/CL-Kombinationen lokal/direkt zentral belegt. Sechs niedrigere
CL-FÃ¤lle wurden neu geprÃ¼ft, die bisherigen sechs FÃ¤lle bei identischen
Inputs wiederverwendet. Andere Lifecycle-/CrossDB-/RecoveryvertrÃ¤ge bleiben offen.

Die verbleibenden Arbeiten sind damit genauer getrennt:

| Punkt | Noch erforderlich | Voraussetzung / Verantwortung |
|---|---|---|
| Fachliche Modulabnahme | Nachweiszuordnung aller 45 Module liegt vor. Noch unbelegte API-, Ausgabegrenzen-, Lifecycle-/Upgrade- und ClientfÃ¤lle je zugesagter Kombination abschlieÃŸen. Historisches Capture-Timeout-Gate begrenzt angenommen; skalare Rechte-Dokumentation korrigiert und [begrenzt qualifiziert](REGEX-RIGHTS-QUALIFICATION.md). AusgewÃ¤hlte grÃ¼ne Fixtures ersetzen keine volle Modulabnahme | Modulverantwortlicher; bestehende unverÃ¤nderte Nachweise nur in ihrem belegten Scope weiterverwenden |
| Minimalrechte | Die sechs Regex-Skalarfunktionen, alle fÃ¼nf Ã¶ffentlichen [Execution-Context-APIs](EXECUTION-CONTEXT-RIGHTS-QUALIFICATION.md) und fÃ¼nf [ResultTable-/Error-Envelope-Profile](TABLE-ENVELOPE-RIGHTS-INVESTIGATION.md) sind jeweils lokal und direkt zentral auf zwÃ¶lf Ziel-/CL-Kombinationen mit eigenen Benutzern ohne Login geprÃ¼ft; andere APIs und echte CrossDB-IdentitÃ¤tsmappings bleiben separat | Der ausdrÃ¼cklich freigegebene enge Datenbank-Testaufbau wurde vollstÃ¤ndig bereinigt. Execution Context prÃ¼ft jeweils nur ein Objektrecht und die Abweisung der vier anderen APIs. Keine Server-Logins oder fremden Rechte; weitere Principals nur mit passender Freigabe |
| Datei-/IdentitÃ¤tsmodule | Serverseitige synthetische Datei-, NTFS-/Reparse-/Caller-/ServiceAccount-Fixtures und ihre jeweiligen positiven/negativen FÃ¤lle | Bereitgestellte Fixtures/IdentitÃ¤ten mit geklÃ¤rter Ownership; keine eigenmÃ¤chtige Ã„nderung der Labinfrastruktur |
| Provider/Worker und harte Recovery | Erforderliche administrierte Provider-/Workerhostkombinationen und kontrollierter echter Transport-/Hostverlust | Vorkonfigurierte Provider und geeignete gesonderte Recoveryumgebung; laufende mutierende Tests werden nicht als Ersatz hart abgebrochen |
| Weitere Ressourcen-/Parallelgrenzen | Die modulspezifisch weiterhin verpflichtenden Last-/Heap-/ParallelfÃ¤lle | Je Modul begrenzter gesonderter Testscope und passende Voraussetzungen; die drei ausdrÃ¼cklich optionalen Laufzeitmessungen bleiben optional |
| Endanwender-Clientwege | Der optionale ODBC-PowerShell-Helper ist mit expliziter SQL-Anmeldung auf zwÃ¶lf Ziel-/CL-Kombinationen [nativ geprÃ¼ft](CLR-CLIENT-QUALIFICATION.md); SSMS-GUI und Windows-Anmeldung bleiben `not executed` | Noch ausstehende GUI-/Windows-IdentitÃ¤tsprÃ¼fung; fachliche Modul- und TLS-Gates bleiben separat |

FÃ¼r Kanalaufteilung, grundsÃ¤tzlichen Plattform-/Deployment-Zielumfang und die
Lieferung fertiger CLR-DLLs ist keine erneute Grundsatzentscheidung offen.
Die explizite Ã¶ffentliche VerÃ¶ffentlichungsfreigabe bleibt ausstehend.

## Aufwand und Fortsetzung

Die aktuelle SSIS-Paketmatrix ergÃ¤nzt zehn fehlende FÃ¤lle samt zehn unabhÃ¤ngigen
Audits und Ã¼bernimmt zwei unverÃ¤nderte grÃ¼ne FÃ¤lle ohne erneuten SQL-Lauf.
Ein Luna-Implementierer und das integrierende Vertrags-/Evidenzreview genÃ¼gen.
Sechs OfflineprÃ¼fungen fÃ¼r Zusammensetzung und Manipulationsabwehr laufen im
bestehenden SSIS-Workflow; es entstehen weder ein weiterer Workflow noch ein
SQL-CI-Lauf, Prozessrunner oder eine zusÃ¤tzliche Reviewkette. Lokal werden nur
geÃ¤nderte PrÃ¼fungen ausgefÃ¼hrt; PflichtprÃ¼fungen am aktuellen Head und die echte
Main-Push-CI bleiben erforderlich. Rohprotokolle bleiben privat; Kosten und
Tokens sind unbekannt. Produkt und Paketbytes bleiben unverÃ¤ndert.

Die Head-CI fand auÃŸerdem eine zu enge Ã¤uÃŸere 30-Sekunden-Grenze der
Release-Regressionssuite. Diese ist auf weiterhin endliche 120 Sekunden
angehoben; Umfang, Assertions und einzelne Prozessgrenzen bleiben erhalten.
Ein zunÃ¤chst nur generisch fehlgeschlagener Edit-Distance-Frameworklauf
bestand lokal und im folgenden Head-Lauf. Seine genaue Erstursache bleibt
nicht reproduziert; der bestehende Workflow meldet kÃ¼nftig begrenzt feste
Prozessfehlercodes und Quellzeilen statt privater Prozessdetails. Beide
CI-Anpassungen Ã¤ndern keine Produkt-, SQL-, DLL- oder nativen Testinputs.
Es entstehen keine neuen Jobs, Trigger, TestfÃ¤lle oder Reviewketten; die
grÃ¶ÃŸere Ã¤uÃŸere Reserve gilt nur der vorhandenen Offline-Regressionssuite.
Aktuelle Head-Ergebnisse werden im bestehenden PR gefÃ¼hrt.

Der zusÃ¤tzliche menschliche Installationsauftrag wird durch `INSTALL.md`
und direkte Einstiege aus Root-README, DokumentationsÃ¼bersicht und Paketstart
erfÃ¼llt. Die Anleitung trennt den Endanwenderweg mit verpflichtendem
ZIP-PrÃ¼fsummenvergleich von der weiterhin vollstÃ¤ndigen Maintainer-/CI-
QuellprÃ¼fung. SSMS-MenÃ¼s und Verbindungsdialoge sind anhand der verlinkten
Microsoft-PrimÃ¤rquellen geprÃ¼ft; ein neuer SSMS-GUI-Lauf ist `not executed`.
Die gezeigten Funktionen und Parameter entsprechen den nativen Paketorakeln.

Die bisherige Root-README-Prosa bleibt mit rebasierten Links unter
`Documentation/History/` erhalten. FrÃ¼here Abschnittslinks bleiben erreichbar,
geschÃ¼tzte Lizenztexte bleiben unverÃ¤ndert. Der Inventarcheck liest den
kanonischen generierten Modulkatalog und kontrolliert die beiden Einstiege
aus der Root-README. Fehlende, zusÃ¤tzliche oder doppelte Module sowie fehlende
Installations-/Kataloglinks werden weiter abgewiesen; drei gezielte
Regressionen laufen in der bestehenden Katalogsuite. Es entsteht weder eine
zweite Modulliste noch ein neuer CI-Job. Die Release-Freigabematrix fÃ¼hrt pro
Modul direkt zur lesbaren Modul-README statt zuerst zum YAML-Manifest.

Ein Implementierungsverantwortlicher, ein Arbeitspaket und ein PR; keine
Delegation, neue CI-Workflows oder automatischen Folgewellen. Native PrÃ¼fungen
wurden endlich ausgewÃ¤hlt, Inputs privat eingefroren und pro Fall begrenzt;
der konkrete Markerfehler begrÃ¼ndete den korrigierten Folgeversuch.
Die zwei isolierten CLR-Builds prÃ¼fen ausdrÃ¼cklich Reproduzierbarkeit, keine
Statusauffrischung vorhandener Modulnachweise. ZusÃ¤tzliche Harness-/Pfadguards
laufen ohne SQL innerhalb der bestehenden Release-Regressionssuite. Kosten-
und Tokenverbrauch sind `UNKNOWN`. Die spÃ¤tere ausdrÃ¼ckliche
[Releasefortsetzung](SUPPORT.md#releasefortsetzung-vom-2026-10-24) aktiviert
jetzt autonome Arbeit im bestehenden v1.0.0-Zielumfang und einen Heartbeat als
Stillstand-Sicherungsnetz; VerÃ¶ffentlichung bleibt ein eigener Auftrag.

## JSON-Schema-Callertransaktionen

Der [gebundene Caller-Transaktionsnachweis](json-schema-caller-transaction-qualification.json)
qualifiziert ausschlieÃŸlich Deploy bei fehlendem Schema und Uninstall bei
installiertem Schema auf Windows SQL Server 2025/CU8/CL170 lokal. Beide
Ablehnungen erhalten die aktive Callertransaktion, den Savepoint, den
Modulzustand und die Sessionoptionen; beide Aufrufe gelingen nach vollstÃ¤ndigem
Rollback ohne Callertransaktion. Das Startprofil ist fest auf
`QUOTED_IDENTIFIER ON`, `XACT_ABORT OFF` und `NOCOUNT OFF` gesetzt. Ein
erfolgreicher Zielaufruf mit zwei FachfÃ¤llen und beide unabhÃ¤ngigen Bereinigungsaudits bestanden;
ein vorangegangener bereinigter Vorversuch ist getrennt erfasst. Der Nachweis
erweitert keine anderen Sessionprofile, Ziele oder vollstÃ¤ndigen API-, Rechte-
und Lifecyclematrizen. Produkt- und Paketbytes blieben unverÃ¤ndert; eine
VerÃ¶ffentlichung ist nicht autorisiert.

## JSON-Schema-Deploy-Kollisionsschutz

Der [gebundene Nachweis](json-schema-deploy-collision-qualification.json)
qualifiziert vier feste Deploy-Abweisungen bei fehlendem Schema-Modul und
eigenem leerem `toolbelt_json`-Namespace auf Windows SQL Server 2025/CU8/CL170
lokal: reservierter Caller-Tempzustand (55633/State 1),
fremder Ã¶ffentlicher und interner Slot sowie verwaister DeploymentMode-Marker
(jeweils 55634/State 1). Jeder Fehler erhÃ¤lt den vollstÃ¤ndigen Modulzustand
und seine synthetische Fixture bis zur geprÃ¼ften eigenen Bereinigung. Erst
danach folgt ein gemeinsamer erfolgreicher Deploy. Ein Zielaufruf und ein
unabhÃ¤ngiges Cleanup-/Pin-Audit bestanden, ohne fehlgeschlagene Nativeversuche.
Der Scope ist keine vollstÃ¤ndige Fremdslot-, Marker-, Rechte- oder
Lifecyclequalifikation; Produkt und Paket blieben unverÃ¤ndert.
