# Abnahme der 19 stabilen Kandidaten

Arbeitspaket vom 2026-10-31: die 19 stabilen Kandidaten gegen ihre aktuellen
Quellen und den freigegebenen Supportzielumfang prüfen, ausführbare offene
Pflichtfälle abarbeiten und verbleibende Blocker benennen. Dies ändert weder
den 45-Modul-Zielumfang noch Modulstatus oder Veröffentlichungsfreigaben.

## Ausgewählte Prüfung

Die aktuelle Integration wird auf Windows und Linux mit SQL Server 2019/CL150,
2022/CL150/160 und 2025/CL150/160/170 geprüft: zwölf ausdrücklich ausgewählte
schema-valide Labkontexte, jeweils local/central und zentraler Consumer.
Vorhandene administrative Rechte werden genutzt; keine Logins, Grants,
Serveroptionen, CLR-, Trust-, Zertifikats- oder Labressourcenänderungen.
Functional verwendet Verschlüsselung und den expliziten Lab-Trustwert.

Ausführung: **noch nicht ausgeführt**. Der Testweg steht in der
[Release-Testanleitung](../../Tests/Release/README.md#aktuelle-19-stabile-kandidaten-abnehmen).
Er verwendet aktuelle, commitgebundene Exporte, die bestehenden fünf
Paketorakel und installierte Help-Orakel statt extrahierter Ersatzprozeduren.
Pro Fall werden drei eigene Datenbanken mit Besitz- und Identitätsprüfung
angelegt und entfernt; ein separater Prozess auditiert Cleanup und Inputpins.

## Vorhandene Nachweise und offene Grenzen

Die [Freigabematrix](FREIGABEMATRIX.md) benennt die 19 Kandidaten. Ihre
kanonischen Manifeste bleiben `validated` und `unreleased`. Die
[V0c-Fach- und Lastabnahme](../../Tests/V0C_RELEASE_GATE_STATUS.md),
[Callerberichte](EVIDENCE-MAP.md) und die
[Help-Qualifikation](../../Tests/Release/ParameterHelp.md) behalten jeweils
ihren ursprünglichen Scope und Ausführungszeitpunkt. Die Anwendbarkeit an
aktuellen Quellen und die noch fehlenden Modul-/Client-/Identitätsnachweise
werden im Abschluss dieses Arbeitspakets konkretisiert. Unbekannte Abdeckung
ist kein PASS; optionale Zeitmessungen bleiben gemäß DEC-2026-036 optional.

Rahmen: ein Arbeitspaket/ein PR, ein Implementierer, zwölf native Fälle mit
je einem separaten Audit; 300 Sekunden Arbeit, 360 Sekunden einschließlich
Cleanup und 400 Sekunden äußerer Watchdog je Prozess, höchstens 4800 Sekunden
für die Matrix. Kein automatischer Retry oder Start einer nächsten Welle.
Rohlogs und Restorejournale bleiben privat; Kosten und Tokenverbrauch unbekannt.
