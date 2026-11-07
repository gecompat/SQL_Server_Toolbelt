# Table Clone 4.1.1: vollständiger SQLCMD-Caller-Abbruch

Am 2026-11-07 bestanden die vollständigen kanonischen Caller-Transaktions-
fixtures für Deploy und Uninstall auf zwölf Engine-/CL-Paaren lokal und
direkt zentral: **zwölf erfolgreiche Gesamtfälle, 24 Kontexte und 96
vollständige SQLCMD-Profile**. Ergebnis:
**PASS_FOR_DECLARED_COMPLETE_SQLCMD_CALLER_SCOPE**.

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Der SQLCMD-Clientprozess lief auf Windows mit der vorhandenen administrativen
SQL-Lab-Anmeldung. Linux bezeichnet das SQL-Ziel. Verschlüsselung und der
explizite Functional-Trustwert werden unverändert aus dem schema-validierten
Labvertrag übernommen; keine authentifizierte TLS-, Windows-SSPI- oder
Linux-Clienthost-Abnahme.

## Vollständige Includes und tatsächlicher Batchabbruch

Der [begrenzte Treiber](../../Tests/Release/Invoke-TableCloneSqlcmdCallerLab.ps1)
verwendet die vollständigen Originalfixtures
`Lifecycle.CallerTransaction.Deploy.sql` und
`Lifecycle.CallerTransaction.Uninstall.sql`. Der kanonische Deployment-
Baumkonverter expandiert sämtliche Includes und gebundenen Variablen. Die
Zulassung vergleicht alle acht Texte mit dieser erneuten Originalableitung.
Für OFF wird ausschließlich der eindeutige XACT_ABORT-Anker der Rootfixture
vor der Ableitung angepasst; alle eingebundenen Produktskripte bleiben unverändert.
Der generische Exportwrapper mit eigenem Sitzungsguard wird ausdrücklich
nicht vorangestellt: Nachgewiesen wird der Modulguard im vollständigen Skript.

Pro Kontext laufen vier echte CLI-Prozesse: Deploy und Uninstall, jeweils
mit XACT_ABORT OFF und ON. Jeder muss vollständig erfasst mit Exitcode 1,
SQL-Fehler 50000 und `TBX_TABLE_CLONE_CALLER_TRANSACTION:` enden. Der spätere
Kontrollfehler 54920 darf nie erreicht werden. Dies belegt den tatsächlichen
SQLCMD-Batchabbruch statt bloßer Fragmentausführung. Alle Moduldefinitionen
und Toolbelt-Properties werden vor/nach jedem Kontext identisch geprüft;
der administrative Kontrollclient bleibt transaktionsneutral.

Die bereits gültigen [Clientreader-Nachweise](TABLE-CLONE-WINDOWS-CLIENT-METADATA-QUALIFICATION.md)
prüfen ergänzend den lebenden gesunden Callerzustand im selben Client.
Ein beendeter CLI-Prozess kann diesen lebenden Sitzungszustand nicht ersetzen.
Die Includes erreichen bestimmungsgemäß den frühen Caller-Guard; dies ist
kein positiver Upgrade-/Uninstall- oder Recoverylauf.

## Erhaltener Erstfehler und begrenzte Adapterkorrektur

Der [ursprüngliche Methodenstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/55e334d3025df3eac3944fcb8ca9a70896374307)
endete im ersten CLI-Profil vor jedem bestandenen Profil oder abgeschlossenen
Modus: Die installierte ODBC-SQLCMD-Variante unterdrückte mit `-X1` auch die
benötigte Kennwortumgebung. Der Versuch bleibt **FAILED_CLEANED**, sein
frischer unabhängiger Audit PASS mit `originalRunPassed=false` erhalten.
Eine tatsächlich angelegte eigene DB wurde entfernt. Keine Aufwertung zum PASS.

Der [korrigierte Methodenstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/9e2c3cf7fe9084406a2360c017bc11ed5d2ea9af)
entfernt diese inkompatible Option. Stattdessen entfernt er ausschließlich
im Kindprozess alle geerbten SQLCMD-/OSQL-Umgebungswerte, setzt nur das
vorhandene Kennwort im Speicher und unterbindet mit `-x` zusätzliche
Variablensubstitution. Die bereits vollständig aufgelösten Eingabetexte
lassen außer `:On Error exit` keine Direktiven oder offenen Variablen zu.
Der Elternprozess bleibt unverändert. Keine Kennwörter in Argumenten,
Dateien oder Logs, kein Authentifizierungs- oder Trustfallback.

