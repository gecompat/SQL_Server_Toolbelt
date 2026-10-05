"""Synthetische Oracles über Python Decimal->Fraction, ohne Produktscanner."""
from decimal import Decimal
from fractions import Fraction
from pathlib import Path
import random


def main():
    rng = random.Random(175048)
    literals = ["0", "-0", "-0.000e-999", "1", "-1", "100e-2", "1.2300e2", "0.00010", "1e30", "-1e-30"]
    for _ in range(130):
        whole = str(rng.randrange(1000000000))
        fraction = "".join(str(rng.randrange(10)) for _ in range(rng.randrange(13)))
        literals.append(("-" if rng.randrange(2) else "") + whole +
                        ("." + fraction if fraction else "") + "e" + f"{rng.randrange(-30, 31):+d}")
    rows = []
    for left in literals:
        for right in rng.sample(literals, 6):
            a, b = Fraction(Decimal(left)), Fraction(Decimal(right))
            rows.append((left, right, (a > b) - (a < b), int(a.denominator == 1), int(b.denominator == 1), int(a >= 0), int(b >= 0)))
    # Mathematische Großexponent-Oracles benötigen keine Expansion als Fraction.
    rows.extend([
        ("1e1000000", "9e999999", 1, 1, 1, 1, 1),
        ("-1e1000000", "-9e999999", -1, 1, 1, 0, 0),
        ("1e-1000000", "9e-1000001", 1, 0, 0, 1, 1),
        ("-0e-999999999999999999999999", "0e999999999999999999999999", 0, 1, 1, 1, 1),
        ("1.0e1000000000000000000000000", "10e999999999999999999999999", 0, 1, 1, 1, 1),
        ("1e-1000000000000000000000000", "10e-1000000000000000000000001", 0, 0, 0, 1, 1),
        ("9.999e999999999999999999999999999999", "1e1000000000000000000000000000000", -1, 1, 1, 1, 1),
        ("1.23e2", "123", 0, 1, 1, 1, 1),
        ("100e-3", "0.1", 0, 0, 0, 1, 1),
        ("1e-000000", "1", 0, 1, 1, 1, 1),
        ("1" + "0" * 5000, "1e5000", 0, 1, 1, 1, 1),
        ("0." + "0" * 5000 + "1", "1e-5001", 0, 0, 0, 1, 1),
        ("1e" + "9" * 5000, "10e" + "9" * 4999 + "8", 0, 1, 1, 1, 1),
    ])
    header = "Left|Right|Compare|LeftInteger|RightInteger|LeftNonNegative|RightNonNegative"
    target = Path(__file__).with_name("NumberOracles.tsv")
    target.write_text(header + "\n" + "\n".join("|".join(map(str, row)) for row in rows) + "\n", encoding="ascii")
    print(f"GENERATED SYNTHETIC NUMBER ORACLES {len(rows)}")


if __name__ == "__main__":
    main()
