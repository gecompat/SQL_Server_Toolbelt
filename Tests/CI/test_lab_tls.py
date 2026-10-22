#!/usr/bin/env python3
"""SC-045: echte sqlcmd-Argumentnormalisierung ohne Lab oder Netzwerk."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / "Tests/CI/run-lab-target.sh").read_text(encoding="utf-8")
START = SOURCE.index("run_sqlcmd() {")
FUNCTION = SOURCE[START:SOURCE.index("\n}\n", START) + 3]
CONTROL_START = SOURCE.index("run_control_query() {")
CONTROL = SOURCE[CONTROL_START:SOURCE.index("\n}\n", CONTROL_START) + 3]
BASH = str(Path("C:/Program Files/Git/bin/bash.exe")) if Path("C:/Program Files/Git/bin/bash.exe").is_file() else shutil.which("bash")
if BASH is None:
    raise SystemExit("Lab TLS tests NOT_EXECUTED: bash fehlt")

class LabTls(unittest.TestCase):
    def test_runner_shortcut_rejects_qualified_intent(self):
        names = ('TBX_LAB_QUALIFIED_CONTEXT_FILE', 'TBX_LAB_QUALIFIED_CONTEXT_SHA256', 'TBX_LAB_QUALIFIED_PWSH')
        with tempfile.TemporaryDirectory(prefix='toolbelt-runner-intent-') as directory:
            script = Path(directory) / 'sentinel.sh'
            script.write_text("printf 'FUNCTIONAL_RUNNER_EXECUTED\\n'\n", encoding='utf-8')
            for target in ('runner', ''):
                for actions in ('true', 'false'):
                    for intent in ('Functional', 'AuthenticatedTls', 'Unknown', *names):
                        with self.subTest(target=target, actions=actions, intent=intent):
                            env = os.environ.copy()
                            for name in names:
                                env.pop(name, None)
                            env.update(TBX_SQL_TARGET=target, GITHUB_ACTIONS=actions,
                                       TBX_SQL_TEST_PURPOSE=intent if intent not in names else 'Functional')
                            if intent in names:
                                env[intent] = 'synthetic'
                            result = subprocess.run([BASH, str(ROOT / 'Tests/CI/run-lab-target.sh'), str(script)],
                                                    env=env, text=True, capture_output=True, timeout=10)
                            self.assertEqual(result.returncode, 0 if intent == 'Functional' else 65, result.stderr)
                            self.assertEqual(result.stdout, 'FUNCTIONAL_RUNNER_EXECUTED\n' if intent == 'Functional' else '')

    def call(self, *args, trust="False", purpose="Functional", encrypt="True", context=None, control=False):
        # Identitätsmapper und CLI-Recorder statt Dateizugriff/SQL-Verbindung.
        setup = r'''set -euo pipefail
TBX_SQL_HOST=localhost TBX_SQL_PORT=1433 TBX_SQL_USER=Contoso
lab_sqlcmd=fake_sqlcmd
fake_sqlcmd() { printf '%s\n' "$@"; }
fake_pwsh() { return "${FAKE_GUARD_EXIT:-0}"; }
lab_workspace=/synthetic-workspace repo_root=/synthetic-workspace
base_sqlcmd_args=(-S tcp:localhost,1433 -U Contoso -N)
rewrite_test_database_names() { printf '%s\n' "$1"; }
map_workspace_path() { printf '%s\n' "$1"; }
map_sqlcmd_file_path() { printf '%s\n' "$1"; }
'''
        contract = f'TBX_SQL_ENCRYPT={encrypt} TBX_SQL_TRUST_SERVER_CERTIFICATE={trust} TBX_SQL_TEST_PURPOSE={purpose}\n'
        if context is not None:
            contract += f'TBX_LAB_QUALIFIED_PWSH=fake_pwsh TBX_LAB_QUALIFIED_CONTEXT_FILE=synthetic-context TBX_LAB_QUALIFIED_CONTEXT_SHA256=synthetic-hash FAKE_GUARD_EXIT={context}\n'
        function = CONTROL if control else FUNCTION
        invocation = '\nrun_control_query "$@"' if control else '\nrun_sqlcmd "" "$@"'
        return subprocess.run([BASH, "-s", "--", *args], input=setup + contract + function + invocation,
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
        self.assertIn('base_sqlcmd_args+=(-C)', SOURCE)
        self.assertIn('parsed+=(-C)', FUNCTION)
        for control in (False, True):
            query = ('SELECT 1',) if control else ('-Q', 'SELECT 1')
            for context in (None, 1):
                result = self.call(*query, purpose='AuthenticatedTls', context=context, control=control)
                self.assertEqual(result.returncode, 65)
                self.assertEqual(result.stdout, '')
            result = self.call(*query, purpose='AuthenticatedTls', context=0, control=control)
            self.assertEqual(result.returncode, 0, result.stderr)

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
        result = self.call('-C', '-Q', 'SELECT 1', purpose='AuthenticatedTls', context=0)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('-C', result.stdout.splitlines())

if __name__ == "__main__":
    unittest.main()
