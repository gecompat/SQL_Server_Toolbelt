"""Offline source checks for the guarded JSON Schema deploy collision adapter."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
RELEASE = ROOT / "Tests/Release"


class JsonSchemaDeployCollisionAdapterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.driver = (RELEASE / "Invoke-JsonSchemaDeployCollisionLab.ps1").read_text(encoding="utf-8")
        cls.preparer = (RELEASE / "Prepare-JsonSchemaDeployCollisionRunset.ps1").read_text(encoding="utf-8")
        cls.offline = (RELEASE / "Test-JsonSchemaDeployCollisionOffline.ps1").read_text(encoding="utf-8")

    def test_adapter_is_a_separately_pinned_composition(self):
        for name in (
            "Invoke-JsonSchemaAppLockLab.ps1",
            "Invoke-JsonSchemaUninstallAppLockLab.ps1",
            "Invoke-JsonSchemaCallerTransactionLab.ps1",
            "Assert-RunsetStable",
            "ExpectedRunsetSHA256",
            "Invoke-PinnedSqlBatches",
            "Assert-ReleaseOwnIdentity",
        ):
            self.assertIn(name, self.driver)
        self.assertIn("Prepare-JsonSchemaCallerTransactionRunset.ps1", self.preparer)
        self.assertIn("Test-JsonSchemaDeployCollisionOffline.ps1", self.preparer)
        self.assertIn("Test-JsonSchemaDeployCollisionOffline.ps1", self.driver)
        self.assertNotIn("& (Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1')", self.driver)

    def test_fixed_collisions_and_expected_failures_are_not_widened(self):
        for text in (
            "#tbx_JsonSchema_DeployState",
            "USP_ValidateJsonSchema",
            "FT_ValidateJsonSchemaInternal",
            "Toolbelt.Module.toolbelt.json.schema.DeploymentMode",
            "JSON Schema lifecycle: reservierter Callerzustand belegt.",
            "JSON Schema lifecycle: unregistrierter oder fremder Zielslot.",
            "expected_error=55633",
            "expected_error=55634",
        ):
            self.assertIn(text, self.driver)
            self.assertIn(text, self.preparer)
        self.assertIn("fixture_preserved=$true", self.driver)
        self.assertIn("fixture_removed=$true", self.driver)

    def test_final_database_drop_is_blocked_by_fixture_or_module_drift(self):
        for text in (
            "JSON_DEPLOY_COLLISION_CLEANUP_FIXTURE_OWNERSHIP_UNKNOWN",
            "JSON_DEPLOY_COLLISION_CLEANUP_MODULE_DRIFT",
            "JSON_DEPLOY_COLLISION_CLEANUP_DATABASE_DRIFT",
            "Assert-CleanupFixtureOwnership",
            "JSON_DEPLOY_COLLISION_OFFLINE_FIXTURE_DRIFT_NOT_BLOCKED",
            "JSON_DEPLOY_COLLISION_OFFLINE_MODULE_DRIFT_NOT_BLOCKED",
        ):
            self.assertIn(text, self.driver if "CLEANUP_" in text else self.offline)
        self.assertNotIn("DROP TABLE IF EXISTS", self.driver.upper())
        self.assertNotIn("[Data.SqlClient.SqlTransaction]", self.driver)

    def test_artifacts_and_fixture_ownership_are_typed_and_pinned(self):
        for text in (
            "Assert-ArtifactClosure",
            "Get-FileHash -LiteralPath $full -Algorithm SHA256",
            "Get-FileHash -LiteralPath $full -Algorithm SHA512",
            "Test-SqlObjectPresent",
            "Assert-OwnedFixtureShape",
            "BinaryValue",
            "@TypedValue nvarchar(16)",
            "FOR JSON PATH, INCLUDE_NULL_VALUES",
            "core_owner_id",
            "JSON_DEPLOY_COLLISION_OFFLINE_NULL_TEMP_ID_ACCEPTED",
            "JSON_DEPLOY_COLLISION_OFFLINE_DBNULL_IDENTITY",
            "JSON_DEPLOY_COLLISION_OFFLINE_MARKER_WIDTH_DRIFT_ACCEPTED",
            "JSON_DEPLOY_COLLISION_OFFLINE_ARTIFACT_HASH_DRIFT_ACCEPTED",
        ):
            self.assertIn(text, self.driver + self.offline)


if __name__ == "__main__":
    unittest.main()
