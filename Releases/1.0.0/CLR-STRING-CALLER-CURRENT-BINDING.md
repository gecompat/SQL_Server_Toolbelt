# CLR-String-Callerrechte: aktuelle Zuordnung vorhandener Nachweise

Der Quellenabgleich vom 2026-11-08 bestätigt den bestehenden
[Caller-Nachweis vom 2026-10-25](CLR-STRING-CALLER-QUALIFICATION.md)
für die unveränderten Phonetik-/Edit-Distance-Modulinputs. Die pauschale
Angabe „tatsächliche Minimalrechte offen“ ist für diese bereits geprüften
direkten Datenpfade überholt. **Kein neuer SQL-Lauf, kein Build, keine neue
Rechtevergabe und keine Statushochsetzung** wurden dafür durchgeführt.

## Bereits qualifizierter Umfang

Fünf öffentliche TVFs: Cologne Phonetic, Double Metaphone, Levenshtein,
OSA Distance und Jaro-Winkler. Zwölf Windows-/Linux-Engine-/CL-Paare,
jeweils lokal/direkt zentral: **120 positive Einzel-SELECT-Profile,
1440 SQL229-Abweisungen und 480 feste Wert-/NULL-/Kardinalitätsorakel**.
Interne CLR-Kerne, jeweils andere öffentliche Einstiege und ResultTable-Helfer
bleiben während der Einzelprofile gesperrt. Der Originalbericht erklärt
Gegenkontrollen, Artefaktbindung, die erhaltene Fehlerhistorie und Cleanup.

## Aktuelle Anwendbarkeit ohne neue Ausführung

Der kanonische historische Quellenleser löste die Originalbytes aller
Eingabepins aus der unveränderten
[JSON-Projektion](clr-string-caller-qualification.json) auf und bestätigte deren
Digests. Sämtliche **29 ausgewählten Moduldateien** sind aktuell bytegleich:
CLR-/Projektinputs, öffentliche/interne SQL-Fassaden, Deployment-/Trustskripte
und Manifeste beider Module. Ein privater deterministischer Vergleich hält
Recordpin, Pfadmenge und aktuelle Gleichheit fest. Die ursprünglichen
Ausführungs-, Methoden-, Build- und Binarypins bleiben unverändert.

Spätere allgemeine Installer-/Help-Methoden werden dadurch nicht rückwirkend
als damalige Ausführung ausgegeben. Der Nachweis gilt weiter für seine
ursprünglich qualifizierten Artefakte und unveränderten Modulpfade, nicht für
beliebig neu gebaute oder abweichende DLLs. Die
[aktuelle Phonetik-Frameworkprüfung](PHONETIC-CURRENT-FRAMEWORK-QUALIFICATION.md)
bleibt ein eigener begrenzter Nachweis und keine neue native Rechteprüfung.

## Weiter getrennte Gates

- Lifecycle-DDL-/Release-Marker-Rechte und andere Owner.
- Echte niedrigprivilegierte Netzwerk-/CrossDB-Identitäten.
- Noch unbelegte vollständige API-/Client-/Lifecycle-Zielprofile.
- Phonetik: vollständige Scannerabdeckung und transitive SAFE-Gesamtabnahme.
- Weitere ausdrücklich zugesagte Ressourcen-/Heap-/Recoveryprofile.

Historische datierte Einschränkungen und generierte Evidenzblöcke bleiben
erhalten; aktuelle Übersichten verweisen auf diesen engeren Abgleich.
Beide Module bleiben `partially validated`, `unreleased`. Keine Produkt-SQL-,
Manifest-, Grant-, Server-, Trust- oder Labänderung; keine Veröffentlichung/Tags.
