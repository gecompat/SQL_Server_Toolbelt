# XLSX: native Größenmatrix und aktuelles Installationspaket

Stand 2026-11-16: Die acht [Framework-Grenzworkbooks](XLSX-FULL-SIZE-FRAMEWORK.md)
bestehen unverändert auch über die öffentliche SQL-API: zwölf Engine-/CL-Paare,
jeweils lokal und direkt zentral, mit zwölf frischen unabhängigen Abschlussaudits.
Die [Evidenz](XLSX-NATIVE-PACKAGE-QUALIFICATION.json) bindet exakt diese Daten,
das neue Paket und die tatsächlich ausgeführten Methodensourcen an ihre
ursprünglichen Git-Commits. Das ist `PASS_FOR_DECLARED_SCOPE`, keine vollständige
Modul- oder Produktionskapazitätsabnahme.

## Neues fokussiertes Paket verwenden

Das [XLSX-Installationspaket](InstallPackages/SQL-Server-Toolbelt-1.0.0-XLSX-Install.zip)
mit [SHA256-Sidecar](InstallPackages/SQL-Server-Toolbelt-1.0.0-XLSX-Install.zip.sha256)
enthält ausschließlich ResultTable 1.0, ZIP Memory 1.4 und XLSX Memory 1.2.
Die beiden DLLs stammen bytegleich aus dem bereits qualifizierten
[SST-Kandidaten](XLSX-SST-BUDGET-CORRECTION.md); es gab keinen Produktbuild und
keine Änderung der Produkt-SQL-/CLR-Quellen. Zwei Paketierungen ergeben identische
ZIP-Bytes. Die aktuelle SQL-Quellclosure wird durch den kanonischen Deploy-All-
Exporter in Erst-/Repeat-/Uninstall-/UninstallAbsent-Skripte aufgelöst.

1. Den ZIP-Hash gegen den Sidecar vergleichen, in einen neuen eigenen Ordner
   entpacken und in dessen Unterordner `SQL-Server-Toolbelt-1.0.0-CLR-Install`
   wechseln. Dort liegen `START-HERE.md` und `Install-ClrPackage.ps1`.
2. Mit vorhandenem PowerShell 7 zuerst `./Install-ClrPackage.ps1 -ValidateOnly`
   ausführen. Dies prüft die vollständige Dateiliste ohne SQL oder Toolauswahl.
3. Vorhandene Rechte, eine eigene vorhandene Zieldatenbank und erforderlichen
   CLR-/exakten Assemblytrust vorbereiten. `clr strict security` bleibt aktiv;
   kein `TRUSTWORTHY`, keine Rechtevergabe und keine Infrastrukturverwaltung.
4. Mit vorhandenem sqlcmd und bestehender Anmeldung beispielsweise
   `./Install-ClrPackage.ps1 -Profile Windows-local -Action Install -ServerInstance localhost -Database Contoso`
   ausführen. `Windows-central`, `Portable-local` und `Portable-central` wählen
   den jeweiligen Modus; bei expliziter SQL-Anmeldung ein `PSCredential` verwenden.
   `Repeat` bindet den bestehenden Assemblyhash. `Uninstall`/`UninstallAbsent`
   verlangen zusätzlich `-ConfirmNoExternalConsumers`; Trust bleibt erhalten.

Der unveränderte allgemeine Installer wurde erneut mit `ValidateOnly` geprüft;
ein neuer sqlcmd-Transportlauf dieser Workbooks wird nicht behauptet. Die native
Matrix führte die exakten Paket-SQL-Bytes über den bestehenden SqlClient-Adapter
aus. Windows-/Portable-Profilskripte sind bei dieser Dreimodulclosure bytegleich;
dies wird vor der SQL-Zulassung einschließlich beider Manifestpins geprüft.
Das ältere CLR-Gesamtpaket bleibt mit seinen ursprünglichen Bytes und Nachweisen
erhalten und ist für XLSX keine aktuelle Installationsquelle dieses Builds.
Andere CLR-Module dieses Gesamtpakets wurden nicht neu paketiert oder qualifiziert.

## Tatsächlich ausgeführte Matrix

| Plattform / angeforderter Patch | SQL 2019 | SQL 2022 | SQL 2025 |
|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 |

Jeder der zwölf Fälle prüft beide Modi mit Erst- und Wiederholungsinstallation,
exakten SAFE-Assemblybytes, tatsächlicher Engine/Plattform sowie ausgewähltem
Windows-CU und Compatibility Level. Danach folgen die acht unveränderten Inputs:
16 MiB/+1 Archiv, selektierter 16-MiB/+1-Worksheet-Part, 64 MiB/+1 deklarierte
Archivsumme und 256/257 Parts. Alle übrigen festen Produktionslimits bleiben aktiv.

