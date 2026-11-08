# Phonetik: vorhandene DLL unter aktuellem Compiler prüfen

Am 2026-11-08 bestand die vorhandene Phonetik-DLL des Moduls **1.0.0** den
unveränderten Framework-Harness unter Windows/.NET Framework 4.8:
**223 Assertions je en-US, de-DE und tr-TR, insgesamt 669**.
Ergebnis: **PASS_FOR_DECLARED_CURRENT_COMPILER_OFFLINE_SCOPE**.
Modulstatus und Release bleiben `partially validated`, `unreleased`.

## Ausführung und aktuelle Bindung

Der vorhandene [Frameworkrunner](../../Modules/toolbelt.string.phonetic/Tests/Framework/run-framework-phonetic.ps1)
kompiliert ausschließlich den Testharness und konsumiert eine bereits gebaute
Assembly. Deren Originalbytes passen zur erhaltenen Buildreceipt; alle fünf
zugehörigen C#-Produktquellen stimmen exakt mit dem aktuellen Repositorystand
überein. Auch die drei Framework-Referenzen passen zu ihren erhaltenen Pins.
Das ursprüngliche Differentialbinding, seine Buildreceipt und Kopien bleiben
unverändert. Kein Produktbuild und kein neuer Differentialvergleich.

Ein neuer betroffener Input begründet diesen Lauf: Die vorhandene Compilerdatei
hat andere Bytes als im früheren Binding. Der aktuelle Compiler wurde deshalb
neu ausdrücklich ausgewählt und mit gültiger Microsoft-Authenticode-Signatur
geprüft; sein neuer Hash ist privat gebunden. Der alte Compilerpin wird nicht
still nachgetragen und frühere Ausführungen werden nicht umetikettiert.

Der [unveränderte Harness](../../Modules/toolbelt.string.phonetic/Tests/Framework/PhoneticHarness.cs)
prüft seine vorhandenen Algorithmus-, Eingabe-, Status-, Kultur- und Grenzorakel.
Compile und alle drei Kulturprozesse lieferten Exit 0 und vollständige
erfasste Kanäle. Der Compiler lieferte keine Diagnoseausgabe, die Kulturprozesse
je den exakten Erfolgmarker mit 223 Assertions und decodiert leerem stderr.
Die abschließenden Pins für Runner, Harness, Owned-Process-Helfer, DLL, Compiler
und Referenzen stimmen weiterhin überein. Ein separater privater Nachprüfer
hat Receipts, drei Originalprozessresultate und alle Eingabepins verglichen.

Vor Wiederholung die Variablen für eine quellengebundene Assembly, deren
erwarteten SHA256, den geprüften Compiler und die drei passenden net48-Referenzen
ausdrücklich setzen. Das neue EvidenceDirectory darf noch nicht existieren.
Reproduktionsform nach dieser privaten Vorbereitung:

~~~powershell
pwsh -NoProfile -File Modules/toolbelt.string.phonetic/Tests/Framework/run-framework-phonetic.ps1 `
  -AssemblyPath $QualifiedAssemblyPath `
  -ExpectedAssemblySHA256 $ExpectedAssemblySHA256 `
  -CscPath $CscPath `
  -FrameworkReferenceDirectory $FrameworkReferenceDirectory `
  -EvidenceDirectory .runtime/selected/fresh-framework-output
~~~

Die Variablen bezeichnen vorzubereitende private Eingaben. Ein Dateiname
oder eine Modulversion allein belegt weder Herkunft noch aktuelle Bindung.

## Gemeinsame Grenzen und verbleibende Qualifikation

Vor Start galten zehn Minuten, höchstens zwei Runnerinvocations und acht
untergeordnete Prozesse insgesamt. Eine zweite Invocation wäre nur nach
geändertem Input und konkretem Befund erlaubt gewesen. Tatsächlich bestanden
**eine Invocation und vier Kinder**: Compiler und drei Kulturen. Der Erfolg
schließt alle unbenutzten Restplätze. Jedes Kind hatte höchstens 60 Sekunden,
der äußere Owned-Process-Aufruf 300 Sekunden. Ein Verantwortlicher, keine Agents.

Keine SQL-Verbindung, keine Rechte-, Trust-, CLR-Konfigurations-, Hostinstallations-
oder Labänderung. Die erzeugten Harnessdateien und privaten Originalnachweise
bleiben erhalten; kein Datei-Cleanup-PASS, keine rohe stderr-Byteattestation.

Dieser Nachweis qualifiziert ausschließlich die vorhandene DLL im genannten
Framework-/Compilerkontext. Er schließt weder vollständige Scannerabdeckung
noch SQL-/SAFE-/Zielmatrix-, Minimalrechte-, CrossDB-, Ressourcen- oder
Lifecyclequalifikation. Der frühere endliche 36-Fälle-Java-Vergleich bleibt
eigenständig gültig; er wurde nicht wiederholt. Keine Veröffentlichung oder Tags.
