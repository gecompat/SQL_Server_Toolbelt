"""Komponiert feste öffentliche Funktions-Rechtefixtures; kein SQL-/Labzugriff."""
from pathlib import Path
import argparse
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / 'Tests/Release/Runtime'


def compose(cases: Path) -> tuple[bytes, dict]:
    cases = cases.resolve()
    if cases.parent != RUNTIME.resolve() or not re.fullmatch(r'[A-Z][A-Za-z0-9]+\.FunctionCases\.sql', cases.name):
        raise ValueError('Only canonical function case files are accepted')
    paths = [RUNTIME / 'FunctionCaller.Prelude.sql', cases, RUNTIME / 'FunctionCaller.Assertions.sql']
    data = b'\n'.join(p.read_bytes() for p in paths) + b'\n'
    return data, {'composition_order': [p.relative_to(ROOT).as_posix() for p in paths],
                  'source_sha256': {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
                  'fixture_sha256': hashlib.sha256(data).hexdigest(), 'separator': 'LF', 'final_newline': True}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cases', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if output == ROOT / '.runtime' or not output.is_relative_to((ROOT / '.runtime').resolve()) or output.exists():
        raise ValueError('Fresh private output directory below .runtime required')
    data, manifest = compose(args.cases)
    output.mkdir(parents=True, exist_ok=False)
    (output / 'FunctionRights.sql').write_bytes(data)
    (output / 'composition.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print('PASS composed canonical function rights fixture; no SQL executed')


if __name__ == '__main__':
    main()
