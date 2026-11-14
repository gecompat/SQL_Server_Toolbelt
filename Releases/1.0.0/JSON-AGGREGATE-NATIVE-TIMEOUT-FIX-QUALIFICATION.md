# Native Aggregate-Grenzen: Timeoutkorrektur und aktuelle Abnahme

Stand 2026-11-14: **PASS_FOUR_NATIVE_BOUNDARIES_ALL_24_CONTEXTS**.
Die vier zuvor [blockierten gültigen Entrygrenzen](JSON-AGGREGATE-STABLE-HOST-REST-QUALIFICATION.md)
bestehen mit den finalen aktuellen Constructorbytes auf zwölf Engine-/CL-Paaren,
jeweils lokal und direkt zentral: **96 eindeutige Native-Profile und zwölf frische
unabhängige Abschlussaudits**. Dies ist der Abschluss dieses Grenzfallscope,
kein pauschaler Modul-, Paket-, Kapazitäts- oder Veröffentlichungsnachweis.

## Ursache und Korrektur

Eine isolierte native Probe auf Windows SQL2025/CU8 zeigte für 512 Eingabezeilen
513 Read- und 513 Write-Aufrufe, sowohl für Klasse als auch Struktur. Der Wechsel
zur Struktur beseitigt damit den gemessenen Transportaufwand nicht. Dies misst
nur diese konkrete Probe; beliebige Callbackfolgen werden nicht garantiert.
Die [offizielle Aggregationsschnittstelle](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-user-defined-aggregates-requirements?view=sql-server-ver17)
lässt Zustandsaufbewahrung und Akkumulation beim Queryprozessor.

Der bisherige allgemeine Transport sortiert, validiert und rekonstruiert den
wachsenden Inhalt wiederholt. Der aktuelle Builder ergänzt eine adaptive
Run-/Bitmapdarstellung für gültige Nullmengen mit positiven eindeutigen
Ordinalen; Objectkeys entsprechen dabei der invarianten Dezimaldarstellung des
Ordinals. Andere Werte und größere Ordinalspannen fallen in den allgemeinen
vollständig prüfenden Pfad zurück. Die Callbackreihenfolge ist unerheblich.

Die codierten Bytefolgen bleiben auch nach Read im Builder komprimiert.
Popcount und Dezimalkosten werden über Run-Deskriptoren gefaltet. Normales Add
teilt nur die betroffene codierte Byteposition; allgemeine Materialisierung und
seltene Untergrenzenverschiebung bleiben begrenzt. Profil- und Count-Gates liegen
vor der Mergeexpansion. Kein gemeinsamer mutable Cache oder externer Zustand.
SHA256 verwendet im kompakten Frame den konkreten Frameworkalgorithmus ohne
Providerauflösung pro Frame; die eigene IL-Prüfung erlaubt genau diesen
zusätzlichen Konstruktor, keine allgemeine neue Frameworkfreigabe.

