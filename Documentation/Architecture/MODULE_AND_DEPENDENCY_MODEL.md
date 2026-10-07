# Modul- und Abhängigkeitsmodell

## Moduldefinition

Ein Modul ist eine eigenständige Lifecycle-, Deployment- und Dokumentationseinheit. Es kann eine einzelne zentrale Funktion oder mehrere fachlich zusammengehörige Objekte enthalten.

Eine besonders grundlegende Capability darf selbst ein Modul bilden und von anderen Modulen verwendet werden.

## Mindestbestandteile

Jedes Modul enthält mindestens:

- `module.yaml` als Manifest;
- ein parametergesteuertes Deploy- und ein Uninstall-Skript;
- kanonische Source-Artefakte;
- eigene Dokumentation für jedes öffentliche SQL-Objekt;
- Dokumentation interner Hilfsobjekte;
- synthetische Beispiele;
- statische und Runtime-Testartefakte;
- Primärquellen und bekannte Einschränkungen.

## Abhängigkeiten

- Abhängigkeiten deklarieren Modul-ID, Mindestversion und Installationsort.
- Der vollständige Preflight erfolgt vor der ersten Mutation.
- Fehlende oder ungeeignete Abhängigkeit führt zu klarer Meldung und vollständigem Abbruch.
- Fehlende Module werden nicht automatisch nachinstalliert.
- Zyklen sind unzulässig.
- Eine Dependency wird nicht durch kopierte Objekte ersetzt.

## Kanonische Implementierung

Wiederverwendete Fachlogik existiert genau einmal. Öffentliche Wrapper, alternative Provider, Synonyme und Ausgabeformen verwenden diesen kanonischen Kern. Eine zweite Fachimplementierung ist nur zulässig, wenn sie als eigener Provider denselben öffentlichen Vertrag erfüllt und technisch begründet ist.

## Schemas

Öffentliche Objekte verwenden `toolbelt_<category>`. Ein Modul kann mehrere Schemas verwenden, wenn dies fachlich erforderlich und im Manifest dokumentiert ist.

## Manifestfelder

Mindestens:

- Modul-ID, Name und Version;
- getrennte Implementierungs-, Validierungs- und Release-Statuswerte;
- unterstützte SQL-Server-Versionen und Compatibility Levels;
- Windows-/Linux- und Provider-Matrix;
- Deployment-Modi und Capability-Kennzeichnungen;
- verwendete Schemas und öffentliche/interne Objekte;
- Dependencies mit Ort und Mindestversion;
- Berechtigungen;
- Collation- und Datentypvertrag;
- Resultset- und Help-Verträge;
- CLR-`PERMISSION_SET` und Trust-Anforderungen, falls relevant;
- Lifecycle-Artefakte;
- versionierte Release-Objektmanifeste und tatsächlicher Installationsstand;
- Tests und tatsächlicher Validierungsstatus.

## Getrennte Statusdimensionen

Ein Modul verwendet niemals einen Sammelstatus. Das Manifest ist die
autoritative Quelle für drei voneinander unabhängige Dimensionen.

### Implementierungsstatus

| Wert | Bedeutung |
|---|---|
| `proposed` | Modulgerüst oder Vorschlag ohne vollständigen Code |
| `researched` | fachlich recherchiert, noch nicht implementiert |
| `planned` | funktionsbezogen freigegeben und zur Implementierung geplant |
| `implemented` | Code, statische Verträge und gekoppelte Artefakte vorhanden |
| `deprecated` | Implementierung ist zur Ablösung vorgesehen |
| `unsupported` | Implementierung wird bewusst nicht unterstützt |

### Validierungsstatus

| Wert | Bedeutung |
|---|---|
| `validated` | deklarierter Pflichtscope tatsächlich vollständig erfolgreich |
| `partially validated` | dokumentierter Teil des Pflichtscopes erfolgreich; Rest offen |
| `not executed` | vorgesehene Prüfung nicht ausgeführt |
| `not applicable` | im konkreten Scope fachlich nicht anwendbar und begründet |
| `failed` | Prüfung ausgeführt und fehlgeschlagen |

### Release-Status

| Wert | Bedeutung |
|---|---|
| `unreleased` | noch keine veröffentlichte Version |
| `preview` | ausdrücklich als Vorabversion veröffentlicht |
| `released` | veröffentlichte unterstützte Version |
| `deprecated` | veröffentlichte Version ist zur Ablösung vorgesehen |
| `withdrawn` | Version wurde zurückgezogen |

