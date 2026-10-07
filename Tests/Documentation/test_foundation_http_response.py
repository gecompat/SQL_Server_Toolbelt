#!/usr/bin/env python3
"""Begrenzte HTTP-Antwortregression ohne Netzwerk, Provider oder Dateiausgabe."""

from __future__ import annotations

import ast
import builtins
import contextlib
import hashlib
import http.client
import io
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import time
import types
import unittest
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from unittest.mock import patch
import urllib.error
import urllib.parse
import urllib.request


ROOT = Path(__file__).resolve().parents[2]
ADAPTER_PATH = ROOT / ".ai/foundation/ai_runtime_adapters/reference_adapters.py"
PROTOCOL_PATH = ADAPTER_PATH.with_name("adapter_protocol.py")
BASE = "55cce23bc8bcd097de32f4f7ce92dc188ec62466"
CEILING = 128
CHUNK = 17
SCENARIOS = 0


def isolated(source, names, namespace):
    # Ausschließlich originale Definitionen; keine optionalen Imports oder CLI.
    tree = ast.parse(source)
    selected = [node for node in tree.body if isinstance(node, (ast.ClassDef, ast.FunctionDef))
                and node.name in names]
    if {node.name for node in selected} != set(names):
        raise AssertionError("SOURCE_DEFINITIONS_CHANGED")
    module = ast.Module(body=[ast.ImportFrom(module="__future__", names=[
        ast.alias(name="annotations")], level=0)] + selected, type_ignores=[])
    exec(compile(ast.fix_missing_locations(module), "<synthetic-source>", "exec"), namespace)
    return namespace


def load_sources():
    protocol = types.ModuleType("synthetic_http_protocol")
    sys.modules[protocol.__name__] = protocol
    protocol.__dict__.update(dataclass=dataclass, time=time,
                            CONTRACT="foundation-ai-adapter-jsonl/v1",
                            OPERATIONS={"probe", "catalog", "invoke", "cancel", "provision"},
                            FORBIDDEN_RESULT_KEYS={"prompt", "response", "content", "secret", "credential", "token"})
    isolated(PROTOCOL_PATH.read_text(encoding="utf-8"),
             {"AdapterError", "CircuitBreaker", "_content_free", "ProtocolServer"}, protocol.__dict__)
    source = ADAPTER_PATH.read_text(encoding="utf-8")
    namespace = dict(AdapterError=protocol.AdapterError, urllib=urllib, socket=socket,
                     json=json, os=os, Path=Path, hashlib=hashlib, datetime=datetime,
                     timedelta=timedelta, timezone=timezone,
                     ROUTER_CONTRACT="foundation-model-router/v2",
                     BOUNDARIES={"PROCESS", "HOST", "LOCAL_NETWORK", "REMOTE", "UNKNOWN"},
                     DATA_CLASSES={"PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"},
                     MAX_HTTP_RESPONSE_BYTES=CEILING, HTTP_READ_CHUNK_BYTES=CHUNK)
    names = {"_read_http_body", "now", "isoformat", "canonical_json", "digest_bytes", "digest",
             "required_keys", "is_cloud_tag", "NoRedirect", "HttpAdapter", "OllamaAdapter",
             "OpenAICompatibleAdapter"}
    isolated(source, names, namespace)
    # Fester historischer Kontrollstand, begrenzter read-only Git-Aufruf vor Traps.
    result = subprocess.run(["git", "show", BASE + ":.ai/foundation/ai_runtime_adapters/reference_adapters.py"],
                            cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            timeout=2, check=True)
    old_tree = ast.parse(result.stdout.decode("utf-8"))
    old_class = next(node for node in old_tree.body if isinstance(node, ast.ClassDef)
                     and node.name == "HttpAdapter")
    old_request = next(node for node in old_class.body if isinstance(node, ast.FunctionDef)
                       and node.name == "_request")
    old_request.name = "legacy_request"
    legacy = dict(namespace)
    exec(compile(ast.fix_missing_locations(ast.Module(body=[ast.ImportFrom(
        module="__future__", names=[ast.alias(name="annotations")], level=0), old_request],
        type_ignores=[])), "<synthetic-baseline>", "exec"), legacy)
    return source, namespace, protocol, legacy["legacy_request"]


