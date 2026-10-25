# Series- und Datumsfunktionen mit getrennten Callerrechten

Stand 2026-10-25, zweite vorab geplante Welle des dritten endlichen Rahmens.
Neun öffentliche TVFs bestehen lokal/direkt zentral auf zwölf Ziel-/CL-
Kombinationen mit jeweils genau einem SELECT. Produkt-SQL, Modulversionen,
Status, Manifeste und Pakete bleiben unverändert; keine Veröffentlichung.

## Profile und feste fachliche Orakel

| Modul | Öffentliche Profile | Ausgewählte feste Ergebnisse |
|---|---|---|
| GenerateSeries1.0.0 | BigInt, Int, BigIntStatus | auf-/absteigende Werte, bigint-Minimum, NULL-Grenzen, unveränderter Nullschrittfehler; Status mit OK/SQL_NULL/INVALID/EMPTY/LIMIT und RequestedRows |
| DateSpine1.0.0 | Day, Month, IsoWeek | vollständige kleine Mengen mit Ordinal/PeriodStart, Schalttag, schneidende Monatsgrenzen, ISO-Jahreswechsel bei DATEFIRST7/3; NULL/leere/umgekehrte Bereiche |
| Truncate1.0.0 | Date, DateTime2, DateTimeOffset | Monat, Millisekunde und Stunde mit erhaltenem Offset; genau eine Zeile, NULL- und ungültige Datepartflags |

Truncate wird als vorhandene Date-Spine-Dependency ohnehin installiert und
ist vor Beginn dieser Welle mit seinen drei offenen Callerprofilen aufgenommen
worden. ResultTable1.0.0 vervollständigt die vierteilige Installationsclosure.
Der interne DateSpineCore und der ResultTable-Helper bleiben bei direktem
Aufruf unzugänglich, ebenso die jeweils acht anderen öffentlichen Profile.

Der eigene Benutzer ohne Login erhält nacheinander genau ein SELECT. Fehlendes,
entzogenes und nicht passendes Objektrecht muss genau SQL229 liefern.
Rollen-, Schema- und datenbankweite Rechte werden nicht verwendet. Abhängige
interne Aufrufe funktionieren über die bestehende Ownershipkette. REFERENCES-
Verwendung, DDL und echte CrossDB-Identitätsmappings sind hier nicht qualifiziert.

Der Legacy-Series-Vertrag erhält Schritt0 als Enginefehler, auch bei NULL-
Start; die begrenzte Status-TVF weist einen nicht-NULL-Nullschritt als INVALID
aus. Vier strikte SQL8134-Kontrollen je Kontext ergeben 96 erwartete Fehler-
prüfungen. Der LIMIT-Test verlangt nur die einzelne Statuszeile für1.000.001
angeforderte Werte; er erzeugt keine Million Zeilen. Dies wiederholt keine
separaten großen Lastqualifikationen.

Die Legacy-Series-APIs bleiben gemäß bestehender Betreiberpolicy für
vertrauenswürdige Principals vorgesehen. Diese synthetischen Einzelgrantprofile
sind keine Freigabe ihrer Verwendung durch beliebige untrusted Caller.

## Matrix, Vorgänger und Bereinigung

Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170
bestehen jeweils lokal/direkt zentral:216 Einzelgrantprofile und2.592 strikte
SQL229-Abweisungen. Falscher Festwert und zusätzliches direktes Core-Recht
werden aus den erwarteten Gründen verworfen; beide bleiben FAILED_CLEANED.

Der erste Fixtureentwurf nahm für Legacy-Schritt0 fälschlich eine leere Menge
an. Zwei ursprüngliche Kontrollen und der daran gescheiterte positive Versuch
bleiben samt unabhängigen Audits im Verbrauch. Der vorhandene README-/Source-/
Contract-Vertrag begründete vor dem Nachfolger die Korrektur auf genaue SQL8134-
Kontrollen. Das ist keine Produktkorrektur und kein abgeschwächtes fachliches
Orakel. Neue Sourcepins, Komposition und Kontrollen binden die aktuelle Matrix.

Frische unabhängige Abschlussaudits nach dem letzten Verbraucher bestätigen
alle26 Datenbanknamen der zwölf positiven Fälle und zwei aktuellen Kontrollen
als abwesend. Die drei alten Versuche behalten ihre ursprünglichen Audits.
Eigene Principals und Fixturezustände sind entfernt. Keine Serverkonfigurations-,
Login-, Assemblytrust- oder fremden Änderungen; private Journale bleiben lokal.

## Bindung und verbleibende Grenzen

Der [gemeinsame Testweg](../../Tests/Release/README.md#native-funktions-callerrechte-prüfen)
komponiert den unveränderten Scope-/Rechteablauf mit der festen
`SeriesDate.FunctionCases.sql`. Die [JSON-Projektion](series-date-caller-qualification.json)
bindet Reihenfolge, gesamte Fixture, tatsächliche Source-/Treiber-/Exportbytes,
Fallzahlen und Grenzen. Die öffentlichen Teile entsprechen vor Ausführung den
kanonischen Git-Bytes; der native T-SQL-Treiber bleibt unverändert begrenzt.

Diese Callerprofile sind keine vollständige API-/Ausgabe-/Client-/Lifecycle-/
Ressourcen- oder Supportabnahme. Frühere volle Funktions- und Lastnachweise
bleiben getrennt und werden nicht wiederholt. Echte Lowpriv-CrossDB-Mappings,
authentifiziertes TLS und übrige [Releasegates](RELEASE-GATES.md) bleiben offen.
Functional nutzt Verschlüsselung und den expliziten Trustwert des schema-validen
Labvertrags ohne Transportfallback. Unveröffentlicht.
