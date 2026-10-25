"""Komponiert die feste EventLog-Callerfixture samt abschließender Zeilenprüfung."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / 'Tests/Release/Runtime'


def compose() -> tuple[bytes, dict]:
    # Den gebundenen gemeinsamen Ablauf erhalten; die eigene Prüfung folgt erst
    # nach REVERT und Entfernung des Testprincipals im gemeinsamen Abschluss.
    spec = importlib.util.spec_from_file_location('event_log_base_composer', ROOT / 'Tests/Release/prepare_function_rights.py')
    base = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(base)
    data, original = base.compose(RUNTIME / 'EventLog.FunctionCases.sql')
    post = RUNTIME / 'EventLog.PostAssertions.sql'
    result = data + post.read_bytes() + b'\n'
    manifest = dict(original)
    manifest['composition_order'] = original['composition_order'] + [post.relative_to(ROOT).as_posix()]
    manifest['source_sha256'] = dict(original['source_sha256'])
    manifest['source_sha256'][post.relative_to(ROOT).as_posix()] = hashlib.sha256(post.read_bytes()).hexdigest()
    manifest['fixture_sha256'] = hashlib.sha256(result).hexdigest()
    return result, manifest


def write_fixture(output: Path) -> None:
    output = output.resolve()
    private_root = (ROOT / '.runtime').resolve()
    if output == private_root or not output.is_relative_to(private_root) or output.exists():
        raise ValueError('Fresh private output directory below .runtime required')
    data, manifest = compose()
    output.mkdir(parents=True, exist_ok=False)
    (output / 'FunctionRights.sql').write_bytes(data)
    (output / 'composition.json').write_bytes((json.dumps(manifest, indent=2) + '\n').encode())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    write_fixture(args.output)
    print('PASS feste vierteilige EventLog-Fixture komponiert; kein SQL ausgeführt')


if __name__ == '__main__':
    main()
