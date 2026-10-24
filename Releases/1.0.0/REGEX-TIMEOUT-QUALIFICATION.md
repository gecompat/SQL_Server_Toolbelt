# Begrenzte Regex-Timeout-Untersuchung

Stand: 2026-10-24. Expliziter Benutzerauftrag: den offenen Timeout im Lab
untersuchen und beheben, Sicherheitsbudgets unverändert lassen, einen PR
vorlegen. Keine Veröffentlichung; autonome Weiterentwicklung bleibt pausiert.

## Befund und Korrektur

Der frühere SQL6522-Fehler in `Transformations.Contract.sql` kam aus
`RegexReplace` mit `TBX_REGEX_TIMEOUT` beim kooperativen Gesamtbudget.
Die sieben isolierten positiven Grenzaufrufe und die ursprüngliche vollständige
Fixture mit ihrem Text-Testvorlauf bestanden in dieser Untersuchung bereits
mit der alten qualifizierten DLL. Ein deterministischer Reproduktionsnachweis
für den historischen Timeout liegt damit nicht vor.

Der Replace-Pfad kopierte auch unveränderte große Quellen sowie einen
vollständigen Literalersatz über einen StringBuilder erneut. Die Korrektur
vermeidet diese Materialisierung nach derselben Validierung und erforderlichen
Suche. Occurrence=0 enumeriert weiterhin terminale leere Treffer. Die
abschließende Deadlineprüfung bleibt bestehen. Diese Kopien sind ein möglicher
Beitrag zum Timeout, keine bewiesene alleinige historische Ursache.

Der neue deterministische Frameworkvertrag weist den Kopierpfad bei der alten
DLL mit `REPLACE_REDUNDANT_NO_MATCH_COPY` nach. Er verlangt vollständige
Ergebnisbytes und unveränderte Semantik; Referenzidentität ist lediglich ein
internes Allokationsorakel. Die Grenzen bleiben 500/2000 ms insgesamt,
höchstens 250 ms je Suche und 2/16 MiB je Quelle/Ersatz/Output.

## Qualifikationsstand

Die beiden unveränderten Diagnosefälle wurden jeweils mit eigenem DB-/Trust-
Cleanup und frischem separatem Audit abgeschlossen. Korrekturbuild,
Frameworkregression und neue native Paket-/API-Qualifikation stehen bis zum
Abschluss dieses Arbeitspakets noch aus. Historische Ergebnisse in
[API-QUALIFICATION.md](API-QUALIFICATION.md) werden nicht rückwirkend umgedeutet.
