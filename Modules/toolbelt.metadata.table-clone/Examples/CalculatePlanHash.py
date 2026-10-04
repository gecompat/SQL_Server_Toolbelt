"""Clientbeispiel für Executor-Hashversion 1; keine SQL-Verbindung oder Ausführung.

JSON-Datei als Argument: install_db_id, install_db_name, include_identity,
include_extended_properties, map_mode, external_reference_rule, foreign_key_mode,
mapping (MapOrdinal/SourceSchema/SourceTable/TargetSchema/TargetTable),
plan (Ordinal/ObjectKind/TargetName/ScriptText).
Die Originalstrings stammen unverändert aus Calleroptionen/triggerfreier 4.0-Vorschau.
Die Installationsdatenbankidentität stammt aus dem Installationskontext,
auch beim zentralen dreiteiligen Aufruf. Kein Beispiel mit echten Daten
oder Verbindungswerten versionieren. Python ist nur eine Clientoption,
keine Runtime- oder Deploymentdependency des T-SQL-Moduls.
"""
import hashlib
import json
import struct
import sys


def i32(value):
    if type(value) is not int or not 0 <= value <= 2147483647:
        raise ValueError('I32 verlangt einen nichtnegativen SQL-int.')
    return struct.pack('>I', value)


def frame(value):
    if not isinstance(value, str):
        raise ValueError('Hashtext muss ein unveränderter String sein.')
    raw = value.encode('utf-16-le', errors='surrogatepass')
    return i32(len(raw)) + raw


def bit(value):
    if type(value) is not bool:
        raise ValueError('Bitoptionen müssen JSON-Boolean sein.')
    return bytes([value])


def calculate(request):
    """Protokollableitung; ersetzt weder Planner- noch Executorvalidierung."""
    mapping = sorted(request['mapping'], key=lambda row: row['MapOrdinal'])
    plan = sorted(request['plan'], key=lambda row: row['Ordinal'])
    if not 1 <= len(mapping) <= 64 or not plan:
        raise ValueError('Map-/Planumfang ungültig.')
    ordinals = [row['MapOrdinal'] for row in mapping]
    if any(type(x) is not int or x <= 0 for x in ordinals) or len(set(ordinals)) != len(ordinals):
        raise ValueError('MapOrdinals müssen positiv und eindeutig sein.')
    if [row['Ordinal'] for row in plan] != list(range(1, len(plan) + 1)):
        raise ValueError('PlanOrdinals müssen bei 1 beginnen und lückenlos sein.')
    if request['external_reference_rule'] not in ('REJECT', 'KEEP'):
        raise ValueError('ExternalReferenceRule ungültig.')
    if request['foreign_key_mode'] not in ('CREATE', 'DEFER'):
        raise ValueError('ForeignKeyMode ungültig.')
    if not request['map_mode'] and (len(mapping) != 1 or ordinals != [1]):
        raise ValueError('Einzelmodus verlangt die synthetische Mapzeile 1.')
    header = (
        frame('Toolbelt.TableClone.Execute.Hash') + i32(1) + frame('4.0.0')
        + i32(request['install_db_id']) + frame(request['install_db_name'])
        + bit(request['include_identity']) + bit(request['include_extended_properties'])
        + bit(request['map_mode']) + frame(request['external_reference_rule'])
        + frame(request['foreign_key_mode']) + i32(len(mapping))
    )
    for row in mapping:
        header += i32(row['MapOrdinal'])
        for name in ('SourceSchema', 'SourceTable', 'TargetSchema', 'TargetTable'):
            header += frame(row[name])
    current = hashlib.sha256(header).digest()
    for row in plan:
        payload = current + i32(row['Ordinal'])
        for name in ('ObjectKind', 'TargetName', 'ScriptText'):
            payload += frame(row[name])
        current = hashlib.sha256(payload).digest()
    return hashlib.sha256(current + i32(len(plan))
                          + frame('Toolbelt.TableClone.Execute.Final')).digest()


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('Aufruf: python CalculatePlanHash.py <eigene-vorschau.json>')
    with open(sys.argv[1], encoding='utf-8') as stream:
        request = json.load(stream)
    print('0x' + calculate(request).hex().upper())
