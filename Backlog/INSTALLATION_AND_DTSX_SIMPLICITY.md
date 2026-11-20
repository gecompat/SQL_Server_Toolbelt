# Einfachere Assembly-Installation und DTSX-Debug-Erzeugung

Status: Umsetzung am 2026-11-20 durch ausdrücklichen Benutzerauftrag freigegeben.
Die erste kohärente Teilstufe implementiert den SSIS-Komfortaufruf und dessen
markerlosen SQL-Installer; [Vertrag und Anleitung](../Modules/toolbelt.tsql.ssis-debug/Documentation/SimpleInstallation.md).
Die nachfolgenden Anforderungen bleiben als ursprünglicher Anforderungsabgleich
erhalten. Der [gemeinsame create-only-Quellinstaller](../Scripts/Install/README.md) ist ebenfalls implementiert. Seine vier Profile sind offline geprüft; native Paketabnahme und tatsächliche Abschluss-CI werden als getrennte Abnahmegates geführt. Ein früherer Modulnachweis ist keine neue Gesamtqualifikation dieses Installationswegs.
Historische Releaseartefakte werden weder ersetzt noch neu qualifiziert.

Abnahmefortschritt 2026-11-20: Der begrenzte gemeinsame native Paketlauf
bestand Installation/Wiederholung und acht Prüfungen, scheiterte danach an
der Capability-Projektion und wurde vollständig bereinigt; der separate
Abschlussaudit ist PASS. Der separat freigegebene korrigierte Lauf bestand
neun Prüfungen einschließlich 45 Capability-Kandidaten, scheiterte aber vor
der API-Ausführung an der ebenfalls ausgelassenen SSIS-Prozedur; auch sein
frischer Audit ist PASS. Der Builder ergänzt deshalb jetzt alle namensgleichen
kanonischen Objektdateien, einschließlich sieben Safe-Cast-/JSON-Pointer-TVFs
und beider SSIS-Prozeduren. Ausgewählte Module ohne ausführbare Quelle oder CLR
führen zum Buildabbruch. Zwölf Offlineprüfungen und vier neu gebaute, geparste
Profile bestehen; die statische Objektabdeckung wird je Profil geprüft.
Die anschließend separat freigegebene abschließende Welle bestand auf Windows
SQL2025/CU8 CL170 im lokalen Windows-/Hashprofil alle 13 Prüfungen einschließlich
XML-only-Erzeugung, zentralem Startwerteaufruf und tatsächlicher vollständiger
DebugScript-Ausführung mit erwartetem Zwei-Zeilen-Ergebnis. Der separate frische
Windows-Audit ist PASS. Damit ist dieser begrenzte Consumer-Gesamtfall geschlossen;
keine vollständige native Profil-/Trust-/Produktqualifikation daraus ableiten.
[Nachweisabgrenzung](../Scripts/Install/Tests/QUALIFICATION.md).

## Gewünschte Anwendererfahrung

Toolbelt soll mit wenigen Eingaben installierbar und verwendbar sein. Zusätzliche
Toolbelt-Prüfungen und eine besonders restriktive Abnahme dürfen nicht die einzige
Nutzungsmöglichkeit sein. Neben einem strikten Weg werden bewusst einfachere
Wege mit geringeren Toolbelt-eigenen Sicherheitsanforderungen gewünscht.
Erforderliche SQL-Server-Berechtigungen und Enginegrenzen gelten weiterhin;
der einfachere Weg erteilt nicht selbst zusätzliche Rechte.

## Installation und unabhängige Assemblynamen

Alle von Toolbelt registrierten SQL-Assemblies sollen im Namen mit `tlblt`
beginnen, einschließlich mitgelieferter Drittanbieterabhängigkeiten wie
`Microsoft.SqlServer.TransactSql.ScriptDom` oder gegebenenfalls `Newtonsoft.Json`.
Die genaue nachfolgende Schreibweise ist noch kein festgelegter Namensvertrag.

Das fachliche Ziel ist ausdrücklich die **Koexistenz mit anderen, nicht zu
Toolbelt gehörenden CLR-Installationen und deren abweichenden Bibliotheksversionen**
in derselben Datenbank. Fremde Assemblies dürfen weder umbenannt, aktualisiert,
gelöscht noch stillschweigend für Toolbelt übernommen werden. Parallele Versionen
anderer Installationen sollen die von Toolbelt benötigte Version nicht verdrängen.
Mehrere parallele Toolbelt-Versionen sind damit nicht automatisch beauftragt.

