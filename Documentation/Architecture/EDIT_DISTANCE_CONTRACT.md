# Vor-Source-Vertrag: Levenshtein und Optimal String Alignment

Stand 2026-10-02. Vor-Source-Vertrag. Der vollständige Root-Review und die explizite Metadatenentscheidung vom selben Tag schließen den Vertragsfreeze vor Runtime-Source; der vorher geprüfte Stand hat SHA256 3F082AC420D814263037DD6DF3E104CA6C8F690BCBFF7A30261758DBF69DCA3C. Die Einzelfreigabe vom 2026-10-01 umfasst genau die beiden Editierdistanzen; der Benutzer bestätigte am 2026-10-02 auf die konkrete zusätzliche Frage zum dedizierten portablen SAFE-CLR-Provider „Lebenshtein/OSA assembly -> ja“. Diese Entscheidung autorisiert den eigenen Provider/Lifecycle für Levenshtein und OSA. Jaro, Phonetik, Similarity und Paarvergleiche sind getrennte Funktionen. Kein Runtime-PASS, keine Veröffentlichung oder Installations-/Rechte-/Konfigurationsänderung wird behauptet.

Der ältere [Fuzzy-Researchvorschlag](FUZZY_MATCH_PROPOSAL.md) ist Historie. Seine UTF16-Codeunit-, SVF- und MaxDistance+1-Vorschläge gelten für diese konkretisierte Welle nicht. Der [kanonische Backlog](../../.ai/BACKLOG.md) enthält die ursprüngliche funktionsbezogene Einzelbesprechung.

## Zweck und öffentlicher Schnitt

Genau zwei öffentliche Funktionen im Modul `toolbelt.string.edit-distance` Version 1.0.0: `toolbelt_string.TVF_LevenshteinDistance` und `toolbelt_string.TVF_OsaDistance`. Beide besitzen identische Parameter und Ordinals:

|Ordinal|Parameter|Typ|Default|
|---:|---|---|---|
|1|LeftText|nvarchar(max)|kein Default|
|2|RightText|nvarchar(max)|kein Default|
|3|MaxDistance|int|NULL|
|4|Profile|nvarchar(max)|N'standard'|

Genau eine vollständig berechnete Ergebniszeile:

|Ordinal|Spalte|Typ|Semantik|
|---:|---|---|---|
|1|Distance|int, nullable|Exakte nichtnegative Distanz oder NULL|
|2|ExceedsMaxDistance|bit, nullable|0 bei exakter Antwort, 1 bei bewiesener Schwellenüberschreitung, sonst NULL|
|3|ErrorCode|int|Fester Fachcode; jeder implementierte Ausgabepfad liefert einen nicht-NULL Wert|

Exakt: Distance>=0/Exceeds=0/ErrorCode=0. Bewiesen oberhalb einer gesetzten Schwelle: NULL/1/0, kein geschätzter Abstand. NULL links oder rechts: NULL/NULL/0. Fachfehler: NULL/NULL/fester Code. MaxDistance=NULL berechnet exakt; jeder nichtnegative int einschließlich INT_MAX ist erlaubt. Keine SQL-Culture-/Collation-Normalisierung, Kürzung, optionale Case-/Akzent-/Whitespacebehandlung oder zusätzliche SVF.

SQL-CLR-TVFs können NOT NULL nicht deklarieren. ErrorCode ist logisch bei jeder Ergebniszeile nicht NULL; nullable SQL-/Clientmetadaten sind ausdrücklich zulässig und werden separat nativ qualifiziert. Zwei öffentliche Inlinefassaden transportieren die Defaults über zwei interne CLR-TVFs mit einem gemeinsamen verwalteten Kern. Sie sind keine relationalen DP-Kerne und versprechen keine Inlining-/Parallelitätskosten. Es gibt keinen zusätzlichen Fallbackcode und kein ISNULL mit stillschweigendem Erfolg. Ein unerwartetes NULL des Providers ist ein technischer Fehler, kein Fachresultat. [Microsoft CREATE FUNCTION](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver17).

## Scalar- und Algorithmussemantik

Einheit ist Unicode Scalar Value, keine Bytes, UTF16-Codeunits oder Graphemcluster. Gültige Surrogatpaare zählen jeweils einmal; isolierte Surrogates werden abgewiesen. NUL, BOM, Noncharacters, unassigned Scalars, combining characters, punctuation und trailing spaces bleiben erhalten. Vergleiche ordinal/case-sensitive ohne NFC/NFD/Casefolding. Emoji gegen leer hat Distanz1; e+CombiningAcute gegen é hat Distanz2.

Levenshtein verwendet Einfügen/Löschen/Ersetzen jeweils1. OSA ergänzt benachbarte Transposition für1, mit Rückgriff zwei Zeilen: eingeschränktes Optimal String Alignment, kein uneingeschränktes Damerau-Levenshtein. CA→AC: Levenshtein2/OSA1. CA→ABC: OSA3, unrestricted wäre2. Keine Metric-/Dreiecksungleichungszusage für OSA.

