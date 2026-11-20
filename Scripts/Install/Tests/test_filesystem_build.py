"""Integrity checks for trusted private build inputs; no SQL or native I/O."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'Scripts/Install'))
import filesystem_build as build


class FilesystemBuildTests(unittest.TestCase):
    def fixture(self, directory):
        payload=b'MZsynthetic-build-fixture'
        sources={'Modules/Contoso/Provider.cs':'a'*64}
        record=dict(schema=build.SCHEMA,moduleId=build.MODULE,binaryFile=build.DLL,
                    binarySha256=build.digest(payload),binarySha512=build.digest(payload,'sha512'),
                    sourceFiles=sources,build=dict(configuration='Release',deterministic=True,
                    debugType='None',msbuildSha256='b'*64),sqlExecuted=False)
        (directory/build.DLL).write_bytes(payload)
        return record,sources,payload

    def test_valid_private_manifest_and_binary_match_exact_source_set(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory=Path(temporary);record,sources,payload=self.fixture(directory)
            (directory/build.MANIFEST).write_text(json.dumps(record),encoding='utf-8')
            with patch.object(build,'sources',return_value=sources):
                self.assertEqual(build.admit(ROOT,directory),payload)

    def test_source_binary_identity_and_build_drift_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory=Path(temporary);record,sources,payload=self.fixture(directory)
            changes=[dict(schema='other'),dict(moduleId='other'),dict(binaryFile='../other.dll'),
                     dict(sqlExecuted=True),dict(sourceFiles={}),dict(binarySha256='0'*64),
                     dict(binarySha512='0'*128),dict(extra='not allowed'),
                     dict(build=dict(record['build'],deterministic=False)),
                     dict(build=dict(record['build'],msbuildSha256='not-a-hash'))]
            for change in changes:
                candidate=copy.deepcopy(record);candidate.update(change)
                (directory/build.MANIFEST).write_text(json.dumps(candidate),encoding='utf-8')
                with self.subTest(change=change),patch.object(build,'sources',return_value=sources),self.assertRaises(ValueError):
                    build.admit(ROOT,directory)
            (directory/build.MANIFEST).write_text(json.dumps(record),encoding='utf-8')
            (directory/build.DLL).write_bytes(payload+b'changed')
            with patch.object(build,'sources',return_value=sources),self.assertRaises(ValueError):
                build.admit(ROOT,directory)

    def test_real_source_closure_includes_all_compiler_and_skill_dependencies(self):
        inputs=build.sources(ROOT)
        self.assertIn('Modules/toolbelt.filesystem.windows/Clr/UsageSkillsGenerated.cs',inputs)
        self.assertIn('Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs',inputs)
        self.assertIn('Modules/toolbelt.filesystem.windows/Clr/Toolbelt.Filesystem.Windows.csproj',inputs)
        self.assertIn('Scripts/Install/filesystem_build.py',inputs)
        self.assertIn('Modules/toolbelt.filesystem.windows/module.yaml',inputs)
        self.assertEqual(sum(p.startswith('Metadata/UsageSkills/') for p in inputs),9)
        self.assertNotIn('Metadata/UsageSkills/toolbelt_filesystem/USP_ListDirectory.md',inputs)


if __name__=='__main__':unittest.main()
