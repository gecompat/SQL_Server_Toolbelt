# Einheitliche aktuelle Toolbelt-Installation

Status: ausdrücklich zur autonomen Umsetzung freigegeben am 2026-11-20.
Der Benutzer beauftragt nach dem vollständigen Deploymentabgleich die offenen
Punkte bis zur Integration auf origin/main und einem gebauten Release,
einschließlich Dokumentation. Die Freigabe zum Bauen ist keine Veröffentlichung.

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
