"""Current installer integrity and independent-evidence negative controls; no SQL."""
import contextlib
import copy
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import new_ssis_current_package as composer
import new_ssis_current_standalone_tsql as installer
import validate_ssis_current_package as guard


class CurrentDelivery(unittest.TestCase):
    archive = ROOT / composer.MODULE / 'InstallPackages' / (composer.NAME + '.zip')

    def test_current_package_and_installer_have_actual_runtime_bindings(self):
        with contextlib.redirect_stdout(io.StringIO()):
            record = installer.validate_runtime()
        self.assertEqual(record['scope']['installed_mode_contexts'], 4)

    def test_current_package_carries_current_api_and_installation_route(self):
        with zipfile.ZipFile(self.archive) as archive:
            payload = {name[len(composer.NAME) + 1:]: archive.read(name) for name in archive.namelist()}
        api = json.loads(payload[composer.MODULE + 'Contracts/Api.json'])
        limits = [p for p in api['parameters'] if p['name'].startswith('@Max')]
        self.assertEqual(len(limits), 24)
        self.assertTrue(all(p['type'] == 'bigint' for p in limits))
        self.assertEqual([p['name'] for p in api['parameters'][-4:]],
                         ['@ResultTable', '@KeepData', '@Debug', '@Hilfe'])
        self.assertIn(b'CurrentInstallation.md', payload['START-HERE.txt'])
        self.assertIn(composer.MODULE + 'Documentation/CurrentInstallation.md', payload)

    def test_wrong_runtime_target_or_command_bytes_is_rejected(self):
        original = installer.renderer.read_regular_bounded
        record = json.loads((ROOT / installer.RUNTIME).read_bytes())
        for mutation, reason in (
            (lambda r: r['scope']['targets'][0].update(platform='linux'), 'runtime targets'),
            (lambda r: r['execution']['mode_bindings']['central'].update(command_sha256='0' * 64), 'central command bytes'),
        ):
            changed = copy.deepcopy(record)
            mutation(changed)
            def read(path, maximum):
                return composer.encoded(changed) if path == ROOT / installer.RUNTIME else original(path, maximum)
            with self.subTest(reason=reason), mock.patch.object(installer.renderer, 'read_regular_bounded', side_effect=read):
                with self.assertRaisesRegex(ValueError, reason):
                    installer.validate_runtime()

    def test_missing_audit_or_wrong_qualification_hash_is_rejected(self):
        raw = (ROOT / installer.QUALIFICATION).read_bytes()
        record = json.loads(raw)
        package_sha = composer.sha(self.archive.read_bytes())
        installer.validate_package_qualification(raw, composer.sha(raw), package_sha)
        with self.assertRaisesRegex(ValueError, 'qualification'):
            installer.validate_package_qualification(raw, '0' * 64, package_sha)
        changed = copy.deepcopy(record)
        changed['cases'][0]['final_independent_audit'] = 'not executed'
        altered = composer.encoded(changed)
        with self.assertRaisesRegex(ValueError, 'audits'):
            installer.validate_package_qualification(altered, composer.sha(altered), package_sha)

    def test_rehashed_changed_dependency_is_still_rejected(self):
        runtime = ROOT / '.runtime'
        if runtime.is_symlink():
            raise ValueError('CURRENT_TEST_RUNTIME_REPARSE')
        runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='ssis-current-negative-', dir=runtime) as temporary:
            output = Path(temporary).resolve()
            self.assertEqual(output.parent, runtime.resolve())
            with zipfile.ZipFile(self.archive) as archive:
                payload = {name[len(composer.NAME) + 1:]: archive.read(name) for name in archive.namelist()}
            path = 'Modules/toolbelt.tsql.script-parser/Artifacts/Toolbelt.Tsql.ScriptParser.dll'
            payload[path] += b'synthetic-corruption'
            manifest = json.loads(payload['PACKAGE-MANIFEST.json'])
            manifest['files'] = [{'path': path, 'bytes': len(data), 'sha256': composer.sha(data)}
                                 for path, data in sorted(payload.items())
                                 if path not in ('PACKAGE-MANIFEST.json', 'SHA256SUMS.txt')]
            payload['PACKAGE-MANIFEST.json'] = composer.encoded(manifest)
            payload['SHA256SUMS.txt'] = ''.join(composer.sha(data) + '  ' + path + '\n'
                                                for path, data in sorted(payload.items())
                                                if path != 'SHA256SUMS.txt').encode('ascii')
            changed = output / self.archive.name
            with zipfile.ZipFile(changed, 'x', zipfile.ZIP_DEFLATED) as archive:
                for name, data in payload.items():
                    entry = zipfile.ZipInfo(composer.NAME + '/' + name)
                    entry.create_system = 3
                    entry.external_attr = 0o100644 << 16
                    entry.compress_type = zipfile.ZIP_DEFLATED
                    archive.writestr(entry, data)
            changed.with_suffix('.zip.sha256').write_text(composer.sha(changed.read_bytes()) + '  ' + changed.name + '\n', encoding='ascii')
            with contextlib.redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, 'unchanged predecessor dependency'):
                guard.validate(changed)


if __name__ == '__main__':
    unittest.main()
