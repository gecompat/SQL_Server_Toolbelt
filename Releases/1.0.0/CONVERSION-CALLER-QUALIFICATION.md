# Konvertierungsfunktionen mit getrennten Callerrechten

Die damals offene Manifest-/Paketlücke ist durch die spätere
[exakte Metadatenkorrektur](CALLER-METADATA-UPDATE.md) geschlossen.
Der folgende Ausführungsbericht behält seine ursprünglichen Quellen und Grenzen.

Stand 2026-10-25, erste vorab geplante Welle des dritten endlichen Release-Rahmens.
Alle 16 öffentlichen Base64-, Integer-Base- und URI-Funktionen bestehen mit
getrennten Objektgrants auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral.
Produkt-SQL, Modulstatus und Pakete bleiben unverändert, Veröffentlichung offen.

## Rollen, Grenzen und feste Orakel

Die [komponierte Fixture](../../Tests/Release/README.md#native-funktions-callerrechte-prüfen)
verwendet einen gemeinsamen eigenen Scopeguard und Rechteablauf sowie die feste
`Conversion.FunctionCases.sql`. Sie installiert ausschließlich ResultTable1.0.0,
GenerateSeries1.0.0, Base641.1.0, IntegerBase1.1.0 und UriComponent1.0.0.
Der eigene Benutzer ohne Login erhält nacheinander genau ein benötigtes Recht.

| Familie | TVFs mit SELECT | Scalarwrapper mit EXECUTE |
|---|---|---|
| Base64 | Encode/Decode sowie EncodeStatus/DecodeStatus | Encode/Decode |
| Integer Base | IntegerToBase/TryBaseToInteger | IntegerToBase/TryBaseToInteger |
| URI Component | Encode/Decode sowie EncodeStatus/DecodeStatus | Encode/Decode |

Jeweils fehlendes und entzogenes Recht muss exakt SQL229 liefern. Während eines
positiven Profils bleiben die 15 anderen öffentlichen Funktionen sowie beide
Generate-Series-Dependencies und der ResultTable-Helper bei direktem Aufruf
unzugänglich. Interne Aufrufe über die bestehende Ownershipkette benötigen
keine direkten Zusatzgrants. Rollen-, Schema- und datenbankweite SELECT-/
EXECUTE-/CONTROL-Rechte entfallen; die üblichen breiten Datenbankrollen werden
abgewiesen. DDL, REFERENCES-Verwendung, gebrochene Ownershipketten und echte
CrossDB-Identitätsmappings sind hier nicht qualifiziert.

Die Wertorakel prüfen binär und längengenau Base64werte und NULL, den kleinsten
bigint, Plus als reguläre Alphabetziffer und Overflow sowie URI-Prozent-/UTF8-
Werte. Status-TVFs prüfen zusätzlich die ausgewählten OK-/SQL_NULL-/INVALID-
Fälle. Kardinalität ist ausdrücklich Teil der TVF-Orakel. Vollständige
Grenz-, Last-, Ausgabe-/Client- und Lifecycleverträge behalten ihre bisherigen
Nachweise; diese kleine Rechtefixture ersetzt sie nicht.

Die Unterscheidung zwischen Scalar-EXECUTE und TVF-SELECT folgt den
[SQL-Server-Objektrechten](https://learn.microsoft.com/en-us/sql/t-sql/statements/grant-object-permissions-transact-sql?view=sql-server-ver17)
und wird hier tatsächlich unter eigenen Principals geprüft. Die älteren
pauschalen `permissions_required`-Labels der drei Modulmanifeste sind für
Scalarwrapper veraltet. Diese Welle verändert die an den eingefrorenen
Quellpaketstand gebundenen Manifeste nicht. Der getrennte Metadaten-/Paket-
Refresh bleibt im [Releasebacklog](../../.ai/BACKLOG.md) offen; er ist keine neue
Funktionsfreigabe. Die hier nativ belegten konkreten Callerprofile sind explizit.

## Matrix, Kontrollen und Bereinigung

Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170
bestanden jeweils lokal und direkt zentral: 384 positive Einzelgrantprofile
und 7.680 strikte SQL229-Abweisungen. Ein absichtlich falscher Festwert und
zusätzliches direktes GenerateSeries-Recht wurden jeweils aus dem erwarteten
Grund verworfen; beide bleiben FAILED_CLEANED.

Drei erste Versuche hatten einen CRLF-Falldateistand statt der kanonischen
Git-LF-Bytes: zwei verworfene Kontrollen und ein positiver Fall. Ihre damaligen
unabhängigen Cleanup-/Pinaudits bleiben erhalten; sie werden nicht als neue
LF-Qualifikation ausgegeben. Die verbindliche Fixture wurde neu bytegetreu
komponiert und erhält eigene aktuelle Kontrollen und die vollständige Matrix.

Ein weiterer Versuch scheiterte vor den Funktionsorakeln bei der ResultTable-
Installation an einem vorhandenen benannten Temp-Constraint. Erst eine reine
Leseprüfung seiner Abwesenheit begründete einen frischen eigenen Nachfolger,
der bestand. Fremde Zustände oder Sessions wurden nicht verändert. Insgesamt
bleiben 18 native Versuche dieser Welle im gemeinsamen endlichen Verbrauch.

Frische unabhängige Audits nach dem letzten Verbraucher bestätigen die Inputpins
und alle 27 Datenbanknamen der aktuellen Ausführungen als abwesend: 26 gehören
zu zwölf positiven Fällen und zwei Kontrollen, einer zum Installationsfehler.
Die ursprünglichen drei Versuche behalten ihre ursprünglichen Audits.
Keine Serverkonfigurations- oder Assemblytruständerungen; eigene Principals
und Testdaten sind entfernt. Private Journale und Verbindungsdaten bleiben lokal.

## Reproduzierbare Bindung und offene Gates

Die [JSON-Projektion](conversion-caller-qualification.json) bindet alle tatsächlichen
Fallzahlen, Modulversionen, konsumierten Source-/Treiber-/Exportbytes und die
Komposition `b'\n'.join(parts) + b'\n'`. Öffentliche Fixtureteile entsprechen
bereits vor dem Lauf den gespeicherten Git-Bytes. Der bestehende begrenzte
T-SQL-Treiber und seine Arbeits-/Cleanup-/Auditgrenzen bleiben unverändert.

Dies sind direkte SQL-Callerprofile und keine pauschale API-, Modul-, Client-
oder Supportabnahme. Echte Lowpriv-CrossDB-Mappings, authentifiziertes TLS,
volle Ressourcen-/Lifecycleverträge und der Metadaten-/Paketrefresh bleiben
getrennt. Functional nutzt Verschlüsselung und den ausdrücklich booleschen
Trustwert des schema-validierten Labvertrags; kein Transportfallback.
Die [Releasegates](RELEASE-GATES.md) und der unveröffentlichte Status gelten.
