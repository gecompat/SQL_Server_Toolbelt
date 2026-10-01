"""Synthetische unabhängige V1-Referenz, kein SQL-Server-Runtimenachweis."""
from hashlib import sha256
import json

U = 1 << 64
MIN = -(1 << 63)
MAX = (1 << 63) - 1


def frame(key, version, seed, lower, upper, attempt, domain=b"TBXDRNG1", context=0):
    return (domain + context.to_bytes(8, "big", signed=True)
            + version.to_bytes(4, "big", signed=True)
            + seed.to_bytes(8, "big", signed=True)
            + lower.to_bytes(8, "big", signed=True)
            + upper.to_bytes(8, "big", signed=True)
            + len(key).to_bytes(4, "big") + key + attempt.to_bytes(4, "big"))


def select_candidate(candidates, lower, upper):
    span = upper - lower + 1
    limit = U - U % span
    for attempt, candidate in enumerate(candidates):
        if attempt == 128:
            break
        if candidate < limit:
            return lower + candidate % span, attempt
    return None, None


def mapping(key, version, seed, lower, upper):
    candidates = (int.from_bytes(sha256(frame(key, version, seed, lower, upper, i)).digest()[:8], "big")
                  for i in range(128))
    return select_candidate(candidates, lower, upper)


def run():
    expected_values = [-9, 4631573001509251638, MIN, -57910, -2303072262022855583]
    expected_attempts = [0, 0, 0, 0, 2]
    cases = [(b"\x01\x02\x03", 1, 0, -10, 10),
             (b"\x00", 1, MIN, MIN, MAX),
             (b"\xff\x00", 2147483647, MAX, MIN, MIN),
             (b"synthetic-range", 42, -17, -99999, -1),
             (b"\x00" * 8000, 1, 0, MIN, 0)]
    vectors = []
    for index, (key, version, seed, lower, upper) in enumerate(cases):
        value, attempt = mapping(key, version, seed, lower, upper)
        assert (value, attempt) == (expected_values[index], expected_attempts[index])
        assert value is not None and lower <= value <= upper
        vectors.append(dict(key_hex=key.hex() if len(key) < 20 else None,
                            key_repeat_zero_bytes=len(key) if len(key) >= 20 else None,
                            mapping_version=version, seed=seed, lower=lower, upper=upper,
                            value=value, attempt=attempt,
                            digest_hex=sha256(frame(key, version, seed, lower, upper, attempt)).hexdigest()))
    # Algorithmusgrenzen unabhängig vom Hash erzwingen; kein SQL-Livetest.
    span = (1 << 63) + 1
    limit = U - U % span
    assert select_candidate([limit, limit - 1], MIN, 0) == (0, 1)
    assert select_candidate([limit] * 128, MIN, 0) == (None, None)
    assert select_candidate([limit] * 128 + [0], MIN, 0) == (None, None)
    assert select_candidate([U - 1], MIN, MAX) == (MAX, 0)
    assert select_candidate([0], MIN, MAX) == (MIN, 0)
    # SQL-Encoderdesign unabhängig gegen vorzeichenbehaftete Python-Bytes prüfen.
    for value in [MIN, MIN + 1, -257, -256, -255, -17, -16, -15, -1, 0, 1, 15, 16, 255, 256, MAX]:
        hex_digits = "0123456789ABCDEF"
        encoded = hex_digits[((value & 8070450532247928832) // 1152921504606846976) + (8 if value < 0 else 0)]
        for nibble in range(14, -1, -1):
            power = 16 ** nibble
            encoded += hex_digits[(value & (15 * power)) // power]
        assert bytes.fromhex(encoded) == value.to_bytes(8, "big", signed=True)
    for i in range(2048):
        key = i.to_bytes(4, "big")
        for lower, upper in [(MIN, MAX), (MIN, 0), (0, MAX), (-1, 1), (-17, -3), (MAX, MAX)]:
            value, attempt = mapping(key, 1, MIN + i, lower, upper)
            assert value is not None and lower <= value <= upper and 0 <= attempt < 128
            assert mapping(key, 1, MIN + i, lower, upper) == (value, attempt)
    print(json.dumps(vectors, indent=2))
    print("PASS: independent synthetic V1 reference; SQL runtime NOT_EXECUTED")


if __name__ == "__main__":
    run()