Gemeinsamer Decoder/Validierung/DP-Kern, Algorithmus je EntryPoint intern fest. Zwei Zeilen für Levenshtein, drei für OSA; int-Scalararrays, keine Rekursion/Workerthreads/IO/globalen mutable Caches. Kein Prefix-/Suffixtrimming oder OSA-RowMinimum-Earlyexit. Band |i-j|<=k bei gesetzter Grenze; k intern auf max(n,m) begrenzt, INF=max(n,m)+1, kein MaxDistance+1-/INT_MAX-Overflow. Vollständige Eingabevalidierung vor Längendifferenzzertifikat; außerhalb Band keine unerlaubten stale Werte. Einmalige Zeileninitialisierung und höchstens drei Boundarywrites pro Zeile; keine volle Array.Clear pro Bandzeile.

## Unveränderte begrenzte Profile und Priorität

Profile werden vollständig ordinal/byteexakt als standard oder large geprüft, kein SQL-Padding/Culturevergleich.

|Profil|UTF16-Einheiten je Text|Scalars je Text|DP-Zellen|
|---|---:|---:|---:|
|standard|2048|1024|1048576|
|large|65536|32768|16777216|

1. NULL links/rechts vor allen weiteren Prüfungen: NULL/NULL/0.
2. Profil NULL oder nicht exakt standard/large: Code1.
3. MaxDistance<0: Code2.
4. RawUTF16-Einheiten irgendeines Texts über Profil: Code3.
5. Beide Texte vollständig streng prüfen; irgendein ungültiges UTF16: Code4.
6. Scalarzahl irgendeines Texts über Profil: Code5.
7. Gesetzte Schwelle und |n-m|>MaxDistance: NULL/1/0.
8. Prognostiziertes checked Zellbudget über Profil: Code6.
9. Exakte Antwort oder bewiesene Überschreitung.

Rawlimits vor zusätzlichen Text-/Scalar-/DP-Kopien; Scalarzählung beider Texte vor Scalarcapentscheidung, damit ungültiges UTF16 der Gegenseite Code4 vor Code5 behält. Leere Eingaben liefern nach Validierung die andere Scalarzahl. Exaktes Work=n*m, Bandwork=SUM je i von max(0,min(m,i+k)-max(1,i-k)+1); Budget vor DP, maximal32768 Zählerzeilen. Fachcodes sind Resultcodes, keine SQL-THROW-Nummern. OOM/ThreadAbort/unerwarteter Betriebsfehler bleibt Betriebsfehler, niemals Thresholdflag oder Ressourcen-Fachcode ohne entsprechenden Nachweis. Payloadfreie technische Fehler; keine Eingabetexte protokollieren.

Large erlaubt 32768×32768 mit k1 (98302 Zellen); exakt4096×4096 erreicht16M,4096×4097 überschreitet. Standard1024² erreicht1M; nach Standardtextcaps ist above-cell-limit nicht erreichbar, deshalb interner Zählerseam kein öffentlicher Above-Ceiling-Witness. Nutzdatenpuffer maximal655372 Bytes (zwei Scalararrays + drei OSA-Zeilen), exklusive Objekt-/Marshaling-/Engine-/Originalstringkosten. Keine Heap-, Hardwall-, Durchsatz- oder globale Produktionszusage.

## Provider und Lifecycle

Eigene Assembly ausschließlich dieses Moduls, vorgeschlagener SQL-Name `Toolbelt_String_EditDistance`, Datei `Toolbelt.String.EditDistance.dll`, .NET Framework4.8/Release/AnyCPU/deterministisch, SAFE. Direkte Referenzen ausschließlich vorhandene Framework System/System.Data; kein NuGet/Drittanbieter/Download. SQL-Zugriff DataAccessNone/SystemDataAccessNone, kein ContextConnection. Memory-only; keine Datei/Netzwerk/Prozess/Registry/Thread APIs im Provider. Framework-Harness-IO bleibt außerhalb Providerquellen.

TSQL bevorzugt, aber sequenzielle bandierte DP mit zwei/drei Zeilen besitzt keinen sinnvollen reinen relationalen Inlineausdruck. TSQL-MSTVF würde wiederholte Tabellenupdates benötigen; externe Runtime verändert Transport/Autorisierung und ist kein Fallback. Native SQL2025-Preview ist kein versionsübergreifender Algorithmusvertrag. CLR-Deploy-/Build-/Trustaufwand und Runtimebindung bleiben reale Grenzen.

Lokale und zentrale Installation gleicher Kern; keine Synonyme/ResultTabledependency. Lifecycle vier Slots bei Inlinefassaden: zwei öffentliche IF, zwei interne FT; nur Zielversion1.0.0, eine eigene Assembly. Installer/Uninstaller vor SET/Mutation bei Caller-TX nondooming RAISERROR+RETURN und SQLCMD-OnErrorExit; keine Callerrollback. Byteexakte bekannte Modulversion/Mode, vollständige cohärente Managed/ModuleId/ModuleVersion-Marker, Typen und Ownership vorMutation und unter eigenem AppLock erneutprüfen. Fremde Slots/Schema-/Assemblykollisionen, unbekannte Versionen und externe Dependencies failclosed erhalten. SourceHash nurdiagnostisch, reguläres versionsgleiches Reinstall repariert eigene Source.

