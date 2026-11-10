# JSON Core: fünf direkte Lifecycle-Grenzen

Stand 2026-11-10: **PARTIAL_FOR_DECLARED_FIVE_POINT_MATRIX**.
Zehn vollständige Engine-/CL-Paare bestehen lokal/direkt zentral mit
730 neuen Profilen und zehn frischen unabhängigen Audits. Weitere 28 gültige
Teilprofile aus zwei fehlgeschlagenen, bereinigten Originalen bleiben gebunden.
Damit sind **758 von 876 Profilen belegt; 118 nicht ausgeführt**. Kein
Gesamtabschluss der geplanten zwölf Paare oder des gesamten Core-Moduls.

## Freigabe und fünf konkrete Punkte

Der Benutzer beauftragte am 2026-11-10 die nächsten fünf bereits freigegebenen
Qualifikationspunkte autonom abzuschließen, gültige Evidenz wiederzuverwenden,
nur echte Lücken zu testen und grüne PRs mit tatsächlicher Main-CI zu integrieren.
Ausgewählt wurden fünf bislang nicht durch die Schema-Wrapper oder die
[direkte Core-Sperrmatrix](JSON-CORE-APPLOCK-QUALIFICATION.md) belegte Verträge:

| Punkt | Vertrag je Modus | Belegt / geplant |
|---|---|---|
| 1 | Deploy/Uninstall bei fehlendem Core unter Callertransaktion, alle vier XACT_ABORT-/NOCOUNT-Kombinationen | 176 / 192 |
| 2 | Dieselben frühen Guards bei installiertem bekanntem Core | 168 / 192 |
| 3 | Verwaiste DB-Versions-/Modusmarker ablehnen und unverändert erhalten | 84 / 96 |
| 4 | Sechs Assembly-Markertupel einzeln typverfälschen, Deploy/Uninstall müssen ablehnen und den beschädigten Zustand erhalten | 240 / 288 |
| 5 | Zwei ungültige Deploymentmodi, zwei ungültige Consumer-Bestätigungen und zentrale Bestätigung0 ablehnen | 90 / 108 |

Punkt 4 stellt jedes ursprüngliche eigene `sql_variant`-Markertupel vor dem
nächsten Profil exakt wieder her. Der Beobachtungssnapshot enthält zusätzlich
Assemblyidentität, Owner, Bytes, Berechtigungen und alle relevanten typisierten
Properties mit Basistyp, deklarierter Länge, Datenlänge und Rohbytes. Keine
automatische Adoption oder Reparatur beschädigter Metadaten durch das Produkt.

## Zielmatrix und tatsächlicher Umfang

| Plattform | Engine/Patch | CL | Ergebnis lokal und zentral |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | 8 gültige lokale Teilprofile; 65 Profile nicht ausgeführt |
| Windows | SQL2022/CU26 | 150 | 20 gültige lokale Teilprofile; 53 Profile nicht ausgeführt |
| Windows | SQL2022/CU26 | 160 | vollständige 73 Profile und frischer Audit PASS |
| Windows | SQL2025/CU8 | 150,160,170 | je vollständige 73 Profile und frischer Audit PASS |
| Linux | SQL2019/latest | 150 | vollständige 73 Profile und frischer Audit PASS |
| Linux | SQL2022/latest | 150,160 | je vollständige 73 Profile und frischer Audit PASS |
| Linux | SQL2025/latest | 150,160,170 | je vollständige 73 Profile und frischer Audit PASS |

Der [Treiber](../../Tests/Release/Invoke-JsonCoreBoundariesLab.ps1) verwendet
vollständige kanonische öffentliche Core-Skripte einschließlich ihrer Includes
und fünf kanonisch erzeugter Argumentvarianten. Paket-/Registry-/Projekt-/
Quellbindungen verifizieren die aktuelle bekannte Core-DLL. Kein neuer Build.
Die [Fixture](../../Tests/Release/Runtime/JsonCore.Boundaries.Contract.ps1)
verwendet die tatsächlich qualifizierten Caller-/Savepoint-/Observerorakel
als Funktionen: exakte Fehler, gesunde erhaltene Callertransaktion, Sessionbits,
Zeugenwerte100/200/300, Savepoint- und Vollrollback sowie externe Sitzungs-
und AppLock-Neutralität. Direkte Core-Guards werden nicht aus Schema-Tests abgeleitet.

