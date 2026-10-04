# Paarvergleich – freigegebener Vor-Source-Vertrag 1.0.0

Stand 2026-10-03. Modul `toolbelt.string.text-pairs`, Version1.0.0. Die bestehende Einzelfreigabe vom 2026-10-01 umfasst `toolbelt_string.USP_CompareTextPairs`. Nach gesonderter Besprechung bestätigte der Benutzer am 2026-10-03 die zusätzliche eigene Modul-/Lifecyclegrenze mit „das passt für mich so“. Die anschließende ausdrückliche Wiederaufnahme der autonomen Umsetzung bestätigt die konkretisierten fünf Zusatzentscheidungen: eigenes Wrappermodul, Signatur/Input, Resultstatus, konservative Batchbudgets und administrative Hash-/Sichtbindung. Der korrigierte Vorschlag wurde vor Source durch Root und unabhängig geprüft. **Sourcegate geschlossen.** Die Implementierung und die gezielten Runtime-Nachweise sind inzwischen getrennt dokumentiert; [Nachweisstand](../../Modules/toolbelt.string.text-pairs/Tests/README.md). Vollständige Produktqualifikation bleibt offen. Kein vorhandener Distanz-/Jaro-Nachweis ist ein Nachweis dieser USP.

## Inventar und unveränderte Dependencies

Genau eine öffentliche Stored Procedure; keine zusätzliche Function, Assembly, CLR-EntryPoint, Tabelle, Type, Synonym oder Budget-/Unicode-API. Der Wrapper verwendet ausschließlich die drei bestehenden öffentlichen Inline-TVFs `TVF_LevenshteinDistance`, `TVF_OsaDistance`, `TVF_JaroWinklerSimilarity` und `toolbelt_core.USP_PrepareResultTable`. Ihre Kernverträge und Binarybytes werden nicht geändert. Nach sicherem dynamischem Inputsnapshot stehen drei statische Fachzweige; same-database Dependencies bleiben im Katalog sichtbar. Kein zweiter Vergleichskern, INSERT EXEC oder dynamisches Funktionsziel.

Dependencies in derselben Installationsdatenbank: `toolbelt.string.edit-distance` mindestens1.1.0, erster bekannter Release exakt1.1.0; `toolbelt.core.result-table` mindestens1.0.0, erster bekannter Release exakt1.0.0. Mindestversion allein erlaubt keine unbekannte Zukunftsversion. Local und central verwenden denselben Kern; zentraler Caller ruft die USP dreiteilig auf und übergibt seine sessionlokalen Temps. Keine Cross-database-Dependencyinstallation oder Runtime-Datenbankwahl.

## Öffentliche Signatur

|Position|Parameter|Typ|Default|
|---:|---|---|---|
|1|PairsTable|sysname|NULL|
|2|Algorithm|nvarchar(max)|NULL|
|3|MaxDistance|int|NULL|
|4|Profile|nvarchar(max)|N'standard'|
|5|MaxPairs|int|10000|
|6|MaxTotalTextBytes|bigint|2097152|
|7|MaxTotalWork|bigint|16777216|
|8|ResultTable|sysname|NULL|
|9|KeepData|bit|0|
|10|Debug|tinyint|0|
|11|Hilfe|bit|0|

Algorithm bytegenau `levenshtein`, `osa` oder `jaro-winkler`, kein Trim/Casefold/Padding. Algorithmus, Profil und Schwelle gelten global. Jaro mit nicht-NULL MaxDistance ist Aufruffehler auch bei leerem/NULL-Input. Distanzschwellen einschließlich negativer Werte und Profile einschließlich NULL werden unverändert an den bestehenden Kern übergeben; Kernpriorität bleibt. NULL KeepData/Debug/Hilfe bedeutet0; ResultTableNULL bleibt SELECT-Routing. BudgetNULL ist ungültig. Help1 gewinnt vor allen Fach-/Dependency-/Transaktionsprüfungen, ignoriert Debug/ResultTable und gibt ausschließlich Help1.0 nach dem USP-Vertrag aus.

## Eingabe, Grenzen und Reihenfolge

Vorhandene lokale #Temp, genau ein führendes#, höchstens116 UTF16-Einheiten, kein Multipart/##/#tbx_-Name. Einmal U-object_id auflösen, anschließend tempdb-Katalog über ID. Drei bytegenau benannte Systemspalten: `PairOrdinal bigint`, `LeftText nvarchar(max)`, `RightText nvarchar(max)`. Keine Alias-/CLR-/computed/generated/hidden/encrypted Fachspalten. Physische Positionen und column_id-Lücken unerheblich; zusätzliche Spalten ignoriert. Ordinals nicht NULL/eindeutig, kompletter signed-bigint-Bereich einschließlich0, Lücken/Identity zulässig. Nullable Metadaten erlaubt, Datenregel zwingend. Texte nullable oder NOT NULL, Collation beliebig; keine Textnormalisierung. Input und ResultTable dürfen nicht dasselbe Objekt sein.

