# JSON Core/Schema: ergänzte physische Zielnachweise

Am2026-11-06 bestanden acht neue Core-/Schema-Gesamtläufe:16 lokale/direkt
zentrale Installationskontexte,16 Contract- und16 Safety-Fixtures sowie16
direkte Clientmetadatenprüfungen. Acht frische unabhängige Abschlussaudits
und vier Konfigurationsabschlussaudits bestanden. Ergebnis:
**PASS_FOR_DECLARED_SCOPE**. Core1.0.0 und Schema1.0.1 bleiben teilweise
validiert und unveröffentlicht.

## Neue Kombinationen und ausgeführte Methode

| SQL-Ziel | Compatibility Levels | Modi |
| --- | --- | --- |
| Windows2019/CU32 | 150 | lokal und direkt zentral |
| Windows2022/CU26 | 150,160 | jeweils lokal und direkt zentral |
| Linux2022/latest | 150,160 | jeweils lokal und direkt zentral |
| Linux2025/latest | 150,160,170 | jeweils lokal und direkt zentral |

Der Prüfhost war Windows; Linux bezeichnet die SQL-Plattform. Zentral meint
die direkte Verwendung in derselben Installationsdatenbank, keinen eigenen
CrossDB-Consumer. Die vorhandenen physischen Linux2019-/Windows2025-Berichte
wurden nicht wiederholt. Ihre ursprünglichen Quellen und Grenzen bleiben
erhalten; keine nachträgliche Rohbytebeglaubigung oder neue Zwölfer-Gesamtmatrix.

Ausgeführter Snapshot:
[`56cb070e`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/56cb070ea02774820692e7ceb0a0ca771663cb13).
Der bestehende [Labadapter](../../Tests/CI/run-json-schema-lab.ps1) führt
unverändert Contract.Tests.sql, Safety.Tests.sql und Metadata.Tests.ps1 aus.
Die Contractfixture enthält40 feste Fälle. Die Clientprobe verlangt zehn
benannte typgenaue Spalten, genau zwei Invalid-Instance-Zeilen mit festen
JSON-Pointern sowie EOF ohne weiteres Resultset. SQL-/Clientfehler bleiben
Fehler; vorhandener Testtext allein wäre kein PASS.

Je Modus: Core-/Schema-Installation und Repeat, Core-Uninstall-Abweisung bei
vorhandenem Schema, Schema-Uninstall-Abweisung bei eigenem SQL-Consumer,
Entfernung des Consumers, Schema-Uninstall/Absent-Repeat sowie Core-Uninstall/
Repeat. Bei Schema-Uninstall bleiben Core-Assembly-ID und Binaryhash erhalten.
Das sind ausgewählte Lifecyclefälle, keine volle Upgrade-/Owner-/Drift-/Lock-
oder Kollisionsmatrix.

Die reine [Zielauswahl](../../Tests/CI/JsonSchemaQualificationScope.ps1) wird
von Producer und [Dispositionsaudit](../../Tests/CI/Test-JsonSchemaLabDisposition.ps1)
verwendet. Nur `core-schema` erhält zusätzliche Ziele; Constructor- und
Migrationsauswahl bleiben begrenzt. Unsupported-CLs, Patchersatz, abweichende
Groß-/Kleinschreibung und unbekannte Scopes werden abgewiesen. Der Audit
verlangt vor Lab-/SQL-Zugriff den exakten Helperhash im Originaljournal.
Zwei Offlineprüfungen testen720 Kombinationen und den ungebundenen Auditinput
ohne Labimport/SQL im vorhandenen Release-Prüfprogramm.

Die drei vorhandenen DLLs wurden gegen die bekannte Closure geprüft, ohne
neuen Build. Die gemeinsame Offlinepaketierung erzeugt drei Modulpakete;
der Core-/Schema-Lauf benötigt aber nur die beiden Core-/Schema-Trusthashes.
Die Constructor-DLL wird weder installiert noch vorsorglich vertraut.
Produktquellen, Parameter und Resultsets wurden nicht verändert.

## Endlicher Rahmen und sichere Bereinigung

Vor Testbeginn: maximal24 Ziel-/Auditaufrufe,16 eigene Datenbanken und45
Minuten ohne Wiederholung. Darin enthalten sind acht Läufe, acht reservierte
frische Audits und Vorbereitung/Wiederherstellung mit frischem Audit für vier
physische Konfigurationsbereiche. Alle24 Aufrufe und16 Datenbanken sind in der
Originalfrist geschlossen, ohne nativen Fehlversuch. Frühere geschlossene
Wellen und ihre Fehler bleiben unverändert.

Die bestehende CLR-Testkonfigurationsfreigabe wurde nur soweit erforderlich
verwendet. Der bewährte Helper prüft Strict Security, fremde vorgemerkte
Änderungen und CLR-Verbraucher. Vorzustand und eigener Übergang liegen nur
privat vor. Nach Verbraucherabschluss wird nur der eindeutig eigene Zustand
wiederhergestellt; eine neue Verbindung vergleicht sämtliche Einstellungen
und Trust mit dem Vorzustand. Keine Rechtevergabe, Logins, bestehenden
Identitäten, Zertifikate oder Labressourcen wurden verändert.

Vor DROP werden volle DB-ID, Erstellungszeit und Owner-Marker geprüft.
Nur eigene unveränderte Trusttupel ohne verbleibende globale Verbraucher
werden entfernt; bestehender Trust bleibt erhalten. Acht neue Auditprozesse
binden den unveränderten finalen Journalhash, Datenbankabwesenheit, exakte
Trustdisposition und ursprüngliche Vertragsbytes. Private Originals,
Konfigurationswerte und Rohlogs bleiben außerhalb Git.

## Abgleich alter Offen-Einträge und Grenzen

Die pauschal offene Datenpfad-Minimalrechteprüfung ist bereits durch das
[Callerprofil](JSON-SCHEMA-CALLER-PROFILE.md) und die spätere
[Manifest-/Paketbindung](CALLER-METADATA-UPDATE.md) erledigt: zwölf Ziel-/CL-Fälle
lokal/direkt zentral mit den dort genannten drei Objektrechten. Dieser neue
Funktionslauf vergibt keine Rechte und wiederholt keine grünen Callerfälle.
Datierte alte Matrixzeilen bleiben historische Aussagen.

Noch unbelegte Owner-/Drift-/Lock-/Kollisions- und historische Upgradefälle,
andere Sessionprofile, echte Netzwerk-/CrossDB-Identitäten sowie zugesagte
Ressourcen-/Recoveryprofile bleiben getrennt. Functional verwendet notwendige
Verschlüsselung und den expliziten Lab-Trustwert; keine authentifizierte
TLS-Abnahme. Keine vollständige Modul-/Releaseabnahme, Veröffentlichung oder Tags.
