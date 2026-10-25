"""Prüft die zusätzliche Abschlussbindung und schützt bestehende private Evidenz."""
from pathlib import Path
from unittest.mock import patch
import hashlib
import importlib.util
import json
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('event_log_composer_test', ROOT / 'Tests/Release/prepare_event_log_rights.py')
composer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(composer)


class EventLogCompositionTests(unittest.TestCase):
    def test_fixed_postcondition_is_part_of_executed_bytes_and_binding(self):
        data, manifest = composer.compose()
        parts = manifest['composition_order']
        self.assertEqual(parts, ['Tests/Release/Runtime/FunctionCaller.Prelude.sql',
                                'Tests/Release/Runtime/EventLog.FunctionCases.sql',
                                'Tests/Release/Runtime/FunctionCaller.Assertions.sql',
                                'Tests/Release/Runtime/EventLog.PostAssertions.sql'])
        self.assertEqual(data, b'\n'.join((ROOT / p).read_bytes() for p in parts) + b'\n')
        self.assertEqual(hashlib.sha256(data).hexdigest(), manifest['fixture_sha256'])
        for path, digest in manifest['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest)

    def test_existing_private_output_is_preserved(self):
        parent = ROOT / '.runtime' / ('event-log-compose-test-' + uuid.uuid4().hex)
        self.assertEqual(parent.resolve().parent, (ROOT / '.runtime').resolve())
        output = parent / 'composed'
        try:
            composer.write_fixture(output)
            before = {p.name: p.read_bytes() for p in output.iterdir()}
            self.assertEqual(set(before), {'FunctionRights.sql', 'composition.json'})
            with self.assertRaises(ValueError):
                composer.write_fixture(output)
            self.assertEqual(before, {p.name: p.read_bytes() for p in output.iterdir()})
            self.assertEqual(json.loads(before['composition.json'])['fixture_sha256'],
                             hashlib.sha256(before['FunctionRights.sql']).hexdigest())
        finally:
            # Nur die zwei eigenen bekannten Dateien entfernen; bei unbekannten
            # Resten scheitert rmdir statt rekursiv fremde Inhalte zu löschen.
            if output.exists():
                self.assertEqual(output.resolve().parent, parent.resolve())
                for name in ('FunctionRights.sql', 'composition.json'):
                    path = output / name
                    if path.is_file() and not path.is_symlink():
                        path.unlink()
                output.rmdir()
            if parent.exists():
                parent.rmdir()

    def test_public_output_rejected_before_directory_creation(self):
        with patch.object(Path, 'mkdir') as mkdir:
            with self.assertRaises(ValueError):
                composer.write_fixture(ROOT / 'Releases/ContosoOutsidePrivateScope')
            mkdir.assert_not_called()


if __name__ == '__main__':
    unittest.main()