Backlog-, Kandidaten- und Roadmapstatus beschreiben Arbeitsfluss und Planung;
sie ersetzen keine dieser Modulstatusdimensionen.

## Öffentlicher Veröffentlichungsnachweis

Build/Packaging erzeugt Installationsinputs; ein CI-Artefakt transportiert
Prüfinputs. Beides ist noch keine öffentliche Veröffentlichung. `preview`
und `released` setzen eine ausdrücklich autorisierte öffentliche
Modulveröffentlichung voraus. Ein Tag oder Changelog-Eintrag allein belegt
weder diese Freigabe noch ausreichende Qualifikation.

Versionierte Lifecycle-Release-Manifeste beschreiben außerdem den installierten
Objektbestand; auch sie sind für sich kein öffentlicher Veröffentlichungsnachweis.

Eine Veröffentlichung gilt ausschließlich für die benannte Modulversion,
ihren Quellcommit und den ausdrücklich qualifizierten Supportumfang. Sie
veröffentlicht keine anderen Module und erweitert keine Dependency-,
Plattform-, Provider- oder Deployment-Zusage. Vor Veröffentlichung prüft ein
fachlicher Review die vollständigen Pflichtprüfungen für jede veröffentlichte
Kombination einschließlich relevanter Compatibility Levels, öffentlicher
Verträge, Security, Lifecycle, Dependencies und gegebenenfalls Consumerpfade.
Alle dafür erforderlichen Prüfungen müssen tatsächlich erfolgreich sein;
`preview` ist kein Ersatz für fehlende Pflichtqualifikation im zugesagten Scope.

Ein engerer veröffentlichter Umfang darf vom größeren Entwicklungsziel im
Manifest abweichen. Offene Prüfungen außerhalb dieses Umfangs bleiben sichtbar;
der bestehende `validation_status` wird dadurch nicht automatisch aufgewertet.
Bekannte Grenzen, Breaking Changes, Migrationspfad und die ausdrückliche
Benutzerfreigabe für die konkrete Veröffentlichung müssen nachvollziehbar sein.

### Manifestreferenz und JSON-Vertrag v1

Bei `preview`, `released`, `deprecated` und `withdrawn` verweist das optionale
Top-Level-Feld `publication_record` in `module.yaml` auf eine JSON-Datei innerhalb
des Moduls. Bei `unreleased` fehlt dieses Feld; Build-/Trust-Manifeste bleiben
separate Artefakte. Für abgelöste oder zurückgezogene Veröffentlichungen wird
der historische Nachweis erhalten, mit dem ursprünglichen Kanal.

Der geschlossene JSON-Vertrag ist im bestehenden
[Validator](../../Tests/Documentation/publication.py) implementiert:

| Feld | Vertrag |
|---|---|
| `schema_version` | `1.0` |
| `module_id`, `module_version` | Exakte aktuelle Manifestwerte |
| `source_commit` | Vollständiger 40-stelliger Git-Commit; lokal verfügbar, mit passender Modulidentität/Version im historischen Manifest |
| `publication` | Objekt mit `url`, `tag`, `published_at`, `channel`, `approval_reference` |
| `support_scope` | Nicht leere Liste expliziter Kombinationen; jede enthält `sql_server_version`, `platform`, `provider`, `deployment_mode`, `qualification` |
| `limitations` | Explizite Liste bekannter Einschränkungen; leer nur nach fachlicher Prüfung |
| `pending_outside_scope` | Explizite Liste offener Prüfungen außerhalb des veröffentlichten Umfangs |
| `artifacts` | Liste aller zusätzlich hochgeladenen Releaseassets, jeweils `name` und vollständiger SHA-256 in Kleinschreibung; bei reiner Sourceveröffentlichung gegebenenfalls leer |

`publication.url` ist der öffentliche GitHub-Release-Link dieses Projekts für
den exakten `tag` (Buchstaben/Ziffern sowie Punkt, Bindestrich und Unterstrich;
keine Pfadsegmente). `published_at` ist die tatsächliche UTC-Veröffentlichungszeit
im Format `YYYY-MM-DDTHH:MM:SSZ`. `channel` ist `preview` oder `released` und
entspricht bei aktiven Veröffentlichungen dem Modulstatus. Eine Änderung von
Kanal, Tagziel oder Assets verlangt eine erneute Abnahme und nachvollziehbare
Pflege des Nachweises; Hashes werden nicht stillschweigend passend gemacht.

`approval_reference` nennt eine repository-relative Datei mit optionalem
Headinganker oder eine öffentliche PR-/Issue-Fundstelle dieses Projekts. Sie
muss die konkrete ausdrückliche Benutzerfreigabe auffindbar machen. Die
Datei-/Ankerprüfung attestiert weder Urheber noch Bedeutung einer Freigabe.

