"""Source-bound offline guard for the JSON Schema uninstall lock adapter."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
RELEASE = ROOT / "Tests/Release"


class JsonSchemaUninstallAppLockAdapterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.driver = (RELEASE / "Invoke-JsonSchemaUninstallAppLockLab.ps1").read_text(encoding="utf-8")
        cls.preparer = (RELEASE / "Prepare-JsonSchemaUninstallAppLockRunset.ps1").read_text(encoding="utf-8")
        cls.offline = (RELEASE / "Test-JsonSchemaUninstallAppLockOffline.ps1").read_text(encoding="utf-8")
        cls.uninstall = (ROOT / "Modules/toolbelt.json.schema/Deployment/Uninstall.sql").read_text(encoding="utf-8")
        cls.base = (RELEASE / "Invoke-JsonSchemaAppLockLab.ps1").read_text(encoding="utf-8")

    def test_adapter_is_separate_and_reuses_existing_protocol_helpers(self):
        self.assertIn("Assert-ExternalHolderGranted", self.driver)
        self.assertIn("Acquire-HolderLock", self.driver)
        self.assertIn("Get-ContenderStateSamples", self.driver)
        self.assertIn("Test-ExternalSessionIdle", self.driver)
        self.assertIn("Assert-ReleaseOwnIdentity", self.driver)
        self.assertIn("Invoke-JsonSchemaAppLockLab.ps1", self.driver)  # AST helper source only
        self.assertNotIn("& (Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1')", self.driver)
        self.assertIn("ExpectedRunsetSHA256", self.driver)
        self.assertIn("Assert-RunsetStable", self.driver)

    def test_fixed_uninstall_resources_and_messages_match_the_module_source(self):
        for text in (
            "toolbelt.deploy.json.shared-core",
            "toolbelt.deploy.toolbelt.json.schema",
            "JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar.",
            "JSON Schema lifecycle: Modul-AppLock nicht verfügbar.",
        ):
            self.assertIn(text, self.uninstall)
            self.assertIn(text, self.preparer)
            self.assertIn(text, self.driver)
        self.assertIn("'schema-uninstall-app-lock'", self.preparer)
        self.assertIn("deployment_mode='local'", self.preparer)

    def test_positive_uninstall_checks_full_core_projection_and_keeps_namespace(self):
        for text in (
            "CoreAssembly",
            "permission_set_desc",
            "BinaryHash",
            "RoleMemberships",
            "Principals",
            "Assert-SchemaModuleAbsent",
            "Read-CoreProjection",
            "Assert-SchemaSlots",
            "core_unchanged=$true",
        ):
            self.assertIn(text, self.driver)

    def test_offline_negative_cases_and_new_inputs_are_pinned(self):
        self.assertIn("JSON_UNINSTALL_APPLOCK_OFFLINE_NEGATIVE_CASE_ACCEPTED", self.offline)
        self.assertIn("Prepare-JsonSchemaUninstallAppLockRunset.ps1", self.driver)
        self.assertIn("Test-JsonSchemaUninstallAppLockOffline.ps1", self.driver)
        self.assertIn("Invoke-JsonSchemaUninstallAppLockLab.ps1", self.preparer)
        self.assertIn("Invoke-JsonSchemaAppLockLab.ps1", self.base)


if __name__ == "__main__":
    unittest.main()
