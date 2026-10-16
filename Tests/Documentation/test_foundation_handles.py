"""Synthetische Root-/Handle-Races ohne Netzwerk oder fremde Dateien."""
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
import subprocess
import sys
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("toolbelt_secure_io_test", ROOT / "Scripts/Security/secure_file_io.py")
IO = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(IO)
sys.path.insert(0, str(ROOT / ".ai/foundation/ai_runtime_adapters"))
import reference_adapters as ADAPTERS


class Handles(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="tbx-handle-contract-")
        self.base = Path(self.directory.name).resolve()
        if self.base.parent != Path(tempfile.gettempdir()).resolve():
            raise AssertionError("SYNTHETIC_TEMP_SCOPE")
        self.root = self.base / "allowed"
        self.outside = self.base / "outside"
        self.root.mkdir()
        self.outside.mkdir()
        (self.root / "input").write_bytes(b"allowed")
        (self.outside / "input").write_bytes(b"outside-sentinel")

    def tearDown(self):
        self.directory.cleanup()

    def test_read_and_atomic_replace(self):
        with IO.open_read(self.root / "input", [self.root]) as handle:
            self.assertEqual(handle.read(), b"allowed")
        target = self.root / "output"
        target.write_bytes(b"old")
        with IO.open_atomic_output(target, [self.root]) as output:
            output.write(b"new")
            self.assertEqual(target.read_bytes(), b"old")
        self.assertEqual(target.read_bytes(), b"new")
        self.assertEqual(sorted(p.name for p in self.root.iterdir()), ["input", "output"])

    def test_exception_preserves_target_and_cleans_stage(self):
        target = self.root / "output"
        target.write_bytes(b"old")
        with self.assertRaisesRegex(RuntimeError, "synthetic"):
            with IO.open_atomic_output(target, [self.root]) as output:
                output.write(b"partial")
                raise RuntimeError("synthetic")
        self.assertEqual(target.read_bytes(), b"old")
        self.assertEqual(sorted(p.name for p in self.root.iterdir()), ["input", "output"])

    def test_external_and_ads_rejected(self):
        for target in [self.outside / "input", self.root / ".." / "outside" / "input", self.root / "input:stream"]:
            with self.subTest(target=target.name):
                with self.assertRaises(IO.SecurePathError):
                    with IO.open_read(target, [self.root]):
                        self.fail("external read")
        self.assertEqual((self.outside / "input").read_bytes(), b"outside-sentinel")

    def test_hardlink_rejected(self):
        try:
            os.link(self.outside / "input", self.root / "linked")
        except OSError:
            self.skipTest("Native hardlink creation unavailable")
        with self.assertRaises(IO.SecurePathError):
            with IO.open_read(self.root / "linked", [self.root]):
                self.fail("hardlink read")

    @unittest.skipUnless(os.name == "nt", "Windows junction contract")
    def test_junction_never_reads_or_writes_outside(self):
        junction = self.root / "junction"
        # Eigene synthetische Pfade als argv; kein Shellinterpolieren.
        result = subprocess.run(["cmd", "/d", "/c", "mklink", "/J", str(junction), str(self.outside)],
                                capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, "synthetic junction setup failed")
        try:
            with self.assertRaises(IO.SecurePathError):
                with IO.open_read(junction / "input", [self.root]):
                    self.fail("junction read")
            with self.assertRaises(IO.SecurePathError):
                with IO.open_atomic_output(junction / "output", [self.root]):
                    self.fail("junction write")
            self.assertFalse((self.outside / "output").exists())
            self.assertEqual((self.outside / "input").read_bytes(), b"outside-sentinel")
        finally:
            # Entfernt ausschließlich den selbst erzeugten Link, niemals rekursiv.
            os.rmdir(junction)

    def test_missing_output_parent_created_within_root(self):
        with IO.open_atomic_output(self.root / "a" / "b" / "output", [self.root]) as output:
            output.write(b"bounded")
        self.assertEqual((self.root / "a" / "b" / "output").read_bytes(), b"bounded")

    def command(self, argv):
        return ADAPTERS.CommandAdapter({
            "provider": "contoso", "execution_boundary": "PROCESS",
            "probe_argv": [sys.executable, "-c", "pass"],
            "catalog_argv": [sys.executable, "-c", "pass"],
            "invoke_argv": argv, "environment_allowlist": [],
            "allowed_data_classes": ["PUBLIC"],
            "read_roots": [str(self.root)], "write_roots": [str(self.root)]})

    def test_command_uses_real_stdin_stdout_handles(self):
        command = self.command([sys.executable, "-c",
            "import sys;sys.stdout.buffer.write(sys.stdin.buffer.read().upper())"])
        result = command.invoke({"operation_id": "contoso-op", "data_class": "PUBLIC",
            "input_path": str(self.root / "input"), "output_path": str(self.root / "output")})
        self.assertEqual((self.root / "output").read_bytes(), b"ALLOWED")
        self.assertEqual(result["output_bytes"], 7)
        self.assertEqual(result["output_sha256"], ADAPTERS.digest_bytes(b"ALLOWED"))

    def test_command_rejects_path_placeholders_before_open(self):
        for placeholder in ["{input_path}", "prefix{output_path}"]:
            command = self.command([sys.executable, placeholder])
            with mock.patch.object(ADAPTERS, "open_read", side_effect=AssertionError("unexpected read")), \
                 mock.patch.object(ADAPTERS, "open_atomic_output", side_effect=AssertionError("unexpected write")):
                with self.assertRaises(ADAPTERS.AdapterError) as failure:
                    command.invoke({"operation_id": "contoso-op", "data_class": "PUBLIC",
                        "input_path": str(self.root / "input"), "output_path": str(self.root / "output")})
                self.assertEqual(failure.exception.code, "HANDLE_PATH_ARGUMENT_UNSUPPORTED")

    def test_input_root_rename_keeps_open_identity(self):
        moved = self.base / "moved"
        with IO.open_read(self.root / "input", [self.root]) as source:
            try:
                self.root.rename(moved)
            except PermissionError:
                self.assertEqual(os.name, "nt")
                self.assertEqual(source.read(), b"allowed")
                return
            self.assertEqual(source.read(), b"allowed")
        moved.rename(self.root)

    def test_output_root_rename_cannot_redirect_write(self):
        moved = self.base / "moved"
        renamed = False
        with IO.open_atomic_output(self.root / "output", [self.root]) as output:
            try:
                self.root.rename(moved)
                renamed = True
            except PermissionError:
                self.assertEqual(os.name, "nt")
            output.write(b"bound")
        self.assertFalse((self.outside / "output").exists())
        self.assertEqual(((moved if renamed else self.root) / "output").read_bytes(), b"bound")
        if renamed:
            moved.rename(self.root)

    @unittest.skipIf(os.name == "nt", "POSIX symlink rendezvous; Windows uses held directory handles")
    def test_swapped_root_symlink_never_reads_or_writes_outside(self):
        moved = self.base / "moved"
        with IO.open_atomic_output(self.root / "output", [self.root]) as output:
            self.root.rename(moved)
            self.root.symlink_to(self.outside, target_is_directory=True)
            output.write(b"bound")
            with self.assertRaises(IO.SecurePathError):
                with IO.open_read(self.root / "input", [self.root]):
                    self.fail("symlink read")
        self.assertFalse((self.outside / "output").exists())
        self.root.unlink()
        moved.rename(self.root)

    @unittest.skipIf(os.name == "nt", "POSIX private staging authority")
    def test_replaced_staging_directory_rejected_before_file_create(self):
        mkdir = os.mkdir
        def replace_stage(name, mode=0o777, *, dir_fd=None):
            mkdir(name, mode, dir_fd=dir_fd)
            if str(name).startswith("tbx-stage-"):
                os.rename(name, name + "-owned", src_dir_fd=dir_fd, dst_dir_fd=dir_fd)
                mkdir(name, 0o777, dir_fd=dir_fd)
                os.chmod(name, 0o777, dir_fd=dir_fd)
        with mock.patch.object(IO.os, "mkdir", side_effect=replace_stage):
            with self.assertRaises(IO.SecurePathError):
                with IO.open_atomic_output(self.root / "output", [self.root]):
                    self.fail("untrusted staging directory accepted")
        self.assertFalse((self.root / "output").exists())
        self.assertEqual((self.outside / "input").read_bytes(), b"outside-sentinel")


if __name__ == "__main__":
    unittest.main()