Jede Supportkombination muss im aktuellen und im eingefrorenen Manifest
deklariert sein: SQL-Version, `Windows`/`Linux`, Provider-ID sowie `local`/`central`.
Ihre `qualification` ist eine nicht leere Liste von Objekten mit `reference`,
`method`, `executed_on` (`YYYY-MM-DD`) und `result` (`success`). Die Fundstelle
beschreibt den vollständigen erforderlichen Prüfscope einschließlich relevanter
Compatibility Levels, Ergebnis, Datum und Einschränkungen; das Datum liegt
nicht nach der Veröffentlichung. Erfolgreiche Teilprüfungen dürfen keine
fehlenden Pflichtprüfungen derselben zugesagten Kombination verdecken.

Die Artefaktliste deckt alle hochgeladenen Assets ab, einschließlich mitgelieferter
Trust-Manifeste und SQL-Pakete. CLR-Veröffentlichungen enthalten die benötigten
Binärinputs. Bestehende SHA2-512-/Trust-Verträge bleiben zusätzlich verbindlich;
der Veröffentlichungshash erteilt keine CLR-Trustfreigabe. Die von GitHub
automatisch erzeugten Sourcearchive gehören nicht zu den hochgeladenen Assets;
ihre Quellidentität wird über den aufgelösten Tagcommit angegeben.

### Strukturprüfung und externe Bestätigung

Der Dokumentationsvalidator prüft die Struktur, Manifestzuordnung, lokale
Commitreferenz, Fundstellen und Hashformate ohne Netzwerk. Seine erfolgreiche
lokale Prüfung bestätigt keine öffentliche Veröffentlichung und keine
tatsächliche Testausführung. Er meldet die externe Prüfung separat als
`not executed`, beziehungsweise `not applicable`, wenn keine Datensätze bestehen.

Bei aktivem `preview`/`released` müssen die versionierten Runtime-/Packaginginputs
in `Source`, `Clr`, `Deployment` und `Scripts` dem Quellcommit entsprechen;
neue nicht ignorierte Inputs werden ebenfalls erkannt. Änderungen daran
erfordern einen neuen Entwicklungstand ohne unbelegte Publikationszusage.
Reine Dokumentations-/Nachweispflege bleibt möglich. Historische Datensätze
abgelöster oder zurückgezogener Versionen erfordern keine identische aktuelle
Runtimequelle. Ignorierte Buildoutputs sind kein Beleg für Binaryidentität;
hierfür gelten die separat geprüften Asset- und Trust-Hashes.

Vor Abnahme eines Veröffentlichungsstatus ist zusätzlich der ausdrücklich
gewählte lesende Modus erforderlich:

```text
python Tests/Documentation/validate_documentation.py --all --verify-publications
```

Der Modus verwendet den vorhandenen `gh`-Client mit GET gegen `github.com`.
Gemäß der [GitHub-Releases-API](https://docs.github.com/en/rest/releases/releases#get-a-release-by-tag-name)
werden öffentlicher Release-Link, Kanal, tatsächlicher Veröffentlichungszeitpunkt,
Nicht-Draft-Zustand und vollständige Assetzuordnung geprüft. Die
[Git-Referenz](https://docs.github.com/en/rest/git/refs#get-a-reference) und
gegebenenfalls [annotierte Tags](https://docs.github.com/en/rest/git/tags#get-a-tag)
werden bis zum konkreten Commit aufgelöst; `target_commitish` ist keine
ausreichende Commitbindung. GitHub-Assetdigests müssen zu den angegebenen
SHA-256-Werten passen. Es werden keine Binaries heruntergeladen oder ausgeführt.

Widersprüche und fehlende Releases/Tags sind `PUBLICATION_FAILED`. Nicht
prüfbare API-Antworten, Timeout, fehlender CLI-Zugang oder fehlende Assetdigests
sind `PUBLICATION_UNAVAILABLE`. Beide beenden die externe Abnahme mit Fehler;
eine erfolgreiche Strukturprüfung ersetzt sie nicht. Auch ein entfernter
Release eines `withdrawn`-Moduls erhält keine aktuelle Bestätigung: der
historische Datensatz bleibt erhalten, die aktuelle Nichterreichbarkeit sichtbar.
Es erfolgen keine automatische Veröffentlichung, Tags, Statusänderungen,
Downloads, Credentialausgaben oder Aufbewahrung kompletter API-Antworten.
