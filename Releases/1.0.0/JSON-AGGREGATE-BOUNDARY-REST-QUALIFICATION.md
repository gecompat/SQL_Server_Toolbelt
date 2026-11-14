# Aggregate-Restwelle: unterbrochen, keine neue Gesamtqualifikation

Stand 2026-11-14: **NOT_QUALIFIED_INTERRUPTED**. Die freigegebene Restwelle
schließt weder die vier großen gültigen Eintragsgrenzen noch Linux SQL2025/latest
CL170 lokal/zentral ab. Die [vorige Teilqualifikation](JSON-AGGREGATE-ERRORS-QUALIFICATION.md)
mit 2.640 kleinen Profilen bleibt in ihrem ursprünglichen Scope erhalten.
Kein Produkt-, Binär-, Quoten- oder Rechtevertrag wurde geändert.

## Vorbereiteter und offline geprüfter Restumfang

Der [Adapter](../../Tests/Release/Runtime/JsonConstructors.AggregateErrors.Contract.ps1)
ergänzt vier ausschließlich gültige Eintragsmengen mit einem Eintrag über dem
jeweiligen Limit und die acht getrennten Count-Prioritätsvektoren. Nur im noch
fehlenden Linux-/CL170-Kontext werden die 120 kleinen Fehlervektoren je Modus
zusätzlich ausgewählt. Die 22 grünen kleinen Kontexte werden nicht wiederholt.

Große Vektoren verwenden die ausdrücklich ausgewählte SQL-Form `MAXDOP 1` und
höchstens 180 Sekunden Statementzeit. Das ist eine neue begrenzte Ausführungsform,
kein Nachweis der Ursache früherer Timeouts und kein Engine-Merge-/Heap-/Spill-
oder allgemeiner Hardwallvertrag. Der scoped Koordinator begrenzt Facharbeit auf
zwölf Minuten und Cleanup auf dreizehn Minuten; zusätzlich gilt die ursprüngliche
Gesamtfrist. Andere Scopes behalten ihre bisherigen Statement-/Koordinatorgrenzen.
Typisierte Eingaben, exakte SQL6522/Severity16/Tag-Orakel, null Teilzeilen sowie
Eingabe-/Modul-/Rechte-/Sitzungs-/Transaktions-/AppLock-Vergleiche bleiben erforderlich.

## Tatsächliche Unterbrechungen und begrenzte Befunde

Ein erster Start wurde vor jedem Kindprozess und SQL-Zugriff wegen einer zu
hohen Prozesszeitangabe abgewiesen. Die Korrektur hält die vorhandene
900.000-ms-Prozessgrenze ein; die zwei Reservierungen bleiben verbraucht.

Danach verlor die ausführende Sitzung ihren Koordinator. Das originale Journal
bleibt `RUNNING`; zwei Array-Profil1-Count-Prioritätsreceipts wurden zuvor gespeichert.
Sie sind lediglich Teilbefunde und kein Abschluss eines gültigen großen Inputs.
Die alte PowerShell-Dateisicht war nicht mehr vorhanden. Der neue signierte
Runtimepfad enthielt nachweislich identische Bytes. Ein neuer Recovery-Eingang
band ausschließlich diese Pfadzuordnung; das Original blieb unverändert.
Eine erste Recovery war zuvor an der fehlenden Dateisicht ohne SQL gescheitert.
Die separate eigentumsgeprüfte Bereinigung und ihr frischer Audit bestanden.
Das qualifiziert weder den ursprünglichen Gesamtlauf noch eine OS-Ausfallsicherheit.

Der unabhängige Linux-Kleinfalllauf verlor anschließend ebenfalls seine Sitzung.
Sein Originaljournal enthält ausschließlich Nullbytes und wird unverändert als
beschädigter Nachweis erhalten. Es gibt daraus keine verwertbare Coverage und
keinen Gesamt- oder Cleanup-PASS. Die Ursache des Datenverlusts ist nicht
abschließend geklärt. Die Testfrist ist abgelaufen; es wurden keine weiteren
Qualifikationsläufe begonnen.

