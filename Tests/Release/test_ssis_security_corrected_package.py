"""Aktueller Build: Sicherheitsbindung und ZIP-Integrität, ohne SQL."""
from pathlib import Path
import copy
import json
import sys
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
from new_ssis_current_package import validate_native_record, SECURITY_PROFILE
from validate_ssis_current_package import validate

class CurrentPackageTests(unittest.TestCase):
    def setUp(self):
        self.record=json.loads((ROOT/'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.Build.20261116.json').read_bytes())
    def test_actual_package_payload_and_dependencies(self):
        validate(ROOT/'Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-SecurityCorrected-Install-Windows.zip',profile=SECURITY_PROFILE)
    def test_provider_cannot_be_rebound_by_self_consistent_hashes(self):
        r=copy.deepcopy(self.record);r['provider']['sha256']='0'*64;r['qualified_assembly_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'native security source/provider binding'):validate_native_record(r,SECURITY_PROFILE)
    def test_evidence_is_mandatory_and_exact(self):
        for kind in ('missing','changed'):
            r=copy.deepcopy(self.record);key=next(iter(r['evidence']))
            if kind=='missing':del r['evidence'][key]
            else:r['evidence'][key]='0'*64
            with self.subTest(kind=kind),self.assertRaises(ValueError):validate_native_record(r,SECURITY_PROFILE)
    def test_unexecuted_matrix_cannot_be_promoted_to_build_status(self):
        r=copy.deepcopy(self.record);r['result']='PASS'
        with self.assertRaisesRegex(ValueError,'security build binding'):validate_native_record(r,SECURITY_PROFILE)