MARS-/parallele Input-/Outputmutation während des synchronen Aufrufs ist nicht unterstützt. Row-/Byteadmission vor LOBsnapshotkopie; Snapshot erneut auf Ordinals/Count/Bytes prüfen; gesamte Workadmission vor jedem TVF-Aufruf. Keine Allokationsgarantie bei Verletzung der Stabilitätsvoraussetzung. Interne #tbx_-Objekte routinenspezifisch, eigene Kollisionen vor DDL abweisen, Drop nur eigene Objekte.

Hardcaps: MaxPairs100000, MaxTotalTextBytes16777216, MaxTotalWork67108864; Parameter jeweils1..Hardcap. Alle Inputzeilen zählen einschließlich NULL-Paare. Beide DATALENGTH-Textseiten zählen auch bei NULL-Gegenseite, trailing spaces/NUL unverändert. uL/uR=DATALENGTH/2 als bigint. NULL-Paar Workcharge0, sonst min(uL*uR,Cap); Cap1048576 bei bytegenau standard, sonst16777216 einschließlich ungültigem/NULL Profil. Kein Threshold-/Supplementary-/Fehler-/Identitätsrabatt; leeres Produkt0. Checked/sättigende Einzelcharge und `next > Limit-current` vor Addition, nie erfolgreiche Abklemmung der Gesamtsumme. Globale Reservation ist keine tatsächliche CPU-/Heap-/Hardwall-/Invocationzählung; lineare Validierung/Transport ist nicht Work, Count/Bytes begrenzen separat. Bestehende Appendzeilen liegen außerhalb der Inputbudgets.

## Vollständig materialisierte Ergebnisse

Fünf Spalten: PairOrdinal bigint NOT NULL; Distance int NULL; ExceedsMaxDistance bit NULL; Similarity float(53) NULL; ErrorCode int NOT NULL. Genau eine logische Zeile je Snapshotordinal. Direkter SELECT ORDER BY PairOrdinal; Tempresultate haben keine physische Ordnung. Keine Texte/Rangfolge/Dedup; Append prüft keine Ordinale bestehender Daten auf Eindeutigkeit.

Distanz nur Codes0..6, Similarity immerNULL. Code0 bei NULL-Text: Distance/ExceedsNULL; sonst exact Distance>=0/Exceeds0 (bei gesetzter Schwelle Distance<=Schwelle), oder DistanceNULL/Exceeds1 ausschließlich bei nichtnegativer gesetzter Schwelle. Codes1..6: beideNULL. Jaro nur0,1,3,4,5,6, Distance/Exceeds immerNULL; Code0 mit NULL-Text SimilarityNULL, sonst endliche Similarity0..1; Fehlercodes SimilarityNULL. Kein ProviderNULL-/fehlendeZeile-/unknownCode-Erfolgsfallback. Snapshot↔Result Relation und Anzahl exakt. Fachfehler sind gemischte normale Pair-Ergebnisse; technische und globale Fehler verwerfen den gesamten Aufruf.

Help → nondooming Caller-Stateguard vor eigener Temp-DDL → globale Argumente → Namen/Shape/Alias/Kollisionen → Count/Bytes/Snapshot/Ordinals/Work → TVFs → vollständige Resultkohärenz → Publish. Globale Fehler gewinnen vor Paircodes. Kern-NULL/Profil/Schwellen/Raw/UTF16/Scalar/Workpriorität unverändert.

ResultTableNULL erst nach vollständiger Materialisierung genau ein SELECT; keine atomare Clientübertragungszusage. ResultTable-Publish umfasst Helper UND finalen expliziten Insert in derselben eigenen TX (TC0) oder Caller-Savepoint (committable). OwnTX allein commit/rollback; Caller-State1 nur eigener Savepoint, nie Outercommit/-rollback. State-1 kann nicht zum Savepoint zurückrollen, Originalfehler/Zustand bleibt Caller. Distributed Savepointpfad nicht unterstützt: SAVE vor Helpermutation muss gelingen. SELECTpfad braucht keinen Publishsavepoint. Leerer Input folgt regulärem Replace/Append; alle vier KeepDatafälle/Blocker gemäß Helper1.0. Keine dauerhaften SET-Änderungen. Cleanupfehler sekundär, Originalfehler unverändert.

