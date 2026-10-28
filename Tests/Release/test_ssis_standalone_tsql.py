"""Offline checks for the standalone T-SQL installer batch structure."""
from pathlib import Path
import json
import hashlib
import re
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import new_ssis_standalone_tsql as installer
import help_contract_source


class StandaloneTsqlInstallerTests(unittest.TestCase):
    def test_runtime_report_keeps_scope_and_trust_limit_explicit(self):
        report_path = ROOT / "Releases/1.0.0/ssis-standalone-installer-runtime-qualification.json"
        report = json.loads(report_path.read_text(encoding="utf-8"))
        self.assertIs(report["publication_authorized"], False)
        self.assertEqual(report["kind"], "standalone_tsql_installer_runtime_qualification")
        scope = report["scope"]
        self.assertEqual(scope["case_count"], 2)
        self.assertEqual(scope["deployment_modes"], ["local", "central"])
        self.assertEqual(scope["results"]["target_cases"], "PASS")
        self.assertEqual(scope["results"]["cleanup_audits"], "PASS")
        self.assertIs(scope["assembly_trust"]["installer_registration_opt_in_exercised"], False)
        self.assertIn("The full SQL Server version/platform matrix", scope["not_qualified"])
        self.assertIn("The installer's opt-in assembly-trust registration branch", scope["not_qualified"])
        self.assertEqual(report["date"], "2026-10-28")
        self.assertEqual(report["installer"]["path"], "Releases/1.0.0/SSIS-INSTALL-TSQL.sql")
        self.assertEqual(report["qualified_package"]["sha256"], "A256929FF32DAEE4087DC61C70BB8D4DFFEBB55772878BE53C658088F4E33049")
        execution = report["execution"]
        self.assertEqual(execution["driver"], "Tests/Release/Invoke-StandaloneTsqlInstallerLab.ps1")
        self.assertIn("one SqlClient CommandText", execution["command_method"])
        self.assertEqual(execution["mode_bindings"]["local"]["command_sha256"], report["installer"]["sha256"])
        self.assertEqual(execution["mode_bindings"]["local"]["header_override_count"], 0)
        central = execution["mode_bindings"]["central"]
        self.assertEqual(central["command_sha256"], "3AD62550FAF04A9769B68684BCAE58C72A48F0244101456A5171115696960F75")
        self.assertEqual(central["header_override"], {
            "from": "DECLARE @DeploymentMode nvarchar(16)=N'local';",
            "to": "DECLARE @DeploymentMode nvarchar(16)=N'central';",
            "count": 1,
        })
        self.assertEqual(len(report["execution_input_pins"]), 16)
        self.assertTrue(all(not Path(pin["path"]).is_absolute() for pin in report["execution_input_pins"]))
        sql = (ROOT / report["installer"]["path"]).read_bytes()
        self.assertEqual(hashlib.sha256(sql).hexdigest().upper(), report["installer"]["sha256"])
        central_override = central["header_override"]
        old_header = central_override["from"].encode("utf-8")
        new_header = central_override["to"].encode("utf-8")
        self.assertEqual(sql.count(old_header), central_override["count"])
        central_sql = sql.replace(old_header, new_header, central_override["count"])
        self.assertEqual(hashlib.sha256(central_sql).hexdigest().upper(), central["command_sha256"])
        for pin in report["execution_input_pins"]:
            pinned_bytes = (ROOT / pin["path"]).read_bytes()
            self.assertEqual(hashlib.sha256(pinned_bytes).hexdigest().upper(), pin["sha256"], pin["path"])
        guide = (ROOT / "Releases/1.0.0/SSIS-INSTALL-TSQL.md").read_text(encoding="utf-8")
        self.assertIn("ssis-standalone-installer-runtime-qualification.json", guide)

    def test_navigation_delta_restores_only_the_two_exact_installer_links(self):
        paths = (
            "Releases/1.0.0/README.md",
            "Releases/1.0.0/EVIDENCE-MAP.md",
        )
        runtime = ROOT / ".runtime"
        runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=runtime) as temp:
            temp_root = Path(temp)
            record_path = temp_root / help_contract_source.SSIS_INSTALL_NAV_RECORD
            record_path.parent.mkdir(parents=True)
            shutil.copy2(ROOT / help_contract_source.SSIS_INSTALL_NAV_RECORD, record_path)
            for path in paths:
                target = temp_root / path
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / path, target)
                restored = help_contract_source.validate_ssis_installer_navigation(temp_root, path)
                self.assertEqual(hashlib.sha256(restored).hexdigest(),
                                 help_contract_source.SSIS_INSTALL_NAV_BASELINE_SHA256[path])
            mutated = temp_root / paths[0]
            mutated.write_bytes(mutated.read_bytes() + b"<!-- unrelated text drift -->\n")
            with self.assertRaisesRegex(ValueError, "current bytes differ"):
                help_contract_source.validate_ssis_installer_navigation(temp_root, paths[0])
            with self.assertRaisesRegex(ValueError, "unsupported standalone installer navigation path"):
                help_contract_source.validate_ssis_installer_navigation(temp_root, "Releases/1.0.0/RELEASE-GATES.md")

    def test_go_split_and_header_removal_respect_sql_lexical_context(self):
        text = """SELECT N'first
GO
still string';
/* outer
GO
/* nested */
still comment */
SELECT [GO]
GO
SELECT \"GO\"
GO
SELECT 1
GO
"""
        batches = installer.split_go(text, 3)
        self.assertEqual(len(batches), 4)
        bracket_identifier = installer.split_go("SELECT [a[b\nGO\nc]", 0)
        self.assertEqual(len(bracket_identifier), 1)
        self.assertIn("GO", bracket_identifier[0])
        self.assertIn("GO\nstill string", batches[0])
        self.assertIn("/* outer\nGO", batches[0])
        self.assertIn("SELECT [GO]", batches[0])
        self.assertIn('SELECT \"GO\"', batches[1])

        self.assertEqual(installer.remove_sqlcmd_header(":On Error exit\nSELECT 1"), "SELECT 1")
        literal = "SELECT N':On Error exit';\nSELECT 1"
        self.assertEqual(installer.remove_sqlcmd_header(literal), literal)
        self.assertEqual(installer.remove_sqlcmd_header("SELECT N':r harmless';\n-- $(not a directive)\nSELECT 1"),
                         "SELECT N':r harmless';\n-- $(not a directive)\nSELECT 1")
        with self.assertRaisesRegex(ValueError, "SQLCMD_SYNTAX_REMAINS"):
            installer.remove_sqlcmd_header("SELECT 1\n:On Error exit")
        with self.assertRaisesRegex(ValueError, "SQLCMD_SYNTAX_REMAINS"):
            installer.remove_sqlcmd_header("SELECT 1\n:r other.sql")
        with self.assertRaisesRegex(ValueError, "SQLCMD_SYNTAX_REMAINS"):
            installer.remove_sqlcmd_header("SELECT $(DeploymentMode)")
        with self.assertRaisesRegex(ValueError, "SQL_LEXICAL_STATE_INVALID"):
            installer.split_go("SELECT N'unclosed", 0)

    def test_bounded_package_reader_rejects_oversize_and_reads_exact_bytes(self):
        runtime = ROOT / ".runtime"
        runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=runtime, prefix="ssis-bounded-input-") as folder:
            path = Path(folder) / "input.bin"
            path.write_bytes(b"12345")
            self.assertEqual(installer.read_regular_bounded(path, 5), b"12345")
            with self.assertRaisesRegex(ValueError, "PACKAGE_INPUT_SIZE_LIMIT"):
                installer.read_regular_bounded(path, 4)

    def test_result_table_temp_tables_share_one_outer_stage(self):
        payloads, _, _, _ = installer.read_inputs()
        result_text = installer.expand_fixed_includes(
            installer.RESULT_DEPLOY,
            installer.decode_sql(payloads[installer.RESULT_DEPLOY]).replace("$(DeploymentMode)", "local"),
            payloads,
        )
        result_text = installer.remove_sqlcmd_header(result_text)
        batches = installer.split_go(result_text, 5)
        finalizer = installer.move_result_table_transaction_control(batches[4])
        stage = installer.build_result_table_stage(batches[0], finalizer)
        outer_call = "EXEC sys.sp_executesql @ResultTableStage, N'@ResultTableProcedure nvarchar(max), @RequestedDeploymentMode nvarchar(16), @ResultTableAnsi nvarchar(max), @ResultTableQuotedIdentifier nvarchar(max), @ResultTableFinalize nvarchar(max)', @ResultTableProcedure=@ResultTableProcedure, @RequestedDeploymentMode=@DeploymentMode, @ResultTableAnsi=@ResultTableAnsi, @ResultTableQuotedIdentifier=@ResultTableQuotedIdentifier, @ResultTableFinalize=@ResultTableFinalize;"
        installer.validate_result_table_temp_scope(batches[0], batches[4], stage, outer_call)

        for damaged_first, damaged_final, damaged_stage, damaged_outer in (
            (batches[0].replace("CREATE TABLE #tbx_ResultTableReleaseObjects", "CREATE TABLE #other", 1),
             batches[4], stage, outer_call),
            (batches[0], batches[4].replace("#tbx_ResultTableDeployState", "#other", 1), stage, outer_call),
            (batches[0], batches[4].replace("COMMIT TRANSACTION;", "-- removed", 1), stage, outer_call),
            (batches[0], batches[4], stage.replace("EXEC sys.sp_executesql @ResultTableFinalize;", "", 1), outer_call),
            (batches[0], batches[4], stage.replace("COMMIT TRANSACTION;", "-- removed", 1), outer_call),
            (batches[0], batches[4], "-- removed".join(stage.rsplit("ROLLBACK TRANSACTION;", 1)), outer_call),
            (batches[0], batches[4], stage.replace("EXEC sys.sp_executesql @ResultTableAnsi;", "", 1), outer_call),
            (batches[0], batches[4], stage, outer_call.replace("@ResultTableFinalize=@ResultTableFinalize", "", 1)),
        ):
            with self.subTest(damaged_stage=damaged_stage[-80:]):
                with self.assertRaisesRegex(ValueError, "RESULT_TABLE_TEMP_SCOPE_INVALID"):
                    installer.validate_result_table_temp_scope(damaged_first, damaged_final, damaged_stage, damaged_outer)

    def test_parser_transaction_stays_in_one_outer_scope(self):
        payloads, _, _, _ = installer.read_inputs()
        text = installer.remove_sqlcmd_header(
            installer.decode_sql(payloads[installer.PARSER_DEPLOY]).replace("N'$(DeploymentMode)'", "@RequestedDeploymentMode")
        )
        text = installer.replace_single_binary(text, payloads["parser_dll"], "@ParserDll")
        text = installer.replace_single_binary(text, payloads["scriptdom_dll"], "@ScriptDomDll")
        batches = installer.split_go(text, 14)
        indexes = [i for i, batch in enumerate(batches) if re.search(r"(?is)^\s*CREATE FUNCTION\b", batch)]
        function_calls = []
        for index in indexes:
            function_calls.extend((
                "SET ANSI_NULLS ON;",
                "SET QUOTED_IDENTIFIER ON;",
                "EXEC sys.sp_executesql N'" + installer.escaped_sql_literal(batches[index].strip()) + "';",
            ))
        finalizer = installer.move_parser_transaction_control(batches[13])
        stage = installer.build_parser_stage(batches[0], function_calls, finalizer)
        installer.validate_parser_transaction_scope(batches[0], batches[13], stage)
        self.assertEqual(batches[0].count("BEGIN TRANSACTION;"), 1)
        self.assertEqual(batches[13].count("COMMIT TRANSACTION;"), 1)
        for damaged_stage in (
            stage.replace("COMMIT TRANSACTION;", "-- removed", 1),
            stage.replace("ROLLBACK TRANSACTION;", "-- removed", 1),
            stage.replace("EXEC sys.sp_executesql @ParserFinalize, N'@RequestedDeploymentMode nvarchar(16)', @RequestedDeploymentMode=@RequestedDeploymentMode;", "", 1),
        ):
            with self.assertRaisesRegex(ValueError, "PARSER_TRANSACTION_SCOPE_INVALID"):
                installer.validate_parser_transaction_scope(batches[0], batches[13], damaged_stage)

    def test_generated_installer_is_current_and_has_no_batch_directives(self):
        payloads, _, _, _ = installer.read_inputs()
        hashes = installer.get_hashes(payloads)
        generated = installer.render(payloads, hashes)
        self.assertEqual(generated, (ROOT / installer.OUTPUT).read_bytes())
        sql = generated.decode("utf-8")
        self.assertNotRegex(sql, r"(?im)^\s*GO\s*$")
        self.assertNotRegex(sql, r"(?im)^\s*:(?:r|setvar|On Error)\b|\$\(")
        for forbidden in ("sp_configure", "TRUSTWORTHY ON", "OPENROWSET", "BULK INSERT",
                          "xp_cmdshell", "sp_drop_trusted_assembly"):
            self.assertNotIn(forbidden.lower(), sql.lower())
        self.assertNotRegex(sql, r"(?im)^\s*USE\b")
        self.assertIn("DECLARE @DeploymentMode nvarchar(16)=N'local';", sql)
        self.assertIn("IF @DeploymentMode IS NULL OR @DeploymentMode NOT IN (N'local',N'central')", sql)
        self.assertEqual(sql.count("@RequestedDeploymentMode=@DeploymentMode"), 3)
        self.assertIn("EXEC sys.sp_executesql @ParserStage,", sql)
        self.assertNotIn("@ParserPreamble", sql)
        self.assertIn("ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1", sql)
        self.assertIn("IF DB_ID() IS NULL OR DB_ID() <= 4", sql)
        caller_guard = (
            "IF @@TRANCOUNT <> 0 OR (@@OPTIONS & 2) <> 0\nBEGIN\n"
            "    RAISERROR(N'TBX_SSIS_INSTALL_SESSION: Frische Sitzung ohne Callertransaktion erforderlich.',16,1);\n"
            "    RETURN;\nEND;"
        )
        self.assertLess(sql.index(caller_guard), sql.index("SET NOCOUNT ON;"))
        self.assertLess(sql.index(caller_guard), sql.index("SET XACT_ABORT ON;"))
        temp_guard = (
            "IF OBJECT_ID(N'tempdb..#tbx_ResultTableReleaseObjects') IS NOT NULL OR "
            "OBJECT_ID(N'tempdb..#tbx_ResultTableDeployState') IS NOT NULL\nBEGIN\n"
            "    RAISERROR(N'TBX_SSIS_INSTALL_TEMP_SCOPE: Reservierte ResultTable-Tempnamen sind bereits belegt.',16,1);\n"
            "    RETURN;\nEND;"
        )
        self.assertEqual(sql.count(temp_guard), 1)
        self.assertLess(sql.index(caller_guard), sql.index(temp_guard))
        self.assertLess(sql.index(temp_guard), sql.index("SET NOCOUNT ON;"))
        for label, payload_key in (
            ("Toolbelt LICENSE.md", "LICENSE.md"),
            ("Microsoft ScriptDom LICENSE", "ThirdParty/ScriptDom-180.117.0/LICENSE"),
            ("Microsoft ScriptDom and ANTLR NOTICE", "ThirdParty/ScriptDom-180.117.0/NOTICE.txt"),
        ):
            block = re.search(
                rf"(?ms)^-- BEGIN LICENSE TEXT: {re.escape(label)}\n(.*?)^-- END LICENSE TEXT: {re.escape(label)}$",
                sql,
            )
            self.assertIsNotNone(block)
            comment_lines = block.group(1).splitlines()
            self.assertTrue(all(line == "--" or line.startswith("-- ") for line in comment_lines))
            recovered = "\n".join("" if line == "--" else line[3:] for line in comment_lines) + "\n"
            self.assertEqual(recovered, installer.decode_sql(payloads[payload_key]))
        binary_literals = re.findall(rb"(?i)0x([0-9a-f]+)", generated)
        self.assertTrue(binary_literals)
        self.assertLessEqual(max(map(len, binary_literals)), 8000)
        for variable, payload_key in (("@ParserDll", "parser_dll"),
                                      ("@ScriptDomDll", "scriptdom_dll"),
                                      ("@SsisDll", "ssis_dll")):
            initializer_lines = installer.emit_binary_initializer(variable, payloads[payload_key])
            initializer = "\n".join(initializer_lines)
            self.assertIn(f"DECLARE {variable} varbinary(max) = CONVERT(varbinary(max),0x);", initializer)
            self.assertEqual(sql.count(initializer), 1)
            self.assertEqual(sql.count("DECLARE " + variable + " varbinary(max)"), 1)
            chunks = re.findall(r"0x([0-9A-F]+)", initializer)
            self.assertEqual(bytes.fromhex("".join(chunks)), payloads[payload_key])
            self.assertEqual(installer.validate_binary_initializer(variable, initializer_lines, payloads[payload_key]), payloads[payload_key])
            assignments = initializer_lines[1:]
            self.assertTrue(assignments)
            self.assertTrue(all(line.startswith(f"SET {variable} = {variable} + CAST(0x") for line in assignments))
            for line in assignments:
                group_literals = re.findall(r"0x([0-9A-F]+)", line)
                self.assertLessEqual(len(group_literals), 20)
                self.assertLessEqual(max(map(len, group_literals)), 8000)
            truncated = "\n".join(initializer_lines[:-1])
            with self.assertRaisesRegex(ValueError, "BINARY_INITIALIZER_(?:BYTES_MISMATCH|EMPTY)"):
                installer.validate_binary_initializer(variable, truncated.splitlines(), payloads[payload_key])
            wrong_scope = initializer_lines.copy()
            wrong_scope[1] = wrong_scope[1].replace(f"SET {variable} = {variable}", "SET @OtherDll = @OtherDll", 1)
            with self.assertRaisesRegex(ValueError, "BINARY_INITIALIZER_GROUP_INVALID"):
                installer.validate_binary_initializer(variable, wrong_scope, payloads[payload_key])
        self.assertIn("DECLARE @RegisterAssemblyTrust bit = 0;", sql)
        self.assertEqual(sql.lower().count("sp_add_trusted_assembly"), 3)
        guards = [sql.index("HASHBYTES(N'SHA2_512', @" + name)
                  for name in ("ParserDll", "ScriptDomDll", "SsisDll")]
        first_trust = sql.index("sp_add_trusted_assembly")
        first_stage = sql.index("SET @InstallerStage=N'RESULT_TABLE_1_0_0'")
        self.assertLess(max(guards), first_trust)
        self.assertLess(max(guards), first_stage)
        self.assertIn("IF @ParserDll IS NULL OR @ScriptDomDll IS NULL OR @SsisDll IS NULL OR HASHBYTES", sql)
        self.assertIn("@ResultTableAnsi nvarchar(max), @ResultTableQuotedIdentifier nvarchar(max), @ResultTableFinalize nvarchar(max)", sql)
        self.assertIn("@ResultTableAnsi=@ResultTableAnsi, @ResultTableQuotedIdentifier=@ResultTableQuotedIdentifier, @ResultTableFinalize=@ResultTableFinalize", sql)
        self.assertIn("IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;", sql)
        for missing_guard in (
            "IF @DeploymentMode IS NULL OR @DeploymentMode NOT IN (N'local',N'central')",
            "IF @ParserDll IS NULL OR @ScriptDomDll IS NULL OR @SsisDll IS NULL OR HASHBYTES(N'SHA2_512', @ParserDll)",
            "IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;",
        ):
            with self.subTest(missing_guard=missing_guard[:32]):
                with self.assertRaisesRegex(ValueError, "INSTALLER_GUARD_CONTRACT_INVALID"):
                    installer.validate_installer_guards(sql.replace(missing_guard, "").encode("utf-8"))
        delayed_caller_guard = sql.replace(caller_guard, "", 1).replace(
            "SET NOCOUNT ON;", "SET NOCOUNT ON;\n" + caller_guard, 1
        )
        with self.assertRaisesRegex(ValueError, "INSTALLER_GUARD_CONTRACT_INVALID"):
            installer.validate_installer_guards(delayed_caller_guard.encode("utf-8"))
        delayed_temp_guard = sql.replace(temp_guard, "", 1).replace(
            "SET NOCOUNT ON;", "SET NOCOUNT ON;\n" + temp_guard, 1
        )
        with self.assertRaisesRegex(ValueError, "INSTALLER_GUARD_CONTRACT_INVALID"):
            installer.validate_installer_guards(delayed_temp_guard.encode("utf-8"))

    def test_changed_historical_qualification_is_rejected(self):
        runtime = ROOT / ".runtime"
        runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=runtime, prefix="ssis-installer-record-") as folder:
            temporary_root = Path(folder)
            for relative in (installer.PACKAGE, installer.PACKAGE_SIDECAR,
                             installer.PACKAGE_QUALIFICATION):
                target = temporary_root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / relative, target)
            qualification = temporary_root / installer.PACKAGE_QUALIFICATION
            changed = bytearray(qualification.read_bytes())
            changed[-2] ^= 1
            qualification.write_bytes(changed)
            with patch.object(installer, "ROOT", temporary_root):
                with self.assertRaisesRegex(ValueError, "PACKAGE_QUALIFICATION_SOURCE_DRIFT"):
                    installer.read_inputs()


if __name__ == "__main__":
    unittest.main()