Die 96 positiven Aufrufe liefern jeweils genau die vollständige feste Zeile
`A1 = 42` mit geprüftem Zwölfspaltenschema. Alle 96 Überschreitungen werfen
51520 mit der erwarteten begrenzten Kategorie vor jeder Ergebniszeile.
Definitionssnapshots bleiben gleich. Öffentliche Uninstall-/UninstallAbsent-
Paketdateien entfernen in allen 24 Routen die eigenen Objekte und Assemblies
und hinterlassen einen neutralen Callerzustand. Anschließend werden die eigenen
Datenbanken entfernt und eigene unverbrauchte Trusteinträge abgeglichen entfernt;
fremde/preexistierende Zustände bleiben erhalten. Zwölf neue Prozesse bestätigen
jeweils frisch Datenbank-, Trust- und Konfigurationsabschluss und binden das
exakte finale private Journal.

## Fehlerhistorie und endliche Grenzen

Der erste Dispatch wurde vor Journal-/SQL-Anlage am Privatpfad-Guard abgewiesen.
Die verlorene ursprüngliche Exception wird nicht nachträglich erfunden: Der
Guardfehler ist separat ohne geladenen SQL-Einstieg reproduziert und durch den
reservierten frischen Read-only-Zielaudit geschlossen. Er bleibt `PRE_SQL_REJECTED`,
ohne bestandenen Grenzfall. Der erste Installationsversuch danach bleibt
`FAILED_CLEANED`: Sein neues Zustandsorakel mischte eine Metadatenabfrage mit
`XACT_STATE()` und beobachtete deren AutoCommit. Cleanup und frischer Audit bestanden.

Ein einzelner zusätzlicher Diagnose-/Auditlauf erfasste diese Ursache, stoppte
absichtlich vor allen Workbookaufrufen und bleibt ebenfalls `FAILED_CLEANED`.
Die Korrektur übernimmt das bereits qualifizierte skalare Sitzungsorakel und
trennt es von Metadatenreads; echte Callertransaktionen werden weiterhin abgewiesen.
Fünf Zeilen-/Schema-/Dispose-Gegenproben, der skalare Zustandsgegenfall und die
Paket-/Qualifikationsguards sichern diese Unterscheidung. Kein grüner Kontext
wurde wiederholt und kein früherer Fehler zum Gesamt-PASS aufgewertet.

Der noch offene Rahmen wurde vor Ausschöpfung für genau dieses Diagnosepaar von
28 auf 30 Ziel-/Auditaufrufe und DB-Reservierungen angepasst. Native Startzeit,
60-Minuten-Frist, zwei Korrekturfälle und alte Verbräuche blieben erhalten.
Alle 30 Plätze sind verbraucht und geschlossen; tatsächlich wurden 26 eigene
Datenbanken erzeugt und entfernt, davon 24 im vollständigen Matrixumfang.
Weitere SQL-Aufrufe oder Wiederholungen gehören nicht zu dieser beendeten Welle.

## Nachweise wiederverwenden und Grenzen verstehen

Die unveränderten DLL-/Zell-/Anzeige-/SST-Nachweise werden nur in ihrem ursprünglichen
Scope wiederverwendet. Die acht realen Größeninputs wurden im Framework nicht erneut
ausgeführt; ihre exakten vorherigen Bytes wurden kopiert und gehasht zugelassen.
Bereits grüne fachfremde API-Matrizen wurden nicht wiederholt. Die unveränderten
generischen Paketexporte und Installerfunktionen bleiben kanonisch; zusätzliche
Reviewagenten oder eine neue Reviewkette waren für diesen unveränderten Produkt-
und Rechtescope nicht nötig. Die vorhandene Release-CI ergänzt die neuen Guards
einmal und prüft weiterhin tatsächlichen Head und Main. Private Rohkanäle und
Journale bleiben lokal; im Repository stehen ausschließlich bereinigte Aussagen
und öffentliche Artefakt-/Quellenbindungen.

Historische Matrix- und Testsammelquellen bleiben bytegleich. Der neue Prüfer
validiert Ausführungspins gegen den benannten ursprünglichen Git-Commit und
berechnet aktuelle Produktanwendbarkeit separat. Künftige Produktänderungen
erhalten damit keine alte Qualifikation und verlangen auch kein Umschreiben
historischer Ausführungssourcen.

Dies ist ein Windows-Client-/SqlClient-Funktionsnachweis gegen Windows- und
Linux-Engines. Authentifiziertes TLS, ein neuer sqlcmd-Transportlauf, ein externer
Linux-Exportclient, Peak-RAM und Produktionskapazität sind nicht Teil dieser Welle.
Die deklarierte 64-MiB-Summe ist ein Archivindexnachweis, keine vollständige
Materialisierung unselektierter Zusatzparts oder Heapmessung. Modulstatus bleibt
`partially validated`, Releasezustand `unreleased`. Keine Veröffentlichung oder Tags.
