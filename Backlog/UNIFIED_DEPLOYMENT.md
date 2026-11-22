# Einheitliche aktuelle Toolbelt-Installation

**Status 2026-11-22 nach der ZIP-Abnahme.** Der gemeinsame private
Installationssatz wurde aus `98f49b53` neu gebaut. Die
[gebundene Abnahme](../Scripts/Install/Tests/QUALIFICATION.md#gemeinsamer-installationssatz-nach-der-zip-abnahme)
nennt die vier Installationsprofile und ihre nativen Prüfkontexte.

**Status 2026-11-21.** Der gemeinsame Create-only-Installer und der
Usage-Skill-Katalog sind integriert. Der lokal gebaute Installationssatz
`v1.0.0-rc.5` aus Merge-Commit `73eec6e3` enthält die vier Windows- und
Portable-Profile, die erweiterte Trust-Auswahl und die DTSX-Lookup-Korrektur.
Alle vier Profile und die ZIP-Prüfsummen wurden offline geprüft.

Die native Windows-Lokalabnahme ist an
[PR #630](https://github.com/gecompat/SQL_Server_Toolbelt/pull/630) gebunden.
[PR #632](https://github.com/gecompat/SQL_Server_Toolbelt/pull/632) belegt den
gesonderten Trust-Zweig für vorbereitete Datenbanken.
[PR #633](https://github.com/gecompat/SQL_Server_Toolbelt/pull/633) belegt die
Lookup-Korrektur. Die Nachweise gelten jeweils für ihre dokumentierten Profile.
Die [Installationsanleitung](../INSTALL.md) ist der Einstieg für Anwender.

Die folgenden Abschnitte dokumentieren den am 2026-11-20 freigegebenen
Implementierungsauftrag und die Zwischenstände vor seiner Integration.

## Verbindlicher Gesamtumfang

1. Alle aktuellen SQL-Assemblynamen und ihre Referenzen beginnen mit `tlblt`.
   Manifest, Source, Installationsbuilder und Capability-Projektion müssen
   übereinstimmen. CLR-Klassen und bereits eigene Toolbelt-CLR-Identitäten
   werden dadurch nicht unnötig umbenannt. Die isolierte ScriptDom-Identität
   und ihre vorhandenen gültigen Koexistenznachweise bleiben erhalten.
2. Ein kanonischer markerfreier Installationskern für gemeinsame und einzelne
   Module, lokal und zentral, Windows und Portable mit ihren bestehenden
   Plattformgrenzen. Keine angebotenen aktuellen Installationswege dürfen
   stillschweigend zurück auf markerbasierte Deployments wechseln.
3. Normale SQL-Dateien ohne SQLCMD, nur anfängliches USE anpassen. Wahlweise
   Hashfreigabe, vorhandener DB-Trust mit Hashvergleich oder ohne Hashvergleich.
   Keine automatische Aktivierung von TRUSTWORTHY, keine Rechtevergabe oder
   Abschaltung von Strict Security. Keine Deployment- oder Versionsregistry.
4. Den Ein-Aufruf-Client einschließlich der ausdrücklich optionalen
   Datenbankanlage und CLR-Aktivierung an diesen Kern anbinden. Bestehende
   Sicherheitsgrenzen der Vorbereitung und tatsächliche Engineberechtigungen
   erhalten; keine pauschale sysadmin-Bedingung für reine Objekterstellung.
5. Keine Toolbelt-eigenen Extended Properties in aktueller Installation oder
   Runtimeabhängigkeitsprüfung. Das bereits beauftragte fachliche Kopieren
   benutzerdefinierter Tabellen-Properties bleibt davon getrennt.
6. Create-only bleibt der Lebenszyklus: bestehende Objekte/Installationen
   werden weder automatisch aktualisiert noch entfernt. Aktuelle Einstiege
   dürfen historische Upgrade-/Uninstall-Skripte nicht als dafür geeignet
   ausgeben. Historische Releases, Originalquellen und Nachweise erhalten.
7. README, INSTALL, Modul- und Deploymentlesewege auf denselben aktuellen
   Vertrag führen. Quellbuild, fertiges Installationspaket und historische
   Vorabreleases verständlich unterscheiden.
8. Aktuellen Release-/Installationssatz reproduzierbar bauen, Quell- und
   Binarybindung sowie Offlinepaketkontrollen prüfen. Regulärer PR, grüne
   tatsächliche Head-/Main-CI, Arbeitsbranches und entbehrliche Worktrees
   bereinigen. Keine Veröffentlichung oder Tags.

## Vorgehen und Abnahme

Ein Implementierungsverantwortlicher, keine Delegation. Zusammengehörige
Änderungen bleiben auf einem Arbeitsbranch; Integration erst bei nachgewiesener
Konsistenz des Gesamtumfangs. Fokusabschnitte erhalten einen endlichen Rahmen
von höchstens 90 Minuten einschließlich lokaler Prüfungen und einen privaten
Checkpoint. Ein solcher Checkpoint beendet nicht den fortbestehenden Auftrag.
Vorhandene geschlossene SQL-/Auditbudgets werden nicht erneuert; dieser erste
Abschnitt führt keine SQL-/TLS-/GUI-Aufrufe und keine Infrastrukturaktionen aus.

Verarbeitungsaufwand: Eine kanonische Source-Ermittlung und ein gemeinsamer
Builder ersetzen mehrfach gepflegte Installationslogik. Gezielte Offline-
Gegenproben und Paketprüfung zuerst; vorhandene unveränderte Runtimebelege
mit tatsächlicher Bindung wiederverwenden. Keine Wiederholung grüner
Fachmatrizen allein wegen Namenspflege oder Dokumentation. Pflicht-CI bleibt
erhalten; historische Belege dürfen aktuelle Änderungen nicht qualifizieren.
Notwendige neue Runtimeprüfung nur bei tatsächlichem geänderten Enginevertrag
und innerhalb konkret gültiger Autorität, nie als pauschaler Vollumlauf.

Die Abschlussprüfung muss jeden obigen Punkt einzeln an tatsächlichen Sources,
Builderausgaben, Paketinhalt und CI-/PR-Zustand nachweisen. Ein grüner Teilsatz
ist keine Erledigung dieses Gesamtauftrags.

## Trennung der Regressionen beim Lifecyclewechsel

Die bisherigen modulspezifischen Staticprüfungen enthalten zahlreiche konkrete
Marker-, Deploy-/Uninstall- und Upgradeassertions. Diese bleiben unverändert im
festen Vorgänger `2fbe8e3e` ausführbar. Die aktuellen Einstiegsskripte prüfen
zuerst die Source-Äquivalenz ihrer ausgewählten Komponenten und Abhängigkeiten:
keine CLR-/Fachänderung außer den ausdrücklich benannten SQL-Assemblyreferenzen
und ihren Kommentaren. Ein anderer Fachquellstand verwirft diese Wiederverwendung.
Anschließend laufen die ursprünglichen Lifecycleassertions am festen Original.

Der gemeinsame aktuelle Installationskern, Paketinhalt, Trustauswahl,
Clientprotokoll und Vorbereitungsübergang haben eigene aktuelle Prüfungen.
Historische Releasesuite und früherer SQLCMD-Export laufen ebenfalls explizit
am Original. Kein solcher historischer PASS qualifiziert neue Deploymentbytes.
Die sourcegebundene Zuordnung vermeidet das Umschreiben alter Nachweise und
erhält alle ursprünglichen Assertions. Zukünftige Fachänderungen benötigen eine
neue aktuelle Abnahme; sie dürfen diesen Äquivalenzguard nicht still umgehen.

Zusätzlicher Aufwand: Die kleinen Komponentenvergleiche ersetzen keine Gates;
die vorhandene Releasesuite behält ihr endliches 30-Minutenlimit. Es entstehen
keine SQL-/TLS-/GUI-Dispatches. Gemeinsame Paket-/Clienttests laufen einmal im
aktuellen zentralen Gate; die noch offenen Workflowadapter müssen vor Integration
auf dieselbe Trennung geprüft werden. Keine vollständige CI-Abnahme behaupten.


Native CI des retired SQLCMD-/Marker-Lifecycle wird nicht automatisch gegen
den neuen Installer ausgeführt: deren Upgrade-/Marker-/Uninstall-Orakel prüfen
einen anderen, ausdrücklich abgelösten Vertrag. Die vollständigen Jobs und
Cleanupkörper bleiben als manuell auslösbare historische Prüfung am festen
Originalcommit erhalten. Automatische Komponenten-Gates prüfen Äquivalenz und
Originalassertions; reine aktuelle Framework-/Compilerprüfungen bleiben aktiv.
Aktuelle gemeinsame Paket-/Clientgates decken den neuen Deploymentvertrag ab.
Dies spart unpassende wiederholte native Altmatrizen und behauptet keine neue
native Gesamtqualifikation. Änderungen an Fachquellen blockieren den Reuseguard
und benötigen einen neuen aktuellen Nachweis-/Adapterscope vor Integration.


## Ergänzter Benutzerumfang: Objekt-Skills

Am 2026-11-20 verlangt der Benutzer zusätzlich maschinenlesbare Skillanweisungen
für alle katalogisierten SQL-Objekte einschließlich interner Helfer und Tabellen: Prozeduren über Hilfe, Funktionen
in ihrer DDL. Die nach Erklärung der CLR-Grenze ausdrücklich genehmigte zusätzliche
SQL-Sicht und der vollständige Abnahmevertrag stehen in
[OBJECT_USAGE_SKILLS.md](OBJECT_USAGE_SKILLS.md). Dieser Punkt gehört vor dem
Gesamtabschluss in denselben aktuellen Release-/Installationsstand. Eine reine
Deploymentfertigstellung ohne diesen Zusatz erfüllt den Gesamtauftrag nicht.
