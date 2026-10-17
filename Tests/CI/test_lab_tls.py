#!/usr/bin/env python3
"""SC-045: echte sqlcmd-Argumentnormalisierung ohne Lab oder Netzwerk."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / "Tests/CI/run-lab-target.sh").read_text(encoding="utf-8")
START = SOURCE.index("run_sqlcmd() {")
FUNCTION = SOURCE[START:SOURCE.index("\n}\n", START) + 3]
BASH = str(Path("C:/Program Files/Git/bin/bash.exe")) if Path("C:/Program Files/Git/bin/bash.exe").is_file() else shutil.which("bash")
if BASH is None:
    raise SystemExit("Lab TLS tests NOT_EXECUTED: bash fehlt")

class LabTls(unittest.TestCase):
    def call(self, *args, trust="False", purpose="Functional", encrypt="True"):
        # Identitätsmapper und CLI-Recorder statt Dateizugriff/SQL-Verbindung.
        setup = r'''set -euo pipefail
TBX_SQL_HOST=localhost TBX_SQL_PORT=1433 TBX_SQL_USER=Contoso
lab_sqlcmd=fake_sqlcmd
fake_sqlcmd() { printf '%s\n' "$@"; }
rewrite_test_database_names() { printf '%s\n' "$1"; }
map_workspace_path() { printf '%s\n' "$1"; }
map_sqlcmd_file_path() { printf '%s\n' "$1"; }
'''
        contract = f'TBX_SQL_ENCRYPT={encrypt} TBX_SQL_TRUST_SERVER_CERTIFICATE={trust} TBX_SQL_TEST_PURPOSE={purpose}\n'
        return subprocess.run([BASH, "-s", "--", *args], input=setup + contract + FUNCTION + '\nrun_sqlcmd "" "$@"',
                              text=True, capture_output=True, timeout=10)

    def test_container_options_cannot_disable_certificate_validation(self):
        result = self.call("-C", "-N", "-S", "127.0.0.1", "-U", "Contoso", "-P", "synthetic", "-Q", "SELECT 1")
        self.assertEqual(result.returncode, 0, result.stderr)
        args = result.stdout.splitlines()
        self.assertEqual(args.count("-N"), 1)
        self.assertNotIn("-C", args)
        self.assertEqual(args[args.index("-S")+1], "tcp:localhost,1433")
        self.assertNotIn("synthetic", args)

    def test_tls_or_hostname_overrides_rejected_before_cli(self):
        for option in ("-Nm", "-No", "-Ctrue", "-F", "-FContoso", "--trust-server-certificate", "--encrypt", "-D"):
            with self.subTest(option=option):
                result = self.call(option)
                self.assertEqual(result.returncode, 64)
                self.assertEqual(result.stdout, "")

    def test_attached_connection_options_do_not_override_lab_host(self):
        result = self.call("-S127.0.0.1", "-UContoso", "-Psynthetic", "-Q", "SELECT 1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("-S127.0.0.1", result.stdout)
        self.assertNotIn("synthetic", result.stdout)

    def test_both_cli_entrypoints_enforce_validation(self):
        self.assertEqual(SOURCE.count('TBX_SQL_TEST_PURPOSE:-Functional'), 4)
        self.assertIn('base_sqlcmd_args+=(-C)', SOURCE)
        self.assertIn('parsed+=(-C)', FUNCTION)

    def test_functional_preserves_explicit_trust_contract(self):
        result = self.call('-C', '-N', '-Q', 'SELECT 1', trust='True')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines().count('-C'), 1)
        self.assertEqual(result.stdout.splitlines().count('-N'), 1)

    def test_authenticated_tls_and_malformed_contracts_reject(self):
        for contract in ({'trust': 'True', 'purpose': 'AuthenticatedTls'}, {'purpose': 'unknown'},
                         {'trust': 'false'}, {'encrypt': 'False'}):
            with self.subTest(contract=contract):
                result = self.call('-Q', 'SELECT 1', **contract)
                self.assertEqual(result.returncode, 65)
                self.assertEqual(result.stdout, '')
        result = self.call('-C', '-Q', 'SELECT 1', purpose='AuthenticatedTls')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('-C', result.stdout.splitlines())

if __name__ == "__main__":
    unittest.main()
