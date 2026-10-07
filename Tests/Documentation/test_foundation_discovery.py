#!/usr/bin/env python3
"""Discovery-Grenztests mit echtem urllib und ausschließlich synthetischen Bytes."""

from __future__ import annotations

import ast
import builtins
import contextlib
from datetime import datetime, timezone
import http.client
import io
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import urllib.error
import urllib.parse
import urllib.request


ROOT = Path(__file__).resolve().parents[2]
DIRECTORY = ROOT / ".ai/foundation/ai_runtime_adapters"
BASE = "cbd75e285a454adc0eceee82302add01c6c50fb4"
CEILING, CHUNK = 128, 17
ENDPOINT = "https://contoso.example"
DEFAULT = "http://127.0.0.1:11434"
SCENARIOS = 0
BUILD_OPENER = urllib.request.build_opener


def isolated(source, names, namespace):
    # Keine vollständigen Modulimports, Konfigurationszugriffe oder CLI-Starts.
    selected = [node for node in ast.parse(source).body
                if isinstance(node, (ast.FunctionDef, ast.ClassDef)) and node.name in names]
    if {node.name for node in selected} != names:
        raise AssertionError("SOURCE_DEFINITIONS_CHANGED")
    tree = ast.Module(body=[ast.ImportFrom(module="__future__", names=[
        ast.alias(name="annotations")], level=0)] + selected, type_ignores=[])
    exec(compile(ast.fix_missing_locations(tree), "<synthetic-source>", "exec"), namespace)