SQL-Signaturen, öffentliche Parameter, Ergebnisform, Quoten und Fehlerprioritäten
bleiben gleich. Die allgemeinen AGF3-Valid-/Fault-Codecs sind unverändert.
Layout, Grenzen, Digest-/Längen-/Mode-/Popcountprüfungen und Fallback stehen im
[aktuellen Transportvertrag](../../Documentation/Architecture/JSON_CLR_MIGRATION_CONTRACT.md#kompakte-aktuelle-engine-zustände-für-nullmengen).
Die [ursprüngliche gemeinsame Registry](JSON-CLOSURE-BEFORE-NATIVE-RUN-TRANSPORT.json)
bleibt bytegleich erhalten; nur die aktuelle Constructorzeile und ihr Target-
Known-Binding wurden auf die neu qualifizierten Bytes gesetzt. Core-/Schema-
Registryzeilen und Binaries bleiben unverändert.

## Tatsächliche aktuelle Native-Matrix

| Plattform | SQL-/Patchselektor | CL | Modi | Native-Profile |
|---|---|---|---|---:|
| Windows | SQL2019/CU32 | 150 | lokal/zentral | 8 |
| Windows | SQL2022/CU26 | 150, 160 | lokal/zentral | 16 |
| Windows | SQL2025/CU8 | 150, 160, 170 | lokal/zentral | 24 |
| Linux | SQL2019/latest | 150 | lokal/zentral | 8 |
| Linux | SQL2022/latest | 150, 160 | lokal/zentral | 16 |
| Linux | SQL2025/latest | 150, 160, 170 | lokal/zentral | 24 |

Jeder Kontext führt Array/Object mal Profil 1/2 mit 10.001 beziehungsweise
100.001 vollständig gültigen Null-Einträgen aus. Der bestehende skalare öffentliche
Aufruf über die unveränderten Eingabespalten und MAXDOP 1 bleibt erhalten:
keine konstante Ersatzexpression, Sortierannahme, Filterung oder vorzeitige
Abschneidung. Erwartet und geprüft sind SQL6522 mit eindeutigem
`TBX_JSON_AGG_ENTRY_LIMIT`, null Teilzeilen, tatsächliche Eingabeanzahl, unveränderte
Input-/Modul-/Sitzungs-/Transaktions-/AppLock-Snapshots und vollständiger Modus-
abschluss. Alle 96 Profile bestanden innerhalb des unveränderten 180-Sekunden-
Statementlimits; eine Fristüberschreitung wird nicht als Entrylimit anerkannt.

Windows-Kontexte liefen im erfolgreichen Abschluss einzeln. Der frühere
sechsfach parallele Gastlauf verursachte dort erneut Timeouts; seine drei
sauber auditierten Fehlläufe bleiben erhalten. Die bereits mit denselben finalen
DLLs bestandenen sechs Linux-Paare und Windows SQL2025/CL170 wurden wiederverwendet.
Nur die fehlenden beziehungsweise fehlgeschlagenen Windows-Kontexte wurden
abschließend einzeln ausgeführt. Das ist keine allgemeine Hostkapazitätszusage.

## Offlineprüfung und Sicherheitsgrenzen

Der bestehende Source-Frameworkrunner bestand mit den finalen Bytes alle Phasen:
drei Cultures, Constructor-/Number-/Schema-/Bridge-Harnesses, große Constructor-
proben, Coretoken/-budgets und eigene Closure-IL. Der kanonische Projektbuild
liefert für alle drei Assemblies identische Bytes. Der neue
[RunTransportHarness](../../Modules/toolbelt.json.constructors/Tests/Framework/RunTransportHarness.cs)
prüft jeden Transport bis zu beiden Entrymaxima, Maximalspannen mit höchstem
Ordinal zuerst, zufällige Reihenfolgen, Fallbacks, unabhängige Clone-/Mergezustände,
Count-/Profilpriorität und beschädigte, abgeschnittene sowie neu gehashte
ungültige Frames. Der eine zusätzliche Compiler-/Harnessprozess bleibt im
bestehenden Frameworkgate; kein weiterer Workflow oder Reviewagent wurde ergänzt.

Sechs fokussierte Adaptergegenproben und zwei Constructor-Dependency-Gegenproben
bestanden. Ein historisches Paket mit abweichenden Constructorbytes wird nicht als
aktueller Sourcebuild zugelassen. Der optionale frische Sourcekandidat ist auf
den Aggregate-Errors-Scope beschränkt und bindet Frameworkreceipt, FrozenInputs,
eigene IL, aktuelle Quellen und exakt bekannte Binaries. Die paketbasierten Metadata-/Aggregate-Caller- und Dependency-Kontext-
Offlinefixtures prüfen bei diesen alten ZIP-Bytes ausdrücklich die Ablehnung
als aktuelle Constructor-Artefakte. Ihre getrennten Rechte-/Reader-/Orakeltests
bleiben aktiv; daraus wird kein neuer nativer Gesamt- oder ZIP-Nachweis.
Ein unabhängiger lokaler
Verifier prüft Originaljournale, exakte Auditbindungen, Quellkapseln, aktuelle
Build-/Registrybytes, eindeutige 96 Profilkeys und die gemeinsame Zählung.

Alle Tests verwenden den schema-validierten Functional-Labvertrag mit dessen
explizitem Verschlüsselungs-/Trustwert, keine authentifizierte TLS-Abnahme.
Keine neuen Login-/Benutzerrechte, Serverrollen, Labressourcen, Zertifikate,
Truststores, TRUSTWORTHY oder Abschaltung der CLR-Strict-Security.

## Gemeinsamer Rahmen, Historie und Bereinigung

Der konkrete autonome Korrekturauftrag enthielt keine neue numerische
Benutzergrenze. Die internen Planungsrahmen wurden anhand der konkreten Befunde
vor Ausschöpfung beziehungsweise Ablauf innerhalb dieses Auftrags angepasst;
keine geschlossene frühere Benutzerwelle wurde erneuert. Ausgangszeitpunkt,
Verbräuche, Fehler und Ownership blieben erhalten. Das gemeinsame finale Journal
zählt **60 Ziel-/Auditaufrufe und 56 DB-Reservierungen innerhalb 180 Minuten**,
einschließlich zweier lesender Diagnoseaufrufe. Ein erster Adapterfehler vor
Ressourcenanlage, eine abgewiesene Diagnose-Zielzuordnung und eine vor SQL
abgewiesene veraltete Dispatcherannahme bleiben als Fehler erhalten.

Frühere Run-only-, Provider-only- und Bitmap-Zwischenkandidaten qualifizieren
nur ihre ursprünglichen Bytes. Acht native Koordinatoren bleiben
FAILED_CLEANED; sie werden nicht in einen Gesamt-PASS umgeschrieben.
Sieben erfolgreiche Zwischenkandidatenpaare bleiben ebenfalls historisch und
werden nicht zu den 96 aktuellen Profilen addiert. Die ursprüngliche Diagnose-
probe ist keine Produktqualifikation. Ihre eigene Bereinigung ist separat belegt.

Insgesamt wurden 47 tatsächlich angelegte eigene Datenbanken und 55 eigene
Trust-Einträge entfernt; elf eigene Konfigurationsänderungen restauriert.
Alle 28 frischen unabhängigen Audits bestanden in ihrem jeweiligen Scope,
darunter die zwölf aktuellen Zielpaare. Andere Verbraucher und schon vorhandene
Konfigurationen blieben erhalten. Originale, Pläne, Inputpins und Captures liegen
weiterhin ausschließlich privat; keine Infrastrukturwerte oder Runtimeausgaben
werden hier veröffentlicht.

Head-CI und exakte Main-PUSH-CI bleiben separate Integrationsgates. Bestehende
ZIP-/Paketnachweise bleiben unverändert an ihre ursprünglichen Paketbytes
gebunden. Dieser Abschluss erstellt keinen vollständigen neuen ZIP-Matrixnachweis.
Modulstatus bleibt `partially validated`, `unreleased`; keine Veröffentlichung
oder Tags.
