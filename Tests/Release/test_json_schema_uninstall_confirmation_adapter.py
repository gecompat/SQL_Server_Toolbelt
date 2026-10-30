"""Offline source-bound checks for the central uninstall confirmation adapter."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
RELEASE = ROOT / "Tests/Release"


class JsonSchemaUninstallConfirmationAdapterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.driver = (RELEASE / "Invoke-JsonSchemaUninstallConfirmationLab.ps1").read_text(encoding="utf-8")
        cls.preparer = (RELEASE / "Prepare-JsonSchemaUninstallConfirmationRunset.ps1").read_text(encoding="utf-8")
        cls.offline = (RELEASE / "Test-JsonSchemaUninstallConfirmationOffline.ps1").read_text(encoding="utf-8")

    def test_scope_and_exact_lifecycle_oracles_are_fixed(self):
        for text in (
            "json-schema-uninstall-confirmation-probe/v1",
            "Version='2025';Patch='CU8'",
            "deployment_mode='central'",
            "confirmation='01'", "confirmation='0'",
            "JSON Schema lifecycle: ungültige Consumer-Bestätigung.",
            "JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.",
            "Assert-ExactBlock", "Assert-PositiveUninstall",
            "Read-JsonSchemaNamespace", "namespace_retained=$true",
        ):
            self.assertIn(text, self.driver + self.preparer)
        self.assertIn("Test-ExternalSessionIdle", self.driver)
        self.assertIn("@@OPTIONS", self.driver)
        self.assertIn("function Get-ObservedTransactionState($Connection)", self.driver)
        self.assertIn("DECLARE @ObservedTranCount int=@@TRANCOUNT,@ObservedXactState smallint=XACT_STATE();", self.driver)
        self.assertNotIn("SELECT XACT_STATE() AS ScalarValue", self.driver)

    def test_session_profile_failure_is_diagnosable_only_in_private_journal(self):
        for field in (
            "stage='SESSION_PROFILE'", "row_count=$profileRows.Count",
            "quoted_identifier=$null", "nocount=$null", "xact_abort=$null",
            "implicit_transactions=$null", "transaction_count=$null", "xact_state=$null",
            "$script:ledger.diagnostics+=@($profileDiagnostic);Save-Journal",
        ):
            self.assertIn(field, self.driver)
        self.assertNotIn("Write-Output $profileDiagnostic", self.driver)

    def test_reuses_pinned_guards_and_has_no_unbounded_execution_path(self):
        for text in (
            "Invoke-JsonSchemaAppLockLab.ps1", "Assert-ReleaseInputs",
            "Assert-RunsetStable", "ExpectedRunsetSHA256", "Assert-ArtifactClosure",
            "Assert-RequiredPins", "Assert-ReleaseOwnIdentity",
            "JSON_UNINSTALL_CONFIRMATION_OWNED_DATABASE_STATE_DRIFT",
            "function Test-ExactSqlErrorSet", "@($caught.Errors)",
        ):
            self.assertIn(text, self.driver)
        self.assertNotIn("DROP TABLE IF EXISTS", self.driver.upper())
        self.assertNotIn("[Data.SqlClient.SqlTransaction]", self.driver)

    def test_offline_negative_controls_cover_tamper_and_scope_drift(self):
        for text in (
            "OFFLINE_DUPLICATE_TRANSFORM_ACCEPTED",
            "OFFLINE_BAD_ARTIFACT_ACCEPTED",
            "OFFLINE_MISSING_HELPER_ACCEPTED",
            "OFFLINE_SQL_ERROR_SET_ORACLE",
            "OFFLINE_SQL_CONTRACT_DRIFT",
            "OFFLINE_UNEXPECTED_APPLOCK_CASE",
        ):
            self.assertIn(text, self.offline)


if __name__ == "__main__":
    unittest.main()