class MemoryResponse:
    def __init__(self, body=b"", *, fragment=None, lazy=False, length=None, close_error=None):
        self.body = body
        self.position = 0
        self.fragment = fragment
        self.lazy = lazy
        self.length = length
        self.close_error = close_error
        self.calls = []
        self.total = 0
        self.closed = False
        self.headers = {"Content-Length": "0"}

    def read(self, n=-1):
        self.calls.append(n)
        # Auch die historische unbeschränkte Kontrolle erhält nur kleine Daten.
        size = n if n >= 0 else len(self.body)
        if self.fragment is not None:
            size = min(size, self.fragment)
        value = b"x" * size if self.lazy else self.body[self.position:self.position + size]
        self.position += len(value)
        self.total += len(value)
        if self.length is not None:
            self.length = max(0, self.length - len(value))
        return value

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.closed = True
        if self.close_error is not None:
            raise self.close_error


class FakeSocket:
    def __init__(self, wire):
        self.stream = io.BytesIO(wire)

    def makefile(self, *_):
        return self.stream


class FakeOpener:
    def __init__(self, response=None, error=None):
        self.response = response
        self.error = error
        self.calls = []

    def open(self, request, timeout):
        self.calls.append((request, timeout))
        if self.error is not None:
            raise self.error
        return self.response


class MemoryInput:
    def read_text(self, *, encoding):
        if encoding != "utf-8":
            raise AssertionError("INPUT_ENCODING_CHANGED")
        return "synthetic Contoso input"


def forbidden(*_, **__):
    raise AssertionError("EXTERNAL_EFFECT_FORBIDDEN")


@contextlib.contextmanager
def effect_traps():
    # Quell-/Fixturelesen ist erlaubt; jede echte Ausgabe und jeder Transport ist gesperrt.
    original_open = builtins.open
    original_io_open = io.open

    def read_only_open(original):
        def guarded(file, mode="r", *args, **kwargs):
            if any(flag in mode for flag in "wax+"):
                forbidden()
            return original(file, mode, *args, **kwargs)
        return guarded

    with contextlib.ExitStack() as stack:
        for owner, name in [(socket, "socket"), (socket, "create_connection"),
                            (socket, "getaddrinfo"), (socket, "gethostbyname"),
                            (urllib.request, "urlopen"), (urllib.request.OpenerDirector, "open"),
                            (http.client.HTTPConnection, "connect"),
                            (http.client.HTTPSConnection, "connect"),
                            (subprocess, "run"), (subprocess, "Popen"), (os, "system"),
                            (os, "open"), (os, "replace"), (os, "remove"), (os, "unlink"),
                            (os, "mkdir"), (tempfile, "mkstemp"), (Path, "write_bytes"),
                            (Path, "write_text"), (Path, "mkdir"), (Path, "unlink")]:
            stack.enter_context(patch.object(owner, name, forbidden))
        stack.enter_context(patch("builtins.open", read_only_open(original_open)))
        stack.enter_context(patch("io.open", read_only_open(original_io_open)))
        yield


class HttpResponseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source, cls.ns, cls.protocol, cls.legacy_request = load_sources()
        cls.error_type = cls.ns["AdapterError"]

    def setUp(self):
        self.traps = effect_traps()
        self.traps.__enter__()
        self.writes = []
        self.ns["safe_path"] = lambda raw, roots, field: MemoryInput() if field == "input_path" else "synthetic-output"
        self.ns["atomic_write"] = lambda path, body: self.writes.append((path, body))

    def tearDown(self):
        self.traps.__exit__(None, None, None)

    def scenario(self):
        global SCENARIOS
        SCENARIOS += 1

    def refusal(self, call, code, error_class="PROTOCOL", retryable=False):
        with self.assertRaises(self.error_type) as caught:
            call()
        self.assertEqual((caught.exception.error_class, caught.exception.code, caught.exception.retryable),
                         (error_class, code, retryable))

    def adapter(self, name, response=None, error=None):
        instance = self.ns[name]({"provider": "contoso", "endpoint": "https://contoso.example",
                                  "execution_boundary": "HOST", "network_authorized": True,
                                  "allowed_data_classes": ["PUBLIC"], "remote_data_classes": ["PUBLIC"],
                                  "read_roots": [], "write_roots": [], "timeout_seconds": 1.25})
        instance.opener = FakeOpener(response, error)
        return instance

    def arguments(self):
        return dict(operation_id="synthetic-operation", model="contoso-model", data_class="PUBLIC",
                    input_path="synthetic-input", output_path="synthetic-output")

    def test_real_constants_and_effect_traps(self):
        tree = ast.parse(self.source)
        values = {}
        for node in tree.body:
            if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
                if node.targets[0].id in {"MAX_HTTP_RESPONSE_BYTES", "HTTP_READ_CHUNK_BYTES"}:
                    values[node.targets[0].id] = eval(compile(ast.Expression(node.value), "<constant>", "eval"), {"__builtins__": {}})
        self.scenario()
        self.assertEqual(values, {"MAX_HTTP_RESPONSE_BYTES": 16 * 1024 * 1024, "HTTP_READ_CHUNK_BYTES": 64 * 1024})
        for call in [lambda: socket.getaddrinfo("fabrikam.example", 443),
                     lambda: urllib.request.urlopen("https://contoso.example"),
                     lambda: subprocess.run(["synthetic"]),
                     lambda: Path("synthetic-output").write_bytes(b"x")]:
            self.scenario()
            with self.assertRaisesRegex(AssertionError, "EXTERNAL_EFFECT_FORBIDDEN"):
                call()

    def test_boundaries_short_reads_and_lazy_overflow(self):
        for size in (0, 1, 127, 128, 129):
            for fragment in (None, 1, 3, 16):
                with self.subTest(size=size, fragment=fragment):
                    self.scenario()
                    response = MemoryResponse(b"x" * size, fragment=fragment)
                    if size > CEILING:
                        self.refusal(lambda: self.ns["_read_http_body"](response), "HTTP_RESPONSE_TOO_LARGE")
                    else:
                        self.assertEqual(self.ns["_read_http_body"](response), b"x" * size)
                    self.assertTrue(response.closed)
                    self.assertLessEqual(response.total, 129)
                    self.assertTrue(all(0 < n <= CHUNK for n in response.calls))
        for fragment in (None, 1, 5):
            self.scenario()
            response = MemoryResponse(lazy=True, fragment=fragment)
            self.refusal(lambda: self.ns["_read_http_body"](response), "HTTP_RESPONSE_TOO_LARGE")
            self.assertEqual(response.total, 129)
            self.assertLessEqual(len(response.calls), 129)
            self.assertTrue(all(0 < n <= CHUNK for n in response.calls))

    def test_real_httpresponse_length_unknown_and_chunked(self):
        for framing in ("length", "unknown", "chunked"):
            for size in (127, 128, 129):
                self.scenario()
                body = b"x" * size
                if framing == "length":
                    headers = f"Content-Length: {size}\r\n".encode("ascii")
                elif framing == "chunked":
                    headers = b"Transfer-Encoding: chunked\r\n"
                    body = f"{size:x}\r\n".encode("ascii") + body + b"\r\n0\r\n\r\n"
                else:
                    headers = b""
                response = http.client.HTTPResponse(FakeSocket(b"HTTP/1.1 200 OK\r\n" + headers + b"\r\n" + body))
                response.begin()
                if size > CEILING:
                    self.refusal(lambda: self.ns["_read_http_body"](response), "HTTP_RESPONSE_TOO_LARGE")
                else:
                    self.assertEqual(self.ns["_read_http_body"](response), b"x" * size)
                self.assertTrue(response.closed)
        self.scenario()
        response = http.client.HTTPResponse(FakeSocket(b"HTTP/1.1 200 OK\r\nContent-Length: 9\r\n\r\n{}"))
        response.begin()
        adapter = self.adapter("OllamaAdapter", response)
        with patch.object(json, "loads", wraps=json.loads) as loads:
            self.refusal(lambda: adapter._request("/api/version"), "HTTP_RESPONSE_INCOMPLETE")
            self.assertEqual(loads.call_count, 0)
        self.assertTrue(response.closed)

    def test_headers_do_not_bypass_and_json_not_parsed_on_overflow(self):
        for header in ("0", "1", "999999999999", "invalid"):
            self.scenario()
            response = MemoryResponse(b" " * 127 + b"{}")
            response.headers["Content-Length"] = header
            adapter = self.adapter("OpenAICompatibleAdapter", response)
            with patch.object(json, "loads", wraps=json.loads) as loads:
                self.refusal(lambda: adapter._request("/v1/models"), "HTTP_RESPONSE_TOO_LARGE")
                self.assertEqual(loads.call_count, 0)
            self.assertEqual(response.total, 129)
            self.assertEqual(adapter.opener.calls[0][1], 1.25)

    def test_close_error_priority_and_original_read_error(self):
        for code, body, length in [("HTTP_RESPONSE_TOO_LARGE", b"x" * 129, None),
                                   ("HTTP_RESPONSE_INCOMPLETE", b"{}", 9)]:
            for close_error in (OSError("synthetic"), TimeoutError("synthetic")):
                self.scenario()
                response = MemoryResponse(body, length=length, close_error=close_error)
                self.refusal(lambda: self.ns["_read_http_body"](response), code)
                self.assertTrue(response.closed)
        for original in (OSError("synthetic"), TimeoutError("synthetic")):
            self.scenario()
            response = MemoryResponse(b"{}", close_error=original)
            with self.assertRaises(type(original)) as caught:
                self.ns["_read_http_body"](response)
            self.assertIs(caught.exception, original)
        self.scenario()
        original = OSError("synthetic-read")
        response = MemoryResponse()
        response.read = lambda n: (_ for _ in ()).throw(original)
        with self.assertRaises(OSError) as caught:
            self.ns["_read_http_body"](response)
        self.assertIs(caught.exception, original)
        self.assertTrue(response.closed)

    def test_request_existing_error_categories(self):
        errors = [(urllib.error.HTTPError("https://contoso.example", 401, "synthetic", {}, None), "CREDENTIAL", "HTTP_401", False),
                  (urllib.error.HTTPError("https://contoso.example", 403, "synthetic", {}, None), "CREDENTIAL", "HTTP_403", False),
                  (urllib.error.HTTPError("https://contoso.example", 500, "synthetic", {}, None), "PROTOCOL", "HTTP_500", True),
                  (TimeoutError("synthetic"), "TIMEOUT", "HTTP_TIMEOUT", True),
                  (urllib.error.URLError(TimeoutError("synthetic")), "TIMEOUT", "HTTP_TIMEOUT", True),
                  (urllib.error.URLError("synthetic"), "AVAILABILITY", "ENDPOINT_UNAVAILABLE", True)]
        for name in ("OllamaAdapter", "OpenAICompatibleAdapter"):
            for error, category, code, retryable in errors:
                self.scenario()
                adapter = self.adapter(name, error=error)
                self.refusal(lambda: adapter._request("/synthetic"), code, category, retryable)
            self.scenario()
            adapter = self.adapter(name, MemoryResponse(b"{"))
            self.refusal(lambda: adapter._request("/synthetic"), "INVALID_JSON_RESPONSE")

    def test_public_methods_overflow_no_output_and_protocol_breaker(self):
        for name in ("OllamaAdapter", "OpenAICompatibleAdapter"):
            for code, response_factory in [("HTTP_RESPONSE_TOO_LARGE", lambda: MemoryResponse(b"x" * 129)),
                                           ("HTTP_RESPONSE_INCOMPLETE", lambda: MemoryResponse(b"{}", length=9))]:
                for operation in ("probe", "catalog", "invoke"):
                    self.scenario()
                    adapter = self.adapter(name, response_factory())
                    arguments = self.arguments() if operation == "invoke" else {}
                    if operation == "probe":
                        result = adapter.probe(arguments)
                        self.assertEqual((result["health"]["state"], result["health"]["reason_code"]),
                                         ("UNAVAILABLE", code))
                    else:
                        self.refusal(lambda: getattr(adapter, operation)(arguments), code)
                    self.assertEqual(self.writes, [])
                self.scenario()
                adapter = self.adapter(name, response_factory())
                server = self.protocol.ProtocolServer(adapter)
                frame = dict(protocol=self.protocol.CONTRACT, request_id="synthetic-request",
                             operation="invoke", arguments=self.arguments())
                for count in (1, 2, 3):
                    adapter.opener.response = response_factory()
                    result = server.handle(frame)
                    self.assertEqual(result["status"], "ERROR")
                    self.assertEqual(result["error"]["code"], code)
                    self.assertFalse(result["error"]["retryable"])
                    self.assertEqual(server.breaker.consecutive_failures, count)
                calls = len(adapter.opener.calls)
                self.assertEqual(server.handle(frame)["error"]["code"], "CIRCUIT_OPEN")
                self.assertEqual(len(adapter.opener.calls), calls)
                self.assertEqual(self.writes, [])
                adapter.opener.response = response_factory()
                frame["operation"], frame["arguments"] = "probe", {}
                result = server.handle(frame)
                self.assertEqual(result["status"], "OK")
                self.assertEqual(result["result"]["health"]["state"], "UNAVAILABLE")
                self.assertEqual(server.breaker.consecutive_failures, 4)

    def test_success_public_output_unchanged(self):
        for name, catalog_body in [("OllamaAdapter", b'{"models":[{"name":"contoso-model"}]}'),
                                   ("OpenAICompatibleAdapter", b'{"data":[{"id":"contoso-model"}]}')]:
            self.scenario()
            adapter = self.adapter(name, MemoryResponse(b"{}", fragment=1))
            self.assertEqual(adapter.probe({})["health"]["state"], "HEALTHY")
            self.scenario()
            adapter.opener.response = MemoryResponse(catalog_body, fragment=3)
            catalog = adapter.catalog({})
            self.assertIn("contoso-model", catalog["fragments"][0]["models"])
            self.scenario()
            payload = {"model": "contoso-model", "choices": []}
            body = self.ns["canonical_json"](payload) + b"\n"
            adapter.opener.response = MemoryResponse(json.dumps(payload).encode("utf-8"), fragment=2)
            self.writes.clear()
            result = adapter.invoke(self.arguments())
            self.assertEqual(self.writes, [("synthetic-output", body)])
            self.assertEqual((result["status"], result["output_bytes"], result["output_sha256"], result["dispatch_status"]),
                             ("COMPLETED", len(body), "sha256:" + hashlib.sha256(body).hexdigest(), "ACTUAL_MODEL_ATTESTED"))
            request, timeout = adapter.opener.calls[-1]
            self.assertEqual((request.get_method(), timeout), ("POST", 1.25))
            self.assertEqual(json.loads(request.data)["messages"], [{"role": "user", "content": "synthetic Contoso input"}])

    def test_fixed_base_negative_witness(self):
        # Kein kopierter neuer Produktkern: tatsächlicher alter Methodenkörper.
        for name in ("OllamaAdapter", "OpenAICompatibleAdapter"):
            self.scenario()
            payload = b" " * 127 + b"{}"
            old_response = MemoryResponse(payload)
            adapter = self.adapter(name, old_response)
            adapter._request = types.MethodType(type(self).legacy_request, adapter)
            self.writes.clear()
            result = adapter.invoke(self.arguments())
            self.assertEqual(old_response.calls, [-1])
            self.assertEqual(old_response.total, 129)
            self.assertEqual(result["status"], "COMPLETED")
            self.assertEqual(self.writes, [("synthetic-output", b"{}\n")])
            self.writes.clear()
            adapter = self.adapter(name, MemoryResponse(payload))
            self.refusal(lambda: adapter.invoke(self.arguments()), "HTTP_RESPONSE_TOO_LARGE")
            self.assertEqual(self.writes, [])


def main():
    # Nur feste synthetische Zähler/Methodennamen; keine Trace-/Payloadausgabe.
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(HttpResponseTests)
    result = unittest.TextTestRunner(stream=io.StringIO(), verbosity=0).run(suite)
    if not result.wasSuccessful():
        names = sorted({case.id().split(".")[-1].split(" ")[0]
                        for case, _ in result.errors + result.failures})
        print("FOUNDATION_HTTP_RESPONSE_FAILED methods=" + ",".join(names))
        return 1
    print(f"FOUNDATION_HTTP_RESPONSE_PASS methods={result.testsRun} scenarios={SCENARIOS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
