# Datenschutz und Vertraulichkeit

## Zweck

Diese Richtlinie trennt zulässige öffentliche Referenzen von personenbezogenen, sensiblen, internen und laufzeitbezogenen Daten. Öffentliche Namen und Links sind für Research, Attribution, Interoperabilität und technische Dokumentation ausdrücklich nutzbar; Originaldaten und nicht öffentliche Betriebsinformationen bleiben geschützt.

## Stop-Gate vor Repository-Änderungen

Vor jeder Dateiänderung, jedem Commit und jedem Pull Request ist zu prüfen:

- Ist der Inhalt für Projektzweck, Quelle, Attribution, Dokumentation, Test oder Interoperabilität relevant?
- Enthält er personenbezogene, sensible, interne, vertrauliche oder aus einer realen Laufzeit erhobene Daten?
- Lässt sich derselbe Zweck mit synthetischen, redigierten oder aggregierten Angaben erreichen?

Im Zweifel wird vor dem Schreiben gestoppt und der Benutzer gefragt.

## Zulässige Inhalte

Zulässig sind insbesondere:

- fachlich relevante, öffentlich bekannte Organisationsnamen;
- fachlich relevante Namen externer oder öffentlicher Projekte;
- öffentliche Quellen-, Projekt-, Standard- und Dokumentations-URLs;
- `gecompat` und `Gerhard Pisch`;
- synthetische Daten und Beispiele;
- `localhost`, `127.0.0.1`, Contoso, Fabrikam, AdventureWorks und WideWorldImporters;
- öffentliche, statische Produkt- und Plattformdokumentation, sofern keine konkreten Laufzeitwerte übernommen werden.

Die Nennung einer öffentlichen Organisation, eines externen Projekts oder einer öffentlichen URL ist keine Freigabe für darin vorkommende personenbezogene, sensible, interne oder vertrauliche Daten.

## Unzulässige Repository-Inhalte

Nicht versioniert oder in Issues, Pull Requests, Beispielen, Help-Ausgaben oder Test-Evidence übernommen werden:

- personenbezogene oder sensible Daten; reale Personennamen nur bei fachlicher Relevanz, rechtmäßiger Verwendung oder ausdrücklicher Freigabe;
- interne oder vertrauliche Firmen-, Kunden-, Organisations- und Projektdaten;
- nicht öffentliche Host-, Server-, Instanz-, Datenbank-, Domain-, Endpoint-, URL-, Netzwerk- oder Pfadangaben;
- Original-Tabelleninhalte aus realen Umgebungen;
- Produktionsdaten, Backups, Exporte oder unveränderte Ausschnitte daraus;
- reale Logs, Traces, Execution Plans, Fehlerausgaben oder sonstige Runtime-Evidence;
- konkrete Hardware-, Kapazitäts-, Inventar- oder Umgebungswerte von Remote Runnern, beispielsweise CPU-Modell oder -Anzahl, RAM, Datenträgerkapazität, freie Kapazität, Hardwareinventar, Hostnamen, Topologie oder tatsächliche Laufzeitpfade;
- Passwörter, Tokens, API-Keys, private Schlüssel und Connection Strings mit Credentials.

Öffentliche Workflow-Konfigurationen und allgemeine Plattformangaben sind zulässig, sofern sie keine konkreten, aus einem Runner ausgelesenen Hardware-, Kapazitäts-, Inventar- oder Umgebungswerte enthalten.

## Debug und Laufzeit

Vertrauliche Runtime-Werte dürfen bei ausdrücklich aktiviertem Debug diagnostisch in Resultsets oder über `OUTPUT` erscheinen, wenn dies für die Funktion notwendig und im öffentlichen Vertrag dokumentiert ist. Echte Secrets werden auch im Debug nicht aktiv ausgegeben.

Reale Debugausgaben, Originaldaten und Runnerwerte werden nicht als Help, Beispiel, Test-Evidence, Issue-, Pull-Request- oder Repository-Inhalt gespeichert. Für dauerhafte Nachweise werden synthetische oder ausreichend redigierte Daten verwendet.

## Entscheidungsregel

Eine Angabe ist zulässig, wenn sie öffentlich, fachlich relevant und nicht personenbezogen, sensibel, intern, vertraulich oder eine konkrete reale Laufzeitausgabe ist. Bei Mischinhalten wird nur der erforderliche öffentliche Teil übernommen; der Rest wird redigiert oder synthetisch ersetzt.

## Signaturartefakte

Signaturzertifikate, asymmetrische Schlüssel und daraus abgeleitete Artefakte werden nicht als dauerhafte Secrets behandelt, müssen aber trotzdem begründet, dokumentiert und reproduzierbar erzeugt werden. Private Schlüssel aus realen Umgebungen bleiben verboten.
