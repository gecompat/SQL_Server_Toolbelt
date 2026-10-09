# CSV-Framework-Abnahme

`run-framework-csv.ps1` prüft ausschließlich das über AssemblyPath und exakten
ExpectedAssemblySHA256 gebundene gepackte .NET-Framework-4.8-Binary. CscPath und
FrameworkReferenceDirectory werden explizit geliefert; kein Download oder
impliziter Compilerfallback. EvidenceDirectory muss neu und außerhalb des
Repositories liegen. Nur der Harness wird kompiliert, keine Produktquellen.
Compile und jeder Harnessprozess verwenden den bestehenden eigenen begrenzten
Prozesshelper mit60 Sekunden; vollständige Ausgabekanäle und Eingabe-/Binarypins
sind Pflicht. Private Diagnoseausgaben und Binaries werden nicht versioniert.

Der DLL-Kopierblock verwendet einen festen 64-KiB-Puffer und einen Lesehandle
mit `FileAccess.Read`/`FileShare.Read`. Die anfängliche `Int64`-Länge bindet die
exakt zu kopierende Byteanzahl; vorzeitiges EOF, zusätzliche Bytes und eine
abweichende abschließende Quell-/Kopielänge werden abgewiesen. Beide Handles
werden auch bei Fehlern geschlossen; erst danach folgen die bestehende
SHA256-Kopieprüfung und die unveränderten Eingabe-/Executable-Endpins.
Partielle eigene Dateien werden bei Fehlern behalten. Der Puffer ersetzt nur
das vollständige DLL-Bytearray; keine neue DLLgrößengrenze, Gesamt-Heap- oder
harte Globaldeadlinegarantie. CLI, Compilerreferenz, Orakel und Prozessbudgets
bleiben unverändert.

Der feste Corpus läuft unter en-US/de-DE/tr-TR. Harte Input-/Quote-/Spalten-/
Zeilen-/Millionenzellgrenzen laufen einmal unter en-US. Er prüft direkte
Quotingorakel zusätzlich zu Roundtrips, vollständige späte Parserabweisung,
interne Sentinel-/Measurecodes, Header-/Token-/CRLF-/Unicode-Codeeinheitentreue
und deklarierte CLR-Funktionsmetadaten am identischen Binary. Der IL-Scan aller
Produktmethoden einschließlich Iteratoren weist direkte Referenzen auf I/O,
Netzwerk, Context Connection, Reflection, Workerthreads/Tasks, Processstart und
Marshal sowie P/Invoke, fremde Catchtypen und globale veränderliche Felder ab.
Diese Abnahme beweist weder native SQL-Transport-/Clientmetadaten noch
ResultTableatomik, SQL-SAFE-Zulassung oder Lifecycle; der lokale IL-Scan ersetzt
keinen vollständigen transitiven Audit der Frameworkimplementierungen.
Diese separaten Gates bleiben vor ihrer Ausführung `not executed`.
