"""Offline-Prüfungen der deterministischen ZIP-Entrycount-Fixtures."""
from pathlib import Path
import io
import hashlib
import json
import os
import shutil
import subprocess
import sys
import uuid
import zipfile

from compose_zip_entry_count import (
    FIXTURE,
    ROOT,
    build_archive,
    compose_sources,
    write_output,
)
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import help_contract_source
import ssis_historical_source_bridge


class ZipEntryCountComposerMixin:
    def test_zip_entry_count_evidence_is_bound_to_current_sources_and_package(self):
        report_path = ROOT / 'Releases/1.0.0/zip-entry-count-qualification.json'
        report = json.loads(report_path.read_bytes())
        self.assertEqual(report['schema_version'], 'toolbelt-zip-entry-count-boundary/v1')
        self.assertIs(report['publication_authorized'], False)
        self.assertIs(report['product_sql_changed'], False)
        self.assertIs(report['product_clr_changed'], False)
        self.assertIs(report['manifest_or_package_changed'], False)
        self.assertEqual(report['module_status'], 'partially validated')
        self.assertEqual(report['release_status'], 'unreleased')
        self.assertEqual(report['result'], 'PASS_FOR_FIXED_ENTRY_COUNT_BOUNDARY')
        self.assertEqual(report['matrix']['case_count'], 12)
        self.assertEqual(len(report['matrix']['cases']), 12)
        expected = {
            (platform, version, level)
            for platform in ('linux', 'windows')
            for version, levels in (('2019', (150,)), ('2022', (150, 160)),
                                    ('2025', (150, 160, 170)))
            for level in levels
        }
        actual = {
            (item['platform'], item['sql_version'], item['compatibility_level'])
            for item in report['matrix']['cases']
        }
        self.assertEqual(actual, expected)
        self.assertEqual(report['results']['positive_calls'], 24)
        self.assertEqual(report['results']['positive_rows_total'], 240000)
        self.assertEqual(report['results']['expected_direct_reader_rejections'], 48)
        self.assertEqual(report['results']['overflow_archive']['sql_error_number'], 51325)
        self.assertEqual(report['results']['invalid_max_entries']['sql_error_number'], 51320)
        self.assertEqual(report['attempts']['total_sql_process_invocations'], 30)
        self.assertEqual(report['cleanup']['immediate_audits_passed'], 12)
        self.assertEqual(report['cleanup']['final_configuration_audits_passed'], 6)
        self.assertEqual(report['cleanup']['own_database_entries_created_and_dropped'], 24)
        self.assertEqual(report['cleanup']['own_trust_removal_events'], 12)
        self.assertEqual(report['repository_input_pin_count'], 115)
        self.assertNotIn('sha512', json.dumps(report).lower())

        overlay_path = report['source_transition']['path']
        self.assertEqual(report['source_transition']['original_execution_sha256'],
                         report['source_sha256'][overlay_path])
        for relative, expected_sha256 in report['source_sha256'].items():
            if relative == overlay_path:
                continue
            path = Path(relative)
            self.assertFalse(path.is_absolute())
            self.assertNotIn('..', path.parts)
            self.assertNotIn('.runtime', path.parts)
            if relative in help_contract_source.source_paths(ROOT):
                help_contract_source.validate_historical_source(ROOT, relative, expected_sha256)
            elif relative in ssis_historical_source_bridge.source_paths():
                ssis_historical_source_bridge.validate_historical_source(ROOT, relative, expected_sha256)
            else:
                self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), expected_sha256)

        package_path = ROOT / report['package']['path']
        package_bytes = package_path.read_bytes()
        package_sha256 = hashlib.sha256(package_bytes).hexdigest()
        self.assertEqual(package_sha256, report['package']['sha256'])
        sidecar = package_path.with_name(package_path.name + '.sha256').read_text(encoding='utf-8').strip()
        self.assertTrue(sidecar.lower().startswith(package_sha256 + ' '))
        with zipfile.ZipFile(io.BytesIO(package_bytes)) as package:
            manifest_names = [name for name in package.namelist() if name.endswith('/CLR-PACKAGE.json')]
            self.assertEqual(len(manifest_names), 1)
            manifest = json.loads(package.read(manifest_names[0]))
            artifacts = [item for item in manifest['artifacts']
                         if item['module_id'] == report['binary']['module_id']]
            self.assertEqual(len(artifacts), 1)
            artifact = artifacts[0]
            binary_name = manifest_names[0].rsplit('/', 1)[0] + '/Binaries/' + artifact['file']
            binary = package.read(binary_name)
            self.assertEqual(hashlib.sha256(binary).hexdigest(), report['binary']['sha256'])
            self.assertEqual(artifact['sql_name'], report['binary']['sql_assembly_name'])
            self.assertEqual(artifact['origin'], report['package']['zip_module_origin'])

    def test_zip_entry_count_preparer_ast_overlay_reconstructs_pinned_original_bytes(self):
        report = json.loads((ROOT / 'Releases/1.0.0/zip-entry-count-qualification.json').read_bytes())
        transition = report['source_transition']
        path = transition['path']
        self.assertEqual(path, 'Tests/Release/Prepare-ZipEntryCountRunset.ps1')
        self.assertEqual(transition['original_execution_commit'],
                         '9044a2cb829d13e905ff08a26f580a97564ce60b')
        self.assertEqual(transition['original_execution_sha256'], report['source_sha256'][path])
        current = (ROOT / path).read_bytes()
        self.assertEqual(hashlib.sha256(current).hexdigest(), transition['current_source_sha256'])
        old_dot_source = (b"$labQualified = Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'\n"
                          b'. $labQualified')
        new_dot_source = b". (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')"
        self.assertEqual(current.count(new_dot_source), 1)
        reconstructed_original = current.replace(new_dot_source, old_dot_source)
        self.assertEqual(hashlib.sha256(reconstructed_original).hexdigest(),
                         transition['original_execution_sha256'])
        self.assertEqual(reconstructed_original.replace(old_dot_source, new_dot_source), current)

    def test_zip_entry_count_composition_uses_fixed_archives_and_input_pins(self):
        fixture = FIXTURE.read_bytes()
        zip_10000 = build_archive(10000)
        zip_10001 = build_archive(10001)
        report = compose_sources(fixture, zip_10000, zip_10001)
        self.assertEqual(report['positive_count'], 10000)
        self.assertEqual(report['overflow_count'], 10001)
        self.assertEqual(report['timestamp_dos'], '2020-02-03 04:05:06')
        self.assertEqual(report['entry_name_pattern'], 'eNNNNN.txt')
        self.assertEqual(report['limits'], {'archive_bytes': 268435456, 'max_entries': 10000})
        self.assertEqual(report['zip_10000_bytes'], len(zip_10000))
        self.assertEqual(report['zip_10001_bytes'], len(zip_10001))
        self.assertRegex(report['zip_10000_sha256'], r'^[0-9a-f]{64}$')
        self.assertRegex(report['zip_10001_sha256'], r'^[0-9a-f]{64}$')
        with zipfile.ZipFile(io.BytesIO(zip_10000), 'r') as archive:
            infos = archive.infolist()
            self.assertEqual(len(infos), 10000)
            for index, info in enumerate(infos):
                self.assertEqual(info.filename, f'e{index:05d}.txt')
                self.assertEqual(info.date_time, (2020, 2, 3, 4, 5, 6))
                self.assertEqual(info.compress_type, zipfile.ZIP_STORED)
                self.assertEqual(info.CRC, 0)
                self.assertEqual(info.file_size, 0)
                self.assertEqual(info.compress_size, 0)
        self.assertEqual(build_archive(10000), zip_10000)
        self.assertEqual(build_archive(10001), zip_10001)

    def test_zip_entry_count_composition_rejects_wrong_input_or_sql_binding(self):
        fixture = FIXTURE.read_bytes()
        with self.assertRaisesRegex(ValueError, 'ZIP_ENTRY_COUNT_UNSUPPORTED_SIZE'):
            build_archive(9999)
        with self.assertRaisesRegex(ValueError, 'ZIP_ENTRY_COUNT_ARCHIVE_COUNT'):
            compose_sources(fixture, build_archive(10000), build_archive(10000))
        changed = fixture.replace(b'@MaxEntries = @MaxEntries', b'@MaxEntries = 10001')
        with self.assertRaisesRegex(ValueError, 'ZIP_ENTRY_COUNT_PARAMETER_BINDING'):
            compose_sources(changed, build_archive(10000), build_archive(10001))

    def test_zip_entry_count_output_is_fresh_and_runtime_scoped(self):
        runtime = ROOT / '.runtime'
        runtime.mkdir(exist_ok=True)
        output = runtime / ('zip-entry-count-' + uuid.uuid4().hex)
        try:
            report = write_output(output)
            self.assertTrue((output / 'ZipEntryCount.Contract.sql').is_file())
            self.assertTrue((output / 'ZipEntryCount.10000.zip').is_file())
            self.assertTrue((output / 'ZipEntryCount.10001.zip').is_file())
            saved = json.loads((output / 'composition.json').read_text(encoding='utf-8'))
            self.assertEqual(saved, report)
            with self.assertRaisesRegex(ValueError, 'ZIP_ENTRY_COUNT_OUTPUT_SCOPE'):
                write_output(output)
        finally:
            if output.exists() and output.resolve().parent == runtime.resolve():
                for child in output.iterdir():
                    child.unlink()
                output.rmdir()

    def test_zip_entry_count_deployment_discovery_rejects_added_and_removed_modules(self):
        powershell = shutil.which('pwsh')
        if not powershell:
            self.skipTest('PowerShell 7 is unavailable for the discovery guard regression.')
        command = [powershell, '-NoProfile', '-NonInteractive', '-File',
                   str(ROOT / 'Tests/Release/Test-ZipEntryCountDeploymentDiscovery.ps1')]
        options = {'capture_output': True, 'text': True, 'timeout': 30, 'check': False}
        if os.name == 'nt':
            options['creationflags'] = getattr(subprocess, 'CREATE_NO_WINDOW', 0)
        completed = subprocess.run(command, **options)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(completed.stderr, '')
        self.assertEqual(completed.stdout.strip(),
                         'PASS ZIP_ENTRY_COUNT deployment discovery rejects additions and removals')
