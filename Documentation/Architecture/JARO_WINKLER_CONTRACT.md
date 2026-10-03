# Jaro-Winkler im vorhandenen SAFE-Provider 1.1.0

Stand 2026-10-03. Die Einzelfreigabe vom 2026-10-01 umfasst genau
`TVF_JaroWinklerSimilarity`. Nach Besprechung des konkreten Provider-,
Ownership-, Versions-, Hash- und Regressionsumfangs antwortete der Benutzer
am 2026-10-03 ausdrücklich: „Ja, bestehende Assembly auf 1.1.0 erweitern“.
Die Erweiterung im Modul `toolbelt.string.edit-distance` ist damit freigegeben.
Keine zusätzliche Assembly, SVF, Paar-USP oder Phonetikfunktion gehört dazu.
Der [Distanzvertrag](EDIT_DISTANCE_CONTRACT.md) bleibt für beide vorhandenen
Funktionen unverändert. Vorhandene historische 1.0-Nachweise qualifizieren
die neuen Source-/Binarybytes nicht. Neue 1.1-Nachweise sind separat in der
[Testmatrix](../../Modules/toolbelt.string.edit-distance/Tests/EDIT_DISTANCE_TEST_MATRIX.md)
festgehalten: Build, Framework, beide IL-Metadatengates und die ausgewählten
privaten Nativeadapter bestanden; **teilweise validiert**, unveröffentlicht.

## Öffentlicher Vertrag

Genau eine öffentliche Inlinefassade `toolbelt_string.TVF_JaroWinklerSimilarity`
über einen internen CLR-TVF-Transport; keine zusätzliche SVF.

|Ordinal|Parameter|Typ|Default|
|---:|---|---|---|
|1|LeftText|nvarchar(max)|kein Default|
|2|RightText|nvarchar(max)|kein Default|
|3|Profile|nvarchar(max)|N'standard'|

Genau eine vollständig berechnete Zeile:

|Ordinal|Spalte|Typ|Semantik|
|---:|---|---|---|
|1|Similarity|float(53), nullable|Ähnlichkeit 0..1, sonst NULL|
|2|ErrorCode|int|logisch stets nicht NULL; 0 Erfolg/NULL, sonst Fachcode|

Physisch nullable SQL-/Clientmetadaten sind zulässig; kein Erfolgsfallback
für unerwartetes Provider-NULL. Double-Berechnung, absolute Golden-Toleranz
1e-12; 0 und 1 in den entsprechenden Erfolgsfällen exakt. Keine Bitgleichheit
zwischen Plattformen oder exakte Darstellung jedes reellen Bruchs.
`IsPrecise=false` entspricht float; `IsDeterministic=true` und kein Datenzugriff.

Unicode Scalar Values, keine Codeunits/Grapheme. Gültige Surrogatpaare zählen
einmal, isolierte Surrogates werden abgewiesen. Ordinal/case-sensitive, keine
NFC/NFD, Casefolding, Collation-/Culture-/Whitespacebehandlung. NUL, BOM,
Noncharacters, combining marks und trailing spaces bleiben erhalten.

## Exakte Matchingvariante

Nach vollständiger Validierung wird die kürzere Scalarfolge zuerst gescannt;
bei gleicher Länge die lexikographisch kleinere nach numerischen Scalarwerten.
Diese kanonische Tie-Orientierung sichert dieselbe Antwort bei Eingabetausch.
Sie ist eine explizite technische Konvention, keine universelle Literaturregel.

Bei n<=m gilt d=max(0,floor(m/2)-1). Für i aufsteigend wird die erste noch
unbenutzte gleiche Position j im inklusiven Fenster
[max(0,i-d),min(m-1,i+d)] gewählt. Jede Position höchstens einmal.
Kein Maximum-Matching und keine Sortierung der Eingabezeichen.