## Fehlerhistorie und gezielte noch gesperrte Fortsetzung

| Methodencommit | Ergebnis |
|---|---|
| `a4fde940` | SQL2019 erster Kontext FAILED_CLEANED nach acht gültigen Callerprofilen; frischer Audit PASS |
| `0deac84e` | SQL2022/CL150 erster Kontext FAILED_CLEANED nach zwanzig gültigen Caller-/Orphanprofilen; frischer Audit PASS |
| `2f002677` | zehn bislang ungetestete Paare vollständig PASS; zehn frische Audits |
| `623ad681` | gezielte Teilfortsetzung vorbereitet; nur Offlineabnahme, nicht nativ ausgeführt |

Der erste Adapter übergab einen unbegrenzten Unicodeparameter an eine
`sql_variant`-Schnittstelle; er bindet nun zuvor `nvarchar(16)`. Der zweite
verwendete eine nicht vorhandene Assembly-ID-Funktion; er verwendet nun den
geschlossenen Kataloglookup auf `sys.assemblies`. Beide Ursachen haben eigene
quellgebundene Gegenproben. Ein zusätzlicher Fehler im privaten Controller
bei einer einelementigen PowerShell-Liste verbrauchte keinen SQL-Aufruf.
Alle ursprünglichen Fehler und ihre Audits bleiben unverändert erhalten.

Elf [Offlineprüfungen](../../Tests/Release/test_json_core_boundaries_lab_contract.py)
und der kanonische Preflight bestehen. Die Fortsetzung kann ausschließlich die
65 beziehungsweise 53 ungeprüften Profile ausführen. Originaljournal, Audit,
Eingaben, unveränderte Produktquellen und tatsächlich wiederverwendete
Orakelfunktionen sind dabei getrennt gebunden. Gegenproben verhindern,
einen Teilrest als vollen neuen Lauf oder einen ursprünglichen Fehler als
Gesamt-PASS auszugeben. Diese Restläufe haben noch keine Ausführungsfreigabe:
der ursprüngliche, vorab gewählte Plan verbietet einen erneuten betroffenen
Fall bei bereits gültigem Präfix. Die konkrete Ausnahme wurde angefragt.

## Sicherheit und endlicher gemeinsamer Rahmen

Die ursprüngliche Welle nutzt bislang **24 von höchstens28 Ziel-/Auditaufrufen
und DB-Reservierungen** innerhalb ihres gemeinsamen45-Minuten-Fensters.
22 tatsächlich angelegte eigene DBs sind entfernt. Zwölf frische Audits binden
die endgültigen Journale, DB-Absenz, vollständige Konfiguration und Trust.
Eigene notwendige CLR-Konfiguration und exakte bekannte Releasehash-Trusteinträge
sind mit den bestehenden Ownership-/Consumerhelfern wiederhergestellt;
vorbestehende Zustände bleiben erhalten. Keine Rechte, Principals, Ownerwechsel,
Lab-, Host-, Zertifikats-, Truststore- oder serverseitigen Datei-I/O-Änderungen.

Die angefragte gezielte Restwelle bleibt auf insgesamt vier weitere Aufrufe,
vier DBs und45Minuten begrenzt; der kumulative28-Aufrufe-/28-DB-Deckel und
die alten Zeit-/Fehlerhistorien bleiben erhalten. Bis zur ausdrücklichen
Ausnahme ist der Restcontroller gesperrt. Private Originale und Quellkapseln
bleiben außerhalb Git. Keine grünen Profile wiederholt, keine allgemeine
Owner-/ACL-/Consumer-/Ressourcen-/Recovery-/TLS- oder Modulgesamtqualifikation.
Functional übernimmt Verschlüsselung und den expliziten Lab-Trustwert.
Keine Veröffentlichung oder Tags.