Bei der Ausgestaltung SQL-Assemblynamen, interne CLR-Identität, Version,
Strong Name und Referenzauflösung getrennt prüfen. Ein SQL-Namenspräfix allein
beweist noch keine funktionierende Versionsisolation. Unveränderte
Drittanbieterbinaries bevorzugen; eine etwaige Anpassung ihrer Identität wäre
ein gesonderter technischer und lizenzrechtlicher Prüfpunkt. Die Abnahme muss
vorinstallierte fremde Bibliotheken anderer Versionen und ihre unveränderte
weitere Verwendbarkeit einschließen. Ein bestehender Namenskonflikt darf nicht
durch Ersetzen fremder Objekte aufgelöst werden.

## Gewünschte Installationswege

| Vorhandener Zustand der Zieldatenbank | Gewünschter Weg |
|---|---|
| `TRUSTWORTHY ON` | Variante mit Prüfung der erwarteten Assembly-Hashes |
| `TRUSTWORTHY ON` | Variante ohne verpflichtende Toolbelt-Hashprüfung oder Hashregistrierung; vorhandenen Datenbank-Trust nutzen |
| `TRUSTWORTHY OFF` | Bisheriger selektiver Trustweg, insbesondere exakte Hashfreigabe, jedoch ohne Extended Properties |

Prüfung der Binaryintegrität und Eintrag in `sys.trusted_assemblies` sind
verschiedene Schritte. Für die erste ON-Variante muss noch festgelegt werden,
ob ausschließlich der lokale Hashvergleich gemeint ist; eine zusätzliche
Registrierung ist daraus nicht automatisch abzuleiten. Kein stiller Wechsel
zwischen den Wegen nach einem Fehler und keine automatische Aktivierung von
`TRUSTWORTHY` oder Abschaltung von `clr strict security` aus diesem Plan.

Für alle Wege gewünscht:

- Installationsskript für normale SQL-Ausführung **ohne SQLCMD als Standard**;
  Datenbankauswahl möglichst ausschließlich über eine anfängliche `USE`-Zeile.
- Keine Extended Properties: weder Modul-/Versions-/Ownershipmarker noch
  Laufzeitabhängigkeiten davon. Auch eine neue Verwaltungstabelle soll nicht
  ungefragt deren Ersatz werden.
- Keine Deployment-Logtabelle und keine pauschale `sysadmin`-Vorbedingung.
  Vorhandene Rechte zum tatsächlichen `CREATE` nutzen; fehlende Rechte meldet
  die Engine. Komfortprüfungen nur dort vorsehen, wo sie einen konkreten Nutzen
  haben und nicht wieder den einzigen Installationsweg einschränken.
- Fehlende notwendige Objekte erstellen; den vorherigen Wunsch nach
  Existenzabsicherung erhalten. Wiederholung, abweichende vorhandene eigene
  Objekte, Upgrade und Uninstall ohne Ownership-Properties vor einer Umsetzung
  eindeutig regeln. Fremde Objekte und bestehende Installationen erhalten.
- Besonders restriktive Integritäts-/Sicherheitsprüfungen als wählbaren Weg
  anbieten und die Reichweite jedes Wegs verständlich benennen.

Der heutige SSIS-Code liest vier Extended Properties über
`Clr/DependencyPins.Generated.cs`. Ein Weg vollständig ohne diese Eigenschaften
benötigt deshalb auch Änderungen am Runtimevertrag und einen neuen Build;
bloßes Weglassen im Installer genügt nicht. Historische Releaseartefakte und
ihre Nachweise bleiben unverändert. Bestehende Projektregeln bevorzugen den
Hashweg; dieser Zukunftsplan ändert sie nicht stillschweigend.

## DTSX-Debug mit möglichst nur einer Eingabe

Gewünscht ist ein Aufruf mit dem vollständigen DTSX-XML, der Debug-SELECT
beziehungsweise das zusammenhängende DebugScript zurückgibt. Nur wenn der
Paketinhalt nicht ausreicht, sollen Startwerte zusätzlich nötig sein.

- Vorhandene interne Defaultwerte von Variablen und Parametern nutzen.
- Startvariablen/-parameter sowie darauf aufbauende Ausdrücke auflösen;
  einfache zusätzliche Werte wahlweise als JSON beim Aufruf übergeben.
- Alternativ am Anfang des erzeugten SQL einen gut lesbaren Variablenblock
  anbieten, in dem der Anwender noch benötigte Startwerte eintragen kann.
  Welche Werte bereits zur Auflösung der SQL-Struktur benötigt werden und
  welche erst beim späteren Ausführen, muss dabei unterscheidbar bleiben.
- Connection-Manager, deren Expressions und Verweise auf Startwerte auflösen
  und daraus die Datenbankzuordnung automatisch ableiten. Eine manuelle
  Connection-ID-/Katalog-JSON-Zuordnung soll kein Regelfall mehr sein.
