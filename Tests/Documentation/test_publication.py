"""Synthetische Publication-Regressionen ohne Netzwerk, SQL oder Releaseerzeugung."""

from __future__ import annotations

import copy
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import publication as p
import validate_documentation as v


class PublicationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.temp.name)
        cls.module_root = cls.root / "Modules/toolbelt.synthetic"
        cls.module_root.mkdir(parents=True)
        cls.manifest_path = "Modules/toolbelt.synthetic/module.yaml"
        cls.manifest = '''module_id: "toolbelt.synthetic"
version: "1.0.0"
sql_server_versions:
  - "2019"
platforms:
  windows: validated
  linux: partially validated
providers:
  - id: default
    platforms: [Windows, Linux]
    status: partially validated
deployment_capabilities:
  local: true
  central: false
clr:
  used: false
'''
        (cls.root / cls.manifest_path).write_text(cls.manifest, encoding="utf-8")
        (cls.module_root / "Source").mkdir()
        (cls.module_root / "Source/Synthetic.sql").write_text("SELECT 1;\n", encoding="utf-8")
        (cls.root / "Evidence.md").write_text("# Freigabe\n\n# Qualifikation\n", encoding="utf-8")
        def git(*args):
            return subprocess.run(["git", "-C", str(cls.root), *args], check=True,
                                  capture_output=True, text=True).stdout.strip()
        git("init", "-q")
        git("add", ".")
        git("-c", "user.name=Contoso", "-c", "user.email=synthetic@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "-qm", "Codex: Synthetic publication fixture")
        cls.commit = git("rev-parse", "HEAD")

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def setUp(self):
        self.module = {"id": "toolbelt.synthetic", "version": "1.0.0", "versions": ["2019"],
                       "implementation_status": "implemented", "validation_status": "partially validated",
                       "release_status": "released", "manifest_path": self.manifest_path,
                       "manifest_text": self.manifest, "root": self.module_root}
        self.record = {"schema_version": "1.0", "module_id": "toolbelt.synthetic", "module_version": "1.0.0",
                       "source_commit": self.commit,
                       "publication": {"url": p.PUBLIC_ROOT + "/releases/tag/synthetic-1.0.0", "tag": "synthetic-1.0.0",
                                       "published_at": "2026-01-01T00:00:00Z", "channel": "released",
                                       "approval_reference": "Evidence.md#freigabe"},
                       "support_scope": [{"sql_server_version": "2019", "platform": "Windows", "provider": "default",
                                          "deployment_mode": "local", "qualification": [
                                              {"reference": "Evidence.md#qualifikation", "method": "Synthetic contract/lifecycle scope",
                                               "executed_on": "2025-12-31", "result": "success"}]}],
                       "limitations": ["Synthetischer Testdatensatz"], "pending_outside_scope": ["Linux offen"],
                       "artifacts": [{"name": "synthetic.dll", "sha256": "a" * 64}]}
        (self.module_root / "Publication.json").write_text(json.dumps(self.record), encoding="utf-8")

    def validate(self):
        return p.validate_record(self.record, self.module, self.root, v.top_scalar, v.top_list, v.section_values)

    def responses(self):
        return [{"draft": False, "tag_name": "synthetic-1.0.0", "html_url": self.record["publication"]["url"],
                 "published_at": "2026-01-01T00:00:00Z", "prerelease": False,
                 "assets": [{"name": "synthetic.dll", "state": "uploaded", "digest": "sha256:" + "a" * 64}]},
                {"ref": "refs/tags/synthetic-1.0.0", "object": {"type": "commit", "sha": self.commit}}]

    def verify(self, responses=None):
        replies = iter(responses or self.responses())
        p.verify_github(self.record, lambda endpoint: next(replies))

    def test_valid_structure_does_not_use_network(self):
        with patch.object(p, "github_get", side_effect=AssertionError("Network")):
            self.validate()

    def test_unreleased_needs_no_record_and_contacts_nothing(self):
        self.module["release_status"] = "unreleased"
        with patch.object(p, "verify_github", side_effect=AssertionError("Network")):
            self.assertEqual(p.validate_publications([self.module], self.root, v.top_scalar,
                             v.top_list, v.section_values, online=True), 0)

    def test_record_is_required_for_published_statuses(self):
        for status in p.PUBLISHED_STATUSES:
            with self.subTest(status=status), self.assertRaises(p.PublicationError):
                self.module["release_status"] = status
                p.validate_publications([self.module], self.root, v.top_scalar, v.top_list, v.section_values)

    def test_record_path_load_and_unreleased_rejection(self):
        self.module["manifest_text"] += 'publication_record: "Publication.json"\n'
        self.assertEqual(p.validate_publications([self.module], self.root, v.top_scalar, v.top_list, v.section_values), 1)
        self.module["release_status"] = "unreleased"
        with self.assertRaises(p.PublicationError):
            p.validate_publications([self.module], self.root, v.top_scalar, v.top_list, v.section_values)

    def test_record_path_escape_and_duplicates(self):
        for declaration in ('publication_record: "../../Evidence.md"\n',
                            'publication_record: "Publication.json"\npublication_record: "Publication.json"\n'):
            with self.subTest(declaration=declaration), self.assertRaises(p.PublicationError):
                self.module["manifest_text"] = self.manifest + declaration
                p.validate_publications([self.module], self.root, v.top_scalar, v.top_list, v.section_values)

    def test_identity_and_source_commit_mismatches(self):
        for field, value in (("module_version", "2.0.0"), ("module_id", "toolbelt.other"),
                             ("source_commit", "f" * 40), ("source_commit", self.commit[:8])):
            with self.subTest(field=field), self.assertRaises(p.PublicationError):
                original = self.record[field]
                self.record[field] = value
                try:
                    self.validate()
                finally:
                    self.record[field] = original
        self.module["version"] = self.record["module_version"] = "2.0.0"
        with self.assertRaises(p.PublicationError):
            self.validate()

    def test_scope_and_qualification_failures(self):
        for key, value in (("sql_server_version", "2025"), ("platform", "Other"),
                           ("provider", "unknown"), ("deployment_mode", "central"), ("qualification", [])):
            record = copy.deepcopy(self.record)
            record["support_scope"][0][key] = value
            with self.subTest(key=key), self.assertRaises(p.PublicationError):
                p.validate_record(record, self.module, self.root, v.top_scalar, v.top_list, v.section_values)
        for key, value in (("result", "failed"), ("executed_on", "2026-01-02"),
                           ("reference", "Evidence.md#absent"), ("reference", "../private.md")):
            record = copy.deepcopy(self.record)
            record["support_scope"][0]["qualification"][0][key] = value
            with self.subTest(key=key), self.assertRaises(p.PublicationError):
                p.validate_record(record, self.module, self.root, v.top_scalar, v.top_list, v.section_values)

    def test_publication_fields_and_hashes(self):
        for key, value in (("url", "https://example.invalid/releases/tag/synthetic-1.0.0"),
                           ("channel", "preview"), ("published_at", "2099-01-01T00:00:00Z"),
                           ("approval_reference", "Evidence.md#absent")):
            record = copy.deepcopy(self.record)
            record["publication"][key] = value
            with self.subTest(key=key), self.assertRaises(p.PublicationError):
                p.validate_record(record, self.module, self.root, v.top_scalar, v.top_list, v.section_values)
        self.record["artifacts"][0]["sha256"] = "not-a-hash"
        with self.assertRaises(p.PublicationError):
            self.validate()

    def test_unknown_and_duplicate_json_keys_rejected(self):
        self.record["unknown"] = True
        with self.assertRaises(p.PublicationError):
            self.validate()
        with self.assertRaises(p.PublicationError):
            json.loads('{"schema_version":"1.0","schema_version":"2.0"}', object_pairs_hook=p.unique_object)

    def test_tree_object_is_not_a_source_commit(self):
        self.record["source_commit"] = subprocess.run(
            ["git", "-C", str(self.root), "rev-parse", "HEAD^{tree}"],
            capture_output=True, text=True, check=True).stdout.strip()
        with self.assertRaises(p.PublicationError):
            self.validate()

    def test_same_version_source_drift_is_not_released(self):
        source = self.module_root / "Source/Synthetic.sql"
        try:
            source.write_text("SELECT 2;\n", encoding="utf-8")
            with self.assertRaises(p.PublicationError):
                self.validate()
        finally:
            source.write_text("SELECT 1;\n", encoding="utf-8")
        extra = self.module_root / "Source/Extra.sql"
        try:
            extra.write_text("SELECT 3;\n", encoding="utf-8")
            with self.assertRaises(p.PublicationError):
                self.validate()
        finally:
            extra.unlink()

    def test_provider_platform_cannot_be_cross_combined(self):
        self.module["manifest_text"] = self.manifest.replace("platforms: [Windows, Linux]", "platforms: [Linux]")
        with self.assertRaises(p.PublicationError):
            self.validate()
        self.module["manifest_text"] = self.manifest.replace("    status: partially validated", "    status: not executed")
        with self.assertRaises(p.PublicationError):
            self.validate()

    def test_duplicate_scope_assets_and_malformed_types(self):
        for key, value in (("support_scope", self.record["support_scope"] * 2),
                           ("artifacts", self.record["artifacts"] * 2), ("limitations", None)):
            record = copy.deepcopy(self.record)
            record[key] = value
            with self.subTest(key=key), self.assertRaises(p.PublicationError):
                p.validate_record(record, self.module, self.root, v.top_scalar, v.top_list, v.section_values)
        self.record["publication"]["channel"] = []
        with self.assertRaises(p.PublicationError):
            self.validate()
        replies = self.responses()
        replies[0]["assets"][0]["name"] = []
        with self.assertRaises(p.PublicationError):
            self.verify(replies)

    def test_online_selection_and_all_local_records_precede_transport(self):
        self.module["manifest_text"] += 'publication_record: "Publication.json"\n'
        with patch.object(p, "verify_github") as verify:
            p.validate_publications([self.module], self.root, v.top_scalar, v.top_list, v.section_values)
            verify.assert_not_called()
            p.validate_publications([self.module], self.root, v.top_scalar, v.top_list, v.section_values, online=True)
            verify.assert_called_once()
        other = dict(self.module, manifest_text=self.manifest)
        with patch.object(p, "verify_github") as verify, self.assertRaises(p.PublicationError):
            p.validate_publications([self.module, other], self.root, v.top_scalar, v.top_list, v.section_values, online=True)
        verify.assert_not_called()

    def test_annotated_tag_depth_and_missing_response_fail_closed(self):
        replies = self.responses()
        replies[1]["object"] = {"type": "tag", "sha": "b" * 40}
        replies.extend([{"object": {"type": "tag", "sha": "b" * 40}}] * 5)
        with self.assertRaises(p.PublicationError):
            self.verify(replies)
        replies = self.responses()
        replies[0] = None
        with self.assertRaises(p.PublicationError):
            self.verify(replies)

    def test_source_only_and_preview(self):
        self.record["artifacts"] = []
        self.module["release_status"] = self.record["publication"]["channel"] = "preview"
        self.validate()
        replies = self.responses()
        replies[0]["prerelease"] = True
        replies[0]["assets"] = []
        self.verify(replies)

    def test_live_release_and_annotated_tag(self):
        self.verify()
        replies = self.responses()
        replies[1]["object"] = {"type": "tag", "sha": "b" * 40}
        replies.append({"object": {"type": "commit", "sha": self.commit}})
        self.verify(replies)

    def test_draft_channel_time_tag_and_asset_mismatches(self):
        mutations = [(0, "draft", True), (0, "prerelease", True), (0, "published_at", "2026-01-02T00:00:00Z"),
                     (0, "html_url", "https://example.invalid/"), (0, "assets", []),
                     (1, "object", {"type": "commit", "sha": "c" * 40}), (1, "ref", "refs/tags/other")]
        for index, key, value in mutations:
            replies = self.responses()
            replies[index][key] = value
            with self.subTest(key=key), self.assertRaises(p.PublicationError):
                self.verify(replies)
        replies = self.responses()
        replies[0]["assets"][0]["digest"] = "sha256:" + "b" * 64
        with self.assertRaisesRegex(p.PublicationError, "PUBLICATION_FAILED"):
            self.verify(replies)
        replies[0]["assets"][0]["digest"] = None
        with self.assertRaisesRegex(p.PublicationError, "PUBLICATION_UNAVAILABLE"):
            self.verify(replies)

    def test_transport_errors_never_pass_or_echo_private_output(self):
        for error in (OSError("private input"), subprocess.TimeoutExpired("private", 30)):
            with patch.object(p.subprocess, "run", side_effect=error), self.assertRaisesRegex(p.PublicationError, "PUBLICATION_UNAVAILABLE"):
                p.github_get("synthetic")
        for code, stderr in ((404, "HTTP 404 private"), (503, "HTTP 503 private")):
            result = subprocess.CompletedProcess([], 1, "private", stderr)
            with patch.object(p.subprocess, "run", return_value=result), self.assertRaises(p.PublicationError) as caught:
                p.github_get("synthetic")
            self.assertNotIn("private", str(caught.exception))
            self.assertIn("FAILED" if code == 404 else "UNAVAILABLE", str(caught.exception))


if __name__ == "__main__":
    unittest.main()