Zwei danach ausschließlich lesende Sicherheitsprüfungen fanden eine temporäre
Testdatenbank und zwei Trust-Einträge mit passendem gemeinsamen Owner-Marker.
Der verlorene Vorzustand wird daraus nicht rekonstruiert oder als bewiesen
behauptet. Nach ausdrücklicher Benutzerfreigabe wurden ausschließlich diese
exakt gebundenen drei Ressourcen entfernt: Datenbankidentität, Erzeugungszeit,
Owner-Marker, Trusthashes/-beschreibungen/-zeiten, aktuelle Fingerprints und
fehlende fremde Verbraucher wurden erneut geprüft. Ein neues explizit autorisiertes
Rebound-Journal und ein unabhängiger frischer Audit bestehen. Konfiguration und
fremde Trust-Einträge blieben gegenüber dem Vorzustand dieser Sicherheitsbereinigung
unverändert. Der verlorene ursprüngliche Konfigurationsvorzustand bleibt unbekannt.
Das beschädigte Original bleibt unverändert; die Bereinigung ist kein nachträglicher
PASS des verlorenen Fachlaufs. Sie benötigte zwei gesondert freigegebene
Sicherheitsaufrufe innerhalb von höchstens 15 Minuten und keine neue Testdatenbank.

Die Abrechnung bleibt konservativ: vierzehn Ziel-/Auditreservierungen einschließlich
zwei nachgelagerter Sicherheits-Leseaufrufe und zwei expliziter Sicherheitsaufrufe, sechs DB-Reservierungen, keine
abgeschlossene neue Fachmatrix. Freie Plätze verlängern die abgelaufenen
60 Minuten nicht. Die frühere Welle mit 32 verbrauchten Aufrufen bleibt getrennt.

## Journalhärtung nach dem konkreten Verlust

Der [gemeinsame private Journalwriter](../../Tests/Release/Invoke-StablePackageLab.ps1)
schreibt nun eindeutige eigene temporäre Dateien mit `WriteThrough` und
`Flush(true)` vor dem atomischen Ersatz. Eine separat geflushte `.previous`-Datei
enthält den zuvor gültigen Zustand; bei der ersten Speicherung gibt es zwei
Kopien desselben initialen Zustands. Leere, NUL-haltige, ungültige oder nicht
objektförmige bestehende Journale werden nicht überschrieben. Ein Fehler beim
Ersatz entfernt ausschließlich eigene temporäre Dateien und erhält das gültige
aktuelle Journal. Backups sind kein automatisch autorisierter Restore und
kein Ersatz für Ownershipprüfung und frischen Audit.

Das benötigt pro Speicherung zwei dauerhafte Dateischreibvorgänge statt eines
ungeflushten Ersatzes und höchstens eine zusätzliche vorherige Journaldatei.
Die stärkere Persistenzgrenze ist wegen der darin gebundenen Ownership- und
Wiederherstellungsinformationen notwendig. Keine neuen CI-Trigger, Agenten,
Reviewketten oder parallelen Vollprüfungen werden eingeführt. Eine garantierte
Wiederherstellung nach beliebigem OS-/Datenträgerausfall wird nicht behauptet.

Historische Regex- und SSIS-Installer-Nachweise behalten ihre unveränderten
Runnerhashes. Ihre Prüfer lesen diesen früheren Runner über den vorhandenen
kanonischen `evidence_sources`-Resolver aus den deklarierten beziehungsweise
exakten unveränderten Report-Commits. Die Listeneinträge des Installerberichts
werden weiterhin einzeln auf ihren originalen Hash geprüft. Aktuelle abweichende
Runnerbytes gelten damit ausdrücklich nicht als historisch ausgeführt; die neue
Journalfunktion hat eigene aktuelle Gegenproben. Keine historischen Berichte,
Quellpins, Pakete oder Archive werden umgeschrieben.

Fünf Offlineprüfungen bestehen: kanonische Admission/Provenienz, geschlossene
Fehlervektoren, beschädigte Wiederverwendungsreceipts, Restscope/Statementzeit/
Gesamtfrist und echte Dateifehler-Gegenproben für Journalersatz, vorherigen
Zustand, temporäre Dateien und NUL-Korruption. Die Journalhärtung wurde nach Ablauf ausschließlich im ausdrücklich freigegebenen
Sicherheitscleanup eingesetzt; es gab keine erneute native Fachqualifikation. Head- und tatsächliche
Main-PUSH-CI sind getrennte Integrationsgates; sie schließen keine native Lücke.

Die [Testmatrix](../../Modules/toolbelt.json.constructors/Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md)
und [Testanleitung](../../Modules/toolbelt.json.constructors/Tests/README.md)
verlinken diesen Fehler-/Methodenabschluss. Modulstatus bleibt `partially validated`,
`unreleased`; vier große Eintragsgrenzen und Linux/CL170 bleiben offen.
Keine Veröffentlichung oder Tags.
