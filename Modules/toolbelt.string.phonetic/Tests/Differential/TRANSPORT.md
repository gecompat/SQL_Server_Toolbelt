# Phonetik-Differentialtests

Der Offline-Test vergleicht die vorhandene Phonetik-Assembly mit den unveränderten Java-Scannern aus Apache Commons Codec 1.18.0. Das Referenzmanifest bindet acht Javaquellen sowie `LICENSE.txt`, `NOTICE.txt` und `pom.xml` an Commit `5f76abb946164b943bc2cf367bc1d70b8f6e70d1`. Die Referenzdateien werden als externe Eingaben bereitgestellt; der Test lädt oder installiert nichts.

Der mitgelieferte Corpus enthält 32 synthetische Fälle für Cologne Phonetic und Double Metaphone. Verglichen werden vollständige Codes. Der Java-Consumer setzt und prüft `MaxCodeLen = 16384`; der Standardwert 4 ist kein Vergleichsorakel. Für `AJ` muss der alternative Double-Metaphone-Code exakt `A ` einschließlich abschließendem ASCII-Leerzeichen sein.

## Voraussetzungen und Aufruf

Der Runner benötigt Windows, PowerShell 7.3 oder neuer, einen vorhandenen C#-Compiler, die .NET-Framework-4.8-Referenzassemblies und ein vorhandenes JDK mit `java` und `javac`. Die Phonetik-DLL muss aus dem zu prüfenden Repository-Stand gebaut und diesem Stand nachvollziehbar zugeordnet sein; Name und Version allein belegen diese Zuordnung nicht.

```powershell
./run-differential-phonetic.ps1 -BindingPath <binding.json> -ExpectedBindingSHA256 <SHA256>
```

Das private Binding ist streng UTF-8 und enthält genau fünf Felder:

| Feld | Bedeutung |
|---|---|
| `Schema` | Exakt `PHONETIC_DIFFERENTIAL_BINDING_V1` |
| `Ready` | Boolesches `true` nach Prüfung aller Eingaben |
| `Inputs` | Die unten genannten 14 Dateibindungen |
| `ReferenceDirectory` | Absolutes Verzeichnis der unveränderten Apache-Referenzdateien |
| `EvidenceDirectory` | Neues, noch nicht vorhandenes privates Ausgabeverzeichnis; sein Elternverzeichnis muss existieren |

`Inputs` enthält genau `Coordinator`, `CSharpConsumer`, `JavaConsumer`, `Corpus`, `Transport`, `OwnedProcess`, `ApacheManifest`, `Assembly`, `Csc`, `Java`, `Javac`, `Mscorlib`, `System` und `SystemData`. Jede Bindung hat genau `Path`, `SHA256` und `Bytes`: einen absoluten Dateipfad, 64 großgeschriebene Hexzeichen und die positive exakte Bytezahl. Der Runner prüft die konsumierten Bytes und lehnt Reparse-Pfade ab. `OwnedProcess` bindet den vorhandenen gemeinsamen Helper; `ApacheManifest` bindet die mitgelieferte `Reference.manifest.json`. Dessen elf `SourcePath`-Einträge werden ausschließlich unter `ReferenceDirectory` aufgelöst.

Java-Optionsvariablen und `CLASSPATH` müssen leer sein. Werkzeuge werden ausdrücklich gebunden; es gibt keine automatische Suche, Installation, Referenzbeschaffung oder Ersatzwahl. Bindings und Laufnachweise gehören nicht ins Repository.

## Corpus und Ergebnisformat

Der Corpus ist ASCII mit LF und einem abschließenden LF. Nach `PHONETIC_CORPUS_V1` folgen 1–64 Records:

```text
CaseId<TAB>Algorithm<TAB>TextBase64
```

IDs sind kanonische Dezimalzahlen von 1 bis N, `Algorithm` ist `C` oder `D`. Base64 transportiert die unveränderten UTF-16LE-Codeeinheiten, einschließlich enthaltenem NUL, TAB, CR oder LF. Jede Eingabe hat 1–128 Codeeinheiten. Cologne erlaubt ASCII und `ÄÖÜäöüß`, Double Metaphone ASCII und `ÇçÑñ`; Double Metaphone braucht mindestens eine Codeeinheit oberhalb U+0020. Leere oder SQL-NULL-Eingaben gehören nicht zu diesem Corpus.

Beide Consumer schreiben ASCII/LF mit abschließendem LF. Nach `PHONETIC_DIFFERENTIAL_V1` folgen genau N Records in Corpusreihenfolge:

