# Table Clone: fehlende Copy-Zielkontexte

Am 2026-11-06 bestanden die fünf unveränderten gruppierten Copy-Orakel des
aktuellen Moduls4.1.1 in22 zuvor fehlenden Installationskontexten. Zwölf
Gesamtläufe,110 Gruppenzeugen und zwölf frische separate Abschlussaudits sind
erfolgreich. Ergebnis: **PASS_FOR_DECLARED_SCOPE**; das Modul bleibt teilweise
validiert und unveröffentlicht.

## Ausgeführte Matrix

| SQL-Ziel | Compatibility Levels | Neu ausgeführte Modi |
| --- | --- | --- |
| Windows2019/CU32 | 150 | lokal und direkt zentral |
| Windows2022/CU26 | 150,160 | jeweils lokal und direkt zentral |
| Windows2025/CU8 | 150,160 | jeweils lokal und direkt zentral |
| Windows2025/CU8 | 170 | ausschließlich direkt zentral |
| Linux2019/latest | 150 | ausschließlich direkt zentral |
| Linux2022/latest | 150,160 | jeweils lokal und direkt zentral |
| Linux2025/latest | 150,160,170 | jeweils lokal und direkt zentral |

Zentral bezeichnet die direkte Nutzung im selben Installationsdatenbankkontext;
Quelle und Ziel liegen weiterhin in derselben Datenbank. Der Prüfhost war
Windows; Linux bezeichnet die SQL-Zielplattform. Dies belegt weder einen
Linux-Clienthost noch CrossDB-Kopie oder ein anderes Anmeldeprofil.

Die beiden bereits bestandenen lokalen Fälle Linux2019/CL150 und
Windows2025/CU8/CL170 wurden nicht wiederholt. Die historischen
[Copy-Nachweise](../../Modules/toolbelt.metadata.table-clone/Tests/README.md#datenkopie-41--vorbereitete-gezielte-orakel)
bleiben unverändert. Ein ScriptDom-Tokenvergleich mit dem ursprünglichen
Copy4.1-Quellstand `e19a3f27` bestätigt gleiche Signaturen und gleiche relevante
Fachlogik: ausgenommen sind ausschließlich die Hilfe und im internen Kern
der Trigger-Opt-in-Zweig. Beide Copy-Aufrufe erzwingen `IncludeTriggers=0` und
`InternalPurpose=COPY_FK`. Der Parser-Pinpatch verändert diesen Pfad nicht.
Dies ist eine statische Anwendbarkeitsprüfung, keine neue native Ausführung
und keine nachträgliche Beglaubigung unbekannter historischer Rohbytes.
Mit dieser begrenzten Wiederverwendung decken die fünf Gruppen die zwölf
Plattform-/Versions-/CL-Paare lokal und direkt zentral ab.

## Methode und Orakel

Ausgeführter Methodensnapshot:
[`ac418907`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/ac418907a2cac7ea7bea4712e0b4c279c88eb0f5).
Der [Treiber](../../Tests/Release/Invoke-TableCloneCopyTargetsLab.ps1) führt die
unveränderten kanonischen Fixtures
[Copy.Contract.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Copy.Contract.sql)
und [Copy.Safety.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Copy.Safety.sql)
aus. Pro Kontext müssen alle fünf exakten PASS-Gruppen einmal auftreten;
SQL-Fehler, fehlende oder doppelte Gruppen verhindern den Gesamt-PASS.
Geprüft sind Form/Spaltenpositionslücken, Daten/NULL/Nutzdatenbytes, KEEP und
REGENERATE einschließlich Identity-only, passende und neu angelegte FKs,
Self-/Zyklus-/externe FK-Grenzen, Admission/Temp-/Help-/Callergrenzen sowie
gemeinsamer Rollback von Daten, FK-DDL und Ausgabe beim späten CHECK-Fehler.
Produktdefinitionen und installierter Modus bleiben erhalten, die Session
endet ohne offene Transaktion.

Die privaten Runsets enthalten exakt zwölf geordnete Zielauswahlen und die
oben genannten22 Modi, eine feste45-Minuten-Frist, Methoden-/Quell-/Exportpins,
die beiden Fixturepfade und den schema-validierten Labvertrag. Mit
`-RunsetPath`, `-CaseIndex` und `-ValidateOnly` lässt sich die Admission ohne
Labimport oder SQL prüfen; `-AuditOnly` startet ausschließlich den unabhängigen
Abschlussaudit. Sieben Offlinegegenproben sichern Autoritätstyp, Ablauf/Dauer,
spätere Zielumetikettierung, ausgeschlossene grüne Modi, Fixture-/Methodenpins
und tatsächliche Änderung der Exportbytes. Sie laufen im vorhandenen
Release-Prüfprogramm, ohne neuen CI-Workflow oder neuen SQL-Trigger.

Die Testexporte verwenden unveränderte `Get-DeploymentModules`-,
`ConvertTo-StandaloneSql`- und `Export-DeploymentSql`-Funktionen des kanonischen
Deployers, mit expliziter Auswahl ausschließlich von ResultTable und Table
Clone. Der allgemeine `Deploy-All -ModuleId`-Aufruf expandiert derzeit auch
die bedingte Parserabhängigkeit und verlangte deshalb im vorbereitenden
Offlineversuch CLR-Eingaben. Dieser Versuch öffnete keine SQL-Verbindung.
Für diesen triggerfreien Copy-Test wurde keine Produktregel geändert:
die bedingte Parserabhängigkeit ist nicht erforderlich; Markerprüfung und
Abweisung jeder Benutzerassembly bestätigen die reine T-SQL-Closure.
Dies qualifiziert keinen neuen Auswahlmodus des allgemeinen Deploy-All-CLI.

## Sicherheit, Abschluss und verbleibende Grenzen

Der neue unabhängige Rahmen unter dem fortbestehenden Qualifikationsauftrag
umfasste höchstens24 Ziel-/Auditaufrufe,22 eigene Datenbanken und45 Minuten
ohne Wiederholung. Alle24 Aufrufe sind innerhalb der ursprünglichen Frist
geschlossen; alle22 Datenbanken entfernt, kein nativer Fehlversuch. Jede
Datenbank wurde vor Entfernung anhand Name, ID, Erstellungszeit und eigenem
Owner-Marker geprüft. Ein jeweils neuer Auditprozess mit frischer Verbindung
bestätigt Abwesenheit, unveränderten finalen Originaljournalhash, Inputs sowie
Serverkonfiguration und Trustbestand. Geschlossene frühere Constructor- und
andere Wellen behalten ihre Zähler, Fehler und Grenzen.

Vorhandene administrative Functional-Anmeldung, Verschlüsselung und expliziter
Trustwert stammen aus dem ausgewählten Labvertrag. Keine Rechte, Benutzer,
Logins, CLR-/Trusteinträge, Serverkonfiguration oder Labressourcen wurden
angelegt oder verändert. Dies ist keine Minimalrechte- oder authentifizierte
TLS-Abnahme. Planner-/Executor-/Trigger-/Upgradevollmatrizen, andere Identitäten,
größere Nutzdaten-/Heap-/Parallelitätsprofile, zusätzliche SNAPSHOT-Konkurrenz
und vollständige Modul-/Releasequalifikation bleiben separat. Historische
Lifecycle-, Client- und Identity-/SNAPSHOT-Nachweise werden dadurch weder neu
ausgeführt noch erweitert. Private Originaljournale und Rohlogs bleiben
außerhalb Git. Keine Veröffentlichung oder Tags.