def load_sources():
    namespace = dict(urllib=urllib, http=http, contextlib=contextlib, json=json, os=os,
                     datetime=datetime, timezone=timezone, MAX_HTTP_RESPONSE_BYTES=CEILING,
                     HTTP_READ_CHUNK_BYTES=CHUNK, DEFAULT_OLLAMA_ENDPOINT=DEFAULT)
    isolated((DIRECTORY / "adapter_protocol.py").read_text(encoding="utf-8"), {"AdapterError"}, namespace)
    adapter_source = (DIRECTORY / "reference_adapters.py").read_text(encoding="utf-8")
    isolated(adapter_source, {"_read_http_body", "NoRedirect"}, namespace)
    isolated((DIRECTORY / "runtime_configuration.py").read_text(encoding="utf-8"),
             {"utc_now", "_probe_candidate", "discover_candidates"}, namespace)
    # Read-only, feste Commitbindung und 2-s-Grenze vor allen Transportfallen.
    previous = subprocess.run(["git", "show", BASE + ":.ai/foundation/ai_runtime_adapters/runtime_configuration.py"],
                              cwd=ROOT, timeout=2, check=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    old = dict(namespace)
    isolated(previous.stdout.decode("utf-8"), {"_probe_candidate"}, old)
    return namespace, adapter_source, old["_probe_candidate"]


def forbidden(*_, **__):
    raise AssertionError("EXTERNAL_EFFECT_FORBIDDEN")


@contextlib.contextmanager
def traps():
    originals = {builtins: builtins.open, io: io.open}
    def read_only(original):
        def guarded(file, mode="r", *args, **kwargs):
            if any(flag in mode for flag in "wax+"):
                forbidden()
            return original(file, mode, *args, **kwargs)
        return guarded
    with contextlib.ExitStack() as stack:
        for owner, name in [(socket, "socket"), (socket, "create_connection"),
                            (socket, "getaddrinfo"), (socket, "gethostbyname"),
                            (http.client.HTTPConnection, "connect"), (http.client.HTTPSConnection, "connect"),
                            (urllib.request.HTTPHandler, "http_open"),
                            (urllib.request.HTTPSHandler, "https_open"), (urllib.request, "urlopen"),
                            (subprocess, "run"), (subprocess, "Popen"), (os, "system"),
                            (os, "open"), (os, "replace"), (os, "unlink"), (os, "remove"), (os, "mkdir"),
                            (tempfile, "mkstemp"), (Path, "write_bytes"), (Path, "write_text"),
                            (Path, "mkdir"), (Path, "unlink")]:
            stack.enter_context(patch.object(owner, name, forbidden))
        for owner, original in originals.items():
            stack.enter_context(patch.object(owner, "open", read_only(original)))
        yield


class FakeSocket:
    def __init__(self, wire):
        self.stream = io.BytesIO(wire)
    def makefile(self, *_):
        return self.stream


class ObservedResponse:
    # Der reale HTTPResponse-Parser bleibt intakt; nur Transport und Beobachtung.
    def __init__(self, body=b"{}", *, status=200, framing="length", declared=None,
                 location=None, fragment=None, lazy=False, close_error=None):
        headers = b""
        if framing == "length":
            headers += f"Content-Length: {len(body) if declared is None else declared}\r\n".encode("ascii")
        elif framing == "chunked":
            headers += b"Transfer-Encoding: chunked\r\n"
            body = f"{len(body):x}\r\n".encode("ascii") + body + b"\r\n0\r\n\r\n"
        if location is not None:
            headers += b"Location: " + location.encode("ascii") + b"\r\n"
        self.raw = http.client.HTTPResponse(FakeSocket(
            f"HTTP/1.1 {status} Synthetic\r\n".encode("ascii") + headers + b"\r\n" + body))
        self.raw.begin()
        self.status = self.code = status
        self.msg = self.raw.reason
        self.headers = self.raw.headers
        self.fragment, self.lazy, self.close_error = fragment, lazy, close_error
        self.reads = []
        self.total = 0
        self.closes = 0
        self.url = ""

    @property
    def length(self):
        return None if self.lazy else self.raw.length

    def read(self, n=-1):
        self.reads.append(n)
        size = min(n, self.fragment) if n >= 0 and self.fragment is not None else n
        value = b"x" * size if self.lazy else self.raw.read(size)
        self.total += len(value)
        return value

    def close(self):
        self.closes += 1
        # Nach dem wirklich erfolgten Close ist auch die Fehlercanary idempotent.
        if self.raw.closed:
            return
        self.raw.close()
        if self.close_error:
            raise self.close_error

    def info(self):
        return self.headers

    def geturl(self):
        return self.url

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()


class FakeHandler(urllib.request.HTTPHandler, urllib.request.HTTPSHandler):
    # Beide nativen Transporthandler ersetzen, damit build_opener auch keinen
    # unbenutzten echten TLSContext oder native Zertifikatkonfiguration erzeugt.
    handler_order = 100
    def __init__(self, routes):
        self.routes = routes
        self.contacts = []
    def http_open(self, request):
        self.contacts.append((request.full_url, request.timeout))
        response = self.routes.get(request.full_url)
        if response is None:
            forbidden()
        if isinstance(response, Exception):
            raise response
        response.url = request.full_url
        return response
    https_open = http_open


class DiscoveryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ns, cls.adapter_source, cls.old_probe = load_sources()

    def setUp(self):
        self.stack = contextlib.ExitStack()
        self.stack.enter_context(traps())
        self.stack.enter_context(patch.dict(os.environ, {}, clear=True))

    def tearDown(self):
        self.stack.close()

    def scenario(self):
        global SCENARIOS
        SCENARIOS += 1

    @contextlib.contextmanager
    def transport(self, routes):
        handler = FakeHandler(routes)
        def factory(*handlers):
            return BUILD_OPENER(urllib.request.ProxyHandler({}), handler, *handlers)
        with patch.object(urllib.request, "build_opener", factory):
            try:
                yield handler
            finally:
                # Auch unbesuchte eigene Route-Handles deterministisch schließen;
                # urllib hält Handler/Opener-Zyklen bis zur späteren GC fest.
                for response in {id(value): value for value in routes.values()
                                 if isinstance(value, ObservedResponse)}.values():
                    response.close()

    def shape(self, row, endpoint, state):
        self.assertEqual(set(row), {"adapter", "endpoint", "state", "checked_at", "version"})
        self.assertEqual((row["adapter"], row["endpoint"], row["state"]), ("ollama", endpoint, state))
        self.assertIsInstance(row["checked_at"], str)
        datetime.fromisoformat(row["checked_at"])
        if state == "UNAVAILABLE":
            self.assertIsNone(row["version"])

    def probe(self, response, state):
        with self.transport({ENDPOINT + "/api/version": response}) as handler:
            row = self.ns["_probe_candidate"](ENDPOINT, 0.125)
        self.shape(row, ENDPOINT, state)
        self.assertEqual(handler.contacts, [(ENDPOINT + "/api/version", 0.125)])
        self.assertGreaterEqual(response.closes, 1)
        self.assertTrue(response.raw.closed)
        return row

    def test_constants_and_traps(self):
        self.scenario()
        constants = {}
        for node in ast.parse(self.adapter_source).body:
            if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
                if node.targets[0].id in {"MAX_HTTP_RESPONSE_BYTES", "HTTP_READ_CHUNK_BYTES"}:
                    constants[node.targets[0].id] = eval(compile(ast.Expression(node.value), "<constant>", "eval"), {"__builtins__": {}})
        self.assertEqual(constants, {"MAX_HTTP_RESPONSE_BYTES": 16 * 1024 * 1024, "HTTP_READ_CHUNK_BYTES": 64 * 1024})
        for call in (lambda: socket.getaddrinfo("fabrikam.example", 443),
                     lambda: urllib.request.urlopen("https://contoso.example"),
                     lambda: subprocess.run(["synthetic"]),
                     lambda: Path("synthetic-output").write_bytes(b"x")):
            self.scenario()
            with self.assertRaisesRegex(AssertionError, "EXTERNAL_EFFECT_FORBIDDEN"):
                call()

    def test_real_framing_boundaries_and_incomplete_eof(self):
        for framing in ("length", "unknown", "chunked"):
            for size in (127, 128, 129):
                self.scenario()
                response = ObservedResponse(b"{}" + b" " * (size - 2), framing=framing)
                with patch.object(json, "loads", wraps=json.loads) as loads:
                    self.probe(response, "HEALTHY" if size <= CEILING else "UNAVAILABLE")
                    self.assertEqual(loads.call_count, 1 if size <= CEILING else 0)
                self.assertTrue(all(0 < n <= CHUNK for n in response.reads))
                self.assertLessEqual(response.total, 129)
        self.scenario()
        response = ObservedResponse(b"{}", declared=9)
        with patch.object(json, "loads", wraps=json.loads) as loads:
            self.probe(response, "UNAVAILABLE")
            self.assertEqual(loads.call_count, 0)
        self.scenario()
        response = ObservedResponse(b"{}", framing="unknown")
        # Echte chunked-Abtrennung unterhalb des Limits, kein voller Bodyread.
        response.raw.close()
        response.raw = http.client.HTTPResponse(FakeSocket(
            b"HTTP/1.1 200 Synthetic\r\nTransfer-Encoding: chunked\r\n\r\n5\r\n{}"))
        response.raw.begin()
        self.probe(response, "UNAVAILABLE")

    def test_fragments_lazy_invalid_payload_and_close_priority(self):
        for fragment in (1, 5):
            self.scenario()
            response = ObservedResponse(b'{"version":"synthetic"}', fragment=fragment)
            self.assertEqual(self.probe(response, "HEALTHY")["version"], "synthetic")
        self.scenario()
        response = ObservedResponse(framing="unknown", lazy=True, fragment=1)
        with patch.object(json, "loads", wraps=json.loads) as loads:
            self.probe(response, "UNAVAILABLE")
            self.assertEqual(loads.call_count, 0)
        self.assertEqual((response.total, len(response.reads)), (129, 129))
        self.assertTrue(all(0 < n <= CHUNK for n in response.reads))
        for body in (b"{", b"\xff", b"\xff\xfe\x00"):
            self.scenario()
            self.probe(ObservedResponse(body), "UNAVAILABLE")
        for body, length in ((b"x" * 129, None), (b"{}", 9)):
            self.scenario()
            response = ObservedResponse(body, declared=length, close_error=OSError("synthetic-close"))
            with patch.object(json, "loads", wraps=json.loads) as loads:
                self.probe(response, "UNAVAILABLE")
                self.assertEqual(loads.call_count, 0)
        self.scenario()
        self.probe(ObservedResponse(b"{}", close_error=OSError("synthetic-close")), "UNAVAILABLE")

    def test_redirects_refused_without_bodyread_even_if_close_fails(self):
        for status in (301, 302, 303, 307, 308):
            for location in ("https://fabrikam.example/api/version", "/relative"):
                for close_error in (None, OSError("synthetic-close")):
                    self.scenario()
                    response = ObservedResponse(b"synthetic-canary", status=status,
                                                location=location, close_error=close_error)
                    self.probe(response, "UNAVAILABLE")
                    self.assertEqual(response.reads, [])
                    self.assertEqual(response.total, 0)

    def test_existing_transport_error_resultshape(self):
        for error in (TimeoutError("synthetic"), urllib.error.URLError("synthetic"), OSError("synthetic")):
            self.scenario()
            with self.transport({ENDPOINT + "/api/version": error}) as handler:
                row = self.ns["_probe_candidate"](ENDPOINT, 0.25)
            self.shape(row, ENDPOINT, "UNAVAILABLE")
            self.assertEqual(handler.contacts, [(ENDPOINT + "/api/version", 0.25)])

    def proposal_shape(self, row):
        self.assertEqual(set(row), {"adapter", "endpoint", "state", "checked_at", "version", "source",
                                    "proposal_only", "requires_confirmation"})
        self.assertTrue(row["proposal_only"])
        self.assertEqual(row["requires_confirmation"],
                         ["execution_boundary", "network_authorized", "data_classes", "remote_models"])

    def test_probe_false_has_no_contacts(self):
        for configured in (None, DEFAULT, "127.0.0.1:11434/", "http://localhost:11434", ENDPOINT):
            self.scenario()
            with patch.dict(os.environ, {} if configured is None else {"OLLAMA_HOST": configured}, clear=True):
                with self.transport({}) as handler:
                    rows = self.ns["discover_candidates"](probe=False)
            self.assertEqual(handler.contacts, [])
            self.assertEqual(len(rows), 1 if configured in (None, DEFAULT, "127.0.0.1:11434/") else 2)
            for row in rows:
                self.proposal_shape(row)
                self.assertEqual((row["state"], row["checked_at"], row["version"]), ("NOT_PROBED", None, None))

    def test_default_dedup_and_remote_authorization(self):
        for configured in (None, DEFAULT + "/", "127.0.0.1:11434", "http://localhost:11434", ENDPOINT):
            self.scenario()
            routes = {DEFAULT + "/api/version": ObservedResponse(b'{"version":"synthetic"}'),
                      "http://localhost:11434/api/version": ObservedResponse(b"{}")}
            with patch.dict(os.environ, {} if configured is None else {"OLLAMA_HOST": configured}, clear=True):
                with self.transport(routes) as handler:
                    rows = self.ns["discover_candidates"](probe=True, timeout=0.375)
            expected = ["http://localhost:11434/api/version", DEFAULT + "/api/version"] if configured == "http://localhost:11434" else [DEFAULT + "/api/version"]
            self.assertEqual(handler.contacts, [(url, 0.375) for url in expected])
            self.assertEqual(len(rows), 2 if configured in ("http://localhost:11434", ENDPOINT) else 1)
            for row in rows:
                self.proposal_shape(row)
                self.assertEqual(row["source"], "OLLAMA_HOST" if configured and row is rows[0] else "SAFE_LOOPBACK_DEFAULT")
                self.assertEqual(row["state"], "AUTHORIZATION_REQUIRED" if row["endpoint"] == ENDPOINT else "HEALTHY")
                if row["endpoint"] == ENDPOINT:
                    self.assertIsNone(row["checked_at"])
                    self.assertIsNone(row["version"])

    def test_fixed_base_negative_controls(self):
        self.scenario()
        response = ObservedResponse(b"{}" + b" " * 127)
        with self.transport({ENDPOINT + "/api/version": response}) as handler:
            opener = BUILD_OPENER(urllib.request.ProxyHandler({}), handler)
            with patch.object(urllib.request, "urlopen", opener.open):
                row = type(self).old_probe(ENDPOINT, 0.125)
        self.shape(row, ENDPOINT, "HEALTHY")
        self.assertEqual(response.reads, [-1])
        self.assertEqual(response.total, 129)
        self.scenario()
        response = ObservedResponse(b"synthetic-canary", status=302,
                                    location="https://fabrikam.example/api/version")
        target = ObservedResponse(b"{}")
        with self.transport({ENDPOINT + "/api/version": response,
                             "https://fabrikam.example/api/version": target}) as handler:
            opener = BUILD_OPENER(urllib.request.ProxyHandler({}), handler)
            with patch.object(urllib.request, "urlopen", opener.open):
                row = type(self).old_probe(ENDPOINT, 0.125)
        self.shape(row, ENDPOINT, "HEALTHY")
        self.assertEqual(handler.contacts, [(ENDPOINT + "/api/version", 0.125),
                                           ("https://fabrikam.example/api/version", 0.125)])
        self.assertEqual(response.reads, [-1])
        self.assertGreaterEqual(response.closes, 1)


def main():
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(DiscoveryTests)
    result = unittest.TextTestRunner(stream=io.StringIO(), verbosity=0).run(suite)
    if not result.wasSuccessful():
        names = sorted({case.id().split(".")[-1].split(" ")[0]
                        for case, _ in result.errors + result.failures})
        print("FOUNDATION_DISCOVERY_FAILED methods=" + ",".join(names))
        return 1
    print(f"FOUNDATION_DISCOVERY_PASS methods={result.testsRun} scenarios={SCENARIOS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