c ist die Matchzahl. Gematchte Scalars werden in der jeweiligen ursprünglichen
Reihenfolge gegenübergestellt; h zählt ungleiche Positionen. Die Transposition
t=h/2 ist eine **reelle Hälfte**, kein Integerfloor. Bei c=0 Ergebnis0,
sonst J=(c/n+c/m+(c-h/2)/c)/3. p ist das gemeinsame Originalpräfix bis vier
Scalars. Nur bei J>7/10 gilt W=J+(p/10)*(1-J), sonst W=J. Der Grenzvergleich
wird rational aus Integer-Matchdaten vorgenommen, damit exakt0,7 keinen Bonus
erhält. Kein Long-string-/ähnliche-Zeichen-/zusätzlicher Datenbonus.
Leer/leer ergibt1, einseitig leer0 nach Validierungen und Arbeitsprüfung.
Identität überspringt keine Ressourcengates.

## Profile, Budgets und Fehlerpriorität

|Profil exakt ordinal|UTF16-Einheiten je Text|Scalars je Text|Fensterplätze|
|---|---:|---:|---:|
|standard|2048|1024|1048576|
|large|65536|32768|16777216|

Geplante Arbeit = SUM i=0..n-1 von
max(0,min(m-1,i+d)-max(0,i-d)+1). Alle möglichen Fensterplätze zählen vor
Matching, auch später bereits belegte Stellen. Hinzu kommt lineare Validierung,
Orientierung, Präfix-/Matchfolgenarbeit. Kein Zeit-/CPU-/Heapbudgetversprechen.
checked Int64-Summe, maximal32768 Summanden vor Matchingpuffern.
Bei gleicher Länge k>=2 ist Arbeit=k*(2d+1)-d*(d+1).
4096²:12580864 zulässig; 5000²:18747500 ergibt Code6, auch bei identischen
Texten. Standard oberhalb des Arbeitsbudgets ist nach Scalarcap nicht erreichbar;
kein falscher öffentlicher Above-Ceiling-Test. Keine Kürzung/Näherung.

1. Irgendein Text NULL: NULL/Error0 vor anderen Argumenten.
2. Profil NULL oder nicht exakt standard/large: Code1.
3. RawUTF16-Einheiten irgendeines Texts zu groß: Code3 vor eigenen Textkopien.
4. Beide Texte vollständig UTF16-prüfen; irgendein invalid: Code4.
5. Irgendeine Scalarzahl zu groß: Code5.
6. Geplante Arbeit zu groß: Code6 vor Matching.
7. Vollständige Formelantwort/Error0.

Code2 ist unbenutzt, es gibt keinen MaxDistance-Parameter. Fachfehler liefern
NULL/festen Code. OOM/ThreadAbort/Transportfehler bleiben technische payloadfreie
Fehler, kein erfundener Ressourcen-Fachcode. Keine Eingabetexte protokollieren.

## Gemeinsamer Kern und Provider

Ein physischer interner Sourceowner `Clr/UnicodeScalar.cs` mit CountStrict und
DecodeValidated übernimmt die bisherigen Scalar-Methodenkörper. DistanceKernel
ändert nur diese Calls/Helperextraktion; DP, Threshold, NULL, Budgets und
Priorität unverändert. JaroKernel/JaroProvider verwenden denselben Helper.
Keine öffentlich aufrufbare Decoder-API, keine installierte SharedAssembly.

Vorhandene ModuleId, SQL-Assembly `Toolbelt_String_EditDistance` und Datei
`Toolbelt.String.EditDistance.dll` bleiben; Modul1.1.0/Assembly1.1.0.0.
Direkte Frameworkreferenzen weiterhin System/System.Data, memory-only,
kein IO/ContextConnection/Workerthread/globaler mutable Cache.
TSQL-Greedy-Matching erfordert eine zustandsbehaftete eindeutige Zuordnung;
ein einfacher Join zählt Duplikate mehrfach. Eine MSTVF wäre möglich, benötigt
jedoch wiederholte Tabellenupdates. Keine gemessene TSQL-Unterlegenheit wird
behauptet. Getrennte CLR-Assembly wurde wegen zusätzlicher Buildsource-/Hash-/
Lifecyclekoordination verworfen; native SQL2025-Funktionen sind kein portabler
2019/2022-Kern. Kein externer Runtimefallback.

