# Work Type mit begrenzten Callerrechten verwenden

Stand 2026-10-25. Die sechs öffentlichen APIs von `toolbelt.core.work-type`
1.2.0 sind mit getrennten Objektrechten lokal und direkt in einer zentralen
Moduldatenbank geprüft. Produktquellen, Modulstatus und bestehende Paketbytes
bleiben unverändert. Dies ist eine zusätzliche Rechtequalifikation.

| API | Geprüfter Mindestrechtesatz |
|---|---|
| `USP_RegisterWorkType` | EXECUTE auf die Procedure und den registrierten Handler |
| `USP_DisableWorkType` | EXECUTE auf die Procedure |
| `USP_RemoveWorkType` | EXECUTE auf die Procedure; fachlich zusätzlich deaktivierter Eintrag und AllowDelete |
| `USP_ResolveWorkType` | EXECUTE auf die Procedure und bei unverändertem Default auf den Handler |
| `VW_WorkTypes` | SELECT auf die View |
| `USP_SetWorkTypePermission` | EXECUTE auf die Procedure und CONTROL auf WorkTypePermission |

Die Registrierung benötigt weiterhin sichtbare Handlermetadaten. Der Test
zeigt mit VIEW DEFINITION ohne Handler-EXECUTE ausdrücklich die Abweisung
51509. Der Resolver weist diese Kombination mit 51534 ab; reine Policy-
Verwaltungs-EXECUTE ohne Tabellen-CONTROL ergibt 51591. Diese Voraussetzungen
werden nicht durch breite Rollen- oder Schemagrants ersetzt. Die Policy-
Verwaltung ist wegen ihres CONTROL-Vertrags eine administrative Oberfläche.

## Ausführung und Ergebnis

Der [Rechteharness](../../Tests/Release/README.md#work-type-mit-getrennten-handler--und-policyrechten-prüfen)
installiert ausschließlich ResultTable und Work Type über die vorhandenen
verbindungslosen SQL-Exports. Jede Datenbank erhält eine eindeutige eigene
Identität und einen Owner-Marker. Die SQL-Fixture verwendet einen Benutzer
ohne Login und einen synthetischen Handler; vorhandene Fixtureobjekte oder
unpassende Datenbankmarker werden abgewiesen.

Zwölf physische Ziel-/CL-Kombinationen bestanden: Windows und Linux mit
SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170. Jeder Fall prüft
lokales und direkt zentrales Deployment, insgesamt **144 positive API-Profile
und 1.368 strikte Abweisungen**. Davon sind 1.296 SQL229-Abweisungen für
fehlende, entzogene oder fremde API-/Tabellenrechte; je 24 Fälle belegen die
drei zusätzlichen Handler-/Policyfehler. Direkter SELECT und UPDATE auf den
internen WorkType-Katalog bleiben auch während der positiven Profile gesperrt.
Feste Namen, Handlerzuordnung, Timeout, Enabled-Zustand und Rückgabezeilen
werden unabhängig vorgegeben. Modulobjekte und Definitionen bleiben erhalten.

Zwei absichtlich veränderte Fixturevarianten wurden verworfen: ein falscher
erwarteter Timeout und ein zusätzliches fremdes API-Recht. Beide bleiben
`FAILED_CLEANED`. Der erste tatsächliche Fixturelauf scheiterte an nicht
explizit nullable deklarierten Erfassungsspalten unter geerbtem ANSI-Default.
Auch dieser Versuch bleibt `FAILED_CLEANED`; seine Originalbytes sind lokal
erhalten. Die finale Fixture deklariert NULL ausdrücklich und behält alle
Wert-, Rechte- und Probenzahlorakel.

Alle 15 Versuche haben eigene unabhängige Input-/Bereinigungsaudits. Nach dem
letzten Verbraucher bestanden weitere frische Audits; alle 27 eigenen
Datenbanknamen waren abwesend. CLR, Assemblytrust, Serverkonfiguration,
Server-Logins und fremde Ressourcen wurden nicht verändert. Tatsächliche
Labidentitäten, Verbindungshinweise und Rohlogs bleiben lokal.

## Quellenbindung und Grenzen

Die [JSON-Projektion](work-type-rights-qualification.json) bindet Produktquellen,
Fixture, Exporter, begrenzten Harness und Labhelfer sowie die tatsächlich
verwendeten Exportbytes. Die neue Release-Regressionsprüfung erhält diese
Bindungen und die genaue Ziel-/CL-/Profilzuordnung. Keine neue CI-Labmatrix
und kein unveränderter vollständiger Modul- oder Paket-Lifecyclelauf.

Functional verwendet erforderliche Verschlüsselung und den expliziten Trustwert
des schema-validierten Labvertrags. Authentifizierte TLS-Abnahme bleibt separat.
Benutzer ohne Login im direkt geöffneten zentralen Kontext belegen kein echtes
CrossDB-Loginmapping. Weitere Policy-/Rollen-/Konkurrenz-/Lifecyclefälle,
Ressourcen-/Recovery-/Clientgates und die übrigen [Releasegates](RELEASE-GATES.md)
bleiben offen. Veröffentlichung benötigt weiterhin einen eigenen Auftrag.