- Den möglichen Bedarf an Projektparametern und externen Projektconnections
  verständlich behandeln: nicht im DTSX enthaltene Informationen lassen sich
  nicht aus dem Paket rekonstruieren. Fehlende oder zyklische Werte sowie
  unbekannte Expressions konkret benennen, nicht stillschweigend erfinden.
- Connectionstrings nicht vollständig ausgeben oder protokollieren; aus einer
  Connectionexpression keine automatische externe Verbindung ableiten.
  Erkannte Server-/Datenbankbezüge und gegebenenfalls nötige Umleitungen
  verständlich behandeln; deren genauer Vertrag bleibt offen.
- Analyse und SQL-Erzeugung führen weder das DTSX-Paket noch das erzeugte
  Debug-SQL automatisch aus.

## Systemkatalogzugriff: erforderlich oder optional?

Ein Zugriff auf die Quelldatenbank ist für das reine Lesen von DTSX-XML und
das Auflösen darin vollständig bestimmter Werte grundsätzlich kein notwendiger
Schritt. Gewünscht ist deshalb ein paketbasierter Erzeugungsweg ohne
verpflichtenden Zugriff auf die Systemkataloge jeder referenzierten Datenbank.
Eine optionale Katalogprüfung kann eine höhere Absicherung ergänzen.

Der heutige Adapter `Clr/SqlAdapter.cs` nutzt die Kataloge unter anderem für
Spalten und Typen, berechnete Spalten, SQL-Moduldefinitionen, Synonyme,
Abhängigkeiten, Security Predicates sowie reale Collation-/Codepagebindung.
Das begründet den **aktuellen** Vertrag, aber keine unveränderliche Anforderung
an jeden künftigen Erzeugungsmodus. Der Runtime-Dependencytest im
Installationskatalog ist ein eigener Aspekt und ebenfalls von den zu
entfernenden Extended Properties betroffen.

Ohne Katalog kann aus vorhandenen Paketmetadaten SQL erzeugt werden; tatsächliche
Objektexistenz, reale Typen, aktuelle Views/Synonyme, RLS und exakte
Datenbanksemantik sind dadurch nicht automatisch geprüft. Fehlende Informationen
als begrenzte Aussage kenntlich machen oder für den betroffenen Pfad anfordern.
Eine nicht geprüfte Ausgabe darf nicht als kataloggeprüft beziehungsweise mit
derselben Sicherheitsgarantie wie der strikte Weg ausgegeben werden. Ein
optionaler strikter Modus soll die dafür wirklich nötigen Rechte weiter nutzen
können. Keine Datenbankrechte allein wegen eines simpleren Modus vergeben.

## Noch festzulegende Verträge und Akzeptanz

1. SQL-Namen und technisch nachgewiesene Koexistenz der CLR-Abhängigkeiten.
2. Bedeutung und Auswahl der drei Trustwege einschließlich verständlicher
   Voreinstellung; keine globale Aufweichung anderer Toolbelt-Module ableiten.
3. Deployment-/Runtime-Abhängigkeiten ohne Extended Properties, Migration und
   Wiederholbarkeit ohne fremde Objekte anzutasten.
4. XML-Eingabe, Startwerte-JSON, Default-/Override-Reihenfolge, Datentypen,
   Scope, Expressionumfang und Connectionauflösung.
5. Paketbasierte SQL-Erzeugung gegenüber optionaler Katalogabnahme, notwendige
   Zusatzinformationen sowie Ergebnis-/Diagnosekennzeichnung.
6. Schlanke gekoppelte Anleitung und nur die notwendigen Offline-/Laufzeittests
   je geänderten Vertrag; vorhandene gültige Nachweise wiederverwenden.

Keine der genannten Prüfungen wurde durch das Erfassen dieses Plans ausgeführt.
Es werden keine SQL-/TLS-Läufe, Rechteänderungen, neuen Releases oder Tags gestartet.

## Quellen und Einordnung

- [Persönlicher Benutzerinput](personal_Backlog_Bainstorm.md#einfachere-installation-und-dtsx-debug--2026-11-19)
- [Kanonischer Backlog](../.ai/BACKLOG.md#einfachere-installation-und-dtsx-debug--2026-11-19)
- [Aktueller SSIS-Aufrufvertrag](../Modules/toolbelt.tsql.ssis-debug/Documentation/USP_ExplainSsisDataFlow.md)
- [Heutige Runtime-Dependencyprüfung](../Modules/toolbelt.tsql.ssis-debug/Clr/DependencyPins.Generated.cs)
- [Heutiger SQL-Katalogadapter](../Modules/toolbelt.tsql.ssis-debug/Clr/SqlAdapter.cs)
- [Aktuelles reguläres CLR-Trustmodell](../Documentation/Architecture/CLR_SECURITY_AND_PORTABILITY.md)
- [Microsoft: CREATE ASSEMBLY und Assemblyabhängigkeiten](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-assembly-transact-sql)