Exakte offline erzeugte Binary-SHA2-512-Provenienz, erwartete installierteBinarybindung ausdrücklich parametriert, 0x nur bei tatsächlich absentemModul/Assembly; unbekannt/mismatch blockieren, keine Version aus Binaryhash erfinden. Privates administratives Trust-Opt-in für exakten Hash nur getrennt; reguläre Deploy-/Uninstallskripte ändern niemals clr enabled/strictSecurity/TRUSTWORTHY/Trustliste oder GRANTs. Keine automatische Provider-/Dependencyinstallation. Aufruf SELECT auföffentlichenTVFs; Deployment-/Trustrechte getrennt dokumentieren und vorhandene Rechte benutzen. SQL-Lab ausschließlich nach Rootkoordination, eigene Journale/private Binarys, keine realen Pfade/Secrets im öffentlichen Nachweis.

## Vorhandene Evidenz und verbleibende Gates

Privater Algorithmuskandidat SourceSHA256 E7F34706A29BA285C0BCB75E032ABF17C27331352CF3085E5E531CB2DA102386; Matrixgoldens1E8990B437FB85494F9334E307F07007839B92231F985C94CADCF2DD8C8F504F. Historischer tatsächlicher Frameworklauf neun Kinder/101936 Assertions; unabhängiger frischer Build gleicherSource und neunKinder ebenfalls101936. Vollständige1M/16M-DP- undLongBand/Supplementary-Computechecks, geplante=ausgeführteZellen. Diese Evidenz betrifft private Algorithmen und Nutzdatenpuffer, kein SQL-/Provider-/Metadaten-/Heap-PASS. Compiler/Buildpfade bleiben privat; öffentliche Quellenhashes enthalten keine Runtimeinventare.

Vor RuntimeSource: exakten Providervertrag unabhängig und durch Root prüfen und Gate dokumentieren; keine zusätzliche finaleDEC-ID selbstallokieren. Danach Providerbuild+Frameworkregression/IL-NoIO+FillRow/NULLtransport, SQLsyntax/staticcontracts/docAudit. VorMerge integrierte nativeAPI/Defaults/SQLClient-/InstalledMetadata/CS-CI-SC-nonSC/NUL/Supplementary/CallerTX/Threshold/Errorpriority/actualbudgets, Mengenaufrufe, localcentral/Lifecycle/faultcollision/Dependencies/uninstall/owncleanup, genuineReinstall sowie vorhandeneMinimalrechte; exakteHead-CI separaterPR-Mergegate. Alle nicht ausgeführten SQL-/Runtimeziele ehrlich NOT_EXECUTED; Modul unveröffentlicht.

Primärquellen: [Unicode-Scalar-/Surrogate-Definition](https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-3/), [NIST Levenshtein](https://xlinux.nist.gov/dads/HTML/Levenshtein.html), [Microsoft CLR-TVFs](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions?view=sql-server-ver17), [CLR-Sicherheit und Portabilität](CLR_SECURITY_AND_PORTABILITY.md).

## Additiver Evidenznachtrag 2026-10-02

Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Beide finalen Läufe hielten sämtliche Quellpins unverändert; je drei eigene Datenbanken und eigener Trust wurden anschließend unabhängig als entfernt bestätigt. Der erste Linux-Lauf SQL468/State9 im Metadaten-Fixture ist ein bereinigter Fehlerlauf, kein PASS. Die korrigierte Collationprüfung wurde im neuen Gesamtadapter ausgeführt. IL-NoIO-/NoPInvoke-/Allowlistprüfung am tatsächlichen Releasebinary separat bestanden. Die historischen Vor-Source-Gates und Algorithmenbelege oben bleiben erhalten; öffentliche Signaturen, Fehlerpriorität und Budgets sind unverändert. Synthetische Rechtepredikate qualifizieren keinen tatsächlichen Lowpriv-Kontext.

## Additive Assemblyfreigabe 2026-10-03

Der Benutzer hat die bestehende Assembly ausdrücklich auf 1.1.0 erweitert.
Der eigenständige [Jaro-Winkler-Vertrag](JARO_WINKLER_CONTRACT.md) ergänzt eine
öffentliche IF und eine interne FT. Die vier bestehenden 1.0-Slots und deren
öffentliche Verträge bleiben unverändert. UnicodeScalar CountStrict und
DecodeValidated haben einen einzigen physischen internen Besitzer; DP und
Threshold-/Budget-/Fehlerverträge werden nicht geändert. Genuine 1.0-Upgrades
und vollständige Levenshtein-/OSA-Regression wurden für die ausgewählten
1.1-Scope separat qualifiziert; siehe die
[aktuelle Testmatrix](../../Modules/toolbelt.string.edit-distance/Tests/EDIT_DISTANCE_TEST_MATRIX.md).
Die bisherige 1.0-Evidenz wird nicht auf den neuen 1.1-Build übertragen.