## Lifecycle und Regression

Bekannte byteexakte Releases1.0.0 (vier Slots) und1.1.0 (sechs Slots).
Neue Slots: öffentliche IF JaroWinklerSimilarity und interne FT
JaroWinklerSimilarityCore. Alte vier EntryPoints/Signaturen bleiben.
Genuine1.0-Quellen unverändert aus öffentlichem Gitblob; Source allein beweist
keinen historischen Build. Hashbindung ExpectedInstalledAssemblyHash bleibt,
0x nur bei vollständig geprüfter Abwesenheit, SHA2-512 aus einem Binarysnapshot.
Die neuen Hashes wurden aus den tatsächlichen neuen Builds separat gebunden;
ein Trust-Opt-in benötigt weiterhin den exakten geprüften Binarysnapshot.

Marker-/Versions-/Mode-/Typ-/Signatur-/Assemblybinding-/Sicht-/Consumerprüfungen
vor und unter AppLock. Neue Namen in installiertem1.0 bleiben fremde
Zukunftsslots, auch bei imitierten Markern. SourceHash nur diagnostisch.
Uninstall filtert installierte Slots; fremde FT-Assemblyverbraucher blockieren
statt mitzudroppen. CallerTX-Guard vor SET, keine Callerrollback, atomare eigene
DDL mit unverändertem Trust-/Config-/Rechtevertrag. Regulär kein Trust-/Config-
oder Rechtewrite. Shared Assembly bedeutet gekoppelte Releases/Uninstall;
Jaro lässt sich nicht separat aus dem Modul uninstallieren.

Vor Merge tatsächlich: vollständige neue Distanzregression, Jaro harte
rationale Goldens/odd h/Ties/Symmetrie/0,7/4Prefix/Scalar-/Workgrenzen, FillRow,
Release/IL, lokale/zentrale API/SQLClient-/InstalledMetadata, genuine4→6,
repeat/uninstall, CallerTX/AppLock/Rollback/futurecollision/Dependency/Hash/
Visibility-oracles und eigene Cleanup. CI separat am exakten PR-Head.
Die ausgewählten privaten 1.1-Nativeadapter bestanden am 2026-10-03 auf
Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral
sowie mit SC-UTF8-Consumer, einschließlich frischer unabhängiger Cleanup-Audits.
Gesunde Caller-Guards wurden als originaler erster Clientbatch direkt geprüft. Für doomed OFF/ON lief der ganze unveränderte erste Produktbatch in einer gewöhnlichen, eigenen DB-Prozedur; Sentinel, Guardaufruf, Vor-/Nachzeugen und eigener Rollback lagen im selben parameterisierten Clientbatch. Das qualifiziert diesen Prozedurkontext, keinen vollständigen SQLCMD-Skriptlauf in einer doomed Caller-Transaktion.
Nicht ausgeführte Minimalrechte, weitere physische Ziele und Heap bleiben offen.

## Primärquellen und Varianten

[NIST DADS](https://xlinux.nist.gov/dads/HTML/jaroWinkler.html) ordnet die
Similarity ein. [Census2004 Abschnitt3.1.1](https://www.census.gov/content/dam/Census/library/working-papers/2004/adrm/rrs2004-02.pdf)
beschreibt Fenster, Score und strikten Präfixbonus; weitere historische
Anpassungen gehören nicht dazu. Das dortige Odd-Mismatchbeispiel verwendet
eine andere Rundung. [Apache-Projektquelle](https://raw.githubusercontent.com/apache/commons-text/master/src/main/java/org/apache/commons/text/similarity/JaroWinklerSimilarity.java)
verwendet reelle Hälfte, aber einen anderen 0,7-Branch/CharSequence-Einheit.
Keine Paritäts-/Fremdcode-/Lizenzübernahme, nur Variante präzisiert.
