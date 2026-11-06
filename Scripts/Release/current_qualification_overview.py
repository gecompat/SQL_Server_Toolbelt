"""Aktuelle Nachweisumfänge aus kanonischen Records lesen, keine neue Abnahme."""
from pathlib import Path
import importlib.util
import json
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import validate_ssis_fresh_build as fresh
import validate_ssis_current_build as build

PARSER = 'Modules/toolbelt.tsql.script-parser/Tests/Qualification/Current.Build.20261105.json'
PARSER_VALIDATOR = 'Modules/toolbelt.tsql.script-parser/Tests/Static/validate_qualification.py'
PAGE = 'Releases/1.0.0/RELEASE-GATES.md'
HEADING = '## Aktueller Qualifikationsabgleich vom 2026-11-06'
_spec = importlib.util.spec_from_file_location('parser_qualification_record', ROOT / PARSER_VALIDATOR)
_parser_validator = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_parser_validator)


def records():
    """Kanonische Records laden; vor jeder Darstellung ihre bestehenden Prüfer nutzen."""
    ssis = json.loads((ROOT / fresh.REPORT).read_bytes())
    parser = json.loads((ROOT / PARSER).read_bytes())
    return ssis, parser


def render(ssis, parser):
    """Nur die belegten Teilumfänge darstellen, insbesondere keine Authentifizierungsunion."""
    current = build.validate()
    if current['qualified_assembly_sha256'] != ssis.get('qualified_assembly_sha256'):
        raise ValueError('Fresh and current build identities differ')
    fresh.validate(ssis)
    _parser_validator.validate(parser)
    # Keine vollständige native Parserquotenabnahme aus dem kombinierten Vertrag ableiten.
    if (parser.get('result') != 'PASS_FOR_APPROVED_COMBINED_SCOPE'
            or parser.get('publicationAuthorized') is not False
            or parser.get('fullNativeBoundaryCoverage') is not False
            or not parser.get('publicBoundaryCallsNotExecuted')):
        raise ValueError('Parser scope does not permit this overview')
    matrix = ssis['zip_matrix']
    assertions = sum(c['package_assertions'] + c['procedure_assertions']
                     + c['functional_assertions'] for c in matrix['cases'])
    gui = ssis['ssms']
    tls = ssis['authenticated_tls']
    ssis_link = f'../../{fresh.REPORT}'
    parser_link = f'../../{PARSER}'
    return f'''{HEADING}

Diese aktuelle Leseübersicht verwendet die kanonischen Modulrecords und deren
Quell-/Artefaktprüfer. Sie ersetzt weder Originaljournale noch Modulmanifeste.
Die älteren datierten Paketberichte und ihre Ausführungspins bleiben unverändert;
ihre damaligen Wörter „aktuell“ und „offen“ sind keine neue Statusfeststellung.

| Nachweis | Belegter Umfang | Eigenständige verbleibende Grenze |
|---|---|---|
| SSIS: frische ZIP-Ausgabe | {matrix['fresh_contexts']} Windows-/Engine-/CL-/Moduskontexte; {assertions} Assertions; {len(matrix['cases'])} frische Audits; {ssis['current_api_parameters']} API-Parameter. [Record]({ssis_link}) | Nur vereinbarter Debugvertrag; keine vollständige SSIS-Runtime-Parität oder unbegrenzte Produktionskapazität. |
| SSIS: sichtbarer SSMS-Gesamtfall | {gui['authentication']}-Anmeldung; {gui['test_purpose']}; Receiptphase {gui['receipt_phase']}; {gui['result_rows']} Ergebniszeilen; Koordinator {gui['coordinator_result']} und Audit {gui['cleanup_audit']}. [Record]({ssis_link}) | Benutzerhilfe bei Anmeldung und Gridoptionen; keine autonome Anmeldung und kein kombinierter Windows-Anmeldeweg mit authentifiziertem TLS. |
| SSIS: ununterbrochener öffentlicher TLS-Neuaufbau | {tls['authentication']}-Anmeldung; {tls['test_purpose']}; {tls['strict_client_stacks']} strikte Clientstacks; {tls['sql_assertions']} Assertions; SQL- und Lab-Abschlussaudit PASS. [Record]({ssis_link}) | Windows SQL2025 RTM, CL170, lokal/zentral; keine Qualifikation anderer Identitäts-/Zielkombinationen. |
| Parser: freigegebener kombinierter Nachweis | {parser['totalCompletedSuites']} native Suites; {parser['frameworkFinalCases']} Frameworkfälle; datenbanklokale Minimalrechte; {parser['quotaAcceptance']}. [Record]({parser_link}) | Kein neuer Netzwerklogin oder Lowpriv-CrossDB-Mapping; nicht ausgeführte öffentliche Quoten-Branches bleiben nicht ausgeführt. |

Der vollständige OS-/VM-Verlust des SSIS-Koordinators ist nicht qualifiziert.
Die alten SSMS-Fehlläufe bleiben fehlgeschlagen; ein späterer Gesamt-PASS
wertet sie nicht auf. Der Parserrecord erhält seine Liste nicht ausgeführter
öffentlicher Grenzaufrufe. Für andere Module bleiben deren konkret benannte
Pflichtfälle und Freigabegrenzen maßgeblich. Veröffentlichung und Tags sind
nicht autorisiert.

Die [Releaseprüfung](../../Tests/Release/README.md#aktuelle-qualifikationsübersicht)
vergleicht diese Darstellung mit den Records. Sie startet keine SQL-/GUI-/
TLS-Wiederholung und erteilt keine neue Testfreigabe.
'''


def section(text):
    if text.count(HEADING) != 1:
        raise ValueError('Current qualification overview missing or duplicated')
    tail = text.split(HEADING, 1)[1]
    return HEADING + tail.split('\n## ', 1)[0]


def validate(text, ssis, parser):
    if section(text).strip() != render(ssis, parser).strip():
        raise ValueError('Current qualification overview differs from canonical scoped records')


if __name__ == '__main__':
    validate((ROOT / PAGE).read_text(encoding='utf-8'), *records())
    print('CURRENT_QUALIFICATION_OVERVIEW_PASS; no new native qualification')