Der kanonische OwnedProcess-Helper bleibt unverändert. Seine eng begrenzte
Komposition wird über eindeutige Anker und vollständige Rückrekonstruktion
geprüft: zusätzliche In-Memory-Kennworteingabe, isolierte Kindumgebung,
strikte UTF-8-Ausgabekanäle sowie sofort geschlossenes umgeleitetes stdin.
Es gibt keinen interaktiven Kennwortdialog oder unbegrenzten Kindprozess.
Dreizehn öffentliche Offlinegegenproben bestanden vor der Wiederaufnahme;
eine verstärkte gezielte Gegenprobe bestätigt zusätzlich die Entfernung
synthetisch vergifteter Startwerte und den unveränderten Elternprozess.

## Gemeinsame Grenzen und unabhängige Abschlussaudits

Vor erstem SQL-Zugriff waren **28 Ziel-/Auditaufrufe, 28 eigene DB-
Reservierungen, 112 CLI-Reservierungen und 60 Minuten** gemeinsam festgelegt.
Die höchstens zwei geänderten Adapterkorrekturen waren nur nach vollständig
bereinigtem Fehlversuch, frischem Audit, null grünen Profilen/Modi sowie
Offlineprüfung vorgesehen. Die eine verwendete Korrektur erhält dieselbe
ursprüngliche Frist, sämtliche Zähler, Fehler und Originaldateien.
Keine Wiederholung eines bereits grünen Profils.

Tatsächlich verbraucht: **26 Ziel-/Auditaufrufe, 26 DB-Reservierungen,
104 CLI-Reservierungen, 97 tatsächliche CLI-Aufrufe** einschließlich des
Fehlprofils. **13 frische Audits**, zwölf erfolgreiche Gesamtfälle und
**25 tatsächlich angelegte eigene DBs entfernt**. Alle ungenutzten Plätze
sind geschlossen. Der unabhängige Nachprüfer bindet die exakten finalen
Originaljournalhashes, Inputpins, Ziel-/CL-/Modulbindungen, alle 96 grünen
CLI-Profile und den vollständigen ursprünglichen Konfigurations-/Trustzustand.

Producer und Audit besitzen getrennte Prozessgrenzen von 400 Sekunden und
4-MiB-Kanäle. Einzelne SQLCMD-Prozesse bleiben auf höchstens 45 Sekunden
innerhalb des begrenzten Producers beschränkt. Die Admission erhält
15 Minuten Reserve. Keine neuen Rechte, Principals, Assemblies, Serveroptionen,
Trusteinträge oder Lab-Infrastruktur. Rohlogs, Identitäten, reale Runtimewerte
und private Journale bleiben außerhalb Git erhalten.

## Wiederverwendung und getrennte Restpunkte

Produkt-SQL, Originalfixtures, gemeinsame Helper und die kanonischen
Exportinputs sind unverändert. Gültige [Planner-/Executor-](TABLE-CLONE-PLANNER-EXECUTOR-QUALIFICATION.md),
[W1-/W2-](TABLE-CLONE-W1-W2-QUALIFICATION.md),
[Copy-](TABLE-CLONE-COPY-TARGET-QUALIFICATION.md),
[Trigger-](TABLE-CLONE-TRIGGER-CURRENT-QUALIFICATION.md) und
[Clientreader-Nachweise](TABLE-CLONE-WINDOWS-CLIENT-METADATA-QUALIFICATION.md)
werden wiederverwendet. Der dort noch offene vollständige SQLCMD-Caller-Abbruch
ist mit diesem gesonderten Bericht geschlossen; die damaligen Teilnachweise
werden nicht rückwirkend erweitert.

Linux-Clienthost, zusätzliche echte Minimalrechte-/CrossDB-Identitäten,
genuine aktuelle Upgrade-/Uninstall-/Recoveryfälle und die Modulgesamtfreigabe
bleiben getrennt. Teilweise validiert, unveröffentlicht; keine Veröffentlichung
oder Tags.
