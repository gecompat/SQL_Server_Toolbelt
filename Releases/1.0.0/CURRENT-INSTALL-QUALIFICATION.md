# Gemeinsamer aktueller Installer: begrenzte native Abnahme

Stand 2026-11-17: PASS_FOR_DECLARED_SCOPE. Der
[maschinenlesbare Record](CURRENT-INSTALL-QUALIFICATION.json) bindet das
[aktuelle gemeinsame Installationspaket](InstallPackages/SQL-Server-Toolbelt-1.0.0-Current-Install.zip),
die ausgeführten Methoden und ihre Quellen. Die [Installation](CURRENT-INSTALL.md)
bleibt für leere ausgewählte Datenbanken bestimmt, ohne Veröffentlichung oder Tags.

## Aktueller Umfang

| SQL-/Patchselektor | CL | Windows | Linux/latest |
|---|---|---|---|
| 2019/CU32 | 150 | Windows-local und Windows-central | Portable-local und Portable-central |
| 2022/CU26 | 160 | Windows-local und Windows-central | Portable-local und Portable-central |
| 2025/CU8 | 170 | Windows-local und Windows-central | Portable-local und Portable-central |

Sechs vollständige Gesamtfälle und sechs frische separate Audits bestehen.
Zwölf Profile prüfen die gemeinsame Neuinstallation, 510 Modul-Inventarzeugen
und 1.578 tatsächliche Hilfeaufrufe einschließlich interner Helfer mit 126.810
Assertions. Der jeweilige frische Audit bindet das unveränderte finale Journal.
Beide realen Prozessrückgaben je Paar sind 0, die Captures vollständig und
Stderr leer; die unmittelbar gesicherten Rückgabereceipts bleiben privat.
Alle zwölf eigenen Datenbanken des erfolgreichen Teilumfangs sind entfernt;
eigene Trust- und erforderliche CLR-Konfiguration sind restauriert, vorhandene
Verbraucher und fremde Konfigurationen wurden nicht verändert.

## Wiederverwendung und notwendige Korrekturen

Die übrigen bereits geprüften DLLs werden bytegleich übernommen. Aktuelle
Constructors und Parser sind an ihre geprüften Originalbinaries und heutigen
Compilerquellen gebunden. Die erste gemeinsame Installation scheiterte an der
alten exakten Parserbindung von SSIS. Der kanonische Generator aktualisiert
nur die Parserhashliterale in drei bestehenden Bindungsquellen. Ein
[eng begrenzter Originalquellleser](../../Scripts/Release/ssis_parser_binding_history.py)
prüft die unveränderten alten Records weiterhin mit ihren tatsächlichen
Originalbytes; jede zusätzliche Quelländerung oder Archivdrift wird abgewiesen.

Der neu gebaute SSIS-Provider ist zweimal reproduziert und besteht 29 begrenzte
Frameworkprozesse. Die gemeinsame native Installation prüft die aktualisierte
Dependencybindung. Kein Fachalgorithmus, SQL-Objekt, öffentlicher Parameter oder
Rechtevertrag wurde ergänzt oder gelockert. Frühere Sicherheits-, Fach-, SSMS-
und TLS-Records behalten ihre ursprünglichen Providerbytes; sie werden nicht
zum aktuellen Gesamt-Binärnachweis umgedeutet. TLS und GUI wurden nicht wiederholt.

Ein zweiter Gesamtfall scheiterte an einem falschen Inventarorakel: Windows
Filesystem und SSIS besitzen nur einen Versionsmarker auf Datenbankebene.
Der korrigierte Adapter prüft für genau diese beiden vorhandenen Verträge den
Versionsmarker und für alle anderen den DeploymentMode. Eine Gegenprobe liest
dafür die echten kanonischen Deployclosures. Beide ursprünglichen Koordinatoren
bleiben FAILED_CLEANED; ihre beiden frischen Abschlussaudits sind PASS.
Kein vollständig bestandener Ziel-/Modusfall wurde erneut ausgeführt.

## Gemeinsame Grenzen und Historie

Der konkrete neue Installerauftrag enthielt kein numerisches Benutzerlimit.
Der interne offene Rahmen wurde nach dem bestätigten Inventarbefund vor
Ausschöpfung von 16/16 auf 18 Dispatch-/DB-Reservierungen angepasst. Originaler
Start, 60-Minuten-Frist, Fehler und Verbräuche blieben erhalten. Insgesamt sind
17 Dispatchreservierungen und 18 DB-Reservierungen geschlossen: 16 tatsächliche
Kindprozesse plus ein vor Kindstart abgewiesener Launcheraufruf. Ein weiterer
Controller-Datumsfehler blieb ebenfalls vor einem neuen Dispatch. Beide
Setupfehler und die erste Admission-Pindrift sind privat erhalten, keine PASS.

14 tatsächlich angelegte eigene Datenbanken wurden entfernt, darunter die
beiden ersten fehlgeschlagenen Fälle. Alle acht frischen Audits sind PASS.
Keine neuen Principals, Grants, Serverrollen, Lab-, Zertifikats- oder
Truststoreänderungen. Private Rohjournale, Marker, Konfigurationen und Captures
werden nicht veröffentlicht. Modulstatus und der bisherige Supportzielumfang
bleiben erhalten; keine vollständige fachliche Wiederqualifikation aller Module,
kein Universalupgrade und kein Veröffentlichungsnachweis.

## Reproduzierbare Offlineprüfung

    python Scripts/Release/current_install_package.py --verify Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Current-Install.zip
    python -B Tests/Release/test_current_install_package.py
    python -B Tests/Release/test_current_install_qualification.py

Diese Prüfungen starten keine SQL-Verbindung. Head- und tatsächliche Main-CI
sind eigenständige Integrationsgates und werden im integrierenden PR festgehalten.
