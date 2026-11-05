# Buildgebundene Ausgabequotenabnahme

Status: **Freigegeben durch ausdrückliche Benutzerentscheidung vom 2026-11-05.**

Der bestehende Hardening-Vertrag trennt Helperprüfungen von tatsächlichen
öffentlichen Grenzaufrufen. Der aktuelle unveränderte Provider hat mehrere
hintereinander geschaltete Grenzen. Ihre gleichzeitige Erreichbarkeit ist
deshalb von ihrer korrekten Durchsetzung zu unterscheiden.

## Bereits ausgeführte öffentliche Nativeprüfungen

Die vier APIs und datenbanklokalen Minimalrechte sind auf Windows SQL Server
2019/CU32 CL150, 2022/CU26 CL150/160 und 2025/CU8 CL150/160/170 jeweils lokal
und zentral geprüft. Die Tokenausgabe liefert 8.191 und 8.192 Zeilen; der
8.193er-Fall scheitert am tatsächlichen öffentlichen Tokenlimit. Auf 2022
und 2025 liefert Errors 255 und 256 Zeilen. Der gewählte 257er-Fall scheitert
bereits am vorgeschalteten Atomlimit, nicht am Errors-Ausgabebudget.

Es gibt **keinen** öffentlichen Native-Nachweis für 32.768 Nodezeilen, den
16-MiB-Property-Ausgabeübergang oder den 257er-Errors-Quotenfehler. Diese
Ausführungen werden auch bei Annahme dieses Vorschlags nicht als PASS erfasst.

## Freigegebene ergänzende Nachweismethode

1. Nativeaufrufe der erreichbaren Grenzen und sämtlicher vier APIs bleiben
   erforderlich. Bestehende Framework-, Syntax-, Lifecycle-, Rechte- und
   Bereinigungsnachweise bleiben erhalten.
2. Der Originaltyp `OutputBudget` aus dem unveränderten Releasebinary wird
   zusätzlich mit **beiden unveränderten Produktionslimits** geprüft:
   256/8.192/32.768 Zeilen zusammen mit 16 MiB sowie 131.072 Properties
   zusammen mit 16 MiB. Nach abgewiesenen Adds bleiben seine Zähler unverändert.
   Dies bleibt ausdrücklich Binary-/Helper-Evidenz, kein öffentlicher API-Lauf.
3. Die Byteprüfung hält 16 MiB fest und variiert die Belastung. Wegen
   UTF-16 plus 128 Byte je Zeile sind nur gerade Verrechnungswerte möglich;
   geprüft werden 16 MiB minus zwei, genau 16 MiB und 16 MiB plus zwei.
4. Eine quellgebundene Invariantenprüfung sichert die vier Budget-Addstellen
   vor allen vier Row-Adds, feste Produktionslimits, breite geprüfte Arithmetik
   und die vollständige Pufferung vor Rückgabe. Diese ist ein überprüfbares
   Codeargument, keine Behauptung einer maschinellen Vollverifikation von C#.
5. Dominierte Grenzen werden mit einer konservativen Rechnung ausgewiesen:
   Errors belegt höchstens `256 * (128 + 2 * 4000)` Byte; Tokens höchstens
   `8192 * (128 + 2 * 64) + 2097152` Byte. Für Nodes wird das Maximum der
   Typ-/Propertynamen aus dem exakt gepinnten ScriptDom-Typkatalog eingesetzt.
   Bei Properties kostet jede Zeile mindestens `128 + 2 * (1 + 4) = 138`
   Byte; die Bytegrenze greift somit vor 131.072 Propertyzeilen.

## Unveränderte Grenzen und Aussagekraft

Die Komponenten sind separat reproduzierbar:

- `Tests/Static/validate_output_invariants.py` prüft den betrachteten
  Providerkörper und verwirft sieben veränderte unsichere Quellen.
- `Tests/Framework/Invoke-Contract.ps1` prüft mit den explizit übergebenen
  Release-/Dependency-/Manifestpfaden auch `actual-output-budgets`; der
  vollständige aktuelle Lauf hat 248 begrenzte Fälle.
- `Tests/Framework/Test-OutputDominance.ps1 -ScriptDomDllPath ...` verlangt
  den exakten veröffentlichten Dependency-Pin und prüft Typkatalog und Rechnung.
- `Tests/Static/validate_qualification.py` schützt den öffentlichen
  Matrix-/Audit-/Quotenstatus vor einer Aufwertung fehlender Nativeaufrufe.

Keine SQL-Signatur, Atom-, Eingabe-, Zeilen-, Tiefen- oder Bytequote wird
geändert. Keine erweiterte Eingabeannahme und kein verändertes Produktbinary.
Die Methode behauptet weder die Unerreichbarkeit aller übrigen API-Quoten
noch universelle ScriptDom-Sicherheit, feste Heapgrenzen oder vollständige
Syntaxabdeckung.

Die ausdrücklich freigegebene Ausgabequotenabnahme für diesen Build besteht
aus den einzeln gekennzeichneten Native-, Binary- und Invariantenbelegen.
Die oben genannten öffentlichen Grenzaufrufe bleiben nicht ausgeführt;
der freigegebene Gesamtnachweis behauptet keinen vollständigen nativen
Quoten-Branchlauf. Ein Quellen-, Pin-
oder Produktbinarywechsel invalidiert die betroffenen Belege; grüne CI
ersetzt diese Bindung nicht.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-05`
- Nachweis: `local: Invoke-ScriptParserCurrentLab.ps1 plus separate configuration recovery/audit; Framework/Invoke-Contract.ps1`
- Scope: Unveränderter aktueller Quellbuild2.0.1: native API-/datenbanklokale Minimalrechtematrix Windows2019CU32/2022CU26/2025CU8 über unterstützte CLs lokal/zentral,72 Suites; frische Parser-/Konfigurationsaudits PASS. Erste Lifecycle-Literalhashfehler und ursprüngliche2025Caller-Restoreblockade bleiben erhalten, finale eigene Wiederherstellung PASS. Token-Grenze nativ, Errors255/256 und vorgelagerte257er-Atomablehnung auf2022/2025. Framework248 inklusive unveränderter Originalbudgets; kombinierte Quotenabnahme ausdrücklich am2026-11-05 freigegeben, keine Aufwertung nicht ausgeführter öffentlicher Grenzaufrufe.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
