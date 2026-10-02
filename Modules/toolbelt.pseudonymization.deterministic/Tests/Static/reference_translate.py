"""Unabhängige synthetische Translate-Referenz; keine SQL-Runtime-Evidenz."""
from hashlib import sha256
import itertools
import struct

LETTERS = "abcdefghijklmnopqrstuvwxyz"
DIGITS = "0123456789"
ALPHABET = LETTERS + LETTERS.upper() + DIGITS
VECTORS = (
    (1, 0, "simvxkhroqdtbwnlguyzpefacjSIMVXKHROQDTBWNLGUYZPEFACJ6301725984"),
    (1, 1, "pajteydqszxviorhfwlcbmungkPAJTEYDQSZXVIORHFWLCBMUNGK7348015269"),
    (2, 0, "aqxfpbuvdntkeliogjchryzswmAQXFPBUVDNTKELIOGJCHRYZSWM3845210769"),
    (2147483647, -(1 << 63), "lfahyntkmjvgdsocbzwxeruqipLFAHYNTKMJVGDSOCBZWXERUQIP3540129867"),
    (1, (1 << 63) - 1, "buevmpwczixgaynshqftrkdjloBUEVMPWCZIXGAYNSHQFTRKDJLO6741329850"),
)


def frame(version, seed, kind, ordinal):
    # struct statt des SQL-Encoders oder int.to_bytes der Vorqualifikation.
    return struct.pack(">8siqBB", b"TBXDTRN1", version, seed, kind, ordinal)


def permutation(alphabet, version, seed, kind, digest=sha256):
    ranks = sorted(range(len(alphabet)),
                   key=lambda ordinal: (digest(frame(version, seed, kind, ordinal)).digest(), ordinal))
    return "".join(alphabet[ordinal] for ordinal in ranks)


def mapping(version, seed):
    lower = permutation(LETTERS, version, seed, 0)
    digits = permutation(DIGITS, version, seed, 1)
    return dict(zip(ALPHABET, lower + lower.upper() + digits))


def translate(value, version, seed=0, separators="", profile="standard"):
    if value is None:
        return None, 0
    if version is None or version <= 0:
        return None, 1
    if seed is None:
        return None, 2
    if profile not in ("standard", "large"):
        return None, 10
    if separators is None or len(separators.encode("utf-16-le", "surrogatepass")) > 66:
        return None, 11
    if len(set(separators)) != len(separators) or any(not 32 <= ord(c) <= 126 or c in ALPHABET for c in separators):
        return None, 11
    limit = 2097152 if profile == "standard" else 16777216
    if len(value.encode("utf-16-le", "surrogatepass")) > limit:
        return None, 12
    if any(c not in ALPHABET + separators for c in value):
        return None, 13
    return value.translate(str.maketrans(mapping(version, seed))), 0


def run():
    checks = 0

    def check(condition):
        nonlocal checks
        checks += 1
        assert condition

    check(sha256(frame(1, 0, 0, 0)).hexdigest() == "e70cd08926a33130655b7c0c3d647e62f90d664e08e9a7f1d9676b32626953d6")
    check(sha256(frame(2147483647, -(1 << 63), 1, 9)).hexdigest() == "a34d48a3f37d6ae66c948f2ddf42b2dfb4c0575c03848c2d01aa7b27ce0ff6ee")
    for version, seed, expected in VECTORS:
        actual = mapping(version, seed)
        check("".join(actual[c] for c in ALPHABET) == expected)
        check(len(set(actual.values())) == 62)
        for c in LETTERS:
            check(actual[c].upper() == actual[c.upper()])
        inverse = {v: k for k, v in actual.items()}
        check(expected.translate(str.maketrans(inverse)) == ALPHABET)

    class Collision:
        def digest(self):
            return bytes(32)
    check(permutation(LETTERS, 1, 0, 0, lambda _: Collision()) == LETTERS)

    for size in range(5):
        for text in itertools.product("aA0-_", repeat=size):
            value = "".join(text)
            result, error = translate(value, 1, 0, "-_")
            check(error == 0)
            inverse = {v: k for k, v in mapping(1, 0).items()}
            check(result.translate(str.maketrans(inverse)) == value)

    punct = "".join(chr(n) for n in range(32, 127) if chr(n) not in ALPHABET)
    check(len(punct) == 33)
    check(translate(punct, 1, separators=punct) == (punct, 0))
    check(translate(punct, 1, separators=punct + "-") == (None, 11))
    check(translate(None, None, None, None, None) == (None, 0))
    check(translate("x", None, None, None, None) == (None, 1))
    check(translate("x", 1, None, None, None) == (None, 2))
    check(translate("x", 1, 0, None, None) == (None, 10))
    check(translate("x", 1, 0, None) == (None, 11))
    for profile in (None, "STANDARD", "standard ", "large ", ""):
        check(translate("x", 1, profile=profile) == (None, 10))
    for separators in ("--", "a", "0", "\0", "\t", "\ud800", "😀"):
        check(translate("x", 1, separators=separators) == (None, 11))
    for value in ("\0", "\t", "\x7f", "ä", "K", "\ud800", "\udfff", "😀", "-", " "):
        check(translate(value, 1) == (None, 13))
    for profile, count, target in (("standard", 1048576, "s"), ("large", 8388608, "s")):
        result, error = translate("a" * count, 1, profile=profile)
        check(error == 0 and result == target * count)
        check(translate("a" * (count + 1), 1, profile=profile) == (None, 12))
        check(translate("a" * (count - 1) + "-", 1, profile=profile) == (None, 13))
    return checks


if __name__ == "__main__":
    print(f"PASS: Translate unabhängige Referenz ({run()} Assertions; SQL not executed)")