## Lifecycle, Hash und Rechte

Genehmigter Deployparameter `ExpectedComparisonAssemblyHash`: verpflichtendes SQLCMD-0x+128Hex-Format, genau64 SHA2-512-Bytes des tatsächlich gebundenen Releasebinary. Vor Mutation und erneut unter eigener AppLock: bekannte Dependencies/byteexakte ModuleId/Version/Mode, exakte P/IF/FT-Slots/Signaturen/Resulttypen, SAFE-Assemblybinding sowie voller Hauptfilecontenthash. Kein CLR-Versionslabel als Binarybeweis; kein KnownArtifactRegistryvertrag. Wrapper ändert/installiert nie Assembly/Trust/Dependencies/Rechte.

Die bekannte Distanzversion1.1.0 speichert DeploymentMode am Modul-Datenbankmarker; ihre sechs Objektmarker enthalten ModuleId/ModuleVersion. ResultTable1.0.0 speichert Mode zusätzlich am P-Objekt. Der Wrapper prüft diese vorhandenen Repräsentationen ohne Marker nachzurüsten. Zusätzlich vorhandene Objekt-Mode-Marker dürfen dem erwarteten Mode nicht widersprechen. Der verpflichtende Datenbank-Mode-Nachweis beider Dependencies bleibt unverändert.

Deploy/Uninstall verlangen vorhandenes datenbankweites VIEW DEFINITION und SELECT auf sys.sql_expression_dependencies, exakt1, 0/NULL blockieren vor Mutation und erneut unter Lock. Administrative Hashsicht muss vollständig sein. Keine GRANTs/Ownerfix/EXECUTE AS/Configänderung. Runtime kein ExpectedHash oder Assemblyfilelesen und kein datenbankweites VIEW DEFINITION; benötigte EXECUTE/SELECT-Rechte und caller-eigene Tempmetadaten genügen nach tatsächlicher Ownershipchain. Minimalrechte sind Prüfpflicht, kein geplanter PASS.

Bekannte eigene P/Modulemarker vor und unter Lock, Fremdkollisionen/unknownRelease/inkohärente Marker erhalten. Reinstall eigener bekannter Source möglich, SourceHash diagnostisch. Das bereits von den Dependencies benötigte Schema wird weder erzeugt, adoptiert, umgeowned noch entfernt; der Wrapper besitzt ausschließlich seine eigene P und Modulmarker. Uninstall nur eigene P, nie Dependencies; sichtbare statische Consumers blockieren, central benötigt explizite NoExternalConsumers-Bestätigung.

Nach aktueller kollisionsfreier Repositorysuche wird für dieses Modul Runtime55100..55109 und Lifecycle55120..55129 verwendet; die Kern-Fachcodes0..6 und Helper51020..51029 bleiben unverändert. Konkrete State-/Fehlerbelegung folgt Source/Objektdokumentation konsistent, keine anderen Module umnummerieren.

## Nachweisgates

Gezielte Runtime-Evidenz ist im Modul-Nachweisstand abgegrenzt; aktuelle PR-Head-CI und Veröffentlichung bleiben getrennte Gates. Die folgende vollständige Pflichtmatrix ist damit nicht insgesamt erfüllt. Pflichtprüfungen:11Parameter/Help/Fünffelder; zulässige und unzulässige Inputtypen/NULL/Ordinals; alle Algorithmen gegen bestehende TVFs inkl hardGoldens und Kerncodes; Count/Text/Work minus/at/plus und sättigende Bigintarithmetik; sämtliche KeepData-/Empty-/lateConstraint-/CallerON/OFF/doomed/SETfälle; Help bei später fehlenden statischen Dependencies als konkretes Compilation/Bindinggate; localcentral/SC-UTF8/client/EOF; bekannte Dependencies/Hashwrong/Markerpadding/Mode/Visibility/AppLock/first-repeat-uninstall/Consumererhalt; fresh ownscopeCleanup und exakte Head-CI. Sourcevorhandensein ist kein PASS.

Primärreferenzen: [DATALENGTH](https://learn.microsoft.com/en-us/sql/t-sql/functions/datalength-transact-sql), [SAVE TRANSACTION](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/save-transaction-transact-sql), [Metadatensicht](https://learn.microsoft.com/en-us/sql/relational-databases/security/metadata-visibility-configuration). Bestehende Regeln: [USP](../Standards/USP_CONTRACT.md), [ResultTable](RESULT_TABLE_MODULE_DESIGN.md), [Distanz](EDIT_DISTANCE_CONTRACT.md), [Jaro](JARO_WINKLER_CONTRACT.md), [Deployment](DEPLOYMENT_MODEL.md).