```text
CaseId<TAB>Algorithm<TAB>Status<TAB>PrimaryByteLength<TAB>PrimaryBase64<TAB>AlternateByteLength<TAB>AlternateBase64
```

Der C#-Status ist `0`, der Java-Status `-`. Cologne verwendet alternativ `-1<TAB>-`; Double Metaphone liefert zwei getrennte Codes. Leere Codes haben Länge 0 und ein leeres Base64feld. Jeder Code ist ASCII und höchstens 16384 Bytes lang. Base64 muss kanonisch sein und die tatsächliche Länge der deklarierten Länge entsprechen.

Der Runner prüft die rohen stdout-Dateien bis zum EOF und vergleicht sämtliche Codebytes. Er trimmt, normalisiert und kürzt nichts. Zusätzliche Records, BOM, CR als Transportzeichen, falsche Felder, IDs oder Längen sowie unvollständige Ausgabe oder ein Fehlerexit führen zum Fehlschlag. Der gemeinsame Helper liefert stderr als decodierten Text; eine rohe stderr-Byteprüfung wird nicht behauptet.

## Umfang und Nachweise

Der Runner startet vier eigene Prozesse: zwei Compiler und zwei Consumer. Jeder erhält höchstens 60 Sekunden innerhalb eines gemeinsamen 240-Sekunden-Arbeitsbudgets. Zwölf weitere Sekunden sind ausschließlich für die Prozessbereinigung reserviert. Eingaben sind auf 16 MiB, die Assembly auf 4 MiB, der Corpus auf 32 KiB und jeder erfasste Ausgabekanal auf 4 MiB begrenzt. Erzeugte Compilerdateien werden begrenzt inventarisiert und vor und nach dem Vergleich geprüft.

Bei Erfolg erscheint `PHONETIC_DIFFERENTIAL_SCOPE_PASS`; bei Fehler oder fehlender Bereitschaft `PHONETIC_DIFFERENTIAL_SCOPE_FAILED_OR_UNREADY`. Private Receipts, Rohdateien und Eingabekopien bleiben erhalten. Unsicheres Prozessende schlägt fehl; die vom Helper verfügbare Primärdiagnose, die Bereinigungsdiagnose und Pin-Nachprüfungen werden getrennt erfasst. Eine vom Helper ersetzte Primärdiagnose wird nicht rekonstruiert.

## Historischer Quellenstand PR301

Die folgende NOT_EXECUTED-Aussage hält den Stand vor der ersten tatsächlichen Ausführung fest.

Diese Grenzen sind kooperative Prüfungen und keine Garantie für gesamten Host-Heap, harte Unterbrechungen oder atomare Dateizugriffe. Der Test führt kein SQL aus. Ein erfolgreicher endlicher Corpusvergleich ersetzt keine vollständige Scanner-, SAFE-, Plattformmatrix- oder Releasequalifikation. Der Differentiallauf ist bislang **nicht ausgeführt**; Quellprüfung und vorhandene Modulnachweise sind getrennt zu bewerten.

## Begrenzter tatsächlicher Differentialnachweis 2026-10-08

Der aktuelle Quellstand bestand einen einmaligen lokalen Offlinevergleich unter Windows mit .NET Framework 4.8 und dem ausdrücklich gewählten JDK27 gegen Apache Commons Codec 1.18.0. Eine frisch aus den fünf aktuellen C#-Quellen gebaute Assembly und der [Runner](run-differential-phonetic.ps1) mit explizitem `BindingPath`/`ExpectedBindingSHA256` lieferten für 32 synthetische Fälle (16 Cologne, 16 Double Metaphone) identische vollständige Primary-/Alternatebytes. Der alternative AJ-Code blieb exakt `A ` einschließlich des abschließenden ASCII-Leerzeichens. Eine unabhängige Prüfung der erhaltenen Receipts, aller Input-/Kopie-/Outputpins und beider roher Ausgaben bestätigte den begrenzten PASS ohne erneuten Lauf.

Dieser Nachweis ist kein SQL-/SAFE-, vollständiger Scanner-, Plattformmatrix- oder Releaseabschluss. Das Modul bleibt `partially validated` und `unreleased`. Bestätigt ist leerer zurückgegebener decodierter stderr-Text, keine rohe stderr-Byteattestation; private Dateien bleiben erhalten, kein Datei-Cleanup-PASS. Produktcode, API und Workflow wurden für diese Evidenzfortschreibung nicht verändert.
