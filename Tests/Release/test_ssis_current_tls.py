"""Manipulationsgegenproben zur echten, getrennt ausgeführten Windows-TLS-Abnahme."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("ssis_tls", ROOT / "Scripts/Release/validate_ssis_current_tls.py")
tls = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(tls)


class TlsEvidence(unittest.TestCase):
    def setUp(self):
        self.record = json.loads((ROOT / tls.REPORT).read_text(encoding="utf-8"))

    def reject(self, mutate):
        changed = copy.deepcopy(self.record)
        mutate(changed)
        with self.assertRaises(ValueError):
            tls.validate(ROOT, changed, check_files=False)

    def test_actual_record_and_current_artifact_binding(self):
        tls.validate(ROOT)

    def test_missing_context(self):
        self.reject(lambda r: r["cases"].pop())

    def test_duplicate_context(self):
        self.reject(lambda r: r["cases"].__setitem__(1, copy.deepcopy(r["cases"][0])))

    def test_wrong_sql_build(self):
        self.reject(lambda r: r["lab"].update(sql_build="17.0.5005.3"))

    def test_container_is_not_a_windows_vm(self):
        self.reject(lambda r: r["lab"].update(provider="docker"))

    def test_certificate_bypass(self):
        self.reject(lambda r: r["transport"].update(trust_server_certificate=True))

    def test_zero_is_not_boolean_false(self):
        self.reject(lambda r: r["transport"].update(trust_server_certificate=0))

    def test_unencrypted_transport(self):
        self.reject(lambda r: r["transport"].update(encrypt=False))

    def test_pooling_or_retry(self):
        self.reject(lambda r: r["transport"].update(pooling=True))
        self.reject(lambda r: r["transport"].update(connect_retry_count=1))

    def test_stale_or_different_snapshot(self):
        self.reject(lambda r: r["transport"].update(fresh_lab_reader_before_every_open=False))
        self.reject(lambda r: r["transport"].update(same_export_bytes=False))

    def test_forged_assertion_count(self):
        self.reject(lambda r: r["cases"][0].update(assertions=True))
        self.reject(lambda r: r.update(assertions=413))

    def test_no_fabricated_wire_fingerprint(self):
        self.reject(lambda r: r["transport"].update(wire_certificate_fingerprint="observed"))

    def test_cleanup_required(self):
        self.reject(lambda r: r["cleanup"].update(own_vm_absent=False))
        self.reject(lambda r: r["cleanup"].update(host_root_trust_unchanged=False))

    def test_original_failed_create_is_retained(self):
        self.reject(lambda r: r["attempt_history"].update(uninterrupted_public_create_pass_claimed=True))
        self.reject(lambda r: r["attempt_history"].update(original_failures_retained=False))

    def test_guard_required(self):
        self.reject(lambda r: r["guarded_connections"].update(target=0))
        self.reject(lambda r: r["guarded_connections"].update(target=4))

    def test_missing_executed_method(self):
        self.reject(lambda r: r["source_sha256"].pop(next(iter(r["source_sha256"]))))

    def test_private_runtime_field_rejected(self):
        self.reject(lambda r: r.update(endpoint="localhost"))
        self.reject(lambda r: r["lab"].update(vm_id="synthetic"))

    def test_publication_not_authorized(self):
        self.reject(lambda r: r.update(publication_authorized=True))

    def test_other_support_gates_stay_separate(self):
        self.reject(lambda r: r["separate_gates"].remove("hard host/transport interruption"))


if __name__ == "__main__":
    unittest.main()